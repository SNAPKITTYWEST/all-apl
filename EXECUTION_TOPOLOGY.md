# EXECUTION TOPOLOGY

## Master Topology

This document provides a source-backed map of the active implementation trees within the repository.

### Primary code-bearing trees

- `mathlib5/`
- `agentos_source/`
- `mathlib5-ffi-bridge/`
- `mathrosetta_source/`
- `legacy/`
- `snapkitty-shell/`

---

## Real Source Surfaces

### `mathlib5/`

The primary VSCP implementation:

- APL Front-end: `mathlib5/layers/apl/src/Parser.hs`
- S-Expr IR: `mathlib5/layers/sexpr/src/AST.hs`
- Lean 4 Core: `agentos_source/collatz-verification/proofs/Collatz.lean`
- Verified Kernel (C--): `mathlib5/kernel/verified_kernel.cm`

### `agentos_source/`

Contains the widest active implementation spread:

- APL Corrections: `agentos_source/math-skills/`
- Rust/Cargo Crates: `agentos_source/axiom-proof/`, `agentos_source/prism-skills/`
- Lean 4 Proofs: `agentos_source/collatz-verification/`
- Fortran DSSPEED: `agentos_source/resonance-math/`

### `mathlib5-ffi-bridge/`

- Lean Bridge: `mathlib5-ffi-bridge/Lean/Bridge.lean`
- C Bridge: `mathlib5-ffi-bridge/C/src/bridge.c`

### `mathrosetta_source/`

- Symbolic Proofs: `mathrosetta_source/proofs/`
- Rosetta Stone: `mathrosetta_source/src/`

### `legacy/`

- Earlier APL refutations: `legacy/apl-corrections/`
