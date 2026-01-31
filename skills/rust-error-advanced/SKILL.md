---
name: rust-error-advanced
description: "Advanced error handling: thiserror vs anyhow, error context, library vs application errors, Result/Option usage, and when to panic"
globs: ["**/*.rs"]
---

# Advanced Error Handling

## Core issues

**Key question:** Is this an expected failure or a bug?

Your error-handling strategy determines how robust the code is.

---

## Result vs Option vs panic

| Type             | When to use                 | Example:                         |
|------------------|-----------------------------|----------------------------------|
| `Result<T, E>`   | Operations expected to fail | Document reading, web requests   |
| `Option<T>`      | Absence is normal           | Lookups that may be empty        |
| `panic!`         | Bug or invariant violation  | Logic error, unrecoverable state |
| `unreachable!()` | Impossible code path        | Exhaustive match fallback        |

---

## Error-handling decision tree

```text
Was failure expected?
 │
 ├─ Yes → Is this library code?
 │   ├─ Yes → thiserror (typed errors)
 │   └─ No  → anyhow (ease of use + context)
 │
 ├─ Yes, but absence is normal → Option<T>
 │
 └─ No → bug or invariant violation → panic!/assert!
```

---

## thiserror (library errors)

```rust
use thiserror::Error;

#[derive(Error, Debug)]
pub enum MyError {
    #[error("validation failed: {0}")]
    Validation(String),

    #[error("IO error: {source}")]
    Io {
        #[from]
        source: std::io::Error,
    },

    #[error("not found: {entity}:{id}")]
    NotFound {
        entity: String,
        id: u64,
    },
}

// Propagate with `?`
fn read_config() -> Result<Config, MyError> {
    let content = std::fs::read_to_string("config.toml")?;
    Ok(toml::from_str(&content)?)
}
```

---

## anyhow (application errors)

```rust
use anyhow::{Context, Result, bail};

fn process_user(id: u64) -> Result<User> {
    let user = db
        .find_user(id)
        .with_context(|| format!("failed to find user {}", id))?;

    if !user.is_active {
        bail!("user {} is not active", id);
    }

    Ok(user)
}

// Combining multiple error sources
fn complex_operation() -> Result<()> {
    let a = operation_a().context("operation A failed")?;
    let b = operation_b().context("operation B failed")?;
    Ok(())
}
```

---

## Error design guidelines

| Scene                 | Recommendation                       |
|-----------------------|--------------------------------------|
| Library code          | thiserror with precise, typed errors |
| Application code      | anyhow for convenience + context     |
| Third-party errors    | Convert via `#[from]`                |
| Need error categories | Add error variants                   |
| Need error context    | `context()` / `with_context()`       |

---

## Common anti-patterns

| Anti-pattern                | Problem              | Solve                    |
|-----------------------------|----------------------|--------------------------|
| `unwrap()` in libraries     | Panics in production | Use `?` and typed errors |
| `Box<dyn Error>` everywhere | Weak diagnostics     | Use thiserror variants   |
| Lost context                | Hard to debug        | Add `.context()`         |
| Too many variants           | Overdesigned         | Simplify or consolidate  |

---

## When to use panic

```rust
// 1. Public API invariant checks
pub fn divide(a: f64, b: f64) -> f64 {
    if b == 0.0 {
        panic!("division by zero"); // Caller must not pass 0
    }
    a / b
}

// 2. Unrecoverable error
fn start_engine() {
    let config = load_critical_config();
    if config.is_corrupted() {
        panic!("cannot start without valid config");
    }
}

// 3. Match exhaustiveness (theoretically unreachable)
fn process_status(status: Status) {
    match status {
        Status::Running => { /* ... */ }
        Status::Stopped => { /* ... */ }
        // Possible new status in the future
        // _ => unreachable!("unknown status: {:?}", status),
    }
}

// 4. Internal invariants
assert!(!queue.is_empty(), "queue should never be empty here");
```

---

## Error propagation patterns

```rust
// Use map_err to convert errors
fn high_level() -> Result<()> {
    low_level().map_err(|e| MyError::from_low_level(e, "high level operation failed"))
}

// Use with_context to add call-chain context
fn middle_layer() -> Result<()> {
    low_level()
        .with_context(|| format!("while processing request {}", request_id))?;
    Ok(())
}
```

---

## Best practices

1. Library code: use precise error types (thiserror).
2. Application code: prioritize ease of use (anyhow).
3. Error conversion: use `#[from]` for consistent propagation.
4. Add context: `context()` / `with_context()` for diagnostics.
5. Preserve sources: keep the underlying error with `#[from]`.
6. Panic only for bugs: expected failures should be `Result`/`Option`.
