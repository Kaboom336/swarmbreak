# T1 greybox handoff — 2026-10-12

Built locally. Static/build checks PASS; Studio runtime and T1 acceptance UNKNOWN.
Owner explicitly authorized T1 despite the old task restriction. Defaults: keep Steal a Pumpkin, solo slots, holiday pets return yearly. Seasonal art/pets are outside this prototype.

## Play in four steps

1. Open `guardian-greybox.rbxl` in Roblox Studio and press Play. Walk to the central blue portal and use Enter (E, controller X, or the touch prompt).
2. Follow the level route, move around the grey cover blocks, and hold Steal for one second beside the glowing ball. The guardian warns/approaches before theft and chases after a 1.2-second head start.
3. Carry the ball back along the same route and use Return at the blue portal. Catch applies one second of slow followed by three seconds of mercy; the carried item stays yours.
4. Walk to the yellow-marked pen bearing your name and use Place. A plain ball occupies one of eight positions. Repeat until full; no hatch, income, shop purchase or save system exists in T1.

## Exact files

- `greybox.project.json`: isolated Rojo 7 DataModel with runnable server/client mappings and hidden developer attributes.
- `GreyboxConfig.luau`: dimensions/tuning and owner defaults.
- `Layout.luau`: seeded authored recipes, Fisher–Yates travel shuffle, connector/bounds validation, signatures and self-test.
- `Greybox.server.luau`: runtime world/pieces, eight pens/solo slots, guardian navigation, validated hold/pickup/return/place, transient recovery and server self-test.
- `Greybox.client.luau`: minimal goal/carry HUD and own-pen highlight/prompts; no seed HUD.
- `guardian-greybox.rbxl`: built place; geometry is created on Play by the included server script.
- `check.luau`: Lune compile/layout/binary source-mapping checks.
- `selene.toml`, `roblox_min.yml`: offline lint setup reused from the existing project's minimal standard.
- `sourcemap.json`: Rojo mapping evidence.
- `T1-greybox.md`: this handoff/evidence.

All files are under `pumpkin/production/slice-v2/prototype/`. No edits to `pumpkin/giant/src`; no commit, publish, downloads, accounts or asset imports. Existing unrelated dirty work was preserved. Existing Patch server/mapping and compile-check code were inspected first. No third-party gameplay framework or art was adopted; no new redistribution licence obligation was introduced.

Source baseline HEAD: `88b000feae0b9c846d97beec85d34cbc3475093f`. Final scoped Git status: `?? pumpkin/production/slice-v2/prototype/`; `git diff --name-only -- pumpkin/giant/src` returned no files. The repository already contained unrelated modified/untracked work at task start.

## Developer controls (server only)

During Play, select ServerScriptService in the **server** Explorer view:

- Set `GreyboxSeed` to 101, 202 or 303 before entering. Setting it to 0 restores session/slot/run-counter seeds and the fixed easy first run. Changing it never modifies an occupied run. Return/place, then enter again for replay.
- Set `GreyboxSelfTest` to true. It builds temporary real floor/cover/connector models for 101, 202, 303 and replay 101; validates floor heights, actual attachment snaps/opposing normals and piece bounds; destroys the temporary models. It also runs scalar recipe/replay/50-seed tests. Look for `[GreyboxSelfTest]` logs and `GreyboxSelfTestResult`. This attribute resets to false after the trigger. **This runtime test is included but was not run in Studio here.**
- Server logs assembled slot/seed/signature, first theft elapsed from fresh character spawn, portal-to-portal elapsed and catch count, item placement and disconnect cleanup. No timed route was observed here.

## Checked evidence

