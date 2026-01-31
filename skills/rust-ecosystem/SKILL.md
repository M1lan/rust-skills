---
name: rust-ecosystem
description: "Rust ecosystem guide: crate selection, library recommendations, frameworks, async runtimes, and tooling. Triggers: crate, library, framework, ecosystem, async runtime, tokio, async-std, serde, reqwest, axum"
globs: ["**/Cargo.toml"]
---

# Rust Ecosystem

## Core issues

Key question: Which crate solves this problem best?

Selecting the right library is the key to efficient Rust development.

---

## Async runtimes

| Runtime         | Characteristics             | Use case              |
|-----------------|-----------------------------|-----------------------|
| tokio           | Most popular, full-featured | General-purpose async |
| async-std       | Std-like API                | Prefer std-style APIs |
| actix           | High performance            | Actix ecosystem       |
| async-executors | Unified interface           | Runtime abstraction   |

```toml
# Web services
tokio = { version = "1", features = ["full"] }
axum = "0.7"

# Lightweight runtime
async-std = "1"
```

---

## Web frameworks

| Framework | Characteristics             | Performance |
|-----------|-----------------------------|-------------|
| axum      | Tower middleware, type-safe | High        |
| actix-web | Max performance             | Highest     |
| rocket    | Developer friendly          | Medium      |
| warp      | Filter-based                | High        |

---

## Serialization

| Library  | Characteristics    | Performance |
|----------|--------------------|-------------|
| serde    | Standard selection | High        |
| bincode  | Binary, compact    | Highest     |
| postcard | no_std, embedded   | High        |
| ron      | Human-readable     | Medium      |

```rust
use serde::{Serialize, Deserialize};

#[derive(Serialize, Deserialize)]
struct User {
 id: u64,
 name: String,
}

// JSON
let json = serde_json::to_string(&user)?;

// Binary
let bytes = bincode::serialize(&user)?;
```

---

## HTTP Client

| Library | Characteristics |
|-----|------|
| reqwest | Most popular, easy to use |
| ureq | Sync, simple |
| surf | Async, modern |

```rust
// reqwest
let response = reqwest::Client::new()
 .post("https://api.example.com")
 .json(&payload)
 .send()
 .await?;
```

---

## Database

| Type         | Library               |
|--------------|-----------------------|
| ORM          | sqlx, diesel, sea-orm |
| Raw SQL      | sqlx, tokio-postgres  |
| NoSQL        | mongodb, redis        |
| Connect pool | sqlx, deadpool, r2d2  |

---

## Concurrency and parallelism

| Scenario      | Recommendation                |
|---------------|-------------------------------|
| Data Parallel | rayon                         |
| Work stealing | crossbeam, tokio              |
| Channels      | tokio::sync, crossbeam, flume |
| Atomics       | std::sync::atomic             |

---

## Error handling

| Library   | Use                 |
|-----------|---------------------|
| thiserror | Library error types |
| anyhow    | Application errors  |
| snafu     | Structured errors   |

---

## Common tooling

| Scenario      | Library              |
|---------------|----------------------|
| Command line  | clap (v4), structopt |
| Logging       | tracing, log         |
| Configuration | config, dotenvy      |
| Testing       | tempfile, rstest     |
| Time          | chrono, time         |

---

## Crate selection principles

1. Maintenance: GitHub activity and last update
2. Downloads: crates.io stats
3. MSRV: minimum supported Rust version
4. Dependencies: quantity and safety
5. Docs: completeness and examples
6. License: MIT/Apache compatibility

---

## Prefer modern alternatives

| Abandon              | Recommendations        | Reason                  |
|----------------------|------------------------|-------------------------|
| `lazy_static`        | `std::sync::OnceLock`  | std internal            |
| `rand::thread_rng`   | `rand::rng()`          | New API                 |
| `failure`            | `thiserror` + `anyhow` | More popular            |
| `serde_derive`       | `serde`                | Unified import          |
| `parking_lot::Mutex` | std::sync::Mutex       | Good enough, fewer deps |

---

## Authentication

```bash
# Check security
cargo audit

# Check licenses
cargo deny check

# Inspect dependency tree
cargo tree -i serde
```

---

## Quick Reference

| Scenario                 | Recommended            |
|--------------------------|------------------------|
| Web Services             | axum + tokio + sqlx    |
| CLI Tools                | clap + anyhow          |
| Serialization            | serde + (json/bincode) |
| Parallel calculations    | rayon                  |
| Configuration Management | config + dotenvy       |
| Logging                  | tracing                |
| Tests                    | tempfile + proptest    |
| Date/time                | chrono                 |
