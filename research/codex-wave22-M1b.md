# Codex M1b: movement review fixes (2026-10-04)
Base: codex/w22-m1 at 28b7425. Push to the same branch: codex/w22-m1.

Rules:
- Runtime-safe APIs only.
- Failing spec first for each fix.

testcmd: cd game && stylua --check src tests && selene src && lune run tests/run.luau && lune run ../tools/lint_runtime_apis.luau && rojo build default.project.json -o out.rbxl

1. **Always-sprint lost after a reward** (Movement.client around lines 49-50):
   - PlayerData.applyStats writes the plain WalkSpeed after every reward pick.
   - Make the server own the final speed: applyStats sets WalkSpeed = stat speed × MovementTuning.sprintMultiplier. Alternatively, the client re-applies the multiplier on every WalkSpeed change, guarded against loops.
   - Spec: after a stat apply, the effective speed still includes the sprint multiplier.
2. **FOV overwrite** (Movement.client line 267):
   - Don't set FOV every RenderStepped.
   - Add the dash and slide kick as an offset into a shared FOV stack in ClientFX, so fovKick (the boss-death kick) and the movement kick add together and both ease back to base.
   - Spec: two kicks add, and each one decays to base.
3. **Sound pool leak** (Sounds.luau lines 30-32):
   - When an asset id is 0, return early before taking a pooled Sound or a SoundBudget slot.
   - Spec: playing an id-0 key leaves the pool and budget counts unchanged.
4. **Double-jump spin** (PlayerPose.luau line 94):
   - Use a monotonic eased angle so it does a full 360: `angle = easeOutQuad(progress) * 2π`, not `sin(progress·π)`.
   - Spec: the angle at progress 1 is 2π, and it's monotonic.
