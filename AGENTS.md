# AGENTS.md

This file provides guidance to AI when working with code in this repository.

## Overview

This repository contains the **Rust Skill System** - a comprehensive AI
assistant skill system for Rust programming, providing 36 specialized
sub-skills covering everything from beginner to expert level. The system is
designed for AI agents (Cursor, Claude Code, etc.) to invoke domain-specific
expertise when answering Rust-related questions.

## Repository Architecture

### Skill System Design

The codebase follows a hierarchical skill organization:

```text
rust-skill (Main Entry)
├── Core Skills (7) - Daily development tasks
├── Advanced Skills (10) - Deep understanding and specialized domains
└── Expert Skills (18) - Highly specialized topics
```

Key architectural principles:

1. Skill Routing: Each skill has trigger keywords that automatically route
   questions to the appropriate domain expert
2. Skill Collaboration: Skills reference and build upon each other (e.g.,
   `rust-ownership` → `rust-mutability` → `rust-concurrency`)
3. Problem-Oriented: Skills are organized by problem type rather than API
   surface area
4. MCP Integration: Skills are exposed via Model Context Protocol for seamless
   AI agent integration

### Directory Structure

- `skills/` - 36 skill directories, each containing a `SKILL.md` with
  domain-specific expertise
  - Each skill follows the pattern: `rust-{domain}/SKILL.md`
  - Skills include description, instructions, constraints, tools, and
    references
- `references/` - Comprehensive reference documentation
  - `core-concepts/` - ownership, lifetimes, concurrency, traits
  - `best-practices/` - API design, coding standards, error handling, unsafe
    rules
  - `ecosystem/` - crate recommendations, testing strategies, modern crates
    (2024-2025)
  - `versions/` - Rust edition features (2021, 2024)
  - `commands/` - Command definitions for code review, unsafe checking, etc.
  - `GLOSSARY.md` - Rust terminology reference
- `scripts/` - Development and validation scripts
- `.mcp.json` - MCP server configuration exposing skills, resources, and tools
- `.cursor/rules.md` - Cursor IDE skill trigger rules

### Skill File Format

Each `skills/*/SKILL.md` follows a standard template:

```markdown
## description
[Role definition and expertise scope]

## instructions
[Operational guidelines and patterns]

## constraints
[Must follow / must avoid rules]

## tools
[Associated scripts and commands]

## references
[Links to related reference documentation]
```

## Key Skills by Problem Domain

When working with Rust code, automatically invoke these skills:

### Compilation Errors

- Ownership/lifetime errors → `rust-ownership`
- Borrow conflicts/mutability → `rust-mutability`
- Send/Sync errors → `rust-concurrency`
- HRTB/GAT complex lifetimes → `rust-lifetime-complex`

### Async Programming

- Basic async/await → `rust-concurrency`
- Stream/select/backpressure → `rust-async`
- Advanced patterns/lifetimes → `rust-async-pattern`
- Future & Pin → `rust-pin`

### Systems Programming

- unsafe/memory operations → `rust-unsafe`
- C/C++/Python interop → `rust-ffi`
- no_std/embedded/WASM → `rust-embedded`
- eBPF kernel programming → `rust-ebpf`
- GPU computing → `rust-gpu`

### Web Development

- axum/HTTP/API → `rust-web`
- Middleware/CORS/rate limiting → `rust-middleware`
- JWT/API Key authentication → `rust-auth`
- Redis caching → `rust-cache`
- RBAC/policy engine → `rust-xacml`

### Performance & Optimization

- Benchmarks/SIMD → `rust-performance`
- False sharing/NUMA → `rust-performance`
- Concurrency optimization → `rust-concurrency`

## Development Commands

### Validation Scripts

Located in `scripts/`:

```bash
# Type checking
./scripts/compile.sh
# Equivalent to: cargo check --message-format=short

# Run all tests
./scripts/test.sh
# Equivalent to: cargo test --lib --doc --message-format=short

# Lint with strict warnings
./scripts/clippy.sh
# Equivalent to: cargo clippy -- -D warnings

# Check code formatting
./scripts/fmt.sh
# Equivalent to: cargo fmt --check
```

### Standard Cargo Workflow

```bash
# Fast type checking (use before suggesting fixes)
cargo check

# Optimized build
cargo build --release

# Run library and doc tests
cargo test --lib --doc

# Lint warnings
cargo clippy

# Format code
cargo fmt
```

## Working with Skills

### Skill Trigger Patterns

When encountering Rust questions, match keywords to skills:

