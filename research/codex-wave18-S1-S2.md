# Codex S1 + S2 (2026-10-03). Cite S0-art-bible.md for every colour, font and timing
Base: integrate/wave13 at 7d6e0ca or later. One branch per task: S1 first, then S2.
Rules:
- Runtime-safe APIs only.
- Failing spec first.
- WaitForChild for sibling client modules.
- No blood: goo is teal. Prices 0. Plain names.
testcmd: cd game && stylua --check src tests && selene src && lune run tests/run.luau && lune run ../tools/lint_runtime_apis.luau && rojo build default.project.json -o out.rbxl

## S1 UI redesign (Zion: "UI looks old, outdated, not sized right")
- Move Theme to the S0 palette now: arena floor OutpostCream, props OutpostShade and SignalOrange, enemy bodies Chitin and ChitinDark with Goo eyes, and the sky dusk preset. Keep V1's contrast spec, but flip it so enemies are darker than the floor.
- New Shared/UiTheme tokens from S0. Update the UiKit builders (Panel, Button, Badge, Bar, Banner) to the S0 kit.
- One UIScale on every ScreenGui, from the S0 formula, updated on ViewportSize change. Lay out at the 1920x1080 reference.
- Restyle everything on the kit: the HUD (V3 rows, XP bar, LV/WAVE, HP bar, ability buttons), level-up cards (V2 chrome), run summary, toasts, banners, settings and the lobby boards.
- Level-up cards must not blind combat (footage at 0:30 and 2:38). They open in the lower 55% of the screen, with the arena still visible above them. The world behind them dims by 25%, and the player takes 50% less damage while cards are open, for up to 6 s.
- Footage, shot 06: the damage numbers are tiny. They become FredokaOne:
  - 28 px normal, 40 px crit, with a stroke.
  - They pop up to 1.3x, then float and fade.
- Spec: HudLayout rects don't overlap or clip at 1280x720, 1920x1080 and a 844x390 phone (safe area); all fonts come from UiTheme.

## S2 Animation pass (Zion: "there aren't really animations yet")
Procedural Motor6D curves now, in Shared/AnimCurves (pure), with keyframes from S0's timing. Each clip also accepts an optional AnimationId in Shared/AnimIds (all 0 for now) so a store pack can replace it later.

**Player:**
- A fire loop with recoil from WeaponPose, kept small.
- A 3-hit melee combo: slash, slash, overhead.
- Dash roll, hit flinch, and a level-up flourish (arms up, 0.4 s).

**Enemies, all R15 and part-rig types:**
- Walk cycle per type, with idle breathing.
- Attack wind-up (pull back plus a Telegraph ground decal), strike lunge, recovery.
- Hit flinch plus a white flash, and death squash plus a goo pop.

**Kill burst:** 12-20 Goo particles, a goo splat decal that fades in 3 s, and a bright XP gem pop with a spin and bounce.

**Evolution cinematic** (J2 pick and shop evolve):
1. 0.6 s slow-mo for the local player. Time scale goes through the client FX only; never pause the server.
2. Camera push-in.
3. Element-coloured ring burst.
4. The weapon model swaps to the evolved look with a flash.
5. Banner: EVOLVED: name.

Specs:
- Every curve starts and ends at neutral.
- Wind-up, strike and recovery durations match S0.
- The combo index cycles 1→2→3→1 and resets after 0.8 s idle.

Placeholder fix in the same branch (footage, shot 12):
- Colour the R15 body parts with the type's Chitin or ChitinDark body colour instead of white.
- Weld the Brute's boss dressing to its torso. It floats detached now.
