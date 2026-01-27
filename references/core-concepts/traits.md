# Rust Trait 系统指南

Trait 是 Rust 类型系统的核心，类似于其他语言的接口（interface）和抽象基类（abstract base class）。

## Trait 基础

### 定义 Trait

```rust
// 定义一个 trait
pub trait Summary {
    fn summarize(&self) -> String;
}

// 为类型实现 trait
pub struct NewsArticle {
    pub headline: String,
    pub location: String,
    pub author: String,
    pub content: String,
}

impl Summary for NewsArticle {
    fn summarize(&self) -> String {
        format!("{}，{} 报道：{}", self.headline, self.location, self.author)
    }
}
```

### 默认实现

```rust
pub trait Summary {
    // 提供默认实现
    fn summarize(&self) -> String {
        String::from("(读取更多...)")
    }
}

// 可以选择覆盖默认实现
impl Summary for NewsArticle {
    fn summarize(&self) -> String {
        format!("{} - {}", self.headline, self.author)
    }
}
```

## Trait 作为约束

### Trait Bound

```rust
// 单个 trait 约束
fn notify<T: Summary>(item: &T) {
    println!("新闻摘要：{}", item.summarize());
}

// 多个 trait 约束
fn notify<T: Summary + Clone>(item: &T) {
    println!("新闻摘要：{}", item.summarize());
}

// 使用 where 子句（更清晰）
fn notify<T>(item: &T)
where
    T: Summary + Clone,
{
    println!("新闻摘要：{}", item.summarize());
}
```

### 返回实现 Trait 的类型

```rust
// 返回 impl Trait
fn returns_summarizable() -> impl Summary {
    NewsArticle {
        headline: String::from("Penguins win the Stanley Cup"),
        location: String::from("Pittsburgh, PA, USA"),
        author: String::from("Iceburgh"),
        content: String::from("The Pittsburgh Penguins once again are the best"),
    }
}
```

## 常用 Trait

### Display 和 Debug

```rust
// Debug 用于调试输出
#[derive(Debug)]
struct Rectangle {
    width: u32,
    height: u32,
}

// Display 用于用户输出
use std::fmt;

impl fmt::Display for Rectangle {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "{}x{} 的矩形", self.width, self.height)
    }
}

// 使用
let rect = Rectangle { width: 30, 50 };
println!("{:?}", rect);           // Debug: Rectangle { width: 30, height: 50 }
println!("{}", rect);             // Display: 30x50 的矩形
```

### PartialEq 和 Eq（相等性）

```rust
#[derive(PartialEq, Debug)]
struct Point {
    x: i32,
    y: i32,
}

// 可以比较
assert!(Point { x: 1, y: 2 } == Point { x: 1, y: 2 });
```

### Clone 和 Copy（克隆与拷贝）

```rust
// Clone：显式深拷贝
#[derive(Clone)]
struct Person {
    name: String,
    age: u32,
}

// Copy：按位复制（需要所有字段都实现 Copy）
#[derive(Copy, Clone)]
struct Point(i32, i32);
```

### Default（默认值）

```rust
#[derive(Default)]
struct Config {
    host: String,
    port: u16,
    max_connections: u32,
}

let config = Config::default();
```

### From 和 Into（类型转换）

```rust
#[derive(From)]
struct Point {
    x: i32,
    y: i32,
}

let p = Point::from((10, 20));

// 实现 Into
impl From<String> for Message {
    fn from(s: String) -> Self {
        Message { content: s }
    }
}
```

### AsRef 和 AsMut（引用转换）

```rust
struct Person {
    name: String,
}

impl AsRef<str> for Person {
    fn as_ref(&self) -> &str {
        &self.name
    }
}

// 使用
let person = Person { name: String::from("Alice") };
let name: &str = person.as_ref();
```

### Deref 和 DerefMut（解引用）

```rust
use std::ops::Deref;

struct MyBox<T>(T);

impl<T> Deref for MyBox<T> {
    type Target = T;
    fn deref(&self) -> &T {
        &self.0
    }
}

// 可以自动解引用
let x = MyBox(5);
assert_eq!(x, 5);
```

## 关联类型

```rust
pub trait Iterator {
    type Item;  // 关联类型
    
    fn next(&mut self) -> Option<Self::Item>;
}

struct Counter {
    count: u32,
}

impl Iterator for Counter {
    type Item = u32;
    
    fn next(&mut self) -> Option<Self::Item> {
        if self.count < 5 {
            self.count += 1;
            Some(self.count)
        } else {
            None
        }
    }
}
```

## 泛型关联类型（GAT）

```rust
trait Container {
    type Item<'a> where Self: 'a;
    
    fn get(&self, index: usize) -> Option<Self::Item<'_>>;
}

impl<T> Container for Vec<T> {
    type Item<'a> = &'a T where Self: 'a;
    
    fn get(&self, index: usize) -> Option<Self::Item<'_>> {
        self.get(index)
    }
}
```

