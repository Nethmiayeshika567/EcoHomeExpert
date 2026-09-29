%  knowledge_base.pl  --  EcoHome Expert
%  Facts (questions / possible answers), sources and production rules.
%  Every rule cites the source(s) it was derived from.

:- module(knowledge_base,
          [ source/3, question/4, rule/7, goal_issue/1, audit_threshold/1 ]).


source(s1, 'ENERGY STAR - Heat & Cool Efficiently',
      'https://www.energystar.gov/saveathome/heating-cooling').
source(s2, 'U.S. DOE (FEMP) - Home Energy Checklist',
      'https://www.energy.gov/cmei/femp/home-energy-checklist').
source(s3, 'ENERGY STAR - Seal and Insulate with ENERGY STAR',
      'https://www.energystar.gov/saveathome/seal_insulate').


question(air_filter, 'What does your heating/cooling air filter look like?', hvac,
         [clean-'Clean', looks_dirty-'Looks dirty']).
question(filter_age, 'When was the air filter last changed?', hvac,
         [within_3_months-'Within the last 3 months',
          over_3_months-'More than 3 months ago']).
question(hvac_tuneup, 'When was the HVAC system last professionally serviced?', hvac,
         [within_year-'Within the last year', over_year-'More than a year ago']).
question(hvac_age, 'How old is your heating/cooling equipment?', hvac,
         [under_10_years-'Under 10 years', over_10_years-'Over 10 years']).
question(hvac_comfort, 'Does the HVAC system keep the house comfortable?', hvac,
         [comfortable-'Yes, comfortable', not_comfortable-'No, not comfortable']).
question(thermostat_type, 'What type of thermostat do you have?', hvac,
         [manual-'Manual', programmable-'Programmable', smart-'Smart (Wi-Fi)']).
question(home_unoccupied, 'Is the home empty for most of the day?', hvac,
         [yes-'Yes', no-'No']).
question(duct_condition, 'What is the condition of your air ducts?', hvac,
         [sealed_insulated-'Sealed and insulated',
          leaky_or_uninsulated-'Leaky or uninsulated',
          no_ducts-'No ducts / not sure']).
question(draft_source, 'Where do you feel drafts or air leaks?', envelope,
         [none-'No drafts', windows-'Around windows', doors-'Around doors',
          utility_gaps-'Pipes, chimney, recessed lights, behind cupboards']).
question(window_condition, 'What is the condition of your windows?', envelope,
         [good-'Good', leaky-'Old or leaky']).
question(attic_insulation, 'Is your attic insulation adequate?', envelope,
         [adequate-'Adequate', inadequate-'Thin / inadequate']).
question(wall_insulation, 'Are your walls insulated?', envelope,
         [insulated-'Yes', uninsulated-'No']).
question(lighting_type, 'What type of lights do you mostly use?', lighting,
         [led-'LED', old_bulbs-'Incandescent or fluorescent']).
question(lights_left_on, 'Are lights often left on in empty rooms?', lighting,
         [yes-'Yes', no-'No']).
question(water_heater_temp, 'What is your water heater temperature setting?', water,
         [at_or_below_120f-'120 F (49 C) or lower', above_120f-'Above 120 F (49 C)']).
question(water_heater_blanket, 'Does your water heater have an insulating blanket?', water,
         [yes-'Yes', no-'No']).
question(hot_water_pipes, 'Are your hot-water pipes insulated?', water,
         [insulated-'Yes', uninsulated-'No']).
question(refrigerator_age, 'How is your refrigerator?', appliances,
         [efficient-'Recent / efficient', aging-'Aging or inefficient']).
question(appliances, 'How are your other major appliances?', appliances,
         [efficient-'Recent / efficient', aging-'Aging or inefficient']).
question(standby_devices, 'Are idle chargers, printers, coffeemakers etc. left plugged in?', electronics,
         [unplugged-'Unplugged when idle', plugged_in-'Left plugged in']).
question(computer_idle, 'What happens to your computer/monitor when not in use?', electronics,
         [turned_off-'Turned off', left_on-'Left on']).
