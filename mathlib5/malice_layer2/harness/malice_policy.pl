% malice_harness.pl — Prolog Gate Policy for Adversarial Node
% Policy rules for DARPA_MALICE_0x00 operations.

:- module(malice_harness, [
    allowed_operation/1,
    requires_receipt/1,
    requires_approval/1,
    valid_malice_result/1,
    receipt_severity/2,
    pipeline_halt/1
]).

% ── Allowed Operations ─────────────────────────────────────────────
allowed_operation(malice_scan).
allowed_operation(malice_refute).
allowed_operation(malice_exploit_search).
allowed_operation(malice_constraint_check).

% ── Receipt Requirements ───────────────────────────────────────────
requires_receipt(malice_scan).
requires_receipt(malice_refute).
requires_receipt(malice_exploit_search).
requires_receipt(malice_constraint_check).

% ── Human Approval Requirements (Adversarial Operations) ───────────
requires_approval(malice_refute).       % Refutation needs review
requires_approval(malice_exploit_search). % Exploit search needs review
% malice_scan and malice_constraint_check are automated

% ── Valid Result Invariants ────────────────────────────────────────
% Soundness: REFUTED result MUST include counterexample
valid_malice_result(malice_result{status: refuted, counterexample: CE}) :-
    CE \= none,
    CE \= "".

% HOLDS result: no counterexample needed
valid_malice_result(malice_result{status: holds}).

% EXPLOIT result: must include exploit description
valid_malice_result(malice_result{status: exploit, exploit: E}) :-
    E \= none.

% ── Receipt Severity ───────────────────────────────────────────────
receipt_severity(malice_result{status: exploit, exploit: _}, critical).
receipt_severity(malice_result{status: refuted, n_goals: N}, high) :- N > 0.
receipt_severity(malice_result{status: refuted}, medium).
receipt_severity(malice_result{status: holds}, low).
receipt_severity(malice_result{status: error}, medium).

% ── Pipeline Halt Conditions ───────────────────────────────────────
% Halt on critical exploit (memory safety violation)
pipeline_halt(malice_step) :-
    receipt_severity(Receipt, critical).

% Halt on too many refutations (possible soundness issue)
pipeline_halt(malice_step) :-
    refutation_count(Count),
    Count > 10.

% ── Counterexample Validity ────────────────────────────────────────
% Counterexample must satisfy all constraints and violate goal
valid_counterexample(CE, Constraints, Goal) :-
    satisfies_all(CE, Constraints),
    violates_goal(CE, Goal).

satisfies_all(_, []).
satisfies_all(CE, [constraint(Op, LHS, RHS) | Rest]) :-
    eval_expr(CE, LHS, Val),
    compare(Op, Val, RHS),
    satisfies_all(CE, Rest).

violates_goal(CE, goal(Coeffs, Bound)) :-
    eval_linear(CE, Coeffs, Val),
    Val > Bound.

% ── Utility ────────────────────────────────────────────────────────
eval_expr(CE, X, Val) :- member(X=Val, CE).
eval_expr(CE, A + B, Val) :- eval_expr(CE, A, VA), eval_expr(CE, B, VB), Val is VA + VB.
eval_expr(CE, A * B, Val) :- eval_expr(CE, A, VA), eval_expr(CE, B, VB), Val is VA * VB.

eval_linear(_, [], 0).
eval_linear(CE, [C*X | Rest], Val) :-
    eval_expr(CE, X, XV),
    eval_linear(CE, Rest, RestVal),
    Val is C * XV + RestVal.

compare(<=, A, B) :- A =< B.
compare(>=, A, B) :- A >= B.
compare(=, A, B) :- A =:= B.

refutation_count(0). % Placeholder
