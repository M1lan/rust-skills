---
name: rust-auth
description: "JWT authentication, API key authentication, distributed token storage, secure password storage"
category: infrastructure
triggers: ["auth", "jwt", "token", "api-key", "permission", "Authentication", "Authorization"]
related_skills:
 - rust-web
 - rust-middleware
 - rust-error
 - rust-concurrency
---

# Rust Auth - Authentication & Authorization Skills

> This skill provides end-to-end authentication and authorization solutions
> including JWT, API keys, and distributed token storage.

## Core concepts

### 1. Authentication architecture design

```text
Authentication & authorization architecture
├── Authentication layer
│ ├── JWT authentication
│ ├── API key authentication
│ └── Multi-factor authentication
├── Authorization layer
│ ├── Role-based access control (RBAC)
│ ├── Permission-based access control
│ └── Fine-grained permissions
└── Session management
 ├── Token management
 ├── Session storage
 └── Concurrency control
```

### 2. Authentication method comparison

| Method     | Use case                             | Security  | Implementation complexity |
|------------|--------------------------------------|-----------|---------------------------|
| JWT token  | Frontend/backend split, API access   | High      | Medium                    |
| API key    | Service-to-service calls, automation | Medium    | Low                       |
| Two-factor | High-security requirements           | Very high | High                      |

---

## Core patterns

### 1. JWT Token authentication

```rust
//! JWT authentication module

use jsonwebtoken::{decode, encode, Algorithm, DecodingKey, EncodingKey, Header, Validation};
use serde::{Deserialize, Serialize};
use std::time::{Duration, SystemTime};
use thiserror::Error;

/// JWT error type
#[derive(Error, Debug)]
pub enum JwtError {
 #[error("Token parsing failed: {0}")]
 ParseError(String),
 #[error("Token validation failed: {0}")]
 ValidationError(String),
 #[error("Token expired")]
 Expired,
 #[error("Token signature invalid")]
 InvalidSignature,
}

/// Token claims (common fields)
#[derive(Debug, Serialize, Deserialize)]
pub struct Claims {
 pub sub: String, // Subject identifier
 pub name: Option<String>, // Name
 pub roles: Vec<String>, // Role list
 pub exp: u64, // Expiration time
 pub iat: u64, // Issued-at time
 // Business fields can be added by expanding fields
}

/// JWT service
pub struct JwtService {
 encoding_key: EncodingKey,
 decoding_key: DecodingKey,
 secret: String,
 expiry: Duration,
 algorithm: Algorithm,
}

impl JwtService {
 pub fn new(secret: String, expiry_seconds: u64) -> Self {
 Self {
 encoding_key: EncodingKey::from_secret(secret.as_bytes()),
 decoding_key: DecodingKey::from_secret(secret.as_bytes()),
 secret,
 expiry: Duration::from_secs(expiry_seconds),
 algorithm: Algorithm::HS256,
 }
 }

 /// Generate token
 pub fn generate_token(&self, subject: &str, roles: &[String]) -> Result<String, JwtError> {
 let now = SystemTime::now()
 .duration_since(SystemTime::UNIX_EPOCH)
 .unwrap()
 .as_secs();

 let claims = Claims {
 sub: subject.to_string(),
 name: None,
 roles: roles.to_vec(),
 exp: now + self.expiry.as_secs(),
 iat: now,
 };

 encode(&Header::new(self.algorithm), &claims, &self.encoding_key)
 .map_err(|e| JwtError::ParseError(e.to_string()))
 }

 /// Verify & Parsing Token
 pub fn verify_token(&self, token: &str) -> Result<Claims, JwtError> {
 let validation = Validation::new(self.algorithm);

 decode::<Claims>(token, &self.decoding_key, &validation)
 .map(|data| data.claims)
 .map_err(|e| match e.kind() {
 jsonwebtoken::errors::ErrorKind::ExpiredSignature => JwtError::Expired,
 jsonwebtoken::errors::ErrorKind::InvalidSignature => JwtError::InvalidSignature,
 _ => JwtError::ValidationError(e.to_string()),
 })
 }

 /// Inspection Token Expiry(Remaining < 10 Minute back true)
 pub fn is_expiring_soon(&self, claims: &Claims) -> bool {
 let now = SystemTime::now()
 .duration_since(SystemTime::UNIX_EPOCH)
 .unwrap()
 .as_secs();
 claims.exp - now < 600
 }
}
```

### Two. API Key Authentication

