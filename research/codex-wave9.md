# Codex wave 9 (start from codex/wave8 once it lands; else from integrate/wave7)
Source: research/ART-DIRECTION-v3.md section 4b. X1 and X6 are already wave 8; do not redo them.
Every task: write the failing spec first, keep to the listed files, no new dependencies, pass prices stay 0.
testcmd: cd game && stylua --check src tests && selene src && lune run tests/run.luau && rojo build default.project.json -o out.rbxl

## T1 Lighting presets (ART-DIRECTION-v3 X2)
Station is BRIGHT dusk daylight (see ART-DIRECTION-v3 section 0): ClockTime about 17, Brightness 2 to 3, warm sun, blue sky, ExposureCompensation about 0, Bloom Intensity about 1.2, Threshold about 0.85, Size 24, ColorCorrection Contrast 0.15, Atmosphere Density about 0.3, Offset 0.25, colour matched to the horizon. Values come from /mnt swarmbreak-studio-research.md and are tuned by eye. Only BossFight may tint red. Add preset NestInterior (Pressure-style, for boss lairs and indoor rooms): dark ambient but every room has visible coloured light sources (PointLights on Neon fixtures, no black corners where enemies hide).
Shared/LightingPresets.luau: pure data presets Station, BossFight, NestInterior, Base, LowQuality (Lighting props, Atmosphere, Bloom, ColorCorrection, Sky tint). Apply in ArenaBuilder and BossIntro. Station must equal the Lighting baked into default.project.json by wave 8.
Spec tests/lightingpresets.spec.luau: Station Brightness >= 2 and ClockTime between 15 and 18; all keys present in every preset; Atmosphere.Color near Sky tint hue; Bloom.Threshold >= 0.8; Theme floor luminance > every Theme enemy body luminance; project.json Lighting == Station.

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

## T6 Final Swarm HUD set (priority 2, do right after T1)
Hud.client.luau + UiKit (from T4, or plain frames if T4 is not merged yet): boss name with a big red HP bar at the top centre; wave number plus round timer at the top centre; Coins/Gems at the top right; the Quests panel on the left (Quests.luau exists); damage numbers with a crit colour; a red hit-direction indicator when the player is hit; red AoE warning circles on the ground before boss and spitter attacks; a "Wave clear +N Coins" banner. The existing pick-1-of-3 reward screen gets rarity-tagged cards.
Spec tests/hudlayout.spec.luau (pure layout data in Shared/HudLayout.luau): each element anchored where listed, nothing overlapping at 1334x750 and 1920x1080, touch targets >= 44 px.

## T7 Rivals-style movement (Zion 10/2)
StarterPlayerScripts/Movement.client.luau + Shared/MovementTuning.luau (pure data): sprint (default on for mobile), slide (crouch while sprinting; momentum decays over about 0.8 s), short dash on a cooldown, jump buffering and coyote time, small FOV kick on sprint and dash, camera tilt on slide. Shooting while moving keeps full speed. Mobile gets a slide/dash button via the touch layout.
Spec tests/movement.spec.luau: pure functions for slide speed curve (monotonic decay, ends at walk speed), dash cooldown, coyote and buffer windows in range, FOV kick returns to base.

## T8 Final Swarm card cadence and chest payoff (laptop player's-eye pass, 10/2)
Evidence: /mnt/project-files/swarmbreak-reference-notes-20261002T012511-1d9d.md. Final Swarm shows a level-up pick every 10-20 s.
In-run XP from kills; each level-up offers 3 rarity-coloured cards with a short flip reveal (reuse the existing pick-1-of-3 reward logic and perks). Early levels are cheap so the first pick lands about 15 s into wave 1. End of run: a short chest-reveal moment (existing Gem crate and pity) before the run summary. At spawn, the tutorial shows a one-line goal banner ("Survive 5 waves").
Spec tests/levelup.spec.luau: pure XP curve where level 1 and 2 need under 20 s of kills at the wave 1 kill rate (constant in data); picks never offer duplicate cards; rarity odds sum to 1; the chest result uses Crate pity.

Order: T1, T6, T8, T7, T3, T2, T4, T5.
