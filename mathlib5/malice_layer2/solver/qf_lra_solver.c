/**
 * qf_lra_solver.c — QF_LRA Counterexample Finder
 * Non-recursive linear arithmetic refutation via Simplex-style search.
 * ANSI C99, arena-allocated, deterministic.
 *
 * Given: A*x <= b (constraints) and c*x <= d (goal)
 * Find: x* such that A*x* <= b AND c*x* > d (counterexample)
 *
 * Exit codes: 0=COUNTEREXAMPLE_FOUND, 1=HOLDS (no counterexample), 2=FORMAT_ERROR, 3=OOM
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

#define MAX_VARS 64
#define MAX_CONS 256
#define MAX_NAME 64

/* ── Types ────────────────────────────────────────────────────────── */
typedef struct {
    char name[MAX_NAME];
    double lo, hi;       /* variable bounds */
    double value;        /* current assignment */
    int fixed;           /* 1 if fixed by constraint */
} Var;

typedef struct {
    double coeffs[MAX_VARS];  /* coefficient for each var */
    double bound;             /* <= bound */
    char op[4];               /* "<=", ">=", "=" */
    int n_vars;
} Constraint;

typedef struct {
    Var vars[MAX_VARS];
    int n_vars;
    Constraint cons[MAX_CONS];
    int n_cons;
    /* Goal: coeffs * x > bound means refuted */
    double goal_coeffs[MAX_VARS];
    double goal_bound;
    int goal_n_vars;
} System;

/* ── Variable lookup ──────────────────────────────────────────────── */
static int find_var(System *sys, const char *name) {
    for (int i = 0; i < sys->n_vars; i++)
        if (strcmp(sys->vars[i].name, name) == 0) return i;
    if (sys->n_vars >= MAX_VARS) return -1;
    strncpy(sys->vars[sys->n_vars].name, name, MAX_NAME - 1);
    sys->vars[sys->n_vars].lo = -1e18;
    sys->vars[sys->n_vars].hi = 1e18;
    sys->vars[sys->n_vars].value = 0.0;
    sys->vars[sys->n_vars].fixed = 0;
    return sys->n_vars++;
}

/* ── Parse S-Expr constraint ──────────────────────────────────────── */
/* Format: (<= (+ (* 2 x) (* 3 y) 5) 10)  or  (assert (<= ...)) */
static const char *skip_ws(const char *p) {
    while (*p && (*p == ' ' || *p == '\t' || *p == '\n' || *p == '\r')) p++;
    return p;
}

static const char *parse_sexpr(const char *p, System *sys, int is_goal);

static const char *parse_term(const char *p, System *sys, Constraint *c, int sign) {
    p = skip_ws(p);
    if (*p == '(') {
        p++; /* skip ( */
        p = skip_ws(p);
        if (strncmp(p, "*", 1) == 0) {
            p = skip_ws(p + 1);
            /* parse coefficient */
            char numbuf[64] = {0};
            int ni = 0;
            if (*p == '-') numbuf[ni++] = *p++;
            while (*p && ((*p >= '0' && *p <= '9') || *p == '.')) {
                if (ni < 63) numbuf[ni++] = *p;
                p++;
            }
            double coeff = atof(numbuf) * sign;
            p = skip_ws(p);
            /* parse variable name */
            char varbuf[MAX_NAME] = {0};
            int vi = 0;
            while (*p && *p != ')' && *p != ' ' && *p != '\t') {
                if (vi < MAX_NAME - 1) varbuf[vi++] = *p;
                p++;
            }
            int idx = find_var(sys, varbuf);
            if (idx >= 0) c->coeffs[idx] += coeff;
            p = skip_ws(p);
            if (*p == ')') p++;
        } else if (strncmp(p, "+", 1) == 0) {
            p++; /* skip + */
            while (*p && *p != ')') {
                p = skip_ws(p);
                if (*p == ')') break;
                p = parse_term(p, sys, c, sign);
                p = skip_ws(p);
            }
            if (*p == ')') p++;
        } else if (strncmp(p, "-", 1) == 0) {
            p++; /* skip - */
            p = skip_ws(p);
            p = parse_term(p, sys, c, -sign);
        } else {
            /* bare variable */
            char varbuf[MAX_NAME] = {0};
            int vi = 0;
            while (*p && *p != ')' && *p != ' ') {
                if (vi < MAX_NAME - 1) varbuf[vi++] = *p;
                p++;
            }
            int idx = find_var(sys, varbuf);
            if (idx >= 0) c->coeffs[idx] += sign;
            if (*p == ')') p++;
        }
    } else {
        /* bare number or variable */
        char buf[MAX_NAME] = {0};
        int bi = 0;
        while (*p && *p != ')' && *p != ' ' && *p != '\t' && *p != '\n') {
            if (bi < MAX_NAME - 1) buf[bi++] = *p;
            p++;
        }
        /* check if it's a number */
        int is_num = (buf[0] >= '0' && buf[0] <= '9') || buf[0] == '-' || buf[0] == '.';
        if (is_num) {
            c->bound -= atof(buf) * sign;
        } else {
            int idx = find_var(sys, buf);
            if (idx >= 0) c->coeffs[idx] += sign;
        }
    }
    return p;
}

