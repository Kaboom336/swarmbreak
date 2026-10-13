# Build tomorrow — Steal a Treasure

2026-10-12 plan for 2026-10-13. **Start from the existing shared-island greybox, prove one Meadow, then scale.** [GDD](GDD.md) is the target; old slice-v2 task scope is historical where it conflicts.
Today: docs/reference images only in this folder. Tomorrow: these are FUTURE file lists, not edits performed today. No commit/publish/upload/spend/account creation/real-save resets. Implementation starts only under tomorrow's task authorization.
Codex builds/tests/researches; Claude handles Studio/design/reference review; Zion plays/checks. One writer at a time. Do not claim runtime PASS when only compile/Lune passed.

## Source and build destination

Source: `pumpkin/production/slice-v2/prototype/guardian-greybox.rbxl` and its eight Luau sources/project mapping. T1 reports static PASS, both runtime gates NOT RUN. Dummy PvP test is not real two-client evidence.
Preserve prototype and unrelated dirty tree. PROPOSED isolated implementation destination **`pumpkin/production/treasure/game/`**, copied from the prototype after future authorization. Keep executable map separate from docs/art. Do not edit `pumpkin/src` or `pumpkin/giant/src` to make this build work.
Read actual donor code before reuse; inspect rights/LICENCE for any new dependency. No new framework. For production save/UI donors, source-reported `pumpkin/giant/src/{ServerScriptService/Patch.server.luau,StarterPlayerScripts/Patch.client.luau,ReplicatedStorage/PatchConfig.luau}` needs a fresh code audit; nothing from it is imported today.
Future common paths below are relative to `pumpkin/production/treasure/`. Copy names retain Greybox test triggers during early batches, then adapt the runner rather than bypassing it.

## Batch sequence and checkpoints

| Order | Outcome | Dependency / owner gate |
|---|---|---|
| B0 | Baseline copied, prototype reproduced, unknowns recorded | Start here; no assumptions that Studio gates passed |
| B1 | Short, readable Meadow with existing carry/PvP rules | B0; Zion checks core run before economy/art |
| B2 | Container/save contract + whole owned-pet loop | B1; Zion checks acorn→pen→Pup→Coins |
| B3 | One final pen/home/Meadow + actual approved art + clips | B2; Claude critic + Zion visual gate before replication |
| B4 | Eight finished pens + five-island data schema, Crystal playable | B3; one new island checked before remaining content |
| B5 | Frost, Volcano, Ocean, one island sub-batch at a time | B4; each mechanic gets full-loop/PvP retest |
| B6 | Halloween/Christmas overlay + titles; cosmetic shop mocks | Five base islands accepted; no paid IDs/live receipts |
| B7 | Whole-game acceptance, evidence and handoff | All prior gates pass; no publication |

Tomorrow prioritize B0–B3. If gates fail, repair that batch; do not rush B4–B7 to claim whole-game completion. End each accepted batch with local rbxl, evidence, exact next instruction and unresolved risks. Zion's next click should be obvious.

### B0 — reproduce and inspect, no redesign yet

**Files:** future `game/{greybox.project.json,GreyboxConfig.luau,Layout.luau,LootRules.luau,Arena.luau,Greybox.server.luau,Greybox.client.luau,LoopTest.luau,check.luau,selene.toml,roblox_min.yml}` copied from source; `game/steal-a-treasure.rbxl`; `evidence/B0-baseline.md`; `game/README.md`.
Read all executable source, record copied-source hashes, current dirty state and tool versions. Change project mapping only enough to isolate this copy. No old installers. Keep test triggers, production action paths and gate lock.
**Acceptance:** pinned Lune compile O0/O1/O2, StyLua, Selene, exact Rojo build; deserialize/build-source match. Reproduce 50-seed rules/layout checks. Run existing Loop then dummy PvP in fresh Studio player session, record actual failures/times. New data namespace not yet needed; no persistence enabled.
**Full-loop/PvP:** existing gate to placement + dummy handoff; run real two-client contested pickup/Bump/drop/Grab/secure/place baseline separately. Log baseline even if failed; B1 must resolve blockers.
**Zion reviews:** one playable greybox and honest baseline list; expected plain art, no pets/income promise. B0 never self-certifies fun.

