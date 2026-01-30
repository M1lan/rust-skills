---
name: rust-anti-pattern
description: "Rust anti-patterns and common errors. Triggers: anti-pattern, common mistake, clone, unwrap, code review, refactor"
globs: ["**/*.rs"]
---

# Rust Anti-patterns and Common Errors

## Core issues

**Key question:** Does this code hide a design problem?

Working code can still be non-idiomatic. Use anti-patterns as a guide for refactoring.

---

## Top 5 mistakes

| Rank | Mistake | Better |
|------|----------------------------|------------------------------------|
| 1 | `.clone()` to avoid borrowing | Use references |
| 2 | `.unwrap()` in production | Use `?` or `context()` |
| 3 | `String` everywhere | Use `&str` or `Cow<str>` |
| 4 | Index-based loops | Use `.iter()` / `.enumerate()` |
| 5 | Fighting lifetimes | Redesign data structures |

---

## Common anti-patterns

### Anti-pattern 1: Clone everywhere

```rust
// ❌ Hides borrowing issues
fn process(user: User) {
    let name = user.name.clone(); // Why clone?
 // ...
}

// ✅ Borrow directly
fn process(user: &User) {
    let name = &user.name; // Just borrow it.
}
```

When do you really need a clone?

- You need an independent copy.
- API requires owned values.
- Data must outlive the source.

### Anti-pattern 2: unwrap everywhere

```rust
// ❌ Panics in production
let config = File::open("config.json").unwrap();

// ✅ Propagate errors
let config = File::open("config.json")?;

// ✅ Add context
let config = File::open("config.json")
    .context("failed to open config")?;
```

### Anti-pattern 3: String everywhere

```rust
// ❌ Unnecessary allocation
fn greet(name: String) {
 println!("Hello, {}", name);
}

// ✅ Borrow instead
fn greet(name: &str) {
 println!("Hello, {}", name);
}

// Use String when you need to own or mutate.
```

### Anti-pattern 4: Index loops

```rust
// ❌ Easy to make mistakes, less idiomatic
for i in 0..items.len() {
 println!("{}: {}", i, items[i]);
}

// ✅ Iterate directly
for item in &items {
 println!("{}", item);
}

// ✅ Index required
for (i, item) in items.iter().enumerate() {
 println!("{}: {}", i, item);
}
```

### Anti-pattern 5: Excess unsafe

```rust
// ❌ Unnecessary unsafe
unsafe {
 let ptr = data.as_mut_ptr();
 // ... Complex Memory Operations
}

// ✅ Prefer safe abstractions
let mut data: Vec<u8> = vec![0; size];
// Vec manages memory safely
```

---

## Code smells

| Smell | Implicit question | Fix |
|------------------|--------------|------------------|
| Many `.clone()` | Ownership unclear | Clarify data flow |
| Many `.unwrap()` | Error handling missing | Use Result/Context |
| Many `pub` fields | No encapsulation | Make fields private |
| Deep nesting | Logic is hard to follow | Extract functions |
| Very long functions | Too many responsibilities | Split functions |
| Huge enums | Missing abstraction | Use traits/types |

---

## Outdated patterns

| Obsolete | Modern |
|----------------------------------|-----------------------|
| Index loop `.items[i]` | `.iter().enumerate()` |
| `collect::<Vec<_>>()` too early | Keep iterators lazy |
| `lazy_static!` | `std::sync::OnceLock` |
| `mem::transmute` | `as` or `TryFrom` |
| Custom linked list | `Vec` or `VecDeque` |
| Manual mutation hacks | `Cell`, `RefCell` |

---

## Code review checklist

- [ ] No unnecessary `.clone()`
- [ ] Library code avoids `unwrap()`
- [ ] No `pub` fields without a reason
- [ ] Avoid index loops when iterators work
- [ ] Avoid `transmute` unless strictly necessary
- [ ] Cancellation/cleanup is handled
- [ ] Every `unsafe` has a SAFETY comment
- [ ] No giant functions (>50 lines)

---

## Ask yourself

1. **Is this code fighting Rust?**
 - If yes, redesign.

2. **Is this line necessary?**
 - If it's only to dodge borrowing, rethink the design.

3. **Will this unwrap panic?**
 - Use `?` or `context()` instead.

4. **Is there a more idiomatic way?**
 - Look at std library APIs and community patterns.
