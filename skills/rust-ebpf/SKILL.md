---
name: rust-ebpf
description: "eBPF and kernel programming: programs, maps, tail calls, perf events, probes, performance analysis"
globs: ["**/*.rs"]
---

# eBPF and Kernel Programming

## Core issues

**Key question:** How can we safely extend kernel behavior without modifying kernel code?

eBPF lets you run user-space logic safely inside the kernel.

---

## eBPF vs kernel modules

| Feature | eBPF | Kernel modules |
|-----|------|---------|
| Safety verification | Verified at load time | Manual review required |
| Stability | Stable API | API may change |
| Performance | JIT-compiled | High but risky |
| Crash risk | Limited | Can crash the kernel |
| Language support | C, Rust | C, Rust |

---

## Aya library

```rust
// Create eBPF programs with aya
use aya::{maps::Map, programs::Xdp, Bpf};
use aya::maps::ArrayMap;
use std::sync::atomic::{AtomicU64, Ordering};

static PACKET_COUNT: AtomicU64 = AtomicU64::new(0);

#[repr(C)]
struct PacketStat {
    rx_packets: u64,
    tx_packets: u64,
}

#[panic_handler]
fn panic(_info: &std::panic::PanicInfo) -> ! {
    unsafe { core::hint::unreachable_unchecked() }
}
```

---

## eBPF maps

```rust
// eBPF shared data maps
use aya::maps::HashMap;
use aya::util::online_cpus;

// Hash map
let mut hash_map = HashMap::try_from(
    (prog.fd().as_ref(), "packet_counts")
)?;

for cpu in online_cpus()? {
    hash_map.insert(cpu as u32, 0u64, 0)?;
}

// Array map
use aya::maps::Array;
let mut array = Array::try_from(
    (prog.fd().as_ref(), "config")
)?;

array.insert(0, 64u32, 0)?; // Batch size

// Per-CPU map
use aya::maps::PerCpuHashMap;
let mut per_cpu = PerCpuHashMap::try_from(
    (prog.fd().as_ref(), "per_cpu_stats")
)?;

for cpu in online_cpus()? {
    per_cpu.insert(cpu as u32, &0u64, 0)?;
}
```

---

## XDP program

```rust
// XDP (Express Data Path) program
use aya::programs::XdpContext;
use aya_bpf::helpers::bpf_redirect;
use aya_bpf::macros::xdp;
use aya_bpf::programs::XdpProgram;

#[xdp]
pub fn xdp_packet_counter(ctx: XdpContext) -> u32 {
    let _ = ctx;

    // Count packets
    PACKET_COUNT.fetch_add(1, Ordering::SeqCst);

    // Redirect to original interface
    bpf_redirect(ctx.ifindex(), 0)
}
```

---

## Tracepoint

```rust
// Tracepoint program
use aya_bpf::macros::tracepoint;
use aya_bpf::programs::TracepointContext;

#[tracepoint(name = "sys_enter_open")]
pub fn trace_sys_enter_open(ctx: TracepointContext) -> u32 {
    let _ = ctx;
    0
}
```

---

## kprobe/kretprobe

```rust
// Kernel probes
use aya_bpf::macros::{kprobe, kretprobe};
use aya_bpf::programs::KprobeContext;

#[kprobe(name = "tcp_v4_connect", fn_name = "tcp_v4_connect_enter")]
pub fn tcp_v4_connect_enter(_ctx: KprobeContext) -> u32 {
    0
}

#[kretprobe(name = "tcp_v4_connect", fn_name = "tcp_v4_connect_exit")]
pub fn tcp_v4_connect_exit(_ctx: KprobeContext) -> u32 {
    0
}
```

---

## User-space loader

```rust
// Full eBPF loader
use aya::Bpf;
use aya::maps::HashMap;
use std::net::Ipv4Addr;

#[tokio::main]
async fn main() -> Result<(), anyhow::Error> {
    // Load eBPF program
    let mut bpf = Bpf::load("ebpf.o")?;

    // Get program
    let program: &mut Xdp = bpf.program_mut("xdp_packet_counter")
        .unwrap()
        .try_into()?;
    program.load()?;
    program.attach("eth0", XdpFlags::default())?;

    // Create map
    let mut blocked_ips: HashMap<_, Ipv4Addr, u8> = HashMap::try_from(
        (bpf.map("blocked_ips")?.fd().as_ref(), "blocked_ips")
    )?;

    blocked_ips.insert(Ipv4Addr::new(1, 2, 3, 4), 1, 0)?;

    // Continuous monitoring
    loop {
        tokio::time::sleep(tokio::time::Duration::from_secs(1)).await;
        // Read stats
    }
}
```

---

## Tail calls

```rust
// Tail call - chained program invocation

// Program 1
#[xdp(name = "packet_parser")]
pub fn packet_parser(ctx: XdpContext) -> u32 {
    let _ = ctx;
    // Parse headers, decide next program
    aya_bpf::helpers::bpf_tail_call(ctx, &JUMP_TABLE, 0)
}

// Program 2
#[xdp(name = "packet_filter")]
pub fn packet_filter(ctx: XdpContext) -> u32 {
    let _ = ctx;
    aya_bpf::programs::XdpAction::Pass.as_u32()
}

// User-space setup
let mut jump_table: ProgramArray = ProgramArray::try_from(
    (bpf.map("jump_table")?.fd().as_ref(), "jump_table")
)?;

jump_table.set(0, bpf.program("packet_filter").unwrap().fd(), 0)?;
```

---

## Performance optimization

| Optimization | Method |
|-------|------|
| Map access | Batch reads, fewer syscalls |
| Tail calls | Limit chain length |
| Data structures | Prefer arrays over hash maps |
| Lock contention | Use PerCPU maps |

---

## Related skills

```
rust-ebpf
    │
    ├─► rust-embedded → no_std, kernel interfaces
    ├─► rust-performance → profiling
    └─► rust-unsafe → low-level memory operations
```