### B1 — Meadow geometry and real shared contest

**Files:** `game/{GreyboxConfig,Layout,Arena,Greybox.server,Greybox.client,LootRules,LoopTest,check}.luau`, `game/greybox.project.json`; `evidence/B1/{RESULTS.md,route-table.csv,clips/}`.
Rename ItemName to Treasure, island to Meadow, currency UI absent until B2. Preserve existing item/race authority. Start160×160, shorten **201.65/256.22** source-reported side walks toward110–130; quick90–105 including portal approach. Two ramps/hill, three routes/two cross-links, optional4/6 jumps/recovery, tall cover/log remain. Fit routes without shrinking clearances. Guardian grounded on ramps, never an unreachable summit.
**Acceptance:** recompute true3D carrying routes;50 seeded validations and10 live bidirectional carrying walks (repeat six recipes if pool still six, do not falsely call them ten unique). Test slowest normal controls, touching cover, guardian pursuit, hide clearance and locked throw/disc1.2s before impact. Natural stationary hit/drop and cover interception; no scripted fake hit proves runtime.
**Full-loop:** home→portal→camp Steal→real throw dodge→ridge up/opposite ramp down→real4/6 jumps→miss/recover→cyan secure→own-pen Place. Original ID, exactly one placed object; repeated Steal/return/Place rejected. Separate shortest novice run fresh secured reward<30s target; advanced route exercises don't certify that time. Portal trip20–45s; log exact misses. Carry6.0 remains disabled.
**PvP:** two actual clients, expired/consumed first shields: A Steal, B Bump, same ID drops, neither holds during settle, B fresh Grab, A can legally contest/reclaim, winner secures/places once. Cancel holds on range/cover; simultaneous Grabs and guardian-hit+Bump; verify both clients see same holder/object.
**Zion reviews:** Play one run, jump/hide/throw close call and friend handoff; whether short enough and worth repeating. Failures stop expansion.

### B2 — authoritative containers, pen Open, Coins, feed and durable recovery

**Files:** `game/{TreasureConfig,IslandConfig,PetConfig,ProfileSchema,LootRules,Arena,GreyboxConfig,Greybox.server,Greybox.client,LoopTest,check}.luau`; new `game/{Profiles,PenService,Economy}.luau`; `game/greybox.project.json`; `evidence/B2/{CONTRACT.md,RESULTS.md,economy.csv}`.
Write contract before wiring modules: itemID/state/version/island/containerId/base-roll/event snapshot/holder; SecurePending escape transaction; pending secured cargo; pet identity/active slot; Coins/unlocks/feed target/flags/schema/session lease. One mapped server orchestrator; no second tick loop. Boundary CAS-locks one winner, saves same-ID pending award before success/transfer/refill. Definite no-write rolls back to legal danger socket; ambiguous writes lock/reconcile under same ID, never re-award to rival. Crash after durable write restores once; crash before durable write awards nothing, with no prior success acknowledged. Test both windows, uncertain write and replay. RAM-only pending state is not recovery evidence.
Open automatically on Place (replaces six-second explicit Hatch); persist resolved pet before reveal. First winner gets Common Pup; add1/s only after pet commit. Copy audited donor helpers narrowly; no legacy schedules/compensation/offline pay. TreasureQA isolated stores/profiles; prove disabled legacy remotes cannot mint Coins.
Implement120 FeedI fixed+1/s on first Pup, once;600 Crystal access after3 escapes. Until B4 Crystal ready, hide its purchase or truthfully disable as unavailable; never charge for a preview under this plan. FeedII+ data inert until content gate ready.
**Acceptance:** pure item/profile/economy boundary tests (duplicate actions, insufficient Coins, wrong pen, nonfinite input, concurrent debit); clean lower-income sim checks GDD model. Actual0 balance does not fake +1 tick. Full active pads use explicit archival selection; collection capacity reserved before entry. No saved profile deletion or broad currency rename in real data.
**Full-loop:** fresh real inputs home→Meadow→Steal→escape→Place→Open→one pet→actual Coins tick→120 feed buy→rate2/s. First earner<120s; record full-repeat time including farthest pen. Verify skip/death/UI interruption releases controls without losing/duplicating pet. Collection/lucky fixtures remain separate from timed run.
**PvP:** two clients full handoff then winner's pen Open; exactly one pet, no temporary-holder guarantee consumption, preserved timestamp/roll, loser receives0. Disconnect/reset before secure leaves item for other player; after secure/reconnect reconstructs same item/pet once. Simultaneous secure/debit/open races, session-lock/load failures, save timeout/unknown-write retries; no acknowledged success without durable recovery. Storage outages stay FAILED/UNKNOWN if untested.
**Zion reviews:** one coherent acorn→Pup→Coins loop, first feed rate/value. No new final-art meshes required to pass logic; art remains clearly greybox.

