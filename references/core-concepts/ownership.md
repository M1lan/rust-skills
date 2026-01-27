# 所有权与借用（Ownership and Borrowing）

所有权是 Rust 最核心的内存安全机制，它让 Rust 能够在不依赖垃圾回收的情况下保证内存安全。

## 核心规则

1. **每个值只有一个所有者**（Each value has a single owner）
2. **当所有者离开作用域时，值会被释放**（When owner goes out of scope, value is dropped）
3. **要么一个可变引用，要么任意数量不可变引用**（Only one mutable reference OR any number of immutable references）

## 所有权转移（Move）

### 什么是移动？

当一个值被赋值给另一个变量时，所有权会转移，原变量不再有效。

```rust
fn main() {
    let s1 = String::from("hello");
    let s2 = s1;  // s1 的所有权转移给 s2

    // println!("{}", s1);  // ❌ 编译错误！s1 不再有效
    println!("{}", s2);  // ✅ OK
}
```

### 移动发生的场景

- 赋值操作：`let s2 = s1`
- 函数传参：`takes_ownership(s1)`
- 函数返回值：`return s1`

```rust
fn takes_ownership(s: String) {
    println!("{}", s);
}  // s 在这里被释放

fn main() {
    let s = String::from("hello");
    takes_ownership(s);  // s 的所有权转移给函数
    // println!("{}", s);  // ❌ 错误！s 不再有效
}
```

## 借用（Borrowing）

### 不可变引用

使用 `&` 创建不可变引用，可以有多个。

```rust
fn calculate_length(s: &String) -> usize {
    s.len()
}  // s 离开作用域，但不会释放它指向的值

fn main() {
    let s = String::from("hello");
    let len = calculate_length(&s);  // 不可变引用
    println!("Length: {}", len);
    println!("{}", s);  // ✅ s 仍然有效
}
```

### 可变引用

使用 `&mut` 创建可变引用，同时只能有一个。

```rust
fn change(s: &mut String) {
    s.push_str(", world");
}

fn main() {
    let mut s = String::from("hello");
    change(&mut s);  // 可变引用
    println!("{}", s);  // ✅ "hello, world"
}
```

### 可变引用规则

```rust
fn main() {
    let mut s = String::from("hello");

    let r1 = &mut s;  // ✅ 第一个可变引用
    // let r2 = &mut s;  // ❌ 错误！不能同时有两个可变引用
    // let r3 = &s;      // ❌ 错误！不可变引用和可变引用不能同时存在

    println!("{}", r1);
}
```

## 切片类型（Slice Type）

### 字符串切片

```rust
fn first_word(s: &String) -> &str {
    let bytes = s.as_bytes();
    for (i, &byte) in bytes.iter().enumerate() {
        if byte == b' ' {
            return &s[0..i];
        }
    }
    &s[..]
}
```

## 生命周期（Lifetime）

### 为什么需要生命周期？

Rust 需要知道引用存活的时间，以确保引用不会指向已释放的内存。

### 生命周期注解

```rust
// 'a 表示返回值的生命周期与两个输入参数中较短的那个相同
fn longest<'a>(s1: &'a str, s2: &'a str) -> &'a str {
    if s1.len() > s2.len() {
        s1
    } else {
        s2
    }
}
```

### 结构体中的生命周期

```rust
struct ImportantExcerpt<'a> {
    part: &'a str,
}

fn main() {
    let novel = String::from("Call me Ishmael. Some years ago...");
    let first_sentence = novel.split('.').next().unwrap();

    let excerpt = ImportantExcerpt {
        part: first_sentence,
    };

    println!("Excerpt: {}", excerpt.part);
}
```

## 智能指针选择

| 场景 | 选择 | 原因 |
|-----|------|------|
| 堆分配单个值 | `Box<T>` | 简单直接 |
| 单线程共享引用计数 | `Rc<T>` | 轻量级 |
| 多线程共享引用计数 | `Arc<T>` | 原子操作 |
| 需要运行时借用检查 | `RefCell<T>` | 单线程内部可变性 |
| 多线程内部可变性 | `Mutex<T>` 或 `RwLock<T>` | 线程安全 |

## 常见错误代码

| 错误码 | 含义 | 常见原因 |
|-------|------|---------|
| E0382 | 值被移动后使用 | 尝试使用已转移所有权的值 |
| E0597 | 生命周期太短 | 返回的引用指向临时值 |
| E0506 | 借用未结束就被修改 | 可变借用期间尝试修改原值 |
| E0507 | 从引用移动出数据 | 尝试从引用获取所有权 |
| E0106 | 生命周期参数缺失 | 返回引用但未标注生命周期 |

## 最佳实践

1. **优先返回所有权**：让调用者决定是否需要所有权
2. **借用优于移动**：只读操作使用引用
3. **生命周期名称要有意义**：使用描述性名称如 `'connection`、`'file`
4. **避免不必要的克隆**：使用引用传递大对象
5. **理解借用规则**：可变引用和不可变引用不能同时存在
