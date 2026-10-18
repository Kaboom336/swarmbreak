# PORTAL HEIST — core-loop arena

2026-10-18. **DESIGN ONLY. No implementation, build, place edits, launch or Studio Play.**

**Decision: choose A, Crack and Escape.** Pick an island at home, read its routes, crack the treasure seal, outsmart the Keeper and its route-control raid, escape through the collapsing portal, then bank/open the treasure into an earning pet. Buy an upgrade and attempt the next heist. Prove Meadow once before integrating Crystal Cave; retain two separate map lanes behind one shared-system owner.

**Evidence key:** CHECKED means inspected local document/source, not executed behavior. OWNER-REPORTED means Zion's instruction. **Every proposed rule, timeline, price, design score, comparison judgment and expected outcome in this document is INFERRED and untested**, including tables and numbered steps. UNKNOWN means evidence is absent. No retention, fun, performance, revenue or first-playable claim follows from this arena.

## Owner brief and authority

**OWNER-REPORTED, Zion, 2026-10-18, verbatim:**

> "well I wouldn't say we have a playable game yet so no launching and maybe we can have 2 codex lanes for map if that works for the 2 starting maps, we should aim for 2-3 on release with a good core game loop mechanic, we should have it act like a portal heist".

The requested deliverable is this arena and its phone summary. Two to three release maps is an aspiration, not a release decision. The first-playable target is **Meadow + Crystal Cave connected to the same home/economy**. Frost is a possible third map, outside this build plan. This latest brief replaces SIMPLIFY's proposed Meadow-only launch and the older GDD's five-map starting scope. Historical files remain unchanged. No launch work, purchases, accounts, publishing, messages to others or Studio Play is authorized. Future validation below also excludes Studio Play.

## What was checked

Reference root: `C:/dev/codex-lab/refs/`. Read the requested Hit Game Bible, Game Theory Checklist, TikTok Roblox Lessons, and the four studies: Steal an Egg, Steal a Brainrot, Grow a Garden, Pet Sim 99. These are supplied historical studies, not newly watched footage or current market rankings. Read [GDD](GDD.md), [ROADMAP-TO-LAUNCH](ROADMAP-TO-LAUNCH.md), [PACIFIST-ARENA](PACIFIST-ARENA.md), [RAID-ARENA](RAID-ARENA.md), [RAID-REVIEW](RAID-REVIEW.md) and [SIMPLIFY](SIMPLIFY.md). Inspected the following source paths and relevant integration points.

| CHECKED source | Established in source / implication |
|---|---|
| [Greybox server](../slice-v2/prototype/Greybox.server.luau), [config](../slice-v2/prototype/GreyboxConfig.luau) | One global arena/rules object, one home entry, same-place character `PivotTo` travel. Steal 2s; cargo escape deadline 60s from completed Steal; first-hit retention false; walking/carry speeds 16/13.5; capacity 8. `returnRun` persists through `core:secure` before normal secure/home. This is a reusable path, not evidence it currently feels complete. |
| [Gameplay](../prototype/meadow-v4/Gameplay.luau) | Meadow v4 is 352 wide; nest (0,48,96), portal (0,0,-136), route/drop fixtures derive from Fix2Routes/RouteData. Coordinates are map-local; do not transplant Cave or section coordinates without transforms. No route timing was measured here. |
| [Domain](../prototype/core/Domain.luau), [Service](../prototype/core/Service.luau), [Config](../prototype/core/Config.luau) | Pending secured cargo, place/open, owned pets, online bank accrual, collect into spendable Coins exist. Default rarity rates 1/4/8; first pet tier override exists. `feed`/`unlocks` fields exist; inspected core modules provide no Feed purchase or Cave-unlock transaction. MaxPets=8 is a hard collection cap, not the GDD's separate 64 collection/8 active system. |
| [Profiles](../prototype/core/Profiles.luau), [Runtime](../prototype/core/Runtime.luau) | Session-owned ProfileStore integration, pending transaction/revision and asynchronous save acknowledgment. Unacknowledged writes become uncertain and block new transactions. Runtime can use a volatile mock; durable behavior is UNKNOWN here. Preserve acknowledgment semantics. |
| [CoreLoop test entry](../prototype/core/Test.server.luau), [core assembly](../prototype/core-build.luau) | CoreLoopTest is a runner/attribute integrating Domain/Profiles/Service; there is no standalone `CoreLoop.luau` in this inspected core directory. Do not create a second economy because of that name. Studio-only store fixture is not to be invoked. |
| [HomeArt](../slice-v2/prototype/HomeArt.client.luau), [Scene](../slice-v2/prototype/Scene.luau), [Section10](../prototype/meadow-v4/Section10.luau) | Existing art and locked portal row are cosmetic. A visible Cave arch does not establish Cave travel or a numeric unlock. Retain art, bind it to authoritative portal state later. |
| [RaidSlice](../prototype/meadow-v4/RaidSlice.luau), RAID-REVIEW | S2 and S5 forks; east eligibility after one Meadow escape; tell 1.5s, full-client warning minimum 1.2s. Existing route-control, native Jump vault and walking bypass are foundations. One deployment per cargo, coordinator/mercy/readiness must survive integration. |
| [Cave loop](../prototype/cave-v2/Loop.server.luau) | Separate in-memory player profiles and cargo, 2s geode prompt, 60s clock, `Domain.secure` in RAM; explicitly no saving. Opening is at the Cave beacon, not the shared home. It uses the shared Meadow rarity table. This is the critical whole-loop gap. |
| [Cave cart](../prototype/cave-v2/Cart.server.luau), [Policy](../prototype/cave-v2/Policy.luau) | Deterministic cart/boarding/switch/speed path and support blast: 1s fuse + 2s cracks, occupancy-aware gap change/repair. No ram/blast damage. Some other Cave threat hooks are previews; a working Keeper/raid equivalent there is not established. |

