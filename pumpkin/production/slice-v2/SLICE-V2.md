# Steal a Pumpkin — evergreen launch slice (v2)

2026-10-12. **OWNER DECISION:** evergreen game; holiday events change its look and limited pets. Guardian island runs are the standout feature. Core: steal → escape → pen → hatch → pet Candy → upgrade → next island.
This is a planning delivery only. No implementation, commit, publish, spend or uploads. This pass writes only `pumpkin/production/slice-v2/`; task file lists describe FUTURE implementation after authorization.

## Evidence, authority and brief

- Checked: old SLICE-SPEC, QUEUE and all six tasks; BLUEPRINT and MAP-REVIEW; v6 CHANGES, critic notes and visual contact sheet; REDRAW-RULES; Hit Game Bible; current source structure, active Rojo mapping, PatchConfig including appended overrides, and relevant server placement/income/guard/save paths; HANDOFF-NOW.
- Latest owner decision overrides the old radial blueprint, option-B recommendation, Halloween-only framing, old scythe/smash tutorial and stale handoff map/model questions. v6 is visual reference, not proof of playable behavior; its pictured prices/rates are illustrative.
- **OWNER-REPORTED approved:** Pumpkin Pup Studio mesh A; Crow source `production/models/crow/blender/`; two vivid-orange wild pumpkin shapes and zone-themed sets; Rare+ outline/glow/rising sparkles; pet name/rarity/Candy/s; pen pets larger than followers.
- **PROPOSED:** all new geometry refinements, probabilities, costs and timings below. **UNKNOWN:** Studio pacing, multiplayer behavior, device performance, fun and acceptance of this plan. No live game research or new independent review claimed.
- Full Keystone Roblox Process Playbook remains **UNKNOWN**: no matching local copy found in refs/active-work/project searches and no Keystone connector exposed. Apply supplied rules: greybox core moment, real art afterward, named-reference arena before acceptance.
- Fantasy: sneak past a huge guardian, bring its glowing treasure home, watch it become an earner. Social: eight visible pens share home; runs are solo in the slice. Later co-op/PvP requires a separate scope decision.
- Target desktop + landscape touch; real minimum phone and performance budget UNKNOWN. Free existing tools/assets only; no Store scripts, purchases, account creation or publishing. Build locally in `pumpkin/giant`; preserve original `pumpkin/src` and real saves.

## Launch content and first route

**One home island + ONE playable guardian island (Pumpkin Meadow).** Island 2 is an unlockable preview, with a “Preview only — next island coming” sign and no active entrance/rewards. No seven-island content build.

1. Spawn near the home portal with one instruction: Enter the portal. Assigned pen marker is visible; no join modal.
2. Arrive on a short shuffled path. See one guardian and one glowing, faceless pumpkin. Walk around cover to dodge its telegraphed approach; jumping/fighting are later mechanics.
3. Hold Steal for 1 s. Server grants one carried pumpkin; guardian wakes/chases. Reverse the SAME assembled route to the SAME portal; returning ends pursuit.
4. Walk to own pen, Place, then explicitly Hatch using the same contextual pen control. Waiting shell earns nothing. First hatch guarantees Pumpkin Pup/Common/+1 Candy/s.
5. Pet earns automatically in one-second ticks. Repeat runs, buy the first Boots upgrade in the single Shop, then unlock island 2's preview at the portal stand.

First reward means the **owned carried pumpkin acquired at theft**, not a free grant or Candy popup. Also report first spendable Candy separately; target <120 s with first earner. No smash-for-Candy side route in this proposal: wild pumpkins are art-only until another slice.
One carry slot per run; eight free pen slots. Full pen blocks new entry before starting a run with one toast. No auto-sell, paid slot prompt or loss. A committed item survives catch/reset/disconnect; catch = 1 s stumble + 3 s mercy, pumpkin retained. Voluntary Drop is optional and owner-reserved; recovery never awards a second item.
Before theft, reset returns home without a reward. After theft, reset/disconnect escrows that same item for home recovery; it does not count as a successful run or difficulty unlock. No failure countdown or item expiry.

## Home and island geometry

