# Ownership and Borrowing

Ownership is the central memory security mechanism of Rust, which allows Rust
to secure the memory without relying on recycling.

## Core rules

1. Each value has a single owner.
2. When the owner goes out of scope, the value is dropped.
3. At any time: one mutable reference _or_ any number of immutable references.

## Transfer of Ownership (Move)

### What's moving?

When a value is given to another variable, ownership is transferred and the
original variable is no longer valid.

```rust
fn main() {
 let s1 = String::from("hello");
 let s2 = s1; // s1 moves ownership to s2

 // println!("{}", s1); // ❌ Compiler error: s1 was moved
 println!("{}", s2); // ✅ OK
}
```

### Move the scene

- Grant operation: `let s2 = s1`
- Function transfer: `takes_ownership(s1)`
- Function returns value: `return s1`

```rust
fn takes_ownership(s: String) {
 println!("{}", s);
} // s dropped here

fn main() {
 let s = String::from("hello");
 takes_ownership(s); // s moved into function
 // println!("{}", s); // ❌ Error: s was moved
}
```

## Borrowing

### Immutable borrow

Creates an immutable reference using `&`.

```rust
fn calculate_length(s: &String) -> usize {
 s.len()
} // s goes out of scope, but the value it points to is not dropped

fn main() {
 let s = String::from("hello");
 let len = calculate_length(&s); // immutable borrow
 println!("Length: {}", len);
 println!("{}", s); // ✅ s It's still working.
}
```

### Mutable borrow

Create mutable references using `&mut`, only one at a time.

```rust
fn change(s: &mut String) {
 s.push_str(", world");
}

fn main() {
 let mut s = String::from("hello");
 change(&mut s); // mutable borrow
 println!("{}", s); // ✅ "hello, world"
}
```

### Mutable borrow rules

```rust
fn main() {
 let mut s = String::from("hello");

 let r1 = &mut s; // ✅ first mutable borrow
 // let r2 = &mut s; // ❌ Error!Can't have two variable references at the same time.
 // let r3 = &s; // ❌ Error!Invertible and variable references cannot exist simultaneously

 println!("{}", r1);
}
```

## Slice Type

### String Slice

```rust
fn first_word(s: &String) -> &str {
 let bytes = s.as_bytes();
 for (i, &byte) in bytes.iter().enumerate() {
 if byte == b' ' {
 return &s[0..i];
 }
 }
 &s[..]
}
```

## Lifetime (Lifetime)

### Why the lifetime?

Rust needs to know the time of survival to ensure that the reference does not point to the released memory.

### Lifetime notes

```rust
// 'a The lifetime indicating the return value is the same as the shorter of the two input parameters
fn longest<'a>(s1: &'a str, s2: &'a str) -> &'a str {
 if s1.len() > s2.len() {
 s1
 } else {
 s2
 }
}
```

### Lifetime in structures

```rust
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

## Smart pointer selection

| Scenario                         | Choice                    | Reason                            |
|----------------------------------|---------------------------|-----------------------------------|
| Heap-allocated single value      | `Box<T>`                  | Simple and straightforward        |
| Single-thread shared refcount    | `Rc<T>`                   | Lightweight                       |
| Multi-thread shared refcount     | `Arc<T>`                  | Atomic operations                 |
| Runtime borrow checking          | `RefCell<T>`              | Single-thread interior mutability |
| Multi-thread interior mutability | `Mutex<T>` or `RwLock<T>` | Thread-safe                       |

## Common error codes

| Error Code | Meaning                     | Common causes                               |
|------------|-----------------------------|---------------------------------------------|
| E0382      | Use after move              | Using a value after its ownership was moved |
| E0597      | Lifetime too short          | Returning a reference to a temporary value  |
| E0506      | Mutated while borrowed      | Mutating while a borrow is active           |
| E0507      | Move out of a reference     | Trying to take ownership from a reference   |
| E0106      | Missing lifetime parameters | Returning references without lifetimes      |

## Best practices

1. Prefer returning ownership: let callers decide if they need ownership
2. Borrow over move: use references for read-only access
3. Use meaningful lifetime names: e.g. `'connection`, `'file`
4. Avoid unnecessary clones: pass large objects by reference
5. Understand borrowing rules: mutable and immutable borrows cannot coexist
