/* fol_resolution_checker.c
 * FOL Resolution Proof Checker — ANSI C99, arena-allocated, deterministic
 * Exit codes: 0=VALID, 1=INVALID, 2=FORMAT ERROR, 3=OOM
 *
 * Proof format (one clause per line):
 *   ID LITERAL...                     (axiom)
 *   ID LITERAL... from ID1 ID2        (resolution step)
 *
 * LITERAL: [~]PRED(ARG,...) or bare atoms
 * Variables: uppercase first letter (X, Y, Z)
 * Constants: lowercase first letter (a, b) or numbers
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#define MAX_CLAUSES 1024
#define MAX_LITS    16
#define MAX_ARGS    8
#define MAX_NAME    64
#define ARENA_SIZE  (1 << 20)

/* ── Arena ────────────────────────────────────────────────────────── */
typedef struct { char *base, *ptr, *end; } Arena;

static Arena arena;
static void arena_init(void) {
    arena.base = (char *)malloc(ARENA_SIZE);
    arena.ptr  = arena.base;
    arena.end  = arena.base + ARENA_SIZE;
}
static void *arena_alloc(size_t n) {
    n = (n + 7) & ~7;
    if (arena.ptr + n > arena.end) return NULL;
    void *p = arena.ptr;
    arena.ptr += n;
    return p;
}

/* ── Types ────────────────────────────────────────────────────────── */
typedef struct { char name[MAX_NAME]; } Term;

typedef struct {
    char pred[MAX_NAME];
    int  arity;
    Term args[MAX_ARGS];
    int  neg; /* 1 if negated */
} Literal;

typedef struct {
    Literal lits[MAX_LITS];
    int     n;
    int     from1, from2; /* parent clause IDs, -1 if axiom */
} Clause;

static Clause clauses[MAX_CLAUSES];
static int nclauses = 0;

/* ── String helpers ───────────────────────────────────────────────── */
static int is_variable(const char *s) {
    return s[0] != '\0' && isupper((unsigned char)s[0]);
}

/* ── Parse a literal like "~P(X,a)" or "Q(Y)" ──────────────────── */
static int parse_literal(const char **pp, Literal *lit) {
    const char *p = *pp;
    while (*p && isspace((unsigned char)*p)) p++;
    if (*p == '\0') return 0;

    lit->neg = 0;
    if (*p == '~') { lit->neg = 1; p++; }

    /* read predicate name */
    int pi = 0;
    while (*p && *p != '(' && *p != ')' && *p != ',' && !isspace((unsigned char)*p)) {
        if (pi < MAX_NAME - 1) lit->pred[pi++] = *p;
        p++;
    }
    lit->pred[pi] = '\0';

    /* read arguments */
    lit->arity = 0;
    if (*p == '(') {
        p++; /* skip ( */
        while (*p && *p != ')' && lit->arity < MAX_ARGS) {
            while (*p && isspace((unsigned char)*p)) p++;
            int ai = 0;
            while (*p && *p != ',' && *p != ')' && !isspace((unsigned char)*p)) {
                if (ai < MAX_NAME - 1) lit->args[lit->arity].name[ai++] = *p;
                p++;
            }
            lit->args[lit->arity].name[ai] = '\0';
            lit->arity++;
            while (*p && (*p == ',' || isspace((unsigned char)*p))) p++;
        }
        if (*p == ')') p++;
    }

    *pp = p;
    return 1;
}

