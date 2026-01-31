---
name: rust-cache
description: "Redis cache management, connection pools, TTL policies, pattern-based deletion, performance optimization"
category: infrastructure
triggers: ["cache", "redis", "ttl", "connection", "Performance optimization", "Cache"]
related_skills:
 - rust-concurrency
 - rust-async
 - rust-performance
 - rust-error
---

# Rust Cache - Cache Management Skills

> This skill provides systematic solutions for Redis caches, including
> connection management, cache strategies, performance optimization, etc.

## Core concepts

### 1. Cache structure design

```text
Cache layer design pattern
├── Cache Manager (CacheManager)
│ ├── Connection Management (ConnectionManager)
│ ├── Serialization/Deserialization
│ ├── TTL Control
│ └── Statistical information
├── Cache Key Generator (CacheKeyBuilder)
│ ├── Namespace Prefix
│ └── Business identifiers
└── Cache Policy
├── Cache-Aside
├── Write-Through
└── Write-Behind
```

### 2. Performance enhancement data

| scene           | No Cache | Cache | Raise    |
|-----------------|----------|-------|----------|
| Complex queries | ~100ms   | <5ms  | **95%+** |
| Frequent visits | ~50ms    | <2ms  | **96%**  |

---

## Core patterns

### 1. Cache manager implementation

