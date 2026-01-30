---
name: skill-index
description: "Query all available skills"
category: system
triggers: ["skill", "index", "list"]
related_skills:
 - rust-skill-index
 - rust-learner
---

# Skill Index command

## Functional description

Query all available skills in Rust Skill and display them by category.

## Use method

```bash
# List all skills
./scripts/skill-index.sh

# Query by category
./scripts/skill-index.sh --category core
./scripts/skill-index.sh --category advanced
./scripts/skill-index.sh --category expert

# Search skills
./scripts/skill-index.sh --search ownership
```

## Skills classification

### Core Skills

| Skills           | Description    | Trigger word                |
|------------------|----------------|-----------------------------|
| rust-skill       | Main entrance  | Rust, cargo, compile        |
| rust-ownership   | Ownership      | ownership, borrow, lifetime |
| rust-mutability  | Mutability     | mut, Cell, RefCell          |
| rust-concurrency | Parallel       | thread, async, tokio        |
| rust-error       | Error handling | Result, Error, panic        |

### Advanced Skills

| Skills            | Description              | Trigger word                |
|-------------------|--------------------------|-----------------------------|
| rust-unsafe       | Unsafe Code              | unsafe, FFI, raw pointer    |
| rust-anti-pattern | Anti-pattern             | anti-pattern, clone, unwrap |
| rust-performance  | Performance optimization | performance, benchmark      |
| rust-web          | Web Development          | web, axum, HTTP             |

### Expert Skills

| Skills     | Description             | Trigger word         |
|------------|-------------------------|----------------------|
| rust-ffi   | Calls across languages  | FFI, C, C++, bindgen |
| rust-pin   | Pin and self-references | Pin, Unpin           |
| rust-macro | Macros and proc-macros  | macro, derive        |
| rust-async | Async patterns          | Stream, backpressure |

## Related skills

- `rust-skill-index` - Skills index
- `rust-learner` - Learning guide
