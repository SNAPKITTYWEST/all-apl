#!/bin/sh
# run_powershell.sh — PowerShell script runner
# Checks for PowerShell, runs scripts

set -e

PS_DIR="layers/scripting/powershell"

if ! command -v powershell > /dev/null 2>&1; then
    echo "PowerShell not found, skipping PowerShell scripts"
    exit 0
fi

echo "Running PowerShell scripts..."
echo ""

for f in "$PS_DIR"/*.ps1; do
    [ -f "$f" ] || continue
    echo ">> $f"
    powershell -ExecutionPolicy Bypass -File "$f"
    echo ""
done

echo "PowerShell scripts complete."