```rust
//! Cache Manager implementation
//!
//! Provide a general pattern for distributed Redis caches

use redis::{aio::ConnectionManager, AsyncCommands};
use serde::{de::DeserializeOwned, Serialize};
use std::sync::Arc;
use std::time::Duration;
use tokio::sync::RwLock;

/// Cache Manager
pub struct CacheManager {
 /// Configure
 config: CacheConfig,
 /// Redis Connection Manager
 redis: Option<ConnectionManager>,
 /// Statistical information
 stats: Arc<RwLock<CacheStats>>,
}

impl CacheManager {
 /// Create a new cache manager(Timeout Control)
 pub async fn new(config: CacheConfig) -> Result<Self, CacheError> {
 let redis = if config.enabled && config.redis.enabled {
 // Create Redis Client
 let client = redis::Client::open(config.redis.url.as_str())
 .map_err(|e| CacheError::Connection(format!("Redis Connection failed: {}", e)))?;

 // Timeout Control(Adapt to Remote Redis)
 let timeout = Duration::from_secs(30);

 match tokio::time::timeout(timeout, ConnectionManager::new(client)).await {
 Ok(Ok(conn)) => Some(conn),
 Ok(Err(e)) => return Err(CacheError::Connection(format!("Redis Connection failed: {}", e))),
 Err(_) => return Err(CacheError::Timeout(format!("Redis Connection timed out({}sec)", timeout.as_secs()))),
 }
 } else {
 None
 };

 Ok(Self {
 config,
 redis,
 stats: Arc::new(RwLock::new(CacheStats::new())),
 })
 }

 /// Get Cache
 pub async fn get<T: DeserializeOwned>(&self, key: &str) -> Result<Option<T>, CacheError> {
 if !self.config.enabled {
 return Ok(None);
 }

 // Increased number of requests
 {
 let mut stats = self.stats.write().await;
 stats.total_requests += 1;
 }

 if let Some(mut redis) = self.redis.clone() {
 match redis.get::<&str, Vec<u8>>(key).await {
 Ok(bytes) if !bytes.is_empty() => {
 // Update statistics
 {
 let mut stats = self.stats.write().await;
 stats.redis_hits += 1;
 }
 self.deserialize(&bytes)
 }
 Ok(_) => {
 let mut stats = self.stats.write().await;
 stats.redis_misses += 1;
 Ok(None)
 }
 Err(e) => {
 log::warn!("Redis Reading Failed: key={}, error={}", key, e);
 let mut stats = self.stats.write().await;
 stats.redis_misses += 1;
 Ok(None) // Cache failure should not affect business
 }
 }
 } else {
 Ok(None)
 }
 }

 /// Set Cache(And... TTL)
 pub async fn set<T: Serialize>(
 &self,
 key: &str,
 value: &T,
 ttl: Option<u64>,
 ) -> Result<(), CacheError> {
 if !self.config.enabled {
 return Ok(());
 }

 let bytes = self.serialize(value)?;

 if let Some(mut redis) = self.redis.clone() {
 let ttl_seconds = ttl.unwrap_or(self.config.default_ttl);
 match redis.set_ex::<&str, Vec<u8>, ()>(key, bytes, ttl_seconds).await {
 Ok(_) => log::debug!("Redis Writing: key={}, ttl={}s", key, ttl_seconds),
 Err(e) => log::warn!("Redis Writing failed: key={}, error={}", key, e),
 }
 }

 Ok(())
 }

 /// Remove cache
 pub async fn delete(&self, key: &str) -> Result<(), CacheError> {
 if let Some(mut redis) = self.redis.clone() {
 match redis.del::<&str, ()>(key).await {
 Ok(_) => log::debug!("Redis Delete: {}", key),
 Err(e) => log::warn!("Redis Failed to delete: key={}, error={}", key, e),
 }
 }
 Ok(())
 }

 /// Serialize
 fn serialize<T: Serialize>(&self, value: &T) -> Result<Vec<u8>, CacheError> {
 serde_json::to_vec(value).map_err(|e| {
 CacheError::Serialization(format!("Serialization failed: {}", e))
 })
 }

 /// Deserialize
 fn deserialize<T: DeserializeOwned>(&self, bytes: &[u8]) -> Result<Option<T>, CacheError> {
 if bytes.is_empty() {
 return Ok(None);
 }

 match serde_json::from_slice(bytes) {
 Ok(value) => Ok(Some(value)),
 Err(e) => {
 log::warn!("Deserialization failed: {}", e);
 Ok(None) // Damaged data should skip,Do not return error
 }
 }
 }
}

/// Cache Statistical Information
#[derive(Debug, Clone, Default)]
pub struct CacheStats {
 pub total_requests: u64,
 pub redis_hits: u64,
 pub redis_misses: u64,
}

impl CacheStats {
 pub fn new() -> Self {
 Self::default()
 }

 /// Hit rate
 pub fn hit_rate(&self) -> f64 {
 if self.total_requests == 0 {
 0.0
 } else {
 self.redis_hits as f64 / self.total_requests as f64 * 100.0
 }
 }
}

/// Cache Error Type
#[derive(Debug, thiserror::Error)]
pub enum CacheError {
 #[error("Connection error: {0}")]
 Connection(String),
 #[error("Timeout Error: {0}")]
 Timeout(String),
 #[error("Serialization error: {0}")]
 Serialization(String),
 #[error("Redis Error: {0}")]
 Redis(#[from] redis::RedisError),
}
```

### 2. Cache key design pattern

```rust
/// Cache Key Generator
///
/// Design principles:
/// 1. Use a namespace prefix to avoid key collisions
/// 2. Include business identifiers for clarity
/// 3. Support versioning for cache updates
pub struct CacheKeyBuilder;

impl CacheKeyBuilder {
 /// Key to build a namespace
 /// Format: {namespace}:{entity}:{id}
 pub fn build(namespace: &str, entity: &str, id: impl std::fmt::Display) -> String {
 format!("{}:{}:{}", namespace, entity, id)
 }

 /// Build list cache key
 /// Format: {namespace}:{entity}:list:{query_hash}
 pub fn list_key(namespace: &str, entity: &str, query: &str) -> String {
 use sha2::{Digest, Sha256};
 let mut hasher = Sha256::new();
 hasher.update(query.as_bytes());
 let hash = format!("{:x}", hasher.finalize());
 format!("{}:{}:list:{}", namespace, entity, &hash[..8])
 }

 /// Build pattern key
 /// Format: {namespace}:{entity}:*
 pub fn pattern(namespace: &str, entity: &str) -> String {
 format!("{}:{}:*", namespace, entity)
 }

 /// Build Version Key
 /// Format: {namespace}:{entity}:{id}:v{version}
 pub fn versioned(namespace: &str, entity: &str, id: impl std::fmt::Display, version: u64) -> String {
 format!("{}:{}:{}:v{}", namespace, entity, id, version)
 }
}
```

