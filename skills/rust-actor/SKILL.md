---
name: rust-actor
description: "Actor model: message passing, supervision, state management, deadlock avoidance. Triggers: actor, actix, supervision, mailbox, message"
globs: ["**/*.rs"]
---

# Actor Model

## Core issues

Key question: How do we avoid deadlocks and achieve reliable communication in an actor system?

The actor model simplifies concurrency through message passing and isolation.

---

## Actor vs thread model

| Feature          | Thread Model             | Actor Model               |
|------------------|--------------------------|---------------------------|
| State sharing    | Shared memory + locks    | Message passing           |
| Deadlock risk    | High (lock order issues) | Low                       |
| Scalability      | Limited by threads       | Can scale to many actors  |
| Fault management | Manual                   | Supervision tree          |
| Debugging        | Hard (data races)        | Easier (message ordering) |

---

## Actor Core Structure

```rust
// Actor Foundation trait
trait Actor: Send + 'static {
 type Message: Send + 'static;
 type Error: std::error::Error;

 fn receive(&mut self, ctx: &mut Context<Self::Message>, msg: Self::Message);
}

// Actor Context
struct Context<A: Actor> {
 mailbox: Receiver<A::Message>,
 sender: Sender<A::Message>,
 state: ActorState,
 supervisor: Option<SupervisorAddr>,
}

enum ActorState {
 Starting,
 Running,
 Restarting,
 Stopping,
 Stopped,
}
```

---

## Message transmission

```rust
// Synchronous request
fn sync_request<A: Actor, R>(
 actor: &Addr<A>,
 msg: A::Message,
 timeout: Duration,
) -> Result<R, A::Error> {
 let (tx, rx) = channel();
 let request = Request {
 payload: msg,
 response: tx,
 };

 actor.send(request)?;

 rx.recv_timeout(timeout)?
}

// Asynchronous send
fn async_send<A: Actor>(actor: &Addr<A>, msg: A::Message) {
 actor.send(msg);
}

// Message envelope
enum Envelope<A: Actor> {
 Async(A::Message),
 Request {
 payload: A::Message,
 response: Sender<Result<A::Response, A::Error>>,
 },
 Signal(ActorSignal),
}
```

---

## Deadlock prevention

```rust
// 1. Avoid cyclical waits by enforcing ordering
enum GlobalMessage {
 // Ordered in constant order
 UserMsg(UserMessage),
 SystemMsg(SystemMessage),
 InternalMsg(InternalMessage),
}

// 2. Timeout mechanism
fn send_with_timeout<A: Actor, M: Send + 'static>(
 addr: &Addr<A>,
 msg: M,
 timeout: Duration,
) -> Result<(), SendError<M>> {
 let (tx, rx) = channel();

 addr.send(AsyncWrapper { msg, reply_to: tx });

 rx.recv_timeout(timeout)
 .map(|_| ())
 .map_err(|_| SendError::Timeout)
}

// 3. Limit mailbox size (backpressure)
struct BoundedMailbox<A: Actor> {
 receiver: Receiver<A::Message>,
 sender: Sender<A::Message>,
 capacity: usize,
}

impl<A: Actor> Mailbox for BoundedMailbox<A> {
 fn capacity(&self) -> usize {
 self.capacity
 }
}
```

---

## Supervision Tree

```rust
// Supervision Policy
enum SupervisionStrategy {
 OneForOne, // Only restart the failed actor
 AllForOne, // Restart all when one fails
 RestForOne, // Restart actors after the failed one
}

struct Supervisor {
 children: HashMap<ChildId, Child>,
 strategy: SupervisionStrategy,
 max_restarts: u32,
 window: Duration,
}

impl Supervisor {
 fn handle_child_error(&mut self, child_id: ChildId, error: &dyn std::error::Error) {
 let child = self.children.get_mut(&child_id).unwrap();
 child.restart_count += 1;

 if self.should_restart(child_id) {
 self.restart_child(child_id);
 } else {
 self.stop_child(child_id);
 }
 }

 fn should_restart(&self, child_id: ChildId) -> bool {
 let child = &self.children[&child_id];
 child.restart_count <= self.max_restarts
 }
}
```

---

## Status Management

```rust
// Actor Internal Status
struct UserActor {
 id: UserId,
 session: Option<Session>,
 message_history: Vec<Message>,
 followers: HashSet<UserId>,
}

impl Actor for UserActor {
 type Message = UserMessage;

 fn receive(&mut self, ctx: &mut Context<Self::Message>, msg: Self::Message) {
 match msg {
 UserMessage::Login(session) => {
 self.session = Some(session);
 }
 UserMessage::Post(content) => {
 if let Some(session) = &self.session {
 self.message_history.push(Message {
 content,
 timestamp: Utc::now(),
 user: session.user_id,
 });
 }
 }
 UserMessage::Follow(target_id) => {
 self.followers.insert(target_id);
 }
 }
 }
}

// Statusshot
impl UserActor {
 fn snapshot(&self) -> UserSnapshot {
 UserSnapshot {
 id: self.id,
 message_count: self.message_history.len(),
 followers_count: self.followers.len(),
 is_online: self.session.is_some(),
 }
 }
}
```

---

## Actor Life Cycle

```rust
// Lifetime events
enum LifecycleEvent {
 PreStart,
 PostStart,
 PreRestart,
 PostRestart,
 PostStop,
}

trait LifecycleHandler: Actor {
 fn pre_start(&mut self, ctx: &mut Context<Self::Message>) {
 // Initialization Resources
 }

 fn post_start(&mut self, ctx: &mut Context<Self::Message>) {
 // Start Timer,Connection etc.
 }

 fn pre_restart(&mut self, ctx: &mut Context<Self::Message>, error: &dyn std::error::Error) {
 // Cleaning up resources
 }

 fn post_stop(&mut self) {
 // Save Status,Close Connection
 }
}
```

---

## Actix Example

```rust
// Actix Web Actor
use actix::{Actor, Handler, Message, Context};

struct MyActor {
 counter: usize,
}

impl Actor for MyActor {
 type Context = Context<Self>;

 fn started(&mut self, _ctx: &mut Self::Context) {
 println!("Actor started");
 }
}

#[derive(Message)]
#[rtype(result = "usize")]
struct Increment;

impl Handler<Increment> for MyActor {
 type Result = usize;

 fn handle(&mut self, msg: Increment, _ctx: &mut Self::Context) -> Self::Result {
 self.counter += 1;
 self.counter
 }
}

// Use
let actor = MyActor { counter: 0 }.start();
let result = actor.send(Increment).await?;
```

---

## Common problems

| Problem             | Reason               | Solve                              |
|---------------------|----------------------|------------------------------------|
| Deadlock.           | Can not open message | Timeout, avoiding cycle dependence |
| Information backlog | Consumers slow       | Back pressure, restricted flow.    |
| Memory Leak         | Actor didn't stop.   | Lifetime management                |
| Inconsistencies     | Send Message         | Ordered, single-lined              |

---

## Links to other skills

```text
rust-actor
 │
 ├─► rust-concurrency → Parallel Model
 ├─► rust-async → We're on a async.
 └─► rust-error → Error Dissemination
```
