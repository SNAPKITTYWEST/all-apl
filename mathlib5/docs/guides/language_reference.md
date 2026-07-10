# Language Reference

## Syntax Overview

```m5
-- Comments: -- line comment
--           /- block comment -/

-- Declarations
theorem name : Type := proof
lemma name : Type := proof
def name : Type := value
axiom name : Type

-- Terms
fun x => body          -- lambda
(x : Type) → Codomain  -- dependent function type
if c then t else e     -- conditional
let x := v in body     -- let binding
match e with | p => b  -- pattern matching

-- Types
Prop                   -- proposition type
Type                   -- data type universe
Nat                    -- natural numbers
Int                    -- integers
Real                   -- real numbers
Bool                   -- booleans
String                 -- strings
Array α n              -- fixed-size array
```

## Type System

MATHLIB5 uses Calculus of Inductive Constructions (CIC) with:

- **Dependent types**: types can depend on values
- **Universe polymorphism**: types in types
- **Inductive types**: user-defined data types
- **Type classes**: ad-hoc polymorphism

## Universe Hierarchy

```
Prop : Type 0 : Type 1 : Type 2 : ...
```

- `Prop` is proof-irrelevant
- `Type i` is cumulative: `Type i : Type (i+1)`

## Inductive Types

```m5
inductive Nat where
  | zero : Nat
  | succ : Nat → Nat

inductive List (α : Type) where
  | nil : List α
  | cons : α → List α → List α

inductive Fin (n : Nat) where
  | mk : (i : Nat) → (h : i < n) → Fin n
```

## Pattern Matching

```m5
def isZero : Nat → Bool
  | 0 => true
  | _ + 1 => false

def length {α : Type} : List α → Nat
  | [] => 0
  | _ :: xs => 1 + length xs
```

## Termination

All functions must terminate. The compiler checks:

1. Structural recursion on inductive types
2. Well-founded relations
3. Mutual recursion with decreasing measures

```m5
-- Structural recursion (accepted)
def fact : Nat → Nat
  | 0 => 1
  | n + 1 => (n + 1) * fact n

-- Well-founded recursion (accepted)
def div : Nat → Nat → Nat
  | 0, _ => 0
  | n + 1, d => if h : d ≤ n + 1 then div (n + 1 - d) d + 1 else 0
```
