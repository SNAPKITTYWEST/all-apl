# Getting Started with MATHLIB5

## Installation

```bash
# Clone
git clone https://github.com/user/mathlib5.git
cd mathlib5

# Build the kernel
cd kernel
gcc -std=c99 -pedantic -Wall -Wextra -O2 -c kernel.c -o kernel.o

# Build the compiler
cd ../compiler/lexer
gcc -std=c99 -pedantic -Wall -Wextra -O2 -c lexer.c -o lexer.o

# Return to root
cd ../..
```

## First Theorem

Create a file `hello.m5`:

```m5
theorem hello : True := by
  trivial
```

Verify it:

```bash
./bin/mathlib5 check hello.m5
# OK: hello verified
```

## First Proof

Create `example.m5`:

```m5
theorem modus_ponens {P Q : Prop} (h1 : P → Q) (h2 : P) : Q := by
  exact h1 h2
```

## Core Concepts

### Dependent Types

MATHLIB5 uses dependent types. Types can depend on values:

```m5
def Vec (α : Type) (n : Nat) : Type := Array α n

def head {α : Type} {n : Nat} (v : Vec α (n + 1)) : α := v[0]
```

### The `by` Keyword

Proofs are written using tactics after `by`:

```m5
theorem add_comm (a b : Nat) : a + b = b + a := by
  induction a with
  | zero => simp
  | succ n ih => simp [Nat.succ_add, ih]
```

### Universes

Types are organized in a universe hierarchy:

```m5
#check Type 0  -- : Type 1
#check Type 1  -- : Type 2
```

## Next Steps

- [Language Reference](language_reference.md) — Complete syntax
- [Proof Guide](proof_guide.md) — Tactics and patterns
- [Mathematics Guide](math_guide.md) — Available libraries
