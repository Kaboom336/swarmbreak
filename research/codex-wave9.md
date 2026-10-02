# Codex wave 9 (start from codex/wave8 once it lands; else from integrate/wave7)
Source: research/ART-DIRECTION-v3.md section 4b. X1 and X6 are already wave 8; do not redo them.
Every task: write the failing spec first, keep to the listed files, no new dependencies, pass prices stay 0.
testcmd: cd game && stylua --check src tests && selene src && lune run tests/run.luau && rojo build default.project.json -o out.rbxl

## T1 Lighting presets (ART-DIRECTION-v3 X2)
Shared/LightingPresets.luau: pure data presets Station, BossFight, Base, LowQuality (Lighting props, Atmosphere, Bloom, ColorCorrection, Sky tint). Apply in ArenaBuilder and BossIntro. Station must equal the Lighting baked into default.project.json by wave 8.
Spec tests/lightingpresets.spec.luau: all keys present in every preset; Atmosphere.Color near Sky tint hue; Bloom.Threshold >= 0.8; Theme floor luminance > every Theme enemy body luminance; project.json Lighting == Station.

## T2 VFX library (X3)
Shared/VfxDefs.luau (HitSpark, MuzzleFlash, DeathBurst, SpawnBuildIn, Telegraph, PickupMagnet, BossWeakPoint) + StarterPlayerScripts/ClientFX.luau (pooled emitters, Emit(n), no per-hit Instance.new).
Spec tests/vfxdefs.spec.luau: every Transparency sequence starts and ends at 1; Rate <= 100; worst-case emits/sec under a budget constant; Telegraph colours warm and never a player hue.

## T3 Hit and kill feedback (X4)
HitMarkers.client.luau, Effects.client.luau, Shared/Feel.luau: hit = spark + 0.06 s white flash + sound + damage number; crit variant bigger; kill = DeathBurst + coin flying to the counter.
Extend tests/feel.spec.luau: timings in range, crit scale > normal, every enemy type has a DeathBurst colour.

## T4 UI kit (X5)
Shared/UiTheme.luau (font, stroke, corner, gradients, rarity colours, sizes) + StarterPlayerScripts/UiKit.luau (Panel, Button with 1.05/0.95 press tween, Counter count-up, Banner, Portrait). Migrate Hud.client.luau screens to it.
Spec tests/uitheme.spec.luau: text/stroke contrast >= 4.5:1; rarity colours == Theme.Rarity; touch targets >= 44 px at 1334x750; no tweened Thickness on text strokes.

## T5 Capture script (X7)
game/tools/capture.luau for the Studio command bar: 6 fixed cameras (see ART-DIRECTION-v3 section 5), apply Station preset, wait, screenshot. No unit test; must pass selene/stylua.
