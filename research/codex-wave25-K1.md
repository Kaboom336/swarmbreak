# Codex K1: combat camera and the scythe kit, mobile-first (2026-10-04). Follow game-bible-v3.md, "Cinematic combat"
Base: integrate/wave13 head after C1 (or e639f92 if C1 hasn't landed). Branch: codex/w25-k1.

Rules:
- Runtime-safe APIs only.
- Failing spec first.
- WaitForChild for sibling client modules.
- No shaky camera. No blood.

testcmd: cd game && stylua --check src tests && selene src && lune run tests/run.luau && lune run ../tools/lint_runtime_apis.luau && rojo build default.project.json -o out.rbxl

1. **CombatCamera** (client, pure math in Shared/CombatCameraMath):
   - The target distance, height and FOV blend from nearby enemy count (wider in crowds), with an elite/boss close-low framing.
   - Spring-damped and eased, with a maximum change rate per second. It never moves while a dash or aim input is fresh (0.2 s).
   - On by default; there's a settings toggle.
2. **Scythe weapon:** idle, a 3-hit combo, a heavy attack, and Dash Spin (dash plus a 360 spin hitbox, reusing M1 dash). Procedural poses through PlayerPose and AnimCurves; no uploads.
3. **Ultimate "Reaper Arc":**
   - About 1.5 s, local only.
   - Camera orbit around the player, a time-slow feel (client animation speed only; server time keeps running), a slash ring with pooled VFX, then an ease back to the play camera.
   - Skippable. The setting can be Full, Short (0.6 s) or Off.
4. **Abilities:** an ability pool data module. Each weapon lists 6 or more abilities; a loadout takes 2 plus the ultimate. For now the scythe has 3 real abilities, and the others are stubs.
5. **Mobile:**
   - Touch buttons for attack, dash, jump, slide, ability 1, ability 2 and the ultimate.
   - Thumb-zone layout, safe-area aware, minimum 56 px.
   - Auto-aim stays on.
   - Gamepad mappings too.
6. **Specs:**
   - Camera math: monotonic in crowd size, rate-limited, and frozen during fresh input.
   - The ultimate timeline length is ≤ 1.5 s, Short is ≤ 0.6 s, and the server time scale is untouched.
   - Ability pool: loadout validity.
   - Touch layout: buttons don't overlap at 667x375 and 1280x720.
