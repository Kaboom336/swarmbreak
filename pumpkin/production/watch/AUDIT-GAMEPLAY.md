# AUDIT: GAMEPLAY, LOOP, FUN, ECONOMY, ONBOARDING (2026-10-10 launch playtest)

Auditor scope: core loop, first 10 minutes, economy curve, session hooks. Read-only, and no game code was edited.

Evidence:
- **LOG:** `_G.WatchLog` on the Server, player Kabbom336, 10 s samples, 0-941 s of this playtest.
- **REC:** `rec/play_000.mp4`, sampled every 30 s into 3x3 sheets (sheet 1 frames f1-f9, sheet 2 frames f10-f11).
- **CFG:** `giant/src/ReplicatedStorage/PatchConfig.luau`.
- **SRV:** `giant/src/ServerScriptService/Patch.server.luau`.
- **SIM:** `lune run scene/econ-sim.luau`, plus a copy of it in the scratchpad with the proposed numbers. That copy reports farm share per 2 minutes.

## 0. Verdict in one paragraph
Smashing pumpkins, the verb the player does most, pays about **1 % of income** from minute 5 on, in both the sim and the live log. The whole economy is pets: nest steals plus full-pen sales of 20k-53k each. Scythes, the first purchase, therefore buy nothing that matters. Damage only speeds up a candy stream that is already 1 %, and it nudges the guard FIGHT bar. From about minute 8 to minute 16 the player's income sat flat at 314/s (LOG 521-941 s). Candy piled up to 228k, the next gate cost 318k, and the player went idle twice (`IdleShield=true` at 761 s and 921 s). The King fight pays roughly 8 seconds of income plus one pet worth about one nest steal. Ghosts and the Purge punish the one behaviour we want, which is going out into the zones. Around 20 systems show up in the first 10 minutes; the bible's target is 5 to learn.

