---
name: rust-dpdk
description: "User-space networking expert. Handles DPDK, user-space drivers, high-performance networking, packet processing, zero-copy, RSS load balancing"
globs: ["**/*.rs"]
---

# User-Space Networking (DPDK)

## Core issues

Key question: How do we process millions of packets per second (PPS)?

Traditional kernel network stacks incur heavy context switching and memory-copy overhead.

---

## DPDK vs kernel network stack

| Feature           | Kernel network stack    | DPDK                   |
|-------------------|-------------------------|------------------------|
| Context switching | Switch per packet       | Poll mode, no switches |
| Memory copies     | Multiple copies         | Zero-copy              |
| Interrupts        | Frequent interrupts     | Poll mode driver       |
| Latency           | Higher                  | Microseconds           |
| Throughput        | Tens of thousands PPS   | Millions PPS           |
| CPU utilization   | Lower but with overhead | High but efficient     |

---

## Core components

```rust
// DPDK core structures
struct DpdkContext {
    memory_pool: Mempool,        // Memory pool
    ports: Vec<Port>,            // NIC ports
    rx_queues: Vec<RxQueue>,     // Receive queues
    tx_queues: Vec<TxQueue>,     // Transmit queues
    cpu_cores: Vec<Core>,        // CPU core assignment
}

struct Port {
    port_id: u16,
    mac_addr: [u8; 6],
    link_speed: u32,
    max_queues: u16,
}

struct Mempool {
    name: String,
    buffer_size: usize,
    cache_size: usize,
    total_buffers: u32,
}
```

---

## Memory pool management

```rust
// Create a DPDK memory pool
fn create_mempool() -> Result<Mempool, DpdkError> {
    let mempool = unsafe {
        rte_mempool_create(
            b"packet_pool\0".as_ptr() as *const c_char,
            NUM_BUFFERS as u32,          // Number of buffers
            BUFFER_SIZE as u16,          // Buffer size
            CACHE_SIZE as u32,           // CPU cache size
            0,                           // Private data size
            Some(rte_pktmbuf_pool_init), // Pool init function
            std::ptr::null(),            // Pool init args
            Some(rte_pktmbuf_init),      // Object init function
            std::ptr::null(),            // Object init args
            rte_socket_id() as i32,      // NUMA socket
            0,                           // Flags
        )
    };

    if mempool.is_null() {
        Err(DpdkError::MempoolCreateFailed)
    } else {
        Ok(Mempool { inner: mempool })
    }
}

// Allocate a buffer
fn alloc_mbuf(mempool: &Mempool) -> Option<*mut rte_mbuf> {
    unsafe {
        let mbuf = rte_pktmbuf_alloc(mempool.inner);
        if mbuf.is_null() {
            None
        } else {
            Some(mbuf)
        }
    }
}
```

---

## Zero-copy receive

```rust
// Receive packets with zero-copy
fn process_packets(
    port_id: u16,
    queue_id: u16,
    bufs: &mut [*mut rte_mbuf; MAX_BURST_SIZE],
) -> usize {
    let num_received = unsafe {
        rte_eth_rx_burst(
            port_id,
            queue_id,
            bufs.as_mut_ptr(),
            MAX_BURST_SIZE as u16,
        )
    };

    // Process mbufs directly without copying
    for i in 0..num_received {
        let mbuf = bufs[i];

        // Access data (zero-copy)
        let data_ptr = unsafe { rte_pktmbuf_mtod(mbuf, *const u8) };
        let data_len = unsafe { rte_pktmbuf_pkt_len(mbuf) };

        // Process the packet
        process_packet(data_ptr, data_len);

        // Free mbuf back to the pool
        unsafe { rte_pktmbuf_free(mbuf); }
    }

    num_received
}
```

---

## Batch transmit

```rust
// Send packets in batch
fn transmit_packets(
    port_id: u16,
    queue_id: u16,
    packets: &[Packet],
) -> usize {
    let mut mbufs: Vec<*mut rte_mbuf> = packets
        .iter()
        .map(|p| p.to_mbuf())
        .collect();

    let sent = unsafe {
        rte_eth_tx_burst(
            port_id,
            queue_id,
            mbufs.as_mut_ptr(),
            mbufs.len() as u16,
        )
    };

    // Free unsent mbufs
    for i in sent..mbufs.len() {
        unsafe { rte_pktmbuf_free(mbufs[i]); }
    }

    sent
}
```

