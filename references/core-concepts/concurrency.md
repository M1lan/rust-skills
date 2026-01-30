# Concurrency

Rust's type system enforces memory safety and prevents data races at compile
time.

## Send and Sync

### Send - transferable across threads

```rust
// Send types:
// - Most owned types (String, Vec, etc.)
// - Types whose fields are all Send
// - References &T where T: Sync

// ❌ Not Send: Rc<T> (non-atomic ref count)
```

### Sync - shareable across threads

```rust
// Sync types:
// - &T where T: Sync
// - Mutex<T> where T: Send + Sync
// - Atomic types

// ❌ Not Sync: RefCell<T> (runtime borrow checking is not thread-safe)
```

## Basic Threads

### Create Thread

```rust
use std::thread;
use std::time::Duration;

fn main() {
 let handle = thread::spawn(|| {
 for i in 1..=5 {
 println!("Thread: {}", i);
 thread::sleep(Duration::from_millis(100));
 }
 });

 for i in 1..=5 {
 println!("Main: {}", i);
 thread::sleep(Duration::from_millis(100));
 }

 handle.join().unwrap(); // Waiting for thread to complete
}
```

### Move value to thread

```rust
fn main() {
 let v = vec![1, 2, 3];

 let handle = thread::spawn(move || {
 println!("Vector: {:?}", v);
 });

 handle.join().unwrap();
 // v Moved,Cannot use here
}
```

## Shared Status

### Mutex - Cross-Lock

```rust
use std::sync::{Arc, Mutex};
use std::thread;

fn main() {
 let counter = Arc::new(Mutex::new(0));
 let mut handles = vec![];

 for _ in 0..10 {
 let counter = Arc::clone(&counter);
 let handle = thread::spawn(move || {
 let mut num = counter.lock().unwrap();
 *num += 1;
 });
 handles.push(handle);
 }

 for handle in handles {
 handle.join().unwrap();
 }

 println!("Result: {}", *counter.lock().unwrap());
}
```

### RwLock - Multireading Book

```rust
use std::sync::{Arc, RwLock};
use std::thread;

fn main() {
 let data = Arc::new(RwLock::new(0));
 let mut handles = vec![];

 // Multiple Readers
 for _ in 0..5 {
 let data = Arc::clone(&data);
 let handle = thread::spawn(move || {
 let value = data.read().unwrap();
 println!("Read: {}", value);
 });
 handles.push(handle);
 }

 // Single author
 {
 let mut value = data.write().unwrap();
 *value += 100;
 println!("Writing: {}", value);
 }

 for handle in handles {
 handle.join().unwrap();
 }
}
```

## Message transmission

### Channels

```rust
use std::sync::mpsc;
use std::thread;

fn main() {
 let (tx, rx) = mpsc::channel();

 let tx1 = tx.clone();
 let handle1 = thread::spawn(move || {
 tx1.send("From Thread 1 Greetings.").unwrap();
 });

 let handle2 = thread::spawn(move || {
 tx.send("From Thread 2 Greetings.").unwrap();
 });

 for _ in 0..2 {
 println!("Copy that.: {}", rx.recv().unwrap());
 }

 handle1.join().unwrap();
 handle2.join().unwrap();
}
```

### Send multiple values

```rust
use std::sync::mpsc;
use std::thread;

fn main() {
 let (tx, rx) = mpsc::channel();

 thread::spawn(move || {
 for i in 1..=5 {
 tx.send(i).unwrap();
 thread::sleep(std::time::Duration::from_millis(100));
 }
 drop(tx); // The signal's over.
 });

 for received in rx {
 println!("Copy that.: {}", received);
 }

 println!("Channel closed.");
}
```

## Atomic Type

### Basic atomic type

```rust
use std::sync::atomic::{AtomicUsize, Ordering};
use std::thread;

fn main() {
 let counter = AtomicUsize::new(0);
 let mut handles = vec![];

 for _ in 0..10 {
 let counter = &counter;
 let handle = thread::spawn(move || {
 counter.fetch_add(1, Ordering::SeqCst);
 });
 handles.push(handle);
 }

 for handle in handles {
 handle.join().unwrap();
 }

 println!("Counter: {}", counter.load(Ordering::SeqCst));
}
```

### Atom Order

```rust
use std::sync::atomic::{AtomicBool, Ordering};

// Relaxed - Unordered,But atom operations
// Acquire - and Release Sync
// Release - and Acquire Sync
// SeqCst - Order consistency(Strongest,Default)

fn example(ordering: Ordering) {
 let flag = AtomicBool::new(false);

 // Mostly. SeqCst To be correct.
 flag.store(true, Ordering::SeqCst);
 flag.load(Ordering::SeqCst);
}
```

