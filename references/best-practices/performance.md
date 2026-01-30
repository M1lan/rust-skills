# Rust Performance Optimization Guide

This document provides systematic guidance for Rust performance optimization, including common models, tools and best practices.

## Performance optimization priority

```
1. Algebra Selection (10x - 1000x) ← Maximum proceeds
2. Data structure (2x - 10x)
3. Reduction in distribution (2x - 5x)
4. Cache Optimization (1.5x - 3x)
5. SIMD/Parallel (2x - 8x)
```

 Warning**: Early optimization is the source of all evils.

## Performance Measurement Tool

### Benchmark

```bash
# cargo bench - Internal benchmark test
cargo bench

# criterion - Statistical benchmarking tests
cargo bench --features criterion

# insta - Quick test.(Return detection)
cargo install cargo-insta
cargo insta test
```

### Profiling Tool

| Tools | Use | Platform |
|-----|------|------|
| `perf` | CPU Flame Chart | Linux |
| `flamegraph` | Visible flame map | Linux/macOS |
| `heaptrack` | Memory Allocation Tracking | Linux |
| `valgrind --tool=cachegrind` | Cache Analysis | Linux |
| `dhat` | Stack distribution analysis | Cross Platform |
| `tracy` | Real-time performance analysis | Cross Platform |

### Example of CPU flame map

```bash
# Generate flame maps
cargo flamegraph

# Or use perf
perf record -F 99 --call-graph dwarf -a -- ./target/release/my_app
perf script | inferno-flamegraph > flamegraph.svg
```

## Memory Optimization

### 1. Pre-allocation

```rust
// ❌ Every increase is allocated.
let mut vec = Vec::new();
for i in 0..1000 {
 vec.push(i);
}

// ✅ Pre-allocation Known Size
let mut vec = Vec::with_capacity(1000);
for i in 0..1000 {
 vec.push(i);
}
```

### Two. ... avoid unnecessary

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

### 3. SmallVec

```rust
use smallvec::SmallVec;

// 16 bytes inline
let mut vec: SmallVec<[u8; 16]> = SmallVec::new();

// Example
let mut array: SmallVec<[i32; 8]> = SmallVec::new();
array.push(1);
array.push(2);
```

### 4. String optimization

```rust
// ❌ String concatenation in a loop: O(n²)
let mut result = String::new();
for i in 0..1000 {
 result.push_str(&format!("{}", i));
}

// ✅ Use with_capacity
let mut result = String::with_capacity(4000);
for i in 0..1000 {
 use std::fmt::Write;
 write!(&mut result, "{}", i).unwrap();
}

// ✅ Use push_str Direct Operations
let mut result = String::with_capacity(4000);
for i in 0..1000 {
 result.push_str(i.to_string().as_str());
}
```

## Data structure selection

### Selection guidelines

| Scenario | Recommended | Not recommended |
|-----|------|-------|
| Small number of elements (<1,000) | `Vec` + linear search | `HashMap` |
| Many lookups | `HashMap` / `BTreeMap` | `Vec` |
| Sequential access | `Vec` / `VecDeque` | `LinkedList` |
| LIFO | `Vec` | `LinkedList` |
| FIFO queue | `VecDeque` | `LinkedList` |
| Random access | `Vec` | `LinkedList` |

### Example: When to use Vec instead of HashMap

```rust
// Small number of elements: linear search is faster
let small_map: Vec<(u32, String)> = vec![
 (1, "one".to_string()),
 (2, "two".to_string()),
];

// Linear search O(n), but n is small so it's cheaper
for (k, v) in &small_map {
 if *k == target {
 return Some(v);
 }
}

// Large number of elements: HashMap is faster
let large_map: HashMap<u32, String> = (0..10000)
 .map(|i| (i, format!("{}", i)))
 .collect();

// Hash lookup O(1), faster than linear search
large_map.get(&target);
```

## Avoid anti-patterns

| Anti-pattern | Why not | Better |
|-------|-----------|---------|
| Cloning to avoid lifetimes | Performance cost | Proper ownership design |
| Boxing everything | Indirection cost | Prefer stack allocation |
| HashMap for small datasets | Too much overhead | Vec + linear search |
| String concatenation in loops | O(n²) | `with_capacity` or `format!` |
| LinkedList | Cache-unfriendly | Vec or VecDeque |
| Frequent small-to-big growth | Reallocation cost | Pre-allocate size |

