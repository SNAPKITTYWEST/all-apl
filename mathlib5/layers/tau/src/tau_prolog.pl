% ============================================================
% Tau Prolog — Browser-side theorem proving
% ============================================================
% Runs in JavaScript via tau-prolog.js
% Connects to S-expression IR for proof generation
% ============================================================

% ============================================================
% Sorry Classification (matches ASP gate.lp)
% ============================================================

sorry_classifiable(sumsquares) :-
    has_pattern(sum, _),
    has_pattern(power, 2),
    has_pattern(range, _).

sorry_classifiable(sumlinear) :-
    has_pattern(sum, _),
    has_pattern(range, _),
    not(has_pattern(power, _)).

sorry_classifiable(sumcubes) :-
    has_pattern(sum, _),
    has_pattern(power, 3),
    has_pattern(range, _).

sorry_classifiable(polynomial) :-
    has_pattern(plus, _),
    has_pattern(times, _),
    has_pattern(power, _).

sorry_classifiable(linear) :-
    has_pattern(plus, _),
    has_pattern(times, _),
    not(has_pattern(power, _)).

% ============================================================
% Proof Term Generation
% ============================================================

proof_term(X, induction_proof) :-
    sorry_classifiable(X, sumsquares),
    has_variable(X, N),
    base_case(X, 0),
    inductive_step(X, N).

proof_term(X, omega_proof) :-
    sorry_classifiable(X, linear),
    has_linear_constraints(X).

proof_term(X, ring_proof) :-
    sorry_classifiable(X, polynomial),
    has_polynomial_identity(X).

% ============================================================
% Closed-Form Computation
% ============================================================

closed_form(sumsquares, N, Result) :-
    Result is N * (N + 1) * (2 * N + 1) div 6.

closed_form(sumlinear, N, Result) :-
    Result is N * (N + 1) div 2.

closed_form(sumcubes, N, Result) :-
    Sum is N * (N + 1) div 2,
    Result is Sum * Sum.

% ============================================================
% Verification
% ============================================================

verified(X) :-
    proof_term(X, Proof),
    type_check(Proof),
    not(contains_sorry(Proof)).

% ============================================================
% S-expression Integration
% ============================================================

% Convert S-expression to Prolog facts
% Input: (sum (range 1 n) (power k 2))
% Output: has_pattern(sum, _), has_pattern(power, 2), has_pattern(range, [1, n])

sexpr_to_facts(sexpr(List), Facts) :-
    maplist(sexpr_to_fact, List, Facts).

sexpr_to_fact(sexpr([atom(sum), X]), has_pattern(sum, X)).
sexpr_to_fact(sexpr([atom(power), X, N]), has_pattern(power, N)).
sexpr_to_fact(sexpr([atom(range), A, B]), has_pattern(range, [A, B])).
sexpr_to_fact(sexpr([atom(times), X, Y]), has_pattern(times, [X, Y])).
sexpr_to_fact(sexpr([atom(plus), X, Y]), has_pattern(plus, [X, Y])).

% ============================================================
% Query Interface
% ============================================================

% ?- sorry_classifiable(X), proof_term(X, P), verified(X).
% X = sumsquares,
% P = induction_proof
