%  gui.pl  --  EcoHome Expert : graphical interface (XPCE)
%  Run:  swipl -q -s gui.pl

:- use_module(library(pce)).
:- use_module(knowledge_base).
:- use_module(inference_engine).
:- use_module(explanation).

:- dynamic keys/1, idx/1, ui/2, results/1.

:- initialization(gui, main).

gui :-
    retractall(ui(_, _)),
    findall(K, question(K, _, _, _), Keys),
    retractall(keys(_)), assertz(keys(Keys)),
    build_window,
    restart.

build_window :-
    new(F, frame('EcoHome Expert')),
    new(D, dialog),
    send(F, append, D),
    send(D, append, new(T, label(title, 'EcoHome Expert'))),
    send(T, font, font(helvetica, bold, 18)),
    send(D, append, label(sub, 'Home Energy Efficiency Troubleshooting Adviser')),
    send(D, append, new(Prog, label(progress, ''))),
    send(Prog, font, font(helvetica, bold, 12)),
    send(D, append, new(Q, label(question, ''))),
    send(Q, font, font(helvetica, roman, 12)),
    send(D, append, new(M, menu(answer, cycle))),
    send(D, append, new(Nx, button(next, message(@prolog, on_next)))),
    send(D, append, new(Rs, button(restart, message(@prolog, restart))), right),
    send(D, append, button(exit, message(F, destroy)), right),
    send(D, append, new(GM, menu(goal, cycle)), next_row),
    forall(goal_issue(G),
           ( issue_label(G, L), send(GM, append, menu_item(G, @default, L)) )),
    send(D, append, new(Pv, button(prove_goal, message(@prolog, on_prove)))),
    send(D, append, new(Sh, button(show_results, message(@prolog, on_show))), right),
    new(V, view),
    send(V, editable, @off),
    send(V, size, size(95, 26)),
    send(V, below, D),
    assertz(ui(frame, F)), assertz(ui(prog, Prog)), assertz(ui(q, Q)),
    assertz(ui(menu, M)), assertz(ui(next, Nx)), assertz(ui(restart, Rs)),
    assertz(ui(goal, GM)), assertz(ui(prove, Pv)), assertz(ui(show, Sh)),
    assertz(ui(view, V)),
    send(F, open).

restart :-
    retractall(idx(_)), assertz(idx(1)),
    clear_answers, retractall(results(_)),
    ui(view, V), send(V, clear),
    ui(goal, GM), send(GM, active, @off),
    ui(prove, Pv), send(Pv, active, @off),
    ui(show, Sh), send(Sh, active, @off),
    ui(menu, M), send(M, active, @on),
    ui(next, Nx), send(Nx, active, @on),
    show_question.

show_question :-
    idx(I), keys(Keys), nth1(I, Keys, Key),
    length(Keys, N),
    question(Key, Text, _, Opts),
    ui(prog, P), format(atom(PT), 'Question ~w of ~w', [I, N]), send(P, selection, PT),
    ui(q, Q), send(Q, selection, Text),
    ui(menu, M), send(M, clear),
    forall(member(Val-Label, Opts), send(M, append, menu_item(Val, @default, Label))),
    Opts = [First-_|_], send(M, selection, First),
    ui(frame, F), send(F, fit).

on_next :-
    idx(I), keys(Keys), nth1(I, Keys, Key),
    ui(menu, M), get(M, selection, Val),
    current_answers(L), append(L, [Key=Val], L1), set_answers(L1),
    length(Keys, N),
    (   I < N
    ->  I1 is I + 1, retractall(idx(_)), assertz(idx(I1)), show_question
    ;   finish
    ).

finish :-
    current_answers(Answers),
    forward_chain(Answers, Fired),
    report_string(Answers, Fired, S),
    retractall(results(_)), assertz(results(S)),
    ui(prog, P), send(P, selection, 'Assessment complete'),
    ui(q, Q), send(Q, selection, 'Review the recommendations below. You can also prove a specific goal (backward chaining).'),
    ui(menu, M), send(M, active, @off),
    ui(next, Nx), send(Nx, active, @off),
    ui(goal, GM), send(GM, active, @on),
    ui(prove, Pv), send(Pv, active, @on),
    ui(show, Sh), send(Sh, active, @on),
    show_text(S).

on_show :- ( results(S) -> show_text(S) ; true ).

on_prove :-
    ui(goal, GM), get(GM, selection, G),
    (   backward_chain(issue(G), Proof) -> Result = proof(Proof) ; Result = fail ),
    proof_string(issue(G), Result, S),
    show_text(S).

show_text(S) :-
    ui(view, V), send(V, clear),
    atom_string(A, S), send(V, append, A).
