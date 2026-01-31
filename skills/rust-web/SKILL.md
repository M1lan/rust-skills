---
name: rust-web
description: "Rust web development: axum, actix, HTTP, REST, APIs, databases, state management. Triggers: web, HTTP, REST, API, axum, actix, handler, database, server, routing"
globs: ["**/*.rs"]
---

# Rust Web Development

## Mainstream framework selection

| Framework | Characteristics                    | Recommended use case          |
|-----------|------------------------------------|-------------------------------|
| axum      | Modern, Tokio ecosystem, type-safe | Preferred for new projects    |
| actix-web | High performance, actor model      | High-performance requirements |
| rocket    | Developer-friendly, zero config    | Rapid prototyping             |

---

## Axum quick start

### Basic structure

```rust
use axum::{routing::get, Router};

#[tokio::main]
async fn main() {
    let app = Router::new()
        .route("/", get(root))
        .route("/users", get(list_users).post(create_user))
        .route("/users/:id", get(get_user).delete(delete_user))
        .with_state(pool.clone());

    axum::Server::bind(&"0.0.0.0:3000".parse().unwrap())
        .serve(app.into_make_service())
        .await
        .unwrap();
}
```

### Handler patterns

```rust
// Get params from path
async fn get_user(Path(id): Path<u32>) -> Json<User> {
    User::find(id).await
        .map(Json)
        .ok_or_else(|| StatusCode::NOT_FOUND)
}

// Get from JSON body
async fn create_user(Json(user): Json<CreateUserRequest>) -> Result<Json<User>, StatusCode> {
    User::create(user).await
        .map(Json)
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)
}

// Query parameters
async fn list_users(Query(params): Query<ListUsersParams>) -> Json<Vec<User>> {
    User::list(params).await
}
```

### State management

```rust
// AppState type
type AppState = Arc<Pool<Postgres>>;

// Extract state
async fn handler(state: State<AppState>) { ... }

// Shared state
let pool = PgPoolOptions::new()
    .max_connections(5)
    .connect(&db_url)
    .await?;

let app = Router::new()
    .route("/", get(handler))
    .with_state(Arc::new(pool));
```

---

## Error handling

```rust
use axum::{
    response::{IntoResponse, Response},
    Json,
};
use thiserror::Error;

#[derive(Error, Debug)]
pub enum ApiError {
    #[error("user not found")]
    NotFound,

    #[error("invalid input: {0}")]
    Validation(String),

    #[error("database error")]
    Database(#[from] sqlx::Error),
}

impl IntoResponse for ApiError {
    fn into_response(self) -> Response {
        match self {
            ApiError::NotFound => (StatusCode::NOT_FOUND, self.to_string()).into_response(),
            ApiError::Validation(msg) => (StatusCode::BAD_REQUEST, msg).into_response(),
            ApiError::Database(e) => {
                tracing::error!("database error: {}", e);
                (StatusCode::INTERNAL_SERVER_ERROR, "internal error").into_response()
            }
        }
    }
}
```

---

## Middleware patterns

```rust
// Log requests
async fn log_requests(req: Request, next: Next) -> Result<Response, Infallible> {
    let start = Instant::now();
    let method = req.method().clone();
    let path = req.uri().path().to_string();

    let response = next.run(req).await;

    tracing::info!(
        "{} {} {} - {:?}",
        method,
        path,
        response.status(),
        start.elapsed()
    );

    Ok(response)
}

// Use
let app = Router::new()
    .route("/", get(handler))
    .layer(layer_fn(log_requests));
```

---

## Database integration

### SQLx example

```rust
// Define model
#[derive(Debug, FromRow)]
struct User {
    id: i32,
    name: String,
    email: String,
    created_at: chrono::DateTime<Utc>,
}

// Query
async fn get_user(pool: &Pool<Postgres>, id: i32) -> Result<User, sqlx::Error> {
    sqlx::query_as!(User, "SELECT * FROM users WHERE id = $1", id)
        .fetch_one(pool)
        .await
}

// Transaction
let mut tx = pool.begin().await?;
sqlx::query!("INSERT INTO ...") .execute(&mut *tx).await?;
tx.commit().await?;
```

---

## Web development best practices

| Scenario           | Recommended practice                        |
|--------------------|---------------------------------------------|
| JSON serialization | `#[derive(Serialize, Deserialize)]` + serde |
| Configuration      | `config` crate + env files                  |
| Logging            | `tracing` + `tracing-subscriber`            |
| Health checks      | `GET /health` endpoint                      |
| CORS               | `tower_http::cors`                          |
| Rate limiting      | `tower::limit`                              |
| OpenAPI            | `utoipa`                                    |

---

## Common errors

| Error                         | Cause                 | Fix                      |
|-------------------------------|-----------------------|--------------------------|
| State shared between handlers | `Rc` not thread-safe  | Use `Arc`                |
| Async handler holds a lock    | Possible deadlock     | Reduce lock scope        |
| Errors not propagated         | Handler returns error | Implement `IntoResponse` |
| Large request body            | Memory pressure       | Set size limits          |

---

## Project structure reference

```text
src/
├── main.rs           # Entry
├── lib.rs            # Shared code
├── app.rs            # Router assembly
├── routes/           # Route definitions
│   ├── mod.rs
│   ├── users.rs
│   └── auth.rs
├── models/           # Data models
├── services/         # Business logic
├── errors/           # Error types
```
