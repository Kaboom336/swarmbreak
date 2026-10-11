# Game Theory Checklist: Roblox simulator / steal-a / pet-collection games

Scoring: 0-10 per item (0 absent, 5 works but weak, 10 matches the best reference game). Test = what to do in a playtest. Targets are design heuristics unless marked [src].

Sources used (credibility noted):
- Roblox Creator Docs, analytics and engagement (primary): https://create.roblox.com/docs/production/analytics/engagement . Key claims: D1 retention and average session time are the first metrics to fix; New User First Session Retention chart measures FTUE; high D1 retention makes recommendation/featuring more likely; join/leave friction is very low so first impression is critical; do not gate progression so hard that new users cannot have fun in session one.
- Roblox acquisition/analytics overview (primary): https://create.roblox.com/docs/production/analytics/acquisition and https://create.roblox.com/docs/production/analytics
- Variable-ratio and pity overview (secondary, mixed quality): https://abratabia.com/game-economy/loot-and-gacha.php , https://dl.digra.org/index.php/dl/article/download/2731/2717/2777 (DiGRA paper on gacha motivation). Pity = bounded cost; rarity tiers 4-6; show odds.
- Juice/game feel: Nijman "Art of Screenshake" (https://www.youtube.com/watch?v=AJdEqssNZ-U), Jonasson/Purho "Juice it or lose it" (Nordic Game Jam 2012), Swink "Game Feel".
- Hit-simulator case studies (low-to-mid credibility, figures unverified): https://rolearn.dev/case-studies/brainrot-game-meme-culture-25m-ccu , https://rolearn.dev/insights/grow-a-garden-ccu-record-analysis . Takeaway: Steal a Brainrot was meme/virality-led and faded fast; Grow a Garden layered plant/grow/harvest/trade/restock and held players. The D7 figures (about 6% vs 28%) are from one site only; treat as indicative.
- Local internal evidence: ROBLOX-HIT-GAME-BIBLE (5 systems to learn, 1 clock in first 10 min), our own econ-sim.

NOTE: I did not get DevForum postmortem text (not indexed by search); DevForum claims below come from the bible and the case-study sites.

## A. LOOP (L)
| # | Principle | Why | Playtest test | Target |
|---|---|---|---|---|
| L1 | One core verb, first reward under 30 s | Roblox join friction is near zero; leave fast if no fun [src Roblox docs] | Stopwatch from spawn to first candy/pet | <30 s to first reward, <2 min to first earner |
| L2 | The most-repeated verb must pay meaningfully (active verb share of income) | If the main verb is decoration, the loop is hollow (PS99 breakables, GaG harvest) | Read income log: share from active verb | 20-50% of income from the active verb at every zone |
| L3 | Loop closes in 60-120 s: acquire, risk, bank, upgrade | Short cycles give many reward beats per session | Time one full steal-carry-place-hatch cycle | 60-120 s; no more than 30 s of pure travel |
| L4 | Always one clear "next thing to buy" within 1-3 min | Removes idle/dead zones | Log candy vs next cost every 10 s | Next purchase affordable in <=3 min at all times; no flat income >3 min |
| L5 | Second-order loop (compulsion) exists: upgrade makes loop faster, which funds next tier | Compounding is the hook after minute 5 | Check that each upgrade visibly changes cycle time or yield | Each tier >=1.5x yield or 25% faster |
| L6 | Idle/AFK is safe-but-slow, active is clearly better | Prevents both punishing breaks and botting | Compare AFK vs active income | Active >=2-3x AFK |

## B. PACING / ECONOMY (P)
| # | Principle | Why | Playtest test | Target |
|---|---|---|---|---|
| P1 | Power curve: each zone/gate arrives at roughly geometric spacing | Keeps a new goal on the horizon | Run econ-sim; record arrival minutes | Gates at about 3/10/18/30/48/75 min (ours); gap between gates <=8 min in the first 30 min |
| P2 | Sources and sinks balanced; late sinks scale with income | Candy hoards (228k idle) mean sinks are missing | Plot candy balance over 30 min | Balance never exceeds ~2x next cost |
| P3 | Depth reward: deeper zone clearly better (3-10x per zone) | Gives exploration a reason | Compare income per zone | 3-10x income step per zone |
| P4 | Variable-ratio rewards (rare drops, golden/mutation) on top of a steady base | VR schedules give persistent response rates [DiGRA paper above] | Count surprise events in 10 min | 1 notable surprise per 60-120 s; rare spikes at 1-3% |
| P5 | Pity / bad-luck protection with visible counter | Bounds worst case; pity costs designer almost nothing | Check guaranteed-drop rule exists and UI shows count | Guarantee rare within ~5-10 attempts at boss tier; visible "N to go" |
| P6 | Odds disclosed for any random pet/crate | Fairness; legal in many markets; Roblox requires odds disclosure for paid random items | Find odds screen | 100% of random items show percentages |
| P7 | Events pay more than baseline (boss, weather, mutations) | Appointment events must beat just farming | Compare 20 min of event vs farming | Event reward >=3 min of income and something exclusive |

## C. ONBOARDING / FTUE (O)
| # | Principle | Why | Playtest test | Target |
|---|---|---|---|---|
| O1 | Teach the real verb first (the one that earns) | Wrong first verb wastes minute 1 | Watch a naive player 60 s, count what they do | First tutorial step = money-making verb, done in <20 s |
| O2 | Zero popups and zero loss in first 60 s | Roblox player base is young/low patience | Count modals in first 3 min | 0 popups, 0 ways to lose in first 3 min |
| O3 | Systems introduced one at a time: <=5 to learn, <=12 visible HUD elements, 1 clock in 10 min | Cognitive load; bible target | Count new nouns/buttons in first 10 min | <=5 new mechanics, 1 timer |
| O4 | Guided arrow/waypoint, not text | Kids skip text | Does a first-timer reach step 3 unprompted? | >=80% of testers complete tutorial unaided |
| O5 | No progression gate before ~5 min that blocks fun [Roblox docs] | Keeps the first session fun | Time to first wall | First hard gate >=3 min in, cost reachable |
| O6 | First pet/hatch reveal is fast then escalates | Early dopamine, then save big reveals | Time of first hatch | First hatch <=3 s wait; rare reveal bigger than common |
| O7 | Measure the funnel: first-session retention chart, D1 | It is what Roblox ranks on [src] | Check analytics events exist | Targets: D1 >=20% okay, >=30% strong (heuristic) |

## D. RETENTION (R)
| # | Principle | Why | Playtest test | Target |
|---|---|---|---|---|
| R1 | Return hook: offline income or "while you were away" card | Gives a reason to rejoin; GaG grows offline | Leave 30 min, rejoin | Pays 25-50% of rate, capped 2-8 h, shown on a card |
| R2 | Daily reward with streak, in hub only, never mid-action | Appointment mechanic; interrupts hurt | Trigger daily mid-run | Shows only when idle/safe; reward scales with income |
| R3 | One appointment event on a visible single timer | Predictable reasons to be present | Read HUD for clocks | One chip: next event; events every 5-20 min |
| R4 | Restock / refill timers (GaG-style) | Strong session-return loop | Check a restock exists | 5 min cycle for the main shop/nest |
| R5 | Session length hooks: always a partial progress bar near completion | Zeigarnik-style "almost there" | Does HUD show % to next gate? | Always-on progress bar |
| R6 | Content cadence: update every 1-2 weeks | Case studies tie CCU floor to updates (weak source) | Roadmap | Update every 7-14 days |

## E. SOCIAL (S)
| # | Principle | Why | Playtest test | Target |
|---|---|---|---|---|
| S1 | Steal/raid is opt-in or protected early | Loss on new players causes churn | Join as new player; count losses before 15 min | 0 losses before 15-30 min |
| S2 | Loss is capped, recoverable and counterable (lock, shield, guard) | Loss aversion is ~2x gain; unfair loss = quit | Lose an item on purpose; ask how it felt | Max loss <=1 item/<=5% income; always a visible counter |
| S3 | Visible others: leaderboards, shared boss, pens visible | Social proof and showing-off drive virality | Count players seen in lobby | Shared boss or board visible in <2 min |
| S4 | Thievery reward is spectacle (screen-recordable) | SaB virality was clip-driven | Record 10 s of steal: shareable? | A clip-worthy moment every 2 min |
| S5 | Cooperation moments (boss fights) with clear contribution UI | Boosts retention vs pure PvP | Fight with 3 testers | Fight lasts >=60 s; each player sees own damage |

## F. FEEL / JUICE (F)
| # | Principle | Why | Playtest test | Target |
|---|---|---|---|---|
| F1 | Every core action has 3+ feedback channels: sound, particles, number, camera/hit-pause | "Juice it or lose it"; Nijman screenshake | Mute test and no-VFX test | Each hit: sound + burst + number + 40-80 ms hit-pause; crit adds shake |
| F2 | Numbers merge, not pile; one combo counter | Overlap kills readability | Spam attack 10 s | <=1 floater per hit; merged within 0.3 s |
| F3 | The highest-value moment (bank/hatch) is the biggest juice | Reward moment must peak | Compare delivery vs normal hit | Delivery > hit in intensity; 0.5-1.5 s of celebration |
| F4 | Animations/visual tiers readable at play distance | Tier progression must be seen | Screenshot at default camera | Tier difference visible from 30 studs |
| F5 | Input responsiveness | Game feel is input-perception loop (Swink) | Swing, measure delay | Swing starts <100 ms after click; mobile touch target >=44 px |

## G. CLARITY / COGNITIVE LOAD (C)
| # | Principle | Why | Playtest test | Target |
|---|---|---|---|---|
| C1 | HUD hierarchy: main currency biggest | Eye goes to money | 5 s glance test: what number do they report? | Candy largest text; >=14 px secondary |
| C2 | Context-aware objective line | Static text is ignored | Read header in 5 states | Changes with state; always actionable |
| C3 | One toast queue, dedupe | Overlap confuses | Trigger 3 events fast | <=2 lines, dedupe 3 s |
| C4 | Silhouette/colour consistency: what is smashable/stealable reads instantly | Legibility of the identity verb | Show screenshot to 3 strangers: "what do you smash?" | 3/3 answer correctly in 3 s |
| C5 | Collection index: completion %, hints for unknown slots, milestone rewards | Completionism; "???" with source hint | Open index | Hints on every ??? slot; rewards at 25/50/100% |

## H. MONETIZATION ETHICS (M)
| # | Principle | Why | Playtest test | Target |
|---|---|---|---|---|
| M1 | Sell speed/cosmetics, not required progress; free path viable | Fair feel; Roblox policy sensitive to minors | Play free for 30 min: still fun? | Free player reaches zone 3 in first session |
| M2 | No countdown pressure or FOMO traps on minors; no fake scarcity | Ethics and policy | Review all timers on offers | No offer timers <24 h except real events |
| M3 | Paid random items disclose odds and have pity | Fairness, Roblox requirement | See P5/P6 | 100% disclosed |
| M4 | No purchase prompt in first 5 minutes or mid-chase | Trust, retention | Count prompts | 0 in first 5 min |

---

# APPLIED: "Steal a Pumpkin" scores (from FINISH-PLAN.md, AUDIT-GAMEPLAY.md [playtest 2026-10-10], AUDIT-R2.md)

Evidence is from audits, not fresh play; some audit findings may already be fixed by the config changes in AUDIT-GAMEPLAY section 5 (not verified here).

| Item | Score | Evidence |
|---|---|---|
| L1 | 5 | first earner 0:10 good; first smash at 80 s+ idle |
| L2 | 1 | smash = 1% of income (G1) |
| L3 | 4 | 700-stud runs, guard chase ends in 6 s (A17, A33) |
| L4 | 3 | 7-min flat dead zone, 318k gate |
| L5 | 3 | scythes buy nothing that matters |
| L6 | 4 | idle shield hit twice; AFK not compared |
| P1 | 4 | gates 4/15/32 min; proposal fixes to 3/10/18 |
| P2 | 2 | candy hoard 228k |
| P3 | 5 | zone 1->2 good, later walls |
| P4 | 4 | golden pumpkin proposed, not shipped |
| P5 | 3 | pity 10 crates (~200 min), not visible |
| P6 | 2 | no odds screen seen |
| P7 | 2 | King = 8 s of income; fight over in 2 hits (A03) |
| O1 | 3 | tutorial teaches smash first |
| O2 | 5 | daily popup mid-loop, raids at 15 min |
| O3 | 2 | ~20 systems, 3-4 clocks |
| O4 | 4 | text hints only ("Place it!" 15 s stall, A16) |
| O5 | 6 | gate 1 at 5 min is fine |
| O6 | 5 | 8 s first hatch; generic card (A21) |
| O7 | 3 | no analytics noted |
| R1 | 0 | no offline income |
| R2 | 4 | daily exists, mid-loop, 100 candy at 1B (A15) |
| R3 | 3 | 3 clocks |
| R4 | 6 | nests refill exists, unexplained |
| R5 | 3 | gate progress bar missing |
| R6 | 4 | cut list; cadence unknown |
| S1 | 4 | raids target active explorers |
| S2 | 3 | lock is useless/stale text |
| S3 | 4 | King throne not signposted |
| S4 | 5 | |
| S5 | 3 | King fight too short |
| F1 | 4 | thin crescent, no hit-pause |
| F2 | 2 | combo pile-up (A08) |
| F3 | 3 | delivery plain (A32) |
| F4 | 3 | scythe invisible at distance (A09) |
| F5 | 6 | not audited |
| C1 | 3 | HUD inverted (A20) |
| C2 | 2 | static header (A19) |
| C3 | 3 | stacked toasts (A18) |
| C4 | 3 | zones 2-5 blobs (A07) |
| C5 | 4 | index ??? no hints (A12) |
| M1-M4 | 6 | no purchase observed; unverified |

Average of scored items about 3.7/10.

## Top 10 gaps and fixes
1. L2/P2: smash pays 1%. Apply candy ladder (Zone1 8, Zone2 80, ...) plus candy fountain; re-run econ-sim.
2. L4/R5: dead zone and no progress bar. Gates {2.5k, 100k, 900k...}; always-on "next gate %" bar.
3. O1: tutorial order to steal -> hatch -> smash 50 -> buy Iron -> unlock zone; guide arrow.
4. O3/R3/C2: cut to 5 systems and one event chip; hide Fuse, Dash, Lucky, zone quests until later; context-aware objective line.
5. P7/S5: King fight lasts >=60 s, crate always one rarity up, pity 5 with visible counter, banner plus arrow.
6. R1: add offline "while you were away" card (25% rate, 2 h cap).
7. S1/S2: remove ambient raids at launch; Purge hourly after 30 min; ghosts drop candy.
8. F1/F2/F4: hit-pause, bigger scythe, one combo counter, merged floaters.
9. C4/A07: same pumpkin silhouette tinted per zone; fix zone palettes.
10. A01/A02: camera/void escape blockers (kill plane, camera reset) before any other polish; also the C1 HUD hierarchy.
