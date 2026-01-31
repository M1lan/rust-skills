---
name: rust-async
description: "Advanced async patterns: Stream, backpressure, select!, join!, cancellation, Future. Triggers: async, Stream, backpressure, select, Future, tokio, async-std, cancel"
globs: ["**/*.rs"]
---

# Advanced Async Patterns

## Core issues

Key question: How do we handle flow control and resources correctly in async
code?

Async is not the same as parallelism, and it introduces its own complexity.

---

## Stream processing

```rust
use tokio_stream::{self as Stream, StreamExt};

async fn process_stream(stream: impl Stream<Item = Data>) {
    stream
        .chunks(100) // Batch processing
        .for_each(|batch| async {
            process_batch(batch).await;
        })
        .await;
}
```

### Backpressure

```rust
use tokio::sync::Semaphore;

let semaphore = Semaphore::new(10); // At most 10 concurrent tasks.

let stream = tokio_stream::iter(0..1000)
    .map(|i| {
        let permit = semaphore.clone().acquire_owned();
        async move {
            let _permit = permit.await;
            process(i).await
        }
    })
    .buffer_unordered(100); // At most 100 concurrent items.
```

---

## select! and timeouts

```rust
use tokio::select;
use tokio::time::{sleep, timeout};

async fn multiplex() {
    loop {
        select! {
            msg = receiver.recv() => {
                if let Ok(msg) = msg {
                    handle(msg).await;
                }
            }
            _ = sleep(Duration::from_secs(5)) => {
                // Timeout handling
            }
            else => break, // All branches complete.
        }
    }
}
```

---

## Task cancellation

```rust
use tokio::time::timeout;

async fn with_timeout() -> Result<Value, TimeoutError> {
    timeout(Duration::from_secs(5), long_operation()).await
}

// Cooperative cancellation
let mut task = tokio::spawn(async move {
    loop {
        // Check cancellation flag
        if task.is_cancelled() {
            return;
        }
        // Keep working.
    }
});

// Force-cancel
task.abort();
```

---

## join! vs try_join

```rust
// Run in parallel, wait for both
let (a, b) = tokio::join!(async_a(), async_b());

// Short-circuit on error
let (a, b) = tokio::try_join!(async_a(), async_b())?;

// Propagate errors
fn combined() -> impl Future<Output = Result<(A, B), E>> {
    async {
        let (a, b) = try_join!(op_a(), op_b())?;
        Ok((a, b))
    }
}
```

---

## Common errors

| Error                | Reason                     | Solve                                        |
|----------------------|----------------------------|----------------------------------------------|
| Missing `.await`     | Future not polled          | Add `.await`                                 |
| Ignored cancellation | Tasks run forever          | Add cancellation checks                      |
| No backpressure      | Unbounded concurrency      | Use Semaphore/buffer                         |
| Deadlock             | Holding locks across await | Drop locks before `await`                    |
| Detached tasks       | Resource leaks             | Use `tokio::spawn` carefully and track joins |

---

## Performance hints

- Prefer bounded concurrency over unbounded fan-out.
- `buffer_unordered` is more flexible; `buffered` preserves ordering.
- Batching reduces overhead.
- Minimize lock usage in async code.