question(shade_trees, 'Is your house shaded by trees or shrubs (hot climate)?', cooling,
         [yes-'Yes', no-'No']).
question(cooling_used, 'Do you use air conditioning regularly?', cooling,
         [yes-'Yes', no-'No']).



% ---------- Heating & cooling (S1, S2) ----------
rule(r01, [air_filter=looks_dirty], issue(dirty_filter), hvac,
     'A dirty filter slows air flow and makes the system work harder, wasting energy.',
     'Change the filter now. Check it monthly; if it looks dirty after a month, change it.',
     [s1, s2]).
rule(r02, [filter_age=over_3_months], issue(overdue_filter), hvac,
     'The filter has gone past the minimum replacement interval of 3 months.',
     'Replace the filter and change it at least every 3 months.',
     [s1]).
rule(r03, [hvac_tuneup=over_year], issue(hvac_tuneup_due), hvac,
     'The heating/cooling system has missed its yearly professional tune-up.',
     'Book a professional HVAC tune-up (annual maintenance).',
     [s1, s2]).
rule(r04, [hvac_age=over_10_years], issue(hvac_evaluation_needed), hvac,
     'Heating/cooling equipment older than 10 years may be inefficient.',
     'Have the equipment evaluated by a professional HVAC contractor.',
     [s1]).
rule(r05, [hvac_comfort=not_comfortable], issue(hvac_evaluation_needed), hvac,
     'The system is not keeping the house comfortable.',
     'Have the equipment evaluated by a professional HVAC contractor.',
     [s1]).
rule(r06, [thermostat_type=manual], issue(manual_thermostat), hvac,
     'A manual thermostat cannot set temperatures back automatically.',
     'Install a programmable thermostat and set it back automatically at night.',
     [s2]).
rule(r07, [thermostat_type=manual, home_unoccupied=yes], issue(smart_thermostat_opportunity), hvac,
     'The home is empty much of the day but the thermostat is manual, so heating/cooling runs when not needed.',
     'Install an ENERGY STAR certified smart thermostat (homes unoccupied much of the day can save about $100 a year).',
     [s1, s2]).
rule(r08, [duct_condition=leaky_or_uninsulated], issue(duct_loss), hvac,
     'Leaky or uninsulated ducts are a big energy waster.',
     'Seal duct seams with mastic or foil tape, starting with ducts in attic, crawlspace, unheated basement or garage, then insulate them.',
     [s1, s2]).

% ---------- Air sealing, windows, insulation (S1, S2, S3) ----------
rule(r09, [draft_source=utility_gaps], issue(major_air_leak), envelope,
     'Gaps around pipes, chimneys, recessed lights or behind cupboards are usually the worst air leaks.',
     'Seal the largest air leaks first; consider an energy auditor with a blower door.',
     [s2, s3]).
rule(r10, [draft_source=windows], issue(window_air_leak), envelope,
     'Air is leaking around the windows.',
     'Caulk around window trim, use rope caulk, or apply plastic film over the window.',
     [s2, s3]).
rule(r11, [draft_source=doors], issue(door_air_leak), envelope,
     'Air is leaking around the doors.',
     'Install weather stripping on the doors and seal behind door trim.',
     [s3]).
rule(r12, [window_condition=leaky], issue(leaky_windows), envelope,
     'Leaky windows lose heat; a typical home loses more than 25% of its heat through windows.',
     'Add weatherstripping and storm windows, or replace with energy-efficient windows.',
     [s2]).
rule(r13, [attic_insulation=inadequate], issue(attic_insulation_low), envelope,
     'Inadequate attic insulation reduces comfort and raises energy use.',
     'Air-seal the attic, then bring attic insulation up to the recommended level.',
     [s2, s3]).
rule(r14, [wall_insulation=uninsulated], issue(walls_uninsulated), envelope,
     'Uninsulated walls let heat escape.',
     'Have an insulation contractor blow cellulose insulation into the walls.',
     [s2]).

% ---------- Lighting (S2) ----------
rule(r15, [lighting_type=old_bulbs], issue(inefficient_lighting), lighting,
     'Incandescent and fluorescent lights use more energy than LEDs.',
     'Replace incandescent/fluorescent bulbs with LEDs, starting with bulbs used several hours a day.',
     [s2]).
