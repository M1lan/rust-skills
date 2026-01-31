---
name: rust-lifetime-complex
description: "Advanced lifetimes: HRTB, GAT, 'static constraints, dyn trait objects, and object safety"
globs: ["**/*.rs"]
---

# Advanced Lifetimes and the Type System

## Core issues

Key question: Why can't this type conversion compile?

The boundaries of type systems are often unexpected.

---

## HRTB + dyn Trait Object Conflict

### Problem code

```rust
// ❌ HRTB We can't load it. dyn trait object
pub type ConnFn<T> =
 dyn for<'c> FnOnce(&'c mut PgConnection) -> BoxFuture<'c, T> + Send;

let f = Box::new(move |conn: &mut PgConnection| -> BoxFuture<'_, i64> {
 Box::pin(async { Ok(42) })
}) as Box<ConnFn<i64>>; // ❌ "one type is more general than the other"
```

### Reason

- The closure captures a specific lifetime.
- The trait object requires a single concrete type.
- It does not become universally quantified by default.

### Fix: keep HRTB at the function boundary

```rust
// ✅ HRTB used at the call boundary
impl Db {
 pub async fn with_conn<F, T, Fut>(&self, f: F) -> Result<T, DbError>
 where
 F: for<'c> FnOnce(&'c mut PgConnection) -> Fut + Send,
 Fut: Future<Output = Result<T, DbError>> + Send,
 {
 let mut conn = self.pool.acquire().await?;
 f(&mut conn).await
 }
}
```

### Use

```rust
db.with_conn(|conn| async move {
 // 'c is introduced at the call; no dyn needed here.
 sqlx::query("...").fetch_all(conn).await
}).await
```

---

## GAT + dyn Trait Object

### Problem code

```rust
// ❌ GAT I can't. dyn Trait Together.
trait ReportRepo: Send + Sync {
 type Row<'r>: RowView<'r>; // ❌ GAT
}

let repo: Arc<dyn ReportRepo> = ...; // ❌ Compiler error
```

### Error message

```text
error[E0038]: the trait cannot be made into an object
because associated type `Row` has generic parameters
```

### Reason

- Trait objects require a single concrete vtable layout.
- The associated type depends on a lifetime, so layout varies.
- This violates object safety rules.

### Resolve: Layer structure

```rust
// Internal: GAT + borrowing (high performance)
trait InternalRepo {
 type Row<'r>: RowView<'r>;
 async fn query<'c>(&'c self) -> Vec<Self::Row<'c>>;
}

// External: owned DTO (GraphQL-friendly)
pub trait PublicRepo: Send + Sync {
 async fn query(&self) -> Vec<ReportDto>; // owned
}

// Adapter layer
impl PublicRepo for PgRepo {
 async fn query(&self) -> Vec<ReportDto> {
 let rows = self.internal.query().await; // Use the inside.
 rows.into_iter().map(|r| r.to_dto()).collect()
 }
}
```

### Chart

```text
GraphQL layer (requires 'static)
 ↓
 PublicRepo Trait (owned)
 ↓
 Adapter (Convert borrowed → owned)
 ↓
 InternalRepo Trait (GAT, borrowed)
 ↓
 DB Implementation
```

---

## 'static demands conflict

### Scenario

```rust
// async-graphql requires 'static
// but the repo method returns borrowed data
async fn resolve(&self) -> Result<&'r Row<'r>> {
 // ❌ 'r cannot outlive 'static
}
```

### Fix: return owned data

```rust
// Do not expose borrows at the API boundary
async fn resolve(&self) -> Result<ReportDto> {
 let row = self.repo.query().await?; // owned
 Ok(row.to_dto())
}
```

### When?

- Borrow only for very short scopes (e.g. within one function).
- Own data at API boundaries.
- Use borrowing only when performance gains are significant.

---

## Common conflict patterns

| Pattern                | Causes of conflict              | Solve                          |
|------------------------|---------------------------------|--------------------------------|
| HRTB → dyn             | Specific vs universal           | Keep HRTB at function boundary |
| GAT → dyn              | Not object-safe                 | Layer the API                  |
| 'static + borrow       | Lifetime conflict               | Return owned data              |
| Async + lifetime       | Futures hold state across await | Drop borrows before await      |
| Closure Capture + Send | Lifetime issues                 | Cloning or 'static             |

---

## When to stop borrowing

### Performance vs maintainability

```rust
// Performance gains vs complexity
fn should_borrow() -> bool {
 // Large data structure → borrow
 // High-frequency access → borrow
 // Simple lifetimes → borrow

 // Complex lifetimes → owned
 // API boundary → owned
 // Async context → owned
}
```

### Rules of thumb

1. API layer: default to owned
2. Internal implementation: borrow when needed
3. Performance hotspots: consider borrowing
4. High complexity: fall back to owned

---

## Debug techniques

### Compiler errors

| Error                               | Meaning                                         |
|-------------------------------------|-------------------------------------------------|
| "one type is more general"          | Trying to treat a specific type as more general |
| "lifetime may not live long enough" | Borrow outlives its scope                       |
| "cannot be made into an object"     | GAT+dyn is incompatible                         |
| "does not live long enough"         | Borrow ends too early                           |

### Methodology

1. Minimize: produce the smallest repro case
2. Annotate lifetimes: write them explicitly
3. Simplify step by step: remove abstractions
4. Accept reality: not all designs are object-safe or borrow-friendly
