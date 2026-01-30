---
name: unsafe-rules
description: "Unsafe Code security rules"
category: code-safety
triggers: ["unsafe", "safety", "SAFETY", "raw pointer", "FFI"]
related_skills:
 - rust-unsafe
 - rust-ffi
 - rust-ownership
---

# Unsafe Code Rules

> This set of rules defines the security check standards for unsafe codes.

---

## High-risk rules (red - subject to compliance)

### U-001: Raw Pointer unquote must be packaged in unsafe block

```rust
// ✅ Correct.
let ptr = &data as *const Data;
unsafe {
 println!("{}", (*ptr).value);
}

// ❌ Error
let ptr = &data as *const Data;
println!("{}", (*ptr).value); // Direct decitation raw pointer
```

### U-002: A SAFETY Comment must be added to all unsafe functions

```rust
/// Set the value of the original memory area
///
/// # Safety
///
/// - `ptr` Must point to a distributed active memory block
/// - `size` The number of bytes must be equal to the actual distribution
/// - The caller must ensure that the memory is not released before the function returns
unsafe fn set_memory(ptr: *mut u8, size: usize, value: u8) {
 // ...
}
```

### U-003: FFI call must use extern block declarations

```rust
// ✅ Correct.
extern "C" {
 fn c_strlen(s: *const c_char) -> usize;
}

// ❌ Error
fn c_strlen(s: *const c_char) -> usize; // Missing extern Statement
```

### U-004: The type that crosses the FFI boundary must have #[repr(C)]

```rust
// ✅ Correct.
#[repr(C)]
pub struct FfiHeader {
 pub magic: u32,
 pub version: u16,
 pub flags: u8,
}

// ❌ Error - Memory layout is uncertain
pub struct Header {
 pub magic: u32,
 pub version: u16,
}
```

### U-005: union field access must be in unsafe block

```rust
// ✅ Correct.
union IntOrFloat {
 as_i32: i32,
 as_f32: f32,
}

let value = unsafe { int_or_float.as_i32 };

// ❌ Error
let value = int_or_float.as_i32;
```

### U-006: The boundary must be verified after the pointer algorithm

```rust
// ✅ Correct.
let ptr = buffer.as_ptr().offset(10);
if ptr < buffer.as_ptr().add(buffer.len()) {
 unsafe { *ptr = 0xFF; }
}

// ❌ Error - Could cross the border.
let ptr = buffer.as_ptr().offset(1000);
unsafe { *ptr = 0xFF; }
```

### U-007: Achieving Send/Sync must ensure a change

```rust
// ✅ Correct. - Thread clear.
unsafe impl Send for ThreadSafeContainer {}

// ❌ Error - Rc It's not linear.
unsafe impl Send for NotThreadSafe {} // Rc<T> Could not close temporary folder: %s
```

### U-008: Widening type (#[repr(u*)]) conversion must be secure

```rust
// ✅ Correct.
fn to_u32(val: u8) -> u32 {
 val as u32 // Small to Large,Clear.
}

// ❌ Danger. - Large to Small,Possible data loss
fn to_u8(val: u32) -> u8 {
 val as u8 // Need additional checks
}
```

### U-009: Ban dynamic distribution in embedded ISR

```rust
// ✅ Correct. - Static distribution
static mut BUFFER: [u8; 256] = [0; 256];

// ❌ Error - Pocket distribution is possible ISR Failed
fn interrupt_handler() {
 let mut vec = Vec::new(); // Ban!
}
```

### U-010: Ban return of a pointer pointing to a local variable

```rust
// ❌ Error - Staple Pointer
fn bad_function() -> *const i32 {
 let x = 42;
 &x as *const i32 // x It's not working after release.
}

// ✅ Correct. - Returns static data
fn good_function() -> *const i32 {
 static X: i32 = 42;
 &X as *const i32
}
```

### U-011: Typologies must be aligned

```rust
// ✅ Correct. - Correct Alignment
#[repr(align(8))]
struct AlignedData {
 value: u64,
}

// ❌ Error - Maybe it's wrong.
let unaligned_ptr = 1 as *const u64;
unsafe { *unaligned_ptr = 42; } // Could collapse.
```

### U-012: Manually achieved drop must handle all fields

