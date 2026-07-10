use crate::mathir::MathIR;

pub struct RewriteRule {
    pub name: String,
    pub pattern: MathIR,
    pub replacement: MathIR,
    pub priority: u32,
}

pub struct Normalizer {
    pub rules: Vec<RewriteRule>,
    pub max_iterations: usize,
}

impl Normalizer {
    pub fn new() -> Self {
        let mut n = Normalizer { rules: Vec::new(), max_iterations: 1000 };
        n.add_arithmetic_rules();
        n.add_algebraic_rules();
        n.add_transcendental_rules();
        n.add_calculus_rules();
        n
    }

    fn add_arithmetic_rules(&mut self) {
        use crate::mathir::*;
        let x = var("x");
        self.rules.push(RewriteRule { name: "add_zero".into(), pattern: add(vec![x.clone(), const_val(0.0)]), replacement: x.clone(), priority: 100 });
        self.rules.push(RewriteRule { name: "add_zero_left".into(), pattern: add(vec![const_val(0.0), x.clone()]), replacement: x.clone(), priority: 100 });
        self.rules.push(RewriteRule { name: "mul_one".into(), pattern: mul(vec![x.clone(), const_val(1.0)]), replacement: x.clone(), priority: 100 });
        self.rules.push(RewriteRule { name: "mul_zero".into(), pattern: mul(vec![x.clone(), const_val(0.0)]), replacement: const_val(0.0), priority: 100 });
        self.rules.push(RewriteRule { name: "pow_zero".into(), pattern: pow(x.clone(), const_val(0.0)), replacement: const_val(1.0), priority: 100 });
        self.rules.push(RewriteRule { name: "pow_one".into(), pattern: pow(x.clone(), const_val(1.0)), replacement: x, priority: 100 });
    }

    fn add_algebraic_rules(&mut self) {
        use crate::mathir::*;
        let x = var("x");
        self.rules.push(RewriteRule {
            name: "pythagorean".into(),
            pattern: add(vec![pow(fn_app("sin", vec![x.clone()]), const_val(2.0)), pow(fn_app("cos", vec![x]), const_val(2.0))]),
            replacement: const_val(1.0),
            priority: 80,
        });
    }

    fn add_transcendental_rules(&mut self) {
        use crate::mathir::*;
        let x = var("x");
        self.rules.push(RewriteRule { name: "exp_zero".into(), pattern: fn_app("exp", vec![const_val(0.0)]), replacement: const_val(1.0), priority: 95 });
        self.rules.push(RewriteRule { name: "ln_one".into(), pattern: fn_app("ln", vec![const_val(1.0)]), replacement: const_val(0.0), priority: 95 });
        self.rules.push(RewriteRule { name: "exp_ln_cancel".into(), pattern: fn_app("exp", vec![fn_app("ln", vec![x.clone()])]), replacement: x.clone(), priority: 95 });
        self.rules.push(RewriteRule { name: "ln_exp_cancel".into(), pattern: fn_app("ln", vec![fn_app("exp", vec![x.clone()])]), replacement: x, priority: 95 });
    }

    fn add_calculus_rules(&mut self) {
        use crate::mathir::*;
        let x = var("x");
        let f = var("f");
        self.rules.push(RewriteRule { name: "deriv_var".into(), pattern: derivative(x, "x"), replacement: const_val(1.0), priority: 90 });
        self.rules.push(RewriteRule { name: "int_deriv_cancel".into(), pattern: integral(derivative(f.clone(), "x"), "x"), replacement: f, priority: 90 });
    }

    pub fn normalize(&self, expr: &MathIR) -> MathIR {
        let mut current = expr.clone();
        for _ in 0..self.max_iterations {
            let mut changed = false;
            let mut sorted_rules = self.rules.iter().collect::<Vec<_>>();
            sorted_rules.sort_by(|a, b| b.priority.cmp(&a.priority));
            for rule in sorted_rules {
                if self.matches(&rule.pattern, &current) {
                    current = self.apply(&rule.pattern, &rule.replacement, &current);
                    changed = true;
                    break;
                }
            }
            if !changed { break; }
        }
        current
    }

    fn matches(&self, pattern: &MathIR, expr: &MathIR) -> bool {
        match (pattern, expr) {
            (MathIR::Const { value: pv }, MathIR::Const { value: ev }) => (pv - ev).abs() < f64::EPSILON,
            (MathIR::Var { .. }, _) => true,
            (MathIR::Add { terms: pt }, MathIR::Add { terms: et }) => pt.len() == et.len() && pt.iter().zip(et.iter()).all(|(p, e)| self.matches(p, e)),
            (MathIR::Mul { factors: pf }, MathIR::Mul { factors: ef }) => pf.len() == ef.len() && pf.iter().zip(ef.iter()).all(|(p, e)| self.matches(p, e)),
            (MathIR::Pow { base: pb, exponent: pe }, MathIR::Pow { base: eb, exponent: ee }) => self.matches(pb, eb) && self.matches(pe, ee),
            (MathIR::Fn { name: pn, args: pa }, MathIR::Fn { name: en, args: ea }) => pn == en && pa.len() == ea.len() && pa.iter().zip(ea.iter()).all(|(p, e)| self.matches(p, e)),
            (MathIR::Derivative { expr: pe, var: pv }, MathIR::Derivative { expr: ee, var: ev }) => pv == ev && self.matches(pe, ee),
            _ => false,
        }
    }

    fn apply(&self, pattern: &MathIR, replacement: &MathIR, expr: &MathIR) -> MathIR {
        if self.matches(pattern, expr) { return replacement.clone(); }
        match expr {
            MathIR::Add { terms } => MathIR::Add { terms: terms.iter().map(|t| self.apply(pattern, replacement, t)).collect() },
            MathIR::Mul { factors } => MathIR::Mul { factors: factors.iter().map(|f| self.apply(pattern, replacement, f)).collect() },
            MathIR::Pow { base, exponent } => MathIR::Pow { base: Box::new(self.apply(pattern, replacement, base)), exponent: Box::new(self.apply(pattern, replacement, exponent)) },
            MathIR::Fn { name, args } => MathIR::Fn { name: name.clone(), args: args.iter().map(|a| self.apply(pattern, replacement, a)).collect() },
            _ => expr.clone(),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::mathir::*;

    #[test]
    fn test_add_zero() {
        let n = Normalizer::new();
        let e = add(vec![var("x"), const_val(0.0)]);
        assert_eq!(n.normalize(&e), var("x"));
    }

    #[test]
    fn test_mul_one() {
        let n = Normalizer::new();
        let e = mul(vec![var("x"), const_val(1.0)]);
        assert_eq!(n.normalize(&e), var("x"));
    }

    #[test]
    fn test_pow_zero() {
        let n = Normalizer::new();
        let e = pow(var("x"), const_val(0.0));
        assert_eq!(n.normalize(&e), const_val(1.0));
    }

    #[test]
    fn test_exp_zero() {
        let n = Normalizer::new();
        let e = fn_app("exp", vec![const_val(0.0)]);
        assert_eq!(n.normalize(&e), const_val(1.0));
    }

    #[test]
    fn test_pythagorean() {
        let n = Normalizer::new();
        let e = add(vec![
            pow(fn_app("sin", vec![var("x")]), const_val(2.0)),
            pow(fn_app("cos", vec![var("x")]), const_val(2.0)),
        ]);
        assert_eq!(n.normalize(&e), const_val(1.0));
    }
}