Reuse option C's **240×192** home and **96×144** playable island envelope. Old 112-stud dock-to-nest distance is an upper path target, not a straight-lane constraint. Option C estimated ~744 slice parts / ~2,004 all-seven parts; these are old planning figures, not counts or v2 acceptance limits.
- Home coordinates: center `(0,0,0)` on walking surface, +Z north. Eight **38×28** pens, centers X=±88, Z=-54/-18/18/54; fronts face inward. Eight slots inside each; low fences and one pen marker.
- Portal at `(0,0,0)`; Shop at `(0,0,-72)`; first spawn `(0,0,-12)`. Clear main paths ≥12 studs. Validate routed pen-to-dock **88–124 studs** (C allowance); move obstructions if any route exceeds124.
- Same-place local portal transfer; no separate places/TeleportService/loading queue. Up to eight isolated run slots, one per assigned pen, spatially separated and unreachable by normal walking. One guardian per active run, one enemy type learned. Never reshuffle a slot with a player/cargo inside.
- A run uses **3–5 instances**, not 3–5 newly generated shapes: EntryReturn **32×4×24**; Straight **32×4×24** or short16; Left/Right Turn **32×4×32**; Wide Bridge **32×4×24** or short16; GuardianNest **48×4×48**. Optional bypass variant and future-only pieces are in [ISLAND-PIECES.md](ISLAND-PIECES.md).
- Fixed EntryReturn and GuardianNest bookend 1–3 shuffled travel pieces. Default four-piece route: EntryReturn → Straight → Bridge → GuardianNest. Entry portal→connector20 + travel24+24 + arena connector→pumpkin40 = **108 studs** one way. Validated range **84–112**.
- Ground stays level, traversable without jumping; walkable width≥12. Covers create a left/right dodge choice. Guardian is ~11 studs tall, catch radius3.5, initial speed .88×carrier speed; no minimum speed floor that overtakes a starter. Warning≥1.2 s, head start1.2 s; initial values require Studio tuning.
- Guardian follows the assembled route/waypoints and can return through the arena; never use `SafeLineZ` or old zone-Z bounds for safety. The arrival/return pad is the sole run safe boundary. Pathfinding does not cut across void or through cover.

## Pacing and simple economy

| Moment | Proposed target; stopwatch definition |
|---|---|
| First reward | **<30 s** from fresh spawn to authoritative carried pumpkin |
| First earner | **<120 s** from fresh spawn to first actual Candy tick |
| One run | **20–45 s**, home portal activation → return to home portal, including both transfers; excludes pen/hatch |
| First upgrade / preview | roughly2–4 min /5–10 min; tune against guaranteed low-income outcomes |

At walk16/carry15,108 studs outbound+return =6.75+7.2=13.95 s. Two assumed2 s transfers +1 s steal =18.95 s; **2–12 s dodge/approach** gives~21–31 s. This is arithmetic, not runtime evidence. A 12-stud spawn approach adds.75 s; first steal target roughly12–21 s. Home return→far pen≤124/15=8.27 s; explicit hatch6 s + reveal≤2.2 s leaves substantial margin below120. Track catch/decision delays separately; do not hide them in averages.
- Proposed first Boots cost **30 Candy**, one purchase, +2 walk speed (16→18, carry15→17). This replaces current Boots750 and scythe150 for the first upgrade. Preserve saved Boots field/ID; cap active slice effect to level1.
- Proposed island2 preview cost **120 Candy**, exact once-only debit, after Boots; preserve Zone2 ownership field. Replace current final-config2500 and old slice1000. Unlock is permanent; preview is honest and does not promise playable island2.
- First run fixed easy, guaranteed Orange/Pup1/s. Later easy: Common80%/Rare20%; standard: Common60%/Rare40%. Within a tier, Pup/Crow50/50. Common uses existing Orange1/s and Sunny4/s; proposed Rare cosmetic variants use2/s and8/s, recorded separately from legacy seed IDs. No Uncommon/new pet mesh needed. First-run guarantee supersedes weights.
- Standard unlocks after3 successful portal escapes; voluntary, no new currency or upgrade tree. Island1 supports both presets. Later island definitions may raise allowed rarity tiers and guardian tuning, but no future tier rewards spawn here.
- Guaranteed floor: one Pup every45 s, first earner by60 s, hatch6 s. Earners at60/105/150/195 s produce30 by90 s; gross150 around155 s, enough for30+120. These are optimistic steady-repeat arithmetic; human navigation/catches and full pen can delay them. Require actual fresh-route timings, no lucky Crow/Rare assumption.
- All Candy comes from hatched pets. No steal cash, Index claims, wild smash, offline pay, timed bonuses, passes, weights/Gold/Shiny/mutation income or migration compensation in clean slice profiles. Pure collection Index, no rewards/search/filter lesson required.

## First-ten-minute count against the Bible

