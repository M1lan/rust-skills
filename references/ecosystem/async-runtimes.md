# 异步运行时对比：Tokio vs async-std

Rust 异步编程需要运行时（Runtime）来执行 Future。本文档对比主流异步运行时。

## 主流运行时对比

| 特性 | Tokio | async-std | smol | async-executor |
|-----|-------|-----------|------|----------------|
| 下载量 | ~50M | ~8M | ~2M | ~1M |
| 稳定性 | 稳定 | 稳定 | 实验性 | 稳定 |
| 性能 | 高 | 中 | 高 | 高 |
| 异步生态 | 丰富 | 一般 | 正在发展 | 轻量级 |

## Tokio

### 特点

- **最流行**：生态最完善，文档最丰富
- **多功能**：提供 I/O、计时器、文件系统、网络等
- **多线程**：默认多线程运行时
- **延迟低**：针对低延迟优化

### 基本使用

```rust
use tokio::{time, net::TcpListener, sync::Mutex};

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // 并发任务
    tokio::spawn(async {
        // 异步代码
    });

    // 计时器
    time::sleep(std::time::Duration::from_secs(1)).await;

    // 互斥锁（异步）
    let lock = Mutex::new(0);
    let mut guard = lock.lock().await;
    *guard += 1;

    Ok(())
}
```

### 运行时配置

```rust
#[tokio::main(flavor = "multi_thread", worker_threads = 4)]
async fn main() {
    // 多线程模式，4 个工作线程
}

#[tokio::main(flavor = "current_thread")]
async fn main() {
    // 单线程模式
}
```

## async-std

### 特点

- **标准库风格**：API 类似 std
- **一致性**：与 std 命名一致
- **轻量级**：依赖较少
- **集成简单**：容易集成到现有项目

### 基本使用

```rust
use async_std::{net::TcpListener, sync::Mutex};

#[async_std::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // 并发任务
    async_std::spawn(async {
        // 异步代码
    });

    // 互斥锁
    let lock = Mutex::new(0).await;
    let mut guard = lock.lock().await;
    *guard += 1;

    Ok(())
}
```

## 选择建议

### 选择 Tokio 的情况

```rust
// 1. 生产环境 Web 服务
// tokio 是最成熟的选择

// 2. 需要高性能网络
// tokio 的网络栈经过大量优化

// 3. 需要完整的异步生态
// tokio::spawn, tokio::time, tokio::fs 等

// 4. 多线程并发
// tokio 的多线程运行时成熟稳定
```

### 选择 async-std 的情况

```rust
// 1. 代码风格一致性
// 如果你更喜欢 std 的命名风格

// 2. 轻量级依赖
// 项目不想引入 tokio 的全部依赖

// 3. 学习目的
// async-std 更接近标准库的抽象
```

### 选择 smol 的情况

```rust
// 1. 极简需求
// smol 是最小的运行时

// 2. 需要与其他运行时互操作
// smol 可以嵌入到其他运行时中

// 3. 实验性项目
// smol 支持最新的异步特性
```

## 性能对比

### 任务创建开销

```rust
// Tokio: 低开销的任务创建
tokio::spawn(async {
    // 轻量级任务
});

// async-std: 类似的开销
async_std::spawn(async {
    // 轻量级任务
});
```

### 通道性能

```rust
// Tokio mpsc 通道
use tokio::sync::mpsc;
let (tx, rx) = mpsc::channel(100);

// async-std mpsc 通道
use async_std::channel;
let (tx, rx) = channel::bounded(100);
```

## 互操作性

### 在 tokio 中运行 async-std

```rust
use tokio::runtime::Runtime;

fn main() {
    let rt = Runtime::new().unwrap();
    rt.block_on(async {
        async_std::task::sleep(std::time::Duration::from_secs(1)).await;
    });
}
```

### 在 async-std 中运行 tokio

```rust
use async_std::task;

fn main() {
    task::block_on(async {
        tokio::time::sleep(std::time::Duration::from_secs(1)).await;
    });
}
```

## 推荐配置

### Web 服务配置

```rust
// Cargo.toml
[dependencies]
tokio = { version = "1.0", features = ["full"] }
axum = "0.7"
sqlx = "0.7"

[profile.release]
lto = true
codegen-units = 1
```

### 轻量级配置

```rust
// Cargo.toml
[dependencies]
async-std = { version = "1.0", features = ["attributes"] }
surf = "2.0"

[dependencies.tokio]
version = "1.0"
features = ["rt", "time"]
optional = true
```

## 常见问题

### Q: 可以混合使用不同的运行时吗？

A: 不建议在同一项目中使用多个运行时。每个运行时都有自己的调度器，混合使用会导致问题。

### Q: 什么时候需要自定义运行时？

```rust
// 高性能场景可能需要自定义配置
use tokio::runtime::Builder;

fn main() {
    let rt = Builder::new()
        .threaded_hammer()  // 优化线程创建
        .worker_threads(16) // 增加工作线程
        .max_blocking_threads(512) // 增加阻塞线程
        .build()
        .unwrap();

    rt.block_on(async {
        // 应用代码
    });
}
```

### Q: 如何测试异步代码？

```rust
#[cfg(test)]
mod tests {
    use tokio::test as tokio_test;

    #[tokio_test]
    async fn test_async_function() {
        // 测试异步代码
    }

    #[async_std::test]
    async fn test_async_std_function() {
        // 测试 async-std 代码
    }
}
```