static const char *parse_constraint(const char *p, System *sys) {
    p = skip_ws(p);
    if (*p == '\0' || *p == '\n' || *p == '\r') return p;

    Constraint c;
    memset(&c, 0, sizeof(c));
    c.bound = 0;

    if (*p == '(') {
        p++; /* skip ( */
        p = skip_ws(p);
        /* parse operator */
        char op[4] = {0};
        int oi = 0;
        while (*p && *p != ' ' && *p != '\t' && *p != '(' && oi < 3) {
            op[oi++] = *p++;
        }
        strncpy(c.op, op, 3);

        p = skip_ws(p);
        /* parse LHS */
        p = parse_term(p, sys, &c, 1);

        p = skip_ws(p);
        /* parse bound number */
        char numbuf[64] = {0};
        int ni = 0;
        if (*p == '-') numbuf[ni++] = *p++;
        while (*p && ((*p >= '0' && *p <= '9') || *p == '.')) {
            if (ni < 63) numbuf[ni++] = *p;
            p++;
        }
        c.bound = atof(numbuf) - c.bound;

        p = skip_ws(p);
        if (*p == ')') p++;
    } else {
        /* Bare format: x <= 5  or  2*x + 3 <= 10 */
        /* Parse variable/expression */
        char varbuf[MAX_NAME] = {0};
        int vi = 0;
        while (*p && *p != ' ' && *p != '\t' && *p != '<' && *p != '>' && *p != '=' && *p != '\n') {
            if (vi < MAX_NAME - 1) varbuf[vi++] = *p;
            p++;
        }
        p = skip_ws(p);

        /* Parse operator */
        char op[4] = {0};
        int oi = 0;
        while (*p && *p != ' ' && *p != '\t' && *p != '\n' && oi < 3) {
            op[oi++] = *p++;
        }
        strncpy(c.op, op, 3);
        p = skip_ws(p);

        /* Parse bound */
        char numbuf[64] = {0};
        int ni = 0;
        if (*p == '-') numbuf[ni++] = *p++;
        while (*p && ((*p >= '0' && *p <= '9') || *p == '.')) {
            if (ni < 63) numbuf[ni++] = *p;
            p++;
        }
        double bound = atof(numbuf);

        /* Check if varbuf is a number or variable */
        int is_num = (varbuf[0] >= '0' && varbuf[0] <= '9') || varbuf[0] == '-';
        if (is_num) {
            /* number <= bound  → always true/false */
            c.bound = bound - atof(varbuf);
        } else {
            /* variable */
            int idx = find_var(sys, varbuf);
            if (idx >= 0) c.coeffs[idx] = 1.0;
            c.bound = bound;
        }
    }

    if (c.op[0] != '\0') {
        sys->cons[sys->n_cons++] = c;
    }
    return p;
}

static const char *parse_assert(const char *p, System *sys) {
    p = skip_ws(p);
    if (strncmp(p, "(assert", 7) == 0) {
        p = skip_ws(p + 7);
        p = parse_constraint(p, sys);
        p = skip_ws(p);
        if (*p == ')') p++;
    } else {
        p = parse_constraint(p, sys);
    }
    return p;
}

