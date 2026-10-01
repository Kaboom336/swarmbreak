# Codex wave 1 (Swarm Break, 2026-10-01)

Repo: https://github.com/Kaboom336/swarmbreak (private), branch off main, one branch per task (codex/<task>), push the branch, do not merge.
Game lives in game/. Pure modules sit in game/src/ReplicatedStorage/Shared/ (no Roblox globals; the server passes os.time()); tests are game/tests/*.spec.luau, loaded by game/tests/run.luau with `load("<Module>")`, `test(name, fn)`, `eq(a, b, msg)` (copy the style of tests/daily.spec.luau). Code is --!strict Luau, must pass stylua and selene. Plain English names, placeholder numbers, no blood.
Tools needed: stylua, selene, lune (cargo install or GitHub releases; versions any recent).

## Task 1: Daily quests (pure module + tests + server wiring)
Goal: three daily quests per player that reset at midnight UTC and pay Gems, so players have a reason to come back each day.
- New game/src/ReplicatedStorage/Shared/Quests.luau: `Quests.Defs` (8-10 quests: kill N enemies, reach wave N, kill a boss, deal N damage with a Melee weapon, open a crate, finish a run, pick N wave rewards, play with a friend), each { Id, Text, Stat, Target, Gems }. `Quests.forDay(dayIndex, userId): {string}` picks 3 distinct ids deterministically (same day + user = same quests; use a simple LCG seeded from dayIndex*1e6+userId, no math.random). `Quests.progress(state, stat, amount)` returns new state; `Quests.claim(state, id)` returns (state, gems) only when complete and not claimed; `Quests.evaluate(state, now)` resets when the stored day differs (reuse Daily.dayIndex).
- ProfileSchema.luau: add a `Quests` field { Day, Ids, Progress, Claimed } with defaults, and make sanitize keep it valid.
- game/src/ServerStorage/PlayerData.luau: call Quests.progress on kill / wave reached / boss kill / crate open / run end; push quest state to the client with the existing stats push.
- tests/quests.spec.luau: deterministic picks, 3 distinct ids, reset on new day, progress caps at Target, claim only once, sanitize repairs junk.

## Task 2: Daily mutations (pure module + tests + wave hook)
Goal: one global modifier per UTC day ("Fast Swarm", "Armored", "Glass Cannon", "Big Bosses", "Double Coins", "Low Gravity", "Swarm x2") so runs feel different day to day.
- New Shared/Mutations.luau: `Mutations.Defs` with Id, Label, Blurb and numeric mods (EnemySpeedMult, EnemyHealthMult, PlayerDamageMult, BossScale, CoinMult, Gravity, SpawnMult); `Mutations.forDay(dayIndex)` deterministic, never the same as the previous day; `Mutations.apply(base, id)` returns a modified copy of a stats table without mutating input.
- Hook in game/src/ServerScriptService/WaveManager.server.luau and ServerStorage/EnemyAI.luau / PlayerData.luau where enemy and coin numbers are computed; publish today's mutation via GameState so the HUD can show "Today: <Label>".
- tests/mutations.spec.luau: defs well formed, deterministic, no repeat on consecutive days across 365 days, apply does not mutate input, CoinMult flows through.

## Task 3: Weekly leaderboard ranking (pure module + tests)
Goal: a weekly best-wave board that resets each Monday 00:00 UTC.
- New Shared/WeeklyBoard.luau: `weekIndex(now)` (Monday-based), `key(now)` -> "Week_<n>" for the OrderedDataStore name, `score(wave, timeSeconds)` that ranks higher wave first, then faster time (encode as one integer), `decode(score)` back to wave and time, `top(entries, n)` sorting ties by name.
- Wire game/src/ServerScriptService/Leaderboard.server.luau to write the weekly key at run end (keep the all-time board as is; wrap DataStore calls in pcall).
- tests/weeklyboard.spec.luau: week boundary at Monday 00:00 UTC, encode/decode round trip, ordering rules.

testcmd: cd game && stylua --check src tests && selene src && lune run tests/run.luau
