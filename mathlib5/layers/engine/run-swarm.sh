#!/bin/sh
# run-swarm.sh — P/NP Swarm Mathematical Engine (POSIX sh)
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
echo "P/NP Swarm Mathematical Engine"
if command -v gfortran >/dev/null 2>&1; then
    gfortran -O2 -o "$SCRIPT_DIR/fortran/pnp_solver" "$SCRIPT_DIR/fortran/pnp_solver.f90" 2>/dev/null || true
fi
if [ -f "$SCRIPT_DIR/fortran/pnp_solver" ]; then
    "$SCRIPT_DIR/fortran/pnp_solver" 2>/dev/null || true
fi
echo "Done"
