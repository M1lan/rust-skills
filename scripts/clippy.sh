#!/usr/bin/env bash
set -euo pipefail

echo "🔎 Running clippy with strict warnings..."
cargo clippy --all-targets -- -D warnings "$@"

echo "✅ Clippy passed with no warnings!"
