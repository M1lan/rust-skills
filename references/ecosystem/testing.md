# Rust 测试策略

全面的测试确保代码正确性并防止回归。

## 测试组织

### 单元测试

```rust
// 与代码在同一文件中
fn add(a: i32, b: i32) -> i32 {
    a + b
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_add_positive() {
        assert_eq!(add(2, 3), 5);
    }
    
    #[test]
    fn test_add_negative() {
        assert_eq!(add(-1, 1), 0);
    }
    
    #[test]
    #[should_panic(expected = "value must be positive")]
    fn test_add_panics_for_invalid_input() {
        // 测试 panic 情况
    }
}
```

### 集成测试

```rust
// tests/integration_test.rs
use my_crate::add;

#[test]
fn test_integration() {
    let result = add(10, 20);
    assert_eq!(result, 30);
}
```

### 文档测试

```rust
/// 将两个数字相加。
///
/// # 示例
///
/// ```
/// use my_crate::add;
/// assert_eq!(add(1, 2), 3);
/// ```
pub fn add(a: i32, b: i32) -> i32 {
    a + b
}
```

## 测试断言

### 基础断言

```rust
#[test]
fn test_assertions() {
    assert!(condition);
    assert!(!condition, "可选消息");
    assert_eq!(left, right);
    assert_ne!(left, right);
}
```

### 浮点数测试

```rust
#[test]
fn test_floating_point() {
    let result = 0.1 + 0.2;
    assert!((result - 0.3).abs() < 1e-10);
}
```

### 自定义断言

```rust
#[track_caller]
fn assert_within_range(value: i32, min: i32, max: i32) {
    assert!(
        value >= min && value <= max,
        "值 {} 不在范围 [{}, {}] 内",
        value,
        min,
        max
    );
}
```

## 测试错误处理

```rust
fn divide(a: i32, b: i32) -> Result<f64, &'static str> {
    if b == 0 {
        Err("不能除以零")
    } else {
        Ok(a as f64 / b as f64)
    }
}

#[cfg(test)]
mod error_tests {
    use super::*;
    
    #[test]
    fn test_divide_by_zero() {
        let result = divide(10, 0);
        assert!(result.is_err());
        assert_eq!(result.unwrap_err(), "不能除以零");
    }
    
    #[test]
    fn test_divide_success() {
        let result = divide(10, 2);
        assert!(result.is_ok());
        assert!((result.unwrap() - 5.0).abs() < 1e-10);
    }
}
```

## 测试私有函数

```rust
// lib.rs
fn internal_helper(input: &str) -> bool {
    input.starts_with('_')
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_internal() {
        assert!(internal_helper("_private"));
        assert!(!internal_helper("public"));
    }
}
```

## 属性测试

```rust
use proptest::prelude::*;

proptest! {
    #[test]
    fn test_reverse_twice(s: String) {
        let reversed: String = s.chars().rev().collect();
        let double_reversed: String = reversed.chars().rev().collect();
        assert_eq!(s, double_reversed);
    }
    
    #[test]
    fn test_add_commutative(a: i32, b: i32) {
        assert_eq!(a + b, b + a);
    }
}
```

## Mock 测试

```rust
// 使用 mockall
#[cfg(test)]
mod tests {
    use super::*;
    use mockall::predicate::*;
    
    #[tokio::test]
    async fn test_with_mock() {
        let mut mock = MockDatabase::new();
        mock.expect_query()
            .with(eq("SELECT * FROM users"))
            .returning(|_| Ok(vec![User { id: 1, name: "Alice" }]));
        
        let result = fetch_users(&mock).await;
        assert!(result.is_ok());
        assert_eq!(result.unwrap().len(), 1);
    }
}
```

## 基准测试

```rust
#![feature(test)]
extern crate test;

use test::Bencher;

#[bench]
fn bench_addition(b: &mut Bencher) {
    b.iter(|| {
        (0..1000).fold(0, |acc, x| acc + x)
    });
}
```

## 运行测试

```bash
# 运行所有测试
cargo test

# 运行特定测试
cargo test test_name

# 运行特定模块的测试
cargo test module_name

# 运行文档测试
cargo test --doc

# 运行测试并显示输出
cargo test -- --nocapture

# 在 release 模式下运行测试
cargo test --release

# 运行测试并生成覆盖率报告
cargo tarpaulin
```

## 测试组织最佳实践

```
src/
├── lib.rs
├── module1.rs
├── module2.rs
└── module1/
    └── mod.rs

