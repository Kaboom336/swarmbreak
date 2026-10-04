# Codex E1b: perk goals count Gold too (2026-10-04)
Base: codex/w23-e1 at f060489. Push to codex/w23-e1.

testcmd: cd game && stylua --check src tests && selene src && lune run tests/run.luau && lune run ../tools/lint_runtime_apis.luau && rojo build default.project.json -o out.rbxl

Goals.luau around line 70: perk goals only look at Gems.
- Make a perk goal funded only when **both** `p.Gold >= cost.Gold` and Gems are enough.
- The goal's gap is the scarcer of the two currencies, measured as a fraction of its cost.
- Its label shows the missing currency, for example "Max HP Lv 3: need 120 Gold".
- Goals.next must never recommend a perk that buyPerk would reject.
- Failing spec first: with enough Gems but too little Gold, the perk is not funded, and the gap is greater than 0.