### B3 — one final art set, camera, reveal and review

**Files:** future `game/assets/{pup-a,crow,golden-acorn,meadow-keeper,home-kit,meadow-kit}/**`; `game/{AssetManifest,PresentationConfig}.luau`; `game/{Greybox.client,Greybox.server,PenService,Arena}.luau` visual adapters only; `game/greybox.project.json`; `ASSET-LEDGER.md`; `evidence/B3/{RESULTS.md,COMPARISON.md,clips/}`.
Pup A is LEFT in studio-pup-abc.jpg; locate actual hierarchy/export before intake. Crow actual Blender/FBX, not new image-derived geometry. Check rights, script-free descendants, scale/front/pivots/grips. Golden acorn hollow cap/two halves new authored hero asset, carry≈4 high; pen pet≥4 and guardian11. No visible primitive fallback accepted as finished art.
Only **one** finished pen/run/reveal first; other seven pens remain functional plain layout. Shared native-material palette, chunky canopy/rock/fence modules; preserve frozen colliders. No world texture painting/DOF, no ref image baked into scene.
Implement bounded2.2s Open, COMMON/Pup/+1 Coins/s and tap-to-skip every frame; Rare+ identity effects follow approved reference. No followers in competitive arenas (protect crop/performance); cosmetic followers at home optional later. Camera follows controls, carrier/guardian/landing central9:16, no run cutscene lock.
**Acceptance:** imports accessible locally, missing real mesh fails art gate; repeated assembly no duplicate listeners/parts. Landscape touch≥48px targets, controller selection/close, mute/reduced-motion/skip/rejoin. Profile chosen baseline phone when available; emulation is layout evidence only.
**Full-loop/PvP:** repeat B2 with real acorn grip/colliders and finished reveal;2 real clients handoff→Open. Capture ridge near-miss, hide/search, bounce/Grab, rarity reveal; verify FX do not conceal red disc or reroute physics.
**Claude/independent review:** side-by-side fixed spawn/run/pen/reveal with supplied Steal an Egg, BGSI, PS99; hide/throw against Steal and Hide/Catastrophic Horse Racing. Three fresh critics (clarity, art identity, play/fairness), no self-awarded score; working/change/simplify/delete recorded. Concept review is not Studio acceptance.
**Zion reviews:** one finished run + one pen + one Open and muted9:16 clips. Only after approval replicate art/content. If missing asset permissions need upload, keep blocked art status and let owner handle account step separately.

### B4 — repeat home art and add Crystal Cave through data

