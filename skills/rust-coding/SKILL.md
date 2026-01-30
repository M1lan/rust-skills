---
name: rust-coding
description: "Rust coding standards: naming, formatting, comments, clippy/rustfmt, lints, and best practices"
globs: ["**/*.rs"]
---

# Rust Coding Standards

## Core issues

**Key question:** What does idiomatic Rust look like?

Follow community conventions to keep code readable and maintainable.

---

## Naming (Rust-specific)

| Rule | Correct | Incorrect |
|----------------------|----------------------------------------------|-------------------------|
| Avoid `get_` for simple accessors | `fn name(&self)` | `fn get_name(&self)` |
| Iterator naming | `iter()` / `iter_mut()` / `into_iter()` | `get_iter()` |
| Conversion naming | `as_` (cheap), `to_` (expensive), `into_` (ownership) | Mixed prefixes |
| `static` names are SCREAMING_SNAKE_CASE | `static CONFIG: Config` | `static config: Config` |
| `const` names are SCREAMING_SNAKE_CASE | `const BUFFER_SIZE: usize = 1024` | lowercase |

### Common Naming

```rust
// Variables and functions: snake_case
let max_connections = 100;
fn process_data() { ... }

// Types and traits: CamelCase
struct UserSession;
trait Cacheable {}

// Constants: SCREAMING_SNAKE_CASE
const MAX_CONNECTIONS: usize = 100;
static CONFIG:once_cell::sync::Lazy<Config> = ...
```

---

## Data types

| Rule | Notes | Example |
|---------------|----------------|---------------------------------------------------|
| Use newtype | Field syntax | `struct Email(String)` |
| Use slice patterns | Pattern match | `if let [first, .., last] = slice` |
| Pre-allocate | Avoid reallocations | `Vec::with_capacity()`, `String::with_capacity()` |
| Avoid Vec for fixed size | Use arrays | `let arr: [u8; 256]` |

### String

| Rule | Notes |
|-------------------------|------------------------------|
| ASCII data → `bytes()` | `s.bytes()` is faster than `s.chars()` |
| Use `Cow<str>` when mutating | Borrowed or owned |
| Prefer `format!` over `+` | Clearer and often faster |
| Avoid repeated `contains()` | Can be O(n*m) |

---

## Error handling

| Rule | Notes |
|----------------------------|------------------|
| Propagate with `?` | No need for `try!()` |
| Prefer `expect()` over `unwrap()` | When a message helps |
| Use `assert!` for invariants | Function entry checks |

```rust
// ✅ Good error management.
fn read_config() -> Result<Config, ConfigError> {
    let content = std::fs::read_to_string("config.toml")
        .map_err(ConfigError::from)?;
    toml::from_str(&content).map_err(ConfigError::parse)
}

// ❌ Avoid
fn read_config() -> Config {
    std::fs::read_to_string("config.toml").unwrap() // panic!
}
```

---

## Memory and lifetimes

| Rule | Notes |
|---------------------------|--------------------------|
| Use descriptive lifetimes | `'src`, `'ctx` instead of `'a` |
| Prefer `try_borrow` for `RefCell` | Avoid panic |
| Use shadowing for conversions | `let x = x.parse()?` |

---

## Concurrency rules

| Rule | Notes |
|------------------|--------------------------------|
| Define lock order | Avoid deadlocks |
| Use atomics for simple flags | `AtomicBool` instead of `Mutex<bool>` |
| Choose memory order carefully | Relaxed/Acquire/Release/SeqCst |

---

## Async code

| Rule | Notes |
|---------------------|-------------------|
| CPU-bound → use threads | Async is best for I/O |
| Don't hold locks across await | Use scoped guards |

---

## Macros

| Rule | Notes |
|--------------------|-----------------|
| Avoid macros unless they help | Prefer functions or generics |
| Macro input should read like Rust | Prioritize readability |

---

## Prefer modern alternatives

| Abandon | Recommendations | Version |
|-------------------------|-----------------------|------|
| `lazy_static!` | `std::sync::OnceLock` | 1.70 |
| `once_cell::Lazy` | `std::sync::LazyLock` | 1.80 |
| `std::sync::mpsc` | `crossbeam::channel` | - |
| `std::sync::Mutex` | `parking_lot::Mutex` | - |
| `failure`/`error-chain` | `thiserror`/`anyhow` | - |
| `try!()` | `?` operator | 2018 |

---

## Clippy Code

```toml
[package]
edition = "2024"
rust-version = "1.85"

[lints.rust]
unsafe_code = "warn"

[lints.clippy]
all = "warn"
pedantic = "warn"
```

### Common Clippy Rules

| Lint | Annotations |
|----------------------------|----------------|
| `clippy::all` | Enable all warnings |
| `clippy::pedantic` | More stringent checks |
| `clippy::unwrap_used` | Avoid unwrap |
| `clippy::expect_used` | Priority |
| `clippy::clone_on_ref_ptr` | Avoid clone Arc |

---

## Formatting (rustfmt)

```bash
# Use default configuration
rustfmt src/lib.rs

# Check Format
rustfmt --check src/lib.rs

# Profile .rustfmt.toml
max_line_width = 100
tab_spaces = 4
edition = "2024"
```

---

## Document Regulation

```rust
/// Module documents
//! This module handles user authentication...

/// Structure Document
///
/// # Examples
/// ```
/// let user = User::new("name");
/// ```
pub struct User { ... }

/// Method Document
///
/// # Arguments
///
/// * `name` - Username
///
/// # Returns
///
/// User instance after initialization
///
/// # Panics
///
/// When user name is empty panic
pub fn new(name: &str) -> Self { ... }
```

---

## Quick Reference

```
Name: snake_case (fn/var), CamelCase (type), SCREAMING_CASE (const)
Format: rustfmt (just use it)
Document: /// for public items, //! for module docs
Lint: #![warn(clippy::all)]
```

---

## Code review checklist

- [ ] Naming follows Rust conventions
- [ ] Use `?` instead of `unwrap()` in fallible code
- [ ] Avoid unnecessary `clone()`
- [ ] Every `unsafe` block has a SAFETY comment
- [ ] Public APIs are documented
- [ ] Run `cargo clippy`
- [ ] Run `cargo fmt`
