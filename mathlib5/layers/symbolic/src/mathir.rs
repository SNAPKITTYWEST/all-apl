use serde::{Serialize, Deserialize};

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum Domain {
    Real,
    Complex,
    Integer,
    Rational,
    Natural,
    Boolean,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum MathIR {
    Const { value: f64 },
    ConstSym { symbol: String },
    Var { id: String, domain: Domain },
    Add { terms: Vec<MathIR> },
    Mul { factors: Vec<MathIR> },
    Pow { base: Box<MathIR>, exponent: Box<MathIR> },
    Fn { name: String, args: Vec<MathIR> },
    Derivative { expr: Box<MathIR>, var: String },
    Integral { expr: Box<MathIR>, var: String, lower: Option<Box<MathIR>>, upper: Option<Box<MathIR>> },
    Limit { expr: Box<MathIR>, var: String, target: Box<MathIR>, dir: String },
    Eq { lhs: Box<MathIR>, rhs: Box<MathIR> },
    ForAll { var: String, domain: String, body: Box<MathIR> },
    Exists { var: String, domain: String, body: Box<MathIR> },
    And { terms: Vec<MathIR> },
    Or { terms: Vec<MathIR> },
    Not { expr: Box<MathIR> },
    Implies { lhs: Box<MathIR>, rhs: Box<MathIR> },
    Matrix { rows: Vec<Vec<MathIR>> },
}

pub fn const_val(v: f64) -> MathIR { MathIR::Const { value: v } }
pub fn const_sym(s: &str) -> MathIR { MathIR::ConstSym { symbol: s.to_string() } }
pub fn var(name: &str) -> MathIR { MathIR::Var { id: name.to_string(), domain: Domain::Real } }
pub fn add(terms: Vec<MathIR>) -> MathIR { MathIR::Add { terms } }
pub fn mul(factors: Vec<MathIR>) -> MathIR { MathIR::Mul { factors } }
pub fn pow(base: MathIR, exp: MathIR) -> MathIR { MathIR::Pow { base: Box::new(base), exponent: Box::new(exp) } }
pub fn fn_app(name: &str, args: Vec<MathIR>) -> MathIR { MathIR::Fn { name: name.to_string(), args } }
pub fn derivative(expr: MathIR, var_name: &str) -> MathIR { MathIR::Derivative { expr: Box::new(expr), var: var_name.to_string() } }
pub fn integral(expr: MathIR, var_name: &str) -> MathIR { MathIR::Integral { expr: Box::new(expr), var: var_name.to_string(), lower: None, upper: None } }
pub fn eq(lhs: MathIR, rhs: MathIR) -> MathIR { MathIR::Eq { lhs: Box::new(lhs), rhs: Box::new(rhs) } }
pub fn forall(var_name: &str, domain: &str, body: MathIR) -> MathIR { MathIR::ForAll { var: var_name.to_string(), domain: domain.to_string(), body: Box::new(body) } }
pub fn exists(var_name: &str, domain: &str, body: MathIR) -> MathIR { MathIR::Exists { var: var_name.to_string(), domain: domain.to_string(), body: Box::new(body) } }
pub fn and_expr(terms: Vec<MathIR>) -> MathIR { MathIR::And { terms } }
pub fn or_expr(terms: Vec<MathIR>) -> MathIR { MathIR::Or { terms } }
pub fn not_expr(expr: MathIR) -> MathIR { MathIR::Not { expr: Box::new(expr) } }
pub fn implies(lhs: MathIR, rhs: MathIR) -> MathIR { MathIR::Implies { lhs: Box::new(lhs), rhs: Box::new(rhs) } }
pub fn matrix(rows: Vec<Vec<MathIR>>) -> MathIR { MathIR::Matrix { rows } }

pub fn to_json(expr: &MathIR) -> String {
    serde_json::to_string(expr).unwrap_or_default()
}

pub fn from_json(s: &str) -> Option<MathIR> {
    serde_json::from_str(s).ok()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_const() {
        let e = const_val(42.0);
        assert_eq!(to_json(&e), r#"{"Const":{"value":42.0}}"#);
    }

    #[test]
    fn test_var() {
        let e = var("x");
        match e {
            MathIR::Var { id, .. } => assert_eq!(id, "x"),
            _ => panic!("expected Var"),
        }
    }

    #[test]
    fn test_add() {
        let e = add(vec![const_val(1.0), var("x")]);
        match e {
            MathIR::Add { terms } => assert_eq!(terms.len(), 2),
            _ => panic!("expected Add"),
        }
    }

    #[test]
    fn test_serialize_roundtrip() {
        let e = pow(var("x"), const_val(2.0));
        let json = to_json(&e);
        let e2 = from_json(&json).unwrap();
        assert_eq!(e, e2);
    }
}
