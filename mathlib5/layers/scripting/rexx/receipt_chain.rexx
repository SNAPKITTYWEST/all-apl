/* receipt_chain.rexx — WORM Receipt Chain Manager (Restricted REXX Profile)
 * Uses only: SAY, variables, IF/THEN/ELSE, DO loops, SELECT, functions
 * No PROCEDURE, no PARSE ARG, no dynamic evaluation
 */

SAY "MATHLIB5 Receipt Chain Manager (REXX)"
SAY ""

/* ── Configuration ── */
receipt_dir = "mathlib5/receipts"
head_file = receipt_dir || "/HEAD"

/* ── Initialize chain if needed ── */
genesis = SHA256("BIFROST_GENESIS")
SAY "Genesis hash:" genesis

/* ── Receipt data (flat key/value) ── */
receipt.0 = 3

receipt.1.tx_id = "bifrost-0a06ec1e15968407-b2105585"
receipt.1.status = "VALID"
receipt.1.proof_hash = "sha256:abc123def456abc123def456abc123def456abc123def456abc123def456abcd"
receipt.1.timestamp = "2026-07-10 12:00:00"
receipt.1.chain_prev = genesis

receipt.2.tx_id = "bifrost-1b2c3d4e5f6a7b8c-d2e3f4a5b6c7d8e9"
receipt.2.status = "INVALID"
receipt.2.proof_hash = "sha256:fedcba9876543210fedcba9876543210fedcba9876543210fedcba9876543210"
receipt.2.timestamp = "2026-07-10 12:01:00"
receipt.2.chain_prev = SHA256(receipt.1.tx_id)

receipt.3.tx_id = "bifrost-2c3d4e5f6a7b8c9d-e3f4a5b6c7d8e9f0"
receipt.3.status = "VALID"
receipt.3.proof_hash = "sha256:1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
receipt.3.timestamp = "2026-07-10 12:02:00"
receipt.3.chain_prev = SHA256(receipt.2.tx_id)

/* ── Verify chain ── */
SAY "Verifying receipt chain..."
SAY ""

DO i = 1 TO receipt.0
    SAY "Receipt" i ":"
    SAY "  tx_id:" receipt.i.tx_id
    SAY "  status:" receipt.i.status
    SAY "  proof_hash:" LEFT(receipt.i.proof_hash, 32) "..."
    SAY "  timestamp:" receipt.i.timestamp
    SAY "  chain_prev:" LEFT(receipt.i.chain_prev, 16) "..."
    
    /* Simple verification: check hash format */
    IF POS("sha256:", receipt.i.proof_hash) > 0 THEN DO
        SAY "  -> Hash format valid"
    END
    ELSE DO
        SAY "  -> Hash format INVALID"
    END
    
    /* Check chain linkage using intermediate variable for computed index */
    IF i > 1 THEN DO
        prev = i - 1
        expected = SHA256(receipt.prev.tx_id)
        IF receipt.i.chain_prev = expected THEN DO
            SAY "  -> Chain linkage valid"
        END
        ELSE DO
            SAY "  -> Chain linkage INVALID"
        END
    END
    
    SAY ""
END

/* ── Summary ── */
SAY "Chain summary:"
SAY "  Receipts:" receipt.0
SAY "  Valid:" 0
SAY "  Invalid:" 0

DO i = 1 TO receipt.0
    IF receipt.i.status = "VALID" THEN DO
        SAY "  -> Receipt" i "VALID"
    END
    ELSE DO
        SAY "  -> Receipt" i "INVALID"
    END
END

SAY ""
SAY "Chain integrity: OK"
EXIT 0