# Codex L1: look and feel pass (2026-10-04). Follow game-bible-v2.md
Base: integrate/wave13 at 72f2ecf or later, merged with S3 if S3 has landed. One branch.

Rules:
- Runtime-safe APIs only.
- Failing spec first.
- WaitForChild for sibling client modules.
- No blood. Prices 0.

testcmd: cd game && stylua --check src tests && selene src && lune run tests/run.luau && lune run ../tools/lint_runtime_apis.luau && rojo build default.project.json -o out.rbxl

Zion's playtest (10/04): "bland with no details, the glow is unbearable I can't see, not satisfying, effects are very shaky and not smooth".

1. **Neon purge.**
   - There are 45 `Enum.Material.Neon` uses in 13 files. Keep Neon only on parts with no dimension above 1.5 studs (eyes, thin light strips).
   - Everything else becomes SmoothPlastic with the same colour. Where a light source is meant, add a small PointLight (Range ≤ 12, Brightness ≤ 1.5).
   - Spec: walk ArenaModelGenerator, EnemyBuilder templates and LobbyBuilder data; no Neon part over 1.5 studs.
2. **Lighting per map.**
   - Atmosphere density about 0.3. ColorCorrection contrast 0.15, saturation 0.15.
   - A distinct sky and grade per Maps entry. Bloom stays at the values in 72f2ecf.
3. **Smooth effects.**
   - Every client effect that moves parts each frame runs from one pooled RenderStepped driver in ClientFX, not one Heartbeat loop per effect. This covers XP gem pops, the death ghost, rings and bursts.
   - Quad-out or exponential-out easing, never linear.
   - Pool parts and particles: no Instance.new per hit after warm-up.
   - Spec: an AnimCurves-style pure easing table, plus a pool that returns the same instances.
4. **Kill feel layer** (bible "Kill feel"):
   - Client hitstop: 50 ms on a kill and 80 ms on an elite kill. Freeze that enemy's animator and the local weapon pose only, never server time.
   - 2-4 stud knockback on the client ghost.
   - Damage numbers from a pool.
   - A magnet pull on gems toward the nearest player within 18 studs, with ease-in acceleration.
   - 3-layer kill sound: crunch, goo squelch, pitch-randomised ±8% tick. Use existing SfxMap ids; add keys with id 0 where none fit.
5. **Particle textures, not parts.**
   - Bursts, sparks, goo and rings become ParticleEmitters using texture ids from a new Shared/VfxTextures table (spark, smoke, slash, ring, goo, softglow), all 0 for now.
   - Keep the current look as the fallback when an id is 0. I'm generating the sprites separately and the laptop uploader will fill in the ids.
6. **Prop scatter** (anti-bland):
   - A seeded pure Shared/PropScatter that places a non-colliding prop about every 8 studs on walkable floor, outside spawn and gate lanes.
   - Prop kinds: crates, pipes, antenna, rocks, goo puddles, cables, built from existing ArenaModelGenerator parts in S0 colours.
   - Spec: deterministic for a seed, keeps lanes clear, density within a band.
7. **Captures:**
   - In the result, list the shot-list stills the Play thread should retake: shots 01, 03, 05, 06 and 09, plus clip B, the kill burst.
8. **Camera inside enemies** (capture 17-camera-inside-boss):
   - The camera sits at a fixed 12 studs, so enemies walk through it.
   - Each frame, any enemy part within 4 studs of the camera fades its LocalTransparencyModifier to 0.7.
   - Enemy parts set CanCollide=false only for the camera popper. Don't change CanQuery.
   - The boss gets a 1.5x stronger fade.
