# Rust 术语中英文对照表

> 本项目采用中英混合风格，本文列出推荐的标准术语对照。

## 核心概念

| 英文 | 中文（推荐） | 英文缩写 | 说明 |
|------|-------------|---------|------|
| Ownership | 所有权 | - | Rust 核心特性 |
| Borrowing | 借用 | - | |
| Lifetime | 生命周期 | - | |
| Move | 移动 | - | 值的所有权转移 |
| Clone | 克隆 | - | 深拷贝 |
| Copy | 拷贝 | - | 按位复制 |
| Borrow Checker | 借用检查器 | - | 编译时检查 |

## 类型系统

| 英文 | 中文（推荐） | 说明 |
|------|-------------|------|
| Trait | 特质 | 类似于接口 |
| Generic | 泛型 | |
| Associated Type | 关联类型 | |
| Generic Associated Type | 泛型关联类型 | GAT |
| Higher-Ranked Trait Bound | 高阶 trait 约束 | HRTB |
| Phantom Data | 虚类型 | |
| Smart Pointer | 智能指针 | |

## 智能指针

| 英文 | 中文（推荐） | 线程安全 | 说明 |
|------|-------------|---------|------|
| Box<T> | 箱 | 否 | 堆分配 |
| Rc<T> | 引用计数 | 否 | 单线程共享 |
| Arc<T> | 原子引用计数 | 是 | 多线程共享 |
| RefCell<T> | 内部可变性 | 否 | 运行时借用检查 |
| Mutex<T> | 互斥锁 | 是 | |
| RwLock<T> | 读写锁 | 是 | |

## 并发相关

| 英文 | 中文（推荐） | 说明 |
|------|-------------|------|
| Thread | 线程 | OS 线程 |
| Async | 异步 | |
| Await | 等待 | |
| Future | 未来值 | |
| Send | 发送 | 跨线程转移 |
| Sync | 同步 | 跨线程共享 |
| Channel | 通道 | 消息传递 |
| Spawn | 生成任务 | 创建新任务 |
| Deadlock | 死锁 | |
| Race Condition | 竞态条件 | |

## 异步运行时

| 英文 | 中文（推荐） |
|------|-------------|
| Tokio | Tokio（保持英文） |
| async-std | async-std（保持英文） |
| Runtime | 运行时 |
| Executor | 执行器 |
| Waker | 唤醒器 |
| Polling | 轮询 |

## 内存安全

| 英文 | 中文（推荐） |
|------|-------------|
| Undefined Behavior | 未定义行为 |
| Memory Safety | 内存安全 |
| Soundness | 健全性 |
| Unsafe | 不安全 |
| FFI | FFI（外部函数接口） |
| Raw Pointer | 原始指针 |
| Reference | 引用 |

## 错误处理

| 英文 | 中文（推荐） |
|------|-------------|
| Panic | 恐慌 |
| Result | 结果类型 |
| Option | 选项类型 |
| Error | 错误 |
| Propagation | 传播 |

## 代码质量

| 英文 | 中文（推荐） |
|------|-------------|
| Benchmark | 基准测试 |
| Profiling | 性能分析 |
| Lint | 代码检查 |
| Formatting | 格式化 |
| Clippy | Clippy（保持英文） |
| cargo-fmt | cargo-fmt（保持英文） |

## 嵌入式

| 英文 | 中文（推荐） |
|------|-------------|
| no_std | no_std（保持英文） |
| Embedded | 嵌入式 |
| Interrupt | 中断 |
| DMA | DMA（直接内存访问） |
| ISR | 中断服务程序 |
| HAL | 硬件抽象层 |

## 使用原则

1. **代码示例**：保持英文（因为代码是英文的）
2. **中文说明**：术语后加英文括号标注
   - ✅ "借用检查器（Borrow Checker）"
   - ✅ "Send trait"
3. **首次出现**：中英对照
4. **后续出现**：统一使用一种语言
5. **专业术语**：保持英文（如 `Pin`、`Arc`、`Mutex`）

