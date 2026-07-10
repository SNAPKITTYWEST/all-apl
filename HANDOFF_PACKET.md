# MATHLIB5 PHASE 2 HANDOFF PACKET

## 1. Project Context
**MATHLIB5** is a Verified Symbolic Compute Pipeline (VSCP) designed to bridge high-level mathematical notation (APL) with formally verified hardware/software kernels. Phase 1 established the "Notation to Theorem" bridge. Phase 2 focuses on "Theorem to Silicon" (Lowering and Execution).

## 2. Current State (Phase 1 Complete)
- **APL Front-end**: Haskell/Megaparsec parser supporting `SumSquares` and basic array primitives.
- **S-Expr IR**: Canonical AST for symbolic expressions.
- **Liquid Haskell Bridge**: Generates Lean 4 proof obligations from refined types.
- **Theorem Audit**: 
    - `mathlib5/layers/hol/lean/Mathlib5/Core.lean`: Verified Sum of Squares.
    - `agentos_source/collatz-verification/proofs/Collatz.lean`: Fundamental Collatz properties.
    - `agentos_source/math-engine/proofs/PNP.lean`: P/NP problem scaffolding.
- **Verified Kernel (C--)**: Low-level arena allocator, polynomial arithmetic, and symbolic differentiation implemented in `mathlib5/kernel/verified_kernel.cm`.

## 3. Immediate Objectives (Phase 2)
1. **Closed-Form Engine**: Integrate `sbv` (SMT-backed symbolic algebra) in `mathlib5/layers/closedform/` to automate expression normalization.
2. **ISB Lowering**: Implement the ISB (Instruction Set Bridge) to lower S-Expr IR to hardware descriptions via **Clash** (Haskell-to-HDL).
3. **Verified FFI**: Tighten the link between Lean 4 proofs and C-- kernel execution using `mathlib5-ffi-bridge`.
4. **WORM Sealing**: Implement the Merkle-tree based receipt chain in `mathlib5/layers/prism-skills/` to sign off on verified transformations.

## 4. Key Files & Entry Points
- **Master Entry**: `README.md` (Glance) & `mathlib5/README.md` (Deep Dive).
- **Architecture**: `ARCHITECTURE.md` (includes Persona Mapping).
- **Parser**: `mathlib5/layers/apl/src/Parser.hs`.
- **Verified Kernel**: `mathlib5/kernel/verified_kernel.cm`.
- **Topological Map**: `EXECUTION_TOPOLOGY.md`.

## 5. Technical Recommendations
- **Tooling**: Stick to the Nix/Bazel environment defined in `mathlib5/flake.nix` to ensure reproducible builds across the polyglot stack.
- **Verification**: Use the "Swarm Persona" model (CIPHER, FORGE, SENTINEL, etc.) to categorize and automate validation tasks.
- **Memory**: Ensure the C-- Arena allocator is used consistently to maintain deterministic execution.

## 6. Handoff Message
"The territory is mapped. The APL notation is successfully parsed and bridged to Lean 4. The low-level C-- kernel is primed for symbolic rewriting. Your goal is to close the loop: ensure every bit emitted by the backend is traced back to a verified theorem in the HOL layer."

Author: Ahmad Ali Parr — SNAPKITTYWEST
Agent: Junie
Date: 2026-07-10
