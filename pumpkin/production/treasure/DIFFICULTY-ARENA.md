# Difficulty + rewards arena — Steal a Treasure

2026-10-18 · Design only. **Pick pattern mastery: parry the guardian, steal, choose an escape route. Release two Crown Roads, Meadow and Crystal Cave, with five zones each.** Rewards: earning treasures (pets OR relics), Coins, and first-clear crown trophies. Defer stat gear.

## Authority and evidence

**OWNER-REPORTED, Zion, 2026-10-18:** approved MIX = Crown Road zones + one Pixel Blade-style parry/stun; no general player attack/kill combat. Release with two maps. Verbatim: “Yes but probably 2 maps on release, also maybe not always pets, we have to decide we're the difficulty it coming from”. The MIX/two-map decision supersedes conflicting one-map/no-parry recommendations in older arenas. Reward selection and all tuning below remain proposals.

**CHECKED:** [ZONE-ARENA](ZONE-ARENA.md), [RAID-ARENA](RAID-ARENA.md), [RAID-REVIEW](RAID-REVIEW.md), [PACIFIST-ARENA](PACIFIST-ARENA.md), [GDD](GDD.md); local [Hit Game Bible](C:/dev/codex-lab/refs/ROBLOX-HIT-GAME-BIBLE.md), [Game Theory Checklist](C:/dev/codex-lab/refs/GAME-THEORY-CHECKLIST.md), [Steal an Egg](C:/dev/codex-lab/refs/BIBLE-STEAL-AN-EGG.md), [Steal a Brainrot](C:/dev/codex-lab/refs/BIBLE-STEAL-A-BRAINROT.md), [Pet Sim 99](C:/dev/codex-lab/refs/BIBLE-PET-SIM-99.md). These are historical studies, not new footage observations. Current guardian presentation/attack, raid and Outsmart source inspected; reuse findings below distinguish source from proposed integration.

