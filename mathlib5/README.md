# MATHLIB5 — Verified Symbolic Compute Pipeline

**The Massive Module: Verified Symbolic Compute from Notation to Silicon**

---

## Overview
MATHLIB5 is a **verified symbolic compute pipeline** that translates APL notation into verified kernels. It provides a compiler-research-grade architecture where APL provides mathematical expression, typed functional languages provide safety guarantees, theorem provers validate transformations, and a low-level backend executes verified kernels.

---

## Key Components
- **APL Front-end**: Parser and type-checker for mathematical notation.
- **Verification Bridge**: Liquid Haskell and Lean 4 integration for formal proofs.
- **Proof Kernel**: Trusted C99/Rust kernels for execution.
- **Symbolic IR**: Canonical S-expression AST.

---

## The Diamond Mine

From SNAPKITTYWEST/mathrosetta and SNAPKITTYWEST/snapkitty-agentos, we cherry-picked:

| Component | Source | Language | What It Does |
|-----------|--------|----------|--------------|
| AXIOM Proof Kernel | axiom-proof | Rust | CIC-dependent type checker, β-reduction, WORM ledger |
| PRISM Skills | prism-skills | Rust | Canonical JSON serialization, SHA-256d hashing, WORM sealing |
| P/NP Attack Coordinator | pnp-attack | Rust | Multi-agent proof search with WORM ledger |
| Collatz Verification Engine | collatz-verification | Rust | Parallel trajectory search with Merkle tree |
| Math Skills (6) | math-skills | Fortran/APL/AXIOM | Enumeration, Isomorphism, Symmetry, Hadamard, Probabilistic, Circuits |
| Math Engine | math-engine | APL/Fortran | P/NP swarm coordinator, TSP solver |
| Policies | policies | Prolog | Pipeline validation, trust deeds |
| Runtime | .agentos | JS/C | GitBucket memory, plasma gate, P/NP verifiers |

---

## Verified Status (2026-07-10)

| Metric | Value |
|--------|-------|
| **Core Architecture** | VSCP (Verified Symbolic Compute Pipeline) |
| **Primary Language** | Haskell / Lean 4 / Rust / C99 |
| **Formal Proofs** | Lean 4 (induction, ring, omega) |
| **Front-end** | APL (Megaparsec) |
| **Status** | **ACTIVE DEVELOPMENT** |
| **Module Scope** | Massive |

---

## Repository Layout (Monorepo)

```
mathlib5/
├── flake.nix             # Nix flake: pinned dependencies
├── WORKSPACE.bazel       # Bazel workspace: multi-language build
├── layers/
│   ├── apl/              # APL Front-end (Haskell)
│   ├── sexpr/            # Symbolic IR (Haskell)
│   ├── liquid/           # Liquid Haskell Refinements
│   ├── hol/              # HOL / Lean 4 Theorem Proving
│   ├── closedform/       # Closed-Form Rewrite Engine
│   ├── backend/          # LLVM/MLIR Backend
│   └── isb/              # Logic-Gate Lowering (Verilog)
├── runtime/              # Verified Kernels (C99/Rust)
├── compiler/             # APL Compiler Frontend (C99)
├── kernel/               # Trusted Proof Kernel (C99)
├── tests/                # Integration & Unit Tests
└── spec/                 # Formal Specifications (BNF)
```

---

## Build System

### Nix Development Shell
```bash
nix develop
```

### Bazel Build
```bash
bazel build //...
bazel test //...
```

### Rust Workspace
```bash
cargo build --release
cargo test
```

---

## Verification Stack (10 Layers)

