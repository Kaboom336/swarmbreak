# Guardian island v2 — climb, dodge, steal

2026-10-12. **Decision: replace the flat solo path with one shared, hilly guardian arena.** Pitch: “Steal the LOOT, dodge flying rocks, outrun your friends home.” Evergreen; working game title remains provisional. The carried object is **LOOT** throughout this design.

## Authority and evidence

- **OWNER-REPORTED:** current flat path rejected; more to see/jump on, simple parkour, small climbable hills while carrying, guardian throws, versatile terrain for players fighting over LOOT. Shared competition for 4–8 entrants is the requested scope.
- **CHECKED:** all of SLICE-V2.md including both bottom TikTok sections; ISLAND-PIECES.md; all eight v7 PNGs and CONCEPTS-V7.md; prototype/T1-greybox.md; GreyboxConfig.luau and Layout.luau; supplied TikTok delta and Hit Game Bible; local PLAYBOOK.md and Roblox production skill/gates; official Humanoid jump documentation.
- **PROPOSED:** every size, timing, control, tier and rule below. **UNKNOWN:** Studio feel, actual reachability, pacing, mobile performance and owner acceptance. Existing T1 reports full-loop runtime NOT RUN; v7 images are concepts, not gameplay evidence.
- Exact Keystone “Roblox Process Playbook” remains unavailable: no matching local copy/connector found. Local PLAYBOOK.md is a separate source. Apply supplied real-art, core-greybox and named-reference comparison rules.
- This document supersedes the island-only assumptions of solo slots, 96×144 envelope, level floors, linear 3–5-piece route, no jumps/PvP, retained LOOT on every catch, and ownership committed at nest pickup. Other source files remain historical until a later authorized implementation reconciles them.
- Reuse existing portal/hold/fallback controls, pen placement, guardian silhouette, cover/bridge construction and seeded-template approach. Inspected T1 config/layout before proposing replacement topology; no external kit, code or art imported, so no new licence dependency. Approved home/pet assets remain references; LOOT identity/mesh is unresolved.

## 1. Island concept: Keeper's Knolls

One roughly **144×144-stud** island (acceptable envelope **120–160 across**), continuous grassy ground with shallow gullies and a chunky rock underside. **One guardian, one contested LOOT at a time.** Target four entrants; support eight; start immediately with one. Friends use the same island/difficulty, not private copies.

Use surface Y=0, +Z north. Fixed south entry/return pad centred `(0,0,-58)`, **32×24**; camp centred `(0,0,32)`, **40×40**, nest on a **4-high** terrace with ramps. The nest's large banner/tree silhouette and cyan return arch are visible above cover. No second reward or alternate exit.

| Area / route | Proposed geometry | What happens there |
|---|---|---|
| Centre / quick route | Clear width **16–20**; pad-to-nest walked route **90–105**; staggered **6–8-high**, **8×12** rock cover | Fast approach; guardian has clear throwing windows; rivals can intercept at cover corners. |
| West / ridge route | Hill at `(-40,0,12)`, **40×40**, summit **10**; two **12-wide** switchback ramps, slope ≤**25°**; route **110–125** | Carry LOOT uphill, see rivals below, choose the opposite descent; summit is exposed to throws. |
| East / grove route | Hill at `(40,0,12)`, **40×40**, summit **8**; same two-ramp access; route **115–130** through cover/log | Break guardian sight, hide, flank the quick route; rivals can wait at either grove exit. |
| Optional south knoll | **32×32**, summit **6**, off the centre sightline; two **12-wide** ramps | A third climbing choice on later recipes; never blocks entry's view of the camp. |
| Cross-links | **12–16-wide** paths joining ridge↔centre↔grove at two positions outside the pad | Split, change route mid-chase, ambush; routes reconnect before the safe boundary. |
| Jump shortcuts | **4–8** edge-to-edge gaps; **2–4-high** ledges; **8×8** stepping-stone tops; **12×12** landing areas | Two or three obvious jumps cut a bend; miss into a **3–4-deep** recovery gully with a ramp, not a death pit. |

