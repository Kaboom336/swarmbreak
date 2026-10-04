# Codex M1: movement feel (2026-10-04). Follow game-bible-v3.md
Base: integrate/wave13 head. Branch: codex/w22-m1.

Rules:
- Runtime-safe APIs only.
- Failing spec first.
- WaitForChild for sibling client modules.
- No shaky camera.

testcmd: cd game && stylua --check src tests && selene src && lune run tests/run.luau && lune run ../tools/lint_runtime_apis.luau && rojo build default.project.json -o out.rbxl

1. **Always sprint.** Remove the sprint toggle; the run speed comes from MovementTuning. Mobile behaves the same.
2. **Dash:**
   - Q on keyboard, a button on mobile, and ButtonB on gamepad. It's a ground or air burst toward the move direction.
   - Cooldown from MovementTuning; it keeps the existing dash charges if those exist.
3. **Double jump:** a second jump in the air. Leave hooks for extra jumps from gear: `MovementTuning.extraJumps(perks)`.
4. **Slide:**
   - C or Ctrl while sprinting on the ground. A low hitbox for about 0.6 s and a speed boost that decays.
   - It can be cancelled into a jump (a slide-jump carries momentum).
5. **Three variants each:**
   - A pure `MoveVariants.pick(action, lastIndex, roll)` that never repeats the same variant twice in a row.
   - Variants are procedural poses through PlayerPose and AnimCurves: a body lean, a tuck or spin, and an arm sweep. No animation uploads.
6. **Feel:**
   - A small FOV kick (≤ 6°) on dash and slide, eased out quad.
   - Soft whoosh SFX keys (id 0 if none exists).
   - Dust puff particles from the pooled ClientFX.
7. **Specs:**
   - Variant picker: no repeats, and every variant is reachable.
   - Slide-jump momentum math.
   - Extra-jump counting.
   - Cooldown table bounds.
