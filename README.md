# EcoHome Expert
A Prolog rule-based expert system that diagnoses home energy-efficiency problems.
Knowledge source: ENERGY STAR and U.S. Department of Energy pages (see `knowledge_base.pl`).

## Requirements
* SWI-Prolog 9.x or 10.x (64-bit, includes XPCE for the GUI): https://www.swi-prolog.org/Download.html
* VS Code (optional, only as the code editor)

## Run
Open a terminal in this folder.

| What | Command |
|---|---|
| Graphical interface | `swipl -q -s gui.pl` |
| Command-line interface | `swipl -q -s main.pl -g start -t halt` |
| Automated tests | `swipl -q -s test_system.pl -g run_tests -t halt` |

## Files
* `knowledge_base.pl`  - sources, 23 questions (50 facts), 28 rules
* `inference_engine.pl` - forward chaining + backward chaining
* `explanation.pl`      - shows input facts, rules fired, reasoning, conclusion, source
* `gui.pl`              - XPCE graphical interface
* `main.pl`             - command-line interface
* `test_system.pl`      - PlUnit tests (39 tests)
