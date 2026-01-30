---
name: rust-features
description: "Query Rust version features"
category: version-info
triggers: ["feature", "edition", "version"]
related_skills:
 - rust-learner
 - rust-coding
---

# Rust Features Command

## Functional description

Query feature support across Rust versions and editions.

## Usage

```bash
# View current version features
./scripts/rust-features.sh --current

# Query a specific edition
./scripts/rust-features.sh --edition 2021

# Compare versions
./scripts/rust-features.sh --compare 1.70 1.78
```

## Edition features

### Rust 2015

- Basic ownership system
- Lifetime annotations
- Trait bounds

### Rust 2018

- `?` operator stabilized
- Module system improvements
- async/await foundation

### Rust 2021

- `try` blocks stabilized
- Stricter type coercions
- Closure capture improvements

## Common features

| Feature        | Stable version | Use                     |
|----------------|----------------|-------------------------|
| async/await    | 1.39           | Async programming       |
| const generics | 1.51           | Compile-time evaluation |
| never type `!` | 1.41           | Diverging functions     |
| union          | 1.19           | Low-level unions        |

## Related skills

- `rust-learner` - Version learning
- `rust-coding` - Coding standards
