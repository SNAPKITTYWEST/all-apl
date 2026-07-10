#!/bin/sh
# run_rexx.sh — REXX script runner using custom interpreter
# Uses our Rust-based REXX interpreter

set -e

REXX_DIR="layers/scripting/rexx"
REXX_BIN="target/release/rexx-interp"

if [ ! -f "$REXX_BIN" ]; then
    echo "REXX interpreter not found, building..."
    cargo build --release -p rexx-interp
fi

echo "Running REXX scripts..."
echo ""

for f in "$REXX_DIR"/*.rexx; do
    [ -f "$f" ] || continue
    echo ">> $f"
    "$REXX_BIN" "$f"
    echo ""
done

echo "REXX scripts complete."
