---
name: coding-standards
description: "Rust Coding Code(80Article)"
category: coding-style
triggers: ["coding", "standard", "style", "naming", "convention"]
related_skills:
 - rust-coding
 - rust-anti-pattern
 - rust-learner
---

# Rust Code

> This instruction defines Rust Code standards, covering naming, formatting, documentation, error handling, etc.

---

## Naming Code (N-001 to N-020)

### N-001: Use snake case

```rust
// ✅ Correct.
let max_connections = 100;
let user_name = String::new();
let is_valid = true;

// ❌ Error
let MaxConnections = 100;
let userName = String::new();
```

### N-002: Use the constant SCREAMING SNAKE CASE

```rust
// ✅ Correct.
const MAX_BUFFER_SIZE: usize = 1024;
const DEFAULT_TIMEOUT_MS: u64 = 3000;

// ❌ Error
const MaxBufferSize: usize = 1024;
```

### N-003: Use snake case

```rust
// ✅ Correct.
fn calculate_total_price() -> f64 { ... }
fn process_user_data(user: &User) -> Result<(), Error> { ... }

// ❌ Error
fn CalculateTotalPrice() -> f64 { ... }
```

### N-004: Types and traits in PascalCase

```rust
// ✅ Correct.
struct UserSession;
enum ProcessingState;
trait Serializable;

// ❌ Error
struct user_session;
enum processing_state;
```

### N-005: Avoid prefix Get

```rust
// ✅ Correct. - Direct Description Properties
fn name(&self) -> &str { &self.name }
fn len(&self) -> usize { self.items.len() }

// ❌ Error
fn get_name(&self) -> &str { &self.name }
```

### N-006: Boolean values use is /has /can prefix

```rust
// ✅ Correct.
let is_active = true;
let has_permission = false;
let can_connect = true;

// ❌ Error
let active = true;
```

### N-007: Duplication of type naming

```rust
// ✅ Correct.
struct User;
struct UserRepository;

// ❌ Error
struct UserUser;
```

### N-008: Module using snake case

```rust
// ✅ Correct.
pub mod network_config;
pub mod data_processing;
```

### N-009: Crate name using kebab-case

```toml
[package]
name = "my-awesome-crate"
```

### N-010: Use short descriptive names for broad parameters

```rust
// ✅ Correct.
fn process_items<T: Processable>(items: &[T]) { ... }
struct Cache<K, V> { ... }
```

### N-011: Short name for lifetime parameters

```rust
// ✅ Correct.
fn longest<'a>(s1: &'a str, s2: &'a str) -> &'a str { ... }
```

### N-012: Error type ends with Error

```rust
// ✅ Correct.
struct ParseError;
enum ValidationError;
```

### N-013: Result and Option variables avoid redundant naming

```rust
// ✅ Correct.
match some_result {
 Ok(value) => process(value),
 Err(e) => handle_error(e),
}
```

### N-014: Pool naming in plural form

```rust
// ✅ Correct.
let users: Vec<User> = vec![];
let items: HashSet<String> = HashSet::new();
```

### N-015: Short name for temporary variables

```rust
// ✅ Correct. - Short field acceptable
for i in 0..10 {
 println!("{}", i);
}
```

### N-016: Public API naming is clear

```rust
// ✅ Correct.
pub fn calculate_tax(income: f64, rate: f64) -> f64 { ... }
```

### N-017: Avoid magic numbers, use name constants

```rust
// ✅ Correct.
const HTTP_PORT: u16 = 80;
const MAX_RETRY_ATTEMPTS: u32 = 3;
```

### N-018: Consistency of configuration field names

```rust
// ✅ Correct.
struct Config {
 host: String,
 port: u16,
 timeout_secs: u64,
}
```

### N-019: Avoid naming with underlined beginnings

```rust
// ✅ Correct.
let value = 42;
let _ = compute_side_effect();
```

### N-020: Associated functions are named to reflect semantics

```rust
// ✅ Correct.
impl Vec<u32> {
 fn with_capacity(capacity: usize) -> Self { ... }
 fn from_elem(elem: u32, n: usize) -> Self { ... }
}
```

---

## Code format (F-021 to F-035)

### F-021: Format with rustfmt

```bash
cargo fmt
cargo fmt --check
```

### F-022: Line width does not exceed 100 characters

```rust
// ✅ Correct. - Rational line break
fn complex_function(
 arg1: Type1,
 arg2: Type2,
 arg3: Type3,
) -> Result<Output, Error> {
 // ...
}
```

### F-023: Unanimous parenthesis

