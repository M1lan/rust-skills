# Lifetime Annotated Guide

Lifetime annotated tells the compiler how to relate the references to ensure
that they remain valid.

## Basic lifetime

### Syntax

```rust
&'a str // Reference with lifetime 'a
&'a T // Generic reference with lifetime 'a
```

### Example

```rust
// 'a ties x and y to the same lifetime
fn longest<'a>(x: &'a str, y: &'a str) -> &'a str {
 if x.len() > y.len() {
 x
 } else {
 y
 }
}
```

## When you need explicit lifetimes

### References in Structure

```rust
// ImportantExcerpt The lifetime cannot exceed the text it quotes.
struct ImportantExcerpt<'a> {
 part: &'a str,
}

fn main() {
 let novel = String::from("Call me Ishmael. Some years ago...");
 let first_sentence = novel.split('.').next().unwrap();

 let excerpt = ImportantExcerpt {
 part: first_sentence,
 };

 println!("Excerpt: {}", excerpt.part);
}
```

### Methodology

```rust
impl<'a> ImportantExcerpt<'a> {
 fn announce_and_return_part(&self, announcement: &str) -> &str {
 println!("Attention please: {}", announcement);
 self.part
 }
}
```

## Lifetime omission rules

Rust automatically applies three omitted rules.

### Rule 1: Enter lifetime

```rust
// These are the same:
fn foo(s: &str) -> &str { s }
fn foo<'a>(s: &'a str) -> &'a str { s }
```

### Rule 2: Infer the output lifetime from the input lifetime

```rust
// fn first_word(s: &str) -> &str { ... }
// Expands to:
fn first_word<'a>(s: &'a str) -> &'a str { ... }
```

### Rule 3: Individual input lifetime

```rust
// fn method(&self) -> &str { ... }
// Turn into :
fn method<'a>(&'a self) -> &'a str { ... }
```

## Static lifetime

```rust
// Lifetime
let s: &'static str = "I live forever!";

// String field has a static lifetime
fn print_message() -> &'static str {
 "Hello, world!"
}
```

## Multi-lifetime

```rust
fn both_ends<'a, 'b>(s1: &'a str, s2: &'b str) -> &'a str {
 if s1.len() > s2.len() {
 s1
 } else {
 s2
 }
}
```

## Higher-Ranked Trait Bounds (HRTB)

### What's HRTB?

Allows the designation of "for all lifetimes".

```rust
// F can accept references with any lifetime
fn call_with_any_lifetime<T, F>(val: T, f: F)
where
 F: Fn(&T),
{
 f(&val);
}
```

### FnMut binding

```rust
// Accept returned references,And quote the lifetime freedom
fn make_processor<T>(processor: impl Fn(&T) -> &T) {
 let value = T::default();
 let result = processor(&value);
}
```

## Generic Associated Types (GAT)

```rust
trait Container {
 type Item<'a> where Self: 'a;
 fn get(&self, index: usize) -> Option<Self::Item<'_>>;
}

struct VecContainer<T> {
 data: Vec<T>,
}

impl<T> Container for VecContainer<T> {
 type Item<'a> = &'a T where Self: 'a;

 fn get(&self, index: usize) -> Option<Self::Item<'_>> {
 self.data.get(index)
 }
}
```

## Common lifetime errors

| Error Code | Meaning                                 | Solution                                            |
|------------|-----------------------------------------|-----------------------------------------------------|
| E0597      | Borrowed value doesn't live long enough | Ensure the referenced value lives long enough       |
| E0106      | Missing lifetime parameters             | Add lifetime annotations for returned references    |
| E0515      | Cannot return reference                 | Consider returning an owned type                    |
| E0621      | Lifetime constraints mismatch           | Adjust lifetimes to express relationships correctly |

## Best practices

1. Prefer borrowing over explicit lifetimes: returning owned types can
   avoid lifetime issues
2. Use meaningful lifetime names: e.g. `'connection`, `'file`
3. Avoid overusing `'static`: only use it when truly needed
4. Understand elision rules: the compiler can infer most lifetimes
5. Add lifetimes to structs only when needed: when they contain references

## Complex lifetime patterns

### NLL (non-lexical lifetimes)

Rust 2018 introduced improvements where references can be released sooner after
their use.

```rust
// The old version may require separate declarations
let mut x = String::new();
let r;
x = String::from("hello"); // Reassign after r is no longer used.
r = &x; // NLL allows this.

println!("{}", r);
```

### Lifetimes in async code

```rust
// impl Trait lifetime handling
async fn get_data<'a>(conn: &'a Connection) -> Data {
 conn.query().await
}

// Use Pin Process self-referenced structure
struct SelfRef {
 value: i32,
 pointer_to_value: *const i32,
}
```

### Lifetime in closed bags

```rust
// Lifetime treatment of closed capture references
fn create_closure<'a, T>(value: &'a T) -> impl Fn() -> &'a T {
 move || value
}
```