```rust
// ✅ Correct.
impl Drop for ManualResource {
 fn drop(&mut self) {
 unsafe {
 libc::free(self.ptr as *mut libc::c_void);
 }
 self.is_dropped = true;
 }
}

// ❌ Error - Missing release of certain resources
impl Drop for ManualResource {
 fn drop(&mut self) {
 if self.ptr.is_valid() {
 libc::free(self.ptr as *mut libc::c_void);
 }
 // It's missing. handle Close
 }
}
```

---

## Mid-risk rule (Orange - recommended)

### U-013: Avoid calling other unsafe functions in unsafe

```rust
// ✅ Recommendations - It will be complicated. unsafe Operation Envelope
unsafe fn safe_wrapper(ptr: *mut T) -> Result<(), Error> {
 check_ptr_validity(ptr)?; // Check first.
 complex_operation(ptr) // Reactivate
}

unsafe fn complex_operation(ptr: *mut T) {
 // Assuming verified pointer operation
 (*ptr).do_something();
}
```

### U-014: Replace union field with MaybeUninit

```rust
// ✅ Recommendations
let mut buffer = MaybeUninit::<[u8; 1024]>::uninit();
let ptr = buffer.as_mut_ptr();
unsafe {
 ptr.write_bytes(0, 1024);
}
let buffer = unsafe { buffer.assume_init() };
```

### U-015: FFI strings must handle encoding and length

```rust
// ✅ Recommendations
unsafe fn c_string_to_rust(s: *const c_char) -> Result<String, Utf8Error> {
 if s.is_null() {
 return Ok(String::new());
 }
 let c_str = std::ffi::CStr::from_ptr(s);
 c_str.to_str()?.to_string()
}
```

### U-016: Trans-linear nudity pointer must use Send

```rust
// ✅ Recommendations - Use Arc Packaging
struct ThreadSafePtr {
 ptr: *mut T,
 _marker: std::marker::PhantomData<*mut ()>,
}

unsafe impl Send for ThreadSafePtr {}
unsafe impl Sync for ThreadSafePtr {}
```

### U-017: Avoid frequent creation of original pointers in hot code

```rust
// ✅ Recommendations - Cache Pointer
fn process_buffer(buffer: &mut [u8]) {
 let ptr = buffer.as_mut_ptr();
 let len = buffer.len();
 for i in 0..len {
 unsafe { ptr.add(i).write(compute(i)); }
 }
}
```

### U-018: The type of Drop achieved should not include borrowed fields

```rust
// ✅ Recommendations
struct Container {
 data: Vec<u8>, // Ownership
 capacity: usize,
}

// ❌ Problem - It's possible to borrow fields drop Problem
struct ProblemContainer<'a> {
 data: &'a [u8], // Borrow.
}
```

### U-019: Attention when using ptr:read/write

```rust
// ✅ Recommendations
let val = unsafe { ptr.read() };
ptr.write(val + 1);

// ❌ Attention. - Avoid mixing fingers from different sources
let val = ptr1.read();
ptr2.write(val); // Possible violations provenance Rule
```

### U-020: Crossing FFI Boundaries

```rust
// ✅ Recommendations - Clear null Pointer semantics
extern "C" {
 /// Return next element,If you reach the end and return null
 fn get_next(ptr: *mut Context) -> *mut Element;
}
```

### U-021: Avoid repeating unsafe conversions in the cycle

```rust
// ✅ Recommendations
let base = data.as_ptr() as *const ComplexType;
for i in 0..len {
 unsafe { process(&*base.add(i)); }
}
```

### U-022: Memory alignment check should use sign of and log to

```rust
// ✅ Recommendations
use std::ptr;

let misalignment = ptr::align_of::<u64>();
if addr % misalignment != 0 {
 // Need adjustment
}
```

### U-023: Track unsafe call location using #[track caller]

```rust
// ✅ Recommendations
#[inline]
#[track_caller]
pub unsafe fn unchecked_get_unchecked<T>(index: usize) -> &T {
 // ...
}
```

---

## Low risk rule (yellow - reference recommendation)

### U-024: Prioritize citation rather than nudity pointer

