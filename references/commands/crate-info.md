---
name: crate-info
description: "Query crate information in the Rust ecosystem"
category: dependency-info
triggers: ["crate", "dependency", "library", "Dependency", "Library"]
related_skills:
 - rust-ecosystem
 - rust-learner
---

# Crate Info command

## Functional description

Search for details of crates in the Rust ecosystem:
- Versions and downloads
- Use statistics
- Maintenance status
- Alternatives

## Use method

```bash
# Query crate information
./scripts/crate-info.sh serde

# View similar comparisons
./scripts/crate-info.sh --compare actix axum

# Find alternatives
./scripts/crate-info.sh --alternatives json
```

## Common crate categories

### Web frameworks
| Crate | Week Downloads | Maintenance status | Characteristics |
|-------|---------|---------|------|
| axum | 500K+ | Active | Modern, type-safe |
| actix-web | 300K+ | Active | High performance |
| rocket | 200K+ | Maintenance | Developer-friendly |

### Serialization
| Crate | Week Downloads | Characteristics |
|-------|---------|------|
| serde | 30M+ | JSON/YAML/TOML |
| bincode | 2M+ | Efficient binary |

### Async runtimes
| Crate | Week Downloads | Characteristics |
|-------|---------|------|
| tokio | 25M+ | Full-featured |
| async-std | 1M+ | std-like API |

## Related skills
- Crate selection
- Ecosystem learning
