% refute.lp — Counterexample Search for QF_LRA
% Given constraints and a goal, find a counterexample.

% ── Input: Linear Constraints ───────────────────────────────────────
% constraint(ID, Coeffs..., Bound, Op)
% var(ID, Name)
% goal(Coeffs..., Bound)

% ── Model: Variable Assignments ────────────────────────────────────
% assign(VarID, Value) — the counterexample assignment.

% ── Constraint Satisfaction ─────────────────────────────────────────
% For each constraint: sum(coeffs[i] * value[i]) op bound
holds_constraint(ID) :-
    constraint(ID, _, Bound, "<="),
    assign(V, Val),
    sum_product(ID, V, Val) <= Bound.

% ── Goal Violation (Counterexample) ────────────────────────────────
% Counterexample: all constraints hold, but goal is violated
counterexample :-
    holds_constraint(ID),
    goal(Coeffs, Bound),
    assign(V, Val),
    sum_product_goal(V, Val) > Bound.

% ── QF_LRA Simplex Encoding ────────────────────────────────────────
% Phase 1: Initialize at 0
init_assign(V, 0) :- var(V).

% Phase 2: Try bound values
try_assign(V, Lo) :- var(V), var_bound(V, Lo, _).
try_assign(V, Hi) :- var(V), var_bound(_, _, Hi).
try_assign(V, 0) :- var(V).
try_assign(V, 1) :- var(V).
try_assign(V, -1) :- var(V).

% Phase 3: Select feasible assignment
assign(V, Val) :- try_assign(V, Val), feasible(V, Val).

% Feasible: assignment satisfies all constraints involving V
feasible(V, Val) :-
    var(V),
    try_assign(V, Val),
    constraint(ID, _, _, _),
    constraint_involves(ID, V),
    constraint_satisfied(ID, V, Val).

% ── Output ─────────────────────────────────────────────────────────
#show counterexample/0.
#show assign/2.