These are route budgets to measure after socket placement, not distances derived from the concept pictures. Island 1 uses two hills, **4–6** gaps and **2–3** ledges; **8** gaps/**4** ledges are optional later variants. Every nest/exit remains reachable by walking while carrying. Both sides of each hill have usable ramps; no ladder, wall-run, slide, stamina, precision beam or advanced movement lesson.

**Jump contract:** Roblox defaults are **JumpHeight=7.2 studs** in height mode, **JumpPower=50** in power mode, with UseJumpPower defaulting true; these are different settings, not interchangeable units. Gravity affects power-mode height. [Official Humanoid API source](https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/reference/engine/classes/Humanoid.yaml).
For reproducible T1 tests, explicitly propose height mode: unladen **7.2**, carrying **6.0**, walk/carry speed **16/15**. Start Island 1 without the carrying height reduction; enable 6.0 only after the same routes pass. Do not tune required jumps at the apex limit. Actual clearance/reach with the live avatar, cargo grip and touch input must be measured; gap width alone cannot prove a jump.

Cover means actual sight/impact obstruction: rocks stop a projectile that collides with them; a low bush hides a player only through the hide state. A high arc can clear low rocks but never pass through solid geometry. Make the distinction readable with tall rock alcoves versus low shrubs. No hide socket immediately beside the portal or nest.

**Hide:** one two-ended crawl-log (**16×8**, interior clearance ≥**7 high×6 wide**) and one or two **12×12** bush pockets. Walk into the marked pocket and stop **0.5 s** to show HIDDEN; moving/jumping leaves it. Use the ordinary action control to leave the log if needed, with a large touch hint. Avatar/cargo clearance beats literal low crawl geometry; crawl is a pose, not a new collision size.
Guardian loses sight, walks to last seen point, sniffs with “?” for **2 s**, then patrols. Hiding stops guardian targeting, not already airborne rocks or rival steals; it is not invulnerability. One occupant per pocket, two exits, no body blocking. Carrying concealment lasts at most **5 s**, then LOOT glows and guardian can investigate the opening; **3 s** before re-hiding. Log hide sockets sit within **4 studs** of an opening reachable by the guardian; a crouched, **1.2 s**-warned poke from that opening uses the normal close-range hit/mercy rules and must have clear sight, never hit through timber. Nearby rivals see the glow; never reveal the carrier to the whole server through all cover.

**TikTok reason:** the carrier rises above a hill, leaps down a shortcut as a red disc fills behind them, and a rival cuts across below. Height exposes the chase in a 9:16 crop; arcing throws provide anticipation; failed jumps land in funny recoverable scrambles. Three proposed clip beats: ridge jump→rock near-miss; log hide→guardian “?”→rival at opposite exit; Bump→LOOT bounce→pickup→cyan safety.
Keep carrier, nearby pursuer and next landing in the centre third of the landscape camera for vertical cropping; full-island overview is for layout QA only. Bold “!” / RUN! / HIDDEN / LOOT DROPPED share one objective-banner slot, with steal/impact/escape sound stingers. Landing dust and a small squash are bounded; no cutscene or camera lock during competition. Clips must remain readable muted. No replay system in T1.

## 2. Guardian kit and island tiers

Reuse the **11-stud Meadow Keeper** silhouette from v7 as a modelling reference; add an obvious raised throwing arm and chunky rock/acorn. Evergreen grass, wood, cream and cyan daylight; Halloween/winter dress visual sockets without changing collision, routes or red-disc contrast.

1. **Patrol:** walk camp and two route junctions using authored ground/ramp waypoints. Detect visible entrants in **24 studs**; start the warn beat on detection or completed nest steal. No omniscient tracking through hills/logs.
2. **Warn:** turn to target, big amber “!”, raised arm, **1.2 s** tell. Nest pickup grants **1.2 s** head start before pursuit; finish the warn/head-start together, not two surprise stacked delays. Pickup mercy below still applies.
3. **Chase:** favour a visible carrier; otherwise nearest visible entrant. Keep target for ≥**2 s** unless it hides/exits/becomes invalid; only one target and one attack windup at once. Follow walkable ramps, never teleport up a hill or cut through gullies/cover. Search last seen spot after sight loss; return to patrol after **3 s** without reacquisition.
4. **Throw:** at **12–36-stud** range, plant feet and visibly lob one rock/acorn in an arc. Place an outlined **8-stud-diameter red ground disc** on the actual reachable surface, with a filling ring. Lock impact point at telegraph start; no last-frame homing. Total disc→impact **0.8–1.2 s** includes flight; Island 1 always **1.2 s**. No unseen splash through floors/cover; a rock hitting cover bursts there and cancels the marked landing.
5. **Impact:** one **0.6 s** stumble and bounded **3–4-stud** horizontal knockback; no ragdoll/HP/death. Each affected player can be hit at most once per throw, no lingering hazard. A vulnerable carrier drops the same LOOT onto a validated nearby floor socket. Proximity catch at **3.5 studs** (hide-opening poke ≤4) uses the same stumble/drop/mercy, with a visible close-range tell and no simultaneous throw.

**Mercy is shared across guardian/PvP:** **3 s** after nest/pickup or any valid hit; blue pulse, no further knockback/drop and no hostile hold completion. Guardian avoids players with this shared 3 s impact mercy; the FIRST RUN shield below protects against PvP only. An old airborne impact cannot bypass mercy. First guardian hit of a player's first successful-escape attempt only stumbles and retains LOOT; later vulnerable hits drop it. First-attempt mercy use survives reset/re-entry so it cannot be farmed. Dropped LOOT never despawns because of a hit.

| Island difficulty | Geometry / chase speed relative to starter carry speed | Throws / mercy |
|---|---|---|
| **Island 1 Easy; default** | Two 8/10-high hills; optional 4–6 gaps, 2–3 ledges; chase **0.88×** | One throw, **1.2 s** disc; ≥**4 s** between windup starts; 3 s mercy, first-hit retention. |
| **Island 1 Standard; after 3 escapes, voluntary** | Same walkable routes; optional 8 gap/4 ledge variant; chase **0.92×** | One throw, **1.0 s** disc; ≥**3.5 s** between starts; same mercy. |
| **Future Island 2+; design only** | Three hills up to **14 high**, ramps; chase **0.98×** | One throw, **0.8–1.0 s** disc; ≥**3 s** between starts; retain 3 s mercy. No surprise multi-shot. |

All speed ratios use the configured starter carry speed for that tier, not the fastest upgraded player. Shared difficulty is frozen for the arena; entering players cannot change it mid-chase. Island 2 remains preview-only under the slice; this table does not authorize its build/reward tuning. Add complexity through terrain first, not more enemy types.

## 3. Competition, handoffs and solo play

**Choose deliberate Bump, not accidental contact or instant carrier theft.** Reuse the existing contextual hold button: nest “Steal” **1 s**; vulnerable carrier “Bump” **0.4 s**; dropped LOOT “Grab” **0.4 s**. Clear label/key/controller/touch hint; no weapon/tool hotbar or new persistent HUD button. Carrier can escape the short hold by moving out of range or behind cover.

- Bump requires empty hands, same active arena, **≤4 studs** root-to-root range, line of sight and ≤**3-stud** vertical separation throughout the hold. Completion does one short stumble/knockback and drops LOOT; it never directly grants it to the attacker. **2 s** attacker cooldown from every attempt, including cancelled attempts; ordinary player collisions never deal hits.
- LOOT rests on the closest valid floor socket within **6 studs** of the carrier, with a small visible bounce; do not let physical rolling carry it into void/under scenery. Nobody can Grab during its **0.6 s** settle beat; then anyone, including the former carrier, may begin a fresh **0.4 s** Grab hold. No exclusive reclaim or pre-charging; the server accepts one winner. Ground Grab range **≤4 studs** with clear sight. Mercy blocks attacks, not legal ground Grabs.
- Server owns holds, cooldowns, target, mercy, item ID and transitions: **Nest→Carried(A)→Dropped→Carried(B)→Secured(B)**. Simultaneous nest/ground holds have one atomic winner; everyone else gets “Taken.” One LOOT exists in exactly one state, one player carries at most one, no client-supplied reward or victim ownership claim.
- **Ownership commits at safe return**, not first pickup. Arena LOOT is provisional: reset/disconnect while carrying drops it at the last legal socket for remaining players; leaving never escrows it home. With no occupants, retire the abandoned arena/item without an award. Falling into a gully keeps it; falling outside the island recovers player to pad and drops LOOT on their last valid danger-area socket.
- Crossing the outer cyan safe boundary (including the apron below) automatically invokes validated return and atomically secures the carried LOOT to that player, then transfers them home; no safe camping with provisional LOOT. Existing post-escape recovery/save rules apply to secured LOOT only; it cannot be stolen from home/pens. Freeze base reward roll/event eligibility timestamp at first nest pickup; handoffs never reroll. At secure return finalize the eligible winner's first-Pup override once, retaining item ID/event timestamp, then save that resolved outcome. Temporary holders get no reward/consumed first-Pup guarantee.
- After secured return, replace nest LOOT with a new ID after **3 s** and resume patrol; entrants already inside can compete again. Freeze geometry while anyone remains; do not reshuffle beneath an active chase, dropped item or late joiner. No forced match countdown. Players without LOOT may return home freely.

**Anti-grief:** players do not physically block one another; Bump targets carriers only. No attacks through cover, against hidden geometry you cannot see, in the safe pad or within its **8-stud apron**. The apron is part of the validated return boundary, marked cyan; entering it with LOOT secures/returns immediately. Provide three ≥**12-wide** approaches to it. Already flying rocks cannot hit inside the protected area; reject discs overlapping it.
First nest pickup grants a visible FIRST RUN shield against PvP for **12 s or until secure escape**, whichever comes first; shielded players cannot Bump others. Activate it once per player, recorded across reset/re-entry, never on every Grab. Afterward use normal 3 s mercy. This gives a beginner a direct escape window without indefinite control of the only LOOT. Guardian still threatens them under easy/first-hit mercy; nearby rivals see the shield before trying a hold.
Every valid hit/pickup grants the shared 3 s mercy, preventing group stun chains. A carrier idle outside combat for **10 s** drops the same LOOT after a **2 s** warning; reclaim requires a new Grab input, so AFK hoarding cannot keep it. No revenge bonus, Candy for hits, forced item expiry, kill credit or repeated victim farm. A rival may secure lost provisional LOOT; this intentionally departs from the Bible's zero-loss/player-stealing-later defaults. Explain once: “LOOT is yours when you escape.” The shield replaces an extra combat tutorial.

**If alone:** enter immediately, choose any route, hold at camp, climb/jump/hide from the same guardian and escape. Hide/search and throw near-misses remain the entertaining loop. No fake players, minimum population, uncontested reward multiplier or different maze. A solo drop can be reclaimed; guardian does not collect/destroy it. A late join joins the same frozen arena on the safe pad with arrival mercy, sees carrier/dropped state and cannot trigger a reset.
**Pacing hypotheses:** uncontested portal→portal **20–45 s**; measure contested trips separately, including unsuccessful attempts. Keep fresh first pickup **<30 s**, first secure escape separately reported, and first earner **<120 s** in future full economy tests. Shared contention invalidates the old solo timing arithmetic; do not report temporary pickup as an irrevocably owned reward. Full pen blocks entry before participation, as in the slice.

## 4. Hand-made chunks and safe shuffling

Author shapes once in Studio; reuse native wedge/rock/bridge collision methods, then fit real visual shells. **12 designs**, not 12 required instances or final-art commissions. Use **8–10 chunks** plus authored joining paths on one base; expand the pool only after one good island. No generated terrain/noise, loose obstacle scattering or shuffled terminals.

Table sizes are footprint X×Z; ground/base thickness **4**, top heights relative to local Y=0. Ports N/S/E/W sit at the corresponding edge midpoint, face outward and are **12 wide at Y=0** unless stated; all ports are bidirectional. Match positions/heights/opposed normals. Hill/camp elevation is internal, reached by authored ramps. Cap unused ports with a safe authored boundary, never an invisible wall on a route.

| ID / chunk | Footprint; top heights | Connectors | Adds |
|---|---|---|---|
| I01 EntryReturn | **32×24**; 0 | N/E/W; portal inside south half | Fixed cyan safe pad, three independent approach paths, arrival spacing. Adapt P01. |
| I02 GuardianCamp | **40×40**; terrace 4, banner/tree 18 | S/E/W, ramps to terrace | Fixed one nest/guardian, three approach angles, open throwing lane. Adapt P07; no terminal dead end. |
| I03 RoundHill | **40×40**; summit 8 | N/S/E/W | Two opposite 12-wide ramp ascents plus ground bypass; carrier overlook. |
| I04 SplitHill | **40×40**; summit 10 | N/S/E/W | Two switchback ascents, two summit exits, ambush pocket below; no safe perch. |
| I05 SmallKnoll | **32×32**; summit 6 | N/S/E/W | Optional third mound with two ramps; short crest chase. |
| I06 SteppingStones | **32×24**; tops 1–3, recovery floor -3 | N/S/E/W | Three 8×8 stones, gaps 4/6; two-jump shortcut and 12-wide walk-around. |
| I07 BrokenLedge | **32×24**; tops 2/4, recovery -4 | N/S; E bypass | Two low ledges and 6 gap; optional 8-gap later variant; 12×12 landings. |
| I08 CoverCourt | **32×32**; rock tops 6–8 | N/S/E/W | Two offset rocks, 12-wide passages, intercept/cutback choice. Adapt P02/P05. |
| I09 CrawlLogGrove | **32×24**; log exterior 9, foliage 10 | N/S/E/W | Two-ended 16×8 log, one hide socket, visible exits; guardian sniff gag. |
| I10 BushAlcoves | **32×24**; bushes 5, rear rock 8 | N/S/E/W | Two 12×12 pockets with separate exits; rival sneak/guardian sight break. |
| I11 TwinBridge | **32×32**; decks 2, gully -3 | N/S/E/W | Two 12-wide decks with ≥10 separation and ground ramp bypass; cross-route feints. Adapt P06. |
| I12 RidgeLink | **32×24**; crest 6 | W/E; N/S ground | Two ramps and 12-wide crest; joins routes without an 8-stud blind drop. |

**Assembly rules:**
1. Pick a hand-authored socket recipe within the 144×144 envelope; keep I01 south/I02 north. Two hill sockets choose I03/I04; later recipe adds I05. Centre/side sockets choose size-compatible cover, jump or grove variants; quarter-turn only when ports/ramps/visibility fit. Joins use authored lengths, never stretch jump gaps to make sockets meet.
2. Recipe must have three pad↔camp routes, two cross-links and no compulsory jump. At least two routes stay separate until the protected apron; no single bridge choke. Preserve centre view of nest landmark; hill silhouette/portal remains legible from each decision point.
3. Require two climbable hills, one optional jump set, one hard-cover court and one log/bush hide chunk. Later optional third hill; never put both hide chunks together or all rocks between nest and portal. Exactly one nest, guardian and safe boundary; no spawn within attack range of danger.
4. Validate footprints/joins, path widths, carrier clearances, actual 3D route lengths, jump landing/recovery volumes, safe apron and protected-disc exclusion. Guardian has walkable routes to all summits; no immortal perch. Every hide/jump route reconnects, every gully has two exits. Reject overlapping chunks/cover, unreachable dropped-item sockets or accidental high ledges at joins.
5. Deterministic session seed + arena ID + island/tier + recipe version; reward RNG separate. Retry at most **8** recipes, then use the verified fixed easy recipe. Log rejection reason. Shuffle only once all occupants and provisional LOOT are resolved; never claim per-player reshuffling for shared geometry.
6. First T1 builds one fixed two-hill recipe, not the entire pool. Next verify **50** seeded assemblies statically and walk **10** distinct recipes in both directions while carrying; the numbers are test targets, not completed checks.

## 5. T1 changes and full-loop gate — FUTURE tasks only

- [ ] Replace isolated slots/linear Layout contract with one shared arena ID, membership/capacity, multi-route socket graph and frozen difficulty/seed. Keep home/pen destination per player. Use known fixed recipe before seeded variation.
- [ ] Greybox the 144×144 base, two hills, camp ramps, three routes/two cross-links, one jump set/recovery gully, rock cover, log hide, three pad approaches and protected apron. Plain parts test physics only; fit approved real art after core validation.
- [ ] Implement/verify explicit jump mode and cargo clearance; start carrying at 7.2 height, then test 6.0. Add guardian warn/search/arc/disc, collision interception, drop sockets and shared mercy.
- [ ] Adapt existing hold/fallback action selection for Bump/Grab/hide exit; add authoritative contested item transitions and atomic safe return. Replace pre-escape cargo escrow assumptions; preserve secured recovery/pen placement.
- [ ] Upgrade LoopTest from the old level-floor MoveTo route to typed **Walk / Jump / ClimbRamp / Hide / Dodge / Hold / Handoff** steps using actual characters and normal actions. Explicit Jump requests plus takeoff/landing evidence; never teleport across an obstacle or fake a hit to pass.
- [ ] Preserve the owner-play lock. Require new solo **and two-client** complete-loop passes in fresh Studio Play sessions, plus manual touch/control/clip checks, before one owner-play island is delivered. Old scalar PASS cannot unlock this new topology.

| Full-loop addition | Required observed evidence / fail condition |
|---|---|
| Solo end-to-end | Home→shared pad→nest hold→LOOT→return→own pen; one real object; duplicate hold/return/place rejected. Chase actually moves and at least one normal throw occurs. No runtime result claimed here. |
| Jump | Actual takeoff/landing across 4 and 6 gaps while carrying; optional 8 later; 2–4 ledges; deliberately miss once, recover via ramp with same item. Repeat at each enabled carry height; keyboard/controller/touch, auto-jump on/off. |
| Climb | Carry up both hills and down opposite ramps; move through cross-link while NPC follows valid ground path. Fail on stranded character, unreachably perched carrier or cargo clipping that blocks steering. |
| Throw dodge/hit | Evade a naturally targeted locked disc by moving; stationary vulnerable carrier receives one hit/drop; tall-cover interception works. Observe first-hit retention and 3 s cross-source mercy; airborne rocks/splash never hit safe apron. |
| PvP steal | Use players whose one-time shield is consumed/expired: A takes nest LOOT; B completes Bump→drop, waits shared settle, genuinely wins Grab using normal input; A can chase/reclaim; eventual winner secures/places exactly one. Cancel hold by range/cover; simultaneous Grabs and guardian-hit+Bump yield one state transition. |
| Hide | Enter/leave with cargo; guardian loses sight, searches/sniffs; concealment expires and opening poke can reach a stationary holder with real clear sight. Rival can Bump after mercy; airborne rock obeys collision. Both exits work; occupied hide cannot trap/block another player. |
| Lifecycle / load | 1/2/4/8 clients; late join during carry/drop; leave/reset/fall/full pen; repeated failed attacks; eight players at return. Check shield expiry/one-time use, idle drop, automatic apron return, transferred first-Pup outcome/event timestamp. No duplicate reward, pre-escape escrow, geometry reset, safe camping or lost ground LOOT. |
| Pacing / phone clip | Record each fresh pickup, secure escape, trip and failed attempt; later first actual income tick. Capture ridge near-miss, hide/search and handoff in 9:16 crop, muted and with audio. Clear LOOT/guardian/disc/next landing; real baseline-phone performance UNKNOWN until measured. |

## Comparison, review and lessons

| Named supplied reference / standard | What the v7 flat route does | V2 comparison goal / delete if worse |
|---|---|---|
| **Steal an Egg** — primary guarded pickup/return anchor | Clear nest hold and reverse escape, little route choice | Preserve that clarity with one LOOT/portal; add hill cutbacks. Delete a branch if it hides the objective or turns a quick trip into wandering. |
| **Steal and Hide**, TikTok delta #15 — hide/chase anchor | “!” and escape feedback; no usable hide terrain | Match readable log→HIDDEN→“?” search beat; add rival exit ambush. Delete hide sockets that become safe camping holes. |
| **Catastrophic Horse Racing**, #4/5 — hazard readability | Guardian approach; no airborne anticipation | Compare red-disc→impact and near-miss in matched phone crop. Simplify throws if rocks/discs overlap or cannot be read muted. |

These are supplied offline observations/design comparisons, not current popularity rankings or a played arena pass. BGSI portal legibility and PS99 reward finish remain downstream reference bars. V7 daylight, chunky Keeper and cyan portal work as visual anchors; its level strip, single bridge choke and pumpkin-shaped LOOT cues need replacement.
Independent document critic checked this proposal against slice/T1: fixed indefinite first-run shield, uncommitted safe-apron camping, former-carrier reclaim advantage and ambiguous first-Pup finalization; added bounded concealment/reachable hide poke. This is a rules audit, not runtime evidence. Next have a fresh critic compare matched route/throw/hide frames side by side with supplied references, then Zion checks **one** complete island before more recipes/final art. This document is planning, not implementation authorization or fun/arena approval.
Lessons: When players contest one item, commit ownership at safety because handoffs must conserve it. When cargo changes jumping, test the worst carrying settings because visual gaps do not prove clearance. When height offers escape choices, provide two descents and guardian ramps because a summit must not become permanent safety.