**Files:** `game/{IslandConfig,PetConfig,TreasureConfig,Layout,AssetManifest,Arena,LootRules,Greybox.server,Greybox.client,PenService,Economy,LoopTest,check}.luau`; `game/greybox.project.json`; `game/assets/{home-kit,geode,crystal-keeper,crystal-kit,cave-mole,crystal-pet-variants}/**`; `evidence/B4/{RESULTS.md,COMPARISON.md}`.
Replicate approved pen module to exactly8 positions;8 earning pads each. Activate600 Crystal portal after3 escapes and FeedII600/+5 after access. Data-driven islandID/guardian/container/pet tables, no copied island scripts. Explicitly migrate singleton server arena to `arenasByIsland`: independent rules, holds, guardian ticks, pending secure, refill and teardown; membership/origin lookup gates every action. Client targeting resolves active island hierarchy rather than one SharedIsland. One shared arena per island,8 total players. Add one reflector banked throw with locked final disc, no invisible bounces.
**Acceptance:** verify all64 active pads in8-client test, unique pen allocation; arena membership/island access server-side; Meadow and Cave don't share active item/guardian/cooldowns. Validate exact70/25/5 weights sum100 for each table, rates from GDD. Same random roll retained on handoff. Actual per-island assets/IDs all resolve.
**Full-loop:** unfunded real progression to unlock, then Cave geode→escape→Open Cave pet→Coins→feed; confirm1–3min incremental payback fixture separately from gate savings. Test each return to correct home pen, original Meadow loop unaffected.
**PvP:** real2 clients same Cave, then4/8 occupants split across both islands; simultaneous cave pickup/drop/bank hit/Grab→one secured reward. Keep a Meadow carrier/throw active while Cave fills, empties and retires; no cross-island teardown, cooldown or item reset. Full capacity joins fail gracefully without swapping pens; no population queue required.
**Zion reviews:** home count/path access + one Cave bank near-miss + geode Open; accept new pet Mole before multiplying new art.

### B5 — remaining islands, three separate sub-batches

**Files per sub-batch:** `game/{IslandConfig,PetConfig,TreasureConfig,AssetManifest,Arena,Layout,Greybox.server,Greybox.client,Economy,PenService,LoopTest,check}.luau`; `game/greybox.project.json` where mapping changes; appropriate `game/assets/{frost|volcano|ocean}/**`; `evidence/B5-{island}/{RESULTS.md,COMPARISON.md}`. Only config/adapter branches for one new hazard; avoid branching core ownership by island.
Frost: ice crystal, slide shortcut, new Owl;3000 access/FeedIII. Volcano: magma orb, telegraphed vent shortcut, new Dragon;15000 access/FeedIV. Ocean: pearl clam, surge bridge, new Turtle/Dragon variant;75000 access/FeedV. New models separately approved; not recolour placeholders claimed final.
**Acceptance each:** same three routes/two hills/hide/walking bypass; natural hazard≤one active, ≥1.2s readable tell, recoverable misses, shared mercy, no sudden required precision or hazard spawn in protected apron. Check unlock prerequisite/debit and floor/rarity/rate/bonus math; lower-graphics phone contrast.
**Full-loop each:** real portal→island's container→dodge new mechanic→secure→pen→Open correct pet→actual Coins→relevant feed; data/config validator + seeded routes +10 live walks if recipes changed. Replay old-island loop once when shared logic changes.
**PvP each:** real2-client Bump/drop/Grab near hazard and hide exits→single pet; one normal near-miss and one stationary hit/drop; combined hazard+guardian+Bump produces one transition,3s mercy.4/8 clients across all enabled islands; late join/reset/fall/leave never resets another arena.
**Zion reviews each:** one new mechanical beat, one correct container Open, one new species at gameplay distance; proceed island-by-island. Fail or simplify mechanic before the next sub-batch.

### B6 — events and safe cosmetic shop prototypes

**Files:** `game/{EventConfig,TreasureConfig,PetConfig,AssetManifest,Greybox.client,Greybox.server,Profiles}.luau`; `game/assets/{pumpkin,present,halloween-overlay,christmas-overlay}/**`; `game/CosmeticCatalog.luau`; `evidence/B6/RESULTS.md`.
One overlay system, base→Halloween→Christmas→base. Meadow container changes acorn/pumpkin/present, other islands retain base identities. Title switch exact [🎃] Steal a Treasure. Dates/10% costume odds proposed; do not activate live purchases. Cosmetic catalog mock cards use proposed prices, no fake purchase-success action. Receipt implementation is a separate authorized task after product IDs exist.
**Acceptance:** seasonal props noncolliding, no route/guardian/Coins-rate changes; item event snapshot freezes at first pickup. New steals after expiry base-only; in-flight event item opens costume afterward; existing pet safe. Missing optional overlay falls back base, missing required container blocks finished art gate. No commercial pressure during first run.
**Full-loop/PvP:** each of3 skins Steal→handoff→escape→Place→Open→tick; expiry during carrier handoff/secure/reconnect/open conserves same ID/timestamp/rarity/rate. First-guarantee override still Pup, no event reroll.
**Zion reviews:** same action in matched shots, pumpkin/present opening seam, costume identity, truthful title/offer copy; all base loops remain evergreen.

