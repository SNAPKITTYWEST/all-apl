/**
 * kernel.h — MATHLIB5 Trusted Proof Kernel
 * Smallest possible TCB. Everything else is verified against this.
 *
 * Design principles:
 * - Single file, single compilation unit
 * - No external dependencies beyond C standard library
 * - Deterministic execution (no randomness, no system calls)
 * - Every function has a clear specification
 * - Total functions only (no infinite loops, no partial functions)
 *
 * Trust base: CompCert C compiler + this file (~500 LOC)
 */

#ifndef MATHLIB5_KERNEL_H
#define MATHLIB5_KERNEL_H

#include <stdint.h>
#include <stddef.h>

/* ── Version ──────────────────────────────────────────────────────── */
#define MATHLIB5_VERSION "0.1.0"
#define MATHLIB5_KERNEL_VERSION 1

/* ── Error Codes ──────────────────────────────────────────────────── */
typedef enum {
    ML5_OK = 0,
    ML5_ERR_OOM = 1,
    ML5_ERR_TYPE = 2,
    ML5_ERRҏOUNT = 3,
    ML5_ERR_INTERNAL = 4,
} ML5_Status;

/* ── De Bruijn Indices ────────────────────────────────────────────── */
typedef uint32_t ML5_DeBruijn;

/* ── Expressions (Core Language) ──────────────────────────────────── */
typedef enum {
    ML5_VAR,        /* de Bruijn variable */
    ML5_LAM,        /* lambda abstraction */
    ML5_APP,        /* application */
    ML5_PI,         /* dependent product type */
    ML5_SORT,       /* Type universe */
    ML5_CONST,      /* named constant */
    ML5_LET,        /* let binding */
} ML5_ExprKind;

typedef struct ML5_Expr {
    ML5_ExprKind kind;
    union {
        ML5_DeBruijn var;                    /* ML5_VAR */
        struct { struct ML5_Expr *body; } lam;  /* ML5_LAM: λ. body */
        struct { struct ML5_Expr *fn; struct ML5_Expr *arg; } app;  /* ML5_APP */
        struct { struct ML5_Expr *domain; struct ML5_Expr *codomain; } pi;  /* ML5_PI */
        struct { uint32_t level; } sort;    /* ML5_SORT: Type_i */
        struct { uint32_t id; } kst;       /* ML5_CONST */
        struct { struct ML5_Expr *type; struct ML5_Expr *value; struct ML5_Expr *body; } let_e;  /* ML5_LET */
    } data;
} ML5_Expr;

/* ── Types ────────────────────────────────────────────────────────── */
typedef ML5_Expr ML5_Type;

/* ── Contexts ─────────────────────────────────────────────────────── */
typedef struct ML5_LocalCtx {
    ML5_Type *types;
    ML5_DeBruijn size;
    ML5_DeBruijn capacity;
} ML5_LocalCtx;

/* ── Kernel Environment ───────────────────────────────────────────── */
typedef struct ML5_Constant {
    uint32_t id;
    ML5_Type type;
    ML5_Expr *definition; /* NULL for axioms */
    int is_axiom;
} ML5_Constant;

typedef struct ML5_Env {
    ML5_Constant *constants;
    uint32_t n_constants;
    uint32_t capacity;
} ML5_Env;

/* ── Memory Management (Arena) ────────────────────────────────────── */
typedef struct ML5_Arena {
    char *base;
    char *ptr;
    char *end;
} ML5_Arena;

/* ── API: Expression Construction ─────────────────────────────────── */

/* Create expression constructors */
ML5_Expr *ml5_var(ML5_Arena *a, ML5_DeBruijn idx);
ML5_Expr *ml5_lam(ML5_Arena *a, ML5_Expr *body);
ML5_Expr *ml5_app(ML5_Arena *a, ML5_Expr *fn, ML5_Expr *arg);
ML5_Expr *ml5_pi(ML5_Arena *a, ML5_Expr *domain, ML5_Expr *codomain);
ML5_Expr *ml5_sort(ML5_Arena *a, uint32_t level);
ML5_Expr *ml5_const(ML5_Arena *a, uint32_t id);
ML5_Expr *ml5_let(ML5_Arena *a, ML5_Expr *type, ML5_Expr *value, ML5_Expr *body);

/* ── API: Type Checking ───────────────────────────────────────────── */

/**
 * Type check an expression in a context.
 * Returns ML5_OK if well-typed, error code otherwise.
 */
ML5_Status ml5_typecheck(
    const ML5_Env *env,
    const ML5_LocalCtx *ctx,
    const ML5_Expr *expr,
    ML5_Type *out_type
);

/**
 * Check if two types are convertible (definitional equality).
 */
int ml5_convertible(
    const ML5_Env *env,
    const ML5_LocalCtx *ctx,
    const ML5_Expr *a,
    const ML5_Expr *b
);

/* ── API: Substitution ────────────────────────────────────────────── */

/**
 * Substitute de Bruijn index 0 with a term.
 * [0 := replacement]expr
 */
ML5_Expr *ml5_subst(
    ML5_Arena *a,
    const ML5_Expr *expr,
    const ML5_Expr *replacement
);

/* ── API: Normalization ───────────────────────────────────────────── */

/**
 * Beta-normalize an expression.
 */
ML5_Expr *ml5_normalize(
    ML5_Arena *a,
    const ML5_Env *env,
    const ML5_Expr *expr
);

/* ── API: Environment ─────────────────────────────────────────────── */

ML5_Status ml5_env_create(ML5_Env *env, uint32_t capacity);
ML5_Status ml5_env_add_axiom(ML5_Env *env, const char *name, const ML5_Type *type);
ML5_Status ml5_env_add_definition(ML5_Env *env, const char *name, const ML5_Type *type, const ML5_Expr *def);
void ml5_env_destroy(ML5_Env *env);

/* ── API: Arena ───────────────────────────────────────────────────── */

ML5_Status ml5_arena_create(ML5_Arena *a, size_t capacity);
void *ml5_arena_alloc(ML5_Arena *a, size_t size);
void ml5_arena_reset(ML5_Arena *a);
void ml5_arena_destroy(ML5_Arena *a);

/* ── API: Proof Verification ──────────────────────────────────────── */

/**
 * Verify that a proof term has the given type.
 * This is the core trust boundary.
 */
ML5_Status ml5_verify_proof(
    const ML5_Env *env,
    const ML5_Expr *proof,
    const ML5_Type *theorem
);

#endif /* MATHLIB5_KERNEL_H */
