# INTERCOL UI — System Architecture

**Author:** Ahmad Ali Parr · SnapKitty Collective · 2026

---

## Stack Overview

```mermaid
graph TD
    APL[APL Transform Layer\nsrc/*.apl] -->|symbolic math| STATE[State Model\nstate-model.json]
    LUA[Lua Agent Scripts\nagents/*.lua] -->|behavior events| STATE
    STATE -->|data bridge| CPP[C++ Simulation Core\nruntime/]
    CPP -->|render data| SWIFT[Swift Spatial UI\nui/]

    subgraph APL_LAYER[APL Layer — Pure Math]
        INTERCOL[intercol.apl\nOrthogonality proof]
        PIRTM[pirtm_stability.apl\nContraction proof]
        DOMAIN[sovereign_domain.apl\nBoundary encoding]
        TRANSFORMS[transforms.apl\nFib · Entropy · Trust · Resonance]
    end

    subgraph SWIFT_MODULES[Swift UI Modules]
        M1[Control Panel]
        M2[Sacred Geometry Viewer\n13-node Metatron]
        M3[WORM Seal VM]
        M4[Falsifiable Assurance]
        M5[Context Shedding]
        M6[EDAULC Trust Radar]
        M7[Lua Console]
        M8[APL Transform Console]
        M9[Resonance Timeline]
        M10[Demo Mode]
    end

    APL_LAYER --> APL
    SWIFT_MODULES --> SWIFT
```

---

## Data Flow

```mermaid
sequenceDiagram
    participant LUA as Lua Agent
    participant APL as APL Layer
    participant STATE as State Model
    participant CPP as C++ Core
    participant SWIFT as Swift UI

    LUA->>STATE: agent_join event
    APL->>STATE: INTERCOL(D_i, D_j) result
    STATE->>CPP: trust_vector update
    CPP->>CPP: ERE 5-pass scoring
    CPP->>CPP: entropy_gate check (< 0.21)
    CPP->>CPP: METATRON certification
    CPP->>STATE: WORM receipt append
    STATE->>SWIFT: render update
    SWIFT->>SWIFT: animate 13-node graph
```

---

## WORM Receipt Flow

```mermaid
flowchart LR
    A[Agent Action] --> B[ERE 5 Passes]
    B --> C{Entropy < 0.21?}
    C -->|NO| D[⊥ Null State\nno receipt]
    C -->|YES| E[METATRON\nCertification]
    E --> F[SHA-256\nstate_hash]
    F --> G[WORM Seal\n16-char hex]
    G --> H[Append-Only\nReceipt Log]
    H --> I[UI: verify / replay\nNO delete]
```

---

## EDAULC Trust Vector (7-axis)

```mermaid
radar
    title EDAULC Trust Axes
    "coherence" : 0
    "provenance" : 0
    "reversibility" : 0
    "consent" : 0
    "auditability" : 0
    "semantic_alignment" : 0
    "contradiction_resistance" : 0
```

Each axis: `0.0–1.0`. Not boolean. Trust is a vector, not a flag.

---

## INTERCOL Domain Space

```mermaid
graph LR
    T[TREASURY\nD_1 = 1 0 0 0]
    C[CLINICAL\nD_2 = 0 1 0 0]
    L[LEGAL\nD_3 = 0 0 1 0]
    O[OPERATIONS\nD_4 = 0 0 0 1]

    T -.->|INTERCOL = 0\n⊥ Null State| C
    T -.->|INTERCOL = 0\n⊥ Null State| L
    T -.->|INTERCOL = 0\n⊥ Null State| O
    T -->|INTERCOL = 1\nOK| T
```

Cross-domain transitions are **undefined**, not rejected.  
The state machine has no rule for these edges.

---

## METATRON 13-Node Topology

```mermaid
graph TB
    QS[QUANTUM_SRC\ndepth 0.5]
    SRC[SOURCE\ndepth 0]
    RET[RETRIEVAL\ndepth 1]
    FIL[FILTERING\ndepth 2]
    L4[LEAN4_GATE\ndepth 2.5]
    ADA[ADA_CONTRACT\ndepth 2.5]
    RNK[RANKING\ndepth 3]
    WRM[WORM_SEAL\ndepth 3.5]
    PRO[PROLOG_KERN\ndepth 3.5]
    ASM[ASSEMBLY\ndepth 4]
    MET[METATRON ★\ndepth 5]
    REA[REASONING\ndepth 5]
    MAG[MAGMACORE\ndepth 6]

    QS -->|constraint| SRC
    SRC --> RET --> FIL --> RNK --> ASM --> MET --> REA --> MAG
    L4 -->|constraint| FIL
    ADA -->|constraint| FIL
    WRM -->|constraint| RNK
    PRO -->|constraint| RNK
    MAG -.->|backward| MET
    MET -.->|backward| SRC
```

METATRON reads ALL nodes forward AND backward.  
The intersection of both views is the cage.

---

## File Map

| File | Purpose | Used by |
|---|---|---|
| `src/intercol.apl` | Domain orthogonality proofs | APL Console (M8), Demo (M10) |
| `src/pirtm_stability.apl` | PIRTM contradiction proof | APL Console (M8) |
| `src/sovereign_domain.apl` | Domain boundary encoding | Domain model, C++ core |
| `src/transforms.apl` | Fib · Entropy · Trust · Resonance | APL Console (M8), Demo (M10) |
| `src/state-model.json` | Full UI state schema | C++ core, Swift UI, Lua |
| `docs/INTERCOL.md` | Formal specification | README, LinkedIn post |
| `docs/resonance.html` | Resonance Machine visualizer | GitHub Pages |
| `ARCHITECTURE.md` | This file | Codex, team |

---

*Ahmad Ali Parr · SnapKitty Collective · 2026*