### B7 — whole-game acceptance and handoff

**Files:** `ACCEPTANCE.md`, `evidence/B7/**`, `game/steal-a-treasure.rbxl`, `BUILD-MANIFEST.md`; integration fixes only in prior batch file lists.
Freeze source/package/config versions; record SHA256/dirty state, final file mappings/feature gates and donor licences. Compile/build, config validation, economy simulation; do not rerun broad unchanged tests without a reason.
**Full-loop suite:** one real successful run/Open per5 islands +3 event skins, first fresh earner<120s, exact pickup/secure/whole-loop times, first feed/access, farthest pen, full active roster archive selection. Eight fresh novices together: record EVERY novice's pickup/secure/earner and unsuccessful attempts; single-item contention cannot be certified by first winner/solo timing. Missed<30s secure/<120s earner stays FAILED; shorten routes/refill and retest affected pacing. Whole10min unfunded human session: no grant/admin teleport/debug speed; system/prompt/HUD counts and deliberate Bible exceptions recorded.
**PvP suite:** genuine2/4/8-client same-island and cross-island membership; contention and shields, cancelled/spammed/invalid holds, repeated portal/place/open/buys, late join, reset/disconnect/fall, occupied hide, full storage, save/read/session lease failures. One item→one winner→one pet, loser0, no lost safe cargo. Dummy mode marked separately.
**Art/device suite:** matched spawn/run/hit/escape/pen/Open/shop frames, three critics, Zion10min verdict, landscape touch/controller, actual selected low-end phone FPS/frame time/memory/network/FX cost. Proposed target stable30FPS minimum; measured pass UNKNOWN until hardware exists. No made-up performance result.
Deliver one local rbxl and short route **Play→Meadow→Steal→escape→own pen→Open→Coins→Shop**. If blocked, report exact failed gate and next repair, not a partial “accepted” verdict. A local build does not prove publish permissions/data access.
Release/paid product setup/public clips require later explicit owner instruction. No commits in these batches unless Zion changes the instruction.

## Existing runtime triggers to preserve (B0/B1)

Open the copied rbxl, start fresh player **Test/Play**, wait for character/client readiness. In Server Command Bar, run sequentially; do not move during automated routes:

```luau
game:GetService("ServerScriptService"):SetAttribute("GreyboxLoopTest", true)
-- Wait for actual PASS before triggering next mode.
game:GetService("ServerScriptService"):SetAttribute("GreyboxPvpTest", true)
```

Inspect Result/Success, original item ID, Handoffs, JumpObserved/ClimbObserved/TelegraphObserved, seed/version and Output; conservation failure invalidates both gates. Loop requires fresh first-player state. On failure stop, fix, rebuild and retry fresh. Do not manually set Success or unlock owner gates. From B2 extend the loop runner to pet/tick/feed, preserve placement/dummy tests and add real two-client evidence separately.
Use [Studio Server & Clients](https://create.roblox.com/docs/studio/testing-modes) for real multi-client simulation; official docs distinguish it from solo mode and device/network simulation. Simulate latency/jitter for simultaneous holds. Studio emulation never proves actual phone hardware performance.

## Evidence format for every batch

Record batch/files; source/build hash; PROPOSED targets versus observed values; seeds/routes; original/final item IDs; exact client count and whether dummy; raw Output/clip links; static/build, Studio, critic, owner, device status each PASS/FAIL/NOT RUN. If a target misses, record miss, reason and repair. Owner review gates are future play/design verdicts, not approval to publish.

Lessons: When the prototype is already shared, adapt its tested rules because a fresh framework would discard useful work. When tests use a dummy, add real clients because conservation checks do not establish replication. When one final scene is accepted, batch its modules because approval should precede repeated art production.
