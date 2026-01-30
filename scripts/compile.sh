#!/usr/bin/env bash
set -euo pipefail

echo "🔍 Running cargo check..."
cargo check --all-targets --message-format=short "$@"

echo "✅ All checks passed!"
