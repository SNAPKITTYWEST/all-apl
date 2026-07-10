# MATHLIB5 — Verified Symbolic Compute Pipeline

**The Final Architecture: APL → Rust Kernel → C99 FOL Checker → CodeQL Meta-Validator → ASP Stable Models**

**Author: Ahmad Ali Parr**

## What This Is

MATHLIB5 is a **verified symbolic compute pipeline** that translates APL notation into verified kernels. It uses ASP/Prolog/C as the verification backbone, C99 for FOL resolution checking, CodeQL (Datalog) for meta-validation, and Rust for the proof kernel and all core components. Zero Python.

## The Diamond Mine

From SNAPKITTYWEST/mathrosetta and SNAPKITTYWEST/snapkitty-agentos, we cherry-picked:

| Component | Source | Language | What It Does |
|-----------|--------|----------|--------------|
| AXIOM Proof Kernel | axiom-proof | Rust | CIC-dependent type checker, beta reduction, WORM ledger |
| PRISM Skills | prism-skills | Rust | Canonical JSON serialization, SHA-256d hashing, WORM sealing |
| P/NP Attack Coordinator | pnp-attack | Rust | Multi-agent proof search with WORM ledger |
| Collatz Verification Engine | collatz-verification | Rust | Parallel trajectory search with Merkle tree |
| Math Skills (6) | math-skills | Fortran/APL/AXIOM | Enumeration, Isomorphism, Symmetry, Hadamard, Probabilistic, Circuits |
| Math Engine | math-engine | APL/Fortran | P/NP swarm coordinator, TSP solver |
| Policies | policies | Prolog | Pipeline validation, trust deeds |
| Runtime | .agentos | JS/C | GitBucket memory, plasma gate, P/NP verifiers |

## Directory Structure

```
mathlib5/
├── Cargo.toml                    # Rust workspace (4 crates)
├── kernel/
│   ├── kernel.h                  # Trusted proof kernel (C99)
│   └── kernel.c                  # CIC, de Bruijn, arena, type checking
├── compiler/
│   └── lexer/
│       ├── lexer.h               # Token definitions
│       └── lexer.c               # Tokenizer
├── layers/
│   ├── axiom-proof/              # AXIOM Proof Assistant (Rust)
│   │   ├── src/kernel/checker.rs # CIC type checker, beta reduction
│   │   ├── src/kernel/worm.rs    # WORM proof database, Merkle tree
│   │   ├── src/syntax/parser.rs  # .axiom file parser
│   │   └── Cargo.toml
│   ├── prism-skills/             # PRISM Canonical Skills (Rust)
│   │   ├── src/canonical.rs      # Deterministic JSON serialization
│   │   ├── src/seal.rs           # WORM seal generation/verification
│   │   ├── src/sha256d.rs        # Double SHA-256 hashing
│   │   ├── src/psi_pipeline.rs   # Algebraic topology pipeline
│   │   ├── src/admission.rs      # Fail-closed validation
│   │   └── Cargo.toml
│   ├── pnp-attack/               # P vs NP Proof Search (Rust)
│   │   ├── src/coordinator.rs    # Multi-agent coordinator, WORM ledger
│   │   └── Cargo.toml
│   ├── collatz/                  # Collatz Verification (Rust)
│   │   ├── engine/src/lib.rs     # Parallel trajectory search
│   │   └── engine/Cargo.toml
│   ├── math-skills/              # Mathematical Skills (6)
│   │   ├── skill1-enumeration/   # Combinatorial enumeration
│   │   ├── skill2-isomorphism/   # Graph isomorphism detection
│   │   ├── skill3-symmetry/      # Symmetry breaking
│   │   ├── skill4-hadamard/      # Hadamard matrix construction
│   │   ├── skill5-probabilistic/ # Probabilistic method
│   │   └── skill6-circuits/      # Circuit complexity
│   ├── engine/                   # Math Engine
│   │   ├── apl/pnp_swarm.apl    # APL swarm coordinator
│   │   └── fortran/pnp_solver.f90 # TSP solver
│   ├── fol/                      # FOL Resolution Checker (C99)
│   │   └── src/fol_resolution_checker.c
│   ├── asp/                      # ASP stable model gate
│   ├── codeql/                   # CodeQL meta-validation
│   ├── millennium/               # 7 Clay problems
│   └── ir/                       # Typed IR
├── interop/
│   ├── smt_export/               # Z3/cvc5 export
│   └── lean_import/              # Lean 4 import
├── meta_oracle_engine/           # Boolean verification oracle
├── malice_layer2/                # Adversarial refutation layer
├── policies/
│   ├── pipeline_policy.pl        # Pipeline validation
│   ├── trust_deed.pl             # Trust delegation
│   ├── solver_policy.pl          # Solver selection rules
│   ├── trust_policy.pl           # Proof requirements
│   └── resource_policy.pl        # Resource budgets
├── runtime/                      # AgentOS runtime
│   ├── gitbucket/                # Memory buckets
│   ├── plasma_gate/              # Ed25519 signing
│   ├── pnp/                      # P/NP verifiers
│   └── runtime/                  # Core runtime
├── sorrydb/                      # 392 known sorrys
├── test/                         # Test suite
├── benchmarks/                   # Performance benchmarks
├── docs/
│   ├── guides/                   # 6 user guides
│   ├── adr/                      # Architecture decision records
│   └── rfc/                      # Request for comments
├── examples/
│   └── playground/               # KaTeX/MathQuill frontend
└── symbolic/
    ├── solver_policy.pl
    ├── trust_policy.pl
    └── resource_policy.pl
```

