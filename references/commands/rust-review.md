---
name: rust-review
description: "代码质量审查工具"
category: code-quality
triggers: ["review", "clippy", "lint", "审查", "代码质量"]
related_skills:
  - rust-coding
  - rust-anti-pattern
  - rust-unsafe
---

# Rust Review 命令

## 功能说明

对 Rust 代码进行质量审查，检测：
- 代码风格问题
- 潜在的 bug
- 性能隐患
- 违反最佳实践

## 使用方法

```bash
# 审查整个项目
./scripts/review.sh

# 审查指定文件
./scripts/review.sh src/main.rs

# 仅运行 Clippy
cargo clippy --all-targets
```

## 问题分类

| 严重级别 | 说明 | 处理建议 |
|---------|------|---------|
| 🔴 Error | 编译错误 | 立即修复 |
| 🟠 Warning | 潜在问题 | 优先处理 |
| 🟡 Advice | 改进建议 | 按需优化 |

## 常见问题修复

### Clone 优化
```rust
// ❌ 避免：不必要的 clone
let data = values.clone();

// ✅ 推荐：借用或 Rc/Arc
let data = &values;
```

### Unwrap 使用
```rust
// ❌ 避免：unwrap panic 风险
let value = map.get(key).unwrap();

// ✅ 推荐：模式匹配或 unwrap_or
let value = map.get(key).unwrap_or(&default);
```

## 关联技能
- `rust-coding` - 编码规范
- `rust-anti-pattern` - 反模式识别

