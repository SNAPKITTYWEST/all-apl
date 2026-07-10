# ARCHITECTURE

## Verified Symbolic Compute Pipeline (VSCP)

The MATHLIB5 architecture is centered on a verified pipeline that moves from high-level notation to silicon.

### 1. Unified Pipeline

The repo keeps major experiments in separate top-level trees instead of forcing them into one fake canonical module.

- `agentos_source/` carries the widest runtime and orchestration spread
- `mathlib5/` carries the primary VSCP implementation (APL parser, C-- kernel, Lean 4 proofs)
- `mathlib5-ffi-bridge/` carries proof/system bridge work
- `mathrosetta_source/` carries symbolic emission and theorem-targeting work
- `solarium/` carries the semantic knowledge base and MCP server (Qdrant)
- `legacy/` preserves earlier APL and prior-art material

### 2. Documentation Maps

Files under `docs/` such as `INTERCOL.md` are still meaningful, but they describe specific subprojects or prior-art surfaces.
They should not be read as the architecture of the entire repo.

### 3. Core Implementation

`mathlib5/` is the primary Verified Symbolic Compute Pipeline (VSCP) implementation root, containing the APL frontend, S-Expr IR, Lean 4 Core foundation, and the C-- Verified Kernel.

## Swarm Personas (The Collective)

The system is operated and verified by a collective of specialized AI agent personas:

- **CIPHER**: Cryptographic Verification (Ed25519, SHA-256). Ensures all proof witnesses are valid.
- **FORGE**: Code Generation (APL, Fortran, C--). Emits verified kernels and solvers.
- **SENTINEL**: Security & Threat Detection. Monitors the pipeline for anomalies and adversarial inputs.
- **VAULT**: Memory & Persistence. Manages the WORM ledger and skill persistence.
- **ORACLE**: Problem Analysis & Proof Scaffolding. Analyzes complexity (P/NP) and structures theorems.
- **NEXUS**: Swarm Coordination. Orchestrates the pipeline and compiles agent context.
- **SOLARIUM**: Semantic Knowledge Management (MCP/Qdrant). Provides the memory and document retrieval layer for the swarm.

## Documentation Rules

1. **Source-First**: Documentation must map to actual directories and files in the working tree.
2. **Topology-First**: Execution flow must be described based on the `EXECUTION_TOPOLOGY.md`.
3. **Verified-First**: Claims of "solved" or "verified" must point to a specific executable proof or refutation.

## 🔒 Sovereign Pipeline & Plasma Gate
The entire repository is now synchronized with the Sovereign Pipeline. Every core module contains a `metadata.json` file defining its:
- **Identity**: Unique ID (e.g., `MATHLIB5-20260710-AGENTOSF-001`)
- **Classification**: Family ID (1-11, 106) and Corpora Path
- **Security Audit**: Ed25519 Enforcement, AES-256-GCM Encryption, and SHA-256 Tamper Evidence.
- **WORM Status**: All modules are currently `awaiting_worm_seal`.

Verified modules (23/23): `mathlib5`, `agentos_source`, `mathrosetta_source`, `snapkitty-gitbucket`, `snapkitty-shell`, `legacy/apl-corrections`, etc.
