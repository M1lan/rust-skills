---
name: rust-learner
description: "Learning and ecosystem guide: new versions, crate updates, best practices, RFCs, and weekly news. Triggers: latest version, what's new, Rust version, new features, update, upgrade, RFC, weekly news, learning"
globs: ["**/*.toml", "**/Cargo.lock"]
---

# Rust Learning and Ecosystem Tracking

## Core issues

**Key question:** How do we keep up with Rust's pace?

Rust publishes a new release every six weeks. The ecosystem moves quickly.

---

## Version update policy

### Stable Update

```bash
# Check current version
rustc --version

# Update Rust
rustup update stable

# View changelog
rustup changelog stable
```

### When should you update?

| Scenario | Recommendation |
|-----|------|
| New projects | Use the latest stable |
| Production | Update on the 6-week cycle (after testing) |
| Libraries | Follow an MSRV policy |

### MSRV (Minimum Supported Rust Version)

```toml
[package]
rust-version = "1.70" # Declaration Minimum Supported Version

[dependencies]
# MSRV changes require care across your dependency graph.
serde = { version = "1.0", default-features = false }
```

---

## Learning path for new features

### 2024 Edition Important Features

| Feature | Stable version | Practicality |
|-----|---------|-------|
| `gen blocks` | nightly | ⭐ Experimental |
| `async drop` | nightly | ⭐ Experimental |
| `inline const` | 1.79+ | ✅ Stable |
| `never type` improvements | 1.82+ | ⭐⭐⭐ Common |

### Learning progression

```
Foundation → Ownership, borrowing, lifetimes
 ↓
Intermediate → Trait objects, enums, error handling
 ↓
Concurrency → async/await, threads, channels
 ↓
Advanced → unsafe, FFI, performance
 ↓
Expert → macros, type system, API design
```

---

## Stay up to date

### Official channels

| Channel | Contents | Frequency |
|-----|------|-----|
| [This Week in Rust](https://this-week-in-rust.org/) | Weekly news, RFCs, blogs | Weekly |
| [Rust Blog](https://blog.rust-lang.org/) | Major announcements, deep dives | Occasional |
| [Rust RFCs](https://github.com/rust-lang/rfcs) | Design discussions | Ongoing |
| [Release Notes](https://github.com/rust-lang/rust/blob/master/RELEASES.md) | Version changes | Every 6 weeks |

### Community resources

| Resources | Contents |
|-----|------|
| [docs.rs](https://docs.rs/) | API docs search |
| [crates.io](https://crates.io/) | Package registry |
| [lib.rs](https://lib.rs/) | Curated crate discovery |
| [Rust Analyzer](https://rust-analyzer.github.io/) | IDE plugin |

---

## Dependency update management

### General update

```bash
# Check dependency updates
cargo outdated

# Update minor versions
cargo update

# Force minimal versions (nightly cargo feature)
cargo update -Z direct-minimal-versions
```

### Security audit

```bash
# Check known loopholes
cargo audit

# Check for licences.
cargo deny check licenses
```

---

## My Update Policy

### Quarterly

- [ ] Upgrade to latest status
- [ ] Run `cargo outdated`
- [ ] Run `cargo audit`
- [ ] Check dependent breaking changes
- [ ] Assess whether new features are worth adopting

### Once a year

- [ ] Consider upgrading
- [ ] Reconstruct the old mode code
- [ ] Assessment of MSRV strategies
- [ ] Update the development tool chain

---

## Recommendations for learning resources

### Introduction

- The Rust Programming Language — official book
- Rust by Example — example-driven tutorial

### Progress

- The Rust Reference — language reference
- The Rustonomicon — unsafe Rust guide
- Effective Rust — best practices

### Actual

- Exercism Rust Track
- Rust by Practice
