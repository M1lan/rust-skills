---
name: rust-embedded
description: "嵌入式与 no_std 专家。处理 no_std, embedded-hal, 裸机开发, 中断, DMA, 资源受限环境等问题。触发词：no_std, embedded, embedded-hal, microcontroller, firmware, ISR, DMA, 嵌入式, 裸机"
globs: ["**/*.rs", "**/Cargo.toml"]
---

# 嵌入式与 no_std 开发

## 核心问题

**如何在资源受限环境或没有标准库的情况下编程？**

no_std 不是 Rust 的子集，而是一种不同的编程模式。

---

## no_std 基础

```rust
#![no_std]
// 不能使用 std, alloc, test

use core::panic::PanicMessage;

// 必须实现 panic handler
#[panic_handler]
fn panic(info: &PanicMessage) -> ! {
    loop {}
}

// 可选：定义全局分配器
#[global_allocator]
static ALLOC: some_allocator::Allocator = some_allocator::Allocator;
```

### 可用模块

| 模块 | 用途 |
|-----|------|
| `core` | 基本语言特性 |
| `alloc` | 堆分配（需 allocator） |
| `compiler_builtins` | 编译器内置函数 |

---

## 嵌入式-hal

```rust
use embedded_hal as hal;
use hal::digital::v2::OutputPin;

// 抽象硬件访问
fn blink_led<L: OutputPin>(mut led: L) -> ! {
    loop {
        led.set_high().unwrap();
        delay_ms(1000);
        led.set_low().unwrap();
        delay_ms(1000);
    }
}
```

### 常用 trait

| trait | 操作 |
|-------|------|
| `OutputPin` | 设置高低电平 |
| `InputPin` | 读取引脚 |
| `SpiBus` | SPI 通信 |
| `I2c` | I2C 通信 |
| `Serial` | 串口 |

---

## 中断处理

```rust
#![no_std]
#![feature(abi_vectorcall)]

use cortex_m::interrupt::{free, Mutex};
use cortex_m::peripheral::NVIC;

// 共享状态
static MY_DEVICE: Mutex<Cell<Option<MyDevice>>> = Mutex::new(None);

#[interrupt]
fn TIM2() {
    free(|cs| {
        let device = MY_DEVICE.borrow(cs).take();
        if let Some(dev) = device {
            // 处理中断
            dev.handle();
            MY_DEVICE.borrow(cs).set(Some(dev));
        }
    });
}

// 启用中断
fn enable_interrupt(nvic: &mut NVIC, irq: interrupt::TIM2) {
    nvic.enable(irq);
}
```

---

## 内存管理

### 栈大小

```toml
[profile.dev]
panic = "abort"  # 减少二进制大小

[profile.release]
lto = true
opt-level = "z"  # 最小化大小
```

### 避免动态分配

```rust
// 用栈数组代替 Vec
let buffer: [u8; 256] = [0; 256];

// 或使用定长环形缓冲区
struct RingBuffer {
    data: [u8; 256],
    write_idx: usize,
    read_idx: usize,
}
```

---

## 外设访问模式

```rust
// 寄存器映射
const GPIOA_BASE: *const u32 = 0x4002_0000 as *const u32;
const GPIOA_ODR: *const u32 = (GPIOA_BASE + 0x14) as *const u32;

// 安全抽象
mod gpioa {
    use super::*;
    
    pub fn set_high() {
        unsafe {
            GPIOA_ODR.write_volatile(1 << 5);
        }
    }
}
```

---

## 常见问题

| 问题 | 原因 | 解决 |
|-----|------|-----|
| panic 死循环 | 没有 panic handler | 实现 #[panic_handler] |
| 栈溢出 | 中断嵌套或大局部变量 | 增加栈、减小局部变量 |
| 内存损坏 | 裸指针操作 | 用 safe abstraction |
| 程序不运行 | 链接脚本问题 | 检查 startup code |
| 外设不响应 | 时钟未使能 | 先配置 RCC |

---

## 资源受限技巧

| 技巧 | 效果 |
|-----|------|
| `opt-level = "z"` | 最小化大小 |
| `lto = true` | 链接时优化 |
| `panic = "abort"` | 去掉 unwinding |
| `codegen-units = 1` | 更好的优化 |
| 避免 alloc | 用栈或静态数组 |

---

## 项目配置示例

```toml
[package]
name = "my-firmware"
version = "0.1.0"
edition = "2024"

[dependencies]
cortex-m = "0.7"
cortex-m-rt = "0.7"
embedded-hal = "1.0"
nb = "1.0"

[profile.dev]
panic = "abort"

[profile.release]
opt-level = "z"
lto = true
codegen-units = 1
```