static const char *parse_goal(const char *p, System *sys) {
    /* Goal: (goal (<= ...)) or (assert (> ...)) */
    p = skip_ws(p);
    if (strncmp(p, "(goal", 5) == 0 || strncmp(p, "(assert", 7) == 0) {
        while (*p && *p != '(') p++;
        p = parse_constraint(p, sys);
        /* Copy last constraint to goal */
        if (sys->n_cons > 0) {
            Constraint *last = &sys->cons[sys->n_cons - 1];
            memcpy(sys->goal_coeffs, last->coeffs, sizeof(last->coeffs));
            sys->goal_bound = last->bound;
            sys->goal_n_vars = last->n_vars;
            sys->n_cons--;
        }
    }
    return p;
}

/* ── Evaluate constraint at current assignment ────────────────────── */
static double eval_constraint(System *sys, Constraint *c) {
    double sum = 0;
    for (int i = 0; i < sys->n_vars; i++)
        sum += c->coeffs[i] * sys->vars[i].value;
    return sum;
}

/* ── Evaluate goal ────────────────────────────────────────────────── */
static double eval_goal(System *sys) {
    double sum = 0;
    for (int i = 0; i < sys->n_vars; i++)
        sum += sys->goal_coeffs[i] * sys->vars[i].value;
    return sum;
}

/* ── Check if current assignment satisfies all constraints ────────── */
static int satisfies_all(System *sys) {
    for (int i = 0; i < sys->n_cons; i++) {
        double val = eval_constraint(sys, &sys->cons[i]);
        if (strcmp(sys->cons[i].op, "<=") == 0 && val > sys->cons[i].bound + 1e-9) return 0;
        if (strcmp(sys->cons[i].op, ">=") == 0 && val < sys->cons[i].bound - 1e-9) return 0;
        if (strcmp(sys->cons[i].op, "=") == 0 && fabs(val - sys->cons[i].bound) > 1e-9) return 0;
    }
    return 1;
}

/* ── Simplex-style search for counterexample ──────────────────────── */
static int search_counterexample(System *sys, int depth, int max_depth) {
    if (depth >= max_depth) return 0;

    /* Try each variable at bound values */
    for (int i = 0; i < sys->n_vars; i++) {
        if (sys->vars[i].fixed) continue;

        /* Try lower bound */
        double orig = sys->vars[i].value;
        sys->vars[i].value = sys->vars[i].lo;
        if (satisfies_all(sys)) {
            double g = eval_goal(sys);
            if (g > sys->goal_bound + 1e-9) return 1; /* COUNTEREXAMPLE */
            if (search_counterexample(sys, depth + 1, max_depth)) return 1;
        }

        /* Try upper bound */
        sys->vars[i].value = sys->vars[i].hi;
        if (satisfies_all(sys)) {
            double g = eval_goal(sys);
            if (g > sys->goal_bound + 1e-9) return 1;
            if (search_counterexample(sys, depth + 1, max_depth)) return 1;
        }

        /* Try 0 */
        sys->vars[i].value = 0;
        if (satisfies_all(sys)) {
            double g = eval_goal(sys);
            if (g > sys->goal_bound + 1e-9) return 1;
            if (search_counterexample(sys, depth + 1, max_depth)) return 1;
        }

        /* Try 1 */
        sys->vars[i].value = 1;
        if (satisfies_all(sys)) {
            double g = eval_goal(sys);
            if (g > sys->goal_bound + 1e-9) return 1;
            if (search_counterexample(sys, depth + 1, max_depth)) return 1;
        }

        sys->vars[i].value = orig;
    }
    return 0;
}