## Build

### Rust Workspace
```bash
cargo build --release
cargo test
```

### FOL Checker (C99)
```bash
cd layers/fol/src
gcc -O3 -o fol_check fol_resolution_checker.c
./fol_check
```

### Kernel (C99)
```bash
cd kernel
gcc -O3 -o kernel kernel.c
```

## Verification Stack

```
APL Expression
    │
    ▼
┌─────────────────────────────────────────────────────────┐
│  Layer 0: APL Parser (compiler/lexer/)                  │
│  Tokenizes APL notation into IR                         │
└─────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────┐
│  Layer 1: AXIOM Proof Kernel (axiom-proof/)             │
│  CIC type checker, beta reduction, WORM ledger          │
│  ~500 lines Rust — smallest possible trusted base       │
└─────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────┐
│  Layer 2: C99 FOL Checker (fol/)                        │
│  15/15 classical logic theorems verified                 │
│  ~13ms per proof, zero dependencies                     │
└─────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────┐
│  Layer 3: CodeQL Meta-Validator (codeql/)               │
│  Datalog rules verify proof structure                   │
└─────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────┐
│  Layer 4: ASP Stable Models (asp/)                      │
│  Non-monotonic reasoning, answer sets                   │
└─────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────┐
│  Layer 5: Prolog Policies (policies/)                   │
│  Solver dispatch, trust, resource budgets               │
└─────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────┐
│  Layer 6: PRISM Skills (prism-skills/)                  │
│  Canonical serialization, WORM sealing                  │
└─────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────┐
│  Layer 7: P/NP Swarm (pnp-attack/)                      │
│  Multi-agent proof search, convergence                  │
└─────────────────────────────────────────────────────────┘
```

## Trust Model

- **Kernel**: ~500 lines C99 (CIC, de Bruijn, arena)
- **AXIOM Kernel**: ~400 lines Rust (type checker, beta reduction)
- **FOL Checker**: ~1500 lines C99 (15/15 verified)
- **PRISM Seal**: SHA-256d, canonical JSON, WORM ledger
- **WORM Database**: Append-only, Merkle tree, tamper-evident
- **Ed25519**: Plasma gate signing
- **No Python. No Lean 4. Pure Rust + C99 + APL + Fortran + Prolog.**

## Receipt Chain

```
source.sha256 → binary.sha256 → manifest.json → seal.sha256
```

Every proof is sealed to a WORM ledger with SHA-256 hashing and Merkle tree verification.

## License

Apache 2.0
