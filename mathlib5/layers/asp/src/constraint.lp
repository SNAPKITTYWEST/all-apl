% ============================================================
% ASP Constraint — Second layer: bound the search space
% ============================================================
% Once a sorry passes the gate, constraints limit
% which closing strategies are attempted.
% ============================================================

% ============================================================
% Strategy Registry
% ============================================================

strategy(simp, 1).        % Fastest, covers trivial cases
strategy(omega, 2).       % Linear arithmetic
strategy(ring, 3).        % Polynomial identities
strategy(decide, 4).      % Decidable propositions
strategy(norm_num, 5).    % Numeric normalization
strategy(linarith, 6).    % Linear with hypotheses
strategy(ffi_kernel, 7).  % C-- pre-computed
strategy(asp_solve, 8).   % ASP refutation
strategy(vampire, 9).     % First-order resolution
strategy(human, 10).      % Last resort

% ============================================================
% Constraint: Try strategies in order of cost
% ============================================================

% The cheapest applicable strategy must be tried first
% :- gate_accept(X), strategy(S1, C1), strategy(S2, C2),
%    C1 < C2, applicable(X, S2), not(attempted(X, S1)).

% No strategy may be attempted if a cheaper one exists
% and hasn't been tried yet

% ============================================================
% Constraint: Time bounds per strategy
% ============================================================

time_limit(simp, 100).       % 100ms
time_limit(omega, 500).      % 500ms
time_limit(ring, 500).       % 500ms
time_limit(decide, 1000).    % 1s
time_limit(norm_num, 500).   % 500ms
time_limit(linarith, 1000).  % 1s
time_limit(ffi_kernel, 10).  % 10ms (pre-computed)
time_limit(asp_solve, 5000). % 5s
time_limit(vampire, 10000).  % 10s
time_limit(human, 86400000). % 24h (human intervention)

% ============================================================
% Constraint: Resource budget
% ============================================================

total_budget(60000).  % 60 seconds total per sorry

% The sum of all strategy times must not exceed budget
:- gate_accept(X),
   findall(T, (attempted(X, S), time_limit(S, T)), Times),
   sum_list(Times, Total),
   total_budget(Budget),
   Total > Budget.

% ============================================================
% Constraint: No duplicate attempts
% ============================================================

% Each strategy may be attempted at most once per sorry
:- attempted(X, S), attempted(X, S), X1 != X2.

% ============================================================
% Constraint: FFI kernel has priority for known patterns
% ============================================================

% If the C-- kernel knows this pattern, use it first
:- gate_accept(X), known_pattern(X, P), not(attempted(X, ffi_kernel)).
