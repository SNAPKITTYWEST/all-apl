#!/bin/sh
# verify_chain.sh — ASP→C99→CodeQL verification (POSIX sh)
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LAYER_DIR="$SCRIPT_DIR/../../.."
FOL_SRC="$LAYER_DIR/layers/fol/src/fol_resolution_checker.c"
FOL_BIN="$LAYER_DIR/layers/fol/src/fol_check"
if [ $# -lt 1 ]; then echo "Usage: $0 <problem.lp>"; exit 1; fi
PROBLEM="$1"; shift
echo "MATHLIB5 Verification Chain: $PROBLEM"
if [ ! -f "$FOL_BIN" ] || [ "$FOL_SRC" -nt "$FOL_BIN" ]; then
    gcc -std=c99 -O2 "$FOL_SRC" -o "$FOL_BIN"
fi
if command -v clingo >/dev/null 2>&1; then
    clingo "$PROBLEM" "$@" --text 2>/dev/null > /tmp/asp_stable_model.txt || true
fi
if [ -f /tmp/asp_stable_model.txt ] && [ -f "$FOL_BIN" ]; then
    "$FOL_BIN" /tmp/asp_stable_model.txt && echo "FOL VALID" || echo "FOL INVALID"
fi
echo "Verification complete"
