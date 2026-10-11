# DEVIL'S ADVOCATE: Steal a Pumpkin launch (2026-10-10, for tomorrow)

Read cold: MASTER-LIST, WATCH-NOTES, AUDIT-{SEG0,SEG1,GAMEPLAY,LOBBY-MAP,MODELS-ANIM,VFX-SFX}, FARM-PROPOSAL-A/B, FARM-PLAN, UI-SPEC-V2, LAUNCH-STEPS, launch-art/, and `giant/src` (Patch.server 9.5k lines, Patch.client 6.9k, PatchConfig 1.3k).

## 1. Kill shot

**The store page sells a different game, and nothing on the master list fixes it.** Roblox decides from click-through and first-session playtime whether to send more players. Our storefront is still the pre-pivot "Pumpkin Patch Panic":
- `LAUNCH-STEPS.md` publishes it under the name **"Pumpkin Patch Panic 🎃"**. Its description promises things we are cutting or hiding tomorrow: "grow pumpkins in YOUR patch", "Magic Cauldron" (Brew is hidden until 30 min), "At midnight, ghosts come to steal" (A15 turns raids off), "Blood Moon", "Haunt rebirth + Soul skill tree". It never says the word **steal**.
- `launch-art/icon-draft.png` and `thumb-king.jpg` (dated Oct 8) show the old night scene: a low-poly jack-o'-lantern on a **purple cylinder**, the same "King blob" every auditor called the worst asset. There is no avatar, no pet, no title text and no stealing in them.
- Every game pass and product ID is `0` (PatchConfig 869-883), so day 1 earns nothing and records no conversion data.

Even if all 40 items ship, a kid scrolling Charts sees a nameless pumpkin on a stump and keeps scrolling. Steal-a-X games live or die on a thumbnail that shows **an avatar running with the loot, a guard chasing, and huge title text**.

There is also a 20-day clock: Halloween ends the theme on Oct 31. A first update a week late is half the season.

**Fix (Claude + Zion, about 1 h, after batch 4 below):**
- Rename to **Steal a Pumpkin 🎃**. Keep the DataStore key so saves stay put.
- Capture 3 new thumbnails in-game: a steal chase, a hatch reveal, and the King on his throne. Add title text.
- Rewrite the description around steal → hatch → smash → King.
- Create the passes. **Drop Big Stack**: carry is capped by nest size, so it sells nothing.
- Publish private, then test with 2 accounts.

## 2. Ruling on every list item

Budget: about 8 Codex batches plus 1 buffer. "Cheap version" means the version that ships tomorrow.

