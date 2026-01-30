---
name: rust-ffi
description: "FFI and cross-language interoperability: C/C++, bindgen, PyO3, JNI, memory layout, data conversion. Triggers: FFI, C, C++, bindgen, cbindgen, PyO3, jni, extern, libc, CString, CStr"
globs: ["**/*.rs"]
---

# FFI Interop

## Core issues

**Key question:** How do we safely pass data between Rust and C/C++?

FFI is unsafe by nature; mistakes can cause undefined behavior.

---

## Binding generation

### C/C++ → Rust (bindgen)

```bash
# Auto-generate bindings
bindgen input.h \
 --output src/bindings.rs \
 --whitelist-type 'my_*' \
 --whitelist-function 'my_*'
```

### Rust → C (cbindgen)

```bash
# Generate C Headers
cbindgen --crate mylib --output include/mylib.h
```

---

## Type mapping

| Rust | C | Notes |
|-----|---|---------|
| `i32` | `int` | Usually match |
| `i64` | `long long` | Platform-dependent |
| `usize` | `uintptr_t` | Pointer-sized |
| `*const T` | `const T*` | Read-only |
| `*mut T` | `T*` | Writable |
| `&CStr` | `const char*` | UTF-8 string |
| `CString` | `char*` | Owned C string |
| `NonNull<T>` | `T*` | Non-null pointer |

---

## Common patterns

### Call C function

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

### Pass String

```rust
// ✅ Safe usage
fn process_c_string(s: &CStr) {
 unsafe {
     some_c_function(s.as_ptr());
 }
}

// Creating a CString
fn get_c_string() -> CString {
 CString::new("hello").unwrap()
}
```

### Callbacks

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

## Error handling

### C error codes

```rust
fn call_c_api() -> Result<(), Box<dyn std::error::Error>> {
    let result = unsafe { c_function_that_returns_int() };
    if result < 0 {
        return Err(format!("C API error: {}", result).into());
    }
    Ok(())
}
```

### Panic Crossing FFI

```rust
// Never let a panic cross the FFI boundary.
#[no_mangle]
pub extern "C" fn safe_call() {
    std::panic::catch_unwind(|| {
        rust_code_that_might_panic()
    }).ok(); // Ignore panic
}
```

---

## Memory management

| Scenario | Who frees? | How |
|-----|-------|-------|
| C allocation, Rust use | C | Free |
| Rust allocation, C use | Rust | Provide free function |
| Shared buffer | Both | Document ownership rules |

---

## Common traps

| Trap | Consequences | Avoid |
|-----|------|-----|
| String Encoding Error | Chaos | Use CStr/CString |
| Lifetime mismatch | use-after-free | Document ownership |
| Cross-thread non-Send | Data races | Arc + Mutex |
| Fat pointers in C | Memory corruption | Use thin pointers |
| Missing `#[no_mangle]` | Symbols not found | Export correctly |

---

## Language bindings

| Language | Tool | Use case |
|-----|------|-----|
| Python | PyO3 | Python extension |
| Java | jni | Android/JVM |
| Node.js | napi-rs | Node.js Extension |
| C# | cppwinrt | Windows |
| Go | cgo | Go bridge |

---

## Safety guidelines

1. **Minimize unsafe:** only at FFI boundaries.
2. **Defensive programming:** validate pointers and lengths.
3. **Document ownership:** who allocates and who frees.
4. **Type coverage:** FFI bugs are hard to debug.
5. **Use Miri/ASan:** catch undefined behavior early.

---

## C++ Abnormal treatment

### cxx library

```rust
// Use cxx Achieving security C++ FFI
use cxx::CxxString;
use cxx::CxxVector;

#[cxx::bridge]
mod ffi {
 unsafe extern "C++" {
 include!("my_library.h");
 
 type MyClass;
 
 fn do_something(&self, input: i32) -> i32;
 fn get_data(&self) -> &CxxString;
 fn process_vector(&self, vec: &CxxVector<i32>) -> i32;
 }
 
 #[namespace = "mylib"]
 unsafe extern "C++" {
 fn free_resource(ptr: *mut c_void);
 }
}

struct RustWrapper {
 ptr: *mut c_void,
}

impl RustWrapper {
 pub fn new() -> Self {
 unsafe {
 Self {
 ptr: mylib::create_object(),
 }
 }
 }
 
 pub fn do_something(&self, input: i32) -> i32 {
 unsafe {
 (*self.ptr).do_something(input)
 }
 }
}

impl Drop for RustWrapper {
 fn drop(&mut self) {
 unsafe {
 mylib::free_resource(self.ptr);
 }
 }
}
```

