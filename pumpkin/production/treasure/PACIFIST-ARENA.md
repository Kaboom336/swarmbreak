> **2026-10-18 — OWNER-APPROVED UPDATE:** Zion approved Crown Road zones + one warned guardian PARRY/STUN move, then steal and escape; **no general player attacks, damage/kill combat or kill rewards**. Two maps at release. This supersedes older no-parry/input recommendations below; other new tuning/reward choices remain INFERRED. See [Difficulty + rewards arena](DIFFICULTY-ARENA.md) and [phone summary](DIFFICULTY-ARENA-SUMMARY.md). Design only; no place edits or Studio Play.

# Pacifist arena — Steal a Treasure

2026-10-15 · Design only · No implementation or commit

**Recommendation: Outsmart as the identity, Daredevil as the payoff, Sneak as the opening beat.** “I tricked the Keeper and barely escaped” gives running a purpose without turning the game into combat. Build one Meadow moment for Zion to judge before adding more tricks or movement controls.

## Evidence and boundaries

- **CHECKED:** [GDD](GDD.md), [launch roadmap](ROADMAP-TO-LAUNCH.md), [Keeper attacks, including reviewer kit v4](../models/meadow-keeper/ATTACKS.md), both [Hermes refs](hermes/REFS.md) and [content](hermes/CONTENT.md), and [HANDOFF-NOW](../HANDOFF-NOW.md). Inspected current config, item rules, guardian/attack/decoy modules, tunnel policies/production adapter, ravine policy and cave cart source, listed below. These support reuse estimates; they are not new runtime tests.
- **OWNER-REPORTED:** we do not attack the enemy; no hide spots because they stall the chase; Steal an Egg's sleeping guard **ZZ → ! → RUN** works. The sleeping-guard observation comes from the supplied brief, not an independently verified Hermes observation. Handoff reports earlier Studio passes, then later presentation changes requiring reruns. Current fun/mobile/multiplayer acceptance is **UNKNOWN**.
- **SOURCE CONFLICTS:** GDD still contains a 1s steal, old map dimensions and a first-hit-retain proposal. Current `GreyboxConfig` has **2s Steal**, **60s Escape**, Meadow v4 **352 × 352**, and first-hit retention disabled. Use the user's 2s steal and current knock-drop systems for this arena. Roadmap's “core loop not built” is older than the handoff's core-loop completion. Hermes CONTENT's hiding grass, grip/breath/heat meters, boss bar and long cutscenes are suggestions, not accepted scope.
- The exact Keystone **Roblox Process Playbook** was not available in checked local sources. Apply the supplied lessons and handoff; do not claim the original was read. Reference links below are attributed to Hermes, not newly watched footage or freshly verified pages.
- **ALL new mechanics, numbers, rankings and fun predictions below are INFERRED proposals.** No measured retention, cost in hours, virality or success-rate claim. Relative cost means integration surface on inspected code.

The invariant is **escape before 60s**, with the portal usable immediately. Timer begins at completed nest Steal; the same item/deadline survives knock-drop and PvP handoffs. No trick refreshes it. Keep reachable drops, pickup settle, shared mercy, safe apron and server authority. No forced minute of survival, required hiding, HP bar, enemy damage, KO reward or attacks by the player. Existing PvP Bump stays a brief cartoon treasure contest; this is pacifism toward the Keeper, not removal of all player conflict.

Every threat keeps a visible and audible tell, including dash, tunnel hazards and any new terrain reaction. No cancelling or retargeting committed attacks. Keep an ordinary walking route that works without a trick, bonus or extra movement button.

## A — Sneak

**Fantasy:** the cheeky treasure thief who gets close without being noticed, then bolts.

| Concrete mechanic | Existing fit / proposed change | Relative cost |
|---|---|---|
| 1. Nap and short patrol | Empty nest approaches alternate visible nap/patrol states. ZZ changes to ! on detection; successful 2s Steal always wakes the Keeper and starts RUN. Never wait for a sleep phase to permit Steal; do not put an active chase back to sleep. | Medium: pre-steal state transitions and animation; existing Warn/Chase reused. |
| 2. Readable sight cone | A restrained ground wedge shows facing/detection while approaching; hard cover actually blocks sight. Wedge cannot see through rocks. Once treasure moves, normal search/chase and tunnel interception remain. | Medium: facing-aware detection and matching presentation; existing sight checks are only a foundation. |
| 3. Surface noise | A loose-board patch visibly rattles and turns an idle Keeper toward its last sound point. Walking around it is the quiet choice; no crouch, stamina or noise meter. Noise alone never launches an untold attack. | Medium: authored zones and bounded investigation, no global sound simulation. |
| 4. Distraction throw | After the existing trap unlock, one tossed bell lands on a valid pre-steal placement floor. It replaces that entry's Decoy charge, with the same arm/rattle/investigate/immunity rules. No direct hit, mid-chase spam or projectile weapon. | Medium: arc/landing validation and touch aiming added to existing Decoy lifecycle. |
| 5. Sneak bonus | A cosmetic “Clean steal” stamp for reaching pickup without prior detection. It grants no Coins, odds, speed or extra time; Steal itself wakes the Keeper. Shared patrol means rivals may spoil the attempt, so this is optional personal flair. | Low–medium: detection history plus result feedback. |