```
APL Expression
    │
    ▼
┌────────────────────────────────────────────────────────────────┐
│ Layer 1: APL Parser (compiler/lexer/)                          │
│ Tokenizes APL notation into typed IR                           │
└────────────────────────────────────────────────────────────────┘
    │
    ▼
┌────────────────────────────────────────────────────────────────┐
│ Layer 2: AXIOM Proof Kernel (axiom-proof/)                     │
│ CIC type checker, β-reduction, WORM ledger                     │
│ ~400 lines Rust — smallest possible trusted base               │
└────────────────────────────────────────────────────────────────┘
    │
    ▼
┌────────────────────────────────────────────────────────────────┐
│ Layer 3: C99 FOL Checker (fol/)                                │
│ 15/15 classical logic theorems verified                         │
│ ~13ms per proof, zero dependencies                              │
└────────────────────────────────────────────────────────────────┘
    │
    ▼
┌────────────────────────────────────────────────────────────────┐
│ Layer 4: CodeQL Meta-Validator (codeql/)                       │
│ Datalog rules verify proof structure                            │
└────────────────────────────────────────────────────────────────┘
    │
    ▼
┌────────────────────────────────────────────────────────────────┐
│ Layer 5: ASP Stable Models (asp/)                               │
│ Non-monotonic reasoning, answer sets                            │
└────────────────────────────────────────────────────────────────┘
    │
    ▼
┌────────────────────────────────────────────────────────────────┐
│ Layer 6: Prolog Policies (policies/)                           │
│ Solver dispatch, trust, resource budgets                        │
└────────────────────────────────────────────────────────────────┘
    │
    ▼
┌────────────────────────────────────────────────────────────────┐
│ Layer 7: PRISM Skills (prism-skills/)                          │
│ Canonical serialization, WORM sealing                           │
└────────────────────────────────────────────────────────────────┘
    │
    ▼
┌────────────────────────────────────────────────────────────────┐
│ Layer 8: P/NP Swarm (pnp-attack/)                              │
│ Multi-agent proof search, convergence                          │
└────────────────────────────────────────────────────────────────┘
    │
    ▼
┌────────────────────────────────────────────────────────────────┐
│ Layer 9: Receipt Chain (WORM ledger)                           │
│ SHA-256 + Merkle tree, tamper-evident                          │
└────────────────────────────────────────────────────────────────┘
    │
    ▼
┌────────────────────────────────────────────────────────────────┐
│ Layer 10: Automated Sorry Closing (sorryhunter/)               │
│ Symbolic kernel + tactics + FFI + malice + axiom               │
└────────────────────────────────────────────────────────────────┘
```

---

## Trust Model

| Component | Lines | Language | Verification |
|-----------|-------|----------|--------------|
| C99 Kernel | ~500 | C99 | CIC, de Bruijn, arena |
| AXIOM Kernel | ~400 | Rust | Type checker, β-reduction |
| FOL Checker | ~1500 | C99 | 15/15 theorems |
| PRISM Seal | ~300 | Rust | SHA-256d, canonical JSON, WORM |
| WORM Database | ~200 | Rust | Append-only, Merkle tree |
| REXX Interpreter | ~800 | Rust | Stem vars, dynamic indices |
| FOL Checker | ~1500 | C99 | 15/15 theorems |
| CodeQL Rules | ~500 | Datalog | Meta-validation |
| ASP Rules | ~400 | Prolog | Stable models |
| Prolog Policies | ~200 | Prolog | Solver dispatch/trust |
| PRISM Skills | ~300 | Rust | Canonical JSON, WORM seal |
| REXX Interpreter | ~800 | Rust | Stem vars, dynamic indices |
| R Scripts | 4 files | R | Statistical analysis |
| PowerShell | 2 files | PS | Business logic |

**Ed25519**: Plasma gate signing  
**No Python. No Lean 4. Pure Rust + C99 + APL + Fortran + REXX + R + Prolog.**

---

## Receipt Chain (WORM)

```
source.sha256 → binary.sha256 → manifest.json → seal.sha256
```

Every proof is sealed to a WORM ledger with SHA-256 hashing and Merkle tree verification.

---

## Reproducible Builds

```bash
# Full pipeline
cargo build --release
cargo test
cd layers/fol/src && gcc -O3 -o fol_check fol_resolution_checker.c && ./fol_check
./target/release/sorryhunter dashboard
./target/release/rexx-interp layers/scripting/rexx/classify_proof.rexx
Rscript layers/scripting/r/convergence.R
```

---

## APL Surface Syntax

See [`spec/MATHLIB5.bnf`](spec/MATHLIB5.bnf) for the complete EBNF grammar.

Key features:
- **Inductive types, structures, classes, instances**
- **Dependent types (Π, Σ), refinement types**
- **Tensor/Matrix/Quantum types with shape specs**
- **Σ/Π/∫ expressions, set comprehensions**
- **Kernel pragmas** (target, vectorize, verify, layout, precision)
- **Theorem/proof with tactic language**
- **Module system** (import, namespace, open)

---

## License

Apache 2.0

---

**Author:** Ahmad Ali Parr — SNAPKITTYWEST  
*"The map is not the territory. The proof is the territory."*