- Lune 0.10.5 compiled all five Luau files at O0/O1/O2 with debug level 2: PASS. This is compilation, not Luau type analysis.
- Lune executed the shared layout tests: PASS. Seed 101 = five pieces/108 studs; 202 = three pieces/84 studs; 303 = four pieces/108 studs. Each replay matched its complete scalar connector/transform signature. Fifty fixed seeds passed; malformed snap and route 113 were rejected; the fixed first recipe is four pieces/108 studs.
- Runtime assembly calls the same layout validator before transfer, plus actual floor/attachment checks. Known-safe default is used after a logged invalid candidate. Current enabled straight recipes validate on their first candidate; no unconstrained terrain generation/retry loop.
- StyLua 2.0.2 formatting and `--check .`: PASS.
- Selene 0.31.0 on the whole prototype folder: 0 errors, 0 warnings, 0 parse errors. The offline `roblox_min` standard checks names/syntax, not full Roblox API typing.
- Rojo 7.4.4 `build greybox.project.json -o guardian-greybox.rbxl`: PASS.
- Lune deserialized the built binary and confirmed matching server/client/config/layout source plus the hidden seed attribute: PASS. No online assets or external module IDs are referenced.
- Place SHA256: `E613A97160A69ED7E21ACC3F49C491EA0DE356FEE276B5BA361228E9A3C32ED1`.

The executable files in `C:/Users/zerha/.rokit/bin/` are Rokit shims. They failed with `ERROR home directory not found` in this managed shell. The checks/build used the already installed executables under `.rokit/tool-storage/` (same pinned tool versions), without changing home variables or downloading anything.

Rebuild from this folder using the normal configured shell:

```powershell
& C:/Users/zerha/.rokit/bin/rojo build greybox.project.json -o guardian-greybox.rbxl
```

Managed-shell fallback used here:

```powershell
& C:/Users/zerha/.rokit/tool-storage/rojo-rbx/rojo/7.4.4/rojo.exe build greybox.project.json -o guardian-greybox.rbxl
& C:/Users/zerha/.rokit/tool-storage/lune-org/lune/0.10.5/lune.exe run check.luau
& C:/Users/zerha/.rokit/tool-storage/kampfkarren/selene/0.31.0/selene.exe .
& C:/Users/zerha/.rokit/tool-storage/johnnymorganz/stylua/2.0.2/stylua.exe --check .
```

## Runtime/review gaps

UNKNOWN: Studio startup/play, navmesh traversal and guardian feel, prompt event timing, actual fresh-spawn theft <30 seconds, portal-to-portal 20–45 seconds, reset/catch/repeated-input behavior, two/eight-client isolation, full-pen handling under real replication, touch/controller usability, device performance, screenshots/clips, independent critic and Zion approval. No Studio session was controlled and no timing or arena pass is claimed.

Reset/fall recovery keeps a committed item in this server session and returns it home without counting a successful escape. Disconnect destroys the slot and retires transient cargo/placements; rejoin persistence belongs to later work. Eight players are supported; extra players receive a full-slot message. Developer controls do not grant items or change active runs.

Named comparison targets from the supplied plan: **Steal an Egg** for guarded pickup/reverse escape; **BGSI** for clear hub/portal; **Pet Simulator 99** for later reveal finish. Implementation follows the first two mechanic/layout hypotheses; no side-by-side visual or feel comparison has been performed. Reveal is outside T1. T2 is not started and T1 is not owner-accepted.

Read SLICE-V2, ISLAND-PIECES, T1 and the Roblox production skill/gates. No local Keystone Roblox Process Playbook was found in the coordination search, and no Keystone tool was exposed; its complete contents remain UNKNOWN. Applied the supplied rules: prove the plain-part core moment first and leave final art/review to later milestones.

API references checked: [Roblox pathfinding](https://create.roblox.com/docs/characters/pathfinding), [ProximityPrompt](https://create.roblox.com/docs/reference/engine/classes/ProximityPrompt), and [server-boundary security](https://create.roblox.com/docs/scripting/security/client-server-boundary). Prompt handlers validate player ownership, active run identity, proximity, state and hold duration on the server; client presentation does not award loot.

Lessons:

- When a place contains runtime geometry, verify the binary includes its scripts because a successful empty build cannot prove a playable world.
- When validating seeded layouts, share the validator between runtime and offline tests because two implementations can disagree.
- When Studio is untested, keep pacing and navigation UNKNOWN because static success cannot establish feel.