**Fun moment:** tiptoe around the noisy board, complete the hold beside a snoring giant, see !, run through the tunnel and choose an exit while he circles above. Tunnel is a route with mud, warned hazards and interception, never a stealth shelter.

**Kid-friendly:** expressive surprise and mischief; no weapon, injury or punishment for being spotted. Getting noticed changes the chase, not the player's health.

**Risks:** waiting for naps can replace playing; cones/noise add rules before the first reward; friends can wake the shared Keeper to spoil “clean” steals; reliable sleep makes theft automatic. Keep Steal available, bonuses cosmetic and no reset-to-sleep exploit. If players wait instead of attempting the hold, cut patrol timing and keep only the readable wake beat.

**Reference bar:** [Hermes §1–2](hermes/REFS.md) names **Steal An Egg** as the closest guarded-steal/hatch loop ([community source retained by Hermes](https://roblox.fandom.com/wiki/And_Collect_Rare_Pets/Steal_An_Egg)). The **ZZ → ! → RUN** comparison is owner-reported. Cones, noise, thrown distraction and a sneak bonus are **inferred adaptations**, not mechanics established by that source. Against the reference, this direction wins only if the extra stealth choices preserve its immediate clarity.

## B — Outsmart

**Fantasy:** the small clever runner who makes the big Keeper outplay himself.

| Concrete mechanic | Existing fit / proposed change | Relative cost |
|---|---|---|
| 1. Bait the dash, get stars | Run toward existing solid cover, read the locked dash lane, then cut aside. Keeper bumps it and gets the existing 1.55s wall-stun/stars. Emphasize a soft bonnet wobble and annoyed recovery, not pain. | Low: existing `KeeperAttacks` Blockcast/wall-stun and FX; clarity/tuning pass. |
| 2. Ravine-edge feint | Cut across an existing recoverable crossing while his committed straight dash brakes at the lip. He takes the legal route around; no push, bottomless fall or extra edge stun. Player mistakes still use reachable treasure drops/climb-out. | Low–medium: readable existing no-floor stop and path resumption; geometry-specific validation. |
| 3. Mud slip | Later, a clearly marked open mud strip slows the pursuing Keeper briefly with a boot skid/dizzy pose, then lets him resume. Player takes the dry bypass. No knockdown or automatic drop; trigger only outside committed attacks. | Medium–high: tunnel mud currently affects players; Keeper surface response is new. Do not repurpose the tunnel into a guardian mud trap. |
| 4. Bait the bell | Place the existing Decoy before pickup, then steer pursuit within its trigger range and leave via a cross-link. Existing 1.2s rattle → 2s investigation; committed attacks finish first and 8s immunity prevents a bell chain. | Low: current trap/guardian states; improve readable cause and effect. |
| 5. Loose rope / open cage trick | Later alternative to the bell using the same one-charge budget: a visible rope briefly slows Keeper legs, or an open-sided wicker cage snags his hat. It falls away automatically; no sealed imprisonment, collision wall or player effect. Suggested cap: 1s slow, then the existing Decoy immunity; mutually exclusive with bell effects. | High: new authoritative status and cleanup/animation. Existing placement validation reused, existing Sticky is not a ready guardian slow. |

**Fun moments:** Keeper commits, you sidestep, his hat spins, your rival runs past the same corner and you race for the fallen acorn. Or the bell rattles behind him just as you switch from the ravine route to the tunnel. In later Cave, cart travel can carry the getaway beat; it never rams the Keeper.

**Kid-friendly:** tricks interrupt pursuit briefly; the Keeper stays standing or recovers comically and continues. No hurting, kicking a trapped character, enemy fall spectacle or loot for causing harm. Rope/cage visuals are deferred partly because confinement reads less friendly than a fooled bell investigation.

**Risks:** stun loops turn the enemy into furniture; many decoys trivialize solo runs; redirecting pursuit toward another thief can grief; chokepoint traps can guarantee a Bump. Preserve global Decoy immunity, one-charge caps, broad placement bypasses and existing mercy. Do not reward tricks against other players. Edge stops gain no wall stun. If a corner repeatedly neutralizes pursuit, adjust that corner/attack cadence before adding another trap. Keep mud and rope/cage out of the first slice.

**Reference bar:** [Hermes §3](hermes/REFS.md) supports readable windup/recovery/stun as a design language; its **Deepwoken** citation is a community combat source, not proof of a pacifist trick system. **Steal An Egg** supplies the simpler steal/run bar. Bells, mud and edge feints are **inferred**, with no Hermes game demonstrating this full package. Our existing wall-stun is the concrete reuse advantage. Compared side by side, a trick must explain itself as quickly as the reference's wake/run beat; otherwise simplify it.

## C — Daredevil

**Fantasy:** the runner who escapes by inches and makes friends say “how did you live?”

| Concrete mechanic | Existing fit / proposed change | Relative cost |
|---|---|---|
| 1. Near-miss style points | A small “Close!” pulse for escaping an actual attack envelope without an accepted hit. Award once per attack/player; exclude safe apron and mercy/shield immunity. Show run-local style, no currency or power. | Medium: authoritative attack IDs, miss eligibility and presentation; proximity alone is not reliable proof. |
| 2. No-hit escape bonus | Cosmetic “Untouched” escape stamp if the same carrier takes no accepted guardian hit from original Steal to secure. Any drop/handoff invalidates it; PvP loss never removes base rewards. No extra pet odds, Coins or stats. | Low–medium: per-run bookkeeping and one result stamp. |
| 3. Dodge-roll / slide | Later test one brief directional slide on normal floor, sharing one control across devices. No invulnerability, speed stacking, attack collision bypass or animation-based hitbox shrink. Slam still uses the normal jump; slide is optional repositioning. | High: collision, ledges, carry pose, authority and touch/controller controls. Explicit proposal to reopen GDD's no-dash vocabulary, not an accepted requirement. |
| 4. Distinct-move combo | A compact three-segment run-local chain: evade a fan/log, jump a slam, make a route cut. Repeating the same attack type does not fill it; accepted hit/drop resets it. At cap, stop counting. Never require waiting for attacks, and never attach earning rewards. | Medium–high: event classification/UI; farming risk remains even without money. |
| 5. Clutch route endings | Existing ravine recovery, tunnel exit interception and later Cave cart jump give the spectacle. A tiny “Just in time” result can mark a naturally late secure; no extra reward for delaying. Keep normal camera/control during pursuit, no forced slow motion/replay. | Low for feedback; medium for route fairness checks; Cave integration is separate work. |

**Fun moment:** jump the amber rim, cut out of the red log ring, recover a drop near the ravine and enter cyan safety with the clock nearly gone. In Cave, switch/ride/jump the existing cart while retaining cargo identity; the cart is not already part of Meadow's secured loop.

**Kid-friendly:** mastery is moving and recovering, with no attack input. Never use “one HP” copy: this game has knock-drop, not a health survival system. Style celebrates successful movement rather than hurting a rival.

**Risks:** score farming keeps carriers circling until expiry; roll makes every attack too easy; touch players lose to control complexity; compulsory precision excludes novices; a Bump can spoil a perfect run. Make stamps optional, cap style, preserve normal-route completion, and cut combo before adding a permanent meter. Start with existing jump/cutback skill, not a new slide button.

**Reference bar:** [Hermes §4](hermes/REFS.md) records **Escape Huss Valley** sprint from its [official listing](https://www.roblox.com/games/125215626986308/Escape-Huss-Valley); slide/vault claims are secondary. **Roblox Parkour** tutorials are movement-language references, not verified proof of this scoring system. Near-miss scores, combos, no-hit stamps and their fun are **inferred**. [Hermes §5](hermes/REFS.md) supports immediate danger/twist/payoff clip framing; it does not prove organic TikTok success. Compared with Huss Valley, extra movement must earn its control cost; compared with Steal An Egg, never bury the stolen treasure under scoring UI.

## Arena: judge the moment, not the feature count

Blind review protocol: an independent critic received anonymous X/Y/Z mechanic bundles, the 60s/fairness constraints and reference files, without author identity or this recommendation. X maps to A, Y to B, Z to C. This is document judging, not a blind playtest or proof of fun. No fabricated numerical scores.

| Direction | Against Steal An Egg's immediate steal/run clarity | Against readable telegraph/recovery and movement refs | Against our 60s escape | Design verdict |
|---|---|---|---|---|
| A Sneak | Wake beat is excellent; cones/noise/throws slow teaching. | Adds planning, but little new payoff once cargo moves. | Good only as a short, optional approach; hiding/waiting undermines the chase. | Keep wake language; defer stealth simulation. |
| B Outsmart | One visible bait/recovery can read with almost no tutorial. | Uses our real locked dash/recovery instead of copying combat systems. | Brief pursuit setbacks create route decisions; chains would trivialize it. | Best identity at limited scope. |
| C Daredevil | Immediate running fits; meters compete with treasure/portal. | Strong movement spectacle; new roll needs evidence beyond reference name. | Existing evasions fit; score loops incentivize staying. | Best payoff layer; cut farming incentives. |

**Independent blind verdict: Y → X → Z, therefore B → A → C.** The critic chose one trimmed wall-bait encounter; found overlapping stealth detection rules costly for novices; and rejected near-miss farming, extra controls and stacked slows before chase feel is proven. They recommended wall bait, safe-route/ravine choice, and existing Decoy reuse as the first three changes. They specifically warned that no-hit stamps can feel unfair when PvP causes failure. The table above is the author's comparison; the independent verdict is document review only. Accepted correction: move cosmetic stamps behind route fairness, retain C's clutch movement as the payoff without adding scores now.

## Three highest-value changes to build first — proposed next work only

1. **Make one wall-bait moment legible.** Reuse the existing locked dash, wall stop, stun and stars at one existing broad cover corner, with walking bypass and clear route to cyan. Teach by motion, not a new UI panel. Do not add mud/rope/cages yet. Value: the player deliberately outsmarts the Keeper using mechanics already present.
2. **Make the existing safe-route/ravine choice clear and fair.** Use route signs and readable landing/recovery cues, then tune the current pursuit only if tests reveal a permanent edge stop or unavoidable catch. Preserve the no-trick walking option, reachable knock-drops and tunnel exit choice. Value: the player escapes through a decision, including under PvP pressure, rather than exploiting a stuck Keeper. No new map or mandatory jump.
3. **Make the existing Decoy payoff unmistakable.** Improve bell rattle, Keeper head turn, question-mark investigation and route-switch readability using its current pre-steal unlock, timing and immunity. No distraction-throw control yet. Value: a real planning choice after basic escapes, without another gameplay system. Keep A's ! → RUN language in the existing warning presentation; an actual nap schedule and C's cosmetic stamps can wait.

**One slice before many:** compare one actual 2s steal → bait → portal recording beside Steal An Egg's owner-supplied wake/run example; compare its danger visibility with the Hermes telegraph bar. Zion checks that slice before mud, slide, new islands or more traps. No map rebuild is proposed here.

Future acceptance: watch a novice solo, skilled solo and a two-player Bump contest on the same route. Record steal-to-secure times, misses/hits, drops, time spent deliberately waiting and why each trick triggered. Inspect a failed run too. Verify no-trap walking escape, no repeat-stun corner, no timer refresh on handoff, safe recovery at ravine and no tunnel camping advantage. Check muted phone-sized video for readable tell → choice → recovery → escape; runtime/phone/fun remain UNKNOWN until done. Use existing Loop/PvP/Trap/Ravine/Tunnel suites when implementation eventually occurs; passing those alone does not prove enjoyment.

## Reuse ledger and lessons

Inspected foundations: [config](../slice-v2/prototype/GreyboxConfig.luau), [item rules](../slice-v2/prototype/LootRules.luau), [Arena](../slice-v2/prototype/Arena.luau), [KeeperAttacks](../slice-v2/prototype/KeeperAttacks.luau), [Traps](../slice-v2/prototype/Traps.luau), [TunnelPolicy](../prototype/meadow-v4/TunnelPolicy.luau), [production tunnel adapter](../prototype/meadow-v4/ProductionTunnelController.luau), [RavinePolicy](../prototype/meadow-v4/RavinePolicy.luau), [Cave cart](../prototype/cave-v2/Cart.server.luau). Tunnel already has player mud, warned falling hazards, escalating rumble and a surface Keeper exit intercept. Cart source explicitly has no ram/blast damage; do not infer secure-loop integration from that. No external code/assets adopted, no new licence dependency; external references are comparisons, not assets to copy.

1. When the core is pacifist running, make enemy commitment create a player choice, because a visible mistake is more expressive than adding a player attack.
2. When escape has a deadline, reward completion quality rather than time spent near danger, because uncapped style encourages stalling.
3. When a mechanic sounds new, inspect existing states first, because wall-stun and bell investigation already supply most of the trickster fantasy.
