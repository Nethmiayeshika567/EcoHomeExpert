%  test_system.pl  --  EcoHome Expert automated tests (PlUnit)
%  Run:  swipl -q -s test_system.pl -g run_tests -t halt

:- use_module(library(plunit)).
:- use_module(knowledge_base).
:- use_module(inference_engine).
:- use_module(explanation).

% Baseline: a well-run, efficient home. No rule should fire.
base([ air_filter=clean, filter_age=within_3_months, hvac_tuneup=within_year,
       hvac_age=under_10_years, hvac_comfort=comfortable, thermostat_type=smart,
       home_unoccupied=no, duct_condition=sealed_insulated, draft_source=none,
       window_condition=good, attic_insulation=adequate, wall_insulation=insulated,
       lighting_type=led, lights_left_on=no, water_heater_temp=at_or_below_120f,
       water_heater_blanket=yes, hot_water_pipes=insulated, refrigerator_age=efficient,
       appliances=efficient, standby_devices=unplugged, computer_idle=turned_off,
       shade_trees=yes, cooling_used=yes ]).

% case(TestId, Description, Overrides, ExpectedFiredRules)
case(t01, 'dirty filter',                 [air_filter=looks_dirty],            [r01]).
case(t02, 'filter older than 3 months',   [filter_age=over_3_months],          [r02]).
case(t03, 'no tune-up for over a year',   [hvac_tuneup=over_year],             [r03]).
case(t04, 'HVAC older than 10 years',     [hvac_age=over_10_years],            [r04]).
case(t05, 'HVAC not comfortable',         [hvac_comfort=not_comfortable],      [r05]).
case(t06, 'manual thermostat',            [thermostat_type=manual],            [r06]).
case(t07, 'manual thermostat + empty home',
     [thermostat_type=manual, home_unoccupied=yes],                            [r06, r07]).
case(t08, 'leaky ducts',                  [duct_condition=leaky_or_uninsulated],[r08]).
case(t09, 'utility-gap air leaks',        [draft_source=utility_gaps],         [r09]).
case(t10, 'window drafts',                [draft_source=windows],              [r10]).
case(t11, 'door drafts',                  [draft_source=doors],                [r11]).
case(t12, 'leaky windows',                [window_condition=leaky],            [r12]).
case(t13, 'thin attic insulation',        [attic_insulation=inadequate],       [r13]).
case(t14, 'uninsulated walls',            [wall_insulation=uninsulated],       [r14]).
case(t15, 'old bulbs',                    [lighting_type=old_bulbs],           [r15]).
case(t16, 'lights left on',               [lights_left_on=yes],                [r16]).
case(t17, 'water heater too hot',         [water_heater_temp=above_120f],      [r17]).
case(t18, 'no water-heater blanket',      [water_heater_blanket=no],           [r18]).
case(t19, 'uninsulated hot-water pipes',  [hot_water_pipes=uninsulated],       [r19]).
case(t20, 'aging refrigerator',           [refrigerator_age=aging],            [r20]).
case(t21, 'aging appliances',             [appliances=aging],                  [r21]).
case(t22, 'devices left plugged in',      [standby_devices=plugged_in],        [r22]).
case(t23, 'computer left on',             [computer_idle=left_on],             [r23]).
case(t24, 'no shade + AC in use',         [shade_trees=no],                    [r24]).
case(t25, 'old HVAC + leaky ducts (chained)',
     [hvac_age=over_10_years, duct_condition=leaky_or_uninsulated],            [r04, r08, r25]).
case(t26, 'old HVAC + big air leaks (chained)',
     [hvac_age=over_10_years, draft_source=utility_gaps],                      [r04, r09, r26]).
case(t27, 'dirty filter + no tune-up (chained)',
     [air_filter=looks_dirty, hvac_tuneup=over_year],                          [r01, r03, r27]).
case(t28, 'five separate issues -> energy audit (chained)',
     [thermostat_type=manual, lights_left_on=yes, computer_idle=left_on,
      standby_devices=plugged_in, hot_water_pipes=uninsulated],
     [r06, r16, r19, r22, r23, r28]).

scenario(Overrides, Answers) :-
    base(Base),
    findall(K=V, ( member(K=V0, Base),
                   ( memberchk(K=V1, Overrides) -> V = V1 ; V = V0 ) ), Answers).

fired_ids(Answers, Ids) :-
    forward_chain(Answers, Fired),
    findall(ID, member(fired(ID,_), Fired), L), sort(L, Ids).

:- begin_tests(ecohome_expert).

test(knowledge_base_size) :-
    aggregate_all(count, ( question(_,_,_,O), member(_,O) ), Facts),
    aggregate_all(count, rule(_,_,_,_,_,_,_), Rules),
    Facts >= 20, Rules >= 20.

test(rule_ids_unique) :-
    findall(ID, rule(ID,_,_,_,_,_,_), L), sort(L, S), length(L, N), length(S, N).

test(every_rule_has_valid_sources) :-
    forall(rule(_,_,_,_,_,_,Src), forall(member(S, Src), source(S,_,_))).

test(every_condition_is_askable_or_derivable) :-
    forall(( rule(_,Cs,_,_,_,_,_), member(C, Cs), C = (K=V) ),
           ( question(K,_,_,Opts), memberchk(V-_, Opts) )).

test(baseline_home_fires_nothing) :-
    base(B), fired_ids(B, []).

test(forward_rule, [forall(case(Id, _, Over, Expected)), true(Ids == Expected)]) :-
    Id = Id, scenario(Over, A), fired_ids(A, Ids).

test(backward_proves_chained_goal) :-
    scenario([hvac_age=over_10_years, duct_condition=leaky_or_uninsulated], A),
    set_answers(A), retractall_asker,
    backward_chain(issue(fix_ducts_before_hvac), rule_proof(r25, _, Subs)),
    length(Subs, 2).

test(backward_fails_when_unsupported, [fail]) :-
    base(B), set_answers(B), retractall_asker,
    backward_chain(issue(dirty_filter), _).

test(backward_ask_on_demand) :-
    % only the questions needed for the goal are asked
    clear_answers, retractall(user:asked(_)),
    set_asker(fake_asker),
    backward_chain(issue(dirty_filter), _),
    findall(K, user:asked(K), Ks), Ks == [air_filter],
    retractall_asker.

test(why_not_explains_failure) :-
    base(B), set_answers(B), retractall_asker,
    why_not(issue(door_air_leak), [r11-(draft_source=doors)]).

test(forward_and_backward_agree) :-
    forall(case(_, _, Over, _),
           ( scenario(Over, A), forward_chain(A, F), set_answers(A), retractall_asker,
             forall(( member(fired(ID,_), F), rule(ID,_,issue(G),_,_,_,_) ),
                    backward_chain(issue(G), _)) )).

test(explanation_mentions_rule_and_source) :-
    scenario([air_filter=looks_dirty], A), forward_chain(A, F),
    report_string(A, F, S),
    once(sub_string(S, _, _, _, "Rule r01")),
    once(sub_string(S, _, _, _, "IF:")),
    once(sub_string(S, _, _, _, "Knowledge sources")),
    once(sub_string(S, _, _, _, "energystar.gov")).

:- end_tests(ecohome_expert).

:- dynamic asked/1.
fake_asker(Key, looks_dirty) :- assertz(asked(Key)).
retractall_asker :- set_asker(no_asker).
no_asker(_, _) :- fail.
