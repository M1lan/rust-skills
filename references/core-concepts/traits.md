# Rust Trait System Guide

Trait is the core of the Rust type system, similar to the interface (interface)
and abstract base class (abstract base class).

## Trait Foundation

### Definition Trait

```rust
// Define One trait
pub trait Summary {
 fn summarize(&self) -> String;
}

// Achieved for type trait
pub struct NewsArticle {
 pub headline: String,
 pub location: String,
 pub author: String,
 pub content: String,
}

impl Summary for NewsArticle {
 fn summarize(&self) -> String {
 format!("{},{} Coverage:{}", self.headline, self.location, self.author)
 }
}
```

### Default Realization

```rust
pub trait Summary {
 // Provide default realization
 fn summarize(&self) -> String {
 String::from("(Read More...)")
 }
}

// Could choose to overwrite default realization
impl Summary for NewsArticle {
 fn summarize(&self) -> String {
 format!("{} - {}", self.headline, self.author)
 }
}
```

## Trait as binding

### Trait Bound

```rust
// Single trait Constraints
fn notify<T: Summary>(item: &T) {
 println!("Press summaries:{}", item.summarize());
}

// Multiple trait Constraints
fn notify<T: Summary + Clone>(item: &T) {
 println!("Press summaries:{}", item.summarize());
}

// Use where Sub sentences(Clearer.)
fn notify<T>(item: &T)
where
 T: Summary + Clone,
{
 println!("Press summaries:{}", item.summarize());
}
```

### Returns the type of Trait achieved

```rust
// Back impl Trait
fn returns_summarizable() -> impl Summary {
 NewsArticle {
 headline: String::from("Penguins win the Stanley Cup"),
 location: String::from("Pittsburgh, PA, USA"),
 author: String::from("Iceburgh"),
 content: String::from("The Pittsburgh Penguins once again are the best"),
 }
}
```

## Common Trait

### Display and Debug

```rust
// Debug For debug output
#[derive(Debug)]
struct Rectangle {
 width: u32,
 height: u32,
}

// Display For User Output
use std::fmt;

impl fmt::Display for Rectangle {
 fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
 write!(f, "{}x{} Rectangle", self.width, self.height)
 }
}

// Use
let rect = Rectangle { width: 30, 50 };
println!("{:?}", rect); // Debug: Rectangle { width: 30, height: 50 }
println!("{}", rect); // Display: 30x50 Rectangle
```

### PartialEq and Eq (Equivalent)

```rust
#[derive(PartialEq, Debug)]
struct Point {
 x: i32,
 y: i32,
}

// It's comparable.
assert!(Point { x: 1, y: 2 } == Point { x: 1, y: 2 });
```

### Clone and Copy (cloning and copying)

```rust
// Clone: deep copy
#[derive(Clone)]
struct Person {
 name: String,
 age: u32,
}

// Copy: bitwise copy (all fields must be Copy)
#[derive(Copy, Clone)]
struct Point(i32, i32);
```

### Default (default)

```rust
#[derive(Default)]
struct Config {
 host: String,
 port: u16,
 max_connections: u32,
}

let config = Config::default();
```

### From and Into (type conversion)

```rust
#[derive(From)]
struct Point {
 x: i32,
 y: i32,
}

let p = Point::from((10, 20));

// Achieved Into
impl From<String> for Message {
 fn from(s: String) -> Self {
 Message { content: s }
 }
}
```

### Asref and AsMut (reference conversion)

```rust
struct Person {
 name: String,
}

impl AsRef<str> for Person {
 fn as_ref(&self) -> &str {
 &self.name
 }
}

// Use
let person = Person { name: String::from("Alice") };
let name: &str = person.as_ref();
```

### Deref and DerefMut (excused)

```rust
use std::ops::Deref;

struct MyBox<T>(T);

impl<T> Deref for MyBox<T> {
 type Target = T;
 fn deref(&self) -> &T {
 &self.0
 }
}

// Automatically de-quote
let x = MyBox(5);
assert_eq!(x, 5);
```

## Association Type

```rust
pub trait Iterator {
 type Item; // Association Type

 fn next(&mut self) -> Option<Self::Item>;
}

struct Counter {
 count: u32,
}

impl Iterator for Counter {
 type Item = u32;

 fn next(&mut self) -> Option<Self::Item> {
 if self.count < 5 {
 self.count += 1;
 Some(self.count)
 } else {
 None
 }
 }
}
```

## Generic Associated Types (GAT)

```rust
trait Container {
 type Item<'a> where Self: 'a;

 fn get(&self, index: usize) -> Option<Self::Item<'_>>;
}

impl<T> Container for Vec<T> {
 type Item<'a> = &'a T where Self: 'a;

 fn get(&self, index: usize) -> Option<Self::Item<'_>> {
 self.get(index)
 }
}
```

