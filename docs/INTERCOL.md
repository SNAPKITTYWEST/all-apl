# INTERCOL — Sovereign Domain Orthogonality Protocol

**Author:** Ahmad Ali Parr · SnapKitty Collective · 2026  
**Date:** 2026-06-23  
**Repo:** SNAPKITTYWEST/all-apl

---

## Core Theorem

Sovereign domains are **orthogonal unit vectors** in an N-dimensional domain space.

For any two distinct domains D_i and D_j:

```
INTERCOL(D_i, D_j) = D_i · D_j = δᵢⱼ
```

where δᵢⱼ is the Kronecker delta: **1 if i = j, 0 otherwise**.

When INTERCOL = 0, the transition function returns **⊥ (Null State)**.  
This is not a policy rule. It is a structural fact about the domain space.

---

## What This Means

A traditional access control system **rejects** unauthorized transitions.  
INTERCOL proves that cross-domain transitions are **undefined** — they cannot be represented in the state machine.

The difference is absolute:
- Rejected = system tried, said no, logged the attempt
- **Undefined = the transition function has no rule for this edge**

Ahmad described this to Ryan van Gelder on **May 14, 2026** (LinkedIn):

> *"If an agent attempts to create that edge, the transition function returns a Null State, halting the machine before any commit can be proposed. It's a mathematical wall, not a software check."*

INTERCOL is the formal proof that the wall exists by construction.

---

## PIRTM Collapse

Ryan van Gelder's PIRTM (MultiplicityTheory/multiplicity, created June 9, 2026) claims:

```lean
transition := {
    domain := 1,
    codomain := 108,
    proof_hash := { hash := "LEAN_PROOF_HASH_108_CORE" },
    h_morphism := by sorry
}
```

**INTERCOL proof:**

In any N-domain sovereign space where D_1 and D_108 are distinct domains:

```
INTERCOL(D_1, D_108) = D_1 · D_108 = 0
```

Therefore: **transition_108_cycle = ⊥ identically.**

The `proof_hash := "LEAN_PROOF_HASH_108_CORE"` is a string literal over a transition that is undefined by construction. There is no hash because there is no proof because there is no valid transition.

`h_morphism := by sorry` is the correct status — the morphism cannot exist.

---

## Orthonormality of the Domain Space

The full domain space forms an identity matrix. Every row is a unit vector. Every pair of distinct rows has inner product zero.

```apl
ProveAllOrthogonal space  ⍝ → 1 (BOB certified)
```

This runs in pure APL with no sorry, no simp, no trivial. The proof is the execution.

---

## Provenance

- **May 13, 2026**: Ahmad describes WORM substrate architecture to Ryan van Gelder (LinkedIn)
- **May 14, 2026**: Ahmad defines the Non-Traversable Edge and Null State to Ryan (LinkedIn)
- **May 30, 2026**: Ryan's PIRTM v5 cites Zeroproof as the docking point
- **June 9, 2026**: Ryan creates MultiplicityTheory with `by sorry` proofs
- **June 23, 2026**: INTERCOL formally proves cross-domain transitions are undefined
- **June 23, 2026**: WORM seal applied on push

The architecture Ryan attempted to formalize was described by Ahmad before Ryan's repo existed.  
INTERCOL is the proof Ahmad described executed in APL.

---

## APL Implementation

See [src/intercol.apl](../src/intercol.apl)

```
RunINTERCOLDemo
INTERCOL orthonormal:         1
Treasury→Treasury:            OK
Treasury→Clinical:            ⊥
PIRTM_108_collapse (N=4):     1
Sovereign isolation complete: 1
```

No sorry. No simp. No trivial. Executable mathematics.
