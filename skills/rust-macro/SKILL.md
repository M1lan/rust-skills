---
name: rust-macro
description: "Macros and procedural macros: macro_rules!, derive, proc-macro, compile-time codegen. Triggers: macro, derive, proc-macro, macro_rules"
globs: ["**/*.rs"]
---

# Macros and Procedural Macros

## Core issues

**Key question:** How do we reduce repetition? When to use macros vs generics?

Macros generate code at compile time; generics provide type abstraction.

---

## Macros vs generics

| Dimension | Macros | Generics |
|-----|-----|-----|
| Flexibility | Code transformation | Type abstraction |
| Compile cost | Higher | Lower |
| Error messages | Can be harder to read | Usually clearer |
| Debug | Debug macro extension code | Direct debug |
| Use case | Reduce boilerplate | Shared algorithms |

---

## Declarative macros (macro_rules!)

### Basic structure

```rust
macro_rules! my_vec {
 () => {
 Vec::new()
 };
 ($($elem:expr),*) => {
 vec![$($elem),*]
 };
 ($elem:expr; $n:expr) => {
 vec![$elem; $n]
 };
}
```

### Repetition patterns

| Tag | Meaning |
|-----|------|
| `$()` | Match zero or more |
| `$($x),*` | Comma-separated |
| `$($x),+` | At least one |
| `$x:ty` | Type match |
| `$x:expr` | Expression match |
| `$x:pat` | Pattern match |

---

## Procedural macros

### Keep it simple

```rust
use proc_macro::TokenStream;
#[proc_macro_derive(MyDerive)]
pub fn my_derive(input: TokenStream) -> TokenStream {
 let input = syn::parse_macro_input!(input as syn::DeriveInput);
 let name = &input.ident;
 
 let expanded = quote::quote! {
 impl MyDerive for #name {
 fn my_method(&self) -> String {
 format!("Hello from {}", stringify!(#name))
 }
 }
 };
 
 expanded.into()
}
```

### Use

```rust
#[derive(MyDerive)]
struct MyStruct {
 field: i32,
}
```

---

## Function-like procedural macro

```rust
#[proc_macro]
pub fn my_func_macro(input: TokenStream) -> TokenStream {
 // Convert input
 let tokens = input.into_iter().collect::<Vec<_>>();
 // Generate code
 quote::quote! { /* ... */ }.into()
}
```

---

## Debugging macros

```bash
# View macro extension results
cargo expand
cargo expand --test test_name
```

---

## Best practices

| Approach | Reason |
|-----|------|
| Prefer generics first | Safer, easier to debug |
| Keep macros simple | Complex macros are hard to maintain |
| Document macros | Users need to understand behavior |
| Test expansion results | Ensure correctness |
| Debug with `cargo expand` | Visualize expansion |

---

## Common crates

| crate | Use |
|-------|------|
| `syn` | Parse Rust code |
| `quote` | Generate Rust code |
| `proc-macro2` | Token processing |
| `derive-more` | Common derive macros |