**OWNER-SUPPLIED RESEARCH, 2026-10-18:** Pixel Blade has attack, block/parry, dash and ability controls; perfect parry displays PARRY and a vulnerability window; dash i-frames; !/floor-circle/tether/audio telegraphs; worlds of three chapters with approximately five rooms plus boss; Normal/Heroic/Nightmare; four-player co-op; coins/XP/chests/wishes/rings; 3D pixel art. These supplied details are not all independently verified here. A fresh [official Roblox listing](https://www.roblox.com/games/18172550962/Pixel-Blade) confirms attack, block/parry, dash and parties up to four. We borrow defensive timing and readable recovery, not its damage/counter/gear progression or art assets.

**Every proposed mechanic, score, number, timing, income rate, success target and predicted outcome in this document is INFERRED and UNTESTED.** No playtest, phone benchmark, retention measurement or real-child interview occurred. Runtime/fun/latency acceptance is UNKNOWN. Exact Keystone Roblox Process Playbook was not found in checked local coordination sources; no claim it was read. Applied the supplied real-art/core-moment/reference rules and installed Roblox production skill. No place/code edits, Studio Play, downloads, spending, commits or publication.

## Difficulty source arena

Scores /5: higher = more skill, clearer/fairer, stronger clip potential, or better phone feel. **Cost is reversed: 1 cheap, 5 expensive**, relative to inspected code; no hours estimate. Do not sum unlike cost/benefit scales.

| Candidate source | Skill | Fair/readable | TikTok moment | Build cost | Phone feel | Decision |
|---|---:|---:|---:|---:|---:|---|
| Guardian attack patterns + parry timing | 5 | 4 | 5 | 4 | 4 | MAIN. One clear impact beat; patterns change before precision does. New input/authority/state work. |
| Raid squads / commanded lanes | 4 | 4 | 4 | 3 | 4 | SECONDARY from Z3; one finite pair per cargo, serial strikes. Reuse lane lifecycle, not growing crowds. |
| Escape timer | 2 | 4 | 4 | 2 | 4 | Urgency only. Same original 60s on both maps/all zones; immediate banking allowed. |
| Route / terrain hazards | 4 | 4 | 4 | 3 | 4 | SECONDARY through route choice; dry walking bypass, recoverable falls. No compulsory obby. |
| Rival players | 3 | 2 | 5 | 3 | 3 | Emergent races and loose-cargo recovery only. Not needed for solo difficulty; no Bump/forced drop/bodyblock in selected design. |
| Carry weight / variable speed penalties | 2 | 2 | 3 | 3 | 2 | CUT variable weights. Keep one predictable carry speed, independent of treasure rarity/shape. |
| Detection / sneak simulation | 3 | 3 | 3 | 4 | 3 | CUT cones, crouch, noise meters, hiding and nap waits. Keep an immediate wake/! approach cue. |
| Zone modifiers | 4 | 3 | 4 | 4 | 3 | LATER fixed, previewed single-rule remixes. Cut random weather debuffs, hidden timing changes and daily rule stacks. |

Main skill = **read the pose/shape, time one parry at impact**. Secondary = **pick a viable return lane under one coordinated raid encounter**. Fixed carry speed and deadline make mistakes attributable. Progression must work solo with starter movement; eight players add rivalry, not eight times the attacks.

Cut general attacks, health, enemy kills, attack stats, dash/i-frames, stamina, precision aiming, forced hiding, growing waves, compulsory vaults, random slow/heavy loot and speed gates. Existing Bump remains in historical source until a separately authorized implementation removes its acceptance/input; this document does not claim it was removed. This follows ZONE-ARENA's race/recovery rule rather than older GDD/PACIFIST Bump proposals.

## One move: parry → stun → steal

All values below are tuning seeds in **milliseconds** unless marked seconds.

| Rule | Selected proposal |
|---|---|
| Teach | At the nest, guardian raises its arm, a fixed attack shape appears, ! pulses and a rising sound resolves at impact. Banner: “Block at the flash.” Matching shape/motion makes sound/color optional. |
| Warning vs timing | Each full warning is at least 1200ms; the active parry window is a much smaller final interval. Warning duration is never the parry window. Z1–2 window 300ms, Z3–4 280ms, Z5+ 260ms. No later sub-260ms squeeze. |
| Exact window | For an eligible server attack with impact time T and zone window W, accept one tap timestamp in [T−W, T], with proximity, targeted attack envelope and line-of-sight checks. No directional aim or camera lock required. Early holding does not extend/repeat the window. |
| Success | PARRY text, soft clang, guardian stars/stumble, no damage. Stun 3600ms, same on both maps; cancel the remaining beats of that attack ID. The successful player's nest latch opens for that stun, allowing the existing 2s continuous Steal hold. |
| Nest access | Put the teaching stance within normal Steal reach. Start the hold immediately after parry: 3600−2000=1600ms approach/input margin. A cancelled/late hold spends no treasure and allows another warned attempt. Parry itself grants no item, Coins or clear. |
| Cooldown | 6000ms from every tap, including a miss; visible radial fill. Guardian cannot offer a required nest strike until cooldown is ready. From Z1, keep repeat attempts quick; no separate stamina meter or block-hold mode. |
| Miss | Mistimed tap alone causes no hit. Being inside the committed strike at impact causes existing knock/stumble and reachable knock-drop if carrying. Empty hands lose position/time only. No HP/death, banked loss or automatic expiry; moving out still dodges. |
| Carrying | Same move works on marked guardian parry attacks; same cooldown/stun. Raid runners and terrain use lane choice/jump, with an arrow/footprint cue distinct from the guardian's shield cue. Never show a shield icon on an un-parryable hit. |
| Anti-chain | One accepted stun per guardian attack ID; simultaneous taps cannot extend it. Guardian-wide earliest next stun is 6000ms after the last accepted stun, including different players. No new windup during stun; then a fresh complete warning, never a queued instant hit. Schedule required nest strikes only when both guardian and player are eligible. No Coins/style farming for repeat blocks. Wall bait and parry cannot add durations. |
| Touch | One persistent PARRY shield button during danger, proposed 64×64 logical-pixel target above/left of native Jump, inside device safe inset; right thumb taps while left thumb steers. Steal remains a contextual hold. No swipe, double-tap, four-button hotbar or compulsory shift lock. Validate layout on the actual phone. |
| Authority | Server owns attack ID, committed impact/shape, eligibility, stun and cargo. Client sends tap intent/time, never “parry succeeded”. Immediate predicted button/clang feedback must reconcile; clocks and bounded latency compensation require adversarial testing, not trust in arbitrary old client timestamps. No infinite rewind. |

Parry is new code, not a rename of wall-stun. A shared guardian stun may help friends, but only each successfully parrying player receives its own short nest permission. One atomic source winner; unused permissions expire with stun, and nothing refreshes the cargo clock. Z1 retains the proposed bounded source refill after pickup and supports another full warning before another steal. Do not promise eight novice earners under two minutes until measuring contention. If a rival recovers cargo, it retains the original zone/outcome/deadline; banking can award that zone's clear. A crown means **banked a zone treasure**, not proof of solo parry mastery.

Global threat arbiter: only one damaging commitment can cover a player's corridor at once across guardian, raid and terrain. Guardian attacks pause for an active raid; parry stun/recovery reserves the corridor before any raid starts. Preserve shared 3s hit/pickup mercy, reachable drops, settle/Grab, safe boundary and save lock. Do not overlap a failed-parry knock-drop with a raid hit. During existing mercy, attacks cannot manufacture a successful parry/extra stun. A stunned enemy does not remove the need to carry home before the original deadline.

## Zone ladder — new decisions, not fifteen smaller windows

Each road has **local Z1–5 at release**, later Z6–15 on that road. This means ten launch zones total, not fifteen per map at launch. Later rows are a design backlog, not a content-production commitment. Keep a maximum of three taught demands in any encounter; later zones select previous demands rather than stacking every preceding row.

Notation: warning = first complete shape/pose to first impact. Additional beat times are from that first impact. W = parry window before the shield-marked impact. A successful parry cancels the whole remaining pattern. Avoid earlier movement beats then parry the marked last beat. Every distinct shape is visible from the initial warning; committed targets never retarget.

**First-try targets** below = % of players who bank the chosen zone's self-stolen cargo on their first eligible attempt, after the previous zone clear, solo, baseline movement/no stat gear. Include fails, timeout and abandoned attempts; exclude source-lost-before-attempt contention and report that separately. These are **INFERRED desired ranges, not forecasts or measured rates**. Also log parry success separately so a long return does not masquerade as a timing problem.

| Local zone / release | Exactly one new demand | Meadow pattern / telegraph | Crystal pattern / telegraph | Warning / W (ms), both maps | First-try bank target Meadow / Cave |
|---|---|---|---|---|---|
| 1 / v1 | Time one impact | Big raised palm, filled wedge, single shield flash | Crystal arm rises, straight glowing lane, single shield flash | 1500 / 300 | 80–90% / 75–85% |
| 2 / v1 | Read a delayed impact | Palm holds visibly at shoulder; growing ring resolves later | Crystal charge fills in three steps; no fake strike | 1800 / 300 | 70–80% / 65–75% |
| 3 / v1 | Choose a return fork | Familiar delayed palm; single commanded raid pair on return | Familiar charged arm; single crystal-runner pair at return fork | 1800 / 280 | 60–70% / 55–65% |
| 4 / v1 | Read travel time | One slow seed orb, fixed landing circle; parry at landing, not release | One visible ricochet from marked crystal; final landing circle shown immediately | 2000 / 280 | 50–65% / 45–60% |
| 5 / v1 | Reposition then parry | Outer floor crescent says STEP, final inner palm shield at +1400ms | Two floor strips say STEP, final crystal palm shield at +1400ms | 1500 to STEP, 2900 to parry / 260 | 45–60% / 40–55% |
| 6 / later | Identify approach side | Left/right lifted shoulder and locked wedge | Left/right lit crystal arm and lane | 1500 / 260 | 45–60% / 40–55% |
| 7 / later | Remember two serial route passes | Familiar Z6 strike, return arrows show two separated passes | Familiar Z6 strike, two crystal-runner passes | 1500 / 260; raid tells 1500 each | 40–55% / 35–50% |
| 8 / later | Choose a standing pocket | Two outer circles STEP, central shield palm at +1400ms | Two crystal strips STEP, shield orb at +1400ms | 1500 to STEP, 2900 to parry / 260 | 40–55% / 35–50% |
| 9 / later | Distinguish two rhythms | Raised palm vs shoulder hold, distinct poses; 1500 or 2000ms | Solid vs segmented arm charge; 1500 or 2000ms | 1500 or 2000 / 260 | 35–50% / 35–50% |
| 10 / later | Choose short exposed or longer covered return | Familiar Z9 pose; long red floor lane on shortcut | Familiar Z9 charge; crystal beam strip on shortcut | 1500 or 2000 / 260; route warning 1500 | 35–50% / 30–45% |
| 11 / later | Read alternating return lanes | Familiar single palm, three announced serial lane passes | Familiar single arm, three announced serial lane passes | 1500 / 260; raid tells 1500 each | 35–50% / 30–45% |
| 12 / later | Read an explicit guardian handoff | One palm guardian retires; next section guardian visibly waves before next threat | One crystal guardian retires; next answers with lit arm | 1800 / 260 after handoff | 35–50% / 30–45% |
| 13 / later | Track a longer visible flight | One high seed arc; final circle fixed from start | One longer reflector arc; final circle fixed from start | 2400 / 260 | 30–45% / 30–45% |
| 14 / later | Pick cover before its safe edge ends | Familiar delayed palm; return has earlier visible cover endpoint | Familiar delayed arm; crystal ribs end before fork | 1800 / 260; return warning 1500 | 30–45% / 30–45% |
| 15 / later | Execute two taught decisions in order | Z5 STEP→palm, then one familiar fork | Z5 STEP→arm, then one familiar fork | 1500 to STEP, 2900 to parry / 260; raid 1500 | 30–45% / 30–45% |

The parry itself is still one press in all rows; no multi-parry combo. Map 2's Z4 reflector is a new path variant of the same projectile/landing primitive, not a hidden bounce or a second combat system. Z5 has a 1400ms gap from STEP impact to shield impact, exceeding the 1200ms warning floor. Z7/Z11 reserve serial return passes within one finite deployment, never summon two/three squads at once. Z12 is an explicit later revision to the v1 foreign-guardian ignore rule and needs its own arena/authority review. No automatic difficulty scaling when a skilled friend joins.

If measured Z1 misses its target, fix tell/input/stance first. If Z4 fails while parries pass, inspect route/flight visibility before widening windows. If a later zone is too easy, change a visible pattern/route choice before shortening tells or adding enemies. A below-target launch zone is a tuning defect, not proof the game is satisfyingly hard.

## Rewards: three types at v1

**Type 1: earning treasure**, which can be a pet OR a nonliving relic. Both occupy the same existing eight income slots, use the same reveal/place/collect loop and show name/rarity/Coins per second. A relic does not follow, fight, block or secretly buff parry. **Type 2: Coins**, from those placed earners. **Type 3: crown trophy**, one nonspendable shelf stamp per map/zone first bank; map-completion crown is a larger rendering of those five stamps, not another currency/item economy.

Pets are a reward form, not an unavoidable result of every container. Show the zone's fixed reward family and base income before stealing; rarity is the only roll. First successful ever reward remains the guaranteed Common Pup. No first reward on loss, artificial tutorial grant or reward for stunning. Loot becomes durable at bank acknowledgment; earner appears through existing Place/Open. Clear stamp is attached to that same cargo receipt and cannot duplicate on retry.

| Zone | Meadow reward family | Crystal Cave reward family | Proposed Common floor Coins/s |
|---|---|---|---:|
| 1 | Pup pet | Singing Geode relic | 1 / 4 |
| 2 | Windmill Music Box relic | Cave Crow pet variant | 2 / 6 |
| 3 | Crow pet | Crystal Lantern relic | 4 / 8 |
| 4 | Golden Acorn Clock relic | Geode Pup pet variant | 6 / 12 |
| 5 | Crowned Pup pet variant | Crown Prism relic | 8 / 16 |

All table items/art are proposed, not approved new assets. Reuse approved Pup/Crow bases, acorn/geode shells and native block props first. Existing assets/licenses must be retained; original new relic shapes need art review. Cave's earlier rewards overlap Meadow's later income to make it a genuine alternative road, not five compulsory extra grind tiers. Rare/Epic variants use proposed ×1.5/×2 of that floor with disclosed 70/25/5% odds, locked on original pickup; first-Pup override is explicit. These multipliers replace the older 1/4/8 rarity-rate proposal for new versioned zone rewards only; never rewrite existing owned-pet earnings.

Loop: **bank a harder treasure → replace/fill a visible earner slot → collect more Coins → buy a chosen home trim/relic skin → attempt the next pattern**. Zone access comes from a bank, not Coins or lucky rarity. Coins cannot widen a parry window, buy immunity, extend stun or reset the clock. V1 Coin sinks are a small fixed-price home trim ladder and collection display styles in the existing shop, not a crafting tree. Prices need an income simulation and actual collection cadence before acceptance; no invented payback claim. Spending on a cosmetic has no financial payback. Unlike ZONE-ARENA, stat boots are deferred so difficulty can be judged without purchases.

Replacement at cap eight must compare actual old/new income, require explicit confirmation and reserve capacity before entry; never auto-delete the first/upgraded/favourite earner. Reuse ZONE-ARENA's acknowledged replacement plan, but relic eligibility, generic display identity and immutable rate migration are new work. Preserve existing owed bank accrual and independent award receipts. Shelf crown stamps do not consume earning slots and grant no income. One shelf presentation, no crown counter in danger HUD. Repeat reasons are better income/rarity, the other road's collection and improved execution; crowns alone are not claimed to sustain retention. Active-vs-idle advantage and long-term Coin sinks remain UNKNOWN; simulate the cap-eight economy before claiming checklist compliance.

| Reward option | V1 / later | Bounded feedback rule |
|---|---|---|
| Earning pets + relics | V1 | Same economy and slot cap, never combat power; each successful run has a useful base reward before luck. |
| Coins | V1 | One spendable currency, safe at home; no Coins for hits/kills/parries or failed theft. |
| Cosmetic shelf trophies / crowns | V1, merged as one type | Five first-clear stamps per road; no spending, stats, duplicate payouts or extra tutorial menu. |
| Boots | Later only | Common/Rare/Epic appearance, same stats across rarity. Prototype +1 carry speed / −1 empty-handed speed in one accessory slot; baseline must complete every release zone. No rarity-speed stacking. |
| Gloves | Later only | Common/Rare/Epic appearance, same stats across rarity. Prototype +20ms timing assistance / +1000ms cooldown in that same accessory slot, mutually exclusive with boots. Never required or auto-parry; no paid stat advantage. Reject if it replaces learning. |
| Shields | Later only | Common/Rare/Epic cosmetic alternatives to the default parry pose; no longer stun, universal holding, HP or extra move. |

Do not launch a gear loot table, XP, wishes, rings, crafting, fuse, trading, second currency, rebirth or ten upgrade menus because Pixel Blade has them. Add one gear choice only if replay data identifies a specific unsolved need; gear rarities are cosmetic unless a later reviewed prototype proves a fair bounded sidegrade.

## Two maps, one zone system

| | Meadow Road | Crystal Cave Road |
|---|---|---|
| Identity | Open bright orchard, windmill/crown landmark, warm acorn treasure | Bright readable cavern ribs, prism/crown landmark, geode treasure; no darkness-as-difficulty |
| Guardian language | Palm holds, seed arc, crescent STEP | Arm charge, visible reflector arc, strip STEP |
| Terrain decision | Broad cover cutback; optional low rail with dry walking bypass | Crystal rib fork; visible reflector and raised dry causeway with recoverable lower path |
| Reward theme | Familiar pets mixed with toy orchard relics | More relics, crystal pet variants; same income-slot model |
| Progression | Free Z1; next steal unlocks on previous local zone's durable bank | Road opens after Meadow Z3 bank, no price; Cave Z1 starts a separate local clear ladder |
| Shared home | One persistent home/collection and simple road selector outside danger | Same home and safe-bank behavior; return targets the current map's clearly marked line |

Two authored roads, not ten portals/places. Keep eight players total across both roads; no minimum population. Selecting a road is an empty-handed home action, no map switching with provisional cargo, no timer reset. Shared registry keys `(mapId, zoneId, cargoId)` scope guardian ownership, outcome, clear flags and return encounters. Per-cargo original deadlines and per-player banners replace global singleton assumptions. Each road can run in the same place; final streaming/layout architecture is future engineering work, not an assertion that it already supports two roads.

One local guardian controls its zone plus an adjacent return segment; foreign guardians ignore cargo. Select one return encounter near the active cargo's route rather than triggering every earlier zone. Across eight concurrent runs, schedule only readable bounded commitments in shared corridors; per-cargo raid caps alone are insufficient. Existing two-runner donor gets a proposed **four-runner server cap** across both roads; if full, skip that optional deployment, never block a steal or spawn into the player. This means challenge consistency under load is a measured release risk. No unseen spawning, crossing safety, or forcing both fork exits closed.

Later Z6–15 must not turn into 50 seconds of empty return travel. Keep original 60s clock and baseline walk feasibility; compact band length/return links before building deeper rows. Current road-length/speed arithmetic is only a paper constraint. Do not import later 41.5 carry speed to rescue a route that requires stat purchases. Both maps are required release content; prove one Meadow Z1 parry/steal/bank/reveal and one Cave reflector variant before mass-producing the ten-zone set.

## Reuse and real integration cost

| Inspected foundation | Keep | New work / limitation |
|---|---|---|
| [Keeper client](../slice-v2/prototype/Keeper.client.luau), [KeeperAttacks](../slice-v2/prototype/KeeperAttacks.luau), [Arena](../slice-v2/prototype/Arena.luau) | Guardian animation/FX, locked dash/projectile/slam primitives, wall-stun and hit/drop path | No player parry yet. DashTell=0.5s, SlamLand=0.8s, DashStun=1.55s are current source values, not this design's 1.2s+ / 3.6s contract. Need attack IDs, latch, timestamp validation and stun arbitration. There is no `Keeper.luau` file. |
| [RaidSlice](../prototype/meadow-v4/RaidSlice.luau) | Tell1.5s, client Warning1.2s, Charge0.45s, Recover1s, two serial lanes, raidItem once/cargo, readiness/mercy/tunnel cancellation | Scope to map/zone/cargo and global coordinator. Existing S2/S5 coordinates are old Meadow; author local sockets. Current vault interpolates after Jump; native low rail is not already proven. |
| [Outsmart](../prototype/meadow-v4/Outsmart.luau) | Bait-cover motif, broad route and return cues | Geometry/cues do not implement parry. No additive wall+parry stun or invisible guaranteed nest shortcut. |
| [Greybox server](../slice-v2/prototype/Greybox.server.luau), [config](../slice-v2/prototype/GreyboxConfig.luau) | 2s Steal, original60s cargo clock; predictable movement | `rules.active`/global attributes assume singleton cargo; concurrent sources and two roads need refactoring. Server speed rewrite means gear is not a free config add. |
| [Domain](../prototype/core/Domain.luau), [Profiles](../prototype/core/Profiles.luau) | Existing pet income/open/collect, capacity validation and serial save/receipt lifecycle | Generic relic presentation/type, versioned per-zone rates, map clears/crown stamps and cap-eight replacement are new. Save uncertainty cannot announce an owned reward or duplicate a clear. |
| [Dependency ledger](../prototype/core/Packages/README.md) | Existing ProfileStore Apache-2.0 and RbxUtil MIT foundations; retain notices | No external code/assets adopted. Named games are design comparisons, not licenses to copy their art/code. |

Cost: medium–high overall even with reused geometry; parry + multi-cargo authority + persistence are not a cosmetic patch. No date/day estimate before one accepted slice.

## Reference arena — compare the actual payoff

| Best-in-class bar for this task | Their strength, from supplied study/research | Our proposed transfer / honest gap |
|---|---|---|
| Steal an Egg — steal/run clarity | Sleeping guardian, held object, wake cue, safe line | Prominent cargo and obvious home direction. Our required pre-steal parry adds friction; reject it if novices cannot explain the flash and theft. |
| Pixel Blade — defensive timing | Warned attack → timed block → visible vulnerability | One parry → stars → steal, with no damage follow-up. Current input/network feel and matched footage comparison UNKNOWN. |
| Pet Sim99 — next-area aspiration | Visible themed area/reward progression | Next zone's pattern silhouette and actual earner floor shown in-world; no machine/UI stack. Our skill ladder still needs repeat-play evidence. |
| Steal a Brainrot — visible owned income | Safe home earner/rate/collection make progress legible | Pet and relic both visibly earn; banked collection safe. Crown stamps cannot substitute for a useful earner. |

One phone-shaped muted clip should show warning, tap, stars, stolen object, route choice, bank and actual income. Compare side by side with owner-supplied reference footage before scaling. This document supplies no gameplay capture and does not claim to match those games.

## Three blind critics

Three separate context-isolated AI critics received anonymous X/Y/Z proposals, fixed owner constraints and reference bars, without this recommendation or each other's verdict. Simulated lenses, not real children or professional interviews; document judgments only. X = pattern-first with bounded raids, fixed clock, shared pet/relic income and crown stamps; Y = squad/short-clock pressure with stat gear; Z = stealth/weight/hazard pressure with milestone pets and cosmetics. Each retained the approved parry and two roads. All scores INFERRED.

| Critic | X /10 | Y /10 | Z /10 | Finding |
|---|---:|---:|---:|---|
| TikTok-age player | 8 | 5.5 | 6.5 | X wins the readable parry→grab→escape clip. Change visible patterns, not just timing; Y looks upgrade-gated, Z obscures failure. |
| Retention designer | 8 | 4 | 6 | X best connects mastery, next zone and safe income. First earner<120s unproven. Show relic income vs crown stamps; guarantee useful first successful reward. |
| Codebase engineer | 8 | 3 | 5 | X reuses finite raid exclusions and persistence. Independently checked RaidSlice/Arena/KeeperAttacks/Outsmart/Domain/Profiles excerpts: relics need schema work, parry is new, zone modules are not finished content. |

**Selected plan: X; all three ranked X > Z > Y.** Adopt player correction (visibly different patterns), retention correction (first successful Pup/clear income, not milestone-only earner), engineer correction (preserve raid/guardian/tunnel/stun exclusions; generic relic schema is new), and a timing floor of260ms after Z5 rather than the blind packet's240ms. Preserve client-readiness fairness without allowing missing acknowledgments to bypass progression; readiness abuse needs server-side handling. Keep gear out of v1. Scores apply to the original candidates, not a claim that the revised tuning was rescored. No combined “fun score,” retention forecast or runtime acceptance.

## Future acceptance — no tests run here

1. One representative Meadow moment first: baseline phone controls, parry→2s steal→return fork→bank→Pup income. Zion checks the actual moment before multiplying zones. Then one Cave reflector/landing moment, then full two-road release set. No place implementation is authorized by this design task.
2. Measure fresh players' first-attempt parries/banks by zone, first secured reward<30s and first income<120s; report everyone, including source contention, abandonment and failure. Time the complete home loop. Existing doc targets disagree on loop length; record actual travel, encounter and reveal components before choosing pacing.
3. Check muted and audio phone captures, touch cooldown visibility, 30fps device target, server/client timing disagreement and normal measured latency. Actual device/model and acceptable latency budget UNKNOWN. Widen windows/fix prediction if needed; never call server-only static timing proof of phone fairness.
4. Future meaningful checks: early/late/stale/future parry intent; simultaneous block/hit/drop; multi-beat cancellation; two players parrying same attack; no stun refresh from wall bait; full warning after recovery; mercy/raid/terrain overlap; eight entrants split roads; source starvation; same ID/deadline across recovery; secure/expiry ties; disconnect; uncertain/retried save; old-rate migration; crown duplicate receipts; full-capacity pet/relic replacement.
5. Compare failure and success clips against the named references; watch novice solo, practiced solo and real 2/8-player runs. No general combat, no paid advantage, baseline completion viable, both return lanes never closed. Static contracts/build checks, runtime, device, fun and Zion verdict stay separate. Independent Claude live/design review remains pending; these AI critic personas do not impersonate Claude.

## Lessons

1. When difficulty needs to be learnable, change a visible pattern before shrinking its timing, because players must understand the correction after a loss.
2. When rewards should include more than pets, reuse the earning-slot contract for relics, because another economy/gear tree would delay the core loop.
3. When launching two maps, scope threats and cargo by map/zone/ID, because duplicating a singleton guardian cannot provide fair concurrent play.

**Owner question: approve v1 rewards as earning pets/relics + Coins + crown shelf stamps, with stat gear deferred?**