Source conflicts: roadmap's missing core/Cave list is historical; current source contains both foundations. GDD's 1s steal, first-hit retention, five-map minimum, automatic opening, and 64-pet collection are not current implemented facts. `Service:load` currently maps total `escapes` onto `meadowEscapes`; adding Cave without per-map counters would incorrectly advance Meadow/Bell/raid progression. Global rarity configuration would also give Cave Meadow rewards. These require explicit migration/integration work.

Reuse first: retain project code and existing approved-direction art; no external kit is adopted. Checked [dependency ledger](../prototype/core/Packages/README.md), MIT RbxUtil notice and Apache-2.0 ProfileStore license. Keep notices with reused dependencies; game-study references grant no code/art rights. No new asset rights are assumed. Exact Keystone Roblox Process Playbook was not found in accessible local active-work files or callable Iris/Keystone tools; its text is UNKNOWN. Applied the supplied real-art, core-moment, reference-comparison rules and installed Roblox production skill. Do not claim the original playbook was read.

## Reference arena — side by side

Best-in-class **selected design bars**, INFERRED from supplied studies; not claims about current popularity or overall quality.

| Reference bar / local source | Our required equivalent | Main gap or deliberate cut |
|---|---|---|
| Steal an Egg: §1/§9, readable guard wake → held prize → RUN → safe line | Keeper commitment → acorn/geode in arms → cyan portal destination | Add portal collapse cause/effect without a second clock. Study's first earner was 96s after control, not proof our <30s secured target is met. Cut its trap/ragdoll combat. |
| Steal a Brainrot: §2/§9, visible owned earner → growing collect value → next buy | Home pet shows actual Coins/s; real collected Coins fund next job | No theft of banked home pets, slap tools, paid security bypass or rebirth reset. Its studied account was post-rebirth, not a fresh novice. |
| Grow a Garden: §3/§10, growing home is visible persistent progress | Each successful heist changes your home collection and next reachable destination | Do not copy multiple restock clocks or idle gardening as the active heist. Study starts mid-game; novice pace UNKNOWN. |
| Pet Sim 99: §3/§9, clear next gate and short reveal | Locked Cave shows exact cost/progress; banked loot gives a short skippable pet reveal | No attack swarm, machine menu stack or extra currencies. Study's late-account footage establishes presentation, not new-player pacing. |
| Hit Game Bible laws 1–5/8–9; Checklist L1–L6/O3/S2/F3; TikTok rules 1/2/6–10/16/18 | One sentence, one actionable goal, one clock; risk → visible bank → meaningful next trip; readable muted clip | Checklist combat, daily/FOMO and loss-free defaults conflict with this owner brief. Treat those as heuristics; preserve bounded provisional loss and remove attacks. Caption claims/older Pumpkin audit are not evidence for this game. |

Pitch: **“Crack island treasure, fool its Keeper, escape, grow your crew.”** Crew means your visible collection of earning pets initially; it does not promise autonomous NPC heisters.

