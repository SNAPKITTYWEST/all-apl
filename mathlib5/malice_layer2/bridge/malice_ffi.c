/**
 * malice_ffi.c — C99 FFI Bridge for Malice Adversarial Layer
 * Connects QF_LRA solver to Python/Lean.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Forward declare from qf_lra_solver.c */
/* In production, compile together or use header */

typedef struct {
    int refuted;      /* 1 = counterexample found, 0 = holds */
    char model[2048]; /* variable assignments */
    char error[512];
} MaliceResult;

/**
 * Run QF_LRA refutation on a proof containing sorry statements.
 * Input: path to proof file with linear arithmetic goals.
 * Output: MaliceResult with counterexample or HOLD status.
 */
MaliceResult malice_refute_proof(const char *proof_path) {
    MaliceResult res;
    memset(&res, 0, sizeof(res));

    FILE *f = fopen(proof_path, "r");
    if (!f) {
        snprintf(res.error, sizeof(res.error), "Cannot open %s", proof_path);
        return res;
    }

    /* Extract linear arithmetic goals from proof */
    char line[8192];
    int n_goals = 0;

    while (fgets(line, sizeof(line), f)) {
        /* Look for patterns like: "have ... ≤ ..." or "assert (<= ...)" */
        if (strstr(line, "sorry") || strstr(line, "<=") || strstr(line, ">=")) {
            n_goals++;
        }
    }
    fclose(f);

    if (n_goals == 0) {
        snprintf(res.error, sizeof(res.error), "No linear arithmetic goals found");
        return res;
    }

    /* Run solver */
    char cmd[1024];
    snprintf(cmd, sizeof(cmd), "./qf_lra_solver %s", proof_path);
    int rc = system(cmd);

    if (rc == 0) {
        res.refuted = 1;
        snprintf(res.model, sizeof(res.model), "Counterexample found in %d goals", n_goals);
    } else if (rc == 1) {
        res.refuted = 0;
        snprintf(res.model, sizeof(res.model), "All %d goals hold", n_goals);
    } else {
        snprintf(res.error, sizeof(res.error), "Solver failed with code %d", rc);
    }

    return res;
}

/**
 * FFI entry point: validate a single QF_LRA constraint.
 * Input: S-Expr like "(<= (+ (* 2 x) 3) 10)"
 * Output: 0=COUNTEREXAMPLE, 1=HOLDS, 2=ERROR
 */
int malice_check_constraint(const char *constraint_sexpr, char *model_out, int model_out_len) {
    char tmpfile[] = "/tmp/malice_constraint_XXXXXX";
    FILE *f = tmpfile ? fopen(tmpfile, "w") : NULL;
    if (!f) return 2;

    fprintf(f, "%s\n", constraint_sexpr);
    fclose(f);

    char cmd[512];
    snprintf(cmd, sizeof(cmd), "./qf_lra_solver %s 2>&1", tmpfile);
    FILE *pipe = popen(cmd, "r");
    if (!pipe) { unlink(tmpfile); return 2; }

    char buf[2048] = {0};
    fread(buf, 1, sizeof(buf) - 1, pipe);
    int rc = pclose(pipe);
    unlink(tmpfile);

    if (model_out && model_out_len > 0) {
        strncpy(model_out, buf, model_out_len - 1);
    }

    return (rc >> 8) & 0xFF; /* Extract exit code */
}
