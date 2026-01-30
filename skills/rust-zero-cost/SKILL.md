---
name: rust-zero-cost
description: "Zero-cost abstractions: generics, monomorphization, static vs dynamic dispatch, impl Trait vs dyn Trait"
globs: ["**/*.rs"]
---

# Zero-Cost Abstractions

## Core issues

**Key question:** Do you want static or dynamic dispatch?

Selecting the right abstract layer directly affects performance.

---

## Generics vs trait objects

| Feature | Generics (static dispatch) | Trait object (dynamic dispatch) |
|-----|----------------------|--------------------------------|
| Performance | Zero cost | vtable call overhead |
| Code size | Can grow | Smaller |
| Compile time | Longer | Shorter |
| Flexibility | Types known at compile time | Runtime selection |
| Heterogeneous collections | Not supported | `Vec<Box<dyn Trait>>` |

---

## When to use generics

```rust
// Type known at the time of compilation
fn process<T: Processor>(item: T) {
 item.process();
}

// Return a concrete type
fn create_processor() -> impl Processor {
 // Return a concrete type
}

// Multiple Type Parameters
fn combine<A: Display, B: Display>(a: A, b: B) -> String {
 format!("{} and {}", a, b)
}
```

---

## When to use trait objects

```rust
// Runtime-chosen type
trait Plugin {
 fn run(&self);
}

struct PluginManager {
 plugins: Vec<Box<dyn Plugin>>,
}

// Heterogeneous collection
let handlers: Vec<Box<dyn Handler>> = vec![
 Box::new(HttpHandler),
 Box::new(GrpcHandler),
];
```

---

## Object safety rules

```rust
// ❌ Not object-safe
trait Bad {
 fn create(&self) -> Self; // Returns Self
 fn method(&self, x: Self); // Uses Self in args
}

// ✅ Object-safe
trait Good {
 fn name(&self) -> &str;
}
```

---

## impl Trait vs dyn Trait

```rust
// impl Trait: returns a concrete type (static dispatch)
fn create_processor() -> impl Processor {
 HttpProcessor
}

// dyn Trait: returns a trait object (dynamic dispatch)
fn create_processor() -> Box<dyn Processor> {
 Box::new(HttpProcessor)
}
```

---

## Performance impact

```rust
// Generics: generate code for each type
fn process<T: Trait>(item: T) {
 item.method();
}
// After compilation:
// fn process_Http(item: Http) { ... }
// fn process_Ftp(item: Ftp) { ... }

// Trait object: single call path
fn process(item: &dyn Trait) {
 item.method(); // vtable call
}
```

---

## Common Errors

| Error | Reason | Fix |
|-----|------|-----|
| E0277 | Missing trait bound | Add `T: Trait` |
| E0038 | Trait object not safe | Check object safety rules |
| E0308 | Type mismatch | Unify types or use generics |
| E0599 | Impl not found | Implement trait or check bounds |

---

## Optimization strategy

1. **Hot paths use generics** - eliminate dynamic dispatch overhead
2. **Plugin systems use dyn** - flexibility first
3. **Small collections use generics** - avoid Box allocations
4. **Large collections use dyn** - reduce code bloat
