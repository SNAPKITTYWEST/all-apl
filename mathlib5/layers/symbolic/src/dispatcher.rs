use serde::{Serialize, Deserialize};

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum SolverBackend {
    SymPy, Z3, CVC5, CVODE, Julia, Singular, Lean4, CGAL, DeepONet, Fallback,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum EquationClass {
    PolynomialSystem, ODEStiff, ODENonStiff, PDE, IntegralEquation,
    LogicalConstraint, Geometric, TensorAlgebra, SymbolicIntegration,
    SymbolicLimit, LinearAlgebra, Fallback,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum ProofLevel {
    None, Witness, FullCertificate, LeanTerm, Z3ProofObject,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SolverSpec {
    pub solver: SolverBackend,
    pub capabilities: Vec<String>,
    pub timeout_ms: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProofRequirement {
    pub level: ProofLevel,
    pub backends: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DispatchResult {
    pub solver: SolverSpec,
    pub proof: ProofRequirement,
    pub equation_class: EquationClass,
    pub confidence: f64,
}

pub struct Dispatcher;

impl Dispatcher {
    pub fn new() -> Self { Dispatcher }

    pub fn classify(&self, kind: &str) -> EquationClass {
        match kind {
            "Eq" => EquationClass::PolynomialSystem,
            "Integral" | "Derivative" => EquationClass::SymbolicIntegration,
            "Limit" => EquationClass::SymbolicLimit,
            "ForAll" | "Exists" | "And" | "Or" | "Not" | "Implies" => EquationClass::LogicalConstraint,
            "Matrix" => EquationClass::LinearAlgebra,
            "Tensor" => EquationClass::TensorAlgebra,
            "Geometric" => EquationClass::Geometric,
            _ => EquationClass::Fallback,
        }
    }

    pub fn select_solver(&self, eq_class: &EquationClass) -> SolverSpec {
        match eq_class {
            EquationClass::PolynomialSystem => SolverSpec { solver: SolverBackend::Singular, capabilities: vec!["groebner".into()], timeout_ms: 60000 },
            EquationClass::SymbolicIntegration => SolverSpec { solver: SolverBackend::SymPy, capabilities: vec!["integration".into(), "limits".into()], timeout_ms: 30000 },
            EquationClass::SymbolicLimit => SolverSpec { solver: SolverBackend::SymPy, capabilities: vec!["limits".into(), "series".into()], timeout_ms: 30000 },
            EquationClass::LogicalConstraint => SolverSpec { solver: SolverBackend::Z3, capabilities: vec!["quantifiers".into()], timeout_ms: 30000 },
            EquationClass::LinearAlgebra => SolverSpec { solver: SolverBackend::SymPy, capabilities: vec!["matrix".into()], timeout_ms: 30000 },
            EquationClass::ODEStiff => SolverSpec { solver: SolverBackend::CVODE, capabilities: vec!["bdf".into(), "adjoint".into()], timeout_ms: 60000 },
            EquationClass::ODENonStiff => SolverSpec { solver: SolverBackend::Julia, capabilities: vec!["ode".into(), "auto_diff".into()], timeout_ms: 60000 },
            _ => SolverSpec { solver: SolverBackend::Fallback, capabilities: vec!["sympy".into()], timeout_ms: 30000 },
        }
    }

    pub fn require_proof(&self, eq_class: &EquationClass) -> ProofRequirement {
        match eq_class {
            EquationClass::LogicalConstraint => ProofRequirement { level: ProofLevel::Z3ProofObject, backends: vec!["z3".into()] },
            EquationClass::PolynomialSystem => ProofRequirement { level: ProofLevel::Witness, backends: vec!["groebner_basis".into()] },
            _ => ProofRequirement { level: ProofLevel::None, backends: vec![] },
        }
    }

    pub fn dispatch(&self, kind: &str) -> DispatchResult {
        let eq_class = self.classify(kind);
        let solver = self.select_solver(&eq_class);
        let proof = self.require_proof(&eq_class);
        DispatchResult { solver, proof, equation_class: eq_class, confidence: 0.8 }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_classify_eq() {
        let d = Dispatcher::new();
        assert_eq!(d.classify("Eq"), EquationClass::PolynomialSystem);
    }

    #[test]
    fn test_dispatch_logical() {
        let d = Dispatcher::new();
        let r = d.dispatch("ForAll");
        assert_eq!(r.solver.solver, SolverBackend::Z3);
        assert_eq!(r.proof.level, ProofLevel::Z3ProofObject);
    }

    #[test]
    fn test_dispatch_integral() {
        let d = Dispatcher::new();
        let r = d.dispatch("Integral");
        assert_eq!(r.solver.solver, SolverBackend::SymPy);
    }
}
