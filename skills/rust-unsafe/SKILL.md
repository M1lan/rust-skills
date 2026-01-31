---
name: rust-unsafe
description: "Unsafe code and FFI expert. Covers unsafe, raw pointers, FFI, extern, transmute, *mut/*const, union, #[repr(C)], libc, MaybeUninit, NonNull, SAFETY comments, soundness, UB, memory layout"
globs: ["**/*.rs"]
---

# Unsafe Code and FFI

## Core issues

Key question: When can we use unsafe, and how do we keep it safe?

Unsafe is necessary, but must be used with care.

---

## When can we use unsafe?

| Use case                            | Example                                                      | Allowed               |
|-------------------------------------|--------------------------------------------------------------|-----------------------|
| FFI calls to C                      | `extern "C" { fn libc_malloc(size: usize) -> *mut c_void; }` | ✅                    |
| Low-level abstractions              | `Vec`, `Arc` internals                                       | ✅                    |
| Performance optimization (measured) | Hot paths with evidence                                      | ⚠️ Validate carefully  |
| Avoiding borrow checker             | "Because it's annoying"                                      | ❌                    |

---

## SAFETY comment requirements

Every unsafe block must include SAFETY notes:

```rust
// SAFETY: ptr must be non-null and properly aligned.
// This function is only called after a null check.
unsafe { *ptr = value; }

/// # Safety
///
/// * `ptr` must be properly aligned and not null
/// * `ptr` must point to initialized memory of type T
/// * The memory must not be accessed after this function returns
pub unsafe fn write(ptr: *mut T, value: &T) { ... }
```

---

## Unsafe rules quick check (47)

### General principles (3)

| Rule | Notes                                                   |
|------|---------------------------------------------------------|
| G-01 | Don't use unsafe to bypass the compiler's safety checks |
| G-02 | Don't use unsafe blindly for performance                |
| G-03 | Don't create aliases named "Unsafe" for types/methods   |
|      |                                                         |

### Memory layout (6)

| Rule | Notes                                            |
|------|--------------------------------------------------|
| M-01 | Choose appropriate layout for struct/tuple/enum  |
| M-02 | Don't modify memory owned by other processes     |
| M-03 | Don't let String/Vec free memory owned elsewhere |
| M-04 | Prefer re-entrant C APIs or syscalls             |
| M-05 | Use third-party crates for bitfields             |
| M-06 | Use `MaybeUninit<T>` for uninitialized memory    |

### Raw pointers (6)

| Rule | Notes                                              |
|------|----------------------------------------------------|
| P-01 | Don't share raw pointers across threads            |
| P-02 | Prefer `NonNull<T>` over `*mut T`                  |
| P-03 | Use `PhantomData<T>` to express ownership/variance |
| P-04 | Don't deref casts to misaligned types              |
| P-05 | Don't cast const to mut without guarantees         |
| P-06 | Prefer `ptr::cast` over `as`                       |

### Unions (2)

| Rule | Notes                                               |
|------|-----------------------------------------------------|
| U-01 | Avoid union except for C interop                    |
| U-02 | Don't use union variants across different lifetimes |
|      |                                                     |

### FFI (18)

| Rule | Notes                                                   |
|------|---------------------------------------------------------|
| F-01 | Avoid passing strings directly to C                     |
| F-02 | Read `std::ffi` docs carefully                          |
| F-03 | Implement Drop for wrapped C pointers                   |
| F-04 | Handle panics across FFI boundaries                     |
| F-05 | Use portable type aliases in `std`/`libc`               |
| F-06 | Ensure C-ABI string compatibility                       |
| F-07 | Don't implement Drop for types passed to foreign code   |
| F-08 | Handle errors correctly in FFI                          |
| F-09 | Use references in safe wrappers instead of raw pointers |
| F-10 | Exported functions must be thread-safe                  |
| F-11 | Be careful with `repr(packed)` field references         |
| F-12 | Document invariants for C parameters                    |
| F-13 | Ensure consistent layout for custom types               |
| F-14 | Use stable layouts for FFI types                        |
| F-15 | Validate external inputs defensively                    |
| F-16 | Separate data and code for C callbacks                  |
| F-17 | Use opaque types instead of `c_void`                    |
| F-18 | Avoid passing trait objects to C                        |

### Safety abstractions (11)

| Rule | Notes                                                  |
|------|--------------------------------------------------------|
| S-01 | Consider panic-related memory safety issues            |
| S-02 | Unsafe authors must validate safety invariants         |
| S-03 | Don't expose uninitialized memory in public APIs       |
| S-04 | Avoid double free on panic                             |
| S-05 | Consider safety when implementing auto traits manually |
| S-06 | Don't expose raw pointers in public APIs               |
| S-07 | Provide safe alternatives for performance              |
| S-08 | Returning `&mut` from `&` is wrong                     |
| S-09 | Add SAFETY comments before each unsafe block           |
| S-10 | Add `Safety` sections to public unsafe APIs            |
| S-11 | Use `assert!` (not `debug_assert!`) for invariants     |

### I/O safety (1)

| Rule | Notes                                    |
|------|------------------------------------------|
| I-01 | Ensure I/O safety when using raw handles |
|      |                                          |

---

## Common errors and fixes

| Error                    | Fix                                     |
|--------------------------|-----------------------------------------|
| Null pointer dereference | Check for null before deref             |
| Use-after-free           | Ensure lifetimes are valid              |
| Data races               | Add synchronization or ensure Send/Sync |
| Alignment violations     | Use `#[repr(C)]`, check alignment       |
| Invalid bit patterns     | Use `MaybeUninit`                       |
| Missing SAFETY comment   | Add a comment                           |

---

## Deprecated patterns

| Deprecated                         | Replacement               |
|------------------------------------|---------------------------|
| `mem::uninitialized()`             | `MaybeUninit<T>`          |
| `mem::zeroed()` (reference types)  | `MaybeUninit<T>`          |
| Raw pointer arithmetic             | `NonNull<T>`, `ptr::add`  |
| `CString::new().unwrap().as_ptr()` | Store the `CString` first |
| `static mut`                       | `AtomicT` or `Mutex`      |
| Manual extern bindings             | `bindgen`                 |

---

## FFI tools

| Direction | Tool       |
|-----------|------------|
| C → Rust  | `bindgen`  |
| Rust → C  | `cbindgen` |
| Python    | `PyO3`     |
| Node.js   | `napi-rs`  |

---

## Debug tools

```bash
# Miri: detect undefined behavior
cargo +nightly install miri
cargo miri test

# Memory checks
cargo install valgrind
valgrind ./target/release/my_program

# Data race detection
cargo install helgrind
helgrind ./target/release/my_program
```
