# Codex S5: balance and levelling, driven by a simulator (2026-10-03)

Why: Zion's playtest of 087839f said the levelling speed is off and the game feels aggressive. Plan: style-reset-plan.md.
Base: integrate/wave13 at 475b4d5 or later.

## Rules
- Runtime-safe APIs only.
- Failing spec first.
- Prices 0, plain names, no blood.

testcmd: cd game && stylua --check src tests && selene src && lune run tests/run.luau && lune run ../tools/lint_runtime_apis.luau && rojo build default.project.json -o out.rbxl

## 1. Shared/RunSim.luau (pure, deterministic, seeded)
Simulate one solo run, wave by wave, from the real data:
- WaveTable compositions and packs, Enemies HP, Damage and Speed, Difficulty scaling.
- Weapons DPS (BalanceMath) and LevelUp XP (KillXp, XpCurve).
- A simple player who auto-fires at the nearest enemy and takes every pick.

Output per wave: time to clear, level-up timestamps, peak attackers in contact range, and damage taken per second.

## 2. Targets (tests/runsim.spec.luau; tune the data until they pass)
- **First level-up** between 8 and 15 s after the first pack arrives.
- **Gap between level-ups** of 12-20 s for the first 2 minutes, widening smoothly to 25-40 s by wave 10. There must never be a 60 s+ drought before wave 15.
- **Early damage:** wave 1-3 damage taken stays at or below 6% of max HP per second with the Starter Pistol, and no single wave 1-5 can kill a player standing still in under 12 s.
- **Attackers:** at most 4 melee enemies attack at once (an attack-slot token per player, enforced in EnemyAI). Extra enemies circle at 6-9 studs and wait their turn. This keeps the crowd big without the swarm-kill feel.
- **Contact damage:** a 0.5 s i-frame window after each hit (PlayerData), shown by a white flash on the character.
- **Clear time:** wave clears take 35-70 s through wave 10, and Brute/Queen kills 20-40 s with an average build.

## 3. Wire-in
- EnemyAI uses the attack-slot token.
- PlayerData applies the i-frames.
- LevelUp, Enemies and WaveTable get only the data changes the simulator needs.
- Write the before/after numbers into the commit message (and into your final summary).
