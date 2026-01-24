---
name: skill-index
description: "查询所有可用技能"
category: system
triggers: ["skill", "index", "list", "技能列表", "可用技能"]
related_skills:
  - rust-skill-index
  - rust-learner
---

# Skill Index 命令

## 功能说明

查询 Rust Skill 系统中的所有可用技能，按分类展示。

## 使用方法

```bash
# 列出所有技能
./scripts/skill-index.sh

# 按类别查询
./scripts/skill-index.sh --category core
./scripts/skill-index.sh --category advanced
./scripts/skill-index.sh --category expert

# 搜索技能
./scripts/skill-index.sh --search ownership
```

## 技能分类

### Core Skills (核心技能)
| 技能 | 描述 | 触发词 |
|-----|------|-------|
| rust-skill | 主入口 | Rust, cargo, compile |
| rust-ownership | 所有权 | ownership, borrow, lifetime |
| rust-mutability | 可变性 | mut, Cell, RefCell |
| rust-concurrency | 并发 | thread, async, tokio |
| rust-error | 错误处理 | Result, Error, panic |

### Advanced Skills (进阶技能)
| 技能 | 描述 | 触发词 |
|-----|------|-------|
| rust-unsafe | Unsafe 代码 | unsafe, FFI, raw pointer |
| rust-anti-pattern | 反模式 | anti-pattern, clone, unwrap |
| rust-performance | 性能优化 | performance, benchmark |
| rust-web | Web 开发 | web, axum, HTTP |

### Expert Skills (专家技能)
| 技能 | 描述 | 触发词 |
|-----|------|-------|
| rust-ffi | 跨语言调用 | FFI, C, C++, bindgen |
| rust-pin | Pin 与自引用 | Pin, Unpin |
| rust-macro | 宏与过程宏 | macro, derive |
| rust-async | 异步模式 | Stream, backpressure |

## 关联技能
- `rust-skill-index` - 技能索引
- `rust-learner` - 学习引导

