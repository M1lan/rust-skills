# Rust Skill Rules

> Cursor project rules configuration

## Skill trigger rules

When encountering Rust programming problems, AI should automatically match the
corresponding skill:

| Problem Type                        | Triggered Skill    |
|-------------------------------------|--------------------|
| Ownership/lifetime errors           | `rust-ownership`   |
| Cell/RefCell/Mutex                  | `rust-mutability`  |
| Concurrency/async/threads           | `rust-concurrency` |
| Result/Option/error handling        | `rust-error`       |
| unsafe/FFI/raw pointers             | `rust-unsafe`      |
| Performance optimization/benchmarks | `rust-performance` |
| Web/axum/HTTP                       | `rust-web`         |
| Redis cache management              | `rust-cache`       |
| JWT/API Key authentication          | `rust-auth`        |
| Middleware/CORS/rate limiting       | `rust-middleware`  |
| RBAC/policy engine                  | `rust-xacml`       |
| no_std/embedded/WASM                | `rust-embedded`    |
| Cross-language calls/C++            | `rust-ffi`         |

## Reference files

Skill definition files are located in `skills/*/SKILL.md`, reference
directories:

- `skills/` - Core skills
- `references/best-practices/` - Best practices
- `references/core-concepts/` - Core concepts

## Skill priority

1. **Core Skills** - Use first (daily development)
2. **Advanced Skills** - Reference for deeper understanding
3. **Expert Skills** - Consult for difficult problems

## Usage

Describe the problem directly in conversation, or specify a skill explicitly:

```text
Please use rust-ownership to answer:
"What's the difference between Rc and Arc?"
```