| Budget | V2 count | Bible limit / result |
|---|---|---|
| Learned systems | **5**: portal theft/escape; pen hatch; pet income; Boots buy; next-island unlock | ≤5 default /pass; optional Index would make6, so no tutorial/claim attached |
| Visible systems | **6**: those5 + passive Index | ≤12 /pass |
| Core verb / earning route / stall / enemy type | Steal /pets only /1 Shop /1 guardian type | 1 each /pass |
| Menu buttons / numbers | Shop+Index; optional Drop contextual /Candy+income/s, carry1/1 contextual | 2 buttons +Drop;2 numbers +carry /pass |
| Prompt families | Portal; Steal; pen Place/Hatch; Shop | ≤4 /pass; locked-island unlock is a state of the portal prompt |
| Tutorial / join popups / loss | 5 steps Enter, Steal, Hatch, Buy, Unlock /0 /0 | 5 /0 /0 /pass; escape/place are states within steps |
| Clock | One local hatch countdown, only while waiting; no global restock clock | ≤1 /pass cap; **deviation** from Bible's5-min world-clock pattern, because runs regenerate on demand |

Jump is normal movement, not a required lesson; no dash, sprint button, health/combat system, scythe hotbar, King timer, Daily, quests, rebirth, fuse, selling or PvP. Never count disabled buttons as zero-visible systems: remove them.
These counts do not certify every Bible law: only2 rarity tiers are obtainable here (six visual tokens retained); Boots reduces travel rather than directly increasing income, so1–3min cash payback is unproven; preview access earns nothing. Rare+ outlines follow the latest owner approval despite the Bible's older no-outline art guidance. Track these deliberate slice differences in acceptance.
At most one focused hatch countdown is rendered; other waiting shells show a waiting state without additional clocks. Island2 unlock prompt shares the portal family; it is not a fifth prompt type.

## Seasonal layer: same game, same loop

Base evergreen identity: bright readable pumpkin sanctuary, cyan daylight, green/cream ground, warm wood; giant readable silhouettes. Preserve v6 Pup/pen/reveal identity and low HUD; use REDRAW-RULES for daylight/readability. v6 dusk and older sunset are references, not mandatory permanent lighting.

| Skinnable layer | Halloween now | Winter next |
|---|---|---|
| Sky/lighting | readable blue-violet sky; warm local lamps | pale cyan sky; cool lamps; bounded snow |
| Palette/materials | orange/grape accents, Meadow lime | icy blue/cream accents, snowy surface skin |
| Noncollision props | authored bats, jack-o-lantern decorations, crooked signs | snow caps, gifts, frosted sign/trees |
| Pet variants/UI trim | limited costume Pup/Crow variants | limited scarf/frost Pup/Crow variants |

Future `EventConfig.luau` chooses one server-owned `eventId` + version at server start; clients receive the same version. Base definitions + one overlay apply to tagged visual sockets; do not duplicate worlds/scripts/saves. Skin cannot change connectors, collision, route seed, hazard telegraph contrast, prices or base rates.
Limited variant eligibility is frozen at successful steal using server time and recorded with the item before return/hatch. A hatch after event end keeps its earned variant; existing pets survive event removal. Example Halloween allocation:10% of non-first-run outcomes substitute a limited cosmetic of the rolled Pup/Crow/tier, same rate; no third earning system. Exact variant art and event dates await owner decision.
Event expiry prevents new limited rolls; revert overlay to base on next run assembly/server start, retain occupied run snapshots. Missing overlay asset falls back to base; missing required hero art blocks finished acceptance. Test Base→Halloween→Winter→Base without altering profiles or reward counts.

## Current-code migration (future work only)

Paths relative to `pumpkin/giant/`. KEEP means reuse inspected foundations and verify them; DELETE means exclude runtime/slice handlers, archive source, never wipe saves or broadly delete files.

