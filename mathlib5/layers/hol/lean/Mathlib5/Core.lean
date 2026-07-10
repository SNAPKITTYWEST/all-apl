import Mathlib.Data.Nat.Basic
import Mathlib.Algebra.BigOperators.Basic
import Mathlib.Tactic.Ring

open BigOperators

/-- 
  Sum of squares: Σ_{k=0}^{n-1} (k+1)² = n(n+1)(2n+1)/6
  This lemma is the core proof obligation for SumSquares.apl
--/
theorem sum_squares_formula (n : ℕ) :
  (∑ k in Finset.range n, (k + 1)^2 : ℚ) = n * (n + 1) * (2 * n + 1) / 6 := by
  induction n with
  | zero => simp
  | succ n ih =>
    rw [Finset.sum_range_succ, ih]
    push_cast
    ring
