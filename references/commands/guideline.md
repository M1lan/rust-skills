---
name: guideline
description: "Query coding standards and best practices"
category: coding-standard
triggers: ["guideline", "style", "naming"]
related_skills:
 - rust-coding
 - rust-anti-pattern
 - rust-learner
---

# Guideline Command

## Functional description

Query Rust coding standards and best practices, including:

- Naming conventions
- Code style
- Comment requirements
- Module organization

## Usage

```bash
# View all guidelines
./scripts/guideline.sh

# Query specific categories
./scripts/guideline.sh --category naming
./scripts/guideline.sh --category comments
./scripts/guideline.sh --category modules
```

## Naming conventions

### Variables and functions

```rust
// ✅ Recommended
let item_count = 42;
fn calculate_total() {}

// ❌ Avoid
let cnt = 42;
fn calc() {}
```

### Constants and types

```rust
// ✅ Recommended
const MAX_CONNECTIONS: u32 = 100;
struct UserSession;

// ❌ Avoid
const max = 100;
struct user_session;
```

### Modules and paths

```rust
// ✅ Recommended
mod network_config;
use crate::models::User;

// ❌ Avoid
mod NetworkConfig;
use self::models::User;
```

## Code style

| Standard    | Requirement |
|-------------|-------------|
| Line width  | ≤100 chars  |
| Indentation | 4 spaces    |
| Braces      | K&R style   |

## Related skills

- `rust-coding` - Coding standards
- `rust-anti-pattern` - Anti-pattern recognition
