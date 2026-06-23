# Public Code Evidence

This note records the public-code surfaces used for the APL refutation.

Audit clone:

```text
C:/Users/jessi/Desktop/sentinel-uor-proof-audit/PhaseMirror-multiplicity
```

GitHub metadata observed during Sentinel audit:

```text
PhaseMirror/multiplicity
fork=true
parent=MultiplicityTheory/multiplicity
source=MultiplicityTheory/multiplicity
HEAD=1478916fd626666e8f0d3523260a764fdf0a7577
```

## Evidence 1: Stability Placeholder

Path:

```text
lean/PIRTM/Stability.lean
```

Observed pattern:

```text
proof_hash := { hash := "LEAN_PROOF_HASH_108_CORE" }
is_contractive := by simp
is_ace_dominant := by trivial
```

Correction:

```text
contraction requires spectral radius < 1
α ≥ 1 is rejected as a contraction witness
```

APL:

```text
src/pirtm_stability.apl
```

## Evidence 2: Literal Proof Hash

Paths:

```text
lean/PIRTM/Stability.lean
rust/src/proof_attestation.rs
core_schema.json
```

Observed literal:

```text
LEAN_PROOF_HASH_108_CORE
```

Correction:

```text
proof hash must at minimum be digest-shaped: 64 hexadecimal characters for SHA-256
```

APL:

```text
src/zeroproof_substrate.apl
```

## Evidence 3: Tautological Factorization

Path:

```text
lean/MOC/Core.lean
```

Observed proposition:

```text
∀ p, p = n → p = n
```

Correction:

```text
factorization proof must produce prime factors whose product equals n
```

APL:

```text
src/zeroproof_substrate.apl
```

For `108`:

```text
108 = 2 × 2 × 3 × 3 × 3
```

