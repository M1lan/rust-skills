---
name: rust-resource
description: "Smart pointers and resource management: Box, Rc, Arc, Weak, RefCell, Cell, interior mutability, RAII, Drop, heap allocation, reference counting"
globs: ["**/*.rs"]
---

# Smart pointer and resource management

## Core issues

Key question: How should this resource be managed?

Selecting the right smart pointer is one of the core decisions of Rust
programming.

---

## Selection decision tree

```text
Need to share data?
 │
 ├─ No → Single owner
 │ ├─ Need heap allocation? → Box<T>
 │ └─ Stack is fine → plain value
 │
 └─ Yes → Shared ownership
 │
 ├─ Single-thread?
 │ ├─ Mutable? → Rc<RefCell<T>>
 │ └─ Read-only? → Rc<T>
 │
 └─ Multi-thread?
     ├─ Mutable? → Arc<Mutex<T>> or Arc<RwLock<T>>
     └─ Read-only? → Arc<T>
```

---

## Smart pointer comparison

| Type         | Ownership    | Thread-safe | Use case                                        |
|--------------|--------------|-------------|-------------------------------------------------|
| `Box<T>`     | Single owner | Yes         | Heap allocation, recursive types, trait objects |
| `Rc<T>`      | Shared       | No          | Single-thread sharing, avoid cloning            |
| `Arc<T>`     | Shared       | Yes         | Multi-thread sharing, read-only data            |
| `Weak<T>`    | Weak         | -           | Break cycles                                    |
| `RefCell<T>` | Single owner | No          | Runtime borrow checking                         |
| `Cell<T>`    | Single owner | No          | Copy-type interior mutability                   |

---

## Common errors and solutions

### Rc cycle leak

```rust
// ❌ Memory leak: Rc cycle
struct Node {
 value: i32,
 next: Option<Rc<Node>>,
}

// ✅ Solution: use Weak to break cycles
struct Node {
 value: i32,
 next: Option<Weak<Node>>,
}
```

### RefCell panic

```rust
// ❌ Runtime panic: double borrow
let cell = RefCell::new(vec![1, 2, 3]);
let mut_borrow = cell.borrow_mut();
let another_borrow = cell.borrow(); // panic!

// ✅ Solution: use try_borrow
if let Ok(mut_borrow) = cell.try_borrow_mut() {
 // Safe use
}
```

### Arc overhead complaints

```rust
// ❌ Unnecessary Arc: single-threaded environment
let shared = Arc::new(data);

// ✅ Single-thread Rc
let shared = Rc::new(data);

// ❌ Unnecessary atomic ops
// If you don't need cross-thread sharing, don't use Arc
```

---

## Interior mutability selection

```rust
// Copy type → Cell
struct Counter {
 count: Cell<u32>,
}

// Non-Copy → RefCell
struct Container {
 items: RefCell<Vec<Item>>,
}

// Multi-thread → Mutex or RwLock
struct SharedContainer {
 items: Mutex<Vec<Item>>,
}
```

---

## RAII and Drop

```rust
struct File {
 handle: std::fs::File,
}

impl Drop for File {
 fn drop(&mut self) {
 // Automatically release resources
 println!("File closed");
 }
}

// Use guard pattern to ensure cleanup
struct Guard<'a> {
 resource: &'a Resource,
}

impl Drop for Guard<'_> {
 fn drop(&mut self) {
 self.resource.release();
 }
}
```

---

## Performance hints

| Scenario              | Recommendation                          |
|-----------------------|-----------------------------------------|
| Lots of small objects | Use `Rc::make_mut()` to avoid clones    |
| Read-heavy            | `RwLock` over `Mutex`                   |
| Counters              | Use `AtomicU64` instead of `Mutex<u64>` |
| Cache                 | Consider `moka` or `cached`             |

---

## When you don't need a smart pointer

- Stack allocation is enough → use plain values
- Borrowing is sufficient → use `&T`
- Lifetimes are simple → avoid over-abstraction
