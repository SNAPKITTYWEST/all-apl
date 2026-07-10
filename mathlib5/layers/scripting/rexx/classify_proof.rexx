/* classify_proof.rexx — Proof Classification Engine (Restricted REXX Profile)
 * Uses only: SAY, variables, IF/THEN/ELSE, DO loops, SELECT, functions
 * No PROCEDURE, no PARSE ARG, no dynamic evaluation
 */

SAY "MATHLIB5 Proof Classifier (REXX)"
SAY ""

/* ── Classification data (flat key/value) ── */
proof.0 = 7
proof.1.name = "modus_ponens"
proof.1.pattern = "~P Q | P | Q from 0 1 | from 2"
proof.1.class = "propositional"
proof.1.strategy = "resolution"
proof.1.solver = "fol_checker"

proof.2.name = "syllogism"
proof.2.pattern = "~P(X) Q(X) | ~Q(Y) R(Y) | P(a) | ~R(a)"
proof.2.class = "first_order"
proof.2.strategy = "resolution"
proof.2.solver = "fol_checker"

proof.3.name = "linear_ineq"
proof.3.pattern = "2*x + 3 <= 10"
proof.3.class = "linear_arithmetic"
proof.3.strategy = "simplex"
proof.3.solver = "qf_lra_solver"

proof.4.name = "polynomial"
proof.4.pattern = "x^2 + y^2 = z^2"
proof.4.class = "polynomial"
proof.4.strategy = "groebner"
proof.4.solver = "singular"

proof.5.name = "calculus"
proof.5.pattern = "d/dx (x^2) = 2*x"
proof.5.class = "calculus"
proof.5.strategy = "symbolic_diff"
proof.5.solver = "sym_py"

proof.6.name = "set_theory"
proof.6.pattern = "forall x in S, P(x)"
proof.6.class = "quantifier"
proof.6.strategy = "instantiation"
proof.6.solver = "z3"

proof.7.name = "topology"
proof.7.pattern = "open_ball(x, r) subset U"
proof.7.class = "topological"
proof.7.strategy = "axiom_check"
proof.7.solver = "lean4"

/* ── Classify each proof ── */
DO i = 1 TO proof.0
    SAY proof.i.name
    SAY "  Pattern:" proof.i.pattern
    SAY "  Class:" proof.i.class
    SAY "  Strategy:" proof.i.strategy
    SAY "  Solver:" proof.i.solver
    
    /* Pattern matching */
    IF POS("forall", proof.i.pattern) > 0 THEN DO
        SAY "    -> Quantifier detected, using instantiation"
    END
    IF POS("^", proof.i.pattern) > 0 THEN DO
        SAY "    -> Polynomial detected, using Groebner basis"
    END
    IF POS("<=", proof.i.pattern) > 0 THEN DO
        SAY "    -> Linear arithmetic detected, using simplex"
    END
    IF POS("d/dx", proof.i.pattern) > 0 THEN DO
        SAY "    -> Calculus detected, using symbolic engine"
    END
    IF POS("subset", proof.i.pattern) > 0 THEN DO
        SAY "    -> Topological detected, using axiom check"
    END
    
    SAY ""
END

SAY "Classification complete!"
EXIT 0
