# Proof Guide

## Tactics Overview

| Tactic | Purpose |
|--------|---------|
| `exact` | Apply an exact term |
| `intro` | Introduce variables/assumptions |
| `apply` | Apply a function/theorem |
| `rewrite` | Rewrite using an equation |
| `simp` | Simplification |
| `omega` | Linear arithmetic over Nat/Int |
| `ring` | Ring/field equalities |
| `induction` | Structural induction |
| `cases` | Case analysis |
| `constructor` | Apply a constructor |
| `left`/`right` | Disjunction introduction |
| `exists` | Existential introduction |
| `have` | Assert an intermediate fact |
    | `show` | Provide expected type |
    | `trace` | Debug: print goal |

## Proof Patterns

### Direct Proof

```m5
theorem imp_intro {P Q : Prop} (h : P → Q) (p : P) : Q := by
  exact h p
```

### Proof by Contradiction

```m5
theorem not_not {P : Prop} (h : ¬¬P) : P := by
  by_contra hnp
  exact h hnp
```

### Induction

```m5
theorem add_comm (a b : Nat) : a + b = b + a := by
  induction a with
  | zero => simp
  | succ n ih => simp [Nat.succ_add, ih]
```

### Case Analysis

```m5
theorem or_comm {P Q : Prop} (h : P ∨ Q) : Q ∨ P := by
  cases h with
  | inl hp => exact Or.inr hp
  | inr hq => exact Or.inl hq
```

### Rewriting

```m5
theorem add_zero (n : Nat) : n + 0 = n := by
  simp [Nat.add_zero]
```

### Using `omega`

```m5
theorem le_add_right (n m : Nat) : n ≤ n + m := by
  omega
```

### Using `ring`

```m5
theorem mul_comm (a b : Nat) : a * b = b * a := by
  ring
```

## Common Pitfalls

1. **Termination**: All functions must terminate
2. **Universe constraints**: `Type : Type` is not allowed
3. **Proof irrelevance**: `Prop` values are not distinguished
4. **Excluded middle**: Not built-in, must be assumed as axiom
