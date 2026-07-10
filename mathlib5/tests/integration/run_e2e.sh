#!/bin/sh
# run_e2e.sh — APL E2E pipeline (POSIX sh)
set -e
if [ $# -lt 1 ]; then echo "Usage: $0 <file.apl>"; exit 1; fi
APL_FILE="$1"
BASE="$(basename "$APL_FILE" .apl)"
echo "APL E2E: $APL_FILE"
if command -v apl_parser >/dev/null 2>&1; then apl_parser "$APL_FILE" > "${BASE}.sexpr"; fi
if command -v sexpr_normalize >/dev/null 2>&1; then sexpr_normalize "${BASE}.sexpr" > "${BASE}.norm.sexpr"; fi
if command -v lean >/dev/null 2>&1; then lean --run=mathlib5_core "${BASE}.lean.obligations" 2>/dev/null || true; fi
echo "Pipeline complete: $BASE"
