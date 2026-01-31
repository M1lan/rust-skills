---
name: rust-async-pattern
description: "Advanced async: Stream lifetimes, zero-copy buffers, tokio::spawn + non-'static data, plugin scheduling, tonic. Triggers: async, Stream, tokio::spawn, zero-copy, plugin system, tonic"
globs: ["**/*.rs"]
---

# Advanced Async Patterns

## Core issues

Key question:# Why are lifetimes in async code so hard?

Async complicates borrowing because futures can be held across await points.

---

## Stream + self-referential buffer

### Problem code

```rust
// ❌ Stream returns slices that borrow from internal buffers
pub struct SessionStream<'buf> {
 buf: Vec<u8>,
 cache: Vec<CachedResponse<'buf>>,
}

impl Stream for SessionStream<'buf> {
 type Item = Result<CachedResponse<'buf>, Status>;

 fn poll_next(self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Option<Self::Item>> {
 // ❌ Returned CachedResponse<'buf> borrows from self.buf
 // But Stream::Item can be held arbitrarily long.
 }
}
```

### Error message

```text
error[E0700]: hidden type for `impl futures_core::Stream` captures lifetime that does not appear in bounds
error[E0310]: the parameter type may not live long enough
```

### Root cause

- Stream::Item can be held for an arbitrary duration.
- The returned item borrows from self.
- The borrow does not outlive the stream value.

### Fix: worker + channel pattern

```rust
// ✅ Worker owns buffers; consumers receive owned snapshots
pub struct SessionWorker {
 rx_events: Receiver<Bytes>,
 tx_snapshots: Sender<SnapshotResponse>,
 buf: Vec<u8>,
}

impl SessionWorker {
 pub async fn run(&mut self) {
        while let Some(event) = self.rx_events.recv().await {
            let snapshot = self.process_event(event);
            self.tx_snapshots.send(snapshot).await;
        }
 }

 fn process_event(&mut self, event: Bytes) -> SnapshotResponse {
        // It can borrow internally from self.buf.
        let start = self.buf.len();
        self.buf.extend_from_slice(&event);

        // But outside, return an owned SnapshotResponse.
        SnapshotResponse {
            id: self.next_id,
            payload: Bytes::copy_from_slice(&self.buf[start..]),
        }
}
}

// ✅ Stream only reads from a channel; all items are owned
pub struct SessionStream {
 rx_snapshots: Receiver<SnapshotResponse>,
}

impl Stream for SessionStream {
 type Item = Result<SnapshotResponse, Status>;

 fn poll_next(self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Option<Self::Item>> {
 // All items are owned SnapshotResponse values.
 }
}
```

---

## tokio::spawn + non-'static lifetime

### Problem code

```rust
// ❌ tokio::spawn requires 'static; BorrowedMessage<'a> is not 'static.
pub struct BorrowedMessage<'a> {
 pub raw: &'a [u8],
 pub meta: MessageMeta,
}

pub trait Plugin: Send + Sync {
 fn handle<'a>(&'a self, msg: BorrowedMessage<'a>)
 -> Pin<Box<dyn Future<Output = Result<(), HandlerError>> + Send + 'a>>;
}

fn dispatch_to_plugins(msg: BorrowedMessage<'a>) {
 for p in &plugins {
 let fut = p.handle(msg);
 tokio::spawn(fut); // ❌ fut is not 'static
 }
}
```

### Reason

- Tokio: :spawn does not know when the mission will be completed
- If the job holds reference, may have expired

### Solve: Event loop + actor model

```rust
// ✅ Oh, no. spawn,Each plugin is a permanent one. actor
struct PluginActor<M: MessageHandler> {
 plugin: M,
 queue: Receiver<PluginMsg>,
 arena: MessageArena,
}

impl<M: MessageHandler> PluginActor<M> {
 pub async fn run(&mut self) {
 while let Some(msg) = self.queue.recv().await {
 // Yes. arena Can not open message
 self.arena.with_message(msg, |msg_ref| {
 self.plugin.handle(msg_ref);
 });
 }
 }
}

// ✅ Index instead of direct borrowing
pub struct MessageRef {
 index: usize,
 generation: u64,
}

struct MessageArena {
 buffers: Vec<Arc<Buffer>>,
}

impl MessageArena {
 pub fn get(&self, ref: MessageRef) -> Option<&[u8]> {
 // Secured through indexing
 self.buffers.get(ref.index)?.get(ref.generation)
 }
}
```

---

## Plugin system scheduling pattern

### Constraints

1. Reuse zero-copy buffers
2. Hot-pluggable plugins
3. Async handlers
4. Retry/delayed ack

### Final structure

```text
┌─────────────────────────────────────┐
│ Decode Layer │ Holds buffers
├─────────────────────────────────────┤
│ MessageArena │ Buffer management
├─────────────────────────────────────┤
│ Event Loop │ Cooperative scheduling
├─────────────────────────────────────┤
│ Plugin Actor │ One per plugin
└─────────────────────────────────────┘
│
↓ API layer sees only owned data
┌─────────────────────────────────────┐
│ GraphQL / gRPC │ Requires 'static
└─────────────────────────────────────┘
```

### Key design

```rust
// 1. Buffer management arena
struct MessageArena {
 buffers: Vec<Arc<Buffer>>,
 free_list: Vec<usize>,
}

impl MessageArena {
 // Return an index, not a reference
 fn alloc(&mut self, data: &[u8]) -> MessageRef {
 let idx = self.buffers.len();
 self.buffers.push(Arc::new(data.to_vec()));
 MessageRef { index: idx, generation: 0 }
 }
}

// 2. API exposes only owned data
pub trait Plugin: Send + Sync {
 async fn handle(&self, msg: OwnedMessage); // owned
}
```

---

## Common problems

| Problem                     | Reason                        | Solve              |
|-----------------------------|-------------------------------|--------------------|
| Stream returns a borrow     | Item lifetime escapes         | Worker + channel   |
| tokio::spawn not 'static    | Tasks may hold temporary refs | Event-loop pattern |
| Plugin handler lifetime     | Plugin holds message          | Actor + index      |
| async-graphql + GAT         | 'static requirement           | Owned DTO          |
| tonic stream self-reference | Buffer reuse conflicts        | Snapshot pattern   |

---

## When to spawn, when to act

| scene                                   | Programme       |
|-----------------------------------------|-----------------|
| Independent missions, possible parallel | tokio::spawn    |
| Need for collaborative movement         | Event Loop      |
| Plugin System                           | Actor model     |
| Long-run statusful                      | Actor           |
| Short-term tasks                        | spawn           |
| We need back pressure control.          | Channel + actor |
