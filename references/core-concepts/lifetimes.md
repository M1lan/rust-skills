# 生命周期注解指南（Lifetime Annotations Guide）

生命周期注解告诉编译器引用之间如何关联，确保引用始终有效。

## 基本生命周期

### 语法

```rust
&'a str      // 带生命周期 'a 的引用
&'a T        // 泛型引用，带生命周期 'a
```

### 示例

```rust
// 'a 表示 x 和 y 中较短的生命周期
fn longest<'a>(x: &'a str, y: &'a str) -> &'a str {
    if x.len() > y.len() {
        x
    } else {
        y
    }
}
```

## 需要生命周期注解的场景

### 结构体中的引用

```rust
// ImportantExcerpt 的生命周期不能超过它引用的文本
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

### 方法

```rust
impl<'a> ImportantExcerpt<'a> {
    fn announce_and_return_part(&self, announcement: &str) -> &str {
        println!("Attention please: {}", announcement);
        self.part
    }
}
```

## 生命周期省略规则

Rust 自动应用三条省略规则。

### 规则 1：输入生命周期

```rust
// 这些是等价的：
fn foo(s: &str) -> &str { s }
fn foo<'a>(s: &'a str) -> &'a str { s }
```

### 规则 2：从输入生命周期推断输出生命周期

```rust
// fn first_word(s: &str) -> &str { ... }
// 变成：
fn first_word<'a>(s: &'a str) -> &'a str { ... }
```

### 规则 3：单个输入生命周期

```rust
// fn method(&self) -> &str { ... }
// 变成：
fn method<'a>(&'a self) -> &'a str { ... }
```

## 静态生命周期

```rust
// 存活整个程序周期
let s: &'static str = "I live forever!";

// 字符串字面量具有静态生命周期
fn print_message() -> &'static str {
    "Hello, world!"
}
```

## 多生命周期

```rust
fn both_ends<'a, 'b>(s1: &'a str, s2: &'b str) -> &'a str {
    if s1.len() > s2.len() {
        s1
    } else {
        s2
    }
}
```

## 高阶 trait 约束（HRTB）

### 什么是 HRTB？

允许指定"对于所有生命周期"的约束。

```rust
// T 的引用可以实现 F，其中 F 接受任何生命周期的引用
fn call_with_any_lifetime<T, F>(val: T, f: F)
where
    F: Fn(&T),
{
    f(&val);
}
```

### FnMut 约束

```rust
// 接受返回引用的闭包，且引用生命周期自由
fn make_processor<T>(processor: impl Fn(&T) -> &T) {
    let value = T::default();
    let result = processor(&value);
}
```

## 泛型关联类型（GAT）

```rust
trait Container {
    type Item<'a> where Self: 'a;
    fn get(&self, index: usize) -> Option<Self::Item<'_>>;
}

struct VecContainer<T> {
    data: Vec<T>,
}

impl<T> Container for VecContainer<T> {
    type Item<'a> = &'a T where Self: 'a;

    fn get(&self, index: usize) -> Option<Self::Item<'_>> {
        self.data.get(index)
    }
}
```

## 生命周期常见错误

| 错误码 | 含义 | 解决方案 |
|-------|------|---------|
| E0597 | 借用生命周期太短 | 确保引用指向的值存活足够久 |
| E0106 | 生命周期参数缺失 | 为返回引用的函数添加生命周期注解 |
| E0515 | 无法返回引用 | 考虑返回所有权类型 |
| E0621 | 生命周期约束不匹配 | 调整生命周期注解以正确表达关系 |

## 最佳实践

1. **优先使用借用而非生命周期注解**：返回所有权类型可以避免生命周期问题
2. **生命周期名称要有意义**：使用 `'connection`、`'file` 等描述性名称
3. **避免过度使用 `'static`**：只有真正需要时才使用
4. **理解省略规则**：大多数情况编译器能自动推断
5. **结构体需要生命周期时再添加**：只在包含引用时才需要

## 复杂生命周期模式

### NLL（非词法生命周期）

Rust 2018 引入的改进，引用可以在其使用范围结束后更早释放。

```rust
// 旧版本可能需要分开声明
let mut x = String::new();
let r;
x = String::from("hello");  // 重新绑定导致 r 的借用结束
r = &x;  // NLL 允许这个

println!("{}", r);
```

### 异步代码中的生命周期

```rust
// 返回 impl Trait 时生命周期处理
async fn get_data<'a>(conn: &'a Connection) -> Data {
    conn.query().await
}

// 使用 Pin 处理自引用结构
struct SelfRef {
    value: i32,
    pointer_to_value: *const i32,
}
```

### 闭包中的生命周期

```rust
// 闭包捕获引用时的生命周期处理
fn create_closure<'a, T>(value: &'a T) -> impl Fn() -> &'a T {
    move || value
}
```
