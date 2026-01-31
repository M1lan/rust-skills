---
name: rust-coroutine
description: "Coroutines and green threads: generators, suspend/resume, stackful vs stackless coroutines, context switching. Triggers: coroutine, green thread, generator, suspend, resume, context switch"
globs: ["**/*.rs"]
---

# Coroutines and Green Threads

## Core issues

Key question: How do we implement efficient lightweight concurrency?

Coroutines provide user-space context switching and avoid kernel-thread
overhead.

---

## Coroutines vs threads

| Feature     | OS threads | Coroutines            |
|-------------|------------|-----------------------|
| Scheduling  | Kernel     | User space            |
| Switch cost | ~1μs       | ~100ns                |
| Count       | Thousands  | Hundreds of thousands |
| Stack size  | 1-8MB      | A few KB              |
| Preemption  | Preemptive | Cooperative           |

---

## Rust native generators

```rust
// Generators on nightly Rust
#![feature(generators)]
#![feature(generator_trait)]

use std::ops::Generator;

fn simple_generator() -> impl Generator<Yield = i32, Return = ()> {
    || {
        yield 1;
        yield 2;
        yield 3;
        // Generator completes
    }
}

fn main() {
    let mut gen = simple_generator();
    loop {
        match unsafe { Pin::new_unchecked(&mut gen).resume() } {
            GeneratorState::Yielded(v) => println!("Yielded: {}", v),
            GeneratorState::Complete(()) => {
                println!("Done!");
                break;
            }
        }
    }
}
```

---

## Stackful coroutine

```rust
// Using a stackful coroutine library
use corosensei::{Coroutine, Pin, Unpin};

fn runner<'a>(start: bool, coroutine: &'a Coroutine<'_, ()>) {
    if start {
        println!("Starting coroutine");
        coroutine.run();
    }
}

fn main() {
    let coroutine = Coroutine::new(|_| {
        println!("  In coroutine - 1");
        corosensei::yield!();
        println!("  In coroutine - 2");
        corosensei::yield!();
        println!("  In coroutine - 3");
    });

    let mut pin = Pin::new(&coroutine);
    unsafe { pin.as_mut().set_running(true) };

    println!("Main: first resume");
    unsafe { pin.resume(false) }; // false = not the first time

    println!("Main: second resume");
    unsafe { pin.resume(false) };

    println!("Main: third resume");
    unsafe { pin.resume(false) };

    println!("Main: done");
}
```

---

## Stackful coroutine patterns

### 1. Coroutine state machine

```rust
enum CoroutineState {
    Init,
    Processing,
    Waiting,
    Done,
}

struct StatefulCoroutine {
    state: CoroutineState,
    data: Vec<u8>,
}

impl StatefulCoroutine {
    fn new() -> Self {
        Self {
            state: CoroutineState::Init,
            data: Vec::new(),
        }
    }

    fn step(&mut self) {
        match self.state {
            CoroutineState::Init => {
                println!("Initialize");
                self.state = CoroutineState::Processing;
            }
            CoroutineState::Processing => {
                println!("Processing data");
                self.state = CoroutineState::Waiting;
            }
            CoroutineState::Waiting => {
                println!("Waiting for I/O");
                self.state = CoroutineState::Done;
            }
            CoroutineState::Done => {
                println!("Already done");
            }
        }
    }
}
```

### 2. Coroutine pool

```rust
use std::sync::Arc;
use std::thread;
use std::sync::mpsc;

struct CoroutinePool {
    workers: Vec<thread::JoinHandle<()>>,
    sender: mpsc::Sender<Job>,
}

struct Job {
    data: Vec<u8>,
    result_tx: mpsc::Sender<Result<Vec<u8>, ()>>,
}

impl CoroutinePool {
    pub fn new(size: usize) -> Self {
        let (sender, receiver) = mpsc::channel();
        let receiver = Arc::new(receiver);

        let workers = (0..size)
            .map(|_| {
                let receiver = Arc::clone(&receiver);
                thread::spawn(move || {
                    while let Ok(job) = receiver.recv() {
                        // Process job
                        let result = process_job(&job);
                        let _ = job.result_tx.send(result);
                    }
                })
            })
            .collect();

        Self { workers, sender }
    }

    pub fn submit(&self, data: Vec<u8>) -> mpsc::Receiver<Result<Vec<u8>, ()>> {
        let (result_tx, result_rx) = mpsc::channel();
        let job = Job { data, result_tx };
        self.sender.send(job).unwrap();
        result_rx
    }
}

fn process_job(job: &Job) -> Result<Vec<u8>, ()> {
    Ok(job.data.clone())
}
```

---

## Stackless coroutine

```rust
// Use async/await to implement stackless coroutines
async fn async_task(id: u32) -> u32 {
    println!("Task {} started", id);

    // Simulate I/O
    tokio::time::sleep(std::time::Duration::from_millis(100)).await;

    println!("Task {} resumed", id);
    id * 2
}

async fn main() {
    // Run multiple coroutines concurrently
    let results = futures::future::join_all(
        (0..10).map(|i| async_task(i))
    ).await;

    println!("Results: {:?}", results);
}
```

---

## Context switching mechanism

```rust
// Manual context switching
use std::arch::asm;

struct Context {
    rsp: u64,
    r15: u64,
    r14: u64,
    r13: u64,
    r12: u64,
    rbp: u64,
    rbx: u64,
}

impl Context {
    unsafe fn new(stack: &mut [u8]) -> Self {
        let stack_top = stack.as_mut_ptr().add(stack.len());
        let rsp = (stack_top as *mut u64).wrapping_sub(1) as u64;

        Self {
            rsp,
            r15: 0,
            r14: 0,
            r13: 0,
            r12: 0,
            rbp: 0,
            rbx: 0,
        }
    }

    unsafe fn switch(&mut self, next: &mut Context) {
        asm!(
            "push rbx",
            "push rbp",
            "push r12",
            "push r13",
            "push r14",
            "push r15",
            "mov [rdi], rsp",     // Save current stack pointer
            "mov rsp, [rsi]",     // Switch to new stack
            "pop r15",
            "pop r14",
            "pop r13",
            "pop r12",
            "pop rbp",
            "pop rbx",
            in("rdi") self as *mut Context,
            in("rsi") next as *mut Context,
        );
    }
}
```

---

## Coroutine scheduler

```rust
// Simple coroutine scheduler
enum Task {
    Coroutine(fn(&mut Scheduler)),
    Finished,
}

struct Scheduler {
    ready: Vec<Task>,
    current: Option<Task>,
}

impl Scheduler {
    pub fn new() -> Self {
        Self {
            ready: Vec::new(),
            current: None,
        }
    }

    pub fn spawn(&mut self, task: Task) {
        self.ready.push(task);
    }

    pub fn run(&mut self) {
        while let Some(task) = self.ready.pop() {
            self.current = Some(task);
            match std::mem::replace(&mut self.ready, vec![]) {
                Task::Coroutine(f) => f(self),
                Task::Finished => continue,
            }
        }
    }
}
```

---

## Common problems

| Problem               | Cause                | Fix                           |
|-----------------------|----------------------|-------------------------------|
| Coroutine doesn't run | Missing scheduler    | Implement or use a scheduler  |
| Stack overflow        | Recursion too deep   | Use heap-allocated stacks     |
| Memory leak           | Task never completes | Clean up coroutines correctly |
| Deadlock              | Circular waiting     | Avoid cyclic dependencies     |

---

## Related skills

```text
rust-coroutine
    │
    ├─► rust-async → async/await implementation
    ├─► rust-concurrency → concurrency model
    └─► rust-performance → performance optimization
```