## 1. First 10 minutes, step by step (this playtest, LOG + REC)
| t | What the player does / sees | New thing to learn | Count |
|---|---|---|---|
| 0:00 | Spawn in the hub. Banner "Smash pumpkins!" HUD: Shop, Index, Teleport, Daily, Settings, candy + rate, carry line, **3 timers** (King in, Spooky Hour in, Midnight in) (REC f1) | HUD, smash order, 3 clocks | 3 |
| 0:00-0:80 | **Does not smash.** Carries a nest pumpkin, idles 30 s+ in the hub at (1482,4,61) (LOG 40-70 s). Income from 1 pup is 4.2/s, and candy reaches 348 without a single swing | carry, place, hatch, pen income | 4 |
| 1:30-4:00 | Smash order "collect 30 candy" crawls 0→9→19→20→27→28→28→28→29 over **150 s** (LOG 90-240 s): about **0.2 candy/s from smashing, against 12.6/s from the pen** | scythe, HP bars, combo, candy pops | 4 |
| 2:50 | Spends 873 (LOG 160→170 s): Iron Scythe and Boots | Shop: scythes, Boots, Stack | 3 |
| 3:50-4:10 | Nest steal → Ghost/Shadow pet, income 12.6 → **75.6** (LOG 240-250 s) | guard chase, crow-dive twist, FIGHT tap bar, RUN!!/Drop | 4 |
| 5:00 | Gate 1,000 paid (LOG 301→311 s), Zone 2 Graveyard | gate, zone 2, Fuse unlock, zone quests button | 3 |
| 5:50-8:40 | More steals, income 151 → 166 → **pen full**: "Pens full! Swap or Sell" (REC f2, f3, f6) | swap/sell prompts | 1 |
| ~8:20 | **King Night** (Kings=1, CleaverSkin at 501 s): fight, lackeys, shield, crate, MVP | boss rules | 3 |
| ~9:00 | Pen-sale jackpots: +24k (591 s), +53k (691 s) | sell value | 0 |
| ~10:00 | Daily Reward popup appears mid-play (REC f6). Banner "Ghosts and players can raid you now! Lock your Base at its sign post!" (REC f5; the admin save has old PlayTime, and the text is stale per R26 #5) | daily, Purge/raids/lock | 2 |
| 10-16 min | Income **flat 314/s for 7 min**, candy 100k→228k, nothing worth buying, idle twice; rotating order "Smash 25 pumpkins 6/25" (REC f10-f11) | (no new hook) | 0 |

**Total in 10 minutes: about 27 things to learn, across about 20 systems.** The bible limit (ROBLOX-HIT-GAME-BIBLE §2h/§7) is 5 to learn, at most 12 visible, and 1 clock. We show 3 clocks, plus a 4th (Purge) once the shield ends. The first earner arrives fine, but the first verb we teach (smash) is the one that does not matter.

## 2. Scores vs references (1-10, ours vs each ref doing the same line)
| Checklist line (bible §3a/§6/§7) | SaE | SaB | GaG | PS99 | Ours | Note |
|---|---|---|---|---|---|---|
| One core verb in minute 1 | 9 | 9 | 9 | 9 | 4 | We teach smash first, but steal is the real verb |
| Reward under 30 s | 9 | 9 | 7 | 10 | 6 | The player idled 80 s before the first smash |
| Earner under 2 min | 9 | 9 | 8 | 7 | 8 | The first pet at 0:10 is good |
| Active verb pays vs passive | 7 (steal = income) | 7 | 8 (harvest) | 10 (breakables = coins) | **1** | Smash is 1 % of income |
| One clear "next thing to buy" at all times | 9 | 9 | 9 | 9 | 3 | 7-min dead zone at 314/s, 318k gate |
| Depth reward (go deeper = clearly better) | 9 (emoji ladder) | 8 (rarer carpet) | 8 | 9 | 5 | Gate 3 is a 17-min wall |
| Boss/event worth showing up for | n/a | 8 (events x mutations) | 9 (weather x mutations) | 8 (raids/eggs) | 2 | King = 8 s of income + 1 normal pet |
| Max 5 systems / 1 clock in 10 min | 9 | 8 | 9 | 7 | 2 | About 20 systems, 3-4 clocks |
| 0 popups on join / 0 ways to lose early | 9 | 6 | 10 | 10 | 5 | The Daily popup lands mid-loop; raids at 15 min |
| Why come back (offline, restock, pity) | 8 (offline line) | 8 (rebirth, lock) | 10 (plants grow offline, restock) | 9 (dailies, ranks) | 3 | No offline income, no visible pity, no restock |
| Why stay 20 min | 8 | 9 | 8 | 9 | 4 | Dead zone at 8-16 min |
| Fear of loss after the shield only | 8 | 9 (core) | n/a | n/a | 4 | Raids punish exploring; the Purge is twice an hour |

## 3. Problem table
| id | What is wrong (specific) | What refs do | Our distinct-style fix (Halloween identity) | sev | effort | simplify/cut? |
|---|---|---|---|---|---|---|
| G1 | **Smashing pays about 1 % of income.** Zone1 small pumpkin = 1 candy (CFG `Zones.Zone1.candy=1`, SRV 3762). The sim reports a farm share of 1 % from minute 6 to 48 (current config). LOG: 29 smash candy in 150 s against 12.6/s pen income | PS99: breakables are THE coin source; GaG: harvest = money; SaE: the active verb (steal) is what earns | Candy x8-x200 per zone (section 5). A smash then pays 7-50 % of income, and every smash makes a candy fountain. Scythes become a real upgrade | blocker | S (config) | no |
| G2 | **Tutorial teaches the wrong verb first.** Step 1 "Smash 30 candy" took 150 s+ (LOG), while the player already carried a nest pumpkin and idled in the hub | SaE minute 1: steal → place → +$5 | Order: 1 Steal a glowing pumpkin → 2 Place it → 3 Smash 5 pumpkins (with G1 this takes 15 s) → 4 Buy Iron Scythe → 5 Unlock Graveyard | blocker | S | merge |
| G3 | **Dead zone at 8-16 min.** Income flat at 314/s for 7 min (LOG 521-941 s). Gate 3 = 318k (CFG `Economy.gateCosts[2]`) at 314/s = 17 min. Pen full at 6, so extra steals only sell | SaE/SaB: next slot/speed price always 1-3 min away; GaG 5-min restock | Gate 3 → 100k (section 5). Smash income now fills the gap; show "next gate 64 % ▓▓▓" on the HUD | blocker | S | no |
| G4 | **King Night not worth it.** `Progress.bossCandy` = 480 s x zone.candy / swings (SRV 8299-8314). For Zone2 + Iron that is about 2.6k = 8 s of 314/s income. The crate tier-1 pet (55 %) is the same pet a 60-s nest steal gives. Kinglet pity needs 10 crates (about 200 min) | GaG/SaB events give rare mutations nobody else has; PS99 raids give exclusive pets | (a) `KingNight.farmSeconds` 1800, which with G1 candy makes the King worth about 3 min of income; (b) `rarityWeights` {0,70,27,3}, so the crate is always at least one rarity above your zone (tier 2+); (c) `pity` 5; (d) show "KINGLET in 4 crates" on the loot board | bad | S | no |
| G5 | **Ghosts punish exploring.** Raid eligibility *requires* the owner to be >60 studs from home and active (SRV 6140-6170), so it hits exactly the kid who goes into the zones. Income pauses until 5 taps. Plus the Purge at :10/:50, plus the stale "Lock your Base" text (REC f5) | SaB: theft is the game, but the lock is free and obvious; SaE: the reset never takes anything; GaG/PS99: no loss | Launch: no ambient raids (`Raid.grace` = 1e9). Ghosts appear only in the Purge, once an hour (`Purge.minutes` = {50}), with grace 30 min. Make ghosts a **reward**: a bonked ghost drops candy = 10 s of income | bad | S | cut/later |
| G6 | **3-4 clocks on the HUD** (King in, Spooky Hour in, Midnight in; REC f1-f11) + the Purge chip | Bible §7: 1 clock (SaE reset 5:00) | One chip: the next event only ("KING NIGHT 4:32"). Midnight becomes "NESTS REFILL" at 5:00 (`DayLength` 255 + `MidnightLength` 45 = 300 s) | bad | S (client) | merge |
| G7 | **Stack upgrade is useless above level 1.** A nest holds `HoardCount`=3 and wild pumpkins are never carried (R20), yet `Upgrades.Stack.max`=10 and the HUD says "Carry 0/5" (REC f1) | SaE: carry fixed | `Upgrades.Stack.max` = 1 (carry 3 = one full nest) | polish | S | cut |
| G8 | **Lucky Swing, Brew, Haunt/skill tree, Fuse, Witch Merchant, Spooky, Dash, Teleport** all exist at launch | Bible: unlock one per update | Hide (section 4) | bad | S | cut/later |
| G9 | **First hatch takes 8 s** (`CarveNewSeconds`=8); SaE's first hatch is instant | SaE 0:50 instant reveal | `CarveNewSeconds` 2 | polish | S | no |
| G10 | **No reason to come back.** No offline income, no visible pity, no restock | SaE: "offline 1 h income" always on screen; GaG plants grow offline | Launch-day add: on rejoin, pay 25 % of income/s x seconds away, capped at 2 h, with a "While you were away: +48k 🍬" card (M, code) | bad | M | no |
| G11 | **Daily popup lands mid-loop** (REC f6, at about 10 min, over the RUN!! state) | SaE free gift at 13:20, in the hub, never mid-chase | Show only when in the hub and not carrying | polish | S | no |
| G12 | **Gate 2 is reached at 2.5-4 min, then the rate barely moves** (Zone1→2 pets 4-17 → 63-76/s is good). The Fuse unlock appears at the same moment | SaE zone 2 ≈ 2:44 | Keep the gate, but hide Fuse until Zone 3 | polish | S | later |

## 4. CUT or HIDE for launch (first session = 5 things: steal, place, smash, shop, gate)
| System | Action | How (config where possible) |
|---|---|---|
| Ambient ghost raids (midnight `raidCheck`) | CUT for launch | `Config.Raid.grace = 1e9` |
| The Purge | LATER: once an hour, never in the first 30 min | `Config.Purge.minutes = { 50 }`, `Config.Purge.grace = 1800` |
| Spooky Hour timer | HIDE the timer, keep the surprise x2 event | client: drop the "Spooky Hour in" line; `SpookyLength` 90 → 180 so it is noticeable |
| Midnight timer | MERGE into one "next event" chip; rename to nest reset | `DayLength = 255`, `MidnightLength = 45` (5:00 cycle) |
| King Night for new players | HIDE the chip/banners until 10 min of playtime (the event still runs) | `Config.Unlocks.King = 600` |
| Brew / cauldron, Lucky Swing | stay hidden (already at 1800) | keep `Unlocks.Brew/LuckySwing = 1800`; set `Upgrades.Lucky.cut = true` |
| Haunt + skill tree, Rebirth | hidden until 50 % of cost (keep) | `Unlocks.HauntPillAt` unchanged |
| Fuse machine | LATER (Zone 3, not Zone 2) | code: `Unlock_Fuse` → hasZone "Zone3" (SRV 7863) |
| Witch Merchant | LATER (Zone 4, already) | keep |
| Stack upgrade levels 2-10 | CUT | `Upgrades.Stack.max = 1` |
| Sharp Blade | already cut | keep |
| Teleport button | KEEP but only after the first gate | client |
| Dash (Q) | LATER: tier 3 scythe, not tier 2 (one fewer thing in the first 5 min) | `Config.Dash.tier = 3` |
| Zone quests button + checkboxes | HIDE until Zone 3 | client |
| Rotating orders (Smash 25 at 207k candy, REC f10) | KEEP one, but never "smash N" after the tutorial unless G1 is fixed | config `RotatingOrders` |
| Daily popup | only in the hub while not carrying | client |

## 5. Economy numbers to change (exact PatchConfig keys)
Verified with the econ sim on a scratch copy (`scratchpad/gp/sim`): **"OK: Boots + dash arrivals within 25 %; all crate tiers cross at most one gate at a time."**

| Key | Now | New | Why |
|---|---|---|---|
| `Zones.Zone1.candy` | 1 | **8** | Smash = 14 candy/s at minute 2 (77 % of income) |
| `Zones.Zone2.candy` | 3 | **80** | 17-42 % of income in Zone 2 |
| `Zones.Zone3.candy` | 9 | **250** | 21-34 % |
| `Zones.Zone4.candy` | 27 | **1200** | 21-35 % |
| `Zones.Zone5.candy` | 80 | **6000** | 22-47 % |
| `Zones.Zone6.candy` | 240 | **30000** | 33-52 % |
| `Zones.Zone7.candy` | 720 | **150000** | about 30 % |
| `Economy.gateCosts` (also overwrites `Zones.ZoneN.cost`) | {1000, 318000, 3064000, 18507000, 138275000, 785290000} | **{2500, 100000, 900000, 9000000, 80000000, 540000000}** | Sim arrivals: Zone2 2.5, Zone3 10.0, Zone4 15.5, Zone5 27.6, Zone6 47.1, Zone7 74.0 min. Was 4/15/32/60/92/137 |
| `Progression.arrivalMinutes` | {0,5,15,30,50,80,120} | **{0,3,10,18,30,48,75}** | The first session (about 20 min) reaches Zone 4 instead of Zone 3 |
| `KingNight.farmSeconds` | 480 | **1800** | With the new candy the King pays about 3 min of income, not 8 s |
| `KingNight.rarityWeights` | {55,33,10,2} | **{0,70,27,3}** | The crate is always better than a nest steal (tier 2+ promotes one rarity) |
| `KingNight.pity` | 10 | **5** | Kinglet in at most 5 King Nights (about 100 min), not 200. Kinglet earns about 75k/s, so keep its roll at 3 % (weights[4]) |
| `Raid.grace` | 900 | **1e9** | No ambient raids at launch |
| `Purge.minutes` / `Purge.grace` | {10,50} / 900 | **{50} / 1800** | One Purge an hour, never in the first 30 min |
| `CarveNewSeconds` | 8 | **2** | Near-instant first hatches, like SaE |
| `Upgrades.Stack.max` | 10 | **1** | Carry 3 = one nest; levels above that are dead |
| `Upgrades.Lucky.cut` | nil | **true** | Unclear odds layer |
| `Dash.tier` | 2 | **3** | One fewer verb in minutes 1-5 |
| `Unlocks.King` | 0 | **600** | No boss rules before 10 min |
| `DayLength` | 150 | **255** | A 5:00 nest-reset clock (SaE reset) |
| `SpookyLength` | 90 | **180** | x2 long enough to feel |
| `TutorialOrders` | smash 30 → buy Iron → steal → hatch → fill pen 2 | **steal → hatch → farmCandy 50 → buy Iron → unlockZone** | Teach the real verb first |

Check after the change: `Tools` costs (150 / 1.2k / 9k / 60k / 400k / 2.5M) still sit within about 1 minute of earnings at their zone. Re-run `lune run scene/econ-sim.luau` in giant after editing.

## 6. The 3 biggest fun problems and their fixes
1. **The thing you do most (smash) is worthless.** Smashing is 1 % of income (SIM current: farmShare 1 % from minute 6 to 48; LOG: 29 candy in 150 s against 12.6/s pen). Scythes, damage and crits are all decoration. **Fix:** the per-zone candy ladder in section 5, which makes smashing 20-50 % of income. Also add a candy fountain + "+80" pop that scales with the pumpkin, and a Golden pumpkin (1 in 40) worth 20x as a mini jackpot. Effort S.
2. **No pull forward (8-16 min dead zone, King not worth it).** Income was flat for 7 minutes and the player went idle twice. The boss pays 8 seconds of income. **Fix:** gates {2.5k, 100k, 900k, ...}, so a new gate comes every 5-8 min in the first session. The King crate is always one rarity above your zone, with pity 5 and a "KINGLET in N" counter; the boss becomes the way to get the next zone's pet early. Add an always-on HUD progress bar to the next gate. Effort S (config) + S (bar).
3. **Too much to learn, and the scary parts punish exploring.** About 20 systems and 3-4 clocks in 10 minutes. Ghosts target exactly the active player who is out in the zones (SRV 6140-6170), and the warning text points to a lock that does nothing (R26 #5, REC f5). **Fix:** run the first session as 5 things (steal, place, smash, shop, gate) with one event chip. Cut ambient raids. Make the Purge hourly and move it after 30 min. Turn ghosts into candy piñatas until then. Effort S.

## 7. The 5 changes that most raise "premium" feel for the least effort
1. The section 5 candy ladder plus a juicy candy fountain on every smash, so the core verb finally feels rewarding (config + existing pop VFX).
2. One HUD event chip instead of 3 timers, plus a "next gate ▓▓▓▓ 64 %" bar (client, S).
3. Tutorial reordered to steal-first, with a 2 s first hatch (config, S).
4. King crate always better than a steal, plus a visible pity counter "KINGLET in 4" (config + 1 label).
5. No ghost losses in the first 30 min; ghosts drop candy instead (config + small code).
