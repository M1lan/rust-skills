---
name: docs
description: "查询 Rust 官方文档"
category: documentation
triggers: ["docs", "documentation", "api", "文档", "API"]
related_skills:
  - rust-learner
  - rust-ecosystem
---

# Docs 命令

## 功能说明

快速查询 Rust 官方文档和 API：
- 标准库文档
-  crates.io 文档
- 官方教程
- RFC 文档

## 使用方法

```bash
# 查询 std 文档
./scripts/docs.sh std Vec

# 查询 crate 文档
./scripts/docs.sh crate serde

# 打开本地文档
./scripts/docs.sh --local

# 搜索文档
./scripts/docs.sh --search "iterator"
```

## 常用文档

### 标准库
| 模块 | 用途 |
|-----|------|
| std::collections | 集合类型 |
| std::sync | 同步原语 |
| std::future | 异步基础 |
| std::io | 输入输出 |

### 书籍和教程
| 资源 | 地址 |
|-----|------|
| Rust Book | doc.rust-lang.org/book |
| Rust By Example | doc.rust-lang.org/rust-by-example |
| Async Book | async-book.cloudshift.tw |

## 快速查询

```bash
# 查询 trait 用法
./scripts/docs.sh trait From

# 查询宏定义
./scripts/docs.sh macro vec!

# 查询属性
./scripts/docs.sh attr derive
```

## 关联技能
- `rust-learner` - 学习引导
- `rust-ecosystem` - crate 文档

