/* collatz_ffi.h — Collatz Verification Engine C API
 * Parallel trajectory search with WORM sealing.
 * Call from C99, Fortran, or any FFI-capable language.
 */

#ifndef COLLATZ_FFI_H
#define COLLATZ_FFI_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* ── Single trajectory ── */
/* Returns 0 on success, fills out_length, out_max_value, out_steps */
int collatz_compute(uint64_t start,
                    uint64_t *out_length,
                    uint64_t *out_max_value,
                    uint64_t *out_steps);

/* ── Parallel search ── */
int collatz_parallel_search(uint64_t start, uint64_t end,
                            uint64_t *out_count,
                            uint64_t *out_max_length,
                            uint64_t *out_max_length_start,
                            uint64_t *out_max_value,
                            uint64_t *out_max_value_start);

/* ── Merkle root (caller frees with collatz_string_free) ── */
char *collatz_merkle_root(uint64_t start, uint64_t end);

/* ── WORM sealing ── */
int collatz_seal_range(uint64_t start, uint64_t end,
                       uint64_t **out_entries,
                       uint64_t *out_count);

/* ── String cleanup ── */
void collatz_string_free(char *s);

#ifdef __cplusplus
}
#endif

#endif /* COLLATZ_FFI_H */