tests/
├── integration_test1.rs
└── integration_test2.rs

benches/
├── bench1.rs
└── bench2.rs

Cargo.toml
```

## 持续集成

```yaml
# .github/workflows/rust.yml
name: Rust

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: 运行测试
        run: cargo test --all-features
      - name: 运行 clippy
        run: cargo clippy --all-targets -- -D warnings
      - name: 检查格式化
        run: cargo fmt --check
```

## 总结

| 测试类型 | 用途 | 位置 |
|---------|------|------|
| 单元测试 | 测试单个函数 | 源码中的 `#[cfg(test)]` |
| 集成测试 | 测试模块交互 | `tests/` 目录 |
| 文档测试 | 验证文档示例 | 文档注释中 |
| 属性测试 | 跨输入测试属性 | `proptest!` 宏 |
| 基准测试 | 测量性能 | `benches/` 目录 |

## 现代测试工具

### rstest - 基于夹具的测试

```rust
use rstest::*;

#[fixture]
fn fibonacci_input() -> u32 {
    10
}

#[rstest]
fn test_fibonacci[
    fibonacci_input,
    // 来自夹具的参数
    case(0, 0),
    case(1, 1),
    case(2, 1),
    case(3, 2),
    case(4, 3),
    case(5, 5),
    case(6, 8),
    case(7, 13),
    case(8, 21),
    case(9, 34),
    case(10, 55),
](n: u32, expected: u64) {
    assert_eq!(fibonacci(n), expected);
}
```

### proptest - 属性测试

```rust
use proptest::prelude::*;

proptest! {
    #[test]
    fn test_sort_properties(vec in prop::collection::vec(0..1000i32, 0..100)) {
        let mut sorted = vec.clone();
        sorted.sort();
        
        // 检查已排序
        assert!(sorted.windows(2).all(|w| w[0] <= w[1]));
        
        // 检查元素相同
        assert_eq!(sorted.len(), vec.len());
        let mut sorted_copy = sorted;
        sorted_copy.sort();
        assert_eq!(sorted, sorted_copy);
    }
    
    #[test]
    fn test_add_commutative(a in 0i64..10000, b in 0i64..10000) {
        assert_eq!(a + b, b + a);
    }
}
```

### quickcheck - 快速属性测试

```rust
use quickcheck::{QuickCheck, TestResult};

fn property_add_commutative(a: i32, b: i32) -> TestResult {
    if a == i32::MAX || b == i32::MAX {
        return TestResult::discard();
    }
    TestResult::from_bool(a + b == b + a)
}

#[test]
fn test_quickcheck() {
    QuickCheck::new().tests(1000).quickcheck(property_add_commutative);
}
```

### mockall - Mock 框架

```rust
use mockall::{mock, predicate::*};

mock! {
    Database {
        fn connect() -> Result<Connection, Error>;
        fn query(&self, sql: &str) -> Result<Vec<Row>, Error>;
    }
}

#[test]
fn test_with_mock() {
    let mut mock = MockDatabase::new();
    
    mock.expect_connect()
        .returning(|| Ok(Connection::new()));
    
    mock.expect_query()
        .with(eq("SELECT * FROM users"))
        .returning(|_| Ok(vec![Row::new("user1")]));
    
    let result = mock.query("SELECT * FROM users");
    assert!(result.is_ok());
}
```

### tempfile - 临时测试数据

```rust
use tempfile::TempDir;

#[test]
fn test_with_temp_file() {
    let temp_dir = TempDir::new().unwrap();
    let file_path = temp_dir.path().join("test.txt");
    
    std::fs::write(&file_path, "test data").unwrap();
    
    let content = std::fs::read_to_string(&file_path).unwrap();
    assert_eq!(content, "test data");
    
    // 当 temp_dir 离开作用域时自动清理
}
```

### assert_fs - 文件系统测试

```rust
use assert_fs::prelude::*;
use assert_fs::TempDir;

#[test]
fn test_config_file() -> Result<(), Box<dyn std::error::Error>> {
    let temp = TempDir::new()?;
    let file = temp.child("config.json");
    
    file.write_str(r#"{"port": 8080}"#)?;
    
    let content = file.read_string()?;
    assert!(content.contains("8080"));
    
    Ok(())
}
```

## 测试组织最佳实践

```
src/
├── lib.rs
├── main.rs
└── ...
    ├── module_a.rs
    └── module_a/
        └── tests.rs  // module_a 的集成测试

tests/
├── integration_a.rs
└── integration_b.rs

benches/
└── benchmark.rs
```
