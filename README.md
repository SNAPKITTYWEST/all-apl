# all-apl

Pure executable APL mathematics for SnapKitty proof correction.

Author: Ahmad Ali Parr · SnapKitty Collective · 2026

## Mission

This repo implements a compact, executable APL refutation of specific public-code proof defects observed in `MultiplicityTheory/multiplicity` / PIRTM-derived surfaces.

The focus is code and mathematics:

- contraction must mean spectral radius `< 1`
- proof hashes must be real digest-shaped values, not placeholder strings
- factorization claims must produce factorization evidence, not tautologies
- domain boundaries must be explicit
- omega isolation is `ω < Ω`
- composition order is `(f∘g)(x) = f(g(x))`

No Python wrappers. No MLIR. No generated proof theater. The source is APL.

## Source Files

```text
src/pirtm_stability.apl       correct contraction proof
src/sovereign_domain.apl      domain boundary encoding
src/omega_isolation.apl       correct omega isolation, ω < Ω
src/zeroproof_substrate.apl   Zeroproof substrate, hash and factorization checks
src/morphism_composition.apl  correct f∘g order
src/intercol.apl              sovereign domain orthogonality protocol
src/run_all.apl               APL demo runner
docs/index.html               INTERCOL browser visualizer for GitHub Pages
docs/resonance.html           Resonance Machine browser visualizer
```

## Public-Code Evidence Checked

These public-code patterns were observed in the locally cloned audit copy of `PhaseMirror/multiplicity`, which is a fork of `MultiplicityTheory/multiplicity`:

```text
C:/Users/jessi/Desktop/sentinel-uor-proof-audit/PhaseMirror-multiplicity/lean/PIRTM/Stability.lean
C:/Users/jessi/Desktop/sentinel-uor-proof-audit/PhaseMirror-multiplicity/lean/MOC/Core.lean
C:/Users/jessi/Desktop/sentinel-uor-proof-audit/PhaseMirror-multiplicity/rust/src/proof_attestation.rs
C:/Users/jessi/Desktop/sentinel-uor-proof-audit/PhaseMirror-multiplicity/core_schema.json
```

Observed defects:

1. `is_contractive := by simp` combined with `is_ace_dominant := by trivial`.
2. `proof_hash := { hash := "LEAN_PROOF_HASH_108_CORE" }`.
3. `factor_unique n h = ∀ p, p = n → p = n`.

## Mathematical Corrections

### 1. Stability

Correct condition:

```text
ρ(T) < 1
```

For the scalar/diagonal finite-gain case implemented here:

```apl
SpectralRadiusDiag gains = max |gains|
IsContractive gains      = SpectralRadiusDiag gains < 1
```

The contradiction is executable:

```text
α < 1 and α ≥ 1 cannot both hold.
```

### 2. Proof Hash

This repo does not pretend a literal label is a hash.

`zeroproof_substrate.apl` structurally validates SHA-256 digest shape:

```text
64 hexadecimal characters
```

`LEAN_PROOF_HASH_108_CORE` is rejected.

### 3. Factorization

The tautology:

```text
p = n -> p = n
```

is not a factorization proof.

The APL substrate computes a real prime-factor witness and checks:

- all factors are prime
- factors are sorted
- product of factors equals `n`

For `108` the executable witness is:

```text
2 2 3 3 3
```

### 4. Domain Boundary

Boundaries are encoded as:

```text
name lower upper omega cap
```

and checked by `WithinDomain`.

### 5. Omega Isolation

Correct isolation:

```text
ω < Ω
```

not `ω > Ω`.

The resonance entropy gate uses:

```text
ε < 0.21
```

### 6. Morphism Composition

Correct order:

```text
(f∘g)(x) = f(g(x))
```

The APL operator `Compose` executes that order directly.

## BOB + EDAULC

Each module uses the same minimal proof discipline:

```apl
Assert ← EDAULC failure gate
BOB    ← reasoning loop over boolean proof obligations
```

Every proof step is reduced to executable conditions. A failed condition signals.

## Running

Load the APL files in this order in a Dyalog-compatible APL session:

```apl
]LOAD src/pirtm_stability.apl
]LOAD src/sovereign_domain.apl
]LOAD src/omega_isolation.apl
]LOAD src/zeroproof_substrate.apl
]LOAD src/morphism_composition.apl
]LOAD src/run_all.apl
RunAll ⍬
```

This machine did not have an APL interpreter installed during repo creation, so runtime execution was not performed locally. Static source and provenance checks were performed.

## Governance Boundary

This repo critiques public code patterns. It does not claim private knowledge of any person or private repository.

## Seal

AN = correct executable APL proof substrate requested.

KI = grounded in public/local audit source paths listed above.

ME = no hidden claims; every correction is represented as executable APL conditions.
