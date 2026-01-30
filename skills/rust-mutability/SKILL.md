---
name: rust-mutability
description: "Mutability and interior mutability: E0596/E0499/E0502, Cell/RefCell, Mutex/RwLock, borrow conflicts"
globs: ["**/*.rs"]
---

# Mutability and Interior Mutability

## Core issues

**Key question:** Does the data need to change, and who controls the change?

Mutability changes program state and requires careful design.

---

## Mutability types

| Type | Controller | Thread-safe | Use case |
|-----|-------|---------|---------|
| `&mut T` | External caller | Yes | Standard mutable borrowing |
| `Cell<T>` | Internal | No | Copy-type interior mutability |
| `RefCell<T>` | Internal | No | Non-Copy interior mutability |
| `Mutex<T>` | Internal | Yes | Cross-thread interior mutability |
| `RwLock<T>` | Internal | Yes | Many readers, few writers |

---

## The rules

```
At any time:
├─ Many `&T` (immutable borrows)
└─ Or one `&mut T` (mutable borrow)

They cannot coexist.
```

---

## Error code quick check

| Error Code | Meaning | Don't say | Ask |
|-------|------|--------|------|
| E0596 | Cannot borrow mutably | "add mut" | Does this need to change? |
| E0499 | Multiple mutable borrows | "split borrows" | Is the data structured correctly? |
| E0502 | Mutable + immutable overlap | "separate scopes" | Why do you need both at once? |
| RefCell panic | Runtime borrow error | "use try_borrow" | Is runtime checking acceptable? |

---

## When to use interior mutability

```rust
// Situation 1: mutate from &self
struct Config {
 counters: RefCell<HashMap<String, u32>>,
}

impl Config {
 fn increment(&self, key: &str) {
     // Borrow mutably via RefCell
     let mut counters = self.counters.borrow_mut();
     *counters.entry(key.to_string()).or_insert(0) += 1;
 }
}

// Situation 2: Copy type
struct State {
 count: Cell<u32>,
}

impl State {
 fn increment(&self) {
     self.count.set(self.count.get() + 1);
 }
}
```

---

## Thread safety selection

```rust
// Simple counter → Atomic Type
let counter = AtomicU64::new(0);

// Complex Data → Mutex or RwLock
let data = Mutex::new(HashMap::new());

// Many reads, some writes → RwLock
let data = RwLock::new(HashMap::new());
```

---

## Common problems

### Borrow conflict

```rust
// ❌ Borrow conflict
let mut s = String::new();
let r1 = &s;
let r2 = &s;
let r3 = &mut s; // Conflict!

// ✅ Separate fields
let mut s = String::new();
{
    let r1 = &s;
    // Use r1
}
let r3 = &mut s;
// Use r3
```

### RefCell panic

```rust
// ❌ Double mutable borrow
let cell = RefCell::new(vec![]);
let mut_borrow = cell.borrow_mut();
let another = cell.borrow(); // panic!

// ✅ Use try_borrow to avoid panic
if let Ok(mut_borrow) = cell.try_borrow_mut() {
 // Safe use
}
```

---

## Design checklist

1. Is mutation necessary?
 - Could you return a new value instead?
 - Can it be immutable?

2. Who controls mutation?
 - External caller
 - Internal logic (interior mutability)
 - Thread-safe synchronization

3. Concurrency scope?
 - Single-thread
 - Multi-thread

---

## Follow-up

If conflicts persist:

```
E0499/E0502 (borrow conflict)
 ↑ Ask: is the data structure right?
 ↑ rust-type-driven: should we split the data?
 ↑ rust-concurrency: is async involved?
```