## Rules shared by the arena

All are INFERRED design contracts except owner constraints/current source facts identified above.

- Plan by looking: portal card names destination/reward/one route condition; island vista shows treasure, Keeper, exit and a broad route choice. No required planning menu, key hunt, hiding perch, minion defeat or timed entry queue.
- Pacifism applies to rivals too in the proposed first playable. **Disable the current physical Bump action**, its input and server acceptance; do not rename it into a supposedly harmless action. Keep races to the nest and recovery of legitimately dropped treasure. No player-triggered damage, knockback, forced rival drops, Sticky slow or weapon. This changes current PvP; design only today. Retain guardian/hazard knock-drop, same-ID Grab, mercy, reachable recovery and protected apron.
- One shared contested item per map for A/C. Exclusive winner secures one pet; helping is voluntary, no implied crew split payout. Home pets and Coins are safe. Geometry/encounter settings freeze while occupied, cargo unresolved, or saving uncertain. No force-shuffle under a runner.
- Keeper, raid charges, tunnel hazards and Cave hazards share threat reservations and mercy. Preserve complete warning opportunities, locked commitments, walking bypasses and safe recovery. A portal countdown never shortens a tell. Cart/blast changes terrain, never hurts a character or rams an enemy.
- Loss is only unresolved treasure/time on that attempt, never banked pets/Coins. Empty-handed return always works. SecurePending is protected and locked through uncertain saving, never recycled to another winner. No success toast, new nest or home award before durable acknowledgment.
- No timer refresh on drop, Grab, cart boarding, trick, rival handoff, re-entry or late join. No reward for waiting until the final second. Same cargo outcome travels through every adapter; no reroll at the portal or home.

## A — Crack and Escape

**Core decision:** choose the approach now; steal, then read the getaway fork under pressure. Entry/planning is untimed. Completing the existing 2s Steal cracks the treasure seal and starts the existing 60s item deadline, presented as the treasure portal collapsing. You can extract immediately.

**30-second hook — INFERRED target:** 0–5s face the free Meadow portal; 5–15s enter and identify gold treasure/cyan exit; 15–30s complete Steal, see Keeper react and start the escape. These are targets, not current distances/times. A provisional grab is not an owned reward. First durable secure <30s remains the Bible stretch gate; if actual traversal misses it, report the miss and shorten the initial route before adding chores. First real earner target <120s.

**Five-minute loop — illustrative, not a forced round:** enter → choose broad approach → crack/grab → bait the Keeper into cover → choose the commanded raid gap or walking bypass → cross cyan before zero → save/return → place/open at own plot → pet earns into plot bank → collect → buy Feed I → re-enter. Repeat while saving toward Cave. Faster escapes end immediately; this does not demand a five-minute heist.

**Session goal:** add visible earners, buy one real upgrade, and unlock/attempt Cave through ordinary earned Coins and Meadow bank count. No promise of Cave by minute five.

**What changes each heist:** initially the west/east route choice, Keeper commitment, rivals and optional bell already create variation. Preserve existing east raid eligibility after one Meadow escape and one deployment per cargo; do not add a second mandatory encounter. Later, one pre-entry route-emphasis card selects an authored raid fork while retaining walking bypass, original timer and payout. First run is default; change cards only after the arena is empty and the item resolved. Random geometry, random timer length and stacking modifiers are excluded.

**Progression:** pets are the first crew and earn Coins at home. Buy Feed I (120 Coins, +1/s to first pet) and then Cave access (600 + three durable Meadow banks). Feed is proposed purchase work, not already a working button. Proposed Survey Lens (60 Coins) would preview optional authored shortcuts before entry; critics challenged selling information, so it is removed from the selected first playable. Basic navigation/recovery cues are free. Later gear/crew possibilities and map-three gate are specified below.

**Social/rivalry:** two players choose the same portal and race for the nest; a friend can bait a committed Keeper while the carrier takes the other path. A rival can recover a dropped item after settle/Grab, preserving the deadline. No Bump, trade economy, party requirement, shared payout or attack reward. After winner banks, the next treasure allows helpers their turn. Repeatedly unrewarded helpers are a real retention risk to observe.

**TikTok moment:** “I fooled him and made the portal.” Held acorn, committed Keeper dash into cover, squad lane crossing, shrinking cyan ring, then cut to the same prize's pet and first real earning tick. Retain player control; no manufactured last-second bonus or forced camera. Virality is UNKNOWN.

