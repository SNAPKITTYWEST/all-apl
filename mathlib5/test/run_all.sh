#!/bin/sh
# run_all.sh — MATHLIB5 Test Suite (POSIX sh)
# Run: sh test/run_all.sh

set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0
TOTAL=0

pass() { PASS=$((PASS+1)); TOTAL=$((TOTAL+1)); printf "  [PASS] %s\n" "$1"; }
fail() { FAIL=$((FAIL+1)); TOTAL=$((TOTAL+1)); printf "  [FAIL] %s — %s\n" "$1" "$2"; }

echo "============================================================"
echo " MATHLIB5 Test Suite"
echo "============================================================"

# ── FOL Checker ──
echo ""
echo ">> FOL Checker"
FOL_BIN="$ROOT/layers/fol/src/fol_check"
if [ -f "$FOL_BIN" ]; then
    for proof in \
        "0 ~P Q
1 P
2 ~Q
3 Q from 0 1
4 from 3 2" \
        "0 ~P Q
1 ~Q
2 P
3 ~P from 0 1
4 from 2 3" \
        "0 ~P(X) Q(X)
1 ~Q(Y) R(Y)
2 P(a)
3 ~R(a)
4 Q(a) from 0 2
5 R(a) from 1 4
6 from 5 3"; do
        tmpf=$(mktemp /tmp/m5test.XXXXXX)
        printf '%s\n' "$proof" > "$tmpf"
        if "$FOL_BIN" "$tmpf" >/dev/null 2>&1; then
            pass "fol_proof_$$"
        else
            fail "fol_proof_$$" "exit $?"
        fi
        rm -f "$tmpf"
    done

    # Reject invalid
    tmpf=$(mktemp /tmp/m5test.XXXXXX)
    printf '0 P(a)\n1 Q(b)\n' > "$tmpf"
    if "$FOL_BIN" "$tmpf" >/dev/null 2>&1; then
        fail "fol_rejects_invalid" "should have failed"
    else
        pass "fol_rejects_invalid"
    fi
    rm -f "$tmpf"
else
    echo "  (FOL binary not found, skipped)"
fi

# ── Rust test suite ──
echo ""
echo ">> Rust crate tests"
if cd "$ROOT" && cargo test 2>/dev/null | grep -q "test result: ok"; then
    pass "cargo_test"
else
    fail "cargo_test" "cargo test failed"
fi

# ── Summary ──
echo ""
echo "============================================================"
printf " RESULTS: %d/%d passed, %d failed\n" "$PASS" "$TOTAL" "$FAIL"
echo "============================================================"

if [ "$FAIL" -gt 0 ]; then exit 1; fi
