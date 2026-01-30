#!/usr/bin/env bash
set -euo pipefail

echo "📊 Running Rust tests..."

# Get available CPU threads for parallel testing
if command -v nproc &> /dev/null; then
    THREADS=$(nproc)
elif command -v sysctl &> /dev/null; then
    THREADS=$(sysctl -n hw.ncpu)
else
    THREADS=4
fi

# Run all tests in parallel
echo "🏃‍♀️‍➡️ Running tests in parallel (${THREADS} threads)..."
cargo test --workspace --all-targets -- --test-threads="$THREADS" "$@"

echo "✅ All tests passed!"