### 3. Batch cache deletion pattern

```rust
impl CacheManager {
 /// Batch remove cache (supports pattern matching)
 ///
 /// Use SCAN for incremental deletes, avoid DEL blocking
 pub async fn delete_pattern(&self, pattern: &str) -> Result<usize, CacheError> {
 let mut deleted_count = 0;

 if let Some(redis) = &self.redis {
 let mut cursor: u64 = 0;

 loop {
 let result: std::result::Result<(u64, Vec<String>), redis::RedisError> =
 redis::cmd("SCAN")
 .arg(cursor)
 .arg("MATCH")
 .arg(pattern)
 .arg("COUNT")
 .arg(100)
 .query_async(&mut redis.clone())
 .await;

 match result {
 Ok((new_cursor, keys)) => {
 if !keys.is_empty() {
 let del_result: std::result::Result<(), redis::RedisError> =
 redis::cmd("DEL").arg(&keys).query_async(&mut redis.clone()).await;

 if del_result.is_ok() {
 deleted_count += keys.len();
 }
 }
 cursor = new_cursor;
 if cursor == 0 {
 break;
 }
 }
 Err(e) => {
 log::warn!("Redis SCAN Failed: {}", e);
 break;
 }
 }
 }

 log::info!("Batch deletion complete: pattern={}, deleted={}", pattern, deleted_count);
 }

 Ok(deleted_count)
 }
}
```

---

## Configuration Management

### 1. Cache Configuration

```rust
/// Cache Configuration
#[derive(Debug, Clone)]
pub struct CacheConfig {
 pub enabled: bool,
 pub redis: RedisConfig,
 pub default_ttl: u64, // Default TTL(sec)
}

#[derive(Debug, Clone)]
pub struct RedisConfig {
 pub enabled: bool,
 pub url: String,
 pub pool_size: u32,
 pub max_retries: u32,
}

impl Default for CacheConfig {
 fn default() -> Self {
 Self {
 enabled: true,
 redis: RedisConfig {
 enabled: true,
 url: "redis://localhost:6379".to_string(),
 pool_size: 10,
 max_retries: 3,
 },
 default_ttl: 3600, // Default 1 Hours
 }
 }
}
```

---

## Best practices

### 1. Cache strategy selection

| Policy        | Apply scene                        | Strengths                | Disadvantages               |
|---------------|------------------------------------|--------------------------|-----------------------------|
| Cache-Aside   | Read and write.                    | Simple, reliable.        | Risk of cache inconsistency |
| Write-Through | High data consistency requirements | Strong coherence         | Write delay increase        |
| Write-Behind  | High write throughput              | Writing performance high | Risk of data loss           |

### Two. . TTL Layer Design

```rust
/// TTL Layer Design
pub struct CacheTTL {
 pub short: u64 = 300, // 5 min - Thermal Data
 pub medium: u64 = 3600, // 1 Hours - Medium frequency data
 pub long: u64 = 86400, // 24 Hours - Low frequency data
 pub static_data: u64 = 604800, // 7 days - Static Data
}

/// Use Example
impl CacheManager {
 /// Storage of HF access data - 5 min
 pub async fn set_hot_data<T: Serialize>(&self, key: &str, data: &T) -> Result<()> {
 self.set(key, data, Some(300)).await
 }

 /// Storage frequency data - 1 Hours
 pub async fn set_medium_data<T: Serialize>(&self, key: &str, data: &T) -> Result<()> {
 self.set(key, data, Some(3600)).await
 }

 /// Storage of low frequency data - 24 Hours
 pub async fn set_cold_data<T: Serialize>(&self, key: &str, data: &T) -> Result<()> {
 self.set(key, data, Some(86400)).await
 }
}
```

### 3. Cache penetrator protection

