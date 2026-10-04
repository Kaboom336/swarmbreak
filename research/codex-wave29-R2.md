# Codex R2: last fix round. Boss stuck, 2x hit/kill impact, wave pacing (2026-10-04)

Base: integrate/wave13 at 5dd4367. Zion picked "one more round" after the final judge. This round is judged against captures/art-final2/ on art/landing-pad 6ad1e74 (notes.md there).

Rules:
- Follow game-bible-v3.md: bright, sharp anime action. No blood; goo is teal or green. Mobile-first.
- Built-in rbxasset:// textures only. Insert nothing from the store.
- FOV changes go through ClientFX/FovStack only.

testcmd: cd game && stylua --check src tests && selene src && lune run tests/run.luau && lune run ../tools/lint_runtime_apis.luau && rojo build default.project.json -o out.rbxl

## 1. Boss stuck above the north gate (intermittent, stage 5 wave 4)
Evidence:
- Big Brute's bounding box was 100x56x94, centred about 72 studs up near (-6, -70), above the north art gate.
- HP stayed frozen at 313/1016 for more than 20 s. The player could not reach it, and the camera washed cyan near it.
- A second stage 5 run cleared normally.
- The boss spawn had a 272 ms frame spike.

Root-cause it. Don't patch the symptom. Likely places to look:
- EnemyRigBuilder buildFresh for bosses: the scale when there is no rigHeight entry. A 100-stud box means the template was scaled by the wrong size.
- ArenaLayout.bossSpawnForWave versus the stage's zone. Campaign stages use layoutWave, not the raw wave.
- EnemyAI or EnemyWatchdog respawn, which teleports to the "nearest open gate". The north art gate may sit on top of art geometry.
- An outline or Highlight, or goo VFX, parented to the boss and causing the cyan wash.

Fix:
- The boss always spawns on floor (ArenaLayout.onFloor) in the active stage zone.
- Bosses have a rig height band of 12 to 18 studs.
- A watchdog: if the boss is off-floor or more than 15 studs above the floor for over 2 s, or takes no damage for 10 s while players are in range, re-place it on the boss spawn.

Specs:
- For every stage with a boss, on every difficulty, the boss spawn is on floor in that stage's zone.
- The boss rig height is within the band.
- The watchdog rule is a pure function, with tests.

## 2. Hit and kill impact at least 2x (CombatEffects, ClientFX, VfxDefs, Feel)
Hunty's hits fill a large part of the screen with saturated purple and orange. Ours are thin streaks.
- **DeathBurst:** shockwave ring radius at least 2x the current one (scale to enemy size; at least 8 studs for normal enemies, 16 for Tanks). A filled flash disc (Neon, 0.08 s). 16 to 24 sparks. Plus a short anime "impact frame": a white-to-accent full-screen flash of 0.05 s or less on elite and boss kills only.
- **Scythe swing:** a wide crescent slash mesh or Beam arc that covers the hit arc (about 10 studs), in purple and gold, 0.12 s. A hit-stop of 0.04 s per hit, already in Feel; make sure it fires for the scythe.
- **Hit sparks:** 2x the size. Add 6 to 8 radial speed streaks.
- **Damage numbers:** 1.5x the size on scythe hits.
- **Budget stays:**
  - At most 60 live VFX parts.
  - Low quality halves the counts.
  - Each wave averages 55 fps or more in RunSim proxies.
  - Never cover the screen centre for more than 0.3 s.

## 3. Wave pacing
With the scythe, waves clear in 1 to 2 s. Only the finale lasts.
- Target: every wave lasts at least 12 s in RunSim with the Reaper starter loadout, and the finale at least 20 s.
- Do this by spawning in timed pulses (2 to 4 pulses per wave from different gates) instead of one dump. Raise enemy counts only if pulses aren't enough.
- Keep the total clear time per stage at 6 minutes or less on Normal.
- Add a Reaper starter profile to RunSim. Specs cover both pacing targets.

## Done when
The gate is green, and the specs above cover the boss placement, the watchdog, the VFX sizes and budget, and the pacing.
