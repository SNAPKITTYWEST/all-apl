# MATHLIB5 — Verified Symbolic Compute Stack

A symbolic mathematics engine where APL provides mathematical expression, typed functional languages provide safety guarantees, theorem provers validate transformations, and a low-level backend executes verified kernels.

## Repository Layout (Monorepo, Nix + Bazel)

```
mathlib5/
├── flake.nix # Nix flake: pinned nixpkgs, haskell.nix, lean4, apl, llvm, z3, cvc5
├── WORKSPACE.bazel # Bazel workspace: rules_haskell, rules_rust, rules_lean, rules_apl, rules_llvm
├── BUILD.bazel # Top-level targets
├── layers/
│ ├── apl/ # APL front-end (parser, type-checker, array IR)
│ ├── sexpr/ # S-expression IR (canonical symbolic AST)
│ ├── liquid/ # Liquid Haskell refinement-type layer
│ ├── isb/ # ISB / logic-gate lowering (Verilog/Chisel emit)
│ ├── closedform/ # Non-recursive summation / closed-form engine
│ ├── tex/ # TeX pretty-printer + doc generator
│ ├── hol/ # HOL / Lean 4 theorem-prover bridge
│ └── backend/ # FFI + LLVM/MLIR verified backend
├── runtime/
│ ├── ffi/ # C/FFI shim (verified via CompCert subset)
│ └── kernels/ # Pre-verified kernels (BLAS, FFT, etc.)
├── tests/
│ ├── unit/ # Per-layer property tests (QuickCheck, Lean)
│ ├── integration/ # End-to-end: APL → TeX → Lean → LLVM → exec
│ └── benchmarks/ # Performance vs. NumPy/Julia/Lean
├── docs/
│ └── spec.md # Living spec (this file, rendered via TeX layer)
└── ci/
    ├── github-actions.yml
    └── benchmark.yml
```

## Key Verification Checkpoints (Gate Criteria)

| Gate | Tool | Artifact | Pass Condition |
|------|------|----------|----------------|
| **Parsing** | APL parser | `.sexpr` | Round-trip: `parse ∘ print = id` |
| **Refinement** | Liquid Haskell | Proof obligations | All `Safe` / `Proved` |
| **Theorem Proving** | Lean 4 | `mathlib5_core` | `sorry`-free, `decide` closes goals |
| **Closed-Form** | SBV + Lean lemmas | `.closed.sexpr` | Equivalence proved vs. recursive spec |
| **Synthesis** | Yosys/nextpnr | Netlist | Timing closure @ target Fmax |
| **Execution** | LLVM + CompCert FFI | Binary | Output matches reference (exact arithmetic) |
| **Documentation** | TeX layer | `spec.pdf` | Renders without warnings |