```rust
//! API Key Authentication module

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};

/// API Key Configure
#[derive(Debug, Clone)]
pub struct ApiKeyConfig {
 pub prefix: String, // Key Prefix
 pub secret: String, // Sign Key
 pub expiry_days: i64, // Valid period
 pub allowed_ips: Vec<String>, // IP White list.
}

/// API Key Information
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ApiKeyInfo {
 pub key_id: String,
 pub owner_id: String,
 pub secret_hash: String,
 pub created_at: DateTime<Utc>,
 pub expires_at: DateTime<Utc>,
 pub last_used_at: Option<DateTime<Utc>>,
 pub disabled: bool,
 pub scopes: Vec<String>,
}

/// API Key Error
#[derive(Debug)]
pub enum ApiKeyError {
 InvalidKey,
 KeyExpired,
 KeyRevoked,
 SignatureMismatch,
}

/// API Key Generator
pub struct ApiKeyGenerator;

impl ApiKeyGenerator {
 /// Generate API Key
 /// Format: {prefix}_{key_id}_{signature}
 pub fn generate(config: &ApiKeyConfig, owner_id: &str) -> (String, String) {
 let key_id = Self::generate_key_id();
 let secret = Self::generate_secret();
 let signature = Self::compute_signature(config, &key_id, &secret);

 let api_key = format!("{}_{}_{}", config.prefix, key_id, signature);
 let secret_hash = Self::hash_secret(config, &secret);

 (api_key, secret_hash)
 }

 /// Authentication API Key
 pub async fn verify(
 config: &ApiKeyConfig,
 api_key: &str,
 ip: Option<&str>,
 key_info: &ApiKeyInfo,
 ) -> Result<(), ApiKeyError> {
 let parts: Vec<&str> = api_key.split('_').collect();
 if parts.len() != 3 {
 return Err(ApiKeyError::InvalidKey);
 }

 if key_info.disabled {
 return Err(ApiKeyError::KeyRevoked);
 }

 if key_info.expires_at < Utc::now() {
 return Err(ApiKeyError::KeyExpired);
 }

 if let Some(client_ip) = ip {
 if !config.allowed_ips.is_empty()
 && !config.allowed_ips.contains(&client_ip.to_string()) {
 return Err(ApiKeyError::InvalidKey);
 }
 }

 let expected_signature = Self::compute_signature(config, parts[1], "stored");
 if parts[2] != expected_signature {
 return Err(ApiKeyError::SignatureMismatch);
 }

 Ok(())
 }

 fn generate_key_id() -> String {
 use rand::Rng;
 const CHARSET: &[u8] = b"abcdefghijklmnopqrstuvwxyz0123456789";
 let mut rng = rand::thread_rng();
 (0..16).map(|_| CHARSET[rng.gen_range(0..CHARSET.len())] as char).collect()
 }

 fn generate_secret() -> String {
 use rand::Rng;
 const CHARSET: &[u8] = b"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*";
 let mut rng = rand::thread_rng();
 (0..32).map(|_| CHARSET[rng.gen_range(0..CHARSET.len())] as char).collect()
 }

 fn compute_signature(config: &ApiKeyConfig, key_id: &str, secret: &str) -> String {
 let data = format!("{}{}", key_id, secret);
 let mut hasher = Sha256::new();
 hasher.update(data.as_bytes());
 hasher.update(config.secret.as_bytes());
 format!("{:x}", hasher.finalize())[..8].to_string()
 }

 fn hash_secret(config: &ApiKeyConfig, secret: &str) -> String {
 let mut hasher = Sha256::new();
 hasher.update(secret.as_bytes());
 hasher.update(config.secret.as_bytes());
 format!("{:x}", hasher.finalize())
 }
}
```

### 3. Distributed token storage

```rust
//! Distributed token storage

use redis::AsyncCommands;

/// Token Storage Configuration
#[derive(Debug, Clone)]
pub struct TokenStoreConfig {
 pub redis_url: String,
 pub prefix: String,
}

pub struct TokenStore {
 redis: Option<redis::aio::ConnectionManager>,
 config: TokenStoreConfig,
}

impl TokenStore {
 pub async fn new(config: TokenStoreConfig) -> Result<Self, Box<dyn std::error::Error>> {
 let redis = if config.redis_url.starts_with("redis://") {
 let client = redis::Client::open(config.redis_url.as_str())?;
 let conn = redis::aio::ConnectionManager::new(client).await?;
 Some(conn)
 } else {
 None
 };
 Ok(Self { redis, config })
 }

/// Store token (concurrency control)
 pub async fn store_token(
 &self,
 user_id: &str,
 token_id: &str,
 claims: &Claims,
 max_concurrent: usize,
 ) -> Result<(), Box<dyn std::error::Error>> {
 if let Some(ref mut redis) = self.redis {
 let prefix = &self.config.prefix;
 let key = format!("{}:tokens:{}", prefix, user_id);

 // Count existing tokens for the user
 let current_count: usize = redis.scard(&key).await?;

 if current_count >= max_concurrent {
 if let Some(old_token) = redis.spop::<String>(&key).await? {
 redis.del(&format!("{}:token:{}", prefix, old_token)).await?;
 }
 }

 let token_key = format!("{}:token:{}", prefix, token_id);
 let token_data = serde_json::to_string(claims)?;
 let ttl = claims.exp.saturating_sub(86400);
 redis.set_ex(&token_key, token_data, ttl).await?;
 redis.sadd(&key, token_id).await?;
 }
 Ok(())
 }

 /// Revoke token
 pub async fn revoke_token(&self, user_id: &str, token_id: &str) -> Result<(), Box<dyn std::error::Error>> {
 if let Some(ref mut redis) = self.redis {
 let prefix = &self.config.prefix;
 redis.del(&format!("{}:token:{}", prefix, token_id)).await?;
 redis.srem(&format!("{}:tokens:{}", prefix, user_id), token_id).await?;
 }
 Ok(())
 }

 /// Revoke all tokens for a user
 pub async fn revoke_all_tokens(&self, user_id: &str) -> Result<(), Box<dyn std::error::Error>> {
 if let Some(ref mut redis) = self.redis {
 let prefix = &self.config.prefix;
 let set_key = format!("{}:tokens:{}", prefix, user_id);
 let token_ids: Vec<String> = redis.smembers(&set_key).await?;

 for token_id in token_ids {
 redis.del(&format!("{}:token:{}", prefix, token_id)).await?;
 }
 redis.del(&set_key).await?;
 }
 Ok(())
 }
}
```

