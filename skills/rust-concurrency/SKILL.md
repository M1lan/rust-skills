---
name: rust-concurrency
description: "Concurrency and async expert. Covers Send/Sync, threads, async/await, tokio, channels, Mutex/RwLock, deadlocks, race conditions. Triggers: thread, spawn, channel, mpsc, Mutex, RwLock, Atomic, async, await, Future, tokio, deadlock, race condition"
globs: ["**/*.rs"]
---

# Concurrency and Async

## Core issues

**Key question:** How do we pass data safely across threads and tasks?

Concurrency is about coordinating parallel work. Rust's type system provides strong guarantees here.

---

## Threads vs async

| Dimension | Threads | Async |
|-----|--------------|-------------|
| Memory | Each thread has its own stack | Tasks share a runtime and reuse stacks |
| Blocking | Blocks an OS thread | Does not block; yields to the runtime |
| Use case | CPU-bound work | I/O-bound work |
| Complexity | Simpler model | More complex scheduling |

---

## Send/Sync quick judgement

### Send - transfer of ownership across threads

```
Primitive types → auto Send
References → auto Send if T: Sync
Raw pointers → not Send
Rc → not Send (non-atomic ref count)
```

### Sync - share references across threads

```
&T where T: Sync → Auto Sync
RefCell → not Sync (runtime borrow checking is not thread-safe)
MutexGuard → not Sync (not implemented)
```

---

## Common patterns

### 1. Shared mutability

```rust
use std::sync::{Arc, Mutex};

let counter = Arc::new(Mutex::new(0));
let mut handles = vec![];

for _ in 0..10 {
    let counter = Arc::clone(&counter);
    let handle = std::thread::spawn(move || {
        let mut num = counter.lock().unwrap();
        *num += 1;
    });
    handles.push(handle);
}

for handle in handles {
    handle.join().unwrap();
}
```

### 2. Message passing

```rust
use std::sync::mpsc;

let (tx, rx) = mpsc::channel();

thread::spawn(move || {
    tx.send("hello").unwrap();
});

println!("{}", rx.recv().unwrap());
```

### 3. Async tasks

```rust
use tokio;

#[tokio::main]
async fn main() {
    let handle = tokio::spawn(async {
        // A different task.
    });

    handle.await.unwrap();
}
```

---

## Common errors and fixes

| Error | Reason | Solve |
|-----|-----|-----|
| E0277 Send not satisfied | Contains a non-Send type | Check field types or wrap with Arc/Mutex |
| E0277 Sync not satisfied | Shared type is not Sync | Use Mutex/RwLock or redesign sharing |
| Deadlock | Lock ordering differs | Enforce a consistent lock order |
| MutexGuard across await | Holding a lock while awaiting | Drop the lock before `await` |

---

## Performance considerations

- Keep lock granularity small.
- Prefer RwLock when reads dominate writes.
- Atomics are lighter than locks but only for simple updates.
- Message passing avoids shared state but may increase copying.
