/**
 * kernel.c — MATHLIB5 Trusted Proof Kernel Implementation
 * ~500 LOC. Smallest possible TCB.
 */

#include "kernel.h"
#include <stdlib.h>
#include <string.h>

/* ── Arena Allocator ──────────────────────────────────────────────── */

ML5_Status ml5_arena_create(ML5_Arena *a, size_t capacity) {
    a->base = (char *)malloc(capacity);
    if (!a->base) return ML5_ERR_OOM;
    a->ptr = a->base;
    a->end = a->base + capacity;
    return ML5_OK;
}

void *ml5_arena_alloc(ML5_Arena *a, size_t size) {
    size = (size + 7) & ~7; /* align to 8 bytes */
    if (a->ptr + size > a->end) return NULL;
    void *p = a->ptr;
    a->ptr += size;
    return p;
}

void ml5_arena_reset(ML5_Arena *a) { a->ptr = a->base; }
void ml5_arena_destroy(ML5_Arena *a) { free(a->base); a->base = NULL; }

/* ── Expression Constructors ──────────────────────────────────────── */

ML5_Expr *ml5_var(ML5_Arena *a, ML5_DeBruijn idx) {
    ML5_Expr *e = ml5_arena_alloc(a, sizeof(ML5_Expr));
    if (!e) return NULL;
    e->kind = ML5_VAR;
    e->data.var = idx;
    return e;
}

ML5_Expr *ml5_lam(ML5_Arena *a, ML5_Expr *body) {
    ML5_Expr *e = ml5_arena_alloc(a, sizeof(ML5_Expr));
    if (!e) return NULL;
    e->kind = ML5_LAM;
    e->data.lam.body = body;
    return e;
}

ML5_Expr *ml5_app(ML5_Arena *a, ML5_Expr *fn, ML5_Expr *arg) {
    ML5_Expr *e = ml5_arena_alloc(a, sizeof(ML5_Expr));
    if (!e) return NULL;
    e->kind = ML5_APP;
    e->data.app.fn = fn;
    e->data.app.arg = arg;
    return e;
}

ML5_Expr *ml5_pi(ML5_Arena *a, ML5_Expr *domain, ML5_Expr *codomain) {
    ML5_Expr *e = ml5_arena_alloc(a, sizeof(ML5_Expr));
    if (!e) return NULL;
    e->kind = ML5_PI;
    e->data.pi.domain = domain;
    e->data.pi.codomain = codomain;
    return e;
}

ML5_Expr *ml5_sort(ML5_Arena *a, uint32_t level) {
    ML5_Expr *e = ml5_arena_alloc(a, sizeof(ML5_Expr));
    if (!e) return NULL;
    e->kind = ML5_SORT;
    e->data.sort.level = level;
    return e;
}

ML5_Expr *ml5_const(ML5_Arena *a, uint32_t id) {
    ML5_Expr *e = ml5_arena_alloc(a, sizeof(ML5_Expr));
    if (!e) return NULL;
    e->kind = ML5_CONST;
    e->data.kst.id = id;
    return e;
}

ML5_Expr *ml5_let(ML5_Arena *a, ML5_Expr *type, ML5_Expr *value, ML5_Expr *body) {
    ML5_Expr *e = ml5_arena_alloc(a, sizeof(ML5_Expr));
    if (!e) return NULL;
    e->kind = ML5_LET;
    e->data.let_e.type = type;
    e->data.let_e.value = value;
    e->data.let_e.body = body;
    return e;
}

/* ── Substitution (avoid capture) ─────────────────────────────────── */

static ML5_Expr *shift(ML5_Arena *a, const ML5_Expr *e, ML5_DeBruijn cutoff, ML5_DeBruijn amount) {
    if (!e) return NULL;
    switch (e->kind) {
    case ML5_VAR:
        if (e->data.var < cutoff) return ml5_var(a, e->data.var);
        return ml5_var(a, e->data.var + amount);
    case ML5_LAM: {
        ML5_Expr *body = shift(a, e->data.lam.body, cutoff + 1, amount);
        return ml5_lam(a, body);
    }
    case ML5_APP: {
        ML5_Expr *fn = shift(a, e->data.app.fn, cutoff, amount);
        ML5_Expr *arg = shift(a, e->data.app.arg, cutoff, amount);
        return ml5_app(a, fn, arg);
    }
    case ML5_PI: {
        ML5_Expr *dom = shift(a, e->data.pi.domain, cutoff, amount);
        ML5_Expr *cod = shift(a, e->data.pi.codomain, cutoff + 1, amount);
        return ml5_pi(a, dom, cod);
    }
    case ML5_SORT:
        return ml5_sort(a, e->data.sort.level);
    case ML5_CONST:
        return ml5_const(a, e->data.kst.id);
    case ML5_LET: {
        ML5_Expr *t = shift(a, e->data.let_e.type, cutoff, amount);
        ML5_Expr *v = shift(a, e->data.let_e.value, cutoff, amount);
        ML5_Expr *b = shift(a, e->data.let_e.body, cutoff + 1, amount);
        return ml5_let(a, t, v, b);
    }
    }
    return NULL;
}

