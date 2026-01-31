---
name: rust-error
description: "Error handling specialist: Result vs Option, panic, anyhow, thiserror, custom errors, and propagation. Triggers: Result, Error, panic, ?, unwrap, expect, anyhow, thiserror"
globs: ["**/*.rs"]
---

# Rust Error Handling

## Core issues

**Key question:** Is this an expected failure or a bug?

- Expected failure → `Result`
- Absence is normal → `Option`
- Bug / unrecoverable → `panic!`

---

## Result vs Option

### `Option` for "absence is normal"

```rust
// Lookups may legitimately return nothing.
fn find_user(id: u32) -> Option<User> {
    users.get(&id)
}

// Use
let user = find_user(123);
if let Some(u) = user {
    println!("Found: {}", u.name);
}

// Or propagate with `?` (after wrapping in Result).
let user = find_user(123).ok_or(UserNotFound)?;
```

### `Result` for "possible failure"

```rust
// File may not exist
fn read_file(path: &Path) -> Result<String, io::Error> {
    std::fs::read_to_string(path)
}

// Network requests may be timed out
fn fetch(url: &str) -> Result<Response, reqwest::Error> {
    reqwest::blocking::get(url)?
}
```

---

## Error type selection

### Library Code

```rust
use thiserror::Error;

#[derive(Error, Debug)]
pub enum ParseError {
 #[error("invalid format: {0}")]
 InvalidFormat(String),

 #[error("missing field: {0}")]
 MissingField(&'static str),

 #[error("IO error: {source}")]
 Io {
 #[from]
 source: io::Error,
 },
}
```

### Application code

```rust
use anyhow::{Context, Result, bail};

fn process_config() -> Result<Config> {
    let content = std::fs::read_to_string("config.json")
        .context("failed to read config file")?;

    let config: Config = serde_json::from_str(&content)
        .context("failed to parse config")?;

    Ok(config)
}
```

### Mixed scenario

Inside libraries, prefer thiserror. In applications, use anyhow for speed and context.

---

## Error propagation best practices

```rust
// ✅ Good: distinct error type
fn validate() -> Result<(), ValidationError> {
    if name.is_empty() {
        return Err(ValidationError::EmptyName);
    }
    Ok(())
}

// ✅ Good: add context during propagation
let config = File::open("config.json")
    .map_err(|e| ConfigError::with_context("config", e))?;

// ✅ Good: use the `?` operator
let data = read_file(&path)?;

// ❌ Bad: unwrap() in a fallible operation
let content = std::fs::read_to_string("config.json").unwrap();

// ❌ Bad: silently ignore errors
let _ = some_fallible_function();
```

---

## When to panic

| Scenario             | Example                              | Rationale                       |
|----------------------|--------------------------------------|---------------------------------|
| Invariant violation  | Profile validation failed            | Program cannot safely continue  |
| Initialization check | `EXPECTED_ENV.is_set()`              | Configuration must be valid     |
| Test assertions      | `assert_eq!`                         | Verify assumptions              |
| Unrecoverable state  | Connection unexpectedly disconnected | Prefer crashing over corruption |

```rust
// ✅ Accepted: initialization check
let home = std::env::var("HOME")
    .expect("HOME environment variable must be set");

// ✅ Accepted: test assertion
assert!(!users.is_empty(), "should have at least one user");

// ❌ Not acceptable: user input parse failure
let num: i32 = input.parse().unwrap();
```

---

## Anti-patterns

| Anti-pattern                | Problem              | Better                   |
|-----------------------------|----------------------|--------------------------|
| `.unwrap()` everywhere      | Panics in production | `?` or `context()`       |
| `Box<dyn Error>` everywhere | Weak diagnostics     | Use a named error type   |
| Silently ignore errors      | Bugs are hidden      | Handle or propagate      |
| Too many variants           | Overdesigned         | Simplify the error model |
| Panic for control flow      | Misuse of panic      | Use normal control flow  |

---

## Quick Reference

| Scenario                      | Choice                           | Tools               |
|-------------------------------|----------------------------------|---------------------|
| Library returns custom error  | `Result<T, Enum>`                | thiserror           |
| Application quick development | `Result<T, anyhow::Error>`       | anyhow              |
| Absence is normal             | `Option<T>`                      | `None` / `Some(x)`  |
| Expected panic                | `panic!` / `assert!`             | Only for invariants |
| Error conversion              | `.map_err()` / `.with_context()` | Add context         |
