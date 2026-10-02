# Codex wave 8: get the Blender models into the game (2026-10-02)

Base: integrate/wave7 (or main once merged). One combined branch codex/wave8.
testcmd: cd game && stylua --check src tests && selene src && lune run tests/run.luau && rojo build default.project.json -o out.rbxl

## Task 1: Model uploader (tools/upload_models.py, Python 3, stdlib + requests)
- Reads assets/models/manifest.json; for each entry (enemies/*, weapons/*, arena/*) uploads the FBX as a Model asset with the Roblox Open Cloud Assets API (POST https://apis.roblox.com/assets/v1/assets, multipart: request JSON {assetType:"Model", displayName, description, creationContext:{creator:{userId|groupId}}} + fileContent). Poll the returned operation until done; record assetId.
- API key: read from env ROBLOX_API_KEY, else prompt with getpass (never print it, never write it to disk). Creator id from --user-id or --group-id.
- Skip entries whose FBX hash is unchanged since the last run (cache in tools/.upload_cache.json, gitignored). --dry-run lists what would upload.
- Writes game/src/ReplicatedStorage/Shared/ModelAssets.luau: `return { ["enemies/Walker"] = 123, ... }` sorted, stylua-formatted.
- Unit-test the pure parts with python -m unittest (manifest parsing, cache skip, Luau writer) in tools/test_upload_models.py; add that to the testcmd as `&& python3 tools/test_upload_models.py` only if it runs offline.

## Task 2: Runtime model library (ServerStorage/ModelLibrary.luau + Shared/ModelAssets.luau)
- ModelAssets.luau starts as `return {}` (typed { [string]: number }).
- ModelLibrary.preload(): for each id, InsertService:LoadAsset(id) in pcall, take the first Model child, store under ServerStorage.ModelCache[group.."/"..name]. ModelLibrary.get(key): clone or nil.
- On clone: parts ending "_Glow" -> Material Neon; names kept so EnemyBuilder can rig them (Torso/Head/Jaw/Arm_L/R/Leg_n/Wing_n); scale so the model's bounding size matches Enemies.Defs[...].Size (pure helper Fit.scaleFor(boundsSize, targetSize) with tests).
- EnemyBuilder.build: if ModelLibrary.get("enemies/"..typeName) exists, use its MeshParts instead of the part-built body, attach with the same Motor6D names; else current fallback. WeaponModels and ArenaBuilder do the same for weapons/* and arena/*.
- Pure helpers + tests for: key naming, Glow detection, scale fit, rig-part matching (which names map to which Motor6D).

## Task 3: Edit mode looks like the game
- Move Lighting setup into default.project.json: Lighting (Technology Future, Ambient/OutdoorAmbient dark purple, ClockTime 0, Brightness, EnvironmentDiffuseScale) with children Bloom, ColorCorrection, Atmosphere and Sky using the same values the runtime code sets now (grep the current runtime lighting code and delete the duplicate there).
- Emit the arena layout (ArenaLayout data from wave 6) as static parts in Workspace/Arena via a Lune generator tools/gen_arena.luau that writes *.model.json in the explicit CFrame form {"CFrame":{"CFrame":{"position":[..],"orientation":[[..],[..],[..]]}}}; ArenaBuilder must not duplicate them at runtime. Test: generator output is deterministic and every CFrame uses the explicit form.