```rust
fn foo() {
 // ...
}

if condition {
 // ...
} else {
 // ...
}
```

### F-024: Match branch alignment

```rust
match value {
 Pattern1 => { ... }
 Pattern2 => { ... }
 _ => { ... }
}
```

### F-025: Chain call break

```rust
let result = items
 .iter()
 .filter(|x| x.is_valid())
 .map(|x| x.value())
 .collect::<Vec<_>>();
```

### F-026: Generic Parameter Explosion

```rust
fn generic_function<T, U, V>(
 arg1: T,
 arg2: U,
 arg3: V,
) -> Result<Output, Error>
where
 T: Trait1,
 U: Trait2,
 V: Trait3,
{
 // ...
}
```

### F-027: Structure field alignment

```rust
struct Config {
 host: String,
 port: u16,
 timeout: Duration,
 max_retries: u32,
}
```

### F-028: Double slash while comments and codes are running

```rust
let value = 42; // It's a one-line note.
```

### F-029: Document comments used ///

```rust
/// Processing of user requests
///
/// # Arguments
///
/// * `request` - User request data
pub fn handle_request(request: &Request) -> Response {
 // ...
}
```

### F-030: Use module level comments / /!

```rust
//! Network communication module
//!
//! Provision TCP/UDP Protocol support and connection management functions.
```

### F-031: Add brackets to complex expressions

```rust
let result = (a + b) * (c - d) / e;
```

### F-032: Match expression to avoid overlaying

```rust
match data {
 Ok(ref data) if data.is_empty() => return Ok(Default::default()),
 Ok(data) => process(data),
 Err(e) => return Err(e),
}
```

### F-033: Closed Parameter Line Break

```rust
let result = items
 .iter()
 .filter(|item| item.is_valid())
 .map(|item| item.value())
 .collect::<Vec<_>>();
```

### F-034: Properties Formatting

```rust
#[derive(Debug, Clone, PartialEq)]
#[cfg(test)]
pub struct Config {
 // ...
}
```

### F-035: Import Group Sorting

```rust
use std::collections::HashMap;
use std::io::{Read, Write};

use serde::{Deserialize, Serialize};

use crate::config::Config;
use crate::error::AppError;
```

---

## Error handling (E-036 to E-050)

### E-036: User-defined error type for library code

```rust
#[derive(Error, Debug)]
pub enum ParseError {
 #[error("invalid format: {0}")]
 InvalidFormat(String),

 #[error("missing field: {0}")]
 MissingField(&'static str),

 #[error(transparent)]
 Io(#[from] std::io::Error),
}
```

### E-037: application usage

```rust
use anyhow::{Context, Result};

fn main() -> Result<()> {
 let config = load_config()
 .context("Failed to load configuration")?;
 Ok(())
}
```

### E-038: Error Dissemination Usage?

```rust
fn read_and_parse(path: &Path) -> Result<Data, ParseError> {
 let content = std::fs::read_to_string(path)
 .map_err(ParseError::from_io)?;
 let data = serde_json::from_str(&content)
 .map_err(ParseError::from_json)?;
 Ok(data)
}
```

### E-039: Providing meaningful error context

```rust
let file = std::fs::File::open(path)
 .with_context(|| format!("Failed to open: {}", path.display()))?;
```

### E-040: Avoid panic processing errors in libraries

```rust
// ✅ Correct.
fn parse_number(input: &str) -> Result<u32, ParseNumberError> {
 input.parse().ok_or(ParseNumberError::InvalidFormat)
}

// ❌ Error
fn parse_number(input: &str) -> u32 {
 input.parse().expect("Invalid number format")
}
```

### E-041: Error type achieved std::error::Error

```rust
impl std::fmt::Display for MyError {
 fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
 write!(f, "{}", self.message)
 }
}

impl std::error::Error for MyError {}
```

### E-042: Use? Error conversion

```rust
impl From<std::io::Error> for AppError {
 fn from(e: std::io::Error) -> Self {
 AppError::Io(e)
 }
}
```

### E-043: Avoid unwrap and expediency

```rust
// ✅ Correct. - Use only when convinced not to fail
fn get_version() -> &'static str {
 env!("CARGO_PKG_VERSION")
}

// ❌ Error
let value = map.get(&key).unwrap();
```

### E-044: Use appropriate methods to process

```rust
let value = config.get("key").unwrap_or(&DEFAULT_VALUE);
let value = config.get("key").ok_or(KeyNotFoundError)?;
```

### E-045: Error log records balance information with noise

```rust
tracing::error!(error = %error, "Operation failed");
```

### E-046: Consider future extensions when defining an error variant

