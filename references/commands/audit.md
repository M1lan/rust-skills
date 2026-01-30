---
name: audit
description: "Security audits and vulnerability detection"
category: security
triggers: ["audit", "security", "vulnerability", "safety"]
related_skills:
 - rust-unsafe
 - rust-ffi
 - rust-coding
---

# Audit Command

## Functional description

Security audit for Rust projects, checking:

- Dependency vulnerabilities
- Code security risks
- Privacy leaks
- Permission issues

## Usage

```bash
# Full audit
./scripts/audit.sh

# Dependencies only
./scripts/audit.sh --deps

# Code only
./scripts/audit.sh --code

# Generate report
./scripts/audit.sh --report html
```

## Checks

### 1. Dependency security

```bash
cargo audit
# Check known vulnerabilities
```

### 2. Code risks

```rust
// Checkpoints
// - unsafe usage
// - cryptography choices
// - random number generation
// - permission control
```

### 3. Privacy compliance

```rust
// Checkpoints
// - logging sensitive data
// - data storage security
// - network transport encryption
```

## Risk levels

| Level    | CVSS    | Action          |
|----------|---------|-----------------|
| Critical | ≥9.0    | Fix immediately |
| High     | 7.0-8.9 | Prioritize      |
| Medium   | 4.0-6.9 | Plan fixes      |
| Low      | <4.0    | Fix as needed   |

## Related skills

- `rust-unsafe` - Unsafe safety
- `rust-ffi` - Cross-language safety
- `rust-coding` - Coding standards
