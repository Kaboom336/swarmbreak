# Handoff: Steal a Pumpkin (2026-10-12 ~19:50 UTC)

## Where we are
- Zion (10/12 18:10): stop 2D, start 3D models one at a time, slowly, so he learns the process. Concepts final set = concepts/v6 (judge panel: ours 7-8 Codex / 6-7 Claude; real hit frames 6-8). Plan page: https://claude.ai/artifact/4UhV6VWs5ohfDiJdLkD5mA (diagrams, map options, screens).
- Map: options A radial / B compact plaza (recommended, 19-45 s runs) / C islands in blueprint/map-options/MAP-REVIEW.md. Zion has NOT picked yet ("not 100% confident" on radial).
- Model lab: separate Studio place C:\dev\codex-lab\model-lab\model-lab.rbxl (copy, game untouched; studio_id changes on reopen, use list_roblox_studios). Daytime preset from concepts/v5/BUILDABILITY.md. Folders: ModelLab (pups), SizeLadder, PumpkinLab, CrowLab. Black 2x5.5 block = player scale. Zion must Ctrl+S to keep models (or re-insert by publishedAssetId).
- Method per model: Creator Store check (nothing usable for custom pets) -> Studio generate_mesh 2 versions (explicit parts, 1.5-2.5k tris) -> capture next to concept + a real hit frame -> Zion picks -> refine.
- Decisions: Pumpkin Pup = A (PupGen2, chibi studded, assetId 98518831184004; colour a bit red, recolour attempt worse). Pet size by place: pen pets bigger Common 4 / Rare 4.8 / Epic 5.8 / Legendary 7 / Mythic 9 studs; follower pets current smaller ladder (3.2-7). Several pumpkin models per zone, each zone its own themed set.
- Pending Zion: Crow C (assetId 116910402228285) yes/retry; pumpkins "A fixed" (E, 99871023459752) + "D fixed" (D2, 127689219325625) + Graveyard ghost sample ok?
- Zone 1 pets (PatchConfig): Pumpkin Pup (Orange), Crow (Sunny).
- Insight: real hits (PS99) pets = simple smooth shapes, huge eyes, glow/sparkle/name tags. Next: add glow, sparkle, name tag effects in Studio; then nest pumpkin (glowing) and scythe.
- Rules: ask one clearly labelled question at a time ("Crow C: yes/retry"); show a real hit model next to ours; close helpers/tabs when done.

## Usage
- Claude weekly 86% at 19:50Z (reset 10/14 21:00Z). Pause Claude-heavy judging at 90% and tell Zion.

## Code
- Branch pumpkin/patch-panic; commit with -c user.name/email from last commit; only git add pumpkin/giant pumpkin/production pumpkin/tools.
- Slice spec/tasks (production/slice) are stale vs v6 + map choice: refresh after Zion picks the map.
