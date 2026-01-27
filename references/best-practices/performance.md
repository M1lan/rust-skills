# Rust 性能优化指南

本文档提供 Rust 性能优化的系统性指南，包括常见模式、工具和最佳实践。

## 性能优化优先级

```
1. 算法选择     (10x - 1000x)   ← 最大收益
2. 数据结构     (2x - 10x)
3. 减少分配     (2x - 5x)
4. 缓存优化     (1.5x - 3x)
5. SIMD/并行    (2x - 8x)
```

**警告**：过早优化是万恶之源。先让代码跑起来，再优化热点。

## 性能测量工具

### Benchmark

```bash
# cargo bench - 内置基准测试
cargo bench

# criterion - 统计基准测试
cargo bench --features criterion

# insta - 快照测试（回归检测）
cargo install cargo-insta
cargo insta test
```

### Profiling 工具

| 工具 | 用途 | 平台 |
|-----|------|------|
| `perf` | CPU 火焰图 | Linux |
| `flamegraph` | 可视化火焰图 | Linux/macOS |
| `heaptrack` | 内存分配追踪 | Linux |
| `valgrind --tool=cachegrind` | 缓存分析 | Linux |
| `dhat` | 堆分配分析 | 跨平台 |
| `tracy` | 实时性能分析 | 跨平台 |

### CPU 火焰图示例

```bash
# 生成火焰图
cargo flamegraph

# 或者使用 perf
perf record -F 99 --call-graph dwarf -a -- ./target/release/my_app
perf script | inferno-flamegraph > flamegraph.svg
```

## 内存优化

### 1. 预分配

```rust
// ❌ 每次增长都分配
let mut vec = Vec::new();
for i in 0..1000 {
    vec.push(i);
}

// ✅ 预分配已知大小
let mut vec = Vec::with_capacity(1000);
for i in 0..1000 {
    vec.push(i);
}
```

### 2. 避免不必要的 clone

```rust
// ❌ 不必要的 clone
fn process(item: &Item) {
    let data = item.data.clone();
    // ...
}

// ✅ 使用引用
fn process(item: &Item) {
    let data = &item.data;
    // ...
}
```

### 3. 小对象优化（SmallVec）

```rust
use smallvec::SmallVec;

// 16 个以内不分配堆内存
let mut vec: SmallVec<[u8; 16]> = SmallVec::new();

// 栈上数组
let mut array: SmallVec<[i32; 8]> = SmallVec::new();
array.push(1);
array.push(2);
```

### 4. 字符串优化

```rust
// ❌ 循环中字符串拼接 O(n²)
let mut result = String::new();
for i in 0..1000 {
    result.push_str(&format!("{}", i));
}

// ✅ 使用 with_capacity
let mut result = String::with_capacity(4000);
for i in 0..1000 {
    use std::fmt::Write;
    write!(&mut result, "{}", i).unwrap();
}

// ✅ 使用 push_str 直接操作
let mut result = String::with_capacity(4000);
for i in 0..1000 {
    result.push_str(i.to_string().as_str());
}
```

## 数据结构选择

### 集合对比

| 场景 | 推荐 | 不推荐 |
|-----|------|-------|
| 少量元素（<1000） | `Vec` + 线性搜索 | `HashMap` |
| 大量元素查找 | `HashMap` / `BTreeMap` | `Vec` |
| 顺序访问 | `Vec` / `VecDeque` | `LinkedList` |
| LIFO 栈 | `Vec` | `LinkedList` |
| FIFO 队列 | `VecDeque` | `LinkedList` |
| 随机访问 | `Vec` | `LinkedList` |

### 示例：什么时候用 Vec 而不是 HashMap

```rust
// 少量元素，线性搜索更快
let small_map: Vec<(u32, String)> = vec![
    (1, "one".to_string()),
    (2, "two".to_string()),
];

// 线性搜索 O(n)，但 n 很小，开销更低
for (k, v) in &small_map {
    if *k == target {
        return Some(v);
    }
}

// 大量元素，HashMap 更快
let large_map: HashMap<u32, String> = (0..10000)
    .map(|i| (i, format!("{}", i)))
    .collect();

// 哈希查找 O(1)，比线性搜索快得多
large_map.get(&target);
```

## 避免反模式

