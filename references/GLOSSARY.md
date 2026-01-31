# Rust Terminology Glossary

> Recommended terminology and short notes.

## Core concepts

| English        | Recommended term | Abbreviations | Notes                          |
|----------------|------------------|---------------|--------------------------------|
| Ownership      | Ownership        | -             | Core Rust concept              |
| Borrowing      | Borrowing        | -             |                                |
| Lifetime       | Lifetime         | -             |                                |
| Move           | Move             | -             | Transfer of ownership of value |
| Clone          | Cloning          | -             | Deep Copy                      |
| Copy           | Copy             | -             | Copy in bits                   |
| Borrow Checker | Borrow checker   | -             | Compile-time checking          |

## Type System

| English                   | Recommended term          | Notes                |
|---------------------------|---------------------------|----------------------|
| Trait                     | Trait                     | Similar to interface |
| Generic                   | Generic                   |                      |
| Associated Type           | Associated Type           |                      |
| Generic Associated Type   | Generic Associated Type   | GAT                  |
| Higher-Ranked Trait Bound | Higher-ranked trait bound | HRTB                 |
| Phantom Data              | PhantomData               |                      |
| Smart Pointer             | Smart pointer             |                      |

## Smart Pointer

| English    | Recommended term         | Thread-safe | Notes                   |
|------------|--------------------------|-------------|-------------------------|
| Box<T>     | Box                      | Yes         | Heap allocation         |
| Rc<T>      | Reference-counted        | No          | Single-thread sharing   |
| Arc<T>     | Atomic reference-counted | Yes         | Multi-thread sharing    |
| RefCell<T> | Interior mutability      | No          | Runtime borrow checking |
| Mutex<T>   | Mutex                    | Yes         |                         |
| RwLock<T>  | Read-write lock          | Yes.        |                         |

## Concurrency

| English        | Recommended term       | Notes                 |
|----------------|------------------------|-----------------------|
| Thread         | Thread                 | OS Thread             |
| Async          | Async                  |                       |
| Await          | Await                  |                       |
| Future         | Future values          |                       |
| Send           | Send                   | Cross-thread transfer |
| Sync           | Sync                   | Cross-thread sharing  |
| Channel        | Channel                | Message passing       |
| Spawn          | Spawn                  | Task creation         |
| Deadlock       | Deadlock.              |                       |
| Race Condition | Competition conditions |                       |

## Async runtime

| English   | Recommended term         |
|-----------|--------------------------|
| Tokio     | Tokio (maintain English) |
| async-std | async-std                |
| Runtime   | Runtime                  |
| Executor  | Executor                 |
| Waker     | Waker                    |
| Polling   | Polling                  |

## Memory safety

| English            | Recommended term                 |
|--------------------|----------------------------------|
| Undefined Behavior | Undefined behavior               |
| Memory Safety      | Memory safety                    |
| Soundness          | Soundness                        |
| Unsafe             | Unsafe                           |
| FFI                | FFI (foreign function interface) |
| Raw Pointer        | Raw pointer                      |
| Reference          | Reference                        |

## Error handling

| English     | Recommended term |
|-------------|------------------|
| Panic       | Panic            |
| Result      | Result           |
| Option      | Option           |
| Error       | Error            |
| Propagation | Propagation      |

## Code quality

| English    | Recommended term             |
|------------|------------------------------|
| Benchmark  | Benchmark testing            |
| Profiling  | Performance analysis         |
| Lint       | Linting                      |
| Formatting | Formatting                   |
| Clippy     | Clippy (maintain English)    |
| cargo-fmt  | Cargo-fmt (maintain English) |

## Embedded

| English   | Recommended term                   |
|-----------|------------------------------------|
| no_std    | no_std                             |
| Embedded  | Embedded                           |
| Interrupt | Interrupt                          |
| DMA       | DMA (direct memory access)         |
| ISR       | Interruption of service procedures |
| HAL       | Hardware Abstract Layer            |

## Principles of use

- "Borrow Checker"
- ✅ "Send trait"
