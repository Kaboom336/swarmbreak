# Island Raid: you vs the Guardian and its army

Recommend D: steal immediately, then outsmart a Guardian commanding small runner squads across linked districts.
First build proposal: one Meadow S2 encounter, one Sprout Runner type, one Jump-confirmed low vault; keep a walking bypass.
Zion judges that slice before a larger island, more minions or another movement move. Design only; nothing implemented.

2026-10-17 · All new designs, budgets, costs, scores and predicted outcomes are **INFERRED**, not measured.

## Owner brief and evidence

**OWNER-REPORTED, verbatim (Zion, 2026-10-17):**
> "the game doesn't seem hard enough and maybe we should make it more movement based with a larger map and a guardian that can spawn an army to its like an island raid player vs guardian and its army."
>
> "u can arena that idea"

**CHECKED:** [earlier arena](PACIFIST-ARENA.md), [GDD](GDD.md), [roadmap](ROADMAP-TO-LAUNCH.md), [cinematic movement](CINEMATIC-MOVE.md), [Meadow sections](sections/SECTIONS.md), [Cave sections](cave-sections/SECTIONS.md), both currently present `hermes/*.md` files ([REFS](hermes/REFS.md), [CONTENT](hermes/CONTENT.md)); source modules linked below. Additional context: [current handoff](../HANDOFF-NOW.md), existing test filenames and dependency licence ledger. Source inspection only; no suites, Studio, footage review or device tests performed for this arena.

| Evidence | What it establishes / limit |
|---|---|
| [GreyboxConfig](../slice-v2/prototype/GreyboxConfig.luau) | Steal **2s**, escape **60s**, capacity **8**, walk **16**, carry **13.5**, jump height **7.2**; first-hit retention **false**. MeadowV4 branch is **352×352**; default legacy IslandSize160 is not the v4 footprint. |
| [Gameplay](../prototype/meadow-v4/Gameplay.luau) | Routes derive from Fix2Routes/RouteData; nest, return, PvP routes and reachable drop sampling are coordinated. Bigger geometry requires matching navigation and drop updates. |
| [KeeperAttacks](../slice-v2/prototype/KeeperAttacks.luau) | Fan, lob, slam and locked straight dash; swept collision, legal-floor/safety checks, cover wall-stun and repeated-corner protection. Current dash tell **0.5s**, slam landing **0.8s**, wall stun **1.55s**. New 1.2s army tells below are proposals, not current universal behavior. |
| [Outsmart](../prototype/meadow-v4/Outsmart.luau) | Authored wall-bait floor/cover, reserved bell clearing and route/recovery cues exist. Outsmart remains the chosen identity. |
| [TunnelPolicy](../prototype/meadow-v4/TunnelPolicy.luau), [production adapter](../prototype/meadow-v4/ProductionTunnelController.luau), [RavinePolicy](../prototype/meadow-v4/RavinePolicy.luau) | Tunnel has mud, warned falling hazards, escalating rumble and surface Keeper interception; ravine has rim-drop/recovery policy. Tunnel's direct drop/knockback path is not proof of unified mercy with a new army. Estimated hit/escape rates in policy are not telemetry. |
| Cinematic movement document | Existing running ramp/FOV/dust is cosmetic, suppressed while carrying/slowed. Physical sprint, slide and vault are new gameplay work. Recent offline repairs do not establish live feel. |
| Section registries | Extensive Meadow and Cave art exists, much marked REVISIT/live acceptance UNKNOWN. Section bounds are ownership envelopes, not navigation. Gameplay and section coordinates must be reconciled through actual mounted transforms before placing anything. |

**SOURCE CONFLICTS:** GDD retains 1s steal, 160-sized map and first-hit-retain language; use current config above. Roadmap's unbuilt-loop/Cave statements are historical: handoff reports subsequent core and Cave work. Preserve it, do not restart it. Hermes CONTENT's hiding grass, boss bar, grip/heat/breath meters, extra rosters and long cutscenes are suggestions, not accepted scope.

**UNKNOWN:** cause of perceived ease, actual route times, present streaming settings, phone floor, current multiplayer balance, retention and fun. Owner feedback establishes dissatisfaction, not a measured diagnosis. Exact Keystone Roblox Process Playbook was not located in accessible local sources or callable Keystone tools; the supplied real-art/greybox/reference rules and installed Roblox production skill were applied. No claim the Keystone original was read.

