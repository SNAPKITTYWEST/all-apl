/**
 * bridge_meta_oracle.c — FFI Bridge between Python and C Kernel
 * Exposes validate_proof() for Python ctypes / CFFI.
 */

#include "asp_validate.c"

/**
 * Validate a proof file. Returns 0=VALID, 1=INVALID, 2=FORMAT_ERROR.
 * Thread-safe: uses static clause array per call (or arena in production).
 */
int validate_proof(const char *proof_path) {
    /* Reset state */
    nclauses = 0;
    memset(clauses, 0, sizeof(clauses));
    return check_proof(proof_path);
}

/**
 * Validate proof from a string buffer (for in-memory proofs).
 * Writes buffer to temp file, validates, returns result.
 */
int validate_proof_buffer(const char *proof_text, int length) {
    char tmpname[] = "/tmp/oracle_proof_XXXXXX";
    int fd = -1;
    FILE *f = NULL;

    /* Use tmpfile as fallback */
    f = tmpfile();
    if (!f) return 2;
    fwrite(proof_text, 1, length, f);
    fflush(f);
    rewind(f);

    nclauses = 0;
    memset(clauses, 0, sizeof(clauses));

    char line[8192];
    int last_empty = -1;
    while (fgets(line, sizeof(line), f)) {
        const char *p = line;
        while (*p && isspace((unsigned char)*p)) p++;
        if (*p == '\0' || *p == '#' || *p == '\n' || *p == '\r') continue;
        int id;
        Clause c;
        if (parse_line(line, &id, &c) < 0) { fclose(f); return 2; }
        if (id < 0 || id >= MAX_CLAUSES) { fclose(f); return 2; }
        clauses[id] = c;
        if (id >= nclauses) nclauses = id + 1;
        if (c.n == 0 && c.from1 >= 0) last_empty = id;
    }
    fclose(f);
    if (last_empty < 0) return 1;

    for (int i = 0; i < nclauses; i++) {
        Clause *c = &clauses[i];
        if (c->from1 < 0) continue;
        if (c->from1 >= i || c->from2 >= i) return 1;
        if (c->from1 < 0 || c->from1 >= nclauses) return 1;
        if (c->from2 < 0 || c->from2 >= nclauses) return 1;
        Clause *p1 = &clauses[c->from1];
        Clause *p2 = &clauses[c->from2];
        int found = 0;
        for (int a = 0; a < p1->n && !found; a++) {
            for (int b = 0; b < p2->n && !found; b++) {
                if (p1->lits[a].neg != p2->lits[b].neg &&
                    strcmp(p1->lits[a].pred, p2->lits[b].pred) == 0 &&
                    p1->lits[a].arity == p2->lits[b].arity) {
                    Subst s; s.n = 0;
                    if (unify_lits(&p1->lits[a], &p2->lits[b], &s)) found = 1;
                }
            }
        }
        if (!found && c->n > 0) return 1;
    }
    return 0;
}
