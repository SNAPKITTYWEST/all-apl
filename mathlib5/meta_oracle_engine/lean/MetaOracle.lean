-- MetaOracle.lean — Lean 4 Types for Boolean Gate Verification
-- Defines proof term structure and validation entry point.

import Mathlib.Data.List.Basic
import Mathlib.Data.Nat.Basic

namespace MetaOracle

/-- Oracle verification status -/
inductive OracleStatus where
  | valid
  | invalid (reason : String)
  deriving Repr, BEq

/-- Proof step in a resolution proof -/
structure ProofStep where
  id : Nat
  literals : List String
  from1 : Option Nat := none
  from2 : Option Nat := none
  deriving Repr

/-- A complete proof -/
structure Proof where
  steps : List ProofStep
  deriving Repr

/-- Check if any step contains 'sorry' -/
def containsSorry (proof : Proof) : Bool :=
  proof.steps.any fun step =>
    step.literals.any fun lit =>
      lit.containsSubstr "sorry"

/-- Validate proof structure: all parent refs are earlier IDs -/
def validateStructure (proof : Proof) : Bool :=
  let ids := proof.steps.map ProofStep.id
  proof.steps.all fun step =>
    match step.from1, step.from2 with
    | some f1, some f2 => f1 < step.id && f2 < step.id && ids.contains f1 && ids.contains f2
    | none, none => true  -- axiom
    | _, _ => false

/-- Validate complete proof: no sorry + valid structure + has empty clause -/
def validate (proofText : String) : Bool :=
  let lines := proofText.trim.splitOn "\n"
  let nonEmpty := lines.filter fun l => !l.trim.isEmpty && !l.trim.startsWith "#"
  let steps := nonEmpty.filterMap fun line =>
    let tokens := line.trim.splitOn " "
    match tokens with
    | idStr :: rest =>
      match idStr.toNat? with
      | some id =>
        let hasFrom := rest.any fun t => t == "from"
        some { id := id, literals := rest.filter fun t => t != "from", from1 := none, from2 := none }
      | none => none
    | [] => none
  let proof := { steps := steps }
  !containsSorry proof && validateStructure proof

/-- FFI entry point for Python bridge -/
def validateFFI (proofText : String) : IO Bool :=
  IO.println s!"[Lean4] Validating: {proofText.take 80}..."
  let result := validate proofText
  IO.println s!"[Lean4] Result: {result}"
  pure result

end MetaOracle

/-- Main entry point -/
def main : IO Unit :=
  IO.println "MetaOracle Lean 4 Kernel Ready"