| Keywords                                | Triggered Skill       |
|-----------------------------------------|-----------------------|
| ownership, borrow, lifetime             | `rust-ownership`      |
| mut, Cell, RefCell, interior mutability | `rust-mutability`     |
| thread, async, tokio, concurrency       | `rust-concurrency`    |
| Result, Error, panic, error handling    | `rust-error`          |
| thiserror, anyhow, context              | `rust-error-advanced` |
| unsafe, FFI, raw pointer                | `rust-unsafe`         |
| performance, benchmark, SIMD            | `rust-performance`    |
| web, axum, HTTP, API                    | `rust-web`            |
| cache, redis, TTL                       | `rust-cache`          |
| auth, jwt, token, api-key               | `rust-auth`           |
| middleware, cors, rate-limit            | `rust-middleware`     |
| no_std, embedded, WASM                  | `rust-embedded`       |
| eBPF, kernel module                     | `rust-ebpf`           |
| GPU, CUDA                               | `rust-gpu`            |

### Manual Skill Invocation

If auto-matching is unclear, explicitly reference skills:

```text
Please use rust-ownership skill to answer:
"What's the difference between Rc and Arc?"
```

### Reading Skill Files

Each skill is self-contained in `skills/{skill-name}/SKILL.md`. The file
structure is:

1. description - Role and expertise scope
2. instructions - Code analysis patterns, problem-solving approach, best
   practices
3. constraints - Must follow/avoid rules, safety requirements
4. tools - Associated scripts
5. references - Related documentation in `references/`

## Reference Documentation

The `references/` directory contains deep technical content:

### Core Concepts (`references/core-concepts/`)

- `ownership.md` - Ownership and borrowing rules
- `lifetimes.md` - Lifetime annotations and bounds
- `concurrency.md` - Thread safety, Send/Sync, synchronization
- `traits.md` - Trait system and bounds

### Best Practices (`references/best-practices/`)

- `api-design.md` - API design guidelines
- `coding-standards.md` - 80-item coding standards checklist
- `unsafe-rules.md` - 47-item unsafe code safety rules
- `error-handling.md` - Error handling strategies
- `best-practices.md` - General best practices

### Ecosystem (`references/ecosystem/`)

- `crates.md` - Recommended crates by category
- `modern-crates.md` - Modern crates (2024-2025 ecosystem)
- `async-runtimes.md` - Async runtime comparison
- `testing.md` - Testing strategies and tools

### Commands (`references/commands/`)

- `rust-review.md` - Code review command specification
- `unsafe-check.md` - Unsafe code security checking
- `skill-index.md` - Skill index command
- `audit.md` - Security audit procedures

## MCP Integration

This repository provides MCP (Model Context Protocol) integration via
`.mcp.json`:

### MCP Resources

- `skills/` - All skill definition files
- `core-concepts/` - Core Rust concepts
- `best-practices/` - Best practices documentation
- `ecosystem/` - Crate and tool recommendations
- `commands/` - Command system
- `scripts/` - Utility scripts

### MCP Tools

- `/rust-review` - Code quality review
- `/unsafe-check` - Unsafe code security check
- `/skill-index` - Query available skills
- `/rust-features` - Query Rust features
- `/crate-info` - Get crate information
- `/guideline` - Coding standards query
- `/audit` - Security audit
- `/docs` - Documentation query

## Translation Context

This repository was translated from Chinese to English using multiple AI
translation passes (codex 0.92.0 and Claude Code 2.1.27). The translation
process is documented in README.md.

Use `rg -n -P "\\p{Han}" .` to find any remaining Chinese characters.

## Working with Claude Code

When answering Rust questions in this repository:

1. Read before suggesting: Never propose changes to code you haven't read
2. Use skill routing: Match questions to appropriate skill files
3. Reference documentation: Point to specific files in `references/` for deeper
   understanding
4. Validate with tools: Use scripts in `scripts/` for type checking, testing,
   linting
5. Follow constraints: Each skill has "must follow" and "must avoid" rules
6. Provide complete examples: Code samples should be compilable and tested
7. Explain the "why": Don't just show patterns, explain the reasoning behind
   them

### Skill Collaboration Paths

Skills build upon each other. When a question involves multiple domains:

```text
rust-ownership → rust-mutability → rust-concurrency → rust-async
rust-unsafe → rust-ffi → rust-ebpf / rust-gpu
rust-error → rust-error-advanced → rust-anti-pattern
rust-web → rust-middleware → rust-auth → rust-xacml
                          → rust-cache
```

Invoke related skills when questions span multiple domains.

## Important Notes

- This is a documentation/skill repository, not a Rust cargo project (no
  Cargo.toml)
- Skills are designed to be referenced by AI agents, not executed directly
- The 36 skills provide comprehensive coverage from beginner to expert level
- Each skill is self-contained but references related skills for complex
  problems
- Use the MCP integration for seamless skill routing in supported AI tools
