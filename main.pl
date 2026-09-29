%  main.pl  --  EcoHome Expert : command-line interface
%  Run:  swipl -q -s main.pl -g start -t halt

:- use_module(knowledge_base).
:- use_module(inference_engine).
:- use_module(explanation).
:- use_module(library(readutil)).

start :-
    repeat,
        banner,
        format('1. Start Energy Assessment (forward chaining)~n'),
        format('2. Check a Specific Problem (backward chaining)~n'),
        format('3. View Knowledge Base~n'),
        format('4. Exit~n~nEnter option: '),
        read_choice(4, Opt),
        do_option(Opt),
    Opt == 4, !.

banner :-
    format('~n=========================================~n'),
    format('             ECOHOME EXPERT~n'),
    format('  Home Energy Efficiency Troubleshooting~n'),
    format('=========================================~n').

do_option(1) :- forward_session.
do_option(2) :- backward_session.
do_option(3) :- show_kb.
do_option(4) :- format('Goodbye.~n').

% ---------- forward chaining : ask everything, then fire rules ----------
forward_session :-
    clear_answers,
    findall(K, question(K, _, _, _), Keys),
    forall(member(K, Keys), ( cli_ask(K, V), assertz_answer(K, V) )),
    current_answers(Answers),
    forward_chain(Answers, Fired),
    format('~n~n'),
    print_forward_report(Answers, Fired).

assertz_answer(K, V) :- current_answers(L), set_answers([K=V|L]).

% ---------- backward chaining : goal first, ask only what is needed ----------
backward_session :-
    findall(G, goal_issue(G), Goals),
    format('~nChoose the problem you want to check:~n'),
    forall(nth1(I, Goals, G),
           ( issue_label(G, L), format('  ~w. ~w~n', [I, L]) )),
    length(Goals, N),
    format('Enter number: '), read_choice(N, Ix),
    nth1(Ix, Goals, Goal),
    clear_answers,
    set_asker(cli_ask),
    format('~nI will only ask the questions needed to prove or disprove this goal.~n'),
    (   backward_chain(issue(Goal), Proof) -> Result = proof(Proof) ; Result = fail ),
    retractall_asker,
    format('~n'),
    current_answers(A),
    print_proof_report(issue(Goal), Result, A).

retractall_asker :- set_asker(none_asker).
none_asker(_, _) :- fail.

% ---------- asking a question ----------
cli_ask(Key, Value) :-
    question(Key, Text, _, Opts),
    format('~n~w~n', [Text]),
    forall(nth1(I, Opts, _-Label), format('  ~w. ~w~n', [I, Label])),
    length(Opts, N),
    format('Answer: '), read_choice(N, Ix),
    nth1(Ix, Opts, Value-_).

read_choice(Max, Choice) :-
    repeat,
        read_line_to_string(user_input, S),
        (   S == end_of_file -> Choice = Max, !
        ;   number_string(Choice, S), integer(Choice), between(1, Max, Choice) -> !
        ;   format('Please enter a number between 1 and ~w: ', [Max]), fail
        ).

% ---------- view KB ----------
show_kb :-
    aggregate_all(count, question(_,_,_,_), NQ),
    aggregate_all(count, ( question(_,_,_,O), member(_, O) ), NF),
    aggregate_all(count, rule(_,_,_,_,_,_,_), NR),
    format('~nKNOWLEDGE BASE: ~w questions, ~w possible facts, ~w rules~n~n', [NQ, NF, NR]),
    forall(rule(ID, Conds, issue(C), Cat, _, Rec, Src),
           ( issue_label(C, CL),
             format('~w [~w] IF ~w THEN ~w~n     ACTION: ~w~n     SOURCE: ~w~n',
                    [ID, Cat, Conds, CL, Rec, Src]) )).
