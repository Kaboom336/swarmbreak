# Codex C1b: stages reach their own zones; stage-aware leaderboard (2026-10-04)
Base: codex/w24-c1 at a3aea88. Push to codex/w24-c1 (K1 rebases on it afterwards).

testcmd: cd game && stylua --check src tests && selene src && lune run tests/run.luau && lune run ../tools/lint_runtime_apis.luau && rojo build default.project.json -o out.rbxl

1. **Zones per stage** (WaveManager around lines 787-789):
   - Add a pure `ArenaLayout.layoutWave(zoneId, localWave)` = clamp(zone.FirstWave + localWave - 1, zone.FirstWave, zone.LastWave).
   - Everything that keys on the wave for **layout** uses it: gate eligibility (gateOpen), EnemyAI watchdog respawn, openBridges, bossSpawnForWave, the zone banners and the lighting zone. Publish it as `State.LayoutWave` for the server systems that read State.
   - The HUD keeps the local wave ("WAVE 3 / 8") from State.Wave.
   - At stage start: open every bridge up to the stage's zone (no banner), and spawn players in the stage's zone. Landing Pad stages are unchanged.
   - Spec: for a Refinery stage, the layout wave on local waves 1-8 stays within 6-10. Gates, the boss spot and bridges resolve to Refinery for a Refinery stage, and the same holds for Hive Core.
2. **Leaderboard** (PlayerData around lines 988-989):
   - Bump the store to `SwarmBreak_top_v2`.
   - Score = difficultyIndex × 10000 + stage × 100 + clearedWaves, where Nightmare beats Hard beats Normal. Leave the old v1 store unread.
   - Spec: the score is monotonic in difficulty, then stage, then waves.
