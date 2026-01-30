---
name: rust-gpu
description: "GPU memory and compute: CUDA, OpenCL, GPU memory, compute shaders, memory coalescing, zero-copy, VRAM management, heterogeneous computing"
globs: ["**/*.rs"]
---

# GPU Memory and Compute

## Core issues

**Key question:** How do we manage GPU memory and heterogeneous compute efficiently in Rust?

GPU computing requires specialized memory management and synchronization.

---

## GPU memory architecture

```
┌─────────────────────────────────────────┐
│               GPU memory                │
├─────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐       │
│  │   Global    │  │   Shared    │       │
│  │   Memory    │  │   Memory    │       │
│  │  (VRAM)     │  │  (SMEM)     │       │
│  └─────────────┘  └─────────────┘       │
│                                         │
│  ┌─────────────┐  ┌─────────────┐       │
│  │  Constant   │  │   Local     │       │
│  │   Memory    │  │   Memory    │       │
│  └─────────────┘  └─────────────┘       │
└─────────────────────────────────────────┘
        ↓                    ↑
   CPU (via PCIe)        GPU compute units
```

---

## Memory type comparison

| Memory type | Location | Latency | Size | Use |
|---------|------|------|------|------|
| Global | VRAM | High | Large | Input/output data |
| Shared | SMEM | Low | Small | Intra-block communication |
| Constant | Cache | Medium | Medium | Read-only data |
| Local | Registers/VRAM | High | Small | Per-thread private |
| Register | SM | Lowest | Very small | Per-thread private |

---

## CUDA memory management (rust-cuda)

```rust
// Use rust-cuda or cuda-sys
use cuda_sys::ffi::*;

// Device memory allocation
let mut d_ptr: *mut f32 = std::ptr::null_mut();
unsafe {
    cudaMalloc(&mut d_ptr as *mut *mut f32, size * std::mem::size_of::<f32>())
};

// Host-to-device copy
unsafe {
    cudaMemcpy(
        d_ptr as *mut c_void,
        h_ptr as *const c_void,
        size * std::mem::size_of::<f32>(),
        cudaMemcpyHostToDevice
    );
};

// Device-to-host copy
let mut h_result: Vec<f32> = vec![0.0; size];
unsafe {
    cudaMemcpy(
        h_result.as_mut_ptr() as *mut c_void,
        d_ptr as *const c_void,
        size * std::mem::size_of::<f32>(),
        cudaMemcpyDeviceToHost
    );
};

// Free device memory
unsafe {
    cudaFree(d_ptr as *mut c_void);
};
```

---

## Zero-copy memory

```rust
// Zero-copy: shared host and device memory
let mut h_ptr: *mut f32 = std::ptr::null_mut();

// Allocate pinned host memory (page-locked)
unsafe {
    cudaMallocHost(&mut h_ptr as *mut *mut f32, size * std::mem::size_of::<f32>())
};

// Pinned memory can be accessed directly by the GPU
// but increases pressure on system memory

// Use cudaMemcpyAsync for async copy (overlap with compute)
let stream: cudaStream_t = std::ptr::null_mut();
unsafe {
    cudaMemcpyAsync(
        d_ptr as *mut c_void,
        h_ptr as *const c_void,
        size * std::mem::size_of::<f32>(),
        cudaMemcpyHostToDevice,
        stream
    );
};

// Synchronize
unsafe {
    cudaStreamSynchronize(stream);
};
```

---

## Unified memory

```rust
// Unified memory: CPU and GPU manage migration automatically
let mut unified_ptr: *mut f32 = std::ptr::null_mut();

unsafe {
    // Allocate unified memory
    cudaMallocManaged(&mut unified_ptr as *mut *mut f32, size * std::mem::size_of::<f32>());
};

// CPU access
unsafe {
    for i in 0..size {
        *unified_ptr.add(i) = i as f32;
    }
};

// GPU access (auto-migrates to device)
launch_kernel(unified_ptr, size);

// CPU access results (auto-migrates back)
unsafe {
    println!("Result: {}", unified_ptr.add(0).read());
};

// Free
unsafe {
    cudaFree(unified_ptr as *mut c_void);
};
```

---

## Memory coalescing

```rust
// Coalesced access to optimize global memory bandwidth
// ❌ Non-coalesced access
__global__ void bad_access(float* data) {
    int idx = threadIdx.x + blockIdx.x * 32; // Strided access
    float value = data[idx * 32];  // Each thread strides by 32
}

// ✅ Coalesced access
__global__ void coalesced_access(float* data) {
    int idx = threadIdx.x + blockIdx.x * blockDim.x; // Contiguous access
    float value = data[idx];  // Threads access consecutive elements
}
```

---

## Shared memory usage

```rust
// Use shared memory to reduce global memory access
__global__ void shared_memory_reduce(float* input, float* output) {
    __shared__ float sdata[256];  // 256 bytes per block

    int tid = threadIdx.x;
    int idx = blockIdx.x * blockDim.x + threadIdx.x;

    // Load from global memory into shared memory
    sdata[tid] = input[idx];
    __syncthreads();

    // Reduction
    for (int s = blockDim.x / 2; s > 0; s >>= 1) {
        if (tid < s) {
            sdata[tid] += sdata[tid + s];
        }
        __syncthreads();
    }

    // Write back result
    if (tid == 0) {
        output[blockIdx.x] = sdata[0];
    }
}
```

---

## Memory alignment

```rust
// Memory alignment optimization
const size_t ALIGNMENT = 256;  // 256-byte alignment

// cudaMalloc returns aligned pointers
// but custom structs must be aligned
struct alignas(256) AlignedData {
    float4 position;  // 16 bytes
    float4 normal;    // 16 bytes
    // ... padding to 256 bytes
};

// Check alignment
assert(((uintptr_t)ptr % ALIGNMENT) == 0);
```

---

## Performance checklist

| Item | Checkpoint |
|-------|-------|
| Memory coalescing | Threads access contiguous memory |
| Shared memory | Reduce global memory access |
| Alignment | 256-byte alignment |
| Async ops | Overlap compute and transfer |
| Pinned memory | Use page-locked memory |
| Batching | Reduce kernel launch overhead |

---

## Related skills

```
rust-gpu
    │
    ├─► rust-performance → performance optimization
    ├─► rust-unsafe → low-level memory operations
    └─► rust-embedded → no_std devices
```
