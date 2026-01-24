---
name: rust-features
description: "查询 Rust 版本特性"
category: version-info
triggers: ["feature", "edition", "version", "特性", "版本"]
related_skills:
  - rust-learner
  - rust-coding
---

# Rust Features 命令

## 功能说明

查询 Rust 不同版本和 Edition 的特性支持情况。

## 使用方法

```bash
# 查看当前版本特性
./scripts/rust-features.sh --current

# 查询特定 Edition
./scripts/rust-features.sh --edition 2021

# 对比版本差异
./scripts/rust-features.sh --compare 1.70 1.78
```

## Edition 特性

### Rust 2015
- 基础所有权系统
- 生命周期标注
- trait bounds

### Rust 2018
- `?` 运算符稳定
- 模块系统改进
- async/await 基础

### Rust 2021
- `try` 块稳定
- 更严格的类型转换
- 闭包捕获优化

## 常用特性

| 特性 | 稳定版本 | 用途 |
|-----|---------|------|
| async/await | 1.39 | 异步编程 |
| const generics | 1.51 | 编译期计算 |
| never type `!` | 1.41 | 发散函数 |
| union | 1.19 | 原始联合体 |

## 关联技能
- `rust-learner` - 版本学习
- `rust-coding` - 编码规范