## Parallel processing

### Rayon Parallel

```rust
use rayon::prelude::*;

let data: Vec<i32> = (0..1_000_000).collect();

// Parallel Summon
let sum: i32 = data.par_iter().sum();

// Parallel Map
let doubled: Vec<i32> = data.par_iter()
 .map(|x| x * 2)
 .collect();

// Parallel Filter
let evens: Vec<i32> = data.par_iter()
 .filter(|&&x| x % 2 == 0)
 .cloned()
 .collect();
```

### Parallel Performance Tips

```rust
// 1. The amount of data is big enough to go in parallel.
if data.len() < 1000 {
 data.iter().sum() // One-way faster.
} else {
 data.par_iter().sum() // Parallel faster.
}

// 2. Reduce cross-line data transfer
let expensive_result = data.par_iter()
 .map(|x| compute(x)) // Complex calculations
 .reduce(|| 0.0, |a, b| a + b); // Merge Results

// 3. Use fold Not collect(Decrease Memory)
let result: i32 = (0..1_000_000).par_iter()
 .fold(|| 0, |acc, &x| acc + x)
 .sum();
```

## Lock Optimization

### Reduce lock holding time

```rust
// ❌ Time-consuming operation during lock holding
let mut guard = mutex.lock().unwrap();
process_data(&guard.data); // Time-consuming Operations,Block Other Threads
guard.data = new_data;

// ✅ Minimize lock range
let new_data = process_data(&guard.data); // Lockout Calculator
*guard = new_data; // Only locked internal values
```

### Use appropriate locks

```rust
use std::sync::{Mutex, RwLock};

// Read and write. → RwLock
let lock = RwLock::new(data);

// Multiple Readers
let reader = lock.read().unwrap();
// ... Read Operations

// Single author
let mut writer = lock.write().unwrap();
// ... Writing Operations

// Simple counter → Atomic
use std::sync::atomic::{AtomicUsize, Ordering};
let counter = AtomicUsize::new(0);
counter.fetch_add(1, Ordering::SeqCst);
```

## Compiler optimization

### Cargo configuration

```toml
[profile.release]
opt-level = 3        # Highest optimization level
lto = true           # Link-time optimization
codegen-units = 1    # Single codegen unit (better optimization)
panic = "abort"      # Reduce panic unwind code
strip = true         # Remove debug symbols

[profile.dev]
opt-level = 0        # Fast compile during development
debug = true         # Keep debug info
```

### Inline control

```rust
// Force inline hot functions
#[inline(always)]
fn small_function(x: i32) -> i32 {
 x + 1
}

// Hint the compiler to inline
#[inline]
fn frequently_called() {
 // ...
}

// Avoid unnecessary inlining (reduce code bloat)
#[inline(never)]
fn rarely_called_expensive() {
 // ...
}
```

## Common issue checklist

| Symptom | Possible causes | Query |
|-----|---------|---------|
| Memory keeps growing | Leaks, accumulation | heaptrack |
| High CPU usage | Algorithm issues | flamegraph |
| Unstable latency | Allocation churn | dhat |
| Low throughput | Serial processing | rayon parallelism |
| High latency | Lock contention | perf lock |
| Low cache hit rate | Unfriendly data structures | cachegrind |

## Optimization checklist

- [ ] Have you measured it? Don't guess.
- [ ] Are bottlenecks confirmed?
- [ ] Is the algorithm optimal?
- [ ] Is the data structure appropriate?
- [ ] Are unnecessary allocations reduced?
- [ ] Can it be parallelized?
- [ ] Has memory been released? (RAII)
- [ ] Is the lock scope minimized?
- [ ] Are compiler optimizations enabled?

## Further reading

- [Rust Performance Book](https://nnethercote.github.io/perf-book/)
- [Compiler Explorer](https://godbolt.org/) - inspect generated assembly
- [Cargo Profiles](https://doc.rust-lang.org/cargo/reference/profiles.html)

- [Rust Performance Book](https://nnethercote.github.io/perf-book/)
- [Compiller Express] ( - View compilation output
- [Cargo Profile](https://doc.rust-lang.org/cargo/reference/profiles.html)
