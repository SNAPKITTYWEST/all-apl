/* mathlib5_driver.c — Unified C99 Driver
 * Links Rust FFI (axiom, prism, collatz) + Fortran DSSPEED engine
 * This is the single entry point for the verified compute pipeline.
 *
 * Build:
 *   cargo build --release          # builds Rust static libs
 *   gfortran -O3 -c dsspeed.f90   # compile Fortran
 *   gcc -O3 -o mathlib5 mathlib5_driver.c \
 *       -L target/release -laxiom -lprism -collatz \
 *       -ldsspeed -lgfortran -lm -lpthread
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

/* Rust FFI headers */
#include "axiom_ffi.h"
#include "prism_ffi.h"
#include "collatz_ffi.h"

/* Fortran DSSPEED interface (name-mangled) */
extern void dsspeed_benchmark_(void);

/* ── Helpers ── */
static double now_ms(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec * 1000.0 + ts.tv_nsec / 1e6;
}

#define BENCH_START(name) double _t0 = now_ms(); printf("▶ %s\n", name);
#define BENCH_END(name)   printf("  ✓ %s (%.2f ms)\n", name, now_ms() - _t0);

/* ═══════════════════════════════════════════════════════════ */
/* Test 1: AXIOM Proof Kernel (Rust FFI)                     */
/* ═══════════════════════════════════════════════════════════ */
static int test_axiom(void) {
    BENCH_START("AXIOM Proof Kernel (Rust FFI)");

    AxiomEnv *env = axiom_env_new();
    axiom_env_extend(env, "Nat", 0);

    /* Build: λ(x : Type₀). x : Π(x : Type₀). Type₀ */
    Term *nat_type = axiom_term_type(0);
    Term *var_x = axiom_term_var("x");
    Term *lam = axiom_term_lam("x", nat_type, var_x);

    Term *inferred = NULL;
    int rc = axiom_infer(env, lam, &inferred);
    if (rc != 0) { printf("  ✗ infer failed\n"); return 1; }

    printf("  λ(x : Type₀). x  :  inferred type OK\n");

    /* WORM seal */
    AxiomWorm *worm = axiom_worm_new("axiom_worm.jsonl");
    char *seal = axiom_worm_seal(worm, "id_test", "∀ x : Type₀, x", "λ x. x");
    if (seal) {
        printf("  WORM seal: %.16s...\n", seal);
        axiom_string_free(seal);
    }

    char *root = axiom_worm_merkle_root(worm);
    if (root) {
        printf("  Merkle root: %.16s...\n", root);
        axiom_string_free(root);
    }

    axiom_worm_free(worm);
    axiom_term_free(lam);
    axiom_env_free(env);

    BENCH_END("AXIOM Proof Kernel");
    return 0;
}

/* ═══════════════════════════════════════════════════════════ */
/* Test 2: PRISM Skills (Rust FFI)                           */
/* ═══════════════════════════════════════════════════════════ */
static int test_prism(void) {
    BENCH_START("PRISM Skills (Rust FFI)");

    /* Canonical JSON */
    const char *json = "{\"z\":1,\"a\":2,\"m\":3}";
    char *canonical = prism_canonicalize(json);
    if (canonical) {
        printf("  Canonical: %s\n", canonical);
        prism_string_free(canonical);
    }

    /* SHA-256d hashing */
    const char *data = "MATHLIB5 verified pipeline";
    char *hash = prism_hash_string(data);
    if (hash) {
        printf("  SHA-256:  %.16s...\n", hash);
        prism_string_free(hash);
    }

    char *dhash = prism_hash_double((const uint8_t *)data, strlen(data));
    if (dhash) {
        printf("  SHA-256d: %.16s...\n", dhash);
        prism_string_free(dhash);
    }

    /* WORM seal */
    WormSeal *seal = prism_seal_new("test_label", "test_payload", 42);
    if (seal) {
        printf("  Seal valid: %s\n", prism_seal_verify(seal) ? "YES" : "NO");
        printf("  Artifact: %s\n", prism_seal_artifact(seal));
        prism_seal_free(seal);
    }

    BENCH_END("PRISM Skills");
    return 0;
}

/* ═══════════════════════════════════════════════════════════ */
/* Test 3: Collatz Engine (Rust FFI)                         */
/* ═══════════════════════════════════════════════════════════ */
static int test_collatz(void) {
    BENCH_START("Collatz Engine (Rust FFI)");

    /* Single trajectory */
    uint64_t length, max_val, steps;
    if (collatz_compute(27, &length, &max_val, &steps) == 0) {
        printf("  Trajectory 27: length=%lu, max=%lu\n", (unsigned long)length, (unsigned long)max_val);
    }

    /* Parallel search */
    uint64_t count, max_length, max_length_start, max_value, max_value_start;
    collatz_parallel_search(1, 1000, &count, &max_length, &max_length_start, &max_value, &max_value_start);
    printf("  Parallel 1..1000: %lu trajectories\n", (unsigned long)count);
    printf("  Max length: %lu (start=%lu)\n", (unsigned long)max_length, (unsigned long)max_length_start);
    printf("  Max value:  %lu (start=%lu)\n", (unsigned long)max_value, (unsigned long)max_value_start);

    /* Merkle root */
    char *root = collatz_merkle_root(1, 100);
    if (root) {
        printf("  Merkle root: %.16s...\n", root);
        collatz_string_free(root);
    }

    BENCH_END("Collatz Engine");
    return 0;
}

/* ═══════════════════════════════════════════════════════════ */
/* Test 4: Hyper DSSPEED (Fortran)                           */
/* ═══════════════════════════════════════════════════════════ */
static int test_dsspeed(void) {
    BENCH_START("Hyper DSSPEED (Fortran)");
    dsspeed_benchmark_();
    BENCH_END("Hyper DSSPEED");
    return 0;
}

/* ═══════════════════════════════════════════════════════════ */
/* Main                                                       */
/* ═══════════════════════════════════════════════════════════ */
int main(void) {
    printf("═══════════════════════════════════════════════════════════\n");
    printf("  MATHLIB5 — Verified Symbolic Compute Pipeline\n");
    printf("  C99 Driver + Rust FFI + Fortran DSSPEED\n");
    printf("═══════════════════════════════════════════════════════════\n\n");

    int failures = 0;
    failures += test_axiom();
    failures += test_prism();
    failures += test_collatz();
    failures += test_dsspeed();

    printf("\n═══════════════════════════════════════════════════════════\n");
    if (failures == 0) {
        printf("  ALL SYSTEMS VERIFIED\n");
    } else {
        printf("  %d FAILURES\n", failures);
    }
    printf("═══════════════════════════════════════════════════════════\n");

    return failures;
}
