% linearity.lp — QF_LRA Constraint Encoding for ASP
% Encodes linear arithmetic as ASP constraints.

% ── Variable Bounds ────────────────────────────────────────────────
var_lo(V, -1000) :- var(V).
var_hi(V, 1000) :- var(V).

% ── Constraint Encoding ────────────────────────────────────────────
% Each linear constraint: a1*x1 + a2*x2 + ... + an*xn <= b
% Encoded as: assign(xi, vi) and sum(ai*vi) <= b

% Dot product evaluation
dot_product(ID, Sum) :-
    constraint(ID, _, _, _),
    #sum{Val * Coeff : assign(V, Val), constraint_coeff(ID, V, Coeff)} = Sum.

% Constraint satisfaction
constraint_satisfied(ID) :-
    constraint(ID, _, Bound, "<="),
    dot_product(ID, Sum),
    Sum <= Bound.

constraint_satisfied(ID) :-
    constraint(ID, _, Bound, ">="),
    dot_product(ID, Sum),
    Sum >= Bound.

constraint_satisfied(ID) :-
    constraint(ID, _, Bound, "="),
    dot_product(ID, Sum),
    Sum == Bound.

% ── Goal Violation ─────────────────────────────────────────────────
goal_violated :-
    goal(Coeffs, Bound),
    #sum{Val * Coeff : assign(V, Val), goal_coeff(V, Coeff)} = Sum,
    Sum > Bound.

% ── Counterexample = Constraints Satisfied + Goal Violated ─────────
counterexample :-
    constraint_satisfied(ID),
    goal_violated.

% ── Linear Inequality Propagation ──────────────────────────────────
% If a*x <= b and a > 0, then x <= b/a
propagate_upper(V, Bound / Coeff) :-
    constraint(ID, _, Bound, "<="),
    constraint_coeff(ID, V, Coeff),
    Coeff > 0.

% If a*x <= b and a < 0, then x >= b/a
propagate_lower(V, Bound / Coeff) :-
    constraint(ID, _, Bound, "<="),
    constraint_coeff(ID, V, Coeff),
    Coeff < 0.

% ── Show ───────────────────────────────────────────────────────────
#show counterexample/0.
#show assign/2.
#show constraint_satisfied/1.