---

## Best practices

### 1. Authentication middleware

```rust
//! Authentication middleware

use actix_web::{
 dev::{forward_ready, Service, ServiceRequest, ServiceResponse, Transform},
 Error, HttpMessage,
};
use futures::future::{ready, LocalBoxFuture, Ready};
use std::rc::Rc;

pub struct JwtAuthentication;

impl<S, B> Transform<S, ServiceRequest> for JwtAuthentication
where
 S: Service<ServiceRequest, Response = ServiceResponse<B>, Error = Error> + 'static,
 S::Future: 'static,
 B: 'static,
{
 type Response = ServiceResponse<B>;
 type Error = Error;
 type InitError = ();
 type Transform = JwtAuthMiddleware<S>;
 type Future = Ready<Result<Self::Transform, Self::InitError>>;

 fn new_transform(&self, service: S) -> Self::Future {
 ready(Ok(JwtAuthMiddleware { service: Rc::new(service) }))
 }
}

pub struct JwtAuthMiddleware<S> {
 service: Rc<S>,
}

impl<S, B> Service<ServiceRequest> for JwtAuthMiddleware<S>
where
 S: Service<ServiceRequest, Response = ServiceResponse<B>, Error = Error> + 'static,
 S::Future: 'static,
 B: 'static,
{
 type Response = ServiceResponse<B>;
 type Error = Error;
 type Future = LocalBoxFuture<'static, Result<Self::Response, Self::Error>>;

 forward_ready!(service);

 fn call(&self, req: ServiceRequest) -> Self::Future {
 let service = Rc::clone(&self.service);

 Box::pin(async move {
 let auth_header = req.headers()
 .get("Authorization")
 .and_then(|v| v.to_str().ok());

 let token = match auth_header {
 Some(header) if header.starts_with("Bearer ") => &header[7..],
 _ => return Err(actix_web::error::ErrorUnauthorized("Invalid Authorization")),
 };

 let jwt_service = req.app_data::<JwtService>()
 .ok_or(actix_web::error::ErrorInternalServerError("JWT not configured"))?;

 let claims = jwt_service.verify_token(token)
 .map_err(|_| actix_web::error::ErrorUnauthorized("Invalid token"))?;

 req.extensions_mut().insert(claims);
 service.call(req).await
 })
 }
}
```

### 2. Secure password storage

```rust
//! Secure password storage

use argon2::{self, Config};
use rand::Rng;

/// Password Hash Service
pub struct PasswordHasher;

impl PasswordHasher {
 /// Hash code.
 pub fn hash_password(password: &str) -> Result<String, argon2::Error> {
 let salt = rand::thread_rng().gen::<[u8; 32]>();
 let config = Config::default();

 argon2::hash_raw(password.as_bytes(), &salt, &config)
 .map(|bytes| {
 let salt_b64 = base64::Engine::encode(&base64::engine::general_purpose::STANDARD, &salt);
 let hash_b64 = base64::Engine::encode(&base64::engine::general_purpose::STANDARD, &bytes);
 format!("$argon2id$v=19,m=4096,t=3,p=1${}${}$", salt_b64, hash_b64)
 })
 }

 /// Authentication password
 pub fn verify_password(password: &str, stored_hash: &str) -> Result<bool, argon2::Error> {
 use subtle::ConstantTimeEq;

 let parts: Vec<&str> = stored_hash.split('$').collect();
 if parts.len() != 5 { return Ok(false); }

 let salt = base64::Engine::decode(&base64::engine::general_purpose::STANDARD, parts[2]).unwrap_or_default();
 let stored = base64::Engine::decode(&base64::engine::general_purpose::STANDARD, parts[3]).unwrap_or_default();

 let config = Config::default();
 let computed = argon2::hash_raw(password.as_bytes(), &salt, &config)?;

 Ok(computed.as_slice().ct_eq(&stored))
 }
}
```

---

## Question screening

| Problem                             | Reason                      | Solutions              |
|-------------------------------------|-----------------------------|------------------------|
| Token Expire                        | Time window problem         | Refresh token          |
| The simultaneous login is abnormal. | Redis Connection            | Check connect pool     |
| API Key embezzlement                | No IP white list configured | Enable IP limitations  |
| Password authentication slow        | Argon2 Time-consuming       | Adjusting work factors |

---

## Related skills

- rust-web — web framework integration
- rust-middleware — middleware design
- rust-error — error handling
- rust-cache — token storage/cache
