# MATHLIB5 APL Front-end (`layers/apl`)

## Overview
The APL Front-end is the primary entry point for mathematical expressions in the MATHLIB5 pipeline. It provides a functional parser that translates high-level APL notation into a symbolic S-expression intermediate representation (IR).

## Implementation Details
- **Language**: Haskell
- **Library**: `Megaparsec` for robust and efficient parsing.
- **AST Target**: `mathlib5/layers/sexpr` (S-expressions).

## Supported Syntax
The parser currently supports a subset of APL primitives and functional constructs required for verified symbolic computation:

### Primitives
- `⍳` (Iota): Range generation.
- `+/` (Plus-reduce): Summation.
- `*` (Power): Exponentiation.
- `⍴` (Reshape).
- Mathematical Operators: `+`, `-`, `×`, `÷`, `*`.
- Comparison: `=`, `≠`, `<`, `>`, `≤`, `≥`.

### Data Types
- **Numbers**: Double-precision floating point.
- **Strings**: Double-quoted literals.
- **Atoms**: Identifiers and symbols.
- **Lists**: Space-separated S-expressions enclosed in `()`.

### Functional Constructs
- **Lambda Abstractions**: Enclosed in `{}`.
  - Example: `{ (+/ (⍳⍵) * 2) }` (Sum of Squares).
  - The argument is implicitly bound to `⍵` (omega).

## Build & Test
The APL layer is built using Bazel.

```bash
# Build the parser library
bazel build //layers/apl:apl_parser

# Run parser unit tests
bazel test //layers/apl:apl_parser_test
```

## Integration in MATHLIB5
1. **Parser**: `Parser.hs` consumes APL text and emits `SExpr`.
2. **Bridge**: The `SExpr` is then passed to the Liquid Haskell layer for refinement type checking.
3. **Formalization**: Patterns recognized by the bridge are translated into Lean 4 theorems for formal proof.

---
**MATHLIB5 — Verified Symbolic Compute Pipeline**
