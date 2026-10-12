# Handoff: Steal a Pumpkin, PAUSED (2026-10-12 ~20:45 UTC)

## Status
- PAUSED by Zion 10/12 20:35 UTC: usage goes to Etsy/Whop traffic until a money lane pays. Resume only when Zion says so.
- Direction (Keystone decision "Steal a Pumpkin goes evergreen with guardian island runs and holiday events"): evergreen game, holiday events as re-skins + limited pets; standout = guardian island runs (portal islands from shuffled hand-made pieces; dodge/jump/steal). v1 = home island (8 pens, shop) + ONE simple island run.
- Plan to resume from: pumpkin/production/slice-v2/SLICE-V2.md, ISLAND-PIECES.md (9 pieces), tasks/T1-T5 (T1 = playable Studio greybox, start here), QUESTIONS.md (3 owner questions with proposed defaults: keep the name, solo runs, holiday pets return yearly).
- Older material: concepts/v6 (final concept set), blueprint/ (diagrams, map options), slice/ (stale plan for the old lane map).

## Approved models (model lab place C:\dev\codex-lab\model-lab\model-lab.rbxl; may be unsaved, Zion Ctrl+S)
- Pumpkin Pup = Studio AI mesh "A", assetId 98518831184004 (insert_asset). Pet sizes: pen pets Common 4 / Rare 4.8 / Epic 5.8 / Legendary 7 / Mythic 9 studs; followers 3.2-7.
- Crow = Blender: production/models/crow/blender (build_crow.py, crow.blend, crow.fbx, crow_parts.json). Load into Studio: serve the folder with python http.server, HttpService:GetAsync the JSON, one EditableMesh per part, CreateMeshPartAsync recentres each mesh (offset by the part's vertex centre), rotate 180 deg Y.
- Wild pumpkins: "A fixed" 99871023459752 (round) + "D fixed" 127689219325625 (squat), vivid orange; Graveyard sample (ghost white) in the lab. Each zone/island gets its own themed set.
- Pet effects: no disc; Rare+ rarity outline (Highlight), soft glow, rising sparkles; name tag with name, rarity colour, +candy/s.
- Tools: Blender 4.5 LTS portable at C:\dev\codex-lab\tools\blender (blender.org blocks scripted downloads; official mirrors + sha256 matched).

## Rules learned
- One clearly labelled question at a time; show each model next to the concept AND a real hit.
- Drawings plateau around 7/10; Studio is the real test. Usage cap: Codex builds, Claude judges, max 2 rounds per model, one review page per batch.

## Code
- Branch pumpkin/patch-panic; commit with -c user.name/email from the last commit; only git add pumpkin/giant pumpkin/production pumpkin/tools.