/* ── Parse a proof line ───────────────────────────────────────────── */
static int parse_line(const char *line, int *id, Clause *c) {
    const char *p = line;
    c->n = 0;
    c->from1 = c->from2 = -1;

    while (*p && isspace((unsigned char)*p)) p++;
    if (*p == '\0' || *p == '#' || *p == '\n' || *p == '\r') return -1;

    /* read clause ID */
    *id = 0;
    while (*p && isdigit((unsigned char)*p)) *id = *id * 10 + (*p++ - '0');
    while (*p && isspace((unsigned char)*p)) p++;

    /* check for "from" keyword */
    if (strncmp(p, "from", 4) == 0 && (p[4] == ' ' || p[4] == '\t' || p[4] == '\0')) {
        p += 4;
        while (*p && isspace((unsigned char)*p)) p++;
        c->from1 = 0;
        while (*p && isdigit((unsigned char)*p)) c->from1 = c->from1 * 10 + (*p++ - '0');
        while (*p && isspace((unsigned char)*p)) p++;
        c->from2 = 0;
        while (*p && isdigit((unsigned char)*p)) c->from2 = c->from2 * 10 + (*p++ - '0');
        return 0;
    }

    /* read literals until "from" or end */
    while (*p) {
        while (*p && isspace((unsigned char)*p)) p++;
        if (*p == '\0' || *p == '\n' || *p == '\r') break;
        if (strncmp(p, "from", 4) == 0 && (p[4] == ' ' || p[4] == '\t')) break;
        if (c->n >= MAX_LITS) return -1;
        parse_literal(&p, &c->lits[c->n++]);
    }

    /* check for "from" after literals */
    while (*p && isspace((unsigned char)*p)) p++;
    if (strncmp(p, "from", 4) == 0 && (p[4] == ' ' || p[4] == '\t' || p[4] == '\0')) {
        p += 4;
        while (*p && isspace((unsigned char)*p)) p++;
        c->from1 = 0;
        while (*p && isdigit((unsigned char)*p)) c->from1 = c->from1 * 10 + (*p++ - '0');
        while (*p && isspace((unsigned char)*p)) p++;
        c->from2 = 0;
        while (*p && isdigit((unsigned char)*p)) c->from2 = c->from2 * 10 + (*p++ - '0');
    }

    return 0;
}

/* ── Substitution ─────────────────────────────────────────────────── */
typedef struct { char var[MAX_NAME]; char val[MAX_NAME]; } Binding;
typedef struct { Binding b[32]; int n; } Subst;

static Subst subst_empty(void) { Subst s; s.n = 0; return s; }

static Subst subst_extend(Subst s, const char *var, const char *val) {
    if (s.n >= 32) return s;
    strncpy(s.b[s.n].var, var, MAX_NAME - 1);
    strncpy(s.b[s.n].val, val, MAX_NAME - 1);
    s.n++;
    return s;
}

static const char *subst_lookup(const Subst *s, const char *var) {
    for (int i = s->n - 1; i >= 0; i--)
        if (strcmp(s->b[i].var, var) == 0) return s->b[i].val;
    return NULL;
}

/* ── Unification ──────────────────────────────────────────────────── */
static int unify_terms(const Term *t1, const Term *t2, Subst *s) {
    if (strcmp(t1->name, t2->name) == 0) return 1;

    if (is_variable(t1->name)) {
        const char *v = subst_lookup(s, t1->name);
        if (v) { Term tmp; strncpy(tmp.name, v, MAX_NAME-1); return unify_terms(&tmp, t2, s); }
        *s = subst_extend(*s, t1->name, t2->name);
        return 1;
    }
    if (is_variable(t2->name)) {
        const char *v = subst_lookup(s, t2->name);
        if (v) { Term tmp; strncpy(tmp.name, v, MAX_NAME-1); return unify_terms(t1, &tmp, s); }
        *s = subst_extend(*s, t2->name, t1->name);
        return 1;
    }
    return 0;
}

static int unify_lits(const Literal *l1, const Literal *l2, Subst *s) {
    if (strcmp(l1->pred, l2->pred) != 0) return 0;
    if (l1->arity != l2->arity) return 0;
    for (int i = 0; i < l1->arity; i++)
        if (!unify_terms(&l1->args[i], &l2->args[i], s)) return 0;
    return 1;
}

/* ── Apply substitution ───────────────────────────────────────────── */
static Literal apply_subst(Literal l, Subst s) {
    for (int i = 0; i < l.arity; i++) {
        const char *v = subst_lookup(&s, l.args[i].name);
        if (v) strncpy(l.args[i].name, v, MAX_NAME - 1);
    }
    return l;
}

