#!/bin/sh
# run_benchmarks.sh — MATHLIB5 Benchmark Suite (POSIX sh)
# Run: sh benchmarks/run_benchmarks.sh

set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "============================================================"
echo " MATHLIB5 Benchmark Suite"
echo "============================================================"

# ── FOL Checker benchmark ──
echo ""
echo ">> FOL Checker"
FOL_BIN="$ROOT/layers/fol/src/fol_check"
if [ -f "$FOL_BIN" ]; then
    for n in 5 10 20 50; do
        # Generate chain proof
        tmpf=$(mktemp /tmp/m5bench.XXXXXX)
        printf '0 P0\n' > "$tmpf"
        i=1
        while [ "$i" -lt "$n" ]; do
            printf '%d P%d from %d %d\n' "$i" "$i" "$((i-1))" "$((i-1))" >> "$tmpf"
            i=$((i+1))
        done
        printf '%d from %d %d\n' "$n" "$((n-1))" "$((n-1))" >> "$tmpf"

        t0=$(date +%s%N)
        "$FOL_BIN" "$tmpf" >/dev/null 2>&1 || true
        t1=$(date +%s%N)
        elapsed=$(( (t1 - t0) / 1000000 ))
        printf "  fol_chain_%d: %dms\n" "$n" "$elapsed"
        rm -f "$tmpf"
    done
else
    echo "  (FOL binary not found, skipped)"
fi

# ── Rust benchmark ──
echo ""
echo ">> Rust benchmarks"
if [ -f "$ROOT/target/release/mathlib5_symbolic.dll" ] || [ -f "$ROOT/target/release/libmathlib5_symbolic.a" ]; then
    echo "  Rust binaries available"
else
    echo "  Building release..."
    cd "$ROOT" && cargo build --release 2>/dev/null || true
fi

# ── QF_LRA benchmark ──
echo ""
echo ">> QF_LRA Solver"
QF_BIN="$ROOT/malice_layer2/solver/qf_lra_solver"
if [ -f "$QF_BIN" ] || [ -f "${QF_BIN}.exe" ]; then
    for n in 3 5 10; do
        tmpf=$(mktemp /tmp/m5bench.XXXXXX)
        i=0
        while [ "$i" -lt "$n" ]; do
            printf '(<= x%d %d)\n' "$i" "$((10*(i+1)))" >> "$tmpf"
            i=$((i+1))
        done
        t0=$(date +%s%N)
        "${QF_BIN}" "$tmpf" >/dev/null 2>&1 || true
        t1=$(date +%s%N)
        elapsed=$(( (t1 - t0) / 1000000 ))
        printf "  qf_lra_%d_vars: %dms\n" "$n" "$elapsed"
        rm -f "$tmpf"
    done
else
    echo "  (QF_LRA binary not found, skipped)"
fi

echo ""
echo "============================================================"
echo " Benchmarks complete"
echo "============================================================"
