/* prism_ffi.h — PRISM Skills C API
 * Canonical JSON, SHA-256d hashing, WORM sealing.
 * Call from C99, Fortran, or any FFI-capable language.
 */

#ifndef PRISM_FFI_H
#define PRISM_FFI_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Opaque type */
typedef struct WormSeal WormSeal;

/* ── Canonical JSON ── */
/* Returns sorted-key canonical form (caller frees with prism_string_free) */
char *prism_canonicalize(const char *json_str);

/* ── SHA-256 Hashing ── */
char *prism_hash_bytes(const uint8_t *data, size_t len);
char *prism_hash_string(const char *s);
char *prism_hash_double(const uint8_t *data, size_t len);
char *prism_snapsha256d(const uint8_t *data, size_t len);

/* ── WORM Seal ── */
WormSeal *prism_seal_new(const char *label, const char *payload, uint64_t steps);
int       prism_seal_verify(const WormSeal *seal);
char     *prism_seal_hash(const WormSeal *seal);
char     *prism_seal_artifact(const WormSeal *seal);
char     *prism_seal_content_hash(const WormSeal *seal);
void      prism_seal_free(WormSeal *seal);

/* ── String cleanup ── */
void prism_string_free(char *s);

#ifdef __cplusplus
}
#endif

#endif /* PRISM_FFI_H */
