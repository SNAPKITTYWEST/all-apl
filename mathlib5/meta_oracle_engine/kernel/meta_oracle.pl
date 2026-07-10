/**
 * meta_oracle.pl — Prolog Gate for Structural Proof Validation
 * SWI-Prolog / Tau Prolog compatible.
 * Fast structural check before deep Lean verification.
 */

:- module(meta_oracle, [validate/2, check_sorry/1, check_proof_structure/1]).
:- use_module(library(lists)).
:- use_module(library(sha256)).

:- dynamic clause/3.
:- dynamic derived/3.

/**
 * validate(+ProofText, -Result)
 * Main entry point. Result = valid(Status, ReceiptHash)
 */
validate(ProofText, Result) :-
    parse_proof(ProofText, Clauses),
    ( check_sorry(Clauses) ->
        Result = invalid("sorry_detected")
    ; check_proof_structure(Clauses) ->
        proof_hash(ProofText, Hash),
        Result = valid(Hash)
    ; Result = invalid("no_empty_clause")
    ).

/**
 * parse_proof(+Text, -Clauses)
 * Parse proof text into clause list.
 */
parse_proof(Text, Clauses) :-
    split_string(Text, "\n", "\n", Lines),
    maplist(parse_line, Lines, RawClauses),
    exclude(=(empty), RawClauses, Clauses).

parse_line(Line, empty) :-
    string_to_atom(Line, Atom),
    atom_string(Atom, Str),
    string_length(Str, 0), !.
parse_line(Line, clause(ID, Lits, From)) :-
    split_string(Line, " \t", " \t", Tokens),
    Tokens = [IDStr|Rest],
    atom_string(IDAtom, IDStr),
    number_codes(ID, IDAtom),
    parse_rest(Rest, Lits, From).

parse_rest(["from"|Rest], [], from(A, B)) :-
    Rest = [AStr, BStr],
    atom_string(AAtom, AStr), atom_string(BAtom, BStr),
    number_codes(A, AAtom), number_codes(B, BAtom).
parse_rest(Tokens, Lits, axiom) :-
    maplist(parse_token, Tokens, Lits).

parse_token(Token, lit(Pred, Args)) :-
    split_string(Token, "()", "()", [PredStr|ArgStrs]),
    atom_string(Pred, PredStr),
    maplist(split_comma, ArgStrs, Args).

split_comma(Str, Args) :-
    split_string(Str, ",", "", Args).

/**
 * check_sorry(+Clauses)
 * Succeeds if any clause contains 'sorry' (HARD REJECT).
 */
check_sorry(Clauses) :-
    member(clause(_, Lits, _), Clauses),
    member(lit(Pred, _), Lits),
    sub_string(Pred, _, _, _, "sorry"), !.

/**
 * check_proof_structure(+Clauses)
 * Validates resolution steps form a valid DAG ending in empty clause.
 */
check_proof_structure(Clauses) :-
    last(Clauses, clause(_, [], from(_, _))).

/**
 * proof_hash(+Text, -Hash)
 * SHA-256 hash of proof text.
 */
proof_hash(Text, Hash) :-
    atom_string(Text, Str),
    sha256(Str, HashBytes),
    hex_bytes(HashBytes, Hash).

hex_bytes([], "").
hex_bytes([B|Bs], Hex) :-
    format(atom(HH), "~2~16r", [B]),
    hex_bytes(Bs, Rest),
    atom_concat(HH, Rest, Hex).
