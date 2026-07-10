#!/bin/sh
# run_r.sh — R script runner
# Checks for R, runs scripts

set -e

R_DIR="layers/scripting/r"

if ! command -v Rscript > /dev/null 2>&1; then
    echo "R not found, skipping R scripts"
    exit 0
fi

echo "Running R scripts..."
echo ""

for f in "$R_DIR"/*.R; do
    [ -f "$f" ] || continue
    echo ">> $f"
    Rscript "$f"
    echo ""
done

echo "R scripts complete."