```rust
// ✅ Recommendations
fn process_data(data: &[u8]) { ... }

// Use a naked finger only when an alias is needed
```

### U-025: Avoid converting the same pointer to multiple types

```rust
// ✅ Recommendations - Uniform type conversion
let ptr: *const Header = buffer.as_ptr().cast();
// Hold ptr Yes Header Type used
```

### U-026: *cont/ *mut with NonNull instead of null

```rust
// ✅ Recommendations
use std::ptr::NonNull;

let ptr = NonNull::dangling(); // Always works.
if let Some(data) = NonNull::new(ptr) {
 // ...
}
```

### U-027: Consider using Pin to fix self-referenced structures

```rust
// ✅ Recommendations
use std::pin::Pin;

struct SelfRef {
 data: u32,
 ptr: *const u32,
}

impl SelfRef {
 fn new(data: u32) -> Pin<Box<Self>> {
 let mut this = Box::pin(SelfRef {
 data,
 ptr: std::ptr::null(),
 });
 // Set self-reference safely
 let self_ptr: *const u32 = &this.data;
 unsafe { Pin::get_unchecked_mut(&mut *this).ptr = self_ptr; }
 this
 }
}
```

### U-028: FFI error processing using Resault type

```rust
// ✅ Recommendations
extern "C" {
 fn risky_operation() -> c_int;
}

fn safe_risky_operation() -> Result<(), FfiError> {
 let result = unsafe { risky_operation() };
 if result == 0 {
 Ok(())
 } else {
 Err(FfiError::from_raw_error(result))
 }
}
```

### U-029: Avoid exposure in library API unsafe

```rust
// ✅ Recommendations - Internal unsafe,External security abstract
pub fn safe_process(data: &[u8]) -> Result<Output, Error> {
 // Available internally unsafe,But there's a secure interface.
 unsafe { self.inner.process_unsafe(data) }
}
```

### U-030: Use addr of! Get Field Address

```rust
// ✅ Recommendations - Avoid creating temporary references
let field_addr = unsafe { std::ptr::addr_of!(structure.field) };
```

### U-031: Consider the use of address fixance

```rust
// ✅ Recommendations
fn compare_ptrs<T>(p1: *const T, p2: *const T) -> bool {
 p1 == p2
}
```

### U-032: Create safe packaging for complex unsafe operations

```rust
// ✅ Recommendations
pub struct SafeBuffer {
 ptr: NonNull<u8>,
 size: usize,
}

impl SafeBuffer {
 pub fn new(size: usize) -> Result<Self, AllocError> {
 let ptr = NonNull::new(unsafe {
 libc::malloc(size) as *mut u8
 }).ok_or(AllocError)?;
 Ok(SafeBuffer { ptr, size })
 }

 pub fn as_slice(&self) -> &[u8] {
 unsafe { std::slice::from_raw_parts(self.ptr.as_ptr(), self.size) }
 }

 // Automatically release memory
 impl Drop for SafeBuffer {
 fn drop(&mut self) {
 unsafe { libc::free(self.ptr.as_ptr() as *mut libc::c_void); }
 }
 }
}
```

### U-033: Avoid type conversion using transmute

```rust
// ✅ Recommendations - Use of safer alternatives
let bytes: [u8; 4] = u32::to_ne_bytes(value);

// Use only when necessary transmute,And record why.
unsafe {
 std::mem::transmute::<u32, [u8; 4]>(value)
}
```

### U-034: Consider using Manuel Drop to handle special release sequences

```rust
// ✅ Recommendations
use std::mem::ManuallyDrop;

struct SpecialResource {
 handle: ResourceHandle,
 metadata: Metadata,
}

impl Drop for SpecialResource {
 fn drop(&mut self) {
 // Ensure metadata Release first.
 let metadata = ManuallyDrop::take(&mut self.metadata);
 drop(metadata);

 // Then release. handle
 unsafe { self.handle.release(); }
 }
}
```

### U-035: Overlap check when using copy nonoverlapping

```rust
// ✅ Recommendations
use std::ptr::{copy_nonoverlapping, copy};

let dest = target.as_mut_ptr();
let src = source.as_ptr();

if dest as usize >= src as usize + source.len() {
 // No overlap,It's safe to use. copy_nonoverlapping
 unsafe { copy_nonoverlapping(src, dest, source.len()); }
} else {
 // Overlapping risks,Use copy
 unsafe { copy(src, dest, source.len()); }
}
```

