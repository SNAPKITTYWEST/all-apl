use sha2::{Sha256, Digest};
use serde::{Serialize, Deserialize};

pub const BOOLEAN_REGEX: &str = r"^(VALID|INVALID) (sha256:[a-f0-9]{64})$";

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OracleOutput {
    pub valid: bool,
    pub receipt_hash: String,
    pub raw: String,
}

pub fn parse_boolean_output(text: &str) -> Result<OracleOutput, String> {
    let text = text.trim();
    let parts: Vec<&str> = text.splitn(2, ' ').collect();
    if parts.len() != 2 { return Err(format!("Format violation: {}", &text[..80.min(text.len())])); }
    let status = parts[0];
    let receipt = parts[1];
    if status != "VALID" && status != "INVALID" { return Err(format!("Invalid status: {}", status)); }
    if !receipt.starts_with("sha256:") { return Err("Missing sha256 prefix".into()); }
    if receipt.len() != 71 { return Err(format!("Bad receipt length: {}", receipt.len())); }
    Ok(OracleOutput { valid: status == "VALID", receipt_hash: receipt.to_string(), raw: text.to_string() })
}

pub fn make_receipt_hash(status: &str, proof: &str) -> String {
    let payload = format!("{}:{}", status, proof);
    let mut hasher = Sha256::new();
    hasher.update(payload.as_bytes());
    format!("sha256:{:x}", hasher.finalize())
}

pub fn prolog_fallback(proof_text: &str) -> bool {
    let lines: Vec<&str> = proof_text.lines().map(|l| l.trim()).filter(|l| !l.is_empty() && !l.starts_with('#')).collect();
    let has_sorry = lines.iter().any(|l| l.to_lowercase().contains("sorry"));
    if has_sorry { return false; }
    let has_empty = lines.iter().any(|l| {
        let tokens: Vec<&str> = l.split_whitespace().collect();
        tokens.len() >= 3 && tokens[1] == "from"
    });
    has_empty
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_valid() {
        let r = parse_boolean_output("VALID sha256:abc123def456abc123def456abc123def456abc123def456abc123def456abcd").unwrap();
        assert!(r.valid);
        assert!(r.receipt_hash.starts_with("sha256:"));
    }

    #[test]
    fn test_parse_invalid() {
        let r = parse_boolean_output("INVALID sha256:abc123def456abc123def456abc123def456abc123def456abc123def456abcd").unwrap();
        assert!(!r.valid);
    }

    #[test]
    fn test_parse_format_error() {
        assert!(parse_boolean_output("GARBAGE").is_err());
    }

    #[test]
    fn test_receipt_hash() {
        let h = make_receipt_hash("VALID", "test");
        assert!(h.starts_with("sha256:"));
        assert_eq!(h.len(), 71);
    }

    #[test]
    fn test_prolog_fallback_valid() {
        assert!(prolog_fallback("0 ~P Q\n1 P\n2 Q from 0 1\n3 from 2\n"));
    }

    #[test]
    fn test_prolog_fallback_sorry() {
        assert!(!prolog_fallback("0 P(a)\n1 sorry Q(a)\n2 from 0 1\n"));
    }
}
