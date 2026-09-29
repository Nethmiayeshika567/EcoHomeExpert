%  explanation.pl  --  EcoHome Expert
%  Shows HOW a conclusion was reached:
%  User input -> facts -> rules applied -> reasoning -> conclusion.

:- module(explanation,
          [ print_forward_report/2, print_proof_report/3,
            report_string/3, proof_string/3, issue_label/2 ]).

:- use_module(knowledge_base).
:- use_module(inference_engine).

issue_label(Issue, Label) :-
    atomic_list_concat(Parts, '_', Issue),
    atomic_list_concat(Parts, ' ', Label).

describe_condition(Key=Value, Text) :-
    question(Key, Q, _, Opts), member(Value-Label, Opts), !,
    format(string(Text), '~w  ->  ~w', [Q, Label]).
describe_condition(issue(X), Text) :- !,
    issue_label(X, L),
    format(string(Text), 'Earlier conclusion: ~w', [L]).
describe_condition(issues_at_least(N), Text) :- !,
    format(string(Text), 'At least ~w separate issues were found', [N]).
describe_condition(C, Text) :- format(string(Text), '~w', [C]).

print_sources(Ids) :-
    format('Knowledge sources:~n'),
    forall(member(Id, Ids),
           ( source(Id, T, U),
             format('  - [~w] ~w~n    ~w~n', [Id, T, U]) )).

print_rule_block(ID, Cycle) :-
    rule(ID, Conds, issue(C), Cat, Diag, Rec, Src),
    format('Rule ~w  (fired in cycle ~w)~n', [ID, Cycle]),
    format('Category: ~w~n', [Cat]),
    format('IF:~n'),
    forall(member(Cond, Conds),
           ( describe_condition(Cond, T), format('   * ~w~n', [T]) )),
    issue_label(C, CL),
    format('THEN: ~w~n', [CL]),
    format('Diagnosis: ~w~n', [Diag]),
    format('Recommended action: ~w~n', [Rec]),
    print_sources(Src).

%  ---------- forward chaining report ----------
print_forward_report(Answers, Fired) :-
    format('ECOHOME EXPERT - ASSESSMENT RESULTS (forward chaining)~n~n'),
    length(Answers, NA),
    format('STEP 1 - INPUT FACTS (~w answers)~n', [NA]),
    forall(member(A, Answers),
           ( describe_condition(A, T), format('   ~w~n', [T]) )),
    length(Fired, NF),
    format('~nSTEP 2 - RULES APPLIED: ~w rule(s) fired~n', [NF]),
    (   Fired == []
    ->  format('~nNo energy-efficiency problems were detected from your answers.~n')
    ;   forall(member(fired(ID, Cy), Fired),
               ( format('~n~`-t~50|~n'), print_rule_block(ID, Cy) )),
        format('~n~`-t~50|~n'),
        format('STEP 3 - REASONING SUMMARY~n'),
        forall(member(fired(ID, Cy), Fired),
               ( rule(ID, _, issue(C), _, _, _, _),
                 issue_label(C, CL),
                 format('   cycle ~w: ~w  =>  ~w~n', [Cy, ID, CL]) )),
        format('~nSTEP 4 - FINAL CONCLUSION~n'),
        findall(C, ( member(fired(ID,_), Fired),
                     rule(ID,_,issue(C),_,_,_,_) ), Cs0),
        sort(Cs0, Cs),
        length(Cs, NC),
        format('   ~w distinct energy-efficiency issue(s) identified:~n', [NC]),
        forall(member(C, Cs), ( issue_label(C, L), format('     - ~w~n', [L]) ))
    ).

%  ---------- backward chaining report ----------
print_proof_report(Goal, Result, Answers) :-
    Goal = issue(G), issue_label(G, GL),
    format('ECOHOME EXPERT - BACKWARD CHAINING~n'),
    format('GOAL: is there a "~w" problem?~n~n', [GL]),
    (   Result = proof(P)
    ->  format('GOAL PROVED. Proof tree:~n'),
        print_proof(P, 1),
        P = rule_proof(ID, _, _),
        rule(ID, _, _, _, Diag, Rec, Src),
        format('~nDiagnosis: ~w~nRecommended action: ~w~n', [Diag, Rec]),
        print_sources(Src)
    ;   format('GOAL NOT PROVED with the answers given.~n'),
        set_answers(Answers),
        why_not(Goal, Reasons),
        format('Rules that could prove it, and what was missing:~n'),
        forall(member(ID-M, Reasons),
               ( describe_condition(M, T),
                 format('   rule ~w: not satisfied -> ~w~n', [ID, T]) ))
    ).

print_proof(rule_proof(ID, issue(X), Subs), D) :-
    indent(D), issue_label(X, L),
    format('GOAL ~w  <=  proved by rule ~w~n', [L, ID]),
    D1 is D + 1,
    forall(member(S, Subs), print_proof(S, D1)).
print_proof(fact(F), D) :-
    indent(D), describe_condition(F, T), format('FACT  ~w  [user answer]~n', [T]).
print_proof(count(N, Is), D) :-
    indent(D), length(Is, Len),
    format('COUNT ~w issues found (need at least ~w)~n', [Len, N]).

indent(D) :- N is D * 3, format('~*c', [N, 0' ]).

%  ---------- helpers that return strings (used by the GUI and tests) ----------
report_string(Answers, Fired, S) :-
    with_output_to(string(S), print_forward_report(Answers, Fired)).
proof_string(Goal, Result, S) :-
    current_answers(A),
    with_output_to(string(S), print_proof_report(Goal, Result, A)).