**Reuse/cut:** reuse existing item clock, cargo authority, Keeper/Outsmart/bell, raid forks, drop recovery, home art, reveal and save acknowledgment. Add multi-map registry/travel, map outcomes, coin purchases and portal-state presentation. Cut attack PvP, keys, heat meter, wave waits, multiple loot bags, required crew roles and camera exposition. Relative integration cost: lowest of these designs, still substantial.

**Smallest Meadow proof:** one nest/acorn, existing Keeper wall-bait, one existing raid fork with walking bypass, one cyan return, own home plot, one pet, real collect, Feed I purchase and another entry. No Lens, modifier picker, new map geometry, third map or army expansion. Existing other art/routes remain available; no rebuild is implied.

## B — Portal Expedition

**Core decision:** cash out the nearby cache or risk a deeper prize before a shared portal window ends. Entry opens an illustrative 180s map-wide window, replacing the 60s item clock. One carried item/player, but near/deep caches produce multiple cargo IDs. This intentionally changes current cardinality and timer rules; it is not a config-only reskin.

**30-second hook:** enter, see near/deep rewards and closing portal, grab the close cache and return for a quick owned reward. Target only; code/route times do not establish it. **Five-minute loop:** near-cache bank/open → collect/upgrade → re-enter for deep treasure → raid crosses the return route → extract or abandon that attempt → bank and choose next map. **Session goal:** get the deep geode earner, not just repeat the easiest cache.

**Variation:** cache distribution/reward tier and one frozen raid-fork preset; alarm at cache completion requests a finite coordinated raid, never an extra heat clock. Shared window is visible before entry; late join allowed only with a declared minimum viable opportunity, otherwise next fresh cycle. Starting/joining groups, remaining-time threshold and empty-server reset need new rules. No forced survival or waiting for waves. Deep loot must visibly improve earning value enough to justify travel; otherwise near-cache farming wins.

**Progression:** home Feed, optional purchased portable stash allowing a one-item swap at an authored socket, then Cave 600 + three Meadow banks and Frost 3,000 + three Cave banks (proposed thresholds). Stash never copies loot, banks it remotely or refreshes time. Optional lookout/cart roles; no crew needed to play alone. **Social/rivalry:** shared opportunity to take different caches, contest dropped loot, or abandon a second trip to help a friend. Same exclusive award per item; no home theft or attack.

**TikTok moment:** deeper prize in arms, friend already at the shrinking ring, choose between another cache and escaping together. **Reuse/cut:** keep Keeper, Outsmart, route-control and Cave cart/blast; replace single active item, per-item expiry, refill/late-join assumptions, outcome storage and pending-award arbitration. Cut required lever/key jobs. Relative cost: highest; shared deadlines can punish newcomers before they act.

**Smallest Meadow proof:** two cache positions on existing legal routes, near/deep visible earning difference, one common closure clock, one raid fork, bank/open/collect/one stash upgrade/next expedition. This needs multiple-item recovery/save collision checks before its risk-choice claim is credible. It is larger than A even on one map.

## C — Alarm Job

**Core decision:** commit a route by pulling a public lever, then steal and escape. Entry is untimed; one required lever unlocks treasure access, and 2s Steal starts the familiar 60s collapse. First lever is beside the nest; later job plans change which viable route the public mechanism favors. Bell remains optional misdirection under its current limits.

**30-second hook:** see lever/loot/Keeper, pull lever, fool Keeper, grab and begin getaway. Extra setup risks missing first reward. **Five-minute loop:** prepare lever/optional bell → crack → dodge coordinated raid → portal → home bank/open/collect → buy side-route key kit → try another plan. **Session goal:** complete different job approaches and unlock Cave's cart job.

**Variation:** one chosen public lever branch and raid-route preset, frozen until retirement. Alarm is visible command cue, not a second timer or permission for stacked attacks. **Progression:** permanent route-key kit bought with Coins gives optional side-lever access, Feed boosts income; Cave 600 + three Meadow banks, possible Frost 3,000 + three Cave banks. No key consumption or purchasable escape time. Key price/balance UNKNOWN; no invented affordability claim.

**Social/rivalry:** optional lookout, lever operator and cart driver; every required step is reachable solo. Rivals can use the lever another player opened, creating free-riding and ownership confusion. No split rewards implied. **TikTok moment:** friend's lever opens route, rival races for the prize, carrier takes Cave cart over the blasted gap and reaches cyan.

