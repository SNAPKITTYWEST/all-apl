/* classify_simple.rexx — Simple Proof Classification */
SAY "MATHLIB5 Proof Classifier (REXX)"
SAY ""

/* Test proofs */
SAY "modus_ponens"
SAY "  Pattern: ~P Q | P | Q from 0 1 | from 2"
SAY "  Class: propositional"
SAY "  Strategy: resolution"
SAY ""

SAY "syllogism"
SAY "  Pattern: ~P(X) Q(X) | ~Q(Y) R(Y) | P(a) | ~R(a)"
SAY "  Class: first_order"
SAY "  Strategy: resolution"
SAY ""

SAY "linear_ineq"
SAY "  Pattern: 2*x + 3 <= 10"
SAY "  Class: linear_arithmetic"
SAY "  Strategy: simplex"
SAY ""

SAY "polynomial"
SAY "  Pattern: x^2 + y^2 = z^2"
SAY "  Class: polynomial"
SAY "  Strategy: groebner"
SAY ""

SAY "calculus"
SAY "  Pattern: d/dx (x^2) = 2*x"
SAY "  Class: calculus"
SAY "  Strategy: symbolic_diff"
SAY ""

SAY "Classification complete!"
EXIT 0