## Trait Object (dyn Trait)

### What is Trait Object

```rust
// Static dispatch: generics
fn summarize<T: Summary>(item: &T) {
 println!("{}", item.summarize());
}

// Dynamic dispatch: trait object
fn summarize_dyn(item: &dyn Summary) {
 println!("{}", item.summarize());
}
```

### When to use trait objects

```rust
// Heterogeneous collection: different types, same trait
struct Handler {
 handlers: Vec<Box<dyn Fn(i32) -> i32>>,
}

impl Handler {
 fn add<F: Fn(i32) -> i32 + 'static>(&mut self, handler: F) {
 self.handlers.push(Box::new(handler));
 }

 fn apply(&self, value: i32) -> i32 {
 self.handlers.iter().fold(value, |acc, h| h(acc))
 }
}
```

### Object safety rules

```rust
// ❌ Not object-safe: returns Self
trait Bad {
 fn create(&self) -> Self;
}

// ❌ Not object-safe: generic method
trait Bad2 {
 fn process<T>(&self, item: T);
}

// ✅ Object-safe
trait Good {
 fn name(&self) -> &str;
}
```

## Trait Succession

```rust
trait Person {
 fn name(&self) -> String;
}

trait Employee: Person {
 fn salary(&self) -> u32;
}

struct Manager {
 name: String,
 salary: u32,
}

impl Person for Manager {
 fn name(&self) -> String {
 self.name.clone()
 }
}

impl Employee for Manager {
 fn salary(&self) -> u32 {
 self.salary
 }
}
```

## Common Trait

### DerefCoercion (Auto-Referral)

```rust
// Rust Automatically unquote
fn print_length(s: &str) {
 println!("{}", s.length());
}

let string = String::from("hello");
print_length(&string); // Autorefer to &str
```

### blanket implementations

```rust
// Provided by the Standard Library blanket Achieved
impl<T: Display> Display for Vec<T> {
 // ...
}

// It means everything. Display That's how it works.
```

## Advanced Trait

### marker traits

```rust
// Send:It can be delivered safely online.
unsafe impl Send for MyData {}

// Sync:You can share references safely online.
unsafe impl Sync for MyData {}
```

### Drop Trait

```rust
struct File {
 name: String,
 handle: std::fs::File,
}

impl Drop for File {
 fn drop(&mut self) {
 println!("Close File:{}", self.name);
 }
}
```

### Fn Trait

```rust
// FnOnce:You can call once.
fn consume_fn<T: FnOnce()>(f: T) {
 f(); // Only once.
}

// FnMut:You can call many times.,Variable borrowing
fn mutable_fn<T: FnMut(&mut i32)>(f: &mut T) {
 let mut x = 10;
 f(&mut x);
}

// Fn:You can call many times.,I can't borrow it.
fn immutable_fn<T: Fn(i32) -> i32>(f: &T) {
 let result = f(5);
}
```

## Trait best practice

### 1. Priority use of combinations rather than succession

```rust
// ❌ Bad design.:Use succession
trait Animal {
 fn speak(&self);
}

struct Dog {
 name: String,
}

impl Animal for Dog {
 fn speak(&self) {
 println!("Woof!");
 }
}

// ✅ Good design.:Use Group
struct Speaker {
 message: String,
}

impl Speaker {
 fn speak(&self) {
 println!("{}", self.message);
 }
}
```

### 2. Use newtype mode

```rust
// Packaging type to add trait
struct Meters(u32);

impl std::fmt::Display for Meters {
 fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
 write!(f, "{}m", self.0)
 }
}
```

### 3. Prefer trait bounds over forced conversion

```rust
// ✅ Good: explicit constraints
fn process<T: Summary>(item: &T) {
 item.summarize();
}

// ❌ Bad: relies on runtime type checks
fn process(item: &dyn Summary) {
 item.summarize();
}
```

## Common errors

| Error Code | Meaning               | Fix                             |
|------------|-----------------------|---------------------------------|
| E0277      | Missing trait bound   | Add `T: Trait`                  |
| E0038      | Trait object not safe | Check object safety rules       |
| E0117      | Conflicting impl      | Use newtype or delegation       |
| E0323/4/5  | Trait impl not found  | Implement trait or check bounds |

## Further reading

- [Trait Bounds - Rust Book](https://doc.rust-lang.org/book/ch10-02-traits.html)
- [Advanced Traits](https://doc.rust-lang.org/book/ch19-03-advanced-traits.html)
- [std::ops](https://doc.rust-lang.org/std/ops/index.html) - operator traits