**Reuse/cut:** retain one-item deadline, pending award, Keeper/bell, raid and cart. Add public lever/reset/role states and map-specific side keys; cut B's multiple caches/shared window. Relative cost: middle, with more pre-steal teaching than A. **Smallest Meadow proof:** one public lever beside one nest, one bait/fork, full bank/open/collect/key purchase/re-entry. Main concern: a mandatory permission chore repeated forever. Making lever optional is the likely correction, but then it becomes a later route option inside A.

## Three blind critics

Three independent context-isolated agents received anonymous X/Y/Z packets with the same design constraints, candidate mechanics and code facts, no author recommendation or other critics' scores. The engineer additionally inspected source. Mapping revealed here: **X=A, Y=B, Z=C**. These are **INFERRED simulated persona reviews**, not real children/professional participants, blind gameplay or measured retention. Different lenses, one score /10 each; no false statistical confidence.

| Critic | A | B | C | Independent ranking / objection |
|---|---:|---:|---:|---|
| TikTok-age player | 8.0 | 7.0 | 6.0 | A > B > C. A easiest to retell; route repetition weakens it. B shared late clock feels unfair. C lever is a chore. Cut Lens/modifier UI/map-three work from the proof. |
| Retention designer | 7.5 | 7.0 | 6.0 | A > B > C. Feed alone does not create a fresh heist decision; use an authored fork after first bank. Keep safety signs free and clarify that helpers do not share the prize. B needs fair entry windows/deep value; C needs optional lever. |
| Codebase engineer | 8.0 | 4.5 | 7.0 | A > C > B. A preserves the single-item lifecycle; C needs public-lever commitment/reset rules; B rewrites singleton cargo, clocks, raid targeting and refill. Require transactional purchases, map counters, capacity handling and durable shared Cave progression. |

Scores belong to original candidate packets, including A's proposed Lens. **Winner: A**, selected for steal-first clarity and preserving item/save structure, not numerical certainty. Accepted corrections: delete paid Survey Lens from first playable; keep all basic signs free; use existing S5-after-one-escape route variation; defer new modifiers/gear until baseline; explicitly remove physical Bump for pacifism. The revised A has not been rescored or played. B's push-your-luck and C's optional lever can be reconsidered only if observed repetition survives those simpler choices.

## Selected design: what a portal heist actually means

**Untimed approach → 2s crack → 60s treasure extraction → durable secure → home bank/open → earning crew → collect → upgrade → next portal.** The existing timer starts at completed Steal, not portal entry. This is a deliberate choice: planning remains possible and the clock has one clear cause. “Crack” uses the same hold, not a second minigame.

| State | Player sees / does | Authoritative rule — INFERRED integration contract |
|---|---|---|
| Home ready | Meadow free; Cave next cost and bank count; one objective | Validate profile availability, unlock, empty hands, collection room. Cosmetic arches cannot grant travel. |
| Approach | Free exit/treasure landmarks, route fork, optional unlocked bell | No clock until first completed Steal. One shared arena/map; frozen encounter definition. |
| Crack/carry | Seal flashes; Keeper reacts; “Escape • portal closes 0:60” | Mint item identity/outcome once; original 60s starts. Raid uses progress/eligible fork, not infinite alarm waves. |
| Drop/recover | Same visible treasure, settle/Grab, remaining timer | No refreshed clock/roll or paid reclaim; threats obey mercy and reachable drop rules. |
| Portal boundary | Cyan treasure aperture contracts; always full-width walking trigger | At server `now < deadline`, atomically lock SecurePending before yielding; `now >= deadline` expires. Visual shrink never shrinks the actual hit area or creates precision. |
| Saving | Protected “Saving treasure”; no attacks or successful reward yet | Hold same item through uncertainty; no refill/expiry/other winner. Preserve existing conservative reconciliation, do not invent a failure refund path. |
| Bank/home | Acknowledged secure returns at own gate; Place → Open → pet/name/real rate | Treasure banking is durable secure, home place/open realizes its earning pet. Collect is separate transfer of accrued Coins into spendable balance. Clearly distinguish both. |
| Upgrade/retry | Buy Feed I or permanent Cave access; return to portal | Persist debit/effect together, repeat requests grant once; reject insufficient Coins/busy profile. No provisional loot money. |

At zero the **treasure channel** closes and unresolved loot dissolves; a dim stable empty-handed return remains. Copy: “Treasure portal closed — return home.” Never strand players or claim every form of safe return disappeared. No forced death/evacuation cutscene. Refill after retirement uses the existing 3s baseline, not a forced long round. After resolution, restore cyan for the next item without an occupied geometry reset.

