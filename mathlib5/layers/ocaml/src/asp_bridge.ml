(* ============================================================
   OCaml → ASP Bridge
   Calls ASP solver from OCaml, feeds results back to Lean
   ============================================================ *)

(* OCaml types for ASP interaction *)
type asp_literal = {
  predicate : string;
  arguments : string list;
  negated   : bool;
}

type asp_program = {
  facts      : asp_literal list;
  rules      : asp_rule list;
  constraints : asp_literal list list;
}

and asp_rule = {
  head : asp_literal;
  body : asp_literal list;
}

type asp_result = {
  stable_model : asp_literal list;
  is_sat       : bool;
  solving_time : float;
}

(* ============================================================
   ASP Program Builder
   ============================================================ *)

let make_literal ?(negated=false) pred args =
  { predicate = pred; arguments = args; negated }

let literal_to_string lit =
  let neg = if lit.negated then "not " else "" in
  let args = String.concat ", " lit.arguments in
  Printf.sprintf "%s%s(%s)" neg lit.predicate args

let program_to_string prog =
  let facts = List.map literal_to_string prog.facts in
  let rules = List.map rule_to_string prog.rules in
  let constraints = List.map constraint_to_string prog.constraints in
  String.concat "\n" (facts @ rules @ constraints)

and rule_to_string rule =
  let head = literal_to_string rule.head in
  let body = String.concat ", " (List.map literal_to_string rule.body) in
  Printf.sprintf "%s :- %s." head body

and constraint_to_string lits =
  let lits_str = String.concat ", " (List.map literal_to_string lits) in
  Printf.sprintf ":- %s." lits_str

(* ============================================================
   ASP Solver Interface (clingo)
   ============================================================ *)

let call_clingo program timeout_ms =
  let program_str = program_to_string program in
  let tmp_file = Filename.temp_file "asp" ".lp" in
  let oc = open_out tmp_file in
  output_string oc program_str;
  close_out oc;
  
  let cmd = Printf.sprintf "clingo %s --time-limit=%d --text" tmp_file (timeout_ms / 1000) in
  let ic = Unix.open_process_in cmd in
  let output = ref "" in
  (try while true do
    output := !output ^ "\n" ^ input_line ic
  done with End_of_file -> ());
  let _ = Unix.close_process_in ic in
  Sys.remove tmp_file;
  
  parse_clingo_output !output

let parse_clingo_output output =
  let lines = String.split_on_char '\n' output in
  let sat = List.exists (fun l -> String.trim l = "SATISFIABLE") lines in
  let model_lines = List.filter (fun l -> 
    not (String.contains l ':') && 
    String.length (String.trim l) > 0 &&
    not (String.trim l = "SATISFIABLE") &&
    not (String.trim l = "UNSATISFIABLE")
  ) lines in
  {
    stable_model = List.map parse_literal model_lines;
    is_sat = sat;
    solving_time = 0.0  (* Would be measured in real impl *)
  }

let parse_literal s =
  let s = String.trim s in
  let negated = String.length s > 4 && String.sub s 0 4 = "not " in
  let s = if negated then String.sub s 4 (String.length s - 4) else s in
  match String.split_on_char '(' s with
  | [pred; args_str] ->
    let args = String.split_on_char ',' (String.sub args_str 0 (String.length args_str - 1)) in
    make_literal ~negated (String.trim pred) (List.map String.trim args)
  | _ -> make_literal s []

(* ============================================================
   Sorry Classification via ASP
   ============================================================ *)

let classify_sorry sorry_patterns =
  let program = {
    facts = List.map (fun (pred, args) -> make_literal pred args) sorry_patterns;
    rules = [
      { head = make_literal "gate_accept" ["X"];
        body = [make_literal "sorry_classifiable" ["X"]] };
      { head = make_literal "gate_reject" ["X"];
        body = [make_literal "not_sorry_classifiable" ["X"]] };
    ];
    constraints = [
      [make_literal ~negated:true "gate_accept" ["X"];
       make_literal "not_sorry_classifiable" ["X"]];
    ];
  } in
  call_clingo program 5000

(* ============================================================
   Proof Term Generation via ASP
   ============================================================ *)

let generate_proof_term sorry_id classification =
  let program = {
    facts = [
      make_literal "sorry" [sorry_id];
      make_literal "classification" [sorry_id; classification];
    ];
    rules = [
      { head = make_literal "proof_term" [sorry_id; "by_simp"];
        body = [make_literal "classification" [sorry_id; "trivial"]] };
      { head = make_literal "proof_term" [sorry_id; "by_omega"];
        body = [make_literal "classification" [sorry_id; "linear"]] };
      { head = make_literal "proof_term" [sorry_id; "by_ring"];
        body = [make_literal "classification" [sorry_id; "polynomial"]] };
      { head = make_literal "verified" [sorry_id];
        body = [make_literal "proof_term" [sorry_id; "P"];
                make_literal "type_checks" ["P"]] };
    ];
    constraints = [];
  } in
  call_clingo program 10000

(* ============================================================
   Main Entry Point
   ============================================================ *)

let process_sorry sorry_patterns =
  let classification = classify_sorry sorry_patterns in
  if classification.is_sat then
    let proof = generate_proof_term "sorry_1" "sumsquares" in
    if proof.is_sat then
      Ok proof.stable_model
    else
      Error "Cannot generate proof term"
  else
    Error "Sorry cannot be classified"

let () =
  (* Example: classify a SumSquares sorry *)
  let patterns = [
    ("has_pattern", ["sum"; "k"]);
    ("has_pattern", ["power"; "2"]);
    ("has_pattern", ["range"; "1"; "n"]);
  ] in
  match process_sorry patterns with
  | Ok model -> Printf.printf "Proof: %s\n" 
      (String.concat ", " (List.map literal_to_string model))
  | Error msg -> Printf.printf "Error: %s\n" msg
