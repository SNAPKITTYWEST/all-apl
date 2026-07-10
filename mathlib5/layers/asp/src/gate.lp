% ============================================================
% ASP Gate — First layer: accept/reject sorry candidates
% ============================================================
% Every sorry passes through the gate before attempting closure.
% The gate classifies: can this be solved automatically?
% ============================================================

% ============================================================
% Knowledge Base: Sorry Classification Rules
% ============================================================

% Pattern: simple arithmetic (SumSquares, SumLinear, SumCubes)
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

% Pattern: polynomial identity
sorry_classifiable(polynomial) :-
    has_pattern(plus, _),
    has_pattern(times, _),
    has_pattern(power, _).

% Pattern: linear arithmetic
sorry_classifiable(linear) :-
    has_pattern(plus, _),
    has_pattern(times, _),
    not(has_pattern(power, _)).

% Pattern: set/combinatorial
sorry_classifiable(combinatorial) :-
    has_pattern(foreall, _),
    has_pattern(exists, _).

% Gate decision
gate_accept(X) :- sorry_classifiable(X).
gate_reject(X) :- not(sorry_classifiable(X)).

% ============================================================
% ASP Solver: Generate classification
% ============================================================

% Input: sorry statement as facts
% Output: classification + confidence score

% Example input facts:
% has_pattern(sum, [k, 1, n]).
% has_pattern(power, 2).
% has_pattern(range, [1, n]).

% Query: ?- gate_accept(X).

% ============================================================
% Constraint Rules: What the gate enforces
% ============================================================

% No sorry with unknown patterns passes the gate
:- sorry(X), not(sorry_classifiable(X)), gate_accept(X).

% Conflicting classifications are rejected
:- sorry_classifiable(X), sorry_classifiable(Y), X != Y.

% Every accepted sorry must have a closing strategy
:- gate_accept(X), not(has_strategy(X, _)).