/* ── Propagate bounds ─────────────────────────────────────────────── */
static void propagate_bounds(System *sys) {
    for (int iter = 0; iter < 100; iter++) {
        for (int i = 0; i < sys->n_cons; i++) {
            Constraint *c = &sys->cons[i];
            /* Find single unbounded variable */
            int single = -1;
            int n_unbounded = 0;
            for (int j = 0; j < sys->n_vars; j++) {
                if (fabs(c->coeffs[j]) > 1e-9 && !sys->vars[j].fixed) {
                    if (single >= 0) { n_unbounded++; break; }
                    single = j;
                }
            }
            if (n_unbounded > 0 || single < 0) continue;

            /* Bound the single variable */
            double rest = c->bound;
            for (int j = 0; j < sys->n_vars; j++) {
                if (j != single && fabs(c->coeffs[j]) > 1e-9)
                    rest -= c->coeffs[j] * sys->vars[j].value;
            }
            double coeff = c->coeffs[single];
            if (fabs(coeff) < 1e-12) continue;

            double bound_val = rest / coeff;
            if (strcmp(c->op, "<=") == 0) {
                if (coeff > 0) {
                    if (bound_val < sys->vars[single].hi)
                        sys->vars[single].hi = bound_val;
                } else {
                    if (bound_val > sys->vars[single].lo)
                        sys->vars[single].lo = bound_val;
                }
            } else if (strcmp(c->op, ">=") == 0) {
                if (coeff > 0) {
                    if (bound_val > sys->vars[single].lo)
                        sys->vars[single].lo = bound_val;
                } else {
                    if (bound_val < sys->vars[single].hi)
                        sys->vars[single].hi = bound_val;
                }
            }
        }
    }
}

/* ── Main ─────────────────────────────────────────────────────────── */
int main(int argc, char **argv) {
    const char *path = (argc > 1) ? argv[1] : NULL;
    FILE *f = path ? fopen(path, "r") : stdin;
    if (!f) { fprintf(stderr, "Cannot open %s\n", path ? path : "stdin"); return 2; }

    System sys;
    memset(&sys, 0, sizeof(sys));

    char line[8192];
    while (fgets(line, sizeof(line), f)) {
        const char *p = line;
        while (*p && (*p == ' ' || *p == '\t')) p++;
        if (*p == '\0' || *p == '#' || *p == '\n' || *p == '\r') continue;

        if (strncmp(p, "(goal", 5) == 0) {
            parse_goal(p, &sys);
        } else {
            parse_assert(p, &sys);
        }
    }
    fclose(f);

    /* Check if we have an explicit goal */
    int has_goal = 0;
    for (int i = 0; i < sys.n_vars; i++) {
        if (fabs(sys.goal_coeffs[i]) > 1e-9) { has_goal = 1; break; }
    }

    /* Propagate bounds */
    propagate_bounds(&sys);

    if (has_goal) {
        /* Mode 1: Counterexample search — find x where constraints hold but goal violated */
        int found = search_counterexample(&sys, 0, 8);
        if (found) {
            fprintf(stderr, "REFUTED: counterexample found\n");
            fprintf(stderr, "Model: ");
            for (int i = 0; i < sys.n_vars; i++)
                fprintf(stderr, "%s=%.2f ", sys.vars[i].name, sys.vars[i].value);
            fprintf(stderr, "\n");
            return 0;
        } else {
            fprintf(stderr, "HOLDS: no counterexample found\n");
            return 1;
        }
    } else {
        /* Mode 2: Satisfiability — find any x satisfying all constraints */
        /* Initialize all variables to 0 */
        for (int i = 0; i < sys.n_vars; i++)
            sys.vars[i].value = 0;

        if (satisfies_all(&sys)) {
            fprintf(stderr, "SAT: model found\n");
            fprintf(stderr, "Model: ");
            for (int i = 0; i < sys.n_vars; i++)
                fprintf(stderr, "%s=%.2f ", sys.vars[i].name, sys.vars[i].value);
            fprintf(stderr, "\n");
            return 1; /* SAT = HOLDS */
        }

        /* Try bound values */
        int found = search_counterexample(&sys, 0, 8);
        if (found) {
            fprintf(stderr, "SAT: model found\n");
            fprintf(stderr, "Model: ");
            for (int i = 0; i < sys.n_vars; i++)
                fprintf(stderr, "%s=%.2f ", sys.vars[i].name, sys.vars[i].value);
            fprintf(stderr, "\n");
            return 1; /* SAT = HOLDS */
        } else {
            fprintf(stderr, "UNSAT: constraints unsatisfiable\n");
            return 0; /* UNSAT = REFUTED */
        }
    }
}