---

## RSS load balancing

```rust
// Configure RSS (Receive Side Scaling)
fn configure_rss(port_id: u16) -> Result<(), DpdkError> {
    let mut port_info: rte_eth_dev_info = unsafe { std::mem::zeroed() };
    unsafe {
        rte_eth_dev_info_get(port_id, &mut port_info);
    }

    // Configure RSS hash
    let mut rss_conf: rte_eth_rss_conf = unsafe { std::mem::zeroed() };
    rss_conf.rss_key_len = 40;
    rss_conf.rss_hf = RTE_ETH_RSS_TCP | RTE_ETH_RSS_UDP | RTE_ETH_RSS_IPV4;

    unsafe {
        let ret = rte_eth_dev_rss_hash_conf_update(port_id, &rss_conf);
        if ret < 0 {
            return Err(DpdkError::RssConfigFailed);
        }
    }

    Ok(())
}

// Pick queue by hash
fn get_queue_by_hash(hash: u32, num_queues: u16) -> u16 {
    // Simple modulo distribution
    (hash % num_queues as u32) as u16
}
```

---

## Multi-queue configuration

```rust
// Configure multiple queues
fn configure_multi_queue(port_id: u16, num_queues: u16) -> Result<(), DpdkError> {
    let mut port_conf: rte_eth_conf = unsafe { std::mem::zeroed() };
    port_conf.rxmode.split_hdr_size = 0;
    port_conf.rxmode.mq_mode = rte_eth_mq_mode::ETH_MQ_RX_RSS;
    port_conf.txmode.mq_mode = rte_eth_mq_mode::ETH_MQ_TX_NONE;

    // RX queue config
    let mut rx_conf: rte_eth_rxconf = unsafe { std::mem::zeroed() };
    rx_conf.rx_free_thresh = 32;
    rx_conf.rx_drop_en = 0;

    // TX queue config
    let mut tx_conf: rte_eth_txconf = unsafe { std::mem::zeroed() };
    tx_conf.tx_free_thresh = 32;

    // Setup RX queues
    for queue in 0..num_queues {
        unsafe {
            let ret = rte_eth_rx_queue_setup(
                port_id,
                queue,
                1024, // Queue depth
                rte_socket_id() as u32,
                &rx_conf,
                mempool.inner,
            );
            if ret < 0 {
                return Err(DpdkError::QueueSetupFailed);
            }
        }
    }

    // Setup TX queues
    for queue in 0..num_queues {
        unsafe {
            let ret = rte_eth_tx_queue_setup(
                port_id,
                queue,
                1024,
                rte_socket_id() as u32,
                &tx_conf,
            );
            if ret < 0 {
                return Err(DpdkError::QueueSetupFailed);
            }
        }
    }

    Ok(())
}
```

---

## CPU affinity

```rust
use std::os::raw::c_int;
use std::thread;

fn set_cpu_affinity(core_id: u32) -> Result<(), DpdkError> {
    let mut cpuset: cpu_set_t = unsafe { std::mem::zeroed() };

    unsafe {
        CPU_SET(core_id as usize, &mut cpuset);

        let ret = pthread_setaffinity_np(
            pthread_self(),
            std::mem::size_of::<cpu_set_t>(),
            &cpuset,
        );

        if ret != 0 {
            return Err(DpdkError::AffinitySetFailed);
        }
    }

    Ok(())
}

// Assign a dedicated core to each RX queue
fn allocate_cores_for_queues(num_queues: u16) {
    for queue in 0..num_queues {
        thread::spawn(move || {
            set_cpu_affinity(queue as u32).unwrap();
            process_queue(queue);
        });
    }
}
```

---

## Performance optimization

| Optimization     | Method                                  |
|------------------|-----------------------------------------|
| Memory alignment | Cache-line alignment (64 bytes)         |
| Lock-free queues | Use SPSC queues                         |
| Batching         | Batch send/receive to reduce syscalls   |
| CPU affinity     | Core pinning to reduce context switches |
| Hugepages        | 2MB/1GB pages reduce TLB misses         |

---

## Related skills

```text
rust-dpdk
    │
    ├─► rust-performance → performance optimization
    ├─► rust-embedded → no_std environments
    └─► rust-concurrency → concurrency model
```
