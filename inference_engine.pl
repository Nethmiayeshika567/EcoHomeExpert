%  inference_engine.pl  --  EcoHome Expert
%  Forward chaining (data-driven) and backward chaining (goal-driven).

:- module(inference_engine,
          [ forward_chain/2,      % +Answers, -Fired
            set_answers/1,        % +Answers
            current_answers/1,    % -Answers
            clear_answers/0,
            set_asker/1,          % +Pred   (called as call(Pred, Key, Value))
            backward_chain/2,     % +Goal, -Proof
            why_not/2,            % +Goal, -Reasons
            working_memory/3      % +Answers, +Fired, -WM
          ]).

:- use_module(knowledge_base).
:- use_module(library(lists)).
:- use_module(library(error)).

/* ==================================================================
   FORWARD CHAINING
   ================================================================== */
forward_chain(Answers, Fired) :-
    must_be(list, Answers),
    fc_cycle(Answers, 1, [], Fired).

fc_cycle(Answers, Cycle, Fired0, Fired) :-
    working_memory(Answers, Fired0, WM),
    findall(fired(ID, Cycle),
            ( rule(ID, Conds, _, _, _, _, _),
              \+ memberchk(fired(ID, _), Fired0),
              all_hold(Conds, WM) ),
            New),
    (   New == []
    ->  Fired = Fired0
    ;   append(Fired0, New, Fired1),
        Next is Cycle + 1,
        fc_cycle(Answers, Next, Fired1, Fired)
    ).

%  Working memory = user answers + conclusions of all fired rules
working_memory(Answers, Fired, WM) :-
    findall(Concl, ( member(fired(ID, _), Fired),
                     rule(ID, _, Concl, _, _, _, _) ), Derived),
    append(Answers, Derived, WM).

all_hold([], _).
all_hold([C|Cs], WM) :- holds(C, WM), all_hold(Cs, WM).

holds(issues_at_least(N), WM) :- !,
    findall(X, ( member(issue(X), WM), X \== needs_energy_audit ), Xs),
    sort(Xs, Unique),
    length(Unique, Len),
    Len >= N.
holds(Cond, WM) :- memberchk(Cond, WM).

/* ==================================================================
   BACKWARD CHAINING
  
   ================================================================== */
:- dynamic answer/2.
:- dynamic asker/1.

set_answers(List) :-
    clear_answers,
    forall(member(K=V, List), assertz(answer(K, V))).

current_answers(List) :- findall(K=V, answer(K, V), List).

clear_answers :- retractall(answer(_, _)).

set_asker(Pred) :- retractall(asker(_)), assertz(asker(Pred)).

get_answer(Key, Value) :- answer(Key, Value), !.
get_answer(Key, Value) :-
    asker(Pred), !,
    call(Pred, Key, Value),
    assertz(answer(Key, Value)).

backward_chain(Goal, Proof) :- once(prove(Goal, Proof)).

prove(issues_at_least(N), count(N, Issues)) :- !,
    findall(X, ( goal_issue(X), X \== needs_energy_audit,
                 once(prove(issue(X), _)) ), Xs),
    sort(Xs, Issues),
    length(Issues, Len),
    Len >= N.
prove(issue(X), rule_proof(ID, issue(X), Subs)) :-
    rule(ID, Conds, issue(X), _, _, _, _),
    prove_all(Conds, Subs).
prove(Key=Value, fact(Key=Value)) :-
    get_answer(Key, Value0),
    Value0 == Value.

prove_all([], []).
prove_all([C|Cs], [P|Ps]) :- once(prove(C, P)), prove_all(Cs, Ps).

%  why_not(+Goal, -Reasons): for every rule that could conclude Goal,
%  report the first condition that is not satisfied (explains a failed proof).
why_not(issue(X), Reasons) :-
    findall(ID-Missing,
            ( rule(ID, Conds, issue(X), _, _, _, _),
              first_unmet(Conds, Missing) ),
            Reasons).

first_unmet([C|Cs], Missing) :-
    (   static_holds(C) -> first_unmet(Cs, Missing) ; Missing = C ).

static_holds(Key=Value) :- !, answer(Key, Value).
static_holds(issue(X))  :- !, once(prove_quiet(issue(X))).
static_holds(issues_at_least(N)) :- prove_quiet(issues_at_least(N)).

%  prove without ever asking the user
prove_quiet(Goal) :-
    (   retract(asker(P)) -> Restore = yes ; Restore = no ),
    (   catch(once(prove(Goal, _)), _, fail) -> R = true ; R = false ),
    (   Restore == yes -> assertz(asker(P)) ; true ),
    R == true.
