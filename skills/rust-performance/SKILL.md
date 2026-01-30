---
name: rust-performance
description: "Performance optimization: benchmarking, profiling, allocation, SIMD, cache, and bottleneck analysis. Triggers: performance, optimization, benchmark, profiling, allocation, SIMD, cache"
globs: ["**/*.rs"]
---

# Performance Optimization

## Core issues

**Key question:** Where are the bottlenecks, and is optimization worth it?

First measure, then optimize. Don't guess.

---

## Optimization priorities

```
1. Algorithm selection (10x - 1000x) ← biggest wins
2. Data structures (2x - 10x)
3. Reduce allocations (2x - 5x)
4. Cache Optimization (1.5x - 3x)
5. SIMD/Parallel (2x - 8x)
```

**Warning:** Premature optimization is the root of all evil.

---

## Measurement tools

### Benchmarking

```bash
# cargo bench
cargo bench
# criterion: statistical benchmarking
```

### Profiling

| Tools | Use |
|-----|------|
| `perf` / `flamegraph` | CPU flamegraph |
| `heaptrack` | Allocation Tracking |
| `valgrind --tool=cachegrind` | Cache Analysis |
| `dhat` | Heap allocation analysis |

---

## Common optimization techniques

### 1. Pre-allocation

```rust
// ❌ Each push can reallocate.
let mut vec = Vec::new();
for i in 0..1000 {
 vec.push(i);
}

// ✅ Pre-allocate known size
let mut vec = Vec::with_capacity(1000);
for i in 0..1000 {
 vec.push(i);
}
```

### 2. Avoid unnecessary clones

```rust
// ❌ Unnecessary clone
fn process(item: &Item) {
 let data = item.data.clone();
 // ...
}

// ✅ Use references
fn process(item: &Item) {
 let data = &item.data;
 // ...
}
```

### 3. Batch operations

```rust
// ❌ Multiple database calls
for user_id in user_ids {
 db.update(user_id, status)?;
}

// ✅ Batch Update
db.update_all(user_ids, status)?;
```

### 4. Small object optimization

```rust
// Use SmallVec for small collections
use smallvec::SmallVec;
let mut vec: SmallVec<[u8; 16]> = SmallVec::new();
// 16 elements inline
```

### 5. Parallel processing

```rust
use rayon::prelude::*;
let sum: i32 = data
    .par_iter()
    .map(|x| expensive(x))
    .sum();
```

---

## Anti-patterns

| Anti-pattern | Why not? | Better |
|-------|-----------|---------|
| Clones to avoid lifetimes | Performance cost | Design ownership properly |
| Boxing everything | Indirection cost | Prefer stack/inline types |
| HashMap for tiny datasets | Overhead dominates | Vec + linear search |
| Repeated string concat in loops | O(n²) | `with_capacity` or `format!` |
| LinkedList | Poor cache locality | `Vec` or `VecDeque` |

---

## Symptom checklist

| Symptom | Possible causes | Query |
|-----|---------|---------|
| Memory keeps growing | Leaks or unbounded caches | heaptrack |
| High CPU usage | Algorithm hotspots | flamegraph |
| Latency spikes | Allocation churn | dhat |
| Low throughput | Serial work | rayon parallelism |

---

## Optimization checklist

- [ ] Have you measured it? Don't guess.
- [ ] Are bottlenecks confirmed?
- [ ] Is the algorithm best?
- [ ] Is the data structure appropriate?
- [ ] Are unnecessary allocations reduced?
- [ ] Can work be parallelized?
- [ ] Has the memory been released? (RAII)

---

# Advanced performance optimization

> The following target multi-threaded, high-concurrency scenarios.

## Why is multi-threaded code slower?

Performance problems are often hidden in invisible places.

---

## False sharing

### Symptom

```rust
// Problem: multiple AtomicU64 packed into one struct
struct ShardCounters {
 inflight: AtomicU64,
 completed: AtomicU64,
}
```

- One core is pegged at 90%+
- perf shows many LLC misses
- Atomic RMW operations dominate
- Adding threads makes it slower