rule(r16, [lights_left_on=yes], issue(lights_left_on), lighting,
     'Lights left on in unoccupied rooms waste electricity.',
     'Turn lights off in empty rooms, or install timers, photo cells or occupancy sensors.',
     [s2]).

% ---------- Water heating (S2) ----------
rule(r17, [water_heater_temp=above_120f], issue(water_heater_too_hot), water,
     'The water heater is set hotter than the recommended setting.',
     'Turn the water heater down to the warm setting (120 F / 49 C); it saves energy and avoids scalding.',
     [s2]).
rule(r18, [water_heater_blanket=no], issue(water_heater_uninsulated), water,
     'The water heater has no insulating blanket.',
     'Fit a water-heater insulating blanket; it can pay for itself in a year or less.',
     [s2]).
rule(r19, [hot_water_pipes=uninsulated], issue(pipes_uninsulated), water,
     'Uninsulated hot-water pipes lose heat.',
     'Insulate the hot-water pipes to prevent heat loss.',
     [s2]).

% ---------- Appliances & electronics (S2) ----------
rule(r20, [refrigerator_age=aging], issue(old_refrigerator), appliances,
     'An aging refrigerator may be using much more energy than a modern one.',
     'Check the refrigerator age and condition; consider a top-efficiency ENERGY STAR model.',
     [s2]).
rule(r21, [appliances=aging], issue(old_appliances), appliances,
     'Aging, inefficient appliances waste energy even if they still work.',
     'Replace with top-efficiency ENERGY STAR labeled models (can cut energy bills by up to 30%).',
     [s2]).
rule(r22, [standby_devices=plugged_in], issue(standby_loss), electronics,
     'Chargers and other devices drain energy when plugged in but not in use.',
     'Unplug equipment that drains energy when not in use.',
     [s2]).
rule(r23, [computer_idle=left_on], issue(computer_left_on), electronics,
     'A computer and monitor left on when idle waste energy.',
     'Turn off the monitor after 20 minutes idle, and the CPU too if unused for over 2 hours.',
     [s2]).

% ---------- Cooling (S2) ----------
rule(r24, [shade_trees=no, cooling_used=yes], issue(no_shade), cooling,
     'An unshaded house using air conditioning has higher cooling costs.',
     'Plant shade trees and shrubs around the house to reduce air-conditioning costs.',
     [s2]).

% ---------- Chained rules: use conclusions of earlier rules (forward/backward chaining) ----------
rule(r25, [issue(hvac_evaluation_needed), issue(duct_loss)], issue(fix_ducts_before_hvac), chained,
     'Ducts are leaky and the HVAC equipment may need replacing; ducts may be the real source of the problem.',
     'Before investing in new HVAC equipment, seal and insulate the ducts.',
     [s1]).
rule(r26, [issue(hvac_evaluation_needed), issue(major_air_leak)], issue(fix_leaks_before_hvac), chained,
     'Big air leaks are present and the HVAC equipment may need replacing; leaks may be the real source of the problem.',
     'Before investing in new HVAC equipment, seal the big air leaks in the house.',
     [s1, s2]).
rule(r27, [issue(dirty_filter), issue(hvac_tuneup_due)], issue(hvac_neglected), chained,
     'Both filter care and yearly servicing have been neglected, so the system is likely running inefficiently.',
     'Change the filter immediately and schedule the professional tune-up.',
     [s1]).
% r28 uses issues_at_least(N): N is a design threshold chosen by the system
% designer (not a figure from the sources); DOE recommends an energy audit for
% advice on the home as a whole.
rule(r28, [issues_at_least(5)], issue(needs_energy_audit), chained,
     'Many separate energy-wasting conditions were found in the home.',
     'Schedule a home energy audit (ask your utility or state energy office) to prioritise the fixes.',
     [s2]).

audit_threshold(5).

%  Goals available for backward chaining (every concluded issue)
goal_issue(Name) :-
    setof(N, ID^C^Ca^D^Rc^S^( rule(ID, C, issue(N), Ca, D, Rc, S) ), L),
    member(Name, L).
