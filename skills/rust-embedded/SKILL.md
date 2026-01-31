---
name: rust-embedded
description: "Embedded and no_std expert. Covers no_std, embedded-hal, bare-metal, interrupts, DMA, resource constraints. Triggers: no_std, embedded, embedded-hal, microcontroller, firmware, ISR, DMA"
globs: ["**/*.rs", "**/Cargo.toml"]
---

# Embedded and no_std Development

## Core issues

Key question: How do we program in resource-constrained environments without
the standard library?

no_std is not a subset of Rust; it is a different programming mode.

---

## no_std basics

```rust
#![no_std]
// std, alloc, and test are not available by default

use core::panic::PanicMessage;

// Must provide a panic handler
#[panic_handler]
fn panic(info: &PanicMessage) -> ! {
    loop {}
}

// Optional: define a global allocator
#[global_allocator]
static ALLOC: some_allocator::Allocator = some_allocator::Allocator;
```

### Available modules

| Module              | Use                                  |
|---------------------|--------------------------------------|
| `core`              | Core language types                  |
| `alloc`             | Heap allocation (allocator required) |
| `compiler_builtins` | Compiler intrinsics                  |

---

## embedded-hal

```rust
use embedded_hal as hal;
use hal::digital::v2::OutputPin;

// Abstract hardware access
fn blink_led<L: OutputPin>(mut led: L) -> ! {
    loop {
        led.set_high().unwrap();
        delay_ms(1000);
        led.set_low().unwrap();
        delay_ms(1000);
    }
}
```

### Common traits

| trait       | Operation          |
|-------------|--------------------|
| `OutputPin` | Set high/low level |
| `InputPin`  | Read pin state     |
| `SpiBus`    | SPI communication  |
| `I2c`       | I2C communication  |
| `Serial`    | Serial interface   |

---

## Interrupt handling

```rust
#![no_std]
#![feature(abi_vectorcall)]

use cortex_m::interrupt::{free, Mutex};
use cortex_m::peripheral::NVIC;

// Shared state
static MY_DEVICE: Mutex<Cell<Option<MyDevice>>> = Mutex::new(None);

#[interrupt]
fn TIM2() {
    free(|cs| {
        let device = MY_DEVICE.borrow(cs).take();
        if let Some(dev) = device {
            // Handle interrupt
            dev.handle();
            MY_DEVICE.borrow(cs).set(Some(dev));
        }
    });
}

// Enable interrupt
fn enable_interrupt(nvic: &mut NVIC, irq: interrupt::TIM2) {
    nvic.enable(irq);
}
```

---

## Memory management

### Stack size

```toml
[profile.dev]
panic = "abort"  # Reduce binary size

[profile.release]
lto = true
opt-level = "z"  # Minimize size
```

### Avoid dynamic allocation

```rust
// Use stack arrays instead of Vec
let buffer: [u8; 256] = [0; 256];

// Or use a fixed-size ring buffer
struct RingBuffer {
    data: [u8; 256],
    write_idx: usize,
    read_idx: usize,
}
```

---

## Peripheral access patterns

```rust
// Register mapping
const GPIOA_BASE: *const u32 = 0x4002_0000 as *const u32;
const GPIOA_ODR: *const u32 = (GPIOA_BASE + 0x14) as *const u32;

// Safe abstraction
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

## Common problems

| Problem                  | Cause                             | Fix                           |
|--------------------------|-----------------------------------|-------------------------------|
| panic loop               | No panic handler                  | Implement `#[panic_handler]`  |
| Stack overflow           | Nested interrupts or large locals | Increase stack, reduce locals |
| Memory corruption        | Raw pointer misuse                | Use safe abstractions         |
| Program doesn't run      | Linker script issues              | Check startup code            |
| Peripherals unresponsive | Clock not enabled                 | Configure RCC first           |

---

## Resource-constrained tips

| Tip                 | Effect                     |
|---------------------|----------------------------|
| `opt-level = "z"`   | Minimize size              |
| `lto = true`        | Link-time optimization     |
| `panic = "abort"`   | Remove unwinding           |
| `codegen-units = 1` | Better optimization        |
| Avoid `alloc`       | Use stack or static arrays |

---

## Example project configuration

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

---

## WebAssembly multithreading

### SharedArrayBuffer

```rust
// Server must set Cross-Origin-Opener-Policy
// for browsers to use SharedArrayBuffer

// wasm-bindgen configuration
[dependencies]
wasm-bindgen = { version = "0.2", features = ["enable-threads"] }

// Use atomic memory ordering
use std::sync::atomic::{AtomicUsize, Ordering};

static COUNTER: AtomicUsize = AtomicUsize::new(0);

#[wasm_bindgen]
pub fn increment_counter() -> usize {
    COUNTER.fetch_add(1, Ordering::SeqCst)
}

#[wasm_bindgen]
pub fn get_counter() -> usize {
    COUNTER.load(Ordering::SeqCst)
}
```

