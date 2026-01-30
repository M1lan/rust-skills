---
name: unsafe-check
description: "Unsafe code security checks"
category: code-safety
triggers: ["unsafe", "safety", "FFI"]
related_skills:
 - rust-unsafe
 - rust-ffi
 - rust-ownership
---

# Unsafe Check Command

## Functional description

Check unsafe operations in Rust code to ensure:

- Raw pointer usage is safe
- FFI calls are correct
- Memory layout is correct
- Undefined behavior is prevented

## Usage

```bash
# Security checks
./scripts/unsafe-check.sh

# Generate report
./scripts/unsafe-check.sh --report
```

## Check items

### 1. Raw pointer operations

```rust
// Checkpoints
// - Is the operation inside an unsafe block?
// - Is the pointer null?
// - Are lifetimes correct?
```

### 2. FFI calls

```rust
// Checkpoints
// - extern function declarations are correct
// - Cross-platform compatibility
// - Error handling is complete
```

### 3. Memory safety

```rust
// Checkpoints
// - Send/Sync implemented correctly
// - Borrow rules respected
// - Lifetimes annotated
```

## Severity levels

| Level  | Risk           | Requirement              |
|--------|----------------|--------------------------|
| High   | May cause UB   | Must add SAFETY comments |
| Medium | Potential risk | Review recommended       |
| Low    | Warning        | Fix as needed            |

## Related skills

- `rust-unsafe` - Unsafe coding rules
- `rust-ffi` - Cross-language interop
- `rust-ownership` - Ownership and borrowing
