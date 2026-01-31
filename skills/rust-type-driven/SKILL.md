---
name: rust-type-driven
description: "Type-driven design: newtypes, typestate, PhantomData, marker traits, builder pattern, sealed traits, ZST"
globs: ["**/*.rs"]
---

# Type-driven design

## Core issues

Key question: How can the compiler catch more errors at compile time?

Well-designed types prevent invalid states.

---

## Type design patterns

### Newtype pattern

```rust
// ❌ Raw types are easy to mix up
struct UserId(u64);
struct OrderId(u64);

// ✅ Type safety: cannot mix
fn get_user(user_id: UserId) { ... }
fn get_order(order_id: OrderId) { ... }

// The compiler will stop this:
// get_order(user_id); // Compiler error!
```

### Typestate pattern (Type State)

```rust
// Encode state in the type
struct Disconnected;
struct Connecting;
struct Connected;

struct Connection<State = Disconnected> {
 socket: TcpSocket,
 _state: PhantomData<State>,
}

impl Connection<Disconnected> {
 fn connect(self) -> Connection<Connecting> {
 // ...
 Connection { socket: self.socket, _state: PhantomData }
 }
}

impl Connection<Connected> {
 fn send(&mut self, data: &[u8]) {
// Only the Connected state can send
 }
}
```

### PhantomData

```rust
// Use PhantomData to mark ownership and variance
struct MyIterator<'a, T> {
 _marker: PhantomData<&'a T>,
}

// Tell the compiler we borrow T for lifetime 'a.
```

---

## Make invalid states unrepresentable

```rust
// ❌ Easy to create invalid state
struct User {
 name: String,
 email: Option<String>, // Could be empty
 age: u32,
}

// ✅ email can't be empty
struct User {
 name: String,
 email: Email, // Type guarantees validity
 age: u32,
}

struct Email(String);

impl Email {
 fn new(s: &str) -> Option<Self> {
 if s.contains('@') {
 Some(Email(s.to_string()))
 } else {
 None
 }
 }
}
```

---

## Builder pattern

```rust
struct ConfigBuilder {
 host: String,
 port: u16,
 timeout: u64,
 retries: u32,
}

impl ConfigBuilder {
 fn new() -> Self {
 Self {
 host: "localhost".to_string(),
 port: 8080,
 timeout: 30,
 retries: 3,
 }
 }

 fn host(mut self, host: impl Into<String>) -> Self {
 self.host = host.into();
 self
 }

 fn port(mut self, port: u16) -> Self {
 self.port = port;
 self
 }

 fn build(self) -> Config {
// We can do final validation here.
 Config {
 host: self.host,
 port: self.port,
 }
 }
}
```

---

## Marker traits

```rust
// Use marker traits to tag capability
trait Sendable: Send + 'static {}

// Or use marker traits to constrain types
struct Cache<T: Cacheable> {
 data: T,
}

trait Cacheable: Send + Sync {}
```

---

## Zero-Sized Types (ZST)

```rust
// Use ZSTs as markers
struct DebugOnly;
struct Always;

// Only debug-mode code
struct DebugLogger<Mode = Always> {
 _marker: PhantomData<Mode>,
}

impl DebugLogger<DebugOnly> {
 fn log(&self, msg: &str) {
 println!("[DEBUG] {}", msg);
 }
}
```

---

## Common anti-patterns

| Anti-pattern         | Problem                | Improvement              |
|----------------------|------------------------|--------------------------|
| `is_valid` flag      | Runtime checks         | Encode state in types    |
| Too many `Option`s   | Can be empty           | Redesign the type        |
| Raw types everywhere | Type confusion         | Newtype                  |
| Runtime validation   | Errors discovered late | Validate in constructors |
| Boolean arguments    | Unclear meaning        | Use enums or builders    |

---

## Validation timing

| Validation type    | Best timing     | Example                         |
|--------------------|-----------------|---------------------------------|
| Range validation   | At construction | `Email::new()` returns `Option` |
| State transitions  | Type boundary   | `Connection<Connected>`         |
| Reference validity | Lifetimes       | `&'a T`                         |
| Thread safety      | `Send + Sync`   | Compiler check                  |
