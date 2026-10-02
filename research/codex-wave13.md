# Codex wave 13: safe-before-playtest queue (spare budget until 10/03 17:25Z)
Base: integrate/wave12 f479e52. HARD RULE: do not edit Hud.client.luau, WaveManager.server.luau or DeathFlow.luau (they are frozen until the first-minute playtest). If a task seems to need them, stop at the pure module + spec and note the hook point in RESULT.
Rules: failing spec first, listed files plus one spec, no blood, prices 0, plain names, no new dependencies.
testcmd: cd game && stylua --check src tests && selene src && lune run tests/run.luau && rojo build default.project.json -o out.rbxl

## C1 Co-op element combos (our "beat Final Swarm" hook)
Shared/ElementCombos.luau (pure): when an enemy carries one element status (Nature root, Tech mark, Lightning charge, Dark curse) and a different player hits it with another element, resolve a combo (e.g. Lightning on rooted = Chain Storm, Dark on marked = Void Burst): name, bonus damage multiplier, radius, colour, cooldown per enemy. Status durations as data.
Spec tests/elementcombos.spec.luau: every element pair maps to exactly one combo or none; same-element never combos; multipliers 1.2-2.5; per-enemy cooldown respected by a pure canTrigger(now, last).

## C2 Balance simulator
tools/balance_sim.luau (Lune script, not shipped): simulate each weapon (+ evolutions, + Upgrades levels from Config) vs WaveTable HP scaling for waves 1-25; print a markdown table of time-to-kill per enemy type per wave and expected wave reached. Pure core in Shared/BalanceMath.luau.
Spec tests/balancemath.spec.luau: DPS formula matches weapon stats; wave-1 Walker TTK with starter weapon <= 1.0 s; wave-10 Walker TTK with a level-5 upgraded starter between 0.5 and 3 s.

## C3 Wave composition 1-25 (data only)
WaveTable.luau only: explicit composition per wave (which types, counts, boss every 5), new enemy type introduced at most one per wave, Spitter not before wave 3, Flyer not before wave 4.
Spec tests/wavecomposition.spec.luau: total threat (sum HP x count) non-decreasing except the wave after a boss (breather); introductions as above; wave 1 stays 8 Walkers.

## C4 Weapon role pass (data only)
Shared/Weapons (or wherever weapon stats live): give each weapon a clear role (Starter, Shotgun close, Sniper long, Sword melee arc, Scythe sweep, Laser beam) via Range/Spread/Damage/FireRate; rarity ladder on raw DPS.
Spec tests/weaponroles.spec.luau: at equal rarity no weapon's single-target DPS exceeds another's by > 35%; each weapon has a unique best range band; higher rarity strictly more DPS within a family.

## C5 Server-side combat validation
Combat.server.luau + Shared/FireGuard.luau (pure): reject fire requests faster than the weapon's fire rate (+10% tolerance), origin farther than 8 studs from the character, or direction NaN; count rejects per player and log once per minute.
Spec tests/fireguard.spec.luau: legit cadence accepted; double-rate rejected; far origin rejected; NaN rejected.

## C6 Effect pooling (perf)
ClientFX.luau: pool tracers, hit sparks, damage-number billboards and goo decals (pre-create N, reuse, never Instance.new per hit once warm); Shared/PoolSize.luau pure sizing by Quality level.
Spec tests/pool.spec.luau (pure pool logic): acquire/release reuses objects; never exceeds cap; oldest recycled when full.

## C7 Three maps as data (was B2)
Shared/Maps.luau: Station Deck (bright dusk), Hive Caves (Deep Rock style purple/teal, glowing crystal lights), Overgrown Hangar (sunbeams). Each: lighting preset key, spawn points, prop list, boss, floor colour. ArenaBuilder reads the selected map (default Station Deck). No HUD/WaveManager changes; selection via a GameState value defaulting to Station Deck.
Spec tests/maps.spec.luau: valid preset keys; >= 6 spawns inside bounds; floor-vs-enemy contrast >= 3 per map (reuse enemylook math); unique names.

## C8 First-minute telemetry funnel
Shared/Funnel.luau (pure schema) + emit from Combat.server and LevelUp code paths: run_start, first_hit, first_kill (seconds since start), first_levelup, first_damage_taken, death (wave, seconds). Server-only, via existing Telemetry.
Spec tests/funnel.spec.luau: each event builds with required fields; times non-negative; events fire once per run (pure dedupe).

## C9 CI gate on GitHub
.github/workflows/gate.yml: on push and PR, install stylua, selene, lune and rojo (pinned versions, via rokit or release downloads), run the testcmd. Add rokit.toml (or aftman.toml) pinning the same versions used locally (rojo 7.4.4).
Acceptance: workflow file validates (actionlint if available); README section "CI".

Order: C1, C5, C2, C3, C4, C7, C6, C8, C9. Two at a time.
