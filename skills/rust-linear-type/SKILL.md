---
name: rust-linear-type
description: "Linear types and resource management: RAII, unique ownership, linear semantics, single-use resources"
globs: ["**/*.rs"]
---

# Linear Types

## Core issues

**Key question:** How do we ensure resources are neither leaked nor freed twice?

Linear-type semantics guarantee each resource is used exactly once.

---

## Linear types vs Rust ownership

| Feature | Rust ownership | Linear types |
|-----|------------|---------|
| Move semantics | ✓ | ✓ |
| Copy semantics | Optional | ✗ |
| Destruction guarantee | Drop | Destructible |
| Borrowing | ✓ | ✗ or restricted |
| Shared ownership | Rc/Arc | ✗ |

Rust is not linear by default, but you can implement linear semantics via patterns.

---

## Destructible trait

```rust
// Core of linear types: Destructible ensures a single drop
use std::mem::ManuallyDrop;

struct LinearBuffer {
    ptr: *mut u8,
    size: usize,
}

impl Drop for LinearBuffer {
    fn drop(&mut self) {
        unsafe {
            std::alloc::dealloc(self.ptr, Layout::array::<u8>(self.size).unwrap());
        }
    }
}

// Prevent double free
struct SafeLinearBuffer {
    inner: ManuallyDrop<LinearBuffer>,
}

impl Drop for SafeLinearBuffer {
    fn drop(&mut self) {
        // Ensure it is released only once
        unsafe {
            ManuallyDrop::drop(&mut self.inner);
        }
    }
}
```

---

## Exclusive object pattern

```rust
// Ensure the object can only be moved, not copied
#[derive(Copy, Clone)]
struct FileHandle(u32);

impl FileHandle {
    // Private constructor to prevent external creation
    fn from_raw(fd: u32) -> Self {
        Self(fd)
    }
}

// Wrap as a linear type
struct LinearFile {
    fd: FileHandle,
}

impl LinearFile {
    pub fn open(path: &str) -> Result<Self, std::io::Error> {
        // Open file, return linear file handle
        Ok(LinearFile {
            fd: FileHandle::from_raw(0), // Example
        })
    }

    // consume() consumes self to guarantee linear use
    pub fn consume(self) -> FileHandle {
        self.fd
    }
}
```

---

## Resource token pattern

```rust
// Linear resource token
struct ResourceToken<T> {
    resource: T,
    consumed: bool,
}

impl<T> ResourceToken<T> {
    pub fn new(resource: T) -> Self {
        Self {
            resource,
            consumed: false,
        }
    }

    // Consume token, return resource
    pub fn consume(mut self) -> T {
        self.consumed = true;
        self.resource
    }

    // Check if consumed
    pub fn is_consumed(&self) -> bool {
        self.consumed
    }
}

// Usage example
fn process_resource(token: ResourceToken<Vec<u8>>) -> Vec<u8> {
    // Handle resource here
    let data = token.consume(); // Token invalid after consumption
    data
}
```

---

## Transactional resource management

```rust
// Two-phase commit pattern
struct Transaction<T> {
    data: T,
    committed: bool,
}

impl<T> Transaction<T> {
    pub fn new(data: T) -> Self {
        Self {
            data,
            committed: false,
        }
    }

    pub fn commit(mut self) -> T {
        self.committed = true;
        self.data
    }

    // Rollback: discard resource
    pub fn rollback(self) {
        // Drop happens automatically
    }
}

// Usage
fn example() -> Result<i32, ()> {
    let tx = Transaction::new(100);

    if condition {
        tx.commit(); // Commit, return data
    } else {
        tx.rollback(); // Roll back, discard
    }
}
```

---

## Unique pointer pattern

```rust
// Linear pointer similar to C++ unique_ptr
struct UniquePtr<T: Sized> {
    ptr: *mut T,
    _marker: std::marker::PhantomData<T>,
}

impl<T> UniquePtr<T> {
    pub fn new(data: T) -> Self {
        let ptr = Box::into_raw(Box::new(data));
        Self {
            ptr,
            _marker: std::marker::PhantomData,
        }
    }

    pub fn as_ref(&self) -> Option<&T> {
        if self.ptr.is_null() {
            None
        } else {
            Some(unsafe { &*self.ptr })
        }
    }

    // Consume self, return Box
    pub fn into_box(self) -> Box<T> {
        unsafe {
            let ptr = self.ptr;
            std::mem::forget(self);
            Box::from_raw(ptr)
        }
    }
}

impl<T> Drop for UniquePtr<T> {
    fn drop(&mut self) {
        if !self.ptr.is_null() {
            unsafe {
                Box::from_raw(self.ptr);
            }
        }
    }
}
```

---

## Linear semantics in Rust

| Scenario | Linear guarantee | Pattern |
|-----|---------|------|
| File handle | Close exactly once | RAII + Drop |
| Network connection | Close exactly once | RAII + Drop |
| Memory allocation | Free exactly once | RAII + Drop |
| Lock | Unlock exactly once | RAII + Drop |
| Transaction | Commit or rollback | Transactional pattern |
| FFI resource | Release exactly once | Resource tokens |

---

## Avoided patterns

| Anti-pattern | Problem | Better |
|-------|------|---------|
| Clone allows copying | Breaks linear semantics | Use move semantics |
| Rc/Arc sharing | Multiple ownership | Use linear tokens |
| Manual lifetime management | Error-prone | RAII + Drop |
| Skipping Drop | Resource leaks | Scope-based APIs |

---

## Related skills

```
rust-linear-type
    │
    ├─► rust-resource → RAII and Drop patterns
    ├─► rust-ownership → ownership patterns
    └─► rust-unsafe → low-level resource operations
```