Late arrival during an existing carry sees “Loot moving • 0:SS” before entry and may choose the other map, return, race for a future nest or recover a drop; it does not start a fresh personal timer or steal a second item. No full heist opportunity is promised to a late entrant. If observation shows waiting/starvation, address refill/entry clarity first; do not silently add instancing or clone prizes.

Cave keeps its distinctive route: read walking vs cart path, crack the geode, outsmart the Cave Keeper's committed threat/one route-control fork, choose marked walking bypass or cart departure, see support fuse/cracks and gap, then reach the same kind of cyan extraction boundary. Blast is optional terrain spectacle with occupancy protection. It never targets a rival/keeper or forces every novice onto the jump. Surface raid logic can be adapted to an authored Cave junction; Meadow coordinates and tunnel controller cannot be copied blindly. Existing preview hooks do not count as an integrated Cave Keeper.

## Progression and repeat value — INFERRED proposals

Coins only. Earners come from banked loot; no pickup, alarm, trick, hit or mere participation Coins. No spending real money. Pets stay visible at home initially; pets do not attack or simulate a field crew.

| Stage | Cost / requirement | What changes for the next heist / status |
|---|---|---|
| Meadow starter | Free | First earned pet guaranteed current Common Pup; rate 1/s, not invented free cash. Existing 70/25/5 weights retained initially. |
| Feed I | 120 collected Coins, once | First pet +1/s; income compounds while player is away heisting and funds next map sooner. Reuse `feed` intent, add real purchase. 120/1=120s incremental payback arithmetic; acquisition time is additional. |
| Bell planning | Existing three durable Meadow escapes; remains free | Existing one-charge pre-steal planning/immunity. Do not sell an extra charge or alter arm/tell/effect limits. |
| Crystal Cave / map 2 | 600 collected Coins + three durable Meadow banks | Permanent destination, geode/cart/blast route and distinct earners. Proposed floor 6/s, Rare 12/s, Epic 24/s at initial 70/25/5 weights; outcomes must carry map identity. Rates are GDD proposals, not present Cave output. |
| Optional later gear | Price UNKNOWN; coin-only after baseline review | Candidate Survey Kit previews optional route cards before entry; all exit/hazard/recovery signs stay free. Candidate crew role is a cosmetic home lookout tied to discovery, no autonomous loot. Neither is required in the first playable; reject if it adds menus without a new choice. |
| Frost / possible map 3 | Proposed 3,000 Coins + three durable Cave banks | One distinct optional ice-route decision with ordinary walking bypass; conceptual earning floor 26/s from GDD. No map-three construction in this milestone. Keep its gate unavailable until a real map exists. |

Cave-floor replacement of Meadow-floor pet increases income by 5/s: 600/5=120s modeled incremental payback after acquisition, not measured pacing. At eight existing pets, today's implementation blocks entry; do not label that a complete collection loop. Before acceptance of sustained play, add a small explicit archive/active split: retain owned pets, at most eight earning, permit owner to archive one for an arriving pet; reserve collection capacity before entry. Proposed collection limit 64 is inherited design, not checked implementation. Protect first/feed pet; never auto-delete/sell. This is shared economy work, not a map lane patch.

First five minutes target two or more completed loops and an affordable first buy, but actual trip/earner times UNKNOWN. Show purchase affordability using spendable Coins and separate “collect X” at gate. Cave may take longer than five minutes; do not grant debug money or lower the timer to fake pacing. Active play adds new earners/new routes; idle only accrues existing bank. Log added earning rate from heists versus idle accrual; do not claim active 2–3x idle or retention improvements without data. No offline-income system, daily rewards, heat meter or event clock is needed to prove this loop.

## Numbered plan to FIRST PLAYABLE — future work only

Every step is INFERRED, NOT STARTED by this task. No step authorizes building now, opening Studio Play, launching a client or publishing. The ordered gates define evidence required later; under today's no-launch instruction, live acceptance remains UNKNOWN.

