/* axiom_ffi.h — AXIOM Proof Kernel C API
 * Call from C99, Fortran, or any FFI-capable language.
 * All pointers are opaque. Caller must free with axiom_string_free.
 */

#ifndef AXIOM_FFI_H
#define AXIOM_FFI_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Opaque types */
typedef struct AxiomEnv  AxiomEnv;
typedef struct AxiomWorm AxiomWorm;
typedef struct Term      Term;

/* ── Environment ── */
AxiomEnv *axiom_env_new(void);
void      axiom_env_free(AxiomEnv *env);
void      axiom_env_extend(AxiomEnv *env, const char *name, uint32_t level);

/* ── Term constructors ── */
Term *axiom_term_type(uint32_t level);
Term *axiom_term_var(const char *name);
Term *axiom_term_pi(const char *name, Term *arg_type, Term *body);
Term *axiom_term_lam(const char *name, Term *arg_type, Term *body);
Term *axiom_term_app(Term *func, Term *arg);
void  axiom_term_free(Term *term);

/* ── Type checking ── */
/* Returns 0 on success, -1 on error */
int   axiom_infer(const AxiomEnv *env, const Term *term, Term **out_type);
int   axiom_check(const AxiomEnv *env, const Term *term, const Term *expected);
int   axiom_def_eq(const AxiomEnv *env, const Term *t1, const Term *t2);
int   axiom_verify_proof(const AxiomEnv *env, const Term *theorem, const Term *proof);

/* ── WORM database ── */
AxiomWorm *axiom_worm_new(const char *path);
void       axiom_worm_free(AxiomWorm *worm);

/* Seal proof → returns seal hash (caller frees with axiom_string_free) */
char *axiom_worm_seal(AxiomWorm *worm,
                      const char *theorem_name,
                      const char *theorem,
                      const char *proof);

/* Verify → returns 1 if verified */
int   axiom_worm_verify(const AxiomWorm *worm,
                        const char *theorem_name,
                        const char *theorem,
                        const char *proof);

/* Merkle root (caller frees with axiom_string_free) */
char *axiom_worm_merkle_root(const AxiomWorm *worm);

/* ── String cleanup ── */
void  axiom_string_free(char *s);

#ifdef __cplusplus
}
#endif

#endif /* AXIOM_FFI_H */