| Action | Current file(s) / precise treatment |
|---|---|
| KEEP | `src/ServerScriptService/Patch.server.luau`: load/save/session lock/retry/release, loaded-player guards, pen ownership/slots, carry serialization, exact currency debit foundations. Preserve legacy seed/zone/upgrade fields. Audit atomicity before adapting. |
| KEEP | `src/StarterPlayerScripts/Patch.client.luau`: `UI.tween`, `chunky`, viewport model renderer, sound/FX utilities and panel cleanup; refit presentation. |
| KEEP | `src/ReplicatedStorage/PatchConfig.luau`: seed IDs Orange/Sunny, pet mappings, rarity tokens and inspected movement functions; use final returned values, not first-table values. `sync.project.json` currently maps only Patch config/server/client. |
| REPLACE | `PatchConfig.luau`: active slice policy, tutorial, carry1, hatch6, Boots30/one level, Zone2 preview120, isolated QA save namespace, run/difficulty/variant tables; separate old-profile compatibility from active tuning. |
| REPLACE | `Patch.server.luau`: `Lane.zone`, safety/zone checks, Hoards singleton-per-zone assumptions, wake/chase/bonk, implicit `Hoards.swing` theft; route these through server-owned run IDs/connectors/safe pad. `Bases.put/tick` becomes explicit Seated→Waiting→Hatched with zero waiting income and fixed saved outcome/deadline. |
| REPLACE | `Patch.client.luau`: lane/gate guidance, HUD/shop/scythe controls, carry/camera/hatch adapters; portal transfer feedback and own-pen arrow; no client reward authority. Upgrade control stays inside Shop. |
| REPLACE | `scene/Lobby.luau`, `WorldPlan.luau`, `LaunchLook.luau` through `LaunchLook5.luau` execution with one future `scene/IslandScene.luau` and approved model package. Required legacy containers remain only while adapters need them. |
| REPLACE | Visible `scene/VoxelModels.luau`, `VoxelKit.luau`, `PatchConfig.buildScythe`, server `makePumpkin/Looks.wild/Looks.hatch/guardLook` fallbacks with approved mesh adapters. T1 plain parts are temporary physics/layout evidence only. |
| DELETE from active slice | `Patch.server.luau`: Wild Candy rewards/spawning, `runDay`, KingNight/raid/Purge/ghost/Spooky scheduling, player theft/locks, sell/autosell/fullChoice, cauldron/fuse, orders/reward grants, Daily/Index rewards, passes/receipt economy, offline income and compensation grants. Remove matching client UI/handlers, not just hide tiles. |
| DELETE from assembly | `scene/BuildScene.luau`, `BigMap.luau`, `PatchMap.luau`, `Pyramid.luau`, `Revamp1.luau`, `Dressing10.luau`, `Polish6.luau`, `install.luau`, `install-server.luau`, `install-client.luau`; avoid embedded Source replacement. |
| KEEP excluded | `src/ServerScriptService/Feed.server.luau`, `src/StarterPlayerScripts/Giant.client.luau`, `src/ReplicatedStorage/GiantConfig.luau` already outside Rojo mapping; do not revive pyramid/Gold/growth loop. |
| REPLACE checks | `scene/SliceSmokeTest.luau`, `econ-sim.luau`, `combat-check.luau` route assumptions; reuse `compile-check.luau`. Archive `SmokeTest.luau` historical destructive route; never Admin-reset owner data. |

Future additions: `src/ReplicatedStorage/IslandConfig.luau`, `EventConfig.luau`; `src/ServerScriptService/IslandRuns.luau` required by Patch (not a second main loop); `scene/IslandScene.luau`; script-free `assets/slice-v2/`. Preserve existing PatchRemotes and agree one request/state contract before adding run actions.
Reuse first: existing code and approved meshes, authored piece templates. Local KayKit Space Base Bits/Kenney Space Kit licences are CC0 (checked); their space art is not assumed suitable or approved. No third-party game framework adopted; reference screenshots supply comparison, not redistribution rights.

## Execution and acceptance

Sequential [T1 greybox](tasks/T1-studio-greybox.md) → [T2 contract/run authority](tasks/T2-run-contract.md) → [T3 complete economy](tasks/T3-pen-economy.md) → [T4 art/season/UI](tasks/T4-art-season-ui.md) → [T5 acceptance](tasks/T5-acceptance.md). One writer at a time; no current authorization to execute these tasks.
T1 is a separate local Studio greybox that Zion can play: eight plain pens, shop block, portal,3–5 shuffled plain pieces, one dodge guardian, steal/escape. Prove this core moment before final art or live save work.
Best-in-class anchors from supplied evidence: **Steal an Egg** for guarded loot/return; **BGSI** for portal/hub legibility; **Pet Simulator99** for pet/reveal finish. Compare our run/home/reveal frames side by side with those local references. Portal pursuit ending at dock is a deliberate difference; dodge choices must make the short run interesting.
Claude handles Studio/design review; Codex handles code/build/research. A fresh independent critic must identify working parts and what to change/simplify/delete; no self-issued arena pass. Zion checks one finished pen + one run + one reveal before decorative replication. Eight functional greybox pens are required for layout/capacity, not permission to multiply final art.
Acceptance requires real fresh pacing, fixed-seed shuffles, solo/two/eight clients, transfer/item conservation, save/rejoin, full-pen behavior, landscape touch and10-min absence of late systems. Distinguish static/build, Studio, visual/critic, owner and real-device evidence. No commit/publish.

Lessons: When topology changes, replace spatial assumptions because old safety helpers can silently end danger. When events end, preserve item identity because cosmetics must not erase earned pets. When first-session targets are modeled, time actual input because arithmetic cannot prove clarity or fun.
