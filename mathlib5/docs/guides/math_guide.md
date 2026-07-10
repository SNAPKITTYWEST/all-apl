# Mathematics Guide

## Library Structure

```
stdlib/
├── core/           # Nat, Int, Bool, String, Array
├── algebra/        # Groups, rings, fields, modules
├── analysis/       # Real analysis, measure theory
├── calculus/       # Derivatives, integrals
├── topology/       # Topological spaces, continuity
├── number_theory/  # Primes, modular arithmetic
├── combinatorics/  # Counting, graph basics
├── graph_theory/   # Graphs, paths, trees
├── geometry/       # Euclidean, projective
├── probability/    # Probability theory
└── category_theory/ # Categories, functors, natural transformations
```

## Available Notations

| Notation | Meaning | Library |
|----------|---------|---------|
| `a + b` | Addition | core |
| `a * b` | Multiplication | core |
| `a ^ b` | Power | core |
| `a ≤ b` | Less or equal | core |
| `a ∣ b` | Divisibility | number_theory |
| `∑ x in s, f x` | Summation | algebra |
| `∏ x in s, f x` | Product | algebra |
| `∫ x, f x` | Integral | analysis |
| `∂/∂x f` | Partial derivative | calculus |
| `‖x‖` | Norm | analysis |
| `f ⁻¹` | Inverse function | algebra |
| `X × Y` | Cartesian product | core |
| `A ⊆ B` | Subset | core |
| `A ∪ B` | Union | core |
| `A ∩ B` | Intersection | core |

## Example: Fundamental Theorem of Arithmetic

```m5
import Mathlib.NumberTheory.PrimeFactorization

theorem fta (n : Nat) (h : n > 1) :
    ∃! (f : Nat → Nat), (∀ p, f p > 0 → Prime p) ∧
    (∏ p in (f.support), p ^ f p = n) := by
  exact Nat.exists_unique_factorization n h
```

## Example: Intermediate Value Theorem

```m5
import Mathlib.Analysis.Calculus.IVT

theorem ivt {f : ℝ → ℝ} (hf : Continuous f)
    {a b : ℝ} (ha : f a < 0) (hb : f b > 0) :
    ∃ c ∈ Set.Icc a b, f c = 0 := by
  exact exists_zero_of_continuous_of_neg_pos hf ha hb
```
