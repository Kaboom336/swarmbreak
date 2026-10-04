# Codex E1: bank Gold and Gems from raids (2026-10-04). Follow game-bible-v3.md, "Loop" step 3
Base: integrate/wave13 at 604aecd. Branch: codex/w23-e1.

Rules:
- Runtime-safe APIs only.
- Failing spec first.
- Prices 0 for anything sold for Robux. Plain names.

testcmd: cd game && stylua --check src tests && selene src && lune run tests/run.luau && lune run ../tools/lint_runtime_apis.luau && rojo build default.project.json -o out.rbxl

1. **ProfileSchema:**
   - Add persistent `Gold` (sanitize keeps it; negative or NaN becomes 0).
   - In-run Coins stay as they are, but are renamed "Gold" in the UI.
2. **Deposit at raid end** (pure `Shared/Deposit.luau`):
   - Banked Gold = run Gold × rate. The rate is 100% on a clear, 50% on death, and 0% on leaving early.
   - Gems are collected in-run as now, banked the same way.
   - The run summary shows "Deposited: X Gold, Y Gems" with a count-up.
3. **Stat upgrades** (persistent, extending ProfileSchema perks):
   - The perks are Max HP, Damage %, Move Speed %, Dash charges, Gold find %, Gem find %.
   - Each perk costs Gold and Gems with a rising cost curve (pure table, MaxLevel 10).
   - Run-only level-up cards still reset at the end of a raid.
4. **Lobby:** the existing upgrade board shows both currencies and the new perks. No new buildings yet; the hub comes later with the kit art.
5. **Specs:**
   - Sanitizing keeps Gold.
   - Deposit rates for each run outcome.
   - The cost curve rises monotonically and caps at MaxLevel.
   - A perk purchase fails cleanly when either currency is short.
   - Movement Speed % feeds MovementTuning.runSpeed without stacking the sprint multiplier twice.
