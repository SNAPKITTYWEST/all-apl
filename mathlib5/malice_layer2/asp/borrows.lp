% borrows.lp — ASP-Gat Borrowchain Ownership Tracking
% Models variable ownership as linear resource with borrow semantics.
% Used to detect use-after-free, double-mut, and linear resource violations.

% ── Entities ────────────────────────────────────────────────────────
% var(V), scope(S), time(T).

% ── Ownership (Unique, Linear) ─────────────────────────────────────
{ owns(V, S, T) } = 1 :- var(V), scope(S), time(T).

% ── Borrow Rules (Rust-style) ──────────────────────────────────────
% Immutable borrow: many allowed, no mutable simultaneously
imm_borrow(V, S, T) :- owns(V, S, T), not mut_borrow(V, S, T), not loan(V, _, _, T).

% Mutable borrow: exclusive
mut_borrow(V, S, T) :- owns(V, S, T), not imm_borrow(V, S, T), not loan(V, _, _, T).

% ── Loan Expiry ────────────────────────────────────────────────────
loan(V, S, T, Expires) :- mut_borrow(V, S, T), scope_end(S, Expires).
loan(V, S, T, Expires) :- imm_borrow(V, S, T), scope_end(S, Expires).

% ── Exploits (Adversarial Targets) ─────────────────────────────────
% Use-After-Free: use after loan expires
exploit(uaf(V, T2)) :- mut_borrow(V, S, T1), loan(V, S, T1, Exp), time(T2), T2 > Exp, owns(V, S, T2).

% Double mutable borrow
exploit(double_mut(V, T1, T2)) :- mut_borrow(V, S, T1), mut_borrow(V, S, T2), T1 != T2, not loan(V, S, _, _).

% Use-After-Scope: variable used outside its scope
exploit(use_after_scope(V, T)) :- owns(V, S1, T), scope_end(S1, Exp), T > Exp.

% ── Linear Resource Bounds ─────────────────────────────────────────
% Each variable has exactly one owner at any time
:- time(T), scope(S), var(V), #count{O : owns(V, S, T)} != 1.

% ── Show Exploits ──────────────────────────────────────────────────
#show exploit/1.
#show owns/3.
