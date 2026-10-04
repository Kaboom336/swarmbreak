# Codex U1: anime on-screen effects and the boss health bar (2026-10-04). Follow game-bible-v3.md, "Art style"
Base: integrate/wave13 head (after L2 if it has landed). Branch: codex/w27-u1.

Rules:
- Runtime-safe APIs only.
- Failing spec first.
- No blood.
- No camera shake (UI-only shake is allowed).

testcmd: cd game && stylua --check src tests && selene src && lune run tests/run.luau && lune run ../tools/lint_runtime_apis.luau && rojo build default.project.json -o out.rbxl

1. **Boss health bar** (replaces the current boss bar):
   - A wide top bar with a thick outline, a portrait icon slot (an ImageLabel id table, 0 for now; it falls back to the name initial), a name plate in LuckiestGuy, and phase notches from BossFight thresholds.
   - Fill and trail: the white damage trail drains 0.4 s after the fill, eased out quad.
   - UI shake on hits of 5% or more of max HP (±4 px, 0.15 s). A flash and notch pop when the phase changes.
   - The bar slides in when the intro ends and out on the kill.
   - The bar is coloured from the boss's palette in Theme.
   - Mobile: it fits at 667x375 without covering the top HUD.
2. **On-screen effects:**
   - Damage numbers: thick outline, pop-scale 1.3 to 1 in 0.12 s, crits in gold and bigger.
   - Hit marker: an anime X tick for 0.1 s.
   - Speed lines at the screen edges on dash, slide and ultimates (pooled ImageLabels, texture id 0 falls back to thin frames).
   - Low-HP vignette pulse: a bright magenta or teal edge, never red.
   - Banners: bold, outlined, and a slam-in animation.
   - Nothing covers the screen centre for more than 0.3 s.
3. **Specs:**
   - Trail math: the trail never lags the fill by more than 0.4 s and ends equal to it.
   - Phase notch positions match BossFight.
   - UI shake amplitude is ≤ 4 px.
   - The vignette colour is not red-dominant.
   - The damage number pool is reused.
