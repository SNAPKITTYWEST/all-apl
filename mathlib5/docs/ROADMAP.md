# MATHLIB5 Roadmap

## Phase 0: Foundation (Months 1-3)

- [x] Trusted proof kernel (~500 LOC)
- [x] Lexer and parser
- [ ] Type checker
- [ ] Elaborator
- [ ] Basic tactics (exact, intro, apply, rewrite)
- [ ] Core library (Nat, Int, Bool, List, Array)
- [ ] Test suite with regression tests
- [ ] Documentation: Getting Started, Language Reference

**Milestone**: Can type-check and verify `identity : A → A`

## Phase 1: Standard Library (Months 4-6)

- [ ] Algebra (groups, rings, fields)
- [ ] Number theory (primes, GCD, modular arithmetic)
- [ ] Combinatorics (basic counting)
- [ ] Tactic automation (simp, omega, ring)
- [ ] Inductive types with pattern matching
- [ ] Termination checker
- [ ] Benchmark suite

**Milestone**: Can prove basic algebraic identities

## Phase 2: Analysis and Topology (Months 7-12)

- [ ] Real analysis (limits, continuity, derivatives)
- [ ] Topology (open sets, compactness)
- [ ] Calculus (fundamental theorem)
- [ ] Measure theory basics
- [ ] Category theory basics
- [ ] LLVM backend (basic)
- [ ] SMT export (Z3, cvc5)

**Milestone**: Can prove the Intermediate Value Theorem

## Phase 3: Advanced Mathematics (Months 13-18)

- [ ] Abstract algebra (groups, rings, fields, modules)
- [ ] Linear algebra
- [ ] Number theory (advanced)
- [ ] Graph theory
- [ ] Geometry
- [ ] Probability theory
- [ ] WASM backend
- [ ] C-- backend (CompCert)

**Milestone**: Can prove the Fundamental Theorem of Algebra

## Phase 4: Integration (Months 19-24)

- [ ] Lean import
- [ ] SymPy exchange
- [ ] MLIR backend (hardware)
- [ ] Web IDE
- [ ] Course platform
- [ ] Community contributions

**Milestone**: Production-ready with 1000+ verified theorems

## Success Metrics

| Metric | Phase 0 | Phase 1 | Phase 2 | Phase 3 | Phase 4 |
|--------|---------|---------|---------|---------|---------|
| Theorems | 10 | 100 | 500 | 1000 | 5000 |
| LOC (kernel) | 500 | 500 | 500 | 500 | 500 |
| LOC (stdlib) | 1k | 10k | 50k | 100k | 200k |
| Tactics | 5 | 15 | 30 | 50 | 50 |
| Backends | 0 | 1 | 2 | 4 | 4 |
| Tests | 50 | 200 | 500 | 1000 | 2000 |
