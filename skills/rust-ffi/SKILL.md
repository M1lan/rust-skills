---
name: rust-ffi
description: "FFI 跨语言互操作专家。处理 C/C++ 互操作、bindgen、PyO3、Java JNI、内存布局、数据转换等问题。触发词：FFI, C, C++, bindgen, cbindgen, PyO3, jni, extern, libc, CString, CStr, 跨语言, 互操作, 绑定"
globs: ["**/*.rs"]
---

# FFI 跨语言互操作

## 核心问题

**如何安全地在 Rust 和其他语言之间传递数据？**

FFI 是危险的。任何错误都可能导致未定义行为。

---

## 绑定生成

### C/C++ → Rust (bindgen)

```bash
# 自动生成 bindings
bindgen input.h \
    --output src/bindings.rs \
    --whitelist-type 'my_*' \
    --whitelist-function 'my_*'
```

### Rust → C (cbindgen)

```bash
# 生成 C 头文件
cbindgen --crate mylib --output include/mylib.h
```

---

## 数据类型映射

| Rust | C | 注意事项 |
|-----|---|---------|
| `i32` | `int` | 通常匹配 |
| `i64` | `long long` | 跨平台注意 |
| `usize` | `uintptr_t` | 指针大小 |
| `*const T` | `const T*` | 只读 |
| `*mut T` | `T*` | 可写 |
| `&CStr` | `const char*` | UTF-8 保证 |
| `CString` | `char*` | 所有权转移 |
| `NonNull<T>` | `T*` | 非空指针 |

---

## 常见模式

### 调用 C 函数

```rust
use std::ffi::{CStr, CString};
use libc::c_int;

#[link(name = "curl")]
extern "C" {
    fn curl_version() -> *const libc::c_char;
    fn curl_easy_perform(curl: *mut c_int) -> c_int;
}

fn get_version() -> String {
    unsafe {
        let ptr = curl_version();
        CStr::from_ptr(ptr).to_string_lossy().into_owned()
    }
}
```

### 传递字符串

```rust
// ✅ 安全方式
fn process_c_string(s: &CStr) {
    unsafe {
        some_c_function(s.as_ptr());
    }
}

// 需要 String 时
fn get_c_string() -> CString {
    CString::new("hello").unwrap()
}
```

### 回调函数

```rust
extern "C" fn callback(data: *mut libc::c_void) {
    unsafe {
        let user_data: &mut UserData = &mut *(data as *mut UserData);
        user_data.count += 1;
    }
}

fn register_callback(callback: extern "C" fn(*mut c_void), data: *mut c_void) {
    unsafe {
        some_c_lib_register(callback, data);
    }
}
```

---

## 错误处理

### C 错误码

```rust
fn call_c_api() -> Result<(), Box<dyn std::error::Error>> {
    let result = unsafe { c_function_that_returns_int() };
    if result < 0 {
        return Err(format!("C API error: {}", result).into());
    }
    Ok(())
}
```

### panic 跨越 FFI

```rust
// FFI 边界上的 panic 应该被捕获或禁止
#[no_mangle]
pub extern "C" fn safe_call() {
    std::panic::catch_unwind(|| {
        rust_code_that_might_panic()
    }).ok();  // 忽略 panic
}
```

---

## 内存管理

| 场景 | 谁释放 | 怎么做 |
|-----|-------|-------|
| C 分配，Rust 使用 | C | 不要 free |
| Rust 分配，C 使用 | Rust | 传指针，C 用完通知 Rust |
| 共享缓冲区 | 协商 | 文档说明 |

---

## 常见陷阱

| 陷阱 | 后果 | 避免 |
|-----|------|-----|
| 字符串编码错误 | 乱码 | 用 CStr/CString |
| 生命周期不匹配 | use-after-free | 明确所有权 |
| 跨线程传递非 Send | 数据竞争 | Arc + 锁 |
| 胖指针传 C | 内存损坏 | 扁平化数据 |
| 忘记 `#[no_mangle]` | 符号找不到 | 明确导出 |

---

## 语言绑定工具

| 语言 | 工具 | 场景 |
|-----|------|-----|
| Python | PyO3 | Python 扩展 |
| Java | jni | Android/JVM |
| Node.js | napi-rs | Node.js 扩展 |
| C# | cppwinrt | Windows |
| Go | cgo | Go 桥接 |

---

## 安全准则

1. **最小化 unsafe**：只包装必要的 C 调用
2. **防御性编程**：检查空指针、范围
3. **文档明确**：谁负责释放内存
4. **测试覆盖**：FFI 错误极难调试
5. **用 Miri 检查**：发现未定义行为