### Atomics and memory ordering

```rust
use std::sync::atomic::{AtomicI32, Ordering};

// Trade-offs between ordering strength and performance
#[wasm_bindgen]
pub fn atomic_demo() {
    let atom = AtomicI32::new(0);

    // Strongest, slowest
    atom.store(1, Ordering::SeqCst);

    // Release semantics (producer)
    atom.store(2, Ordering::Release);

    // Acquire semantics (consumer)
    let val = atom.load(Ordering::Acquire);

    // Relaxed semantics, fastest, but can reorder
    atom.store(3, Ordering::Relaxed);
    let val = atom.load(Ordering::Relaxed);
}
```

### Thread-local storage (TLS)

```rust
// WASM thread-local storage
use std::cell::RefCell;

thread_local! {
    static THREAD_ID: RefCell<u32> = RefCell::new(0);
}

#[wasm_bindgen]
pub fn set_thread_id(id: u32) {
    THREAD_ID.with(|tid| {
        *tid.borrow_mut() = id;
    });
}

#[wasm_bindgen]
pub fn get_thread_id() -> u32 {
    THREAD_ID.with(|tid| *tid.borrow())
}
```

---

## RISC-V embedded development

### Basic setup

```rust
// Cargo.toml
[package]
name = "riscv-firmware"
version = "0.1.0"
edition = "2024"

[dependencies]
riscv = "0.10"
embedded-hal = "1.0"

[profile.release]
opt-level = "z"
lto = true
```

### Interrupts and exceptions

```rust
// RISC-V interrupt handling
#![no_std]

use riscv::register::{
    mie::MIE,
    mstatus::MSTATUS,
    mip::MIP,
};

/// Enable machine interrupts
pub fn enable_interrupt() {
    unsafe {
        MIE::set_mext();
        MIE::set_mtimer();
        MIE::set_msip();

        // Global interrupt enable
        MSTATUS::set_mie();
    }
}

/// Disable all interrupts
pub fn disable_interrupt() {
    unsafe {
        MSTATUS::clear_mie();
    }
}
```

### Memory barriers

```rust
// RISC-V memory barriers
use riscv::asm;

/// Data memory barrier - ensure all memory ops complete
fn data_memory_barrier() {
    unsafe {
        asm!("fence iorw, iorw");
    }
}

/// Instruction barrier - ensure instruction stream visibility
fn instruction_barrier() {
    unsafe {
        asm!("fence i, i");
    }
}
```

### Atomic operations

```rust
// Use riscv::atomic module
use riscv::asm::atomic;

fn atomic_add(dst: &mut usize, val: usize) {
    unsafe {
        // Use amoadd.w instruction
        atomic::amoadd(dst as *mut usize, val);
    }
}

fn compare_and_swap(ptr: &mut usize, old: usize, new: usize) -> bool {
    unsafe {
        // Use amoswap.w instruction
        let current = atomic::amoswap(ptr as *mut usize, new);
        current == old
    }
}
```

### Multi-core synchronization

```rust
// RISC-V inter-processor interrupt (IPI)
const M_SOFT_INT: *mut u32 = 0x3FF0_FFF0 as *mut u32;

fn send_soft_interrupt(core_id: u32) {
    unsafe {
        // Set software interrupt bit
        M_SOFT_INT.write_volatile(1 << core_id);
    }
}

fn clear_soft_interrupt(core_id: u32) {
    unsafe {
        M_SOFT_INT.write_volatile(0);
    }
}
```

### RISC-V privilege levels

```rust
// RISC-V privilege level check
use riscv::register::{mstatus, misa};

fn check_privilege_level() -> u8 {
    // 0 = User, 1 = Supervisor, 2 = Hypervisor, 3 = Machine
    (mstatus::read().bits() >> 11) & 0b11
}

fn is_machine_mode() -> bool {
    check_privilege_level() == 3
}

/// Get available ISA extensions
fn get_isa_extensions() -> String {
    let misa = misa::read();
    format!("{:?}", misa)
}
```

---

## RISC-V performance optimization

| Optimization            | Method                                           |
|-------------------------|--------------------------------------------------|
| Memory access           | Use unaligned access instructions (if supported) |
| Atomics                 | Use A extension instructions                     |
| Multiplication/division | Use M extension instructions                     |
| Vector ops              | Use V extension (RV64V)                          |
| Compressed instructions | Use C extension to reduce code size              |

---
