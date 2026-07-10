# MATHLIB5 Handoff Document

## Project Overview
**MATHLIB5** is a compiler-research-grade verified symbolic compute pipeline. It translates APL notation into verified kernels, using Liquid Haskell for refinement types and Lean 4 for theorem proving.

## Current Status (Phase 1 Complete)
Phase 1 established the foundation of the pipeline, focusing on the path from APL source to formal proof obligations.

### Implemented Layers
1.  **APL Front-end (`layers/apl`)**:
    - Functional parser using `Megaparsec`.
    - Supports primitives (`⍳`, `+/`, `*`), floating-point numbers, and lambda abstractions `{...}`.
    - Targets the S-expression IR.
2.  **S-expression IR (`layers/sexpr`)**:
    - Canonical AST defined in Haskell (`AST.hs`).
    - Support for Atoms, Lists, Numbers, and Strings.
    - Derived JSON and Hashable instances.
    - Placeholder normalization utility in `Main.hs`.
3.  **Liquid Haskell / Bridge (`layers/liquid`)**:
    - Literate Haskell refinements (`Refinements.lhs`).
    - Bridge logic (`Bridge.hs`) that extracts Lean 4 proof obligations from APL S-expressions (specifically targeting the `SumSquares` pattern).
4.  **HOL / Lean 4 Bridge (`layers/hol`)**:
    - Core theorem `sum_squares_formula` implemented in Lean 4 (`Core.lean`).
    - Successfully proves $\sum_{k=0}^{n-1} (k+1)^2 = \frac{n(n+1)(2n+1)}{6}$ using induction and `ring` tactics.

### Key Files
- `mathlib5/layers/apl/src/Parser.hs`: APL parser logic.
- `mathlib5/layers/sexpr/src/AST.hs`: IR definition.
- `mathlib5/layers/liquid/src/Bridge.hs`: Logic to generate `.lean` files from AST.
- `mathlib5/layers/hol/lean/Mathlib5/Core.lean`: Formal verification of the "Hello World" example.
- `mathlib5/tests/integration/test_programs/simple_sum.apl`: The target APL program.

## Next Steps (Phase 2)
The next agent should focus on the transformation and execution layers:

1.  **Closed-Form Engine (`layers/closedform`)**:
    - Implement the logic to rewrite recursive APL patterns into the closed-form expressions proved in Lean.
    - Use the bridge to verify that the rewrite is valid.
2.  **ISB / Logic-Gate Lowering (`layers/isb`)**:
    - Start implementing the lowering of S-expressions to hardware descriptions (Verilog/Chisel).
3.  **Backend (`layers/backend`)**:
    - Begin the LLVM/MLIR emission for verified kernels.
4.  **Integration Pipeline**:
    - Finalize `run_e2e.sh` to fully automate the flow from `.apl` to `.exe`.

## Environment Requirements
- **Nix**: Use `flake.nix` to enter the development shell (`nix develop`).
- **Bazel**: Use `bazel build //...` and `bazel test //...` for building and testing.
- **Haskell**: GHC 9.8.2 (via Nix).
- **Lean 4**: Pinned via Nix flake.

## Verification Checkpoints
- Ensure the parser handles the `SumSquares` pattern: `{ (+/ (⍳⍵) * 2) }`.
- Verify that `lh_to_lean_bridge` generates a valid Lean theorem matching `sum_squares_formula`.
- Proofs in `layers/hol` must remain `sorry`-free.
