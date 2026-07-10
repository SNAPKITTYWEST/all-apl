# Theorem Status Map

This file separates actual checked artifacts from open-problem scaffolding, examples, and prior-art claims.

## Status Classes

- `checked-local`
  Narrow theorem or invariant with a concrete proof artifact in the repo.
- `checked-executable`
  Finite executable verification or refutation backed by code.
- `partial-formalization`
  Real formal development, but not a proof of the headline global claim.
- `example-or-demo`
  Illustrative theorem surface, sample term, or documentation example.
- `open-problem-scaffold`
  Infrastructure for working on an open problem, not a resolution.
- `historical-claim`
  Prior-art or narrative claim whose referenced artifact is not present in this working tree.

## Current Map

### checked-executable

- `legacy/apl-corrections/pirtm_stability.apl`
  Executable contradiction check for specific stability/certificate conditions.
- `legacy/apl-corrections/zeroproof_substrate.apl`
  Executable rejection of fake proof hashes and tautological factorization.
- `legacy/apl-corrections/intercol.apl`
  Executable orthogonality/null-transition model over the declared domain basis.
- `legacy/apl-corrections/omega_isolation.apl`
  Executable inequality and inversion rejection check.
- `legacy/apl-corrections/morphism_composition.apl`
  Executable composition-order check.

### checked-local

- `agentos_source/collatz-verification/proofs/Collatz.lean`
  Local lemmas such as `collatz_one`, `collatz_two`, `collatz_four`, `collatz_cycle`,
  `pow_two_reaches_one`, `pow_two_length`, `double_reaches`, `quad_reaches`.
- `mathrosetta_source/proofs/lean4/Sovereign/*.lean`
  Repo-local topology, reachability, conduction, and stack correctness theorems.
- `mathrosetta_source/proofs/isabelle/*.thy`
  Parallel theorem surfaces for the same sovereign/topology model.

### partial-formalization

- `agentos_source/collatz-verification/proofs/Collatz.lean`
  Defines `collatz_conjecture`, but does not prove it globally.
- `agentos_source/math-engine/proofs/PNP.lean`
  Defines envelope-verification structures and proves small local lemmas,
  but still contains `axiom` and `sorry`.
- `mathrosetta_source/proofs/proof_manifest.json`
  Tracks theorem targets as `machine_checked_pending_external_build`, not completed external checker runs.

### example-or-demo

- `agentos_source/axiom-proof/examples/simple.axiom`
  Minimal example.
- `agentos_source/axiom-proof/examples/collatz.axiom`
  Demonstration formalization with `sorry`, not a finished theorem proof.
- `agentos_source/axiom-proof/docs/AXIOM.md`
  Shows example sealing flows and theorem examples; not all shown proofs are completed artifacts.

### open-problem-scaffold

- `agentos_source/pnp-attack/`
  Search and experimentation infrastructure for P vs NP.
- `agentos_source/collatz-verification/`
  Search, visualization, and audit infrastructure around Collatz.
- `agentos_source/math-skills/`
  Capability layer for finite constructions and complexity experiments, not evidence of solving the listed open problems.

### historical-claim

- `docs/PRIOR_ART_DISCLOSURE.md` references Goldilocks Lean/APL artifacts that are not present in this working tree.

## Practical Reading Rule

Do not read the word "theorem" in this repo as meaning "major open problem solved."
Usually it means one of:

1. a local theorem in a repo-specific formal model,
2. an executable finite check,
3. a theorem target emitted for a proof assistant,
4. an open-problem scaffold, or
5. a historical claim that needs the original artifact set to verify fully.

## Where The Novelty Actually Seems To Be

The best case for genuinely novel solved work in this working tree is not "Collatz solved" or "P vs NP solved."
It is the narrower layer where the repo turns vague public claims into executable pass/fail mathematics:

- `pirtm_stability.apl`
  Resolves a specific contradiction between contractivity and an `α ≥ 1` certificate condition.
- `zeroproof_substrate.apl`
  Resolves whether a placeholder string counts as a real proof hash and whether a tautology counts as factorization evidence.
- `intercol.apl`
  Resolves a repo-specific structural claim: cross-domain transitions collapse to null state under the chosen orthogonality model.

Those are narrow, but they are actual solved items in the sense that the repo gives an explicit mathematical model and an executable decision procedure.