### Diagnosis

```bash
# perf analysis
perf stat -d
# Look at LLC-load-misses and locked-instrs

# Flamegraph
cargo flamegraph
# Find atomic fetch_add hotspots
```

### Fix: cache-line padding

```rust
// One cache line per field
#[repr(align(64))]
struct PaddedAtomicU64(AtomicU64);

struct ShardCounters {
 inflight: PaddedAtomicU64,
 completed: PaddedAtomicU64,
}
```

### Validation

```rust
// Benchmark comparison
fn bench_naive() { /* multiple AtomicU64 */ }
fn bench_padded() { /* separate cache lines */ }
```

---

## Lock contention optimization

### Symptom

```rust
// Global HashMap shared by all threads
let shared: Arc<Mutex<HashMap<String, usize>>> = Arc::new(Mutex::new(HashMap::new()));
```

- Lots of time in mutex lock/unlock
- Performance stagnates or degrades with more threads
- High system time

### Fix: shard local counts

```rust
// Per-thread HashMap, merge at the end
pub fn parallel_count(data: &[String], num_threads: usize) -> HashMap<String, usize> {
 let mut handles = Vec::new();
 
 for chunk in data.chunks(/*...*/) {
 handles.push(thread::spawn(move || {
 let mut local = HashMap::new();
 for key in chunk {
 *local.entry(key).or_insert(0) += 1;
 }
 local // Return local count
 }));
 }
 
 // Merge all local results
 let mut result = HashMap::new();
 for handle in handles {
 for (k, v) in handle.join().unwrap() {
 *result.entry(k).or_insert(0) += v;
 }
 }
 result
}
```

---

## NUMA awareness

### Problem scene

```rust
// Multi-socket servers: memory is allocated on a remote NUMA node
let pool = ArenaPool::new(num_threads);
// Rayon work-stealing can run tasks on any thread.
// Cross-NUMA access adds significant latency.
```

### Solve

```rust
// 1. Bind to a NUMA node
let numa_node = detect_numa_node();
let pool = NumaAwarePool::new(numa_node);

// 2. Use a NUMA-aware allocator (jemalloc)
#[global_allocator]
static ALLOC: jemallocator::Jemalloc = jemallocator::Jemalloc;

// 3. Avoid cross-NUMA object copies
// Borrow directly; do not copy data across nodes.
```

### Tools

```bash
# Inspect NUMA topology
numactl --hardware

# Bind to a NUMA node
numactl --cpunodebind=0 --membind=0 ./my_program
```

---

## Data structure optimization

### HashMap vs.

| Scenario | Option | Reason |
|-----|------|-----|
| High concurrency | DashMap or sharded map | Reduces lock contention |
| Read-heavy | `RwLock<HashMap>` | Readers don't block each other |
| Small dataset | Vec + linear search | HashMap overhead dominates |
| Fixed keys | Enum + array | Avoid hash cost |

### Example: Read more and write less

```rust
// Many reads, few updates
struct Config {
 map: RwLock<HashMap<String, ConfigValue>>,
}

impl Config {
 pub fn get(&self, key: &str) -> Option<ConfigValue> {
 self.map.read().get(key).cloned()
 }
 
 pub fn update(&self, key: String, value: ConfigValue) {
 self.map.write().insert(key, value);
 }
}
```

---

## Common traps.

| Trap | Symptom | Solve |
|-----|------|-----|
| Adjacent atomic fields | False sharing | `#[repr(align(64))]` |
| Global mutex | Lock contention | Local counts + merge |
| Cross-NUMA allocation | Memory migration | NUMA-aware allocation |
| Frequent small allocations | Allocator pressure | Object pool |
| Dynamic string keys | Extra allocation | Use integer IDs |

---

## Performance diagnostic tool

| Tools | Use |
|-----|------|
| `perf stat -d` | CPU cycles, cache metrics |
| `perf record -g` | Sampled flamegraph |
| `valgrind --tool=cachegrind` | Cache analysis |
| `jemalloc profiling` | Allocation analysis |
| `numactl` | NUMA affinity |
