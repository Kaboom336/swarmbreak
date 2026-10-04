# Codex C1: Mars Core campaign data (2026-10-04). Follow game-bible-v3.md ("Cores" and "Base and lobby")
Base: integrate/wave13 at e639f92. Branch: codex/w24-c1.

Rules:
- Runtime-safe APIs only.
- Failing spec first.
- Plain names. No blood.

testcmd: cd game && stylua --check src tests && selene src && lune run tests/run.luau && lune run ../tools/lint_runtime_apis.luau && rojo build default.project.json -o out.rbxl

1. **Rename** Outpost 9 to the **Mars Core** in Campaign. Keep the Id `Outpost9` so existing saves stay valid. Change only Name and StoryLine.
   - StoryLine: "A withered Martian factory outpost, overrun by a Nest feeding on its reactor."
2. **Stages:** a pure `Shared/CoreStages.luau`. Each core has 15 stages, and each stage has:
   - Id, Name, Zone (LandingPad for 1-5, Refinery for 6-10, HiveCore for 11-15)
   - Waves (stage 1 = 3 waves, rising to 8 by stage 15)
   - Family = Nest
   - Boss (Brute on stages 5 and 10, Queen on 15, otherwise none)
   - HealthScale and DamageScale (a smooth curve from 1.0 at stage 1 to about 3.0 at stage 15)
   - a one-line StoryBeat
3. **Difficulties:**
   - Normal, Hard and Nightmare, reusing Shared/Difficulty multipliers.
   - Unlock rules: stage n+1 on a difficulty unlocks after stage n is cleared on that difficulty. Hard stage 1 unlocks after Normal stage 15; Nightmare stage 1 after Hard stage 15.
   - Profile flag: `StageClear_<core>_<difficulty>_<n>`. ProfileSchema.sanitize keeps it, and the old MapClear flags migrate (a MapClear on a difficulty counts as all 15 stages cleared on it).
4. **Rewards:**
   - Clearing Nightmare stage 15 grants the Mars base theme: profile `BaseThemes.Mars = true`. It's data only, used later by B1.
   - First clears give Gold and Gems bonuses that scale with stage and difficulty; repeats give 25%.
5. **Run start:** WaveManager runs the chosen stage's wave count, boss and scales instead of the fixed 15-wave run. The lobby board picks a stage and difficulty (a simple list; UI polish later).
6. **Specs:**
   - 15 stages per core, monotonic scales, and bosses on 5, 10 and 15.
   - The unlock chain across difficulties.
   - The flag migration.
   - First-clear vs repeat rewards.
   - The base theme is granted only on Nightmare 15.
   - RunSim: stage 15 on Normal clears in 5-8 minutes.
