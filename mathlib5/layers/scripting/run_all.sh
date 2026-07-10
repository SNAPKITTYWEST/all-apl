#!/bin/sh
# run_all.sh — Run all scripting layers
# Orchestrates R, PowerShell, REXX, POSIX sh

set -e

echo "═══════════════════════════════════════════════════════════"
echo " MATHLIB5 Scripting Layer Runner"
echo "═══════════════════════════════════════════════════════════"
echo ""

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# R scripts
if [ -f "$SCRIPT_DIR/run_r.sh" ]; then
    echo ">> R scripts..."
    sh "$SCRIPT_DIR/run_r.sh"
    echo ""
fi

# PowerShell scripts
if [ -f "$SCRIPT_DIR/run_powershell.sh" ]; then
    echo ">> PowerShell scripts..."
    sh "$SCRIPT_DIR/run_powershell.sh"
    echo ""
fi

# REXX scripts (if interpreter available)
if [ -f "$SCRIPT_DIR/run_rexx.sh" ]; then
    echo ">> REXX scripts..."
    sh "$SCRIPT_DIR/run_rexx.sh"
    echo ""
fi

echo "═══════════════════════════════════════════════════════════"
echo " All scripting layers complete"
echo "═══════════════════════════════════════════════════════════"
