# MATHLIB5 — Verified Symbolic Compute Pipeline (VSCP)

**The Unified Symbolic Compute Stack**

> **Notice:** The active code in this repository is distributed across the root modules and preserved source trees such as `agentos_source/`, `mathlib5-ffi-bridge/`, and `mathrosetta_source/`. The `mathlib5/` subdirectory is not currently the live implementation surface.

## Architecture at a Glance
MATHLIB5 employs a **Verified Symbolic Compute Pipeline** (VSCP):

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                              MATHLIB5 VSCP — FULL STACK                                 │
├─────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                         │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌────────────────────────┐   │
│  │    APL      │───▶│  S-Expr IR  │───▶│   Liquid    │───▶│      Lean 4            │   │
│  │  Frontend   │    │   (S-Expr)  │    │   Haskell   │    │   Theorems             │   │
│  │  (Megaparsec)│   │  Canonical  │    │  Refinement │    │  (No Sorries)          │   │
│  └─────────────┘    └─────────────┘    └─────────────┘    └───────────┬────────────┘   │
│                                                                         │                │
│                                                                         ▼                │
│  ┌─────────────────────────────────────────────────────────────────────────────────┐    │
│  │                         C-- KERNEL LAYER                                        │    │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────────────┐   │    │
│  │  │   C--    │─▶│  LLVM    │─▶│  MLIR    │─▶│   PTX    │  │  SPIR-V /      │   │    │
│  │  │  Kernel  │  │    IR    │  │ Dialect  │  │  (NVIDIA)│  │  Verilog /     │   │    │
│  │  │  (C--)   │  │          │  │          │  │          │  │  Chisel (FPGA) │   │    │
│  │  └──────────┘  └──────────┘  └──────────┘  └──────────┘  └────────────────┘   │    │
│  └─────────────────────────────────────────────────────────────────────────────────┘    │
│                                                                         │                │
│                                                                         ▼                │
│  ┌─────────────────────────────────────────────────────────────────────────────────┐    │
│  │                    VERIFICATION BACKBONE                                        │    │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌────────────────────┐   │    │
│  │  │  CodeQL/     │  │    ASP       │  │  Prolog      │  │  PRISM Skills      │   │    │
│  │  │  Datalog     │  │  (Clingo)    │  │  Policies    │  │  (Canonical JSON,  │   │    │
│  │  │  Meta-Val    │  │  Stable      │  │  (Solver     │  │   WORM Sealing)    │   │    │
│  │  │              │  │  Models      │  │   Dispatch)  │  │                    │   │    │
│  │  └──────────────┘  └──────────────┘  └──────────────┘  └────────────────────┘   │    │
│  └─────────────────────────────────────────────────────────────────────────────────┘    │
│                                                                         │                │
│                                                                         ▼                │
│  ┌─────────────────────────────────────────────────────────────────────────────────┐    │
│  │                    HARDWARE LOWERING                                            │    │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────────────┐   │    │
│  │  │  Clash   │  │  Verilog │  │  Chisel  │  │  PTX     │  │  SPIR-V        │   │    │
│  │  │ (Haskell │  │  (FPGA/  │  │  (Scala) │  │  (NVIDIA)│  │  (Vulkan/      │   │    │
│  │  │  → HDL)  │  │  ASIC)   │  │  (FPGA)  │  │  (GPU)   │  │  Compute)      │   │    │
│  │  └──────────┘  └──────────┘  └──────────┘  └──────────┘  └────────────────┘   │    │
│  └─────────────────────────────────────────────────────────────────────────────────┘    │
│                                                                         │                │
│                                                                         ▼                │
│  ┌─────────────────────────────────────────────────────────────────────────────────┐    │
│  │                    WORM RECEIPT CHAIN                                           │    │
│  │  source.sha256 → binary.sha256 → manifest.json → seal.sha256 (Merkle)          │    │
│  └─────────────────────────────────────────────────────────────────────────────────┘    │
│                                                                                         │
└─────────────────────────────────────────────────────────────────────────────────────────┘
```

1. **Notation**: Concise APL code (e.g., `SumSquares ← { (+/ (⍳⍵) * 2) }`).
2. **Refinement**: Liquid Haskell ensures type safety and generates proof obligations.
3. **Formal Proof**: Lean 4 proves mathematical equivalence (e.g., $\sum k^2 = \frac{n(n+1)(2n+1)}{6}$). [**Collatz.lean**](agentos_source/collatz-verification/proofs/Collatz.lean).
4. **Lowering**: Verified transformation to closed-form expressions. [**verified_kernel.cm**](mathlib5/kernel/verified_kernel.cm).
5. **Execution**: Compilation to machine code via a trusted proof kernel. [**Bridge.lean**](mathlib5-ffi-bridge/Lean/Bridge.lean).

For a source-based map of what is actually present, see [**EXECUTION_TOPOLOGY.md**](EXECUTION_TOPOLOGY.md) and [**CORE_EXPERIMENT_MAP.md**](CORE_EXPERIMENT_MAP.md).
For theorem/proof status across the repo, see [**THEOREM_STATUS.md**](THEOREM_STATUS.md).

---

## Repository Structure (Current)
- **mathlib5/**: The primary symbolic compute stack (includes APL front-end and C-- kernel).
- **agentos_source/**: largest active preserved implementation tree (APL, Rust, Lean, Fortran).
- **mathlib5-ffi-bridge/**: Lean/C bridge work.
- **mathrosetta_source/**: symbolic math/proof emitter tree.
- **solarium/**: Semantic knowledge base and MCP server (Qdrant).
- **legacy/**: earlier APL corrections and refutations.
- **snapkitty-shell/**: sovereign shell/runtime support.

---

## 🔧 Quick Start
### Prerequisites
- **Nix** (with Flakes enabled)
- **Bazel**, **Rust**, **Haskell** (GHC 9.8.2)

### Build & Test
```bash
# inspect the real module map first
open EXECUTION_TOPOLOGY.md

# then enter the module you actually want to build
cd agentos_source
```

---

**Author:** Ahmad Ali Parr · SnapKitty Collective · 2026
**WORM Seal:** `eadec100f43df0659666114fcd509f3ddc2a8d9f2ea7dd3c5eb922af4a0336f5`
