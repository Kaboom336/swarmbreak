# Codex wave 21: S4 Swarm Queen, then P1 enemy pool (2026-10-04). Follow game-bible-v2.md
Base: integrate/wave13 at 854263e or later. Do S4 and P1 on separate branches: codex/w21-s4 and codex/w21-p1.

Rules:
- Runtime-safe APIs only.
- Failing spec first.
- WaitForChild for sibling client modules.
- No blood: goo is teal. Prices 0.
- No Neon on anything bigger than 1.5 studs. Bloom stays as is.
- Shake: the intro gets one pulse of 0.3 or less, and nothing else shakes (Zion: "no shaky effects").

testcmd: cd game && stylua --check src tests && selene src && lune run tests/run.luau && lune run ../tools/lint_runtime_apis.luau && rojo build default.project.json -o out.rbxl

## S4: Swarm Queen
Follow the S4 section in codex-wave19-S3-S4-S6.md (intro, phase 1, the transition at 55%, the kill, and the specs), with these updates:
- The boss spawns at ArenaLayout.bossSpawnForWave(15), in Hive Core.
- Adds come from the Hive gates through ArenaLayout.gateOpen.
- The goo pool hazard uses floor rects from ArenaLayout.floorRects only. It must never cover a DashGap hole or a gate (the spec checks both).
- **Model:** our own, built from primitives for now, in the Nest motif: chitin plates, a goo-glass core and 8 legs. It is about 16 studs tall, with a Body, Head, Leg_1..8 and a Neck rig (the same joint names as the Nest rigs), so EnemyAnimator rig mode drives it. Put the boss in Rigs/Queen.json in the same format as the Mite rig, with no MeshIds (all parts are Part class). It is swappable later.
- **Slow-mo on the kill:** client time only, 0.6 s (Zion's answer is pending; keep it as a Feel constant).

## P1: enemy pool (Play saw a 275 ms hitch with 27 alive)
- **EnemyPool** (server): keep N ready clones per Nest rig key, parented to ServerStorage. Fill it at server start and refill it between waves; N comes from the next wave's WaveTable role counts, up to 12 per role.
- **EnemyRigBuilder.build** takes from the pool and clones only when the pool is empty.
- **On death:** after the dissolve, reset the model (Transparency, Color, joints C0/C1, Health) and return it to the pool. Never return it while the client ghost is still playing.
- **Spawns:** never more than 4 per Heartbeat; queue the rest.
- **Specs:**
  - The pure pool logic takes and returns the same instances (use a fake).
  - The refill count comes from the role counts.
  - The per-frame spawn cap.
- **Result:** the hitch shot list for Play, which is a wave 8 to 10 burst with the worst frame logged.