```rust
#[derive(Error, Debug)]
pub enum AppError {
 #[error("database error: {0}")]
 Database(#[from] sqlx::Error),

 #[error("validation error: {0}")]
 Validation(String),

 #[error("unknown error occurred")]
 Unknown,
}
```

### E-047: Batch operation returns partial success information

```rust
struct BatchResult<T> {
 succeeded: Vec<T>,
 failed: Vec<(T, Error)>,
 skipped: Vec<T>,
}
```

### E-048: Distinction between recoverable and irrecoverable errors

```rust
fn validate_input(input: &str) -> Result<(), ValidationError> {
 if input.is_empty() {
 return Err(ValidationError::Empty);
 }
 Ok(())
}

fn invariant_violated() -> ! {
 panic!("Internal invariant violated");
}
```

### E-049: Error transmission chain to maintain information

```rust
fn level2() -> Result<(), Error> {
 level3().context("Failed at level2")?;
 Ok(())
}
```

### E-050: Test error type

```rust
#[cfg(test)]
mod error_tests {
 #[test]
 fn error_display_format() {
 let error = ParseError::InvalidFormat("test".to_string());
 assert_eq!(error.to_string(), "invalid format: test");
 }
}
```

---

## Document specifications (D-051 to D-065)

### D-051: Public API must have a document comment

```rust
/// Parsing JSON String as Structure
///
/// # Arguments
///
/// * `input` - JSON Input string for format
///
/// # Returns
///
/// Example of a parsing structure
///
/// # Errors
///
/// When? JSON Returns when format is incorrect [`ParseError`]
///
/// # Examples
///
/// ```
/// use my_crate::parse_json;
/// let json = r#"{"name": "Alice"}"#;
/// let value = parse_json(json).unwrap();
/// ```
pub fn parse_json(input: &str) -> Result<Value, ParseError> {
 // ...
}
```

### D-052: Document contains Examples chapters

```rust
/// Maximum number of conventions to calculate two digits
///
/// # Examples
///
/// ```
/// assert_eq!(gcd(12, 18), 6);
/// ```
pub fn gcd(a: u64, b: u64) -> u64 {
 if b == 0 { a } else { gcd(b, a % b) }
}
```

### D-053: Document link with inverse numbers and square brackets

```rust
/// Details about error handling,Please see [`std::io::Error`] and [`std::fmt::Display`].
```

### D-054: Code block tag language in document

```rust
/// ```rust
/// let result = process_request(request);
/// assert!(result.is_ok());
/// ```
///
/// ```json
/// {"status": "ok", "data": 42}
/// ```
```

### D-055: Modular document description of modular duties

```rust
//! Error Processing Module
//!
//! Provides a uniform definition of error type and a functional function for error handling.
//!
//! ## Main type
//!
//! - [`AppError`] - Application master error type
```

### D-056: Complex algorithms providing algorithms

```rust
/// Use bubble sorting to sort slices in situ
///
/// # Algorithm
///
/// Flow Sort Repeat Through Calendar List,Relatively adjacent elements.
///
/// # Time Complexity
///
/// O(n²)
///
/// # Space Complexity
///
/// O(1)
pub fn bubble_sort<T: Ord>(slice: &mut [T]) {
 // ...
}
```

### D-057: Document description panic

```rust
/// Get the first element of the array
///
/// # Panics
///
/// When array is empty panic.
pub fn first<T>(slice: &[T]) -> &T {
 slice.get(0).expect("slice is empty")
}
```

### D-058: Document describes linear security

```rust
/// Profile Manager for Thread Security
///
/// # Thread Safety
///
/// This type works. [`Send`] and [`Sync`],It can be shared safely across multiple lines..
```

### D-059: Cargo.toml contains complete description

```toml
[package]
name = "my-crate"
version = "1.0.0"
description = "A short description of the crate"
authors = ["Author Name <author@example.com>"]
edition = "2024"
repository = "https://github.com/username/repo"
license = "MIT OR Apache-2.0"
keywords = ["tag1", "tag2"]
categories = ["development-tools", "database"]
```

### D-060: Consistency of document comments

```rust
/// Returns processed data successfully
///
/// # Arguments
///
/// * `data` - Enter Data
///
/// # Returns
///
/// processed data
///
/// # Errors
///
/// Returns error when input data is invalid
```

### D-061: Disused #[deprecaed]

```rust
#[deprecated(
 since = "2.0.0",
 note = "Use `parse_config_v2` instead"
)]
pub fn parse_config(path: &Path) -> Result<Config, ConfigError> {
 // ...
}
```

### D-062: Details for internal realization / Comment

```rust
// Use fast path to handle common situations
if let Some(result) = try_fast_path() {
 return result;
}