```rust
/// Cache penetration protection
pub struct CacheBreaker<K, T> {
 manager: Arc<CacheManager>,
 _phantom: std::marker::PhantomData<(K, T)>,
}

impl<K, T> CacheBreaker<K, T>
where
 K: std::fmt::Display + Clone + Send + Sync,
 T: DeserializeOwned + Serialize + Clone,
{
 pub fn new(manager: Arc<CacheManager>) -> Self {
 Self { manager, _phantom: std::marker::PhantomData }
 }

 /// Getting data(Cache protection)
 pub async fn get_or_load<F, Fut>(&self, key: &str, loader: F) -> Result<Option<T>>
 where
 F: FnOnce() -> Fut,
 Fut: std::future::Future<Output = Result<Option<T>>>,
 {
 // 1. Try fetching from cache
 if let Some(cached) = self.manager.get::<T>(key).await? {
 return Ok(Some(cached));
 }

 // 2. Cache Uncut,Load from data source
 let result = loader().await?;

 // 3. Write result to cache
 if let Some(ref value) = result {
 self.manager.set(key, value, None).await?;
 }

 Ok(result)
 }
}
```

### 4. Cache avalanche protection

```rust
/// Cache avalanche protection:Random TTL Shake
fn calculate_jitter_ttl(base_ttl: u64) -> u64 {
 let jitter = (base_ttl as f64 * 0.1)..(base_ttl as f64 * 0.2);
 let jitter_seconds = rand::thread_rng().gen_range(jitter);
 (base_ttl as f64 + jitter_seconds) as u64
}

/// Use Example
pub async fn set_with_jitter(
 cache: &CacheManager,
 key: &str,
 value: &impl Serialize,
 base_ttl: u64,
) -> Result<()> {
 let ttl = calculate_jitter_ttl(base_ttl);
 cache.set(key, value, Some(ttl)).await
}
```

---

## Monitoring and indicators

```rust
use prometheus::{Counter, Histogram, Gauge};

/// Cache Indicators
#[derive(Debug)]
pub struct CacheMetrics {
 pub hits: Counter,
 pub misses: Counter,
 pub operations: Histogram,
 pub latency: Histogram,
 pub size: Gauge,
}

impl CacheMetrics {
 pub fn new() -> Self {
 Self {
 hits: Counter::new("cache_hits_total", "Cache hits total"),
 misses: Counter::new("cache_misses_total", "Cache misses total"),
 operations: Histogram::new(
 "cache_operation_duration_seconds",
 "Cache operation duration",
 vec![0.001, 0.005, 0.01, 0.05, 0.1, 0.5, 1.0],
 ),
 latency: Histogram::new(
 "cache_latency_seconds",
 "Cache latency",
 vec![0.0001, 0.0005, 0.001, 0.005, 0.01, 0.05],
 ),
 size: Gauge::new("cache_size", "Cache size"),
 }
 }

 pub fn record_hit(&self) {
 self.hits.inc();
 }

 pub fn record_miss(&self) {
 self.misses.inc();
 }

 pub fn hit_rate(&self) -> f64 {
 let hits = self.hits.get() as f64;
 let total = hits + self.misses.get() as f64;
 if total > 0.0 { hits / total * 100.0 } else { 0.0 }
 }
}
```

---

## Question screening

| Problem                       | Possible causes                          | Solutions                                     |
|-------------------------------|------------------------------------------|-----------------------------------------------|
| Low Cache Rate                | TTL not set properly                     | Adjust TTL to distinguish heat from cold data |
| Redis connection timed out    | Network delayed or connect pool depleted | Increase timeout, expand the connect pool     |
| Cache does not match database | Also writes Unlocked                     | Use distributed locks                         |
| Overuse of memory             | Cache data is too big                    | Enable compression with maximum capacity      |
| Batch delete blocks           | Using DEL instead of SCAN                | Use SCAN-based deletion instead               |

---

## Related skills

- rust-auth — authentication and access control
- rust-async — async patterns
- rust-performance — performance optimization
- rust-error — error handling
