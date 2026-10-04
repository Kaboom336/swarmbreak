# Codex FX1: anime combat VFX, a stage-finale wave, and a card-pick timeout (2026-10-04)

Base: integrate/wave13 at 6277319 or later. If K1 or U1 have merged, rebase onto them. Follow game-bible-v3.md, "Art style" and "On-screen effects": bright, high-saturation, sharp anime action. No blood. Goo is teal or green.

Evidence: captures/art-final/04-side-by-side-fight.png on art/landing-pad (1adc722).
- The environment is now close to Hunty Zombie.
- The fight frame is not. Our kill burst is a flat white blob, while Hunty fills the frame with saturated purple and orange VFX and motion streaks.

testcmd: cd game && stylua --check src tests && selene src && lune run tests/run.luau && lune run ../tools/lint_runtime_apis.luau && rojo build default.project.json -o out.rbxl

## 1. World combat VFX (VfxDefs.luau, CombatEffects.luau)
Use ParticleEmitter, Beam and Trail with Roblox built-in textures only (rbxasset:// or 0). Insert no store assets and nothing that carries scripts. Everything is pooled.

1. **DeathBurst:** replace the white blob with an anime pop:
   - A saturated ring shockwave (a Beam or a flat cylinder scaling 0.5 to 6 studs in 0.18 s), in teal or the family accent colour.
   - 8 to 12 sharp star or shard sparks with LightEmission 1 and a short life of 0.25 s or less.
   - A goo splash in teal or green.
   - The colour comes from the enemy's family palette in Theme, never white-dominant.
2. **Hit spark:** on every hit, a small X-shaped flash plus 3 to 4 streak particles along the hit normal (0.1 s).
3. **Tracers:** thicker and brighter with a coloured core. Add a muzzle flash star of 0.06 s or less.
4. **Ability and ultimate trails:** every melee swing or dash leaves a Trail in the weapon colour (0.15 s). Ultimates add a screen-filling radial burst of 0.3 s or less.
5. **Budget:**
   - At most 60 live VFX parts per client. Emitters are reused from a pool.
   - On a mobile quality flag (Settings low or a touch device), particle counts are halved.
   - Wave 3 averaged 53 fps with a 68 ms worst frame, so this must not make it worse.

## 2. Stage finale wave (CoreStages.luau, WaveTable, RunSim)
Stage 1's last wave (wave 3) clears in about 2 s and the run ends at once, so nobody sees a fight.
- The final wave of every stage that has no boss becomes a finale: at least 1.6x the enemy count of the previous wave, and it includes a Tank.
- In RunSim, the final wave of every stage takes at least 20 s to clear, and the finale's clear time is longer than the stage's wave 1.

## 3. Reward-card pick timeout
With the card panel hidden on the client, wave 2 stalled for over 3 minutes with 13 enemies alive.
- Find what blocks while a card choice is pending (wave advance or auto-fire) and fix it.
- Combat and waves never pause on a pending pick.
- An unanswered pick auto-chooses the first card after 8 s, server-side.
- Specs:
  - A pending pick never blocks wave advance.
  - The auto-pick fires at 8 s.

## 4. Specs
- The DeathBurst colour is not white-dominant: max channel minus min channel is at least 0.35.
- The burst lasts 0.4 s or less.
- The VFX pool is reused: no new instances after warm-up in a 100-kill sim.
- Live VFX stays at 60 or fewer.
- The stage finale rules from section 2 hold.
