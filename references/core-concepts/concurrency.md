# Rust 并发模式

Rust 的类型系统在编译时强制实施内存安全和无数据竞争。

## Send 和 Sync

### Send - 可以在线程间转移

```rust
// 实现 Send 的类型：
// - 所有拥有类型（String、Vec 等）
// - 只有 Send 字段的类型
// - 引用（&T，其中 T: Sync）

// ❌ 不是 Send：Rc<T>（引用计数非原子）
```

### Sync - 可以在线程间共享

```rust
// 实现 Sync 的类型：
// - &T，其中 T: Send
// - Mutex<T>，其中 T: Send + Sync
// - 原子类型

// ❌ 不是 Sync：RefCell<T>（借用检查在运行时，非线程安全）
```

## 基本线程

### 创建线程

```rust
use std::thread;
use std::time::Duration;

fn main() {
    let handle = thread::spawn(|| {
        for i in 1..=5 {
            println!("线程: {}", i);
            thread::sleep(Duration::from_millis(100));
        }
    });
    
    for i in 1..=5 {
        println!("主线程: {}", i);
        thread::sleep(Duration::from_millis(100));
    }
    
    handle.join().unwrap();  // 等待线程完成
}
```

### 将值移动到线程

```rust
fn main() {
    let v = vec![1, 2, 3];
    
    let handle = thread::spawn(move || {
        println!("向量: {:?}", v);
    });
    
    handle.join().unwrap();
    // v 已被移动，此处无法使用
}
```

## 共享状态

### Mutex - 互斥锁

```rust
use std::sync::{Arc, Mutex};
use std::thread;

fn main() {
    let counter = Arc::new(Mutex::new(0));
    let mut handles = vec![];
    
    for _ in 0..10 {
        let counter = Arc::clone(&counter);
        let handle = thread::spawn(move || {
            let mut num = counter.lock().unwrap();
            *num += 1;
        });
        handles.push(handle);
    }
    
    for handle in handles {
        handle.join().unwrap();
    }
    
    println!("结果: {}", *counter.lock().unwrap());
}
```

### RwLock - 多读单写

```rust
use std::sync::{Arc, RwLock};
use std::thread;

fn main() {
    let data = Arc::new(RwLock::new(0));
    let mut handles = vec![];
    
    // 多个读者
    for _ in 0..5 {
        let data = Arc::clone(&data);
        let handle = thread::spawn(move || {
            let value = data.read().unwrap();
            println!("读取: {}", value);
        });
        handles.push(handle);
    }
    
    // 单个写者
    {
        let mut value = data.write().unwrap();
        *value += 100;
        println!("写入: {}", value);
    }
    
    for handle in handles {
        handle.join().unwrap();
    }
}
```

## 消息传递

### 通道（Channel）

```rust
use std::sync::mpsc;
use std::thread;

fn main() {
    let (tx, rx) = mpsc::channel();
    
    let tx1 = tx.clone();
    let handle1 = thread::spawn(move || {
        tx1.send("来自线程 1 的问候").unwrap();
    });
    
    let handle2 = thread::spawn(move || {
        tx.send("来自线程 2 的问候").unwrap();
    });
    
    for _ in 0..2 {
        println!("收到: {}", rx.recv().unwrap());
    }
    
    handle1.join().unwrap();
    handle2.join().unwrap();
}
```

### 发送多个值

```rust
use std::sync::mpsc;
use std::thread;

fn main() {
    let (tx, rx) = mpsc::channel();
    
    thread::spawn(move || {
        for i in 1..=5 {
            tx.send(i).unwrap();
            thread::sleep(std::time::Duration::from_millis(100));
        }
        drop(tx);  // 信号流结束
    });
    
    for received in rx {
        println!("收到: {}", received);
    }
    
    println!("通道已关闭");
}
```

## 原子类型

### 基础原子类型

```rust
use std::sync::atomic::{AtomicUsize, Ordering};
use std::thread;

fn main() {
    let counter = AtomicUsize::new(0);
    let mut handles = vec![];
    
    for _ in 0..10 {
        let counter = &counter;
        let handle = thread::spawn(move || {
            counter.fetch_add(1, Ordering::SeqCst);
        });
        handles.push(handle);
    }
    
    for handle in handles {
        handle.join().unwrap();
    }
    
    println!("计数器: {}", counter.load(Ordering::SeqCst));
}
```

### 原子顺序

```rust
use std::sync::atomic::{AtomicBool, Ordering};

// Relaxed - 无顺序保证，但原子操作
// Acquire - 与 Release 同步
// Release - 与 Acquire 同步
// SeqCst - 顺序一致性（最强，默认）

fn example(ordering: Ordering) {
    let flag = AtomicBool::new(false);
    
    // 大多数情况使用 SeqCst 保证正确性
    flag.store(true, Ordering::SeqCst);
    flag.load(Ordering::SeqCst);
}
```