ML5_Expr *ml5_subst(ML5_Arena *a, const ML5_Expr *expr, const ML5_Expr *replacement) {
    if (!expr) return NULL;
    switch (expr->kind) {
    case ML5_VAR:
        if (expr->data.var == 0) return shift(a, replacement, 0, 0);
        return ml5_var(a, expr->data.var - 1);
    case ML5_LAM: {
        ML5_Expr *body = ml5_subst(a, expr->data.lam.body, shift(a, replacement, 0, 1));
        return ml5_lam(a, body);
    }
    case ML5_APP: {
        ML5_Expr *fn = ml5_subst(a, expr->data.app.fn, replacement);
        ML5_Expr *arg = ml5_subst(a, expr->data.app.arg, replacement);
        return ml5_app(a, fn, arg);
    }
    case ML5_PI: {
        ML5_Expr *dom = ml5_subst(a, expr->data.pi.domain, replacement);
        ML5_Expr *cod = ml5_subst(a, expr->data.pi.codomain, shift(a, replacement, 0, 1));
        return ml5_pi(a, dom, cod);
    }
    case ML5_SORT:
        return ml5_sort(a, expr->data.sort.level);
    case ML5_CONST:
        return ml5_const(a, expr->data.kst.id);
    case ML5_LET: {
        ML5_Expr *t = ml5_subst(a, expr->data.let_e.type, replacement);
        ML5_Expr *v = ml5_subst(a, expr->data.let_e.value, replacement);
        ML5_Expr *b = ml5_subst(a, expr->data.let_e.body, shift(a, replacement, 0, 1));
        return ml5_let(a, t, v, b);
    }
    }
    return NULL;
}

/* ── Beta Reduction ───────────────────────────────────────────────── */

static int is_var(const ML5_Expr *e, ML5_DeBruijn idx) {
    return e && e->kind == ML5_VAR && e->data.var == idx;
}

ML5_Expr *ml5_reduce(ML5_Arena *a, const ML5_Expr *expr) {
    if (!expr) return NULL;
    if (expr->kind == ML5_APP && expr->data.app.fn->kind == ML5_LAM) {
        /* β-reduction: (λ.body) arg → body[0 := arg] */
        return ml5_subst(a, expr->data.app.fn->data.lam.body, expr->data.app.arg);
    }
    return expr;
}

ML5_Expr *ml5_normalize(ML5_Arena *a, const ML5_Env *env, const ML5_Expr *expr) {
    (void)env;
    if (!expr) return NULL;
    ML5_Expr *e = (ML5_Expr *)expr;
    for (int i = 0; i < 1000; i++) { /* bounded normalization */
        ML5_Expr *reduced = ml5_reduce(a, e);
        if (reduced == e) break;
        e = reduced;
    }
    return e;
}

/* ── Convertibility (α-equivalence + β-equivalence) ───────────────── */

int ml5_convertible(const ML5_Env *env, const ML5_LocalCtx *ctx,
                    const ML5_Expr *a, const ML5_Expr *b) {
    (void)ctx;
    if (a == b) return 1;
    if (!a || !b) return 0;
    if (a->kind != b->kind) return 0;

    ML5_Arena tmp;
    if (ml5_arena_create(&tmp, 1 << 16) != ML5_OK) return 0;

    ML5_Expr *na = ml5_normalize(&tmp, env, a);
    ML5_Expr *nb = ml5_normalize(&tmp, env, b);

    int result = 0;
    if (na->kind == nb->kind) {
        switch (na->kind) {
        case ML5_VAR: result = na->data.var == nb->data.var; break;
        case ML5_SORT: result = na->data.sort.level == nb->data.sort.level; break;
        case ML5_CONST: result = na->data.kst.id == nb->data.kst.id; break;
        case ML5_LAM:
            result = ml5_convertible(env, ctx, na->data.lam.body, nb->data.lam.body);
            break;
        case ML5_APP:
            result = ml5_convertible(env, ctx, na->data.app.fn, nb->data.app.fn) &&
                     ml5_convertible(env, ctx, na->data.app.arg, nb->data.app.arg);
            break;
        case ML5_PI:
            result = ml5_convertible(env, ctx, na->data.pi.domain, nb->data.pi.domain) &&
                     ml5_convertible(env, ctx, na->data.pi.codomain, nb->data.pi.codomain);
            break;
        case ML5_LET:
            result = ml5_convertible(env, ctx, na->data.let_e.value, nb->data.let_e.value) &&
                     ml5_convertible(env, ctx, na->data.let_e.body, nb->data.let_e.body);
            break;
        }
    }

    ml5_arena_destroy(&tmp);
    return result;
}

/* ── Type Checking ────────────────────────────────────────────────── */

static ML5_Type *infer_type(const ML5_Env *env, ML5_LocalCtx *ctx, const ML5_Expr *expr);