## Scope

### std::thread::scope

```rust
use std::thread;

fn main() {
 let mut numbers = vec![1, 2, 3];

 thread::scope(|s| {
 s.spawn(|| {
 println!("Length: {}", numbers.len());
 });

 s.spawn(|| {
 numbers.push(4); // Allow Variable Access!
 });
 });

 // numbers It's still here. - There's a line.
 println!("Numbers: {:?}", numbers);
}
```

## We're moving together

### Tokio

```rust
use tokio::task;
use tokio::time::{sleep, Duration};

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
 let handle = task::spawn(async {
 for i in 1..=5 {
 println!("Different task: {}", i);
 sleep(Duration::from_millis(100)).await;
 }
 "Completed!"
 });

 println!("Waiting for task to be completed...");
 let result = handle.await?;
 println!("Result: {}", result);

 Ok(())
}
```

### Async channels

```rust
use tokio::sync::mpsc;

#[tokio::main]
async fn main() {
 let (tx, mut rx) = mpsc::channel(32);

 tokio::spawn(async move {
 for i in 1..=5 {
 if tx.send(i).await.is_err() {
 break;
 }
 }
 });

 while let Some(value) = rx.recv().await {
 println!("Received: {}", value);
 }
}
```

### Async Mutex

```rust
use tokio::sync::Mutex;
use std::sync::Arc;

#[tokio::main]
async fn main() {
 let counter = Arc::new(Mutex::new(0));
 let mut tasks = vec![];

 for _ in 0..5 {
 let counter = Arc::clone(&counter);
 let task = tokio::spawn(async move {
 let mut guard = counter.lock().await;
 *guard += 1;
 println!("Counter: {}", *guard);
 });
 tasks.push(task);
 }

 for task in tasks {
 task.await.unwrap();
 }

 println!("Final value [v]: {}", *counter.lock().await);
}
```

## Parallel iteration

```rust
use rayon::prelude::*;

fn main() {
 let numbers: Vec<i32> = (1..=1000).collect();

 let sum: i32 = numbers
 .par_iter()
 .map(|&x| x * x)
 .sum();

 println!("Square: {}", sum);
}
```

## Synchronization primitives

### OnceLock and OnceCell

```rust
use std::sync::OnceLock;

fn get_global_config() -> &'static Config {
 static CONFIG: OnceLock<Config> = OnceLock::new();

 CONFIG.get_or_init(|| {
 Config::load()
 })
}
```

### Barrier

```rust
use std::sync::{Arc, Barrier};
use std::thread;

fn main() {
 let barrier = Arc::new(Barrier::new(10));
 let mut handles = vec![];

 for _ in 0..10 {
 let barrier = barrier.clone();
 let handle = thread::spawn(move || {
 println!("Before the barrier");
 barrier.wait();
 println!("After the barrier");
 });
 handles.push(handle);
 }

 for handle in handles {
 handle.join().unwrap();
 }
}
```

## Best practices

### Do

```rust
// ✅ Use Arc to share ownership
let shared = Arc::new(Data::new());

// ✅ Keep lock scopes small
{
 let data = mutex.lock().unwrap();
 process(&data); // Do not hold a lock while processing
}

// ✅ Use channels for loose coupling
let (tx, rx) = mpsc::channel();

// ✅ Use scoped threads for short-lived work
thread::scope(|s| {
 s.spawn(|| { /* ... */ });
});
```

### Don't

```rust
// ❌ Don't hold a lock across an await point
let mut guard = mutex.lock().unwrap();
some_async_operation().await; // Could deadlock!
drop(guard); // Release first

// ❌ Don't use Rc in multi-threaded code
let rc = std::rc::Rc::new(42);
// thread::spawn(move || println!("{}", rc)); // Error!

// ❌ Don't forget to join threads
let handle = thread::spawn(|| { /* ... */ });
handle.join(); // Always join!
```

## Summary

| Primitive        | Use case                 |
|------------------|--------------------------|
| `thread::spawn`  | Basic threads            |
| `Arc<Mutex<T>>`  | Shared mutable state     |
| `Arc<RwLock<T>>` | Read-write lock          |
| `mpsc::channel`  | Message passing          |
| `Atomic*`        | Lock-free counters/flags |
| `Barrier`        | Thread group sync        |
| `Condvar`        | Wait conditions          |
| `tokio::spawn`   | Async tasks              |
| `rayon`          | Parallel iterators       |
