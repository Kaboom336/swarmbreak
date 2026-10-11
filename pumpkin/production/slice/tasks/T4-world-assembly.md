# T4 — Imported hub and Pumpkin Meadow scene

Status: DRAFT coder handoff. No commit/publish/spend. Read spec map/asset/shot sections, T1 contract, T2 manifest, current Lobby/WorldPlan/LaunchLook chain before replacing its output.

## Own files

- `pumpkin/giant/scene/SliceScene.luau` (new asset assembly/validation only)
- `pumpkin/giant/assets/slice-world/**` (new final assembled scene package)
- `pumpkin/production/slice/evidence/T4-world/**` (new)

After T2 approved immutable meshes; parallel T3/T5. No edits to T2 catalogue, Patch scripts/config/Rojo. T6 maps the finished package. Claude handles Studio scene and capture work; Codex prepares assembly/contract validation files.

## Build

1. Assemble imported mesh floors/walls/routes/props, invisible collisions/interaction roots allowed. No code-built primitive visible art; scripts clone/place accepted mesh modules. Replace stale scene contents in an isolated local place copy, not live game.
2. Use O=(1500,groundY,150), +Z north: hub248×160 localZ-160..0, Meadow120×160 Z0..160, wall25, path>=12; eight38×28 pens at contract centres, eight plaza lamps, throne40 bypassed by cream routes. South spawn faces north; nestZ20/guardX11; safe lineZ0; gateZ160.
3. Exactly40 initial wild spawn positions, three nested shells and one active guard hook. Centre play field is clear; decoration only alongside paths/walls. Meadow five families all present; one windmill. No rendered full Zone2 or later zones.
4. Preserve Garden/Patches ownership/Soil/Plot indices1..8, Zones/Zone1 Spawns/Hoard attributes, Zone2/GateWall/UnlockPrompt anchor and scene bounds. Market Seeds is operational Shop; Sell/Upgrades shells closed with no prompts. Empty legacy containers only where required by T3 startup compatibility.
5. Finish hub/Meadow exact palettes and sunset; eight showcase pet placements are inert review/unowned staging, removed at pen assignment and never collectible. No implied starting pets/income. Fresh assigned pen is empty before player delivery.
6. Keep gate preview threshold safe and honest with completion sign; no hidden Candy drops or enemy. Locked-client collision and authoritative range need T3/T5 integration, not a globally removed GateWall.
7. Replace old chain execution with one repeatable SliceScene +package, preserve contract hooks when repeated. Old builders/install scripts archived/not executed; never run their script Source replacement.
8. Capture overhead counts, perspective composition, avatar baselines and ground routes using shot cameras. Default-camera sightline from spawn must show landmark and direction without tree/throne occlusion; no night/BloodMoon tint overrides sunset.

## Acceptance

- Automated scene bounds/count contract plus Studio measurements: 248×160 hub,120×160 Meadow,25 walls,>=12 unobstructed paths, eight38×28 pens/eight plaza lamps/40 wilds/three nest/one guard11/throne40.
- Runtime pen assignment and spawn positions fit collision-free imported assets. Every collider/query root is invisible; no procedural art or floating scenery.
- Hub/Meadow topdown/perspective raw and paired shots match concepts, labelled PROPOSED camera positions adjusted only for framing. No false gameplay ownership in fixtures.
- Assembly is idempotent and preserves server startup contract; no second builders recreate art. Provisional board cap hub<6000 instances classified as parts, Meadow<3000; record actual mesh/texture cost, don't claim phone FPS from part counts.
- No source asset or script file owned by another task changed; hand immutable assembled package/hash to T6.