### U-036: Integrated testing for unsafe code

```rust
// ✅ Recommendations
#[cfg(test)]
mod unsafe_api_tests {
 use super::*;

 #[test]
 fn test_unsafe_pointer_operations() {
 let mut value = 42i32;
 let ptr = &mut value as *mut i32;

 unsafe {
 assert_eq!(read_ptr(ptr), 42);
 write_ptr(ptr, 100);
 }
 assert_eq!(value, 100);
 }
}
```

### U-037: Consider using addresses to confuse key security data

```rust
// ✅ Recommendations - Simple XOR Confusion
fn obfuscate<T>(value: &mut T, key: u64) {
 let bytes = unsafe {
 std::slice::from_raw_parts_mut(
 value as *mut T as *mut u8,
 std::mem::size_of::<T>()
 )
 };
 for byte in bytes {
 *byte ^= key as u8;
 }
}
```

### U-038: Avoid excessive generation of generic codes

```rust
// ✅ Recommendations - Abstract to Single Realization
fn generic_process<T: Processable>(data: &mut [T]) {
 let ptr = data.as_mut_ptr();
 for i in 0..data.len() {
 unsafe { ptr.add(i).process(); }
 }
}
```

### U-039: Consider the issue when comparing addresses

```rust
// ✅ Recommendations
fn is_same_object<T>(a: &T, b: &T) -> bool {
 std::ptr::eq(a as *const T, b as *const T)
}
```

### U-040: Considering the use of address space layout randomization (ASLR)

```rust
// ✅ Recommendations
fn random_offset(base: usize, range: usize) -> usize {
 let random = fastrand::u32(0..1000) as usize;
 base + (random % range)
}
```

### U-041: Avoid global variability

```rust
// ✅ Recommendations - Use thread local storage
thread_local! {
 static THREAD_BUFFER: RefCell<Vec<u8>> = RefCell::new(Vec::new());
}
```

### U-042: Initialize after using zeroed()

```rust
// ✅ Recommendations
let mut value: MaybeUninit<ComplexType> = MaybeUninit::uninit();
// ... Initialize all fields
let value = unsafe { value.assume_init() };
```

### U-043: Consider the effect of memory alignment on performance

```rust
// ✅ Recommendations - Structure by Size
#[repr(C)]
struct OptimizedLayout {
 a: u64, // 8 Bytes
 b: u32, // 4 Bytes
 c: u8, // 1 Bytes
 _pad: [u8; 3], // Fill to 16 Byte Alignment
}
```

### U-044: Avoid calling drop in unsafe

```rust
// ✅ Recommendations - Use ManuallyDrop
use std::mem::ManuallyDrop;

let mut resource = ManuallyDrop::new(Resource::new());
// ... Use of resources
ManuallyDrop::drop(&mut resource); // Visible Call
```

### U-045: Use address tags to detect use-after-free

```rust
// ✅ Recommendations - Simple sentry.
const FREED_MARKER: usize = 0xDEADBEEF;

fn deallocate(ptr: &mut usize) {
 unsafe { libc::free(*ptr as *mut libc::c_void); }
 *ptr = FREED_MARKER;
}

fn access(ptr: &mut usize) -> bool {
 if *ptr == FREED_MARKER {
 return false; // Released
 }
 // Security visits
 true
}
```

### U-046: Consider using miri undefined behavior

```cargo
[profile.dev]
debug = 1

[dev-dependencies]
miri = "0.1"
```

```bash
cargo +nightly miri test
```

### U-047: Periodic review of unsafe code coverage

```rust
// Use coverage Tool Analysis
#[unsafe_code_analysis::covered]
unsafe fn complex_operation() {
 // ...
}
```

---

## Rule sheet

| Level | Number of rules | Annotations |
|-----|-------|------|
| High risk | 12 | We must comply. |
| It's dangerous. | 15 | Recommendation complied, code security improved |
| It's low. | 20 | Reference recommendations, code quality optimization |

---

## Related skills
- Unsafe code fundamentals
- FFI
- Ownership and borrowing
