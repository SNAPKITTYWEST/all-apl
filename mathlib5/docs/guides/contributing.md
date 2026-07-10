# Contributing Guide

## Development Setup

```bash
# Clone
git clone https://github.com/user/mathlib5.git
cd mathlib5

# Build everything
make all

# Run tests
make test

# Run benchmarks
make bench
```

## Code Standards

### C Code (Kernel, Compiler)

- **Standard**: C99 with `-pedantic -Wall -Wextra`
- **Formatting**: 4 spaces indent, no tabs
- **Naming**: `snake_case` for functions, `PascalCase` for types
- **Documentation**: Every function has a doc comment
- **Testing**: Every function has a unit test

### Documentation

- **Format**: Markdown with Mermaid diagrams
- **Style**: Concise, example-driven
- **Coverage**: Every public API has a doc page

## Review Process

1. **Automated**: CI runs tests, lints, type checks
2. **Code Review**: At least one reviewer for every PR
3. **Proof Review**: Proof changes require kernel-level review
4. **Merge**: Only after CI passes and review approved

## Architecture Decision Records (ADRs)

When making significant design decisions:

1. Write an ADR in `docs/adr/`
2. Use the template in `docs/adr/000-template.md`
3. Discuss in a GitHub Issue
4. Merge with the implementation PR

## RFC Process

For language changes:

1. Write an RFC in `docs/rfc/`
2. Use the template in `docs/rfc/000-template.md`
3. Open a Discussion
4. Vote (thumbs up/down)
5. Implement after approval

## Testing

### Unit Tests

```bash
# Run all tests
make test

# Run specific test
make test TEST=test_kernel
```

### Regression Tests

```bash
# Run regression suite
make regression
```

### Benchmarks

```bash
# Run benchmarks
make bench

# Compare with baseline
make bench-compare BASELINE=main
```