1. **Shared owner: freeze contracts and baseline.** Record dirty source state, canonical Meadow/Cave inputs and existing failed/obsolete tests without running builders. Define `mapId`, mounted transform, portal/nest/safe bounds, legal route/drop graph, reward table, encounter config and cleanup interface. Set one shared home/8-player server; no TeleportService/multi-place deployment needed for this design. Freeze definitions/version before map lanes begin.
2. **Shared owner: extract map-aware runtime.** Replace Greybox's singleton arena/rules references with map contexts routed by server-validated membership. One active item/map and one carry/player. Entry/Return, hold validation, hit/mercy, drops, deadline and trap cleanup resolve the actor's map. One coordinator and global actor budget prevents two maps multiplying threats without limit; retain existing raid limits and complete client warning. No map may call Domain directly to award loot.
3. **Shared owner: unify profiles/outcomes and migration.** Extend pending/pet records with map/reward identity and per-map durable bank counters; retain legacy item IDs, rates, feed flag and total escapes. Map old known Meadow records to Meadow; malformed/ambiguous records refuse safely instead of guessed currency. Fix `Service.load` total-to-Meadow mapping. Rate/open/reveal/restoration use stored outcome/map, not whichever global table loaded last. Keep ProfileStore single session and save acknowledgment/reconciliation. Retire Cave RAM awarding and beacon opening in the combined runtime; retain old prototype source as history.
4. **Shared owner: implement the bank → buy → retry spine.** Preserve current home Place/Open/skip/collect; add atomic Feed I and permanent Cave unlock with clear refusal/duplicate handling. Add collection reservation/archive behavior so the ninth earned item does not end the game or disappear. Bind real home portal selectors to unlock/progress; HomeArt is presentation only. Remove server/client Bump and attack/Sticky affordances from the proposed pacifist runtime. Add one-clock portal cues without changing trigger width, mercy or 60s start.
5. **Lane M only: make one Meadow heist adapter and proof package.** Reuse current geometry/routes, Keeper, wall-bait, bell and S2/S5 raid. Declare map definition through the frozen interface; retain safe apron/walking bypasses. Provide source-level route/drop/cargo/portal scenarios and one storyboard of crack → bait → commanded gap → secure → pet → Feed → re-entry. Do not generate a place or claim the storyboard proves fun. This is the first representative moment for Zion/Claude design review.
6. **Gate: Zion checks the one Meadow design slice before multiplying.** Compare planned corresponding beats side by side with the local Egg study's wake/run/safe-line and Brainrot's earner/collect. Select readable portal, bank and next-buy wording. Actual phone clip, novice understanding and fun remain UNKNOWN until separately authorized observation; no Studio Play route is proposed. Resolve a failed bait/route explanation before expanding mechanics.
7. **Two map lanes may run in parallel after steps 1–4 and the Meadow slice gate.** **M** finishes Meadow mapping/cues and route variants; **C** adapts existing Crystal Cave layout, geode, authored Keeper/one route-control fork, walking route, cart boarding/switch/blast/recovery to the exact same interface. Both deliver namespaced source and offline scenario fixtures, no combined place. Cave lane connects cart cargo views to canonical item ID/deadline; expiry/return/drop/reset/disconnect detach riders/FX safely and cannot re-award. No new Cave combat/ram/explosion damage, no additional required minigame.
8. **Shared owner: integrate serially, Meadow then Cave.** Register adapters and mounted transforms, attach portal selection/travel, reward rendering and home return. Remove duplicate Cave player-load/heartbeat/award path from the combined assembly so two loops cannot claim one cargo. Check actual combined input namespace, map bounds, source mappings, old HomeArt labels and lifecycle unload. Only this owner touches project mappings, shared UI, core and final assembly/build scripts. Future builds require separate authorization; this task makes none.
9. **Offline acceptance plan, before any live acceptance claim.** Use pure domain/adapter fixtures for duplicate secure/open/collect/buy; simultaneous same-item grabs; exact deadline tie; shared-save uncertainty; source-map counters/rates; old profile migration; ninth-item reservation/archive; invalid/unlocked portal; cross-map requests; late join; reset/disconnect; concurrent Meadow/Cave save operations. Retain meaningful Loop/drop/tunnel/ravine/raid/cart tests, explicitly revise Bump expectations for the accepted future pacifist change. Never rebrand obsolete failures as passes. Existing CoreLoopTest's Studio-store path must not run; use an isolated offline mock runner instead.
10. **Future observed acceptance, only after a separate owner lift of no-launch restriction.** No Studio Play ever. Use an owner-authorized real-client/private test route only if one is available without unapproved publication; otherwise remain UNKNOWN. Observe solo novice, skilled route, two rivals and eight clients split across maps. From ordinary Coins: Meadow crack/escape/bank/open/collect/Feed/re-enter → unlock Cave → Cave crack/Keep­er/cart-or-walk/escape → same home bank/open/collect → next portal. Record each player's first secure/earner/buy, failures, waiting, route choice, tells actually seen and device readability. Choose actual phone/performance budget with owner; none measured here. This gate is not launch permission.
11. **Declare FIRST PLAYABLE only with end-to-end evidence.** Both maps playable from one home, identical cargo/save guarantees, actual reward difference, persisted purchase/unlock/rejoin, clear next trip and no attacks. Report static/offline, real-client, persistence, phone, fun and Zion acceptance separately. If live tests remain prohibited, deliver implementation evidence later as unaccepted work; do not call it a proven playable game. Map three, monetization and release stay outside this milestone.

