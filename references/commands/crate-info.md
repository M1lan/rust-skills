---
name: crate-info
description: "查询 Crate 依赖信息"
category: dependency-info
triggers: ["crate", "dependency", "library", "依赖", "库"]
related_skills:
  - rust-ecosystem
  - rust-learner
---

# Crate Info 命令

## 功能说明

查询 Rust 生态系统中 Crate 的详细信息：
- 版本和下载量
- 使用统计
- 维护状态
- 替代方案

## 使用方法

```bash
# 查询 Crate 信息
./scripts/crate-info.sh serde

# 查看同类对比
./scripts/crate-info.sh --compare actix axum

# 查找替代品
./scripts/crate-info.sh --alternatives json
```

## 常用 Crate 分类

### Web 框架
| Crate | 周下载量 | 维护状态 | 特点 |
|-------|---------|---------|------|
| axum | 500K+ | 活跃 | 轻量、异步优先 |
| actix-web | 300K+ | 活跃 | 高性能 |
| rocket | 200K+ | 维护中 | 友好 API |

### 序列化
| Crate | 周下载量 | 特点 |
|-------|---------|------|
| serde | 30M+ | JSON/YAML/TOML |
| bincode | 2M+ | 高效二进制 |

### 异步运行时
| Crate | 周下载量 | 特点 |
|-------|---------|------|
| tokio | 25M+ | 全功能 |
| async-std | 1M+ |  std 风格 |

## 关联技能
- `rust-ecosystem` - crate 选择
- `rust-learner` - 生态学习

