# Steal a Pumpkin — handoff (2026-10-10 23:15Z)

Repo C:\dev\codex-lab\pumpkin-loop, branch pumpkin/patch-panic (pushed). Game code: pumpkin/giant/src (Patch.server/client.luau, PatchConfig.luau), Rojo `rojo serve sync.project.json --port 34872` in pumpkin/giant (running, PID 28816). Studio place GrowThePumpkin.rbxl (OneDrive Desktop), studio_id changes on reopen (list_roblox_studios). New map = workspace.Garden (old one in ServerStorage.OldGarden); models in ServerStorage.PetModels / GuardModels / MapModels / KitSource.

Plans (all through arenas): production/R20-PLAN, BOSS-PLAN, PROGRESSION-PLAN, GUARD-PLAN; reviews R20-REVIEW, R21-REVIEW (all fixed in R22, commit 7adb9b3). Arrows full-length + semi-transparent (848873d). Econ sim: pumpkin/giant/scene/econ-sim.luau.

In flight: lobby study agent → production/LOBBY-SPEC.md + refs/aspects/lobby/REFERENCES.md; UI study agent → production/UI-SPEC.md (includes admin panel for UserId 405476801 + Studio). Next: Codex builds lobby (map edits are Studio/execute_luau, Claude does those) + UI + admin via codex_task.sh (CODEX_BIN=C:/Users/zerha/AppData/Local/OpenAI/Codex/bin/8aaf1547b825b104/codex.exe), then reviewer agent, compile-check/stylua/selene, Studio smoke test + side-by-side with SaE/Tongue Evolution frames, commit, Zion plays.

Saving: DataStore code exists; fails in Studio because the place is unpublished (PlaceId 0). Zion must: 2-Step Verification on, File > Publish to Roblox (private), Game Settings > Security > Enable Studio Access to API Services.

Open notes: King loot board too wordy; locked pedestals should look locked; Zion asked what "people plot in egg simulator" means (assumed SaE player pens).
Pipeline: roblox-builder skill (C:\Users\zerha\.claude\skills\roblox-builder\SKILL.md), refs/tools/study.sh, Keystone decision "Roblox build pipeline is automated".
