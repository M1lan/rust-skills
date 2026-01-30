# Side-by-side comparison: Tokio vs async-std

Rust async programming requires a runtime to execute futures. This document compares common runtimes.

## Mainstream run-time comparison

| Feature | Tokio | async-std | smol | async-executor |
|----------|-------|-----------|----------|----------------|
| Downloads | ~50M | ~8M | ~2M | ~1M |
| Stability | Stable | Stable | Experimental | Stable |
| Performance | High | Medium | High | High |
| Ecosystem | Rich | General | Growing | Lightweight |

## Tokio

### Characteristics

- **Most popular:** largest ecosystem and docs
- **Feature-rich:** I/O, timers, file systems, networking
- **Multi-threaded:** default runtime flavor
- **Low latency:** optimized for performance

### Basic use

```rust
use tokio::{time, net::TcpListener, sync::Mutex};

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
 // Spawn a task.
 tokio::spawn(async {
 // Async code
 });

 // Timer
 time::sleep(std::time::Duration::from_secs(1)).await;

 // Async mutex
 let lock = Mutex::new(0);
 let mut guard = lock.lock().await;
 *guard += 1;

 Ok(())
}
```

### Runtime configuration

```rust
#[tokio::main(flavor = "multi_thread", worker_threads = 4)]
async fn main() {
 // Multi-threaded runtime with 4 workers
}

#[tokio::main(flavor = "current_thread")]
async fn main() {
 // Single-threaded runtime
}
```

## async-std

### Characteristics

- **Std-like API:** similar to std
- **Consistency:** close to std naming
- **Lightweight:** fewer dependencies
- **Easy to integrate:** fits existing projects

### Basic use

```rust
use async_std::{net::TcpListener, sync::Mutex};

#[async_std::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
 // Spawn a task.
 async_std::spawn(async {
 // Async code
 });

 // Async mutex.
 let lock = Mutex::new(0).await;
 let mut guard = lock.lock().await;
 *guard += 1;

 Ok(())
}
```

## Selection recommendations

### Selection of Tokio

```rust
// 1. Production web services
// tokio is the most mature choice.

// 2. High-performance networking
// tokio has strong networking performance.

// 3. Full ecosystem support
// tokio::spawn, tokio::time, tokio::fs, etc.

// 4. Multi-threaded runtime
// tokio's multi-threaded scheduler is mature.
```

### When to choose async-std

```rust
// 1. Std-like API preference
// Prefer std naming conventions.

// 2. Lightweight dependency set
// Project wants fewer dependencies than tokio.

// 3. Learning or smaller projects
// async-std stays close to std style.
```

### Select smol

```rust
// 1. Extreme demand
// smol Is the smallest run time

// 2. Need to interoperate with other running times
// smol You can embed in other running times

// 3. Pilot projects
// smol Support for the latest rectangular properties
```

## Performance comparison

### Task Creation Costs

```rust
// Tokio: Create task with low cost
tokio::spawn(async {
 // Lightweight task
});

// async-std: Similar expenses
async_std::spawn(async {
 // Lightweight task
});
```

### Channel performance

```rust
// Tokio mpsc Channels
use tokio::sync::mpsc;
let (tx, rx) = mpsc::channel(100);

// async-std mpsc Channels
use async_std::channel;
let (tx, rx) = channel::bounded(100);
```

## Interoperability

### Run async-std in tokio

```rust
use tokio::runtime::Runtime;

fn main() {
 let rt = Runtime::new().unwrap();
 rt.block_on(async {
 async_std::task::sleep(std::time::Duration::from_secs(1)).await;
 });
}
```

### Run tokio in async-std

```rust
use async_std::task;

fn main() {
 task::block_on(async {
 tokio::time::sleep(std::time::Duration::from_secs(1)).await;
 });
}
```

## Recommended Configuration

### Web Service Configuration

```rust
// Cargo.toml
[dependencies]
tokio = { version = "1.0", features = ["full"] }
axum = "0.7"
sqlx = "0.7"

[profile.release]
lto = true
codegen-units = 1
```

### Lightweight Configuration

```rust
// Cargo.toml
[dependencies]
async-std = { version = "1.0", features = ["attributes"] }
surf = "2.0"

[dependencies.tokio]
version = "1.0"
features = ["rt", "time"]
optional = true
```

## Common problems

### Q: Can you mix different running times?

A: Multiple run-times are not recommended for the same project. Each run-time has its own scheduler, and mixed use can cause problems.

### Q: When do you need to customize running time?

```rust
// High-performance scenarios may require custom configuration
use tokio::runtime::Builder;

fn main() {
 let rt = Builder::new()
 .threaded_hammer() // Optimizing Thread Creation
 .worker_threads(16) // Increase Threads
 .max_blocking_threads(512) // Increase blocking threads
 .build()
 .unwrap();

 rt.block_on(async {
 // Apply Code
 });
}
```

### Q: How do you test the async code?

```rust
#[cfg(test)]
mod tests {
 use tokio::test as tokio_test;

 #[tokio_test]
 async fn test_async_function() {
 // Test the step code
 }

 #[async_std::test]
 async fn test_async_std_function() {
 // Test async-std Code
 }
}
```
