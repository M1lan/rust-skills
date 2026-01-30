---
name: rust-const
description: "Const generics and compile-time evaluation: type-level calculations, compile-time checks, MaybeUninit arrays. Triggers: const, generics, compile-time, MaybeUninit"
globs: ["**/*.rs"]
---

# Const Generics and Compile-Time Evaluation

## Core issues

**Key question:** What can be computed at compile time?

Rust's `const fn` lets you run code at compile time.

---

## Basic const generics

```rust
struct Array<T, const N: usize> {
    data: [T; N],
}

let arr: Array<i32, 5> = Array { data: [0; 5] };
```

### Array initialization

```rust
// Fixed-size array on the stack
let arr: [i32; 100] = [0; 100];

// MaybeUninit for uninitialized memory
use std::mem::MaybeUninit;
let mut arr: [MaybeUninit<i32>; 100] = [MaybeUninit::uninit(); 100];

// Use after initialization
unsafe {
    let arr: [i32; 100] = arr.map(|x| x.assume_init());
}
```

---

## const fn

```rust
const fn double(x: i32) -> i32 {
    x * 2
}

const VAL: i32 = double(5); // Computed at compile time

// Compile-time checks
const fn checked_div(a: i32, b: i32) -> i32 {
    assert!(b != 0, "division by zero");
    a / b
}
```

### Current limitations

```rust
// Some operations are not allowed in const fn yet
const fn heap_alloc() -> Vec<i32> {
    Vec::new() // ❌ not yet supported
}

const fn dynamic_size(n: usize) -> [i32; n] {
    // ❌ array size must be const
    [0; n]
}
```

---

## Compile-time checks

```rust
// Array length check
const fn assert_len<T>(slice: &[T], len: usize) {
    assert!(slice.len() == len);
}

// Usage
const _: () = assert_len(&[1, 2, 3], 3); // Compile-time assertion

// Type-level state machine
struct StateMachine<S: State> {
    data: Vec<u8>,
    _phantom: std::marker::PhantomData<S>,
}

trait State {}
struct Initial;
struct Processing;
struct Done;

impl StateMachine<Initial> {
    fn start(self) -> StateMachine<Processing> {
        StateMachine {
            data: vec![],
            _phantom: std::marker::PhantomData,
        }
    }
}
```

---

## Common patterns

| Pattern | Use | Example |
|-----|------|-----|
| Array type | Fixed-size collection | `[T; N]` |
| Buffer size | Avoid dynamic allocation | `const SIZE: usize = 1024` |
| Compile-time checks | Early error detection | `assert!` in const fn |
| Typestate | State machine | `StateMachine<S>` |

---

## MaybeUninit usage

```rust
// Safe initialization pattern
fn init_array<T: Default + Copy>(len: usize) -> Vec<T> {
    let mut vec = Vec::with_capacity(len);
    for _ in 0..len {
        unsafe {
            vec.as_mut_ptr().write(T::default());
        }
    }
    unsafe {
        vec.set_len(len);
    }
    vec
}

// Large array: stack may overflow
fn big_array_on_heap() -> Box<[u8; 1024 * 1024]> {
    Box::new([0; 1024 * 1024])
}
```

---

## Common errors

| Error | Cause | Fix |
|-----|-----|-----|
| Stack overflow | Large array on the stack | Use Box or Vec |
| Array size mismatch | Wrong const generic value | Check constant values |
| const fn not supported | Language limitation | Use runtime or nightly |
| MaybeUninit not initialized | UB | Use `assume_init` correctly |
