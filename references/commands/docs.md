---
name: docs
description: "Query Rust official documentation"
category: documentation
triggers: ["docs", "documentation", "api", "API"]
related_skills:
 - rust-learner
 - rust-ecosystem
---

# Docs Command

## Functional description

Quickly query Rust official docs and APIs:

- Standard library docs
- crates.io docs
- Official books/tutorials
- RFCs

## Usage

```bash
# Query std docs
./scripts/docs.sh std Vec

# Query crate docs
./scripts/docs.sh crate serde

# Open local docs
./scripts/docs.sh --local

# Search docs
./scripts/docs.sh --search "iterator"
```

## Common docs

### Standard library

| Module           | Use                        |
|------------------|----------------------------|
| std::collections | Collection types           |
| std::sync        | Synchronization primitives |
| std::future      | Async fundamentals         |
| std::io          | Input/output               |

### Books and tutorials

| Resource        | URL                               |
|-----------------|-----------------------------------|
| Rust Book       | doc.rust-lang.org/book            |
| Rust By Example | doc.rust-lang.org/rust-by-example |
| Async Book      | async-book.cloudshift.tw          |

## Quick queries

```bash
# Query trait usage
./scripts/docs.sh trait From

# Query macro definition
./scripts/docs.sh macro vec!

# Query attributes
./scripts/docs.sh attr derive
```

## Related skills

- `rust-learner` - Learning guide
- `rust-ecosystem` - Crate documentation