## Trait 对象（dyn Trait）

### 什么是 Trait 对象

```rust
// 静态分派：泛型
fn summarize<T: Summary>(item: &T) {
    println!("{}", item.summarize());
}

// 动态分派：trait 对象
fn summarize_dyn(item: &dyn Summary) {
    println!("{}", item.summarize());
}
```

### Trait 对象使用场景

```rust
// 异构集合：不同类型但实现同一 trait
struct Handler {
    handlers: Vec<Box<dyn Fn(i32) -> i32>>,
}

impl Handler {
    fn add<F: Fn(i32) -> i32 + 'static>(&mut self, handler: F) {
        self.handlers.push(Box::new(handler));
    }
    
    fn apply(&self, value: i32) -> i32 {
        self.handlers.iter().fold(value, |acc, h| h(acc))
    }
}
```

### 对象安全规则

```rust
// ❌ 不是对象安全的：返回 Self
trait Bad {
    fn create(&self) -> Self;
}

// ❌ 不是对象安全的：泛型方法
trait Bad2 {
    fn process<T>(&self, item: T);
}

// ✅ 对象安全
trait Good {
    fn name(&self) -> &str;
}
```

## Trait 继承

```rust
trait Person {
    fn name(&self) -> String;
}

trait Employee: Person {
    fn salary(&self) -> u32;
}

struct Manager {
    name: String,
    salary: u32,
}

impl Person for Manager {
    fn name(&self) -> String {
        self.name.clone()
    }
}

impl Employee for Manager {
    fn salary(&self) -> u32 {
        self.salary
    }
}
```

## 常用 Trait 实现

### DerefCoercion（自动解引用）

```rust
// Rust 会自动解引用
fn print_length(s: &str) {
    println!("{}", s.length());
}

let string = String::from("hello");
print_length(&string);  // 自动解引用为 &str
```

### blanket implementations

```rust
// 标准库提供的 blanket 实现
impl<T: Display> Display for Vec<T> {
    // ...
}

// 意味着所有 Display 类型都可以这样处理
```

## 高级 Trait

### marker traits

```rust
// Send：可以安全地在线程间传递
unsafe impl Send for MyData {}

// Sync：可以安全地在线程间共享引用
unsafe impl Sync for MyData {}
```

### Drop Trait

```rust
struct File {
    name: String,
    handle: std::fs::File,
}

impl Drop for File {
    fn drop(&mut self) {
        println!("关闭文件：{}", self.name);
    }
}
```

### Fn Trait

```rust
// FnOnce：可以调用一次
fn consume_fn<T: FnOnce()>(f: T) {
    f();  // 只能调用一次
}

// FnMut：可以调用多次，可变借用
fn mutable_fn<T: FnMut(&mut i32)>(f: &mut T) {
    let mut x = 10;
    f(&mut x);
}

// Fn：可以调用多次，不可变借用
fn immutable_fn<T: Fn(i32) -> i32>(f: &T) {
    let result = f(5);
}
```

## Trait 最佳实践

### 1. 优先使用组合而非继承

```rust
// ❌ 不好的设计：使用继承
trait Animal {
    fn speak(&self);
}

struct Dog {
    name: String,
}

impl Animal for Dog {
    fn speak(&self) {
        println!("Woof!");
    }
}

// ✅ 好的设计：使用组合
struct Speaker {
    message: String,
}

impl Speaker {
    fn speak(&self) {
        println!("{}", self.message);
    }
}
```

### 2. 使用 newtype 模式

```rust
// 包装类型以添加 trait
struct Meters(u32);

impl std::fmt::Display for Meters {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        write!(f, "{}m", self.0)
    }
}
```

### 3. 使用 trait bound 而非强制转换

```rust
// ✅ 好的：明确的约束
fn process<T: Summary>(item: &T) {
    item.summarize();
}

// ❌ 不好的：依赖运行时类型检查
fn process(item: &dyn Summary) {
    item.summarize();
}
```

## 常见错误

| 错误码 | 含义 | 解决 |
|-------|------|------|
| E0277 | 缺少 trait bound | 添加 `T: Trait` |
| E0038 | trait object 不安全 | 检查对象安全规则 |
| E0117 | 已存在实现 | 使用 newtype 或委派 |
| E0323/4/5 | 未找到 trait 实现 | 实现 trait 或检查约束 |

## 进一步阅读

- [Trait Bounds - Rust Book](https://doc.rust-lang.org/book/ch10-02-traits.html)
- [Advanced Traits](https://doc.rust-lang.org/book/ch19-03-advanced-traits.html)
- [std::ops](https://doc.rust-lang.org/std/ops/index.html) - 操作符 trait

