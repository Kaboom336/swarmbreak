# Why the playtest looked bad (2026-10-02) and the fix

Seen in Zion's video (Studio, edit mode): dark grey blocks, a red pad, a blue spawn marker under a night sky.

## Cause
1. **None of the Blender models are in Roblox yet.** Roblox only shows meshes that are uploaded as assets. `Shared/Meshes.luau` has no ids, so every enemy, weapon and arena piece falls back to the plain part-built placeholders (EnemyBuilder, WeaponModels, ArenaBuilder). The 40 v2 models exist only as FBX/GLB in `assets/models/`.
2. **Edit mode shows only the static floor and walls** (`Workspace/Arena/*.model.json`). ArenaBuilder decorations, lighting effects, enemies and HUD only appear after pressing Play (F5).
3. Lighting is the default night sky; our post-effects (Bloom, ColorCorrection, Atmosphere) are set at runtime too.

## Fix plan (Codex first, Claude reviews)
A. **Upload the models (one Zion step).** Zion creates a Roblox Open Cloud API key at https://create.roblox.com/dashboard/credentials (Assets: read + write). The device thread runs `tools/upload_models.py`, which asks for the key in a prompt Zion pastes into (Claude never types it), uploads each FBX in `assets/models/` as a Model asset via the Open Cloud Assets API, polls the operation, and writes `game/src/ReplicatedStorage/Shared/ModelAssets.luau` (`["enemies/Walker"] = <assetId>`). Fallback if Zion prefers no key: Studio > Import 3D, one FBX at a time (40 files).
B. **Load uploaded models at runtime (Codex).** Server `ModelLibrary.luau`: `InsertService:LoadAsset(id)` once per model at startup, cache under ServerStorage.ModelCache, clone per spawn; set `_Glow` parts to Neon, keep part names so Motor6D rigging in EnemyBuilder/EnemyAnimator still works; fall back to the part-built model when the id is 0 or loading fails. Same for WeaponModels and ArenaBuilder pieces.
C. **Make edit mode look like the game (Codex).** Bake Lighting into `default.project.json` (Lighting properties + Bloom/ColorCorrection/Atmosphere/Sky children) instead of only at runtime, and place the v2 arena kit (floor tiles, walls, pillars, crates, nest root) as static parts from the same layout data, so Studio shows the real arena before Play.
D. **Rebuild the gallery-vs-game check.** After upload, a device-thread playtest screenshot is judged against assets/renders/arena/Lineup.png; gaps go back into the art gauntlet.
