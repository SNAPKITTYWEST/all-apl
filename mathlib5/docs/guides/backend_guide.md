# Backend Guide

## Overview

MATHLIB5 compiles verified code to multiple targets:

```
MATHLIB5 Source
      ↓
  Core Language (CIC)
      ↓
  ┌───┴───┐
  │ LLVM  │ → Native binaries
  │ WASM  │ → Web/browser
  │ C--   │ → Certified compilation
  │ MLIR  │ → Hardware synthesis
  └───────┘
```

## LLVM Backend

```bash
# Compile to LLVM IR
mathlib5 compile --target llvm input.m5 -o output.ll

# Optimize and generate binary
llc -O2 output.ll -o output.s
gcc output.s -o output
```

## WebAssembly Backend

```bash
# Compile to WASM
mathlib5 compile --target wasm input.m5 -o output.wasm

# Run in browser
node -e "require('fs').readFileSync('output.wasm')"
```

## C-- Backend (CompCert)

```bash
# Compile to C-- (verified compilation)
mathlib5 compile --target cmm input.m5 -o output.mm

# Compile with CompCert
ccomp -O2 output.mm -o output
```

## MLIR Backend (Hardware)

```bash
# Compile to MLIR for FPGA/ASIC synthesis
mathlib5 compile --target mlir input.m5 -o output.mlir

# Synthesize with Xilinx Vivado
vivado -mode batch -source synthesize.tcl
```

## Interoperability

### Import Lean Theories

```bash
# Import from Lean 4
mathlib5 import-lean Mathlib.Data.Nat.Prime -o NatPrime.m5
```

### Export to SMT

```bash
# Export to SMT-LIB for Z3/cvc5
mathlib5 export-smt theorem.m5 -o theorem.smt2

# Solve with Z3
z3 theorem.smt2
```

### Exchange with Symbolic Algebra

```bash
# Export to SymPy
mathlib5 export-sympy expr.m5 -o expr.py

# Import from SymPy
mathlib5 import-sympy expr.py -o expr.m5
```
