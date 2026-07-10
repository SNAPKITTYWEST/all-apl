# MATHLIB5
**The Unified Symbolic Compute Stack**

> **Notice:** This repository has been consolidated to focus on **MATHLIB5**, a compiler-research-grade verified symbolic compute pipeline. The legacy components are now subordinated to this unified architecture.

## The Massive Module: `mathlib5/`
The core of this repository is the `mathlib5` module. It is a comprehensive symbolic mathematics engine where:
- **APL** provides mathematical expression and concise notation.
- **Typed functional languages** (Haskell) provide safety guarantees.
- **Theorem provers** (Lean 4) validate transformations and proofs.
- **Low-level backends** (C99/Rust/LLVM) execute verified kernels.

This architecture ensures a **verified symbolic compute pipeline** from notation to silicon.

---

## Architecture at a Glance
MATHLIB5 employs a **Verified Symbolic Compute Pipeline** (VSCP):

1. **Notation**: Concise APL code (e.g., `SumSquares ← { (+/ (⍳⍵) * 2) }`).
2. **Refinement**: Liquid Haskell ensures type safety and generates proof obligations.
3. **Formal Proof**: Lean 4 proves mathematical equivalence (e.g., $\sum k^2 = \frac{n(n+1)(2n+1)}{6}$).
4. **Lowering**: Verified transformation to closed-form expressions.
5. **Execution**: Compilation to machine code via a trusted proof kernel.

For a deep dive into the architecture, see [mathlib5/README.md](mathlib5/README.md).

---

## Legacy Context (all-apl)
This project originated as a compact APL refutation of specific proof defects observed in public multiplicity theory implementations. These corrections (Stability, Proof Hashes, Factorization, Domain Boundaries) have been integrated as verification checkpoints within the MATHLIB5 pipeline.

---

## Getting Started
### Prerequisites
- **Nix** (with Flakes enabled)
- **Bazel**
- **Rust** (Stable)
- **Haskell** (GHC 9.8.2)

### Build & Test
```bash
cd mathlib5
nix develop
bazel build //...
bazel test //...
```

---

**Author:** Ahmad Ali Parr · SnapKitty Collective · 2026
**WORM Seal:** `eadec100f43df0659666114fcd509f3ddc2a8d9f2ea7dd3c5eb922af4a0336f5`

## Project Legacy Components
These corrections (originally part of the `all-apl` project) are now integrated as verification checkpoints:

### 1. Stability
Correct condition: `ρ(T) < 1`. Diagonal gains: `IsContractive gains = max |gains| < 1`.

### 2. Proof Hash
Structural validation of SHA-256 digest shape (64 hexadecimal characters). Rejects placeholder labels.

### 3. Factorization
Computes real prime-factor witnesses. Checks: all factors are prime, sorted, and product equals $n$.

### 4. Domain Boundary
Encodes boundaries as `name lower upper omega cap` and validates via `WithinDomain`.

### 5. Omega Isolation
Correct isolation: `ω < Ω`. Uses resonance entropy gate: `ε < 0.21`.

### 6. Morphism Composition
Correct order: `(f∘g)(x) = f(g(x))`.

---

## Running Legacy APL
Load the APL files in the `legacy/apl-corrections/` directory in a Dyalog-compatible session:
```apl
]LOAD legacy/apl-corrections/pirtm_stability.apl
]LOAD legacy/apl-corrections/sovereign_domain.apl
]LOAD legacy/apl-corrections/omega_isolation.apl
]LOAD legacy/apl-corrections/zeroproof_substrate.apl
]LOAD legacy/apl-corrections/morphism_composition.apl
]LOAD legacy/apl-corrections/run_all.apl
RunAll ⍬
```