// Slow path: handle boundary cases
slow_path_algorithm()
```

### D-063: Complicated logic with explanatory notes

```rust
// Compressing the state to a single byte using bit calculations
// bit 0-2: Status Code (0-7)
// bit 3-5: flags (3 flags)
const STATUS_MASK: u8 = 0x07;
```

### D-064: TODO and FIXME using standard formats

```rust
// TODO: Optimizing algorithm complexity
// FIXME: May panic at boundary conditions
```

### D-065: Avoid obvious comments

```rust
// ✅ Correct - explain why, not what
std::thread::sleep(Duration::from_secs(5));

// ❌ Error
let x = 5; // Set x to 5
```

---

## Code quality (Q-066 to Q-080)

### Q-066: Avoid unnecessary clone

```rust
// ✅ Correct.
fn process_name(name: &str) {
 println!("{}", name);
}

// ❌ Error
fn process_name(name: &String) {
 let n = name.clone();
 println!("{}", n);
}
```

### Q-067: Prefer to an iterative rather than an index

```rust
let result: Vec<_> = items.iter().filter(|x| x.is_valid()).collect();
```

### Q-068: Avoid distribution of memory in hotspot cycles

```rust
let mut buffer = String::with_capacity(1024);
for _ in 0..1000 {
 buffer.push_str("data");
}
```

### Q-069: Combination with Result/Option

```rust
let value = config
 .get("feature")
 .and_then(|v| v.parse::<bool>().ok())
 .unwrap_or(true);
```

### Q-070: Keep function short and single

```rust
fn validate_email(email: &str) -> Result<(), ValidationError> {
 if !email.contains('@') {
 return Err(ValidationError::InvalidEmail);
 }
 Ok(())
}
```

### Q-071: Avoid type expansion

```rust
fn process_items<T: Processable>(items: &[T]) {
 for item in items {
 item.process();
 }
}
```

### Q-072: Priority use of combinations rather than succession

```rust
struct Calculator {
 logger: Logger,
 validator: Validator,
}
```

### Q-073: Use #[cfg(test)] quarantine test code

```rust
#[cfg(test)]
mod tests {
 #[test]
 fn test_basic_functionality() {
 // Test Code
 }
}
```

### Q-074: Use match integrity

```rust
enum Status {
 Pending,
 Running,
 Completed,
 Failed(String),
}

fn describe(status: Status) -> String {
 match status {
 Status::Pending => "pending".to_string(),
 Status::Running => "running".to_string(),
 Status::Completed => "completed".to_string(),
 Status::Failed(msg) => format!("failed: {}", msg),
 }
}
```

### Q-075: Avoid exposing internal types in open API

```rust
mod internal {
 pub struct InternalState { /* ... */ }
}

pub struct PublicHandle(internal::InternalState);
```

### Q-076: Use appropriate data structures

```rust
let mut unique_items = std::collections::HashSet::new();
let mut ordered_items = std::collections::BTreeSet::new();
```

### Q-077: Avoid overuse of Rc/RefCell

```rust
use std::sync::{Arc, Mutex};

let shared = Arc::new(Mutex::new(0));
```

### Q-078: Check code quality with cargo clippy

```bash
cargo clippy
cargo clippy --fix
```

### Q-079: Write Attribute Test

```rust
use proptest::prelude::*;

proptest! {
 #[test]
 fn test_reverse_twice(s: String) {
 let reversed: String = s.chars().rev().collect();
 let double_reversed: String = reversed.chars().rev().collect();
 assert_eq!(s, double_reversed);
 }
}
```

### Q-080: Periodic review and restructuring

```rust
// Periodic inspection:
// 1. Is the function too long??
// 2. Type overburdened?
// 3. Is there a duplicate code??
// 4. Is the name clear??
// 5. Consistency of error treatment?
// 6. Complete Document?

// Use tool analysis:
// cargo tarpaulin # Code Coverage
// cargo bench # Performance Analysis
```

---

## Standardized Quick Checklist

| Category | Number of rules | Annotations |
|-----|-------|------|
| N - Name code. | 20 | Variables, Constants, Functions, Type Naming |
| F-code format | 15 | Formatting, Comment, Report Sorting |
| E - Error handling. | 15 | Error type, dissemination, log recording |
| D - Document code. | 15 | API documents, modular documents, examples |
| Queen - Code quality. | 15 | Performance, readability, maintenance |

---

## Related skills
- Coding standards
- Anti-pattern recognition
- Rust learning path
