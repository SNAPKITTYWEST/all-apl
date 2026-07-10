use serde::{Serialize, Deserialize};
use std::fs;


#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SorryStatement {
    pub file: String,
    pub line: usize,
    pub context: String,
    pub difficulty: String,
    pub goal_text: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MaliceResult {
    pub refuted: bool,
    pub counterexample: Option<String>,
    pub model: Vec<(String, f64)>,
    pub severity: String,
    pub receipt_hash: String,
}

pub struct MaliceHarness;

impl MaliceHarness {
    pub fn new() -> Self { MaliceHarness }

    pub fn scan_sorry(&self, lean_file: &str) -> Vec<SorryStatement> {
        let content = match fs::read_to_string(lean_file) {
            Ok(c) => c,
            Err(_) => return vec![],
        };
        let lines: Vec<&str> = content.lines().collect();
        let mut sorrys = vec![];
        for (i, line) in lines.iter().enumerate() {
            if line.to_lowercase().contains("sorry") {
                let start = if i >= 5 { i - 5 } else { 0 };
                let end = (i + 6).min(lines.len());
                let context = lines[start..end].join("\n");
                let difficulty = self.classify_difficulty(&context);
                let goal = self.extract_goal(&lines, i);
                sorrys.push(SorryStatement {
                    file: lean_file.to_string(),
                    line: i + 1,
                    context,
                    difficulty,
                    goal_text: goal,
                });
            }
        }
        sorrys
    }

    fn classify_difficulty(&self, context: &str) -> String {
        let ctx = context.to_lowercase();
        if ctx.contains("nat") || ctx.contains("int") || ctx.contains("real") || ctx.contains(" + ") || ctx.contains(" * ") {
            if !ctx.contains("forall") && !ctx.contains("exists") {
                return "linear".into();
            }
        }
        if ctx.contains("ring") || ctx.contains("field") || ctx.contains("pow") { return "algebraic".into(); }
        if ctx.contains("forall") || ctx.contains("exists") { return "quantifier".into(); }
        "unknown".into()
    }

    fn extract_goal(&self, lines: &[&str], sorry_line: usize) -> String {
        for i in (0..=sorry_line).rev().take(20) {
            let line = lines[i].trim();
            if line.starts_with("have ") || line.starts_with("show ") || line.starts_with("theorem ") || line.starts_with("lemma ") {
                return line.to_string();
            }
        }
        lines[sorry_line].trim().to_string()
    }

    pub fn extract_linear_goals(&self, proof_text: &str) -> Vec<String> {
        proof_text.lines()
            .filter(|l| l.contains("<=") || l.contains(">=") || l.contains("= "))
            .map(|l| l.trim().to_string())
            .collect()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_classify_difficulty() {
        let h = MaliceHarness::new();
        assert_eq!(h.classify_difficulty("have h : 2 * x + 3 ≤ 10"), "linear");
        assert_eq!(h.classify_difficulty("forall x, P x"), "quantifier");
        assert_eq!(h.classify_difficulty("ring"), "algebraic");
        assert_eq!(h.classify_difficulty("some random stuff"), "unknown");
    }

    #[test]
    fn test_extract_goals() {
        let h = MaliceHarness::new();
        let goals = h.extract_linear_goals("(<= (+ (* 2 x) 3) 10)");
        assert!(!goals.is_empty());
    }
}
