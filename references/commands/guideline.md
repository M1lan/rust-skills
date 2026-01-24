---
name: guideline
description: "查询编码规范和最佳实践"
category: coding-standard
triggers: ["guideline", "style", "naming", "规范", "命名"]
related_skills:
  - rust-coding
  - rust-anti-pattern
  - rust-learner
---

# Guideline 命令

## 功能说明

查询 Rust 编码规范和最佳实践，包括：
- 命名约定
- 代码风格
- 注释要求
- 模块组织

## 使用方法

```bash
# 查看全部规范
./scripts/guideline.sh

# 查询特定类别
./scripts/guideline.sh --category naming
./scripts/guideline.sh --category comments
./scripts/guideline.sh --category modules
```

## 命名规范

### 变量和函数
```rust
// ✅ 推荐
let item_count = 42;
fn calculate_total() {}

// ❌ 避免
let cnt = 42;
fn calc() {}
```

### 常量和类型
```rust
// ✅ 推荐
const MAX_CONNECTIONS: u32 = 100;
struct UserSession;

// ❌ 避免
const max = 100;
struct user_session;
```

### 模块和路径
```rust
// ✅ 推荐
mod network_config;
use crate::models::User;

// ❌ 避免
mod NetworkConfig;
use self::models::User;
```

## 代码风格

| 规范 | 要求 |
|-----|------|
| 行宽 | ≤100 字符 |
| 缩进 | 4 空格 |
| 括号 | 与 K&R 风格一致 |

## 关联技能
- `rust-coding` - 编码规范
- `rust-anti-pattern` - 反模式识别