| 反模式 | 为什么不好 | 正确做法 |
|-------|-----------|---------|
| clone 躲避生命周期 | 性能开销 | 正确所有权设计 |
| 什么都 Box | 间接成本 | 优先栈分配 |
| HashMap 小数据集 | 开销过大 | Vec + 线性搜索 |
| 循环中字符串拼接 | O(n²) | with_capacity 或 format! |
| LinkedList | 缓存不友好 | Vec 或 VecDeque |
| 频繁 small_to_big | 重新分配开销 | 预分配大小 |

## 并行处理

### Rayon 并行迭代

```rust
use rayon::prelude::*;

let data: Vec<i32> = (0..1_000_000).collect();

// 并行求和
let sum: i32 = data.par_iter().sum();

// 并行映射
let doubled: Vec<i32> = data.par_iter()
    .map(|x| x * 2)
    .collect();

// 并行过滤
let evens: Vec<i32> = data.par_iter()
    .filter(|&&x| x % 2 == 0)
    .cloned()
    .collect();
```

### 并行性能提示

```rust
// 1. 数据量足够大才并行
if data.len() < 1000 {
    data.iter().sum()  // 单线程更快
} else {
    data.par_iter().sum()  // 并行更快
}

// 2. 减少跨线程数据传输
let expensive_result = data.par_iter()
    .map(|x| compute(x))  // 复杂计算
    .reduce(|| 0.0, |a, b| a + b);  // 合并结果

// 3. 使用 fold 而不是 collect（减少内存）
let result: i32 = (0..1_000_000).par_iter()
    .fold(|| 0, |acc, &x| acc + x)
    .sum();
```

## 锁优化

### 减少锁持有时间

```rust
// ❌ 锁持有期间做耗时操作
let mut guard = mutex.lock().unwrap();
process_data(&guard.data);  // 耗时操作，阻塞其他线程
guard.data = new_data;

// ✅ 最小化锁范围
let new_data = process_data(&guard.data);  // 锁外计算
*guard = new_data;  // 只在锁内赋值
```

### 使用适当的锁

```rust
use std::sync::{Mutex, RwLock};

// 读多写少 → RwLock
let lock = RwLock::new(data);

// 多个读者
let reader = lock.read().unwrap();
// ... 读取操作

// 单个写者
let mut writer = lock.write().unwrap();
// ... 写入操作

// 简单计数器 → Atomic
use std::sync::atomic::{AtomicUsize, Ordering};
let counter = AtomicUsize::new(0);
counter.fetch_add(1, Ordering::SeqCst);
```

## 编译器优化

### Cargo 配置

```toml
[profile.release]
opt-level = 3        # 最高优化级别
lto = true           # 链接时优化
codegen-units = 1    # 单个代码生成单元（更好优化）
panic = "abort"      # 减少 panic 展开代码
strip = true         # 移除调试符号

[profile.dev]
opt-level = 0        # 开发时快速编译
debug = true         # 保留调试信息
```

### 内联控制

```rust
// 强制内联热点函数
#[inline(always)]
fn small_function(x: i32) -> i32 {
    x + 1
}

// 提示编译器内联
#[inline]
fn frequently_called() {
    // ...
}

// 避免不必要内联（减少代码膨胀）
#[inline(never)]
fn rarely_called_expensive() {
    // ...
}
```

## 常见问题排查

| 症状 | 可能原因 | 排查方法 |
|-----|---------|---------|
| 内存持续增长 | 泄漏、累积 | heaptrack |
| CPU 占用高 | 算法问题 | flamegraph |
| 响应不稳定 | 分配波动 | dhat |
| 吞吐量低 | 串行处理 | rayon 并行 |
| 延迟高 | 锁竞争 | perf lock |
| 缓存命中率低 | 数据结构不友好 | cachegrind |

## 优化检查清单

- [ ] 测了吗？不要猜测
- [ ] 瓶颈确认了吗？
- [ ] 算法最优吗？
- [ ] 数据结构合适吗？
- [ ] 减少不必要的分配了吗？
- [ ] 能并行吗？
- [ ] 释放内存了吗？（RAII）
- [ ] 锁范围最小化了吗？
- [ ] 编译优化开启了吗？

## 进一步阅读

- [Rust Performance Book](https://nnethercote.github.io/perf-book/)
- [Compiler Explorer](https://godbolt.org/) - 查看汇编输出
- [Cargo Profile](https://doc.rust-lang.org/cargo/reference/profiles.html)

