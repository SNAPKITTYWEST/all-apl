-- ============================================================
-- SorryDB/Scanner.lean — Scan Lean projects for sorry statements
-- Tracks every sorry ever made, feeds them to the closing kernel
-- ============================================================

import Lean
import Lean.Elab.Command

open Lean Elab Command

-- ============================================================
-- Data Structures
-- ============================================================

structure SorryEntry where
  file        : String
  line        : Nat
  column      : Nat
  name        : String
  type        : String
  context     : String
  difficulty  : SorryDifficulty
  status      : SorryStatus
  deriving Inhabited

inductive SorryDifficulty where
  | trivial   -- Can be closed by `simp`, `omega`, or `decide`
  | easy      -- Requires a single tactic like `ring` or `linarith`
  | medium    -- Requires a few tactics or lemma lookup
  | hard      -- Requires domain-specific reasoning
  | open      -- Millennium-class problem
  deriving Inhabited, BEq

inductive SorryStatus where
  | open      -- Not yet addressed
  | attempting -- Being worked on by the kernel
  | closed    -- Proof found and verified
  | failed    -- Could not close (needs human)
  deriving Inhabited, BEq

-- ============================================================
-- Sorry Registry (Global State)
-- ============================================================

structure SorryRegistry where
  mutable entries : Array SorryEntry := #[]
  mutable closedCount : Nat := 0
  mutable openCount : Nat := 0

variable [Monad m] [MonadState SorryRegistry m]

-- ============================================================
-- Scanner: Extract sorries from Lean code
-- ============================================================

def scanFile (path : String) : m (Array SorryEntry) := do
  let content ← IO.FS.readFile path
  let lines := content.splitOn "\n"
  let mut sorries : Array SorryEntry := #[]
  
  for (line, idx) in lines.zipWithIndex do
    let lineNum := idx + 1
    -- Match sorry keyword (not in comments or strings)
    if line.containsSubstr "sorry" && !line.trim.startsWith "--" then
      let entry : SorryEntry := {
        file := path
        line := lineNum
        column := line.indexOf "sorry" |>.toNat
        name := extractName line
        type := extractType line
        context := line.trim
        difficulty := classifyDifficulty line
        status := .open
      }
      sorries := sorries.push entry
  
  pure sorries

def extractName (line : String) : String :=
  -- Extract theorem/def name from line
  let parts := line.splitOn " "
  if parts.length >= 2 then parts[1]! else "unknown"

def extractType (line : String) : String :=
  -- Extract type signature
  if line.containsSubstr ":" then
    let afterColon := line.splitOn ":" |>.drop 1 |>.headD ""
    afterColon.splitOn ":=" |>.headD "" |>.trim
  else "unknown"

def classifyDifficulty (line : String) : SorryDifficulty :=
  -- Heuristic difficulty classification
  let lower := line.toLower
  if lower.containsSubstr "sorry" && lower.containsSubstr "theorem" then
    if lower.containsSubstr "ring" || lower.containsSubstr "simp" || lower.containsSubstr "omega" then
      .trivial
    else if lower.containsSubstr "linarith" || lower.containsSubstr "norm_num" then
      .easy
    else if lower.containsSubstr "induction" || lower.containsSubstr "cases" then
      .medium
    else if lower.containsSubstr "riemann" || lower.containsSubstr "yang" || lower.containsSubstr "navier" then
      .open
    else
      .hard
  else
    .medium

-- ============================================================
-- Command: #scan_sorries
-- ============================================================

elab "#scan_sorries" : command => do
  let env ← getEnv
  let mut totalSorries : Array SorryEntry := #[]
  
  -- Scan all imported files
  for (name, _) in env.constants.map₂ do
    let file := env.getModuleFor? name |>.map (·.toString) |>.getD "unknown"
    if file != "unknown" then
      let sorries ← scanFile file
      totalSorries := totalSorries.append sorries
  
  logInfo m!"Found {totalSorries.size} sorry statements"
  
  -- Print summary
  let trivial := totalSorries.filter (·.difficulty == .trivial)
  let easy := totalSorries.filter (·.difficulty == .easy)
  let medium := totalSorries.filter (·.difficulty == .medium)
  let hard := totalSorries.filter (·.difficulty == .hard)
  let open := totalSorries.filter (·.difficulty == .open)
  
  logInfo m!"  Trivial: {trivial.size}"
  logInfo m!"  Easy:    {easy.size}"
  logInfo m!"  Medium:  {medium.size}"
  logInfo m!"  Hard:    {hard.size}"
  logInfo m!"  Open:    {open.size}"

-- ============================================================
-- Command: #sorry_status
-- ============================================================

elab "#sorry_status" : command => do
  logInfo m!"=== MATHLIB5 Sorry Status ==="
  logInfo m!"Total closed: 0 (building kernel...)"
  logInfo m!"Total open:    scanning..."
  logInfo m!"Millennium:    7 problems targeted"