## 作用域线程

### std::thread::scope

```rust
use std::thread;

fn main() {
    let mut numbers = vec![1, 2, 3];
    
    thread::scope(|s| {
        s.spawn(|| {
            println!("长度: {}", numbers.len());
        });
        
        s.spawn(|| {
            numbers.push(4);  // 允许可变访问！
        });
    });
    
    // numbers 在此处仍然有效 - 线程是有作用域的
    println!("数字: {:?}", numbers);
}
```

## 异步并发

### Tokio

```rust
use tokio::task;
use tokio::time::{sleep, Duration};

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let handle = task::spawn(async {
        for i in 1..=5 {
            println!("异步任务: {}", i);
            sleep(Duration::from_millis(100)).await;
        }
        "完成！"
    });
    
    println!("等待任务完成...");
    let result = handle.await?;
    println!("结果: {}", result);
    
    Ok(())
}
```

### 异步通道

```rust
use tokio::sync::mpsc;

#[tokio::main]
async fn main() {
    let (tx, mut rx) = mpsc::channel(32);
    
    tokio::spawn(async move {
        for i in 1..=5 {
            if tx.send(i).await.is_err() {
                break;
            }
        }
    });
    
    while let Some(value) = rx.recv().await {
        println!("收到: {}", value);
    }
}
```

### 异步 Mutex

```rust
use tokio::sync::Mutex;
use std::sync::Arc;

#[tokio::main]
async fn main() {
    let counter = Arc::new(Mutex::new(0));
    let mut tasks = vec![];
    
    for _ in 0..5 {
        let counter = Arc::clone(&counter);
        let task = tokio::spawn(async move {
            let mut guard = counter.lock().await;
            *guard += 1;
            println!("计数器: {}", *guard);
        });
        tasks.push(task);
    }
    
    for task in tasks {
        task.await.unwrap();
    }
    
    println!("最终值: {}", *counter.lock().await);
}
```

## 并行迭代器

```rust
use rayon::prelude::*;

fn main() {
    let numbers: Vec<i32> = (1..=1000).collect();
    
    let sum: i32 = numbers
        .par_iter()
        .map(|&x| x * x)
        .sum();
    
    println!("平方和: {}", sum);
}
```

## 同步原语

### OnceLock 和 OnceCell

```rust
use std::sync::OnceLock;

fn get_global_config() -> &'static Config {
    static CONFIG: OnceLock<Config> = OnceLock::new();
    
    CONFIG.get_or_init(|| {
        Config::load()
    })
}
```

### Barrier（屏障）

```rust
use std::sync::{Arc, Barrier};
use std::thread;

fn main() {
    let barrier = Arc::new(Barrier::new(10));
    let mut handles = vec![];
    
    for _ in 0..10 {
        let barrier = barrier.clone();
        let handle = thread::spawn(move || {
            println!("屏障前");
            barrier.wait();
            println!("屏障后");
        });
        handles.push(handle);
    }
    
    for handle in handles {
        handle.join().unwrap();
    }
}
```

## 最佳实践

### 应该做

```rust
// ✅ 使用 Arc 实现共享所有权
let shared = Arc::new(Data::new());

// ✅ 锁的范围尽可能小
{
    let data = mutex.lock().unwrap();
    process(&data);  // 处理时不要持有锁
}

// ✅ 使用通道实现松耦合
let (tx, rx) = mpsc::channel();

// ✅ 短期工作使用作用域线程
thread::scope(|s| {
    s.spawn(|| { /* ... */ });
});
```

### 不应该做

```rust
// ❌ 不要在异步代码中跨 await 点持有锁
let mut guard = mutex.lock().unwrap();
some_async_operation().await;  // 可能死锁！
drop(guard);  // 先释放

// ❌ 不要在多线程代码中使用 Rc
let rc = std::rc::Rc::new(42);
// thread::spawn(move || println!("{}", rc));  // 错误！

// ❌ 不要忘记 join 线程
let handle = thread::spawn(|| { /* ... */ });
handle.join();  // 总是要 join！
```

## 总结

| 原语 | 使用场景 |
|-----|---------|
| `thread::spawn` | 基本线程 |
| `Arc<Mutex<T>>` | 共享可变状态 |
| `Arc<RwLock<T>>` | 读写锁 |
| `mpsc::channel` | 消息传递 |
| `Atomic*` | 无锁计数器/标志 |
| `Barrier` | 线程组同步 |
| `Condvar` | 等待条件 |
| `tokio::spawn` | 异步任务 |
| `rayon` | 并行迭代器 |