### C++ Abnormal

```rust
// C++ It's gonna turn out to be an anomaly. Rust panic
// I need it. catch_unwind Capture

#[no_mangle]
pub extern "C" fn safe_cpp_call() -> i32 {
 let result = std::panic::catch_unwind(|| {
 unsafe {
 cpp_function_that_might_throw()
 }
 });
 
 match result {
 Ok(value) => value,
 Err(_) => {
 // C++ Unusual capture.,Return error code
 -1
 }
 }
}

// A better way.:Custom Error Conversion
#[no_mangle]
pub extern "C" fn checked_cpp_call(error_code: *mut i32) -> *const c_char {
 let result = std::panic::catch_unwind(|| {
 unsafe {
 cpp_function()
 }
 });
 
 match result {
 Ok(Ok(value)) => {
 // Success
 value.as_ptr()
 }
 Ok(Err(e)) => {
 // C++ Error
 if !error_code.is_null() {
 unsafe { *error_code = e.code(); }
 }
 std::ptr::null()
 }
 Err(_) => {
 // C++ Unusual
 if !error_code.is_null() {
 unsafe { *error_code = -999; }
 }
 std::ptr::null()
 }
 }
}
```

### Common C++ interop pitfalls

```rust
// C++/Rust interop is tricky.

// 1. Don't let panics cross FFI boundaries
#[no_mangle]
pub extern "C" fn rust_function() {
 // Rust code may panic.
 // If a panic crosses into C++, it's UB.
 
 // Solution: catch_unwind
 let _ = std::panic::catch_unwind(|| {
 risky_rust_code()
 });
}

// 2. C++ destructors vs Rust Drop
// C++ destructors run during stack unwinding.
// Rust Drop also runs; double cleanup can happen.

// Solution: use ManuallyDrop
struct Wrapper {
 inner: ManuallyDrop<InnerType>,
}

impl Drop for Wrapper {
 fn drop(&mut self) {
 // Prevent double cleanup.
 }
}
```

### C++ Smart Pointer Bridge

```rust
// Use cxx Bridge. std::unique_ptr
#[cxx::bridge]
mod ffi {
 unsafe extern "C++" {
 include!("memory");
 
 type UniquePtr<T>;
 
 // Transfer of title:Rust → C++
 fn take_unique_ptr(ptr: Box<UniquePtr<T>>) -> *mut T;
 
 // Transfer of title:C++ → Rust
 fn create_unique_ptr() -> Box<UniquePtr<T>>;
 fn release_unique_ptr(ptr: Box<UniquePtr<T>>) -> *mut T;
 }
}

// Manual bridge. std::shared_ptr
struct SharedPtr<T> {
 ptr: *mut T,
 ref_count: usize,
}

impl<T> SharedPtr<T> {
 pub fn new(ptr: *mut T) -> Self {
 Self {
 ptr,
 ref_count: 1,
 }
 }
 
 pub fn clone(&mut self) {
 self.ref_count += 1;
 }
 
 pub fn drop(&mut self) {
 self.ref_count -= 1;
 if self.ref_count == 0 {
 unsafe {
 // Call C++ delete
 cpp_delete(self.ptr);
 }
 }
 }
}

unsafe impl<T> Send for SharedPtr<T> {}
unsafe impl<T> Sync for SharedPtr<T> {}
```

---

## Common problems

| Problem | Reason | Solve |
|-----|------|-----|
| C++ Unusual Cause Panic | Uncaptured anomaly | catch_unwind |
| Memory Double Release | Lack of ownership | Clear agreement |
| Fat pointer broken. | Layout does not match | \#[repr(C)] |
| Symbol not exported | ## [no mangle] missing | Add Properties |
| Thread security | Not Send/Sync | Arc+Lock |