## Reference arena: keep the lesson, reject incompatible rules

All named games/categories below are **owner-named in this task**. Selecting a best-in-class bar and applying its lesson is **INFERRED**; these are design comparisons, not popularity rankings or tested parity. Live pages checked 2026-10-17; no gameplay was played or watched.

| Reference / evidence | Side-by-side bar for this raid | Candidate pressure test |
|---|---|---|
| [Steal a Brainrot](https://www.roblox.com/games/109983668079237/Steal-a-Brainrot): official description states player stealing and money generation. | Keep contested treasure and visible home reward. Our opponent is also a commanding Guardian; do not import slap gear or theft of secured home pets. | A/D retain steal-first clarity; B delays it; C risks replacing it with an obby. |
| Steal an Egg: owner-reported sleeping guard **ZZ → ! → RUN**; Hermes records steal/hatch collection from a community source. A [same-name listing](https://www.roblox.com/games/107778070777162/Steal-An-Egg) was located, but its identity relative to the owner's example is UNKNOWN. | Selected best-in-class objective/wake/run clarity. Army reveal must be equally legible. No newly verified sleeping-guard claim. | A strongest simple wake escalation; D adds one route decision; B needs more explanation. |
| [Evade](https://www.roblox.com/games/9872472334/Evade): official listing describes movement as key to surviving Nextbots; [nico's nextbots](https://www.roblox.com/games/10118559731/nicos-nextbots) describes being chased. | Evade is the selected best-in-class chase/movement bar. Borrow readable turns and pursuit pressure; exact sprint/slide physics and mobile tuning unchecked. | A tests sustained pursuit; C movement mastery; D bait-and-route choice without another touch button. |
| [DOORS](https://www.roblox.com/games/6516141723/DOORS): official listing establishes horror/learning framing, not the requested Rush behavior. | Rush/minion cue → committed passage → relief is an INFERRED reference analogy. Do not copy mandatory closet hiding, darkness or jumpscares. | B/C use passing threats; D uses finite runner commitments. No claim DOORS enemies are an army. |
| [Piggy](https://www.roblox.com/games/4623386862/Piggy): listing frames escape and lists touch item/trap controls. | Read an objective while pursued; avoid a key-chain task list before the first treasure. | B has the greatest chore/free-rider risk; D keeps the treasure as the sole required objective. |
| [PARKOUR Legacy](https://www.roblox.com/games/445664957/PARKOUR-Legacy): listing emphasizes skill mastery and warns it can be unforgiving. | Movement should create a visibly better route, with a dependable mobile walking alternative. | C most expressive but least welcoming; D borrows only one low vault. |
| Raid/wave games: **Tower Defense Simulator is an INFERRED representative**, not an owner-specified title. Its [official wiki](https://tds.wiki/w/Waves) describes progressively challenging waves/new enemies. | Borrow composition/escalation and recovery windows. Replace killing waves with evading finite deployments; no enemy HP or kill reward. | B closest wave structure, A escalation after theft, D commander trades its own attacks for deployment. |

## Shared rules for every candidate — proposed contract

- **Never attack the Guardian or army.** No weapons, damage, HP bars, ram kills or kill rewards. Dodge, outrun, vault or trick. Minions recover or withdraw; cover bait makes them look fooled, not injured. No forced hiding or dedicated safe perch.
- Keep **one contested item**, atomic pickup/secure, same ID/roll/deadline through Bump/drop/Grab. Completed 2s Steal starts 60s; portal usable immediately. No forced survival minute, refreshed timer, timed extraction gate or waiting for a wave to die. Preserve existing verified-save failure semantics rather than inventing a new award path.
- Every army deployment has a visible doorway/ground marker and audible command, then **at least 1.2s** to react before a locked lane activates. Cancel deployment if an entrant, landing, recovery, nest or safety space would be occupied. No spawn on a player, invisible flanking hit, bodyblocking or commitment retarget. A late-streamed threat must not damage that client without its complete warning opportunity.
- Army and Guardian use one server attack coordinator. Reserve the threatened corridor and a real walking escape lane before committing. In the first slice, allow **one damaging commitment in the encounter at a time**; eventual disjoint districts may act together only when their reachable danger regions do not overlap. New deployments trade against Guardian attacks; they are not free extra damage.
- Route all accepted hits through shared mercy/drop validation, including tunnel hazards when army overlaps their route. Preserve 3s guardian/PvP mercy, existing once-only PvP shield, settle/Grab, reachable recovery and apron protection. No chain hit immediately upon mercy ending. Bell remains optional with existing charge/immunity; no army-wide stun or multiplication of decoy effects.
- Do not grant minions omniscient item tracking. Use visible last-seen junctions and bounded authored patrols; lost sight creates a route guess. Zero/minion-free route edges cannot become permanent camping exploits.
- Geometry freezes while occupied/cargo unresolved. Difficulty preset is shared per encounter, selected before entry, never silently raised by a late join. More rivals add existing Bump/route competition, not extra enemies per player. Empty-handed exit always works.

All times below are illustrative minute-by-minute paths, **not forced durations or measured pacing**. Earlier completion always works. Failed attempts and rewards must be measured separately; no coin/odds changes are proposed.

## A — Raid escape: steal, then the island wakes

**Fantasy:** snatch the acorn and outrun an island-wide manhunt. Army primarily pursues the carrier.

**Minute 0–1:** arrive, see distant barracks and an ordinary camp approach, complete the 2s steal. Guardian signals; two Sprout Runners emerge visibly behind the return fork. **Minute 1–2:** cut between three escape corridors, bait a committed charge into cover, outrun pursuit, secure before the original deadline. **Minute 2–3:** open at home/re-enter; no need to wait for those minutes.

**Army:** two runners initially, up to **six total server-wide**, plus Guardian. Runners follow a small authored lane graph to the last seen junction, warn a straight dash, commit, then recover. Progress at a district boundary permits another pair from visible gates; retire old units before exceeding cap. A single pair threatens the active corridor while others approach or recover. Cover breaks sight; a deliberate cutback fools the line. Never spawn behind an unreadable corner. No mandatory minion encounter before pickup.

**Movement:** automatic **physical sprint** on sustained forward dry-floor movement; no extra mobile button or stamina meter. Carrier stays slower than empty-handed runner; exact speeds/ramp UNKNOWN until tuned. Turn, mud, hit and ledge transitions cancel safely; no speed stacking with recovery. Sprint adds optional flank opportunities; baseline walking route must still work. This reopens current gameplay movement rules, not just cinematic effects.

**Map:** proposed **704×528**, twice current width and 1.5× depth, **3× footprint area** by arithmetic. Preserve the compact camp-to-return spine; expanded coast contains optional crosslinks and pursuit loops, not a compulsory full-width jog. Reuse S1–S7 landmarks/route language, extend beyond S2/S5, adapt S8 exterior support. S9/S10 home and C1–C8 stay untouched. New gates/coast/navigation graph; no uniformly stretched ramps. District streaming and distant silhouettes proposed; cap six simple minion rigs and only the relevant corridor's active tells. Navigation is the main server cost, not just geometry.

**Difficulty:** first encounter one runner pair; later chosen harder encounters add a second pressure direction and a reserve pair, within six. Guardian changes from chase to command opportunities, then intercept; do not shorten tells to create difficulty. Rivals can contest treasure, never cause per-player spawns. Required direct return remains viable without sprint.

**Reuse / discard:** retain Loop/PvP/Trap/CoreLoop contracts, cargo/economy, dash wall-bait, tunnel/ravine, art and movement preferences. Replace single-pursuer-only scheduling and extend route/drop tests. Discard full-map mandatory traversal and per-run random geography. **Relative cost: High. Biggest risk:** six chasers and empty travel produce exhaustion rather than clever escapes; physical sprint may erase existing chase balance.

## B — Wave siege: break the camp's route seals

**Fantasy:** infiltrate a fortified camp while its marching army closes routes; steal after opening the treasure enclosure. Army controls space before theft rather than chasing cargo.

**Minute 0–1:** approach first public route seal, perform a short contextual hold while a finite marching wave crosses nearby. **Minute 1–2:** switch to the opposite ring, activate second seal and steal; completed seals stay public for the occupied encounter. **Minute 2–3:** escape before 60s from that steal, secure/open. Leave early empty-handed if desired. Seals reset only at encounter retirement; they add no new permanent progression.

**Army:** **four marchers per deployment, eight total server-wide**, plus Guardian. Banner and marked gates announce which open ring they will sweep; at least 1.2s warning, fixed route, automatic withdrawal after crossing. Next seal interaction requests the next deployment; no survival countdown, kill/clear objective or requirement to wait until every unit leaves. Marchers are pass-through hazards with gaps; reserve one bypass through each ring. Guardian commands instead of attacking in the same window. An interrupted seal hold loses only its current hold progress, not prior completed seals.

**Movement:** optional **slide**, one large touch button, same action on keyboard/pad; broad directional reposition, no i-frames, hitbox shrink or collision bypass. No forced under-bar passage or slide-only escape; normal jumping/walking work. Slide state, slopes, carry and cooldown authority are new work.

**Map:** **528×528**, 1.5× each dimension, **2.25× area**. Three open camp rings connected by spokes/crosslinks; reuse S7 camp and S6 terrace vocabulary, S1 return, S4 recovery principles. New seal courts, gates, ring navigation; much S2/S5 route arrangement needs redesign. S3 remains optional through-route; home/Cave retained. Stream rings as small units; eight lightweight marchers maximum, no physics crowd simulation. Do not keep every ring's visual wave active for spectators.

**Difficulty:** seal one teaches a crossing, seal two alternates lane directions, cargo phase mixes Guardian interception with a final deployment. Harder preset changes compositions/route choices, not seal count or hold duration. Rivals can complete public work then race for the item; no contributor-exclusive lock. That free-rider consequence is a deliberate unresolved fairness weakness.

**Reuse / discard:** retain post-steal deadline/ownership, drop/mercy, home/reveal/save and existing suites as regression coverage. Add encounter/seal/wave lifecycle tests; rewrite pre-steal objective flow/navigation. Discard immediate treasure access and old camp approach assumptions in this candidate; retain history, not destructive deletion. **Relative cost: Very high. Biggest risk:** doing chores or waiting for waves before the defining steal reduces repeat appeal and first-reward speed.

## C — Parkour gauntlet: steal at the top, escape down the ridge

**Fantasy:** a downhill escape stunt with minions sweeping the next landing. Army is moving terrain pressure, not pursuit AI.

**Minute 0–1:** choose broad walking ascent or practice shortcut; steal at the summit. **Minute 1–2:** descend three connected ridge stages, read a sweeping minion, vault an optional rail, recover any missed shortcut and reach the portal before the same deadline. **Minute 2–3:** home/replay to improve the route; no style farming or reward for delaying escape.

**Army:** **six sweepers total server-wide**, two assigned to each stage, plus Guardian. Marked side doors announce a lane sweep at least 1.2s early; sweep a locked line, pause/recover out of the lane, return to staging. Only current relevant stage threatens the carrier. Never sweep both shortcut landing and walking bypass, or recovery ramp. Sidestep, choose another lane or lure a premature crossing; minions cannot be hit. Inactive stages need no active cosmetic crowds.

**Movement:** **automatic low vault** on deliberate forward movement into a clearly marked low rail. Native jump remains; no added touch button, wall-hop or grapple. No i-frames/hitbox shrink. Reject unsafe landing/blocked headroom. This automatic trigger is a candidate to test, not presumed phone-safe.

**Map:** **704×352**, twice width, unchanged depth, **2× area**. Three switchback platforms use lateral/vertical space; no compulsory 704-stud straight run. Reuse S5 ridge, S6 shelves, S7 summit art and S4 recoverable fall language. New continuous walking ramps, rail landmarks and sweep doors; significant route/drop re-authoring. S2/S3 preserved as optional alternate access, not required gauntlet stages. Home and Cave untouched; Cave cart/explosion work is not converted into a Meadow obstacle. Stage streaming needs complete floor/rail/landing sets before movement. Six simple sweepers, no pursuit pathfinding; geometry/readiness dominates.

**Difficulty:** one clear crossing first, then alternating sweeps and Guardian commands; Guardian moves legally along its outer route, never teleports ahead for an ambush. Advanced optional lines trade tighter turns for distance; standard walk can finish. Rival Bump is restricted by existing legal range/mercy and must not make a landing unavoidable; no physical bodyblock.

**Reuse / discard:** keep jump height, fall recovery, item/save loop, safe apron, tests for those invariants and existing art. Replace substantial route stations, approach timing and navigation assertions for changed geometry; add vault/sweep/recovery checks. Discard required tunnel traversal and a free-roaming army. **Relative cost: High–very high. Biggest risk:** mobile vault mistakes/precision become the game, burying stealing and Outsmart beneath an obby.

## D — Route-control hybrid: steal, bait, choose the gap

**Fantasy:** the Guardian commands the island, but you make its squads commit to the wrong route. Army changes your route decision; it does not simply add pursuers.

**Minute 0–1:** approach using current routes; steal immediately when the hold succeeds. Guardian points and calls a pair from a visible broad junction. **Minute 1–2:** bait its dash at existing cover, read the squad lane, take dry walking bypass or optional vault cut, secure before the same 60s deadline. **Minute 2–3:** open/home/retry a different route; a faster player may already be repeating.

**Army:** **two Sprout Runners in the active district; four total server-wide**, plus Guardian. On steal, raise gate/footprint cue before emergence. A later route-progress trigger may deploy a reserve pair only while retiring/transferring the old pair within cap. Each runner reads a visible last-seen junction, plants its feet, marks a straight lane for at least 1.2s, dashes and visibly recovers. Other runner approaches/recovers rather than stacking another strike. Cover cutbacks fool them. No global carrier beacon, teleport-to-next-district or respawn loops around a dropped item. Retired squads cannot reappear on the same loop indefinitely.

**Movement in the blind candidate:** optional **automatic low vault**, no extra touch control, no i-frames. It keeps default speed/jump rules and uses marked optional rails with a dry walking bypass. Critic correction to the selected version appears below; scores belong to this original candidate.

**Map:** eventual **528×528**, **1.5× dimensions / 2.25× area**. Three linked districts: current camp/descent, west tunnel/cover, east ridge/recovery. Keep the existing direct return; new outer links add choice, not minimum distance. Reuse S1–S7 interiors/landmarks, extend S2/S5 edges only after slice acceptance, extend S8 silhouette around added ground. S9/S10 and all C1–C8 frozen. No cut-and-paste Cave cart, no full art reset. Stream individual district route sets and low-detail far coast; four simple runners and one active commitment in the pilot keep scope bounded.

**Difficulty:** first encounter teaches one pair at one junction. Later chosen shared preset introduces reserve pair and Guardian intercept phase; all trigger on progress, not a timer that rewards waiting. A command uses the Guardian's next attack opportunity; Guardian attacks, runner charge and tunnel fall must compete for that corridor. Rival players add route/Bump decisions without multiplying army or shortening tells. Never require all three districts before escape.

**Reuse / discard:** keep item loop, approved art, wall-bait/repeat-corner protection, bell with its existing limits, tunnel/ravine choices, PvP/mercy/safety, core persistence and all relevant regression suites. Add small runner lifecycle, shared attack reservations and vault validation; extend routes only later. Discard seal objectives, continuous army growth, forced parkour, new meters and a mandatory long island crossing. **Relative cost: Medium–high, the lowest of these four, not a small cosmetic patch. Biggest risk:** a tiny squad underdelivers the word “army”; compensate with the Guardian's readable command and coordinated movement, not fake damaging crowds.

## Mobile and performance budgets — proposals, not measurements

| Budget | A | B | C | D |
|---|---|---|---|---|
| Total minions across server / Guardian | 6 / 1 | 8 / 1 | 6 / 1 | 4 / 1 |
| Main simulation | Bounded lane-graph pursuit | Fixed marching lanes + seal state | Fixed sweep stages | Local junction approach + fixed dash |
| New movement input | Auto physical sprint | One slide button | Auto vault | Initially auto vault; selected revision uses existing Jump |
| Primary cost risk | Path refresh/replication | Wave/state cleanup | Landing/stream readiness | Threat arbitration + vault |

Shared proposed ceilings: minion visual rig at most **8 simple parts**, no ragdolls or collidable crowd; one active tell plus one recovery effect per visible minion; no decorative active army elsewhere. Stagger lane decisions with a **5Hz initial decision budget**, swept hit checks evaluated appropriately during commitments rather than at that slow decision rate. These are starting limits, not benchmarked guarantees. Do not clone full Guardian rigs/forty-segment attack rings for every soldier.

Initial device goal: sustain **30fps** on Zion's selected lower-end phone during an eight-player worst-case encounter; phone/model, memory MB budget and baseline frame cost **UNKNOWN**. Record baseline and slice frame-time distribution, memory, network and server script cost before choosing geometry density. Eight players split across districts still share the same minion cap. Reduce dressing/actors before weakening warning readability.

[Roblox streaming documentation](https://create.roblox.com/docs/workspace/streaming) confirms content can load/unload dynamically and cautions about large moving assemblies. **INFERRED application:** stream small coherent route/landing/cue units; keep authoritative state independent of streamed visuals, verify joins and missing-content behavior, and avoid extra replication foci per soldier. Streaming does not remove server AI work. In the 60s chase, loading stalls are a fairness failure: stop expansion if present; do not silently lengthen/reset cargo timers to disguise them.

No external template/code/assets adopted. Existing project code is the first foundation. [Vendored licence ledger](../prototype/core/Packages/README.md) lists MIT RbxUtil utilities and Apache-2.0 ProfileStore; retain notices with any future reuse. External game references supply no asset or code rights. New minion art needs provenance and script-free intake before implementation; no download/import/spend authorized here.

## Three blind critics

Three separate context-isolated reviewers received the same anonymous X/Y/Z/W candidates, constraints and no recommendation or author preference. Mapping revealed afterward: **X=A, Y=B, Z=C, W=D**. Each scored every candidate. These are **INFERRED simulated persona/document judgments**, not actual children, external professionals, blind gameplay or retention evidence. Engineer received supplied source facts, not an independent runtime audit.

| Critic lens | A | B | C | D |
|---|---|---|---|---|
| 10–14-year-old TikTok-watching player | **7/10:** growing chase makes a clip; huge travel/six chasers may frustrate. | **4/10:** two chores before stealing; following others may be easiest. | **6/10:** shortcuts satisfying; feels more obby than stealing, accidental vault ruins moment. | **8/10:** steal/trick/barely escape reads quickly; two runners can work if entrances/near misses look strong. |
| Roblox retention/fairness designer | **7/10:** clear fantasy/reward; automatic sprint and pursuit stacking risk fairness. | **4/10:** seals postpone the hook, free-riding and safest-wait behavior. | **6/10:** understandable mastery; shortcut advantage can punish mobile, ascent/descent overshadows theft. | **8/10:** repeatable bait/route choice and explainable failure; transfers must never spawn into escape space. |
| Mobile/codebase engineer | **6/10:** 3× area/six pursuit agents plus physical speed validation. | **3/10:** most lifecycle state/cleanup and eight marchers; weak reward pacing. | **5/10:** bounded sweeps help, but new navigation/vault/recovery geometry costs. | **8/10:** closest existing fit, still needs coordinator/lifecycle; tunnel mercy integration unproven. |

Each ranked **D > A > C > B**; agreement is document preference, not statistical validation. Player's necessary cut: B's mandatory seals. Designer and engineer independently requested cutting automatic vault from the first version and proving walking/route-control first. Engineer additionally required shared tunnel/Guardian/runner arbitration and an eight-player split-route check.

## Winner and concrete first slice — proposed future build

**Choose D's route-control, A's immediate army reveal, and Outsmart's existing cover commitment.** Do not combine B's seals or C's multi-stage course. Do not enlarge the full map first. This is a new design proposal, not acceptance of a replacement launch plan or authorization to implement.

**Critic-driven revision:** remove automatic vault triggering. To satisfy the requested one-movement-move slice, include a **Jump-confirmed low vault** at one marked optional obstacle: forward intent + existing Jump while at that rail requests a low vault, otherwise normal Jump. Same mobile Jump button; no aim gesture or new hotbar. This revised variant was not rescored. Compare the encounter walking-only first, then with vault enabled. If the move causes unwanted traversal, cut it and keep the winning route-control encounter rather than add slide/grapple.

| Slice element | Concrete proposed scope |
|---|---|
| One section | **S2 West path/tunnel mouth**, one broad surface junction around the current wall-bait return. Existing `Outsmart.Corner` (-73,0,113) is a source anchor, not a verified placement coordinate in section space. Resolve mounted transform/bounds first; move the pilot within S2 if needed. Existing rest of Meadow supports the run but receives no redesign. |
| One minion type | **Sprout Runner**, two instances maximum in this pilot; squat leafy silhouette, no weapons. Gate/footprints → Guardian point/chirp → ≥1.2s fixed lane → short straight dash → puzzled recovery. One charges while the other stages. Do not copy Guardian's shorter current DashTell into this new type. |
| One move | Jump-confirmed low vault on a proposed **2-stud-high** fallen rail in the optional broad flank. Height is a tuning hypothesis. Server validates approach, headroom, complete floor/landing and bounded displacement; ordinary hitbox/mercy, no i-frames, no vault over chasms. Stop safely on blocked landing; never snap to a far side. Dry walking bypass remains open. |
| One moment | 2s steal → existing Keeper wall-bait → visible squad command at junction → choose walking cutback or vault flank → continue to existing cyan return under same 60s clock. Army cannot damage during the Keeper's committed attack/recovery reservation. No mandatory detour through pilot. |
| Tunnel boundary | S3 interior, mud/fall geometry and both exits remain. First pilot runners stay on surface and outside tunnel/recovery reservations. Coordinator must still resolve any overlapping tunnel/intercept threat; otherwise do not activate the squad at that time. |
| Art/feel | Keep approved Keeper/acorn, warm Meadow and established cyan return; one readable leafy minion. Existing reduced-motion/settings and cargo suppression preserved; no forced camera, score meter or cutscene during pursuit. |

**Keep from current work:** Meadow S1 arrival, S3 tunnel, S4 bridge/ravine/recovery, S5–S7 ridge/camp/cover, S8 silhouette and all S9/S10 home work; modify only the defined S2 pilot later. Keep all Cave C1–C8/cart/explosion content and its build preservation pipeline. Keep home opening/pets/income/save, unique cargo award, deadline, Bump/settle/Grab, bell/immunity and wall-bait protections. Section cosmetics marked REVISIT are not automatically accepted art, but they are not discarded by this direction.

**Future validation, not run today:**

1. Compare walking-only and vault-enabled on the same encounter: novice solo, skilled solo, then real two/eight-player split routes. Capture failure as well as success. Log steal→secure duration, chosen lane, tells actually seen, accepted hit source, repeated corner camping, unwanted vaults and deliberate waiting. A larger map needs route-time evidence before approval.
2. Keep existing LoopTest, PvP, TrapTest, OutsmartTest, DropSampleTest, core domain/CoreLoop, Ravine and Tunnel gates; cinematic lifecycle/reduced-motion checks remain relevant. Existing documented legacy failures remain explicit, never relabeled green. New coverage: global cap/retirement, locked lane/no overlap, shared mercy with tunnel, late-stream warning, same deadline on handoff/expiry tie, blocked vault/headroom/landing, respawn/disconnect cleanup. Changed geometry gets updated route/drop fixtures; do not simply weaken their assertions.
3. Show Zion one matched muted phone-shaped clip beside the owner-supplied Steal an Egg wake/run beat and an actual Evade movement clip when available. Clarity test: can he point to treasure, commanded lane, chosen escape and payoff? No claim footage was compared today. He judges **harder but fair / move feels useful / want another run** before squads, sections or maps multiply.

If walking alone trivializes the pilot, change route choices and coordinated threat timing before adding actors. If every route is caught, simplify the overlap. If minions obscure Guardian identity, delete a runner. If vault is unreliable on touch, remove it. Do not solve any of these with paid power, shorter unreadable tells, compulsory precision or a longer forced escape.

## Lessons

1. When an owner asks for a bigger army, add a readable route decision first, because more land and actors can add travel and unfair overlap without useful difficulty.
2. When enemies and terrain can hit the same carrier, coordinate attack permission and mercy centrally, because separate cooldowns do not prevent stacked loss.
3. When adding mobile movement, require clear player intent and a walking comparison, because cosmetic running and automatic traversal do not establish reliable control.
