---
name: rust-review
description: "Code quality review tool"
category: code-quality
triggers: ["review", "clippy", "lint", "Review", "Code quality"]
related_skills:
 - rust-coding
 - rust-anti-pattern
 - rust-unsafe
---

# Rust Review command

## Functional description

Quality review of Rust code. Test:
- Code style problem.
- Potential bug
- Performance hazard.
- Violation of best practice

## Use method

```bash
# Review of the whole project
./scripts/review.sh

# Review of designation documents
./scripts/review.sh src/main.rs

# Run only Clippy
cargo clippy --all-targets
```

## Problem classification

| Serious level | Annotations | Treatment of recommendations |
|---------|------|---------|
| 🔴 Error | Compiler error | Fix immediately |
| 🟠 Warning | Potential problems | Prioritize |
| 🟡 Advice | Suggested improvements | Optimize if needed |

## Fixes for common problems

### Clone optimization
```rust
// ❌ Avoid: unnecessary clone
let data = values.clone();

// ✅ Recommendation: borrow or use Rc/Arc
let data = &values;
```

### Unwrap
```rust
// ❌ Avoid: unwrap panic risk
let value = map.get(key).unwrap();

// ✅ Recommendation: pattern match or use unwrap_or
let value = map.get(key).unwrap_or(&default);
```

## Related skills
- Coding standards
- Anti-pattern recognition