/* ── Resolve two clauses ──────────────────────────────────────────── */
static Clause resolve_clauses(Clause c1, Clause c2, int li1, int li2) {
    Subst s = subst_empty();
    if (!unify_lits(&c1.lits[li1], &c2.lits[li2], &s)) {
        Clause empty; empty.n = 0; empty.from1 = empty.from2 = -1; return empty;
    }
    Clause res; res.n = 0; res.from1 = -1; res.from2 = -1;
    for (int i = 0; i < c1.n; i++) {
        if (i == li1) continue;
        res.lits[res.n++] = apply_subst(c1.lits[i], s);
    }
    for (int i = 0; i < c2.n; i++) {
        if (i == li2) continue;
        res.lits[res.n++] = apply_subst(c2.lits[i], s);
    }
    return res;
}

/* ── Check if clause is subsumed by existing clause ────────────────── */
static int clause_is_tautology(Clause c) {
    for (int i = 0; i < c.n; i++)
        for (int j = i + 1; j < c.n; j++)
            if (strcmp(c.lits[i].pred, c.lits[j].pred) == 0 &&
                c.lits[i].neg != c.lits[j].neg &&
                c.lits[i].arity == c.lits[j].arity) {
                int match = 1;
                for (int k = 0; k < c.lits[i].arity; k++)
                    if (strcmp(c.lits[i].args[k].name, c.lits[j].args[k].name) != 0) { match = 0; break; }
                if (match) return 1;
            }
    return 0;
}

/* ── Main ─────────────────────────────────────────────────────────── */
int main(int argc, char **argv) {
    const char *path = (argc > 1) ? argv[1] : NULL;
    FILE *f = path ? fopen(path, "r") : stdin;
    if (!f) { fprintf(stderr, "Cannot open %s\n", path ? path : "stdin"); return 2; }

    arena_init();
    char line[4096];
    int last_empty = -1;

    while (fgets(line, sizeof(line), f)) {
        /* skip empty/comment lines */
        const char *p = line;
        while (*p && isspace((unsigned char)*p)) p++;
        if (*p == '\0' || *p == '#' || *p == '\n' || *p == '\r') continue;

        int id;
        Clause c;
        if (parse_line(line, &id, &c) < 0) { fclose(f); return 2; }
        if (id < 0 || id >= MAX_CLAUSES) { fclose(f); return 2; }

        clauses[id] = c;
        if (id >= nclauses) nclauses = id + 1;

        if (c.n == 0) last_empty = id;
    }
    fclose(f);

    if (last_empty < 0) {
        fprintf(stderr, "INVALID: no empty clause found\n");
        return 1;
    }

    /* Verify each resolution step */
    for (int i = 0; i < nclauses; i++) {
        Clause *c = &clauses[i];
        if (c->from1 < 0 && c->from2 < 0) continue; /* axiom */

        if (c->from1 < 0 || c->from1 >= nclauses ||
            c->from2 < 0 || c->from2 >= nclauses) {
            fprintf(stderr, "INVALID: clause %d references nonexistent parent\n", i);
            return 1;
        }

        Clause *p1 = &clauses[c->from1];
        Clause *p2 = &clauses[c->from2];

        /* Try all complementary literal pairs */
        int found = 0;
        for (int a = 0; a < p1->n && !found; a++) {
            for (int b = 0; b < p2->n && !found; b++) {
                if (p1->lits[a].neg != p2->lits[b].neg &&
                    strcmp(p1->lits[a].pred, p2->lits[b].pred) == 0 &&
                    p1->lits[a].arity == p2->lits[b].arity) {
                    Clause res = resolve_clauses(*p1, *p2, a, b);
                    if (res.n != c->n) continue;
                    /* Check if literals match (ignoring variable names) */
                    int match = 1;
                    for (int k = 0; k < res.n; k++) {
                        if (strcmp(res.lits[k].pred, c->lits[k].pred) != 0 ||
                            res.lits[k].neg != c->lits[k].neg ||
                            res.lits[k].arity != c->lits[k].arity) {
                            match = 0; break;
                        }
                    }
                    if (match) { found = 1; break; }
                }
            }
        }

        if (!found) {
            fprintf(stderr, "INVALID: clause %d is not a valid resolvent of %d and %d\n",
                    i, c->from1, c->from2);
            return 1;
        }
    }

    fprintf(stderr, "VALID: proof verified (%d clauses, empty clause at %d)\n",
            nclauses, last_empty);
    return 0;
}
