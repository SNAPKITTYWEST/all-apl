:- module(fol_checker, [check_proof/1, resolve/3, unify/3]).
:- use_module(library(lists)).

:- dynamic clause/2.
:- dynamic derived/2.

%% check_proof(+File)
%  Reads a proof file and validates it.
check_proof(File) :-
    open(File, read, S),
    read_clauses(S, Clauses),
    close(S),
    validate_proof(Clauses).

%% read_clauses(+Stream, -Clauses)
read_clauses(S, [id(ID, Lits, From)|Cs]) :-
    read_line_to_string(S, Line),
    ( Line = end_of_file -> Cs = []
    ; parse_line(Line, id(ID, Lits, From)),
      read_clauses(S, Cs)
    ).

%% parse_line(+Line, -Clause)
parse_line(Line, id(ID, Lits, From)) :-
    split_string(Line, " \t", " \t", [IDStr|Rest]),
    atom_string(ID, IDStr),
    parse_lits(Rest, Lits, From).

parse_lits(Words, Lits, from(A, B)) :-
    append(CLitStrs, ["from", AStr, BStr], Words),
    atom_string(A, AStr), atom_string(B, BStr),
    maplist(parse_lit, CLitStrs, Lits).
parse_lits(Words, Lits, axiom) :-
    maplist(parse_lit, Words, Lits).

parse_lit(Str, lit(Var, Pred, Args)) :-
    ( sub_string(Str, _, _, _, "~") ->
      sub_string(Str, _, _, After, "~"),
      sub_string(Str, _, _, 0, PredRaw),
      Var = neg
    ; PredRaw = Str, Var = pos
    ),
    ( sub_string(PredRaw, Before, _, _, "(") ->
      sub_string(PredRaw, 0, Before, _, Pred),
      sub_string(PredRaw, Before1, _, 0, ArgsStr),
      split_string(ArgsStr, ",", "", Args)
    ; Pred = PredRaw, Args = []
    ).

%% resolve(+C1, +C2, -Resolvent)
%  Resolve two clauses on complementary literals.
resolve(Lits1, Lits2, Resolvent) :-
    select(lit(pos, P, Args), Lits1, Rest1),
    select(lit(neg, P, Args), Lits2, Rest2),
    !,
    append(Rest1, Rest2, Resolvent).
resolve(Lits1, Lits2, Resolvent) :-
    select(lit(neg, P, Args), Lits1, Rest1),
    select(lit(pos, P, Args), Lits2, Rest2),
    !,
    append(Rest1, Rest2, Resolvent).

%% unify(+T1, +T2, -Subst)
unify(X, X, []) :- var(X), !.
unify(X, X, []) :- nonvar(X), !.
unify(v(X), T, [v(X)=T]) :- var(v(X)), !.
unify(T, v(X), [v(X)=T]) :- var(v(X)), !.
unify(f(F, As1), f(F, As2), Subst) :-
    maplist(unify, As1, As2, Substs),
    foldl(append, Substs, [], Subst).
unify(X, T, [X=T]) :- atom(X), nonvar(T).
unify(T, X, [X=T]) :- atom(X), nonvar(T).

%% validate_proof(+Clauses)
validate_proof([]) :- write('ERROR: empty proof'), nl, halt(1).
validate_proof(Clauses) :-
    last(Clauses, id(_, [], _)),
    write('VALID: proof is correct'), nl, halt(0).
validate_proof(_) :-
    write('INVALID: no empty clause derived'), nl, halt(1).