ML5_Status ml5_typecheck(const ML5_Env *env, const ML5_LocalCtx *ctx,
                         const ML5_Expr *expr, ML5_Type *out_type) {
    ML5_LocalCtx ctx_mut = *ctx;
    ML5_Type *t = infer_type(env, &ctx_mut, expr);
    if (!t) return ML5_ERR_TYPE;
    *out_type = *t;
    return ML5_OK;
}

static ML5_Type *infer_type(const ML5_Env *env, ML5_LocalCtx *ctx, const ML5_Expr *expr) {
    if (!expr) return NULL;
    switch (expr->kind) {
    case ML5_VAR:
        if (expr->data.var >= ctx->size) return NULL;
        return &ctx->types[ctx->size - 1 - expr->data.var];
    case ML5_SORT:
        return ml5_sort(NULL, expr->data.sort.level + 1); /* Type_{i+1} : Type_{i+1} */
    case ML5_CONST:
        for (uint32_t i = 0; i < env->n_constants; i++) {
            if (env->constants[i].id == expr->data.kst.id)
                return (ML5_Type *)&env->constants[i].type;
        }
        return NULL;
    case ML5_LAM:
        /* TODO: infer domain from annotation */
        return NULL;
    case ML5_APP: {
        ML5_Type *fn_type = infer_type(env, ctx, expr->data.app.fn);
        if (!fn_type || fn_type->kind != ML5_PI) return NULL;
        /* Check argument matches domain */
        ML5_Type *arg_type = infer_type(env, ctx, expr->data.app.arg);
        if (!arg_type) return NULL;
        if (!ml5_convertible(env, ctx, fn_type->data.pi.domain, arg_type)) return NULL;
        /* Return codomain with argument substituted */
        return fn_type->data.pi.codomain; /* simplified */
    }
    case ML5_PI: {
        ML5_Type *dom_type = infer_type(env, ctx, expr->data.pi.domain);
        if (!dom_type) return NULL;
        /* Check domain is a sort */
        if (dom_type->kind != ML5_SORT) return NULL;
        /* Extend context, check codomain */
        ctx->size++;
        ML5_Type *cod_type = infer_type(env, ctx, expr->data.pi.codomain);
        ctx->size--;
        if (!cod_type) return NULL;
        if (cod_type->kind != ML5_SORT) return NULL;
        /* Return sort(max(level_dom, level_cod)) */
        uint32_t max_level = dom_type->data.sort.level;
        if (cod_type->data.sort.level > max_level)
            max_level = cod_type->data.sort.level;
        return ml5_sort(NULL, max_level);
    }
    case ML5_LET: {
        ML5_Type *val_type = infer_type(env, ctx, expr->data.let_e.value);
        if (!val_type) return NULL;
        ctx->size++;
        ML5_Type *body_type = infer_type(env, ctx, expr->data.let_e.body);
        ctx->size--;
        return body_type;
    }
    }
    return NULL;
}

/* ── Environment ──────────────────────────────────────────────────── */

ML5_Status ml5_env_create(ML5_Env *env, uint32_t capacity) {
    env->constants = calloc(capacity, sizeof(ML5_Constant));
    if (!env->constants) return ML5_ERR_OOM;
    env->n_constants = 0;
    env->capacity = capacity;
    return ML5_OK;
}

ML5_Status ml5_env_add_axiom(ML5_Env *env, const char *name, const ML5_Type *type) {
    if (env->n_constants >= env->capacity) return ML5_ERR_OOM;
    ML5_Constant *c = &env->constants[env->n_constants++];
    c->id = env->n_constants - 1;
    c->type = *type;
    c->definition = NULL;
    c->is_axiom = 1;
    (void)name;
    return ML5_OK;
}

ML5_Status ml5_env_add_definition(ML5_Env *env, const char *name, const ML5_Type *type, const ML5_Expr *def) {
    if (env->n_constants >= env->capacity) return ML5_ERR_OOM;
    ML5_Constant *c = &env->constants[env->n_constants++];
    c->id = env->n_constants - 1;
    c->type = *type;
    c->definition = (ML5_Expr *)def;
    c->is_axiom = 0;
    (void)name;
    return ML5_OK;
}

void ml5_env_destroy(ML5_Env *env) {
    free(env->constants);
    env->constants = NULL;
    env->n_constants = 0;
}

/* ── Proof Verification ───────────────────────────────────────────── */

ML5_Status ml5_verify_proof(const ML5_Env *env, const ML5_Expr *proof, const ML5_Type *theorem) {
    ML5_LocalCtx ctx = {0};
    ML5_Type inferred;
    ML5_Status status = ml5_typecheck(env, &ctx, proof, &inferred);
    if (status != ML5_OK) return status;

    ML5_Arena tmp;
    if (ml5_arena_create(&tmp, 1 << 16) != ML5_OK) return ML5_ERR_OOM;

    ML5_Env env_mut = *env;
    int ok = ml5_convertible(&env_mut, &ctx, &inferred, theorem);
    ml5_arena_destroy(&tmp);

    return ok ? ML5_OK : ML5_ERR_TYPE;
}