### File ownership — prevent collisions

These new adapter paths are **proposed**, not present files or work performed today. Parallel lanes are feasible only after the shared extraction; editing today's singleton Greybox in two lanes is not safe.

| Owner | Exclusive future write scope | Must not touch |
|---|---|---|
| Shared coordinator, serial | `slice-v2/prototype/Greybox.server.luau`, `Greybox.client.luau`, `GreyboxConfig.luau`, `LootRules.luau`, `Arena.luau`, `Scene.luau`, HomeArt; `prototype/core/*`; proposed `prototype/heist/shared/*`; project JSON, mounting/build/assembly scripts and combined manifests | No concurrent shared patches from either map lane. S9/S10 home content remains here even though its folder says meadow-v4. |
| Lane M — Meadow | Proposed `prototype/heist/maps/Meadow/*`, `treasure/heist-evidence/meadow/*`; if needed specifically assigned `prototype/meadow-v4/Gameplay.luau`, Outsmart/RaidSlice and S1–S8 map-only changes | Core, Greybox/Scene/HomeArt, S9/S10, Cave, shared raid contract, project/build outputs. Shared changes requested as a handoff note. |
| Lane C — Crystal Cave | Proposed `prototype/heist/maps/CrystalCave/*`, `treasure/heist-evidence/cave/*`; assigned Cave Loop/Cart/Policy/route modules and C1–C8 content only | Shared core/UI, Meadow, HomeArt, `prototype/cave-v2/build.luau`, project JSON or any complete `.rbxl` output. Replace volatile awarding only through coordinator-approved adapter contract. |

Use isolated branches/worktrees if later available; exclusive paths still govern even in one shared directory. A shared file change pauses dependent lane work until coordinator lands a revised contract; lanes then update their own adapters. No two lanes regenerate the same place, manifest, registry, home UI or build output. Merge order: shared contract → Meadow proof → shared fixes → parallel map adapters → serial integration → offline checks → separately authorized observation. Two map lanes do not remove the single shared-systems critical path.

## Cut list and unresolved risks

- **Keep:** Keeper as the opponent; raid as a commanded route decision; bell/bait as Outsmart; Cave cart/blast as getaway spectacle; earning pets and real collect; approved art and identity-safe cargo.
- **Cut from first playable:** required levers/keys, multiple simultaneous caches, purchased navigation Lens, heat/crew meters, mandatory party, combat/Bump/Sticky, army expansion, procedural chunks, forced camera takes, third-map construction, shops for real money and launch tasks. Preserve historical code/assets; cut means exclude from the proposed runtime.
- **UNKNOWN:** whether any full current loop is enjoyable; route times on these large maps; phone/server budget with two islands; durable saves on a real service; no-attack rivalry satisfaction; helper reward frustration; eight fresh novices competing for one item. Independent live Claude review and Zion acceptance remain pending. No imagined data resolves these.
- Simplify based on failure: if first reward is late, shorten mandatory travel; if two maps duplicate maintenance, fix shared adapter boundary; if a paid gear idea adds no new route choice, delete it; if raid/cart overwhelms first entry, keep optional bypass and introduce the extra choice after first successful bank. Never manufacture tension by shrinking warning windows or trapping players after expiry.

## Lessons

1. When several maps already exist, inspect their award/travel paths before calling the game playable, because a volatile second prototype is not a shared progression loop.
2. When a closing portal is the fantasy, attach its one clock to an explicit player action and preserve item identity, because a second timer or refreshed handoff makes failure hard to understand.
3. When using two map lanes, extract shared state first and assign exact files, because two cosmetic-map tasks otherwise collide in the singleton runtime and home economy.
