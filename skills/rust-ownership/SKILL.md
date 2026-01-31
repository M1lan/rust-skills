---
name: rust-ownership
description: "Ownership, borrowing, and lifetimes. Covers common errors (E0382, E0597, E0506, E0507, E0515, E0716, E0106). Triggers: ownership, borrow, lifetime, move, clone, Copy"
globs: ["**/*.rs"]
---

# Ownership and Lifetimes

## Core message

Each value has a single clear owner.

This is Rust's most distinctive design. Understanding ownership is half of Rust.

---

## Common problem patterns

### Pattern 1: Use after moving

```rust
let s1 = String::from("hello");
let s2 = s1;
// println!("{}", s1); // Compiler error!
```

**Root cause:** ownership of `s1` moved to `s2`, so `s1` is no longer valid.

**Solution:**

- If you need two copies, clone explicitly.
- If you only need to read, borrow (`&str` / `&String`).
- If the move is temporary, redesign the flow to avoid it.

### Pattern 2: Borrow conflict

```rust
let mut s = String::from("hello");
let r1 = &s;
let r2 = &mut s; // Conflict!
// println!("{}", r1);
```

**Root cause:** immutable and mutable borrows coexist.

**Solution:**

- Use immutable borrows first, then mutable borrows.
- Reorder code to end immutable borrows before mutating.

### Pattern 3: Lifetime mismatch

```rust
fn longest<'a>(s1: &'a str, s2: &'a str) -> &'a str {
 if s1.len() > s2.len() { s1 } else { s2 }
}
```

**Root cause:** the return value must be tied to one of the inputs.

**Key steps:**

1. Identify each reference's lifetime.
2. Express relationships with named lifetimes.
3. Prefer returning owned data when practical.

---

## Thinking process

### 1. Who has the data?

| Situation           | Owner                             |
|---------------------|-----------------------------------|
| Function parameters | Caller owns                       |
| Function locals     | Function owns (dropped on return) |
| Struct fields       | Struct instance owns              |
| `Arc<T>`            | Shared ownership                  |

### 2. Is borrowing appropriate?

| Operation                                          | Borrow type      | Notes                             |
|----------------------------------------------------|------------------|-----------------------------------|
| Read-only                                          | `&T`             | Many immutable borrows allowed    |
| Mutation                                           | `&mut T`         | Only one mutable borrow at a time |
| Will the original value be mutated while borrowed? | If yes, redesign |  |

### 3. Can lifetimes be avoided?

```text
Return owned types instead of &str
 ↓
Use owned data instead of slicing borrowed data
 ↓
Use Arc/Rc for shared ownership
 ↓
Only add lifetimes when necessary
```

---

## Smart pointer selection

| Scenario                | Choice              | Reason                            |
|-------------------------|---------------------|-----------------------------------|
| Single owner            | `Box<T>`            | Simple heap allocation            |
| Shared in one thread    | `Rc<T>`             | Cheap ref counting                |
| Shared across threads   | `Arc<T>`            | Atomic ref counting               |
| Runtime borrow checking | `RefCell<T>`        | Single-thread interior mutability |
| Cross-thread mutability | `Mutex` or `RwLock` | Thread-safe interior mutability   |

---

## Anti-patterns

| Anti-pattern                | Problem                 | Better                         |
|-----------------------------|-------------------------|--------------------------------|
| `.clone()` everywhere       | Hides ownership issues  | Design ownership intentionally |
| `'static` everywhere        | Too loose and imprecise | Use real lifetimes             |
| `Box::leak()`               | Memory leaks            | Use proper ownership           |
| Fighting the borrow checker | Wastes time             | Align with the model           |

---

## Practical recommendations

### Common beginner questions

1. **"When do I borrow vs own?"**
- Borrow for read-only access.
- Own when you need to store or mutate long-term.
- Return owned types to avoid lifetime complexity.

1. **"When do I need explicit lifetimes?"**
- Most cases are inferred.
- Structs/traits returning references often need explicit names.
- Use meaningful names like `'src`, `'ctx`.

1. **"Why doesn't this borrow work?"**
- The original value is inaccessible during a mutable borrow.
- Limit the borrow's scope.
- Reorder code to end borrows earlier.

---

## Error code quick check

| Error Code | Meaning                                 | Don't say         | Ask                               |
|------------|-----------------------------------------|-------------------|-----------------------------------|
| E0382      | Use after move                          | "just clone"      | Who should own the data?          |
| E0597      | Borrowed value doesn't live long enough | "extend lifetime" | Is the scope correct?             |
| E0506      | Mutate while borrowed                   | "end borrow"      | Where should mutation happen?     |
| E0507      | Move out of borrowed content            | "clone it"        | Why move from a borrow?           |
| E0515      | Return reference to local data          | "return owned"    | Should callers own it?            |
| E0716      | Temporary value dropped too early       | "bind it"         | Why is this temporary?            |
| E0106      | Missing lifetime parameters             | "add 'a"          | What's the lifetime relationship? |

---

## Design-oriented thinking

When ownership issues persist, work through:

1. **What role does the data play?**
- Entity (unique identity)
- Value object (interchangeable)
- Temporary calculation

1. **Is the ownership design intentional?**
- Intentional: work within the model
- Accidental: redesign the data flow

1. **Patch or redesign?**
- If you tried three times, redesign.

---

## Trace up

When ownership errors persist, go up to the design level:

```text
E0382 (moved value)
 ↑ Question: what design choices led to this ownership pattern?
 ↑ Ask: is this an entity or a value object?
 ↑ Ask: what other constraints exist?

Persistent E0382 → rust-resource: should this be Arc/Rc?
Persistent E0597 → rust-type-driven: is the boundary correct?
E0506/E0507 → rust-mutability: do you need interior mutability?
```

---

## Trace down

From design decisions to implementation:

```text
"Data must be shared"
 ↓ Multi-thread: Arc<T>
 ↓ Single-thread: Rc<T>

"Data needs exclusive ownership"
 ↓ Return owned values

"Data is only used temporarily"
 ↓ Use references within scope

"Need to transfer data between functions"
 ↓ Consider lifetimes or return owned
```