| Item | Ruling | Reason / detail |
|---|---|---|
| A1 Saving | KEEP (Zion clicks) | The code is sound: session-locked UpdateAsync, BindToClose, receipts. **Missing:** test a 2-server rejoin on the private publish. Before launch, run the admin reset on Zion's save, which still has the stale PlayTime that triggered the false "Lock your Base" text. |
| A2 Admin reset | MISSING-DETAIL | `adminFunction "reset"` already exists (SRV 9204-9293). Only check that a client button calls it. 5 minutes, no batch. |
| A3 "Sell for 0" | MERGE → B2 | It goes away when the Sell prompt is cut from the soil. Also make the sell prompt amount equal the amount paid (SEG1 #37: 20.7k shown, 18,900 paid). |
| A4 Farming pays too little | MERGE → A12 | Same fix. |
| A5 First quest clarity | MERGE → A14 | |
| A6 Text overlaps | MERGE → HUD batch | A pop stack above the counter, the rate on its own line (or cut), and the objective drawn without a box above the world billboards. |
| A7 Performance | KEEP, cheap only | Do the nest-egg swap to the mesh carrier (−3,000 parts and welds), delete the hub wall bricks (−2,700), and set billboard MaxDistance 40-60. **CUT M17 union baking** (L effort, Edit-time GeometryService, risky the night before). |
| A8 JOIN RAID fling | KEEP (blocker) | Root cause in code: `kingJoinEvent` pivots the character to `market.Plaza.Position + (0,5,0)` (SRV 8471). That is the centre of the statue and plinth, so the avatar is spawned inside them. Fix: delete the screen button and make a walk-in ring at the throne. If a teleport stays, reuse the raycast landing from `teleportFunction` with an offset. |
| A9 Guardian never wakes | KEEP (blocker), MISSING-DETAIL | Two causes. (1) The eyes never light: `VoxelModels.build` names every part "V" (M05). (2) The chase ends at once: the guard gives up when the thief leaves the zone Z range + `HoardLeashPad 10`, and nests sit near the edges. Codex must check this by logging `g.state` per tick during one steal, not by guessing. Tune it to be escapable (keep `GuardianFirstShare 0.8`). Fire "You got away!" only if the state reached `chase`. |
| A10 Price wall | MERGE → A12 | Also scale the quest rewards to about 30-60 s of income, not a flat 20 candy. |
| A11 One name per thing | KEEP (text pass, S) | Use: Pumpkin (carried), pet name on hatch, **King Fight**, **pen**. Fix "a ORANGE". Do it in the HUD batch. |
| A12 Economy retune | KEEP: the single source of truth for numbers | Apply the AUD-GAMEPLAY §5 table **except** `DayLength`/`SpookyLength` (see §3). It overrides FARM-PLAN §5. **WRONG claim to watch:** the sim "passes" partly because the same change rewrites `Progression.arrivalMinutes`, which are the targets the sim checks. The acceptance test must be a real fresh-save playtest, not only lune. |
| A13 Next-gate bar + King pity | KEEP the bar | Pity weights are config. The "KINGLET in N" label is 1 line on the loot board. |
| A14 First session = 5 systems | KEEP (mostly config) | |
| A15 Loss rules | KEEP (ambient raids off; Purge fully off per A28) | Also remove every "Ghosts coming! Go home" and "Lock your Base" message that the cut makes untrue. |
| A16 One event chip | KEEP in the UI only | Do not change DayLength (§3). |
| A17 Offline income | CUT-TO-LATER | It is a new system with no day-1 value, because nobody has been away yet. Ship it as the day-3 update ("While you were away!") so there is something new to post. |
| A18 No hatch for 5.5 min | KEEP, cheap | `baseSlots` 6→8 (`woods` 10, `castle` 12; check `slotRows` geometry), **and** Swap plays the normal hatch reveal instead of a toast. Do not build a new full-pen flow. |
| A19 Objective stuck / contradicting | KEEP | Objective as a state machine: carrying → "Bring it to your pen", in pen → "Place it", then the next affordable thing. Never "Pens full" while the player is out stealing. |
| A20 Eyes / gold faces | KEEP (S) | Same `p.Name = paletteKey` fix as A9. Batch 1. |
| A21 Few-player servers lack steal targets | CUT-TO-LATER (NPC pens); KEEP config | NPC or bot pens are a new system. Nests are already the always-on steal source. Cheap version: set Max players to 8-10 (not 16) so servers fill, and check `HoardRefill` keeps the nests stocked for 1 player. |
| A22 Badges | KEEP, cheap, optional | Zion creates 3 badges (welcome, first steal, first hatch). Codex adds `AwardBadge` behind ID-0 guards, like the passes. About 15 lines in batch 2. Skip it if Zion has no time. |
| A23 Stacked Swap/Sell prompts sold 4 rares | KEEP (blocker), moved to batch 1 | This is data loss. Delete both soil prompts now (`SRV 3516-3530`). On a full pen, a delivery auto-replaces the weakest pet **with a reveal** (A18). Selling happens only at the stall. |
| A24 "Guard stunned" then bonked | KEEP (blocker), merged with A9 | **Cut the TAP QTE.** The rule becomes one sentence: grab → guard wakes → chase → catch = the pumpkins drop on the ground and can be re-grabbed. Batch 1. |
| A25 Gate takes 92 % with no confirm | KEEP | Unlock on a hold-E prompt that reads "Unlock Haunted Woods: +2 pen slots, 2 new pets" (no touch-buy). Then an unlock burst and a "+277/s!" pop at the pen. The prompt goes in batch 2, the celebration in batch 7. |
| A26 AFK is the best play | WRONG as a launch problem | AFK playtime counts toward Roblox session metrics, and every steal-a game pays AFK. A12 makes active play pay 1.5-2x AFK, which is enough. **CUT the collect plate** (new system). `IdleShield` is moot with raids off. |
| A27 Witch one-shots everything | KEEP, MISSING-DETAIL (contradicts A12) | A12 raises candy but leaves HP unchanged, so in Zones 1-3 (the whole first session) every scythe past Iron still buys nothing. Fix: set each zone's `hp` so that zone's recommended scythe needs 2-3 hits (e.g. Z2 hp ≈ 2.5 × Bone dmg), keeping candy per *second* as simmed. **Re-run the sim.** Batch 2. |
| A28 "The Purge": IP name, does nothing solo, clock soup | KEEP as a CUT | **Turn the Purge off at launch** (`Purge.minutes = {}`), which supersedes A15's hourly Purge. Then nothing needs renaming, the IP risk is gone, and there is one clock fewer. Bring it back later as "Thief Night", only with 2+ eligible players. |
| B17 Carried pumpkins = glowing cubes | MERGE → B15 carry | Opaque real mesh pumpkins: the first at the chest, the rest stacked small above the head. No bubble, no halo. Batch 7. |
| B1 Farming feel | KEEP §1-4 and §6 of FARM-PLAN; §5 WRONG (superseded) | Its "Zone 1 stays 1, Z2-7 x3, baseCandy" is replaced by A12. Keep BonkCooldown 0.55 (both sims assume it). |
| B2 Plot UI | KEEP | One tag (name in rarity colour + $/s) within 25 studs, one prompt per viewer. Cut Swap/Sell from soil (sell at the stall). Cut the OwnerPortrait, the floating Upgrade billboard and "YOUR BASE" near the pen. **Cheaper:** Lock + Upgrade as 2 big ProximityPrompts on the sign post, not a SurfaceGui button board. |
| B3 Index | KEEP, cut to the cheap version (§5) | |
| B4 HUD to top-game level | KEEP, cut to the cheap version (§5) | |
| B5 Red tint | KEEP (blocker) | Edge-only vignette under the HUD DisplayOrder. Only while chased or carrying a stolen pet. Off in the Safe Zone. Batch 1. |
| B6 Hatch reveal | MERGE with B15 + B12 into the "payoff" batch | Reveal on every hatch in the first 10 min and on the first of each pet. Close panels and queue toasts behind it. |
| B7 HUD clutter | MERGE → B4 | |
| B8 Steal cutscene | KEEP as a cut | Delete it. That is about 10 lines removed and an interruption gone. |
| B9 16-sound kit | KEEP, cut to 8 | Use Hit/Crunch, Pop, Candy tick, Grab, Growl, Reveal, Buy and UI click, with 3 SoundGroups and a pool. **MISSING-DETAIL:** Codex cannot audition audio. **Claude** must pick the IDs before the batch with `Roblox_Studio search_asset` and confirm each one plays in a published (not only Studio) place, since audio privacy blocks many library IDs. |
| B10 Camera shake | KEEP (S) | Batch 1. It revives 15 dead call sites. |
| B11 Colour grade | KEEP (S) | Lighting batch. |
| B12 Reward moments | MERGE → payoff batch | Steal grab and purchase only. Rarity escalation on the card is optional. |
| B13 Midnight night look | CUT-TO-LATER | With raids off (A15), midnight is just a nest refill. Replace it with a "Nests restocked!" toast and a glow beam on the nests. A 45-s night every 2.5 min just flickers. |
| B14 Shop icons / muddy colours | MERGE → B4 | Icons come from ViewportFrame renders of our own scythes, not uploaded art. |
| B15 Hatch payoff size, pet life | KEEP | Pet size ≥ 0.8× the pen pumpkin, a pop-in tween, hop and tilt (about 30 client lines). Epic+ aura only. **CUT** the R15 carry and slash animations, which need an uploaded Animation asset. Cheaper: rotate the shoulder Motor6D C0 procedurally in the existing swing RenderStepped, hold the first pumpkin at the chest, and delete the halo ball. |
| B16 Programmer art | KEEP the S parts | Scarecrow jack face + arms down. Startup assert so the Jack fallback never shows. Foil gold finish (A20). Skip CandyBat/Moth/GoldenPup silhouettes (LATER). |
| C1 Lobby premium | KEEP lighting + recolour + lanterns; CUT the prop flood to about 30 | 120-150 props works against A7. The throne is the centrepiece (see C2). |
| C2 Voxel King | KEEP, merge with the throne | One model: the voxel PumpkinKing **sits asleep on the throne** in the hub, then stands and walks at King Fight. That gives one hero silhouette, one boss and the thumbnail subject, with no separate GiantJack throne build. |
| C3 Lime / checker walls | MERGE → C1 | |

## 3. Contradictions and my rulings

1. **Zone 1 candy: FARM-PLAN keeps 1, AUD-GAMEPLAY sets 8.** AUD-GAMEPLAY wins. It answers Zion's complaint and was simmed together with the gates (2.5k first gate). FARM-PLAN's "any Z1 raise fails the sim" only held at gate 1000. Apply the whole A12 table at once, never mixed.
2. **King payout: FARM-PLAN `baseCandy` (freeze the King) vs AUD-GAMEPLAY `farmSeconds 1800` on the new candy.** AUD-GAMEPLAY wins: the King must be worth showing up for. Do not add `baseCandy`.
3. **DayLength 150→255 (AUD-GAMEPLAY) vs the UI-only timer merge (SEG0/SEG1/UI-SPEC).** Keep DayLength 150 and SpookyLength 90. A longer day means fewer midnight nest resets, so steal supply drops the night before launch, and there is no evidence the sim models it. The clock problem is a UI problem, so fix it in the UI.
4. **Which single timer: King (SEG0), Midnight (SEG1, UI-SPEC H4) or the next event (GAMEPLAY).** Ruling: **one chip showing the soonest event** ("NESTS REFILL 1:12" or "KING FIGHT 0:45"). King appears only after 10 min of playtime. No boost tray at launch.
5. **Voxel vs mesh.** SEG0 A36 wants voxel smash pumpkins, while MODELS M02 wants the mesh carrier for performance. Ruling: **anything with a face is voxel** (pets, guards, King). **Anything you smash or carry is mesh.** No new voxel breakables.
6. **Ghosts.** A15 turns raids off, but midnight copy, B13 and the store description still promise ghosts. Ruling: no ghost raids, no ghost text, no ghost on the store page until the Purge returns in an update.
7. **Stack/carry.** A14 sets `Stack.max = 1`, while the Big Stack pass sells "carry 3 more". Ruling: drop Big Stack, hide the Carry upgrade card, and make DoubleCandy also double smash candy (now 20-50 % of income).
8. **Index rewards.** UI-SPEC gives permanent +5/+10/+25 % multipliers and 5 finish tabs, while A12 tunes the economy without them. Ruling: candy-only rewards plus a title. **No multipliers and no finish tabs** at launch, so they cannot break the simmed curve.
9. **Icons.** UI-SPEC says "ImageLabel art only, made with generate_texture or uploads". Uploads need Zion's account and pass moderation, which can take hours on launch day. Ruling: use **ViewportFrame renders of our own models** for scythes, pets and the King. Use at most 4 uploaded icons (cart, book, candy, gear), and fall back to text if moderation is late.
11. **A15 hourly Purge vs A28 "does nothing solo".** No Purge at launch (see A28).
12. **A12 candy ladder vs A27 one-shot scythes.** Change `hp` and candy together in one batch, and re-sim.
13. **A18 "more slots or swap" vs S2-01/S2-05 "selling is the real game".** On a full pen, auto-replace the weakest pet with a reveal, and sell only at the stall. Pets remain the bank.
10. **SaE colours vs our identity.** UI-SPEC copies SaE hex values exactly (#44FF00 Shop, #0EF3FF Index), while the brief says "distinct own style". Ruling: keep SaE's layout and button grammar, but use our palette: orange Shop, purple Index, candy-gold numbers.

## 4. Missing, and will hurt day-1 players

- **Phone layout.** Most Roblox players are on phones, and no batch has a phone acceptance check. The Index at 0.58w is about 220 px wide on a phone, so its tiles are unreadable. On touch, open panels at 0.92w × 0.85h. Test every UI batch in the device emulator (`rbx-device-simulator-lua`) at phone size, and check that the jump and thumbstick zones (x > 0.72, y > 0.62) stay clear. Hold-to-swing must work by holding a finger down.
- **First 60 seconds.** Tutorial order is steal → place → instant hatch (2 s) → smash. A9 makes the guard chase for real, so the very first steal at 0:10 must be unlosable: the first-ever chase is a cosmetic chase (the guard never catches). Today `GuardianFirstShare 0.8` only slows it down.
- **No ways to lose early.** This needs A15 + B5 + no Daily popup mid-run, all already ruled.
- **Save loss.** The code is fine. The risks are process: Studio API access left off, a reset left out on the admin save, and a crash leaving players locked out for `SaveLockSeconds 120` (acceptable). Any new saved fields (Index claims) must default safely when an older save has none.
- **Exploits.** The candy multiplier makes autoclick macros 10-100x more valuable. The server bonk cooldown and the anti-teleport check hold. Index claims must be server-side, idempotent and saved, never trusted from the client. The sell price must be computed on the server when the sale happens.
- **Monetization.** All IDs are 0 (see the kill shot). Also add a **"Skip hatch / Instant Hatch" product** later, not tomorrow.
- **Failure telemetry.** Keep `_G.WatchLog`-style funnel events in live (onboarding funnel is mentioned in LAUNCH-STEPS). Confirm they fire for: first steal, first hatch, first smash, gate 1, quit time.

## 5. Cheaper alternative for each L-effort item

| L item | Ship tomorrow instead |
|---|---|
| B4 Full HUD rework (UI-SPEC §2-5) | `makeButton` + 2 font tokens + 3 left buttons + one event chip + big candy counter + RUN!! as a label + Drop. No right column, no boost tray, no Pets tile. Restyle the Shop to the card grid using the same `makePanel`. |
| B3 Index (finish tabs, multipliers, outlines, detail card) | One "Plain" grid. Static ViewportFrame tiles (yaw −25, built lazily, tinted silhouette when locked), name/???, a per-tile CLAIM (600 × income candy), "Unlocked 5/15" bar, CLAIM ALL with a badge. Skip the detail card, finish tabs and the outline viewport. |
| C1 Lobby premium (props + throne build) | Lighting preset + recolour (`hex()` edits in Lobby.luau) + 30 wall lanterns + 2 string-light rows + the voxel King on the existing plinth, lowered to eye level. |
| A7 Perf (union baking) | Mesh nest eggs + delete the wall bricks + billboard MaxDistance. That covers most of the win. |
| B9 16-sound kit | 8 sounds + a pool + SoundGroups. |
| M10 Client-side guard replication | LATER. Visible wake (eyes, "!", growl) carries the feel. |
| M04/M12 R15 animations | Procedural shoulder Motor6D in code. No asset upload. |
| FARM-PLAN §6 full pooling | Pool `play()` and `burst()`. Skip FX for other players' hits beyond 60 studs. Highlights and candy-bit pools are optional. |

## 6. Build plan (one Codex task each, in order)

Before batch 1, **Claude** does 3 things:
- Picks the 8 sound IDs (published-place check).
- Writes the exact A12 config diff.
- Runs the sim.

| # | Batch | Files | Acceptance check |
|---|---|---|---|
| 1 | **Blockers:** A23 delete the soil Swap/Sell prompts, A8 ring/landing, A9 + A24 wake + real chase (QTE cut, a catch drops re-grabbable pumpkins) + honest toast, A20 + M05 part naming, B5 vignette, B10 shake, B8 cut cutscene, A16 stale banners, A19 objective state machine | server, client, VoxelModels | No Sell or Swap prompt on the soil. JOIN 20 times with no death. A catch drops pumpkins that can be grabbed again. The guard's eyes turn red, it chases ≥ 3 s, and "got away" fires only after a chase. No tint in the Safe Zone. Shake is visible on a hatch. |
| 2 | **Economy + first session:** A12 table (minus DayLength) + A27 zone hp, A28 Purge off, A25 hold-E gate prompt, A22 badges (ID-guarded), Max players 8-10, A13 bar, A14 order and hides, A15, A18 (8 slots + swap reveal), quest rewards in seconds of income, DoubleCandy covers smash, Big Stack and Carry hidden, Daily only in the hub | config, server, client | `lune econ-sim` prints OK. **A fresh-save 10-min playtest:** first hatch < 1:00, Zone 2 by about 3 min, never > 90 s with nothing affordable, a hatch reveal within 5 min. |
| 3 | **Farming feel** (FARM-PLAN §1-4 + §6-lite + 8-sound kit + pools) | client, server (weights) | FARM-PLAN tests 1-5 and 7. Instance count flat after 2 min of 2-player farming. |
| 4 | **Look:** one grade, bloom 0.95, lilac ambient, recolour, lanterns and strings, King on the throne + boss swap, mesh nest eggs, wall bricks gone, billboard MaxDistance | scene builders, server | Part count ≤ 7.5k. A side-by-side hub capture vs SaE, blind-judged as not the "cheap" one. The King walks without sliding. → **Then make the thumbnails.** |
| 5 | **HUD** (cheap B4 + A6 + A11 + B14 Shop cards) | client | Phone and desktop captures: no overlap, 1 timer, 3 left buttons, a 5 % sh candy counter. |
| 6 | **Index** (cheap B3), server claim dedupe saved | client, server | 15 tiles with pictures and silhouettes. Claim pays once and survives a rejoin. Readable on a phone. |
| 7 | **Plot + payoff:** B2, A3, B6/B15/B12, B17 carry, A25 gate celebration | server, client | 1 prompt and 1 tag per pet. Every early hatch shows a card and the pet pops out ≥ 0.8× the pumpkin size. |
| 8 | **Buffer:** private publish, 2-account save/steal test, fixes | all | Rejoin keeps progress. No errors in the server log over 15 min. |

## Addendum: AUDIT-SEG3 (late findings, Claude's rulings)
- Batch 1: hatching pumpkins and freshly swapped pets must not be pick-up-able (player got stuck 40 s holding them in a full pen); no smashing while carrying; with QTE cut, TAP and RUN never both show.
- Batch 2: Swap/auto-replace must not pay out 91% of the stolen value AND hatch it (+195k in 10 s exploit): replacing the weakest pet pays the weakest pet's normal sell value only; after buying a gate the objective points into the new zone; Carry upgrade hidden (already ruled).
- Batch 4/7: Black Cat reveal card renders as a black blob (lighting in ViewportFrame); hatching pumpkin covers the whole pen (scale to slot); Haunted Woods looks like the Meadow (per-zone floor/wall colour).
- LATER: 600-stud return run from Haunted Woods (consider a return portal after gate 2).
