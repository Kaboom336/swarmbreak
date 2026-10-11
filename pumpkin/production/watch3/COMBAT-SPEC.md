# COMBAT-SPEC: merged build spec (judge of SECTION-COMBAT-A vs B)
Two Codex tasks. Do Task 1 first, Task 2 depends on its `recover` window. Server-authoritative Luau, Part/decal telegraphs, procedural tweens, no uploaded animations, no Humanoid.Health damage ever. File refs are Patch.server.luau (SV), Patch.client.luau (CL), PatchConfig.luau (PC) under pumpkin\giant\src.

## Judge scores (1-10)
| Criterion | A (arcade) | B (event) |
|---|---|---|
| Fun/readability for kids | 8 (colour = meaning, donut safe spot, numbered stomps) | 7 (good tells, but more rules) |
| Fairness 1 and many players | 7 (grace 1.5 s, but no player scaling, sweep missing) | 8 (N-scaling, solo +0.3 s warn, 14-stud guard rule, predicted aim) |
| Spectacle | 8 (phase freeze, banner, roar, 80 rain) | 7 (growth, ring, tint) |
| Build simplicity | 6 | 5 (parry, points tiers, growth, ring = four new systems) |
| Identity fit | 7 | 7 |

Kept from A: phase freeze moment, recover-after-attack, Donut with safe centre, Triple Stomp, hit feedback, finale/rain, grace.
Kept from B: shuffled no-repeat deck, Claw Sweep, N-scaling, solo extra warn, 14-60 stud guard rule, predicted aim, root 0.8 s, 2 boulder lanes, per-guard arm-raise.
CUT (system with no big payoff): Parry; contribution points and Bronze/Silver/Gold tiers; stagger meter; King growth scaling; arena neon ring; sky tint per phase; candy loss on hit (kids; adds a loss state); FOV tween; Vine Rows; Candy Storm; Seed Spit; 8 extra config values. Players keep the existing damage ranking, plus one always-visible "YOU: dmg" row.

---
# TASK 1: King boss fight

## 1.1 Config (PC, `Config.KingNight`; delete dead duplicates at PC:858-868 and keep one block)
```
phaseAt = {0.66, 0.33}
attackEvery = {5.0, 4.0, 3.2}      -- seconds between casts, before player scaling
recover = {2.5, 2.0, 1.5}          -- stunnedUntil after Stomp/Sweep/Donut/Triple
recoverMult = 1.5                  -- damage multiplier while recovering (lantern stun stays x2, crit stays 10% x3, cap total x3)
transition = 2.5                   -- phase freeze seconds
grace = 1.5                        -- victim immunity after a hit
soloExtraWarn = 0.3
finale = 2.5
rainCount = 80, rainCandy = 8
```
Warn per attack is used from the attack table (replaces the shared `windup = 1.2`, SV:7482/7485).

## 1.2 Player scaling (S)
`N = clamp(#players counted in fight, 1, 12)`. Interval = `attackEvery[phase] / (1 + 0.1*(N-1))`, min 0.5x. Solo adds `soloExtraWarn` to every warn. Lackeys = `clamp(2*N, 2, 8)`, lackey HP 2. Seedfall circles = `min(2 + floor(N/2), 8)`.

## 1.3 Attack deck (M) - core of the fight
Shuffled deck per phase, never the same attack twice in a row, never two telegraphs at once (Seedfall/Triple circles of one cast count as one). All telegraphs: red `FF3B30` ground shape, fill grows over the warn, last 0.2 s flash white `FFFFFF`. Use existing `Telegraph` remote and `Progress.landAttack`.
| Attack | Phase | Shape | Warn (s) | Hit effect | King tell (procedural) |
|---|---|---|---|---|---|
| Stomp | 1-3 | circle r 18 centred on King ground | 1.5 | push 50, lift 40, stagger 1.0 s | rises 7 studs in 0.25 s, slams 0.15 s |
| Claw Sweep | 1-3 | rect 22 wide x 34 long from King edge toward nearest player | 1.2 | push 50 sideways, stagger 1.0 | yaw -35 deg over 1.0 s, +70 deg over 0.2 s |
| Seed Volley | 1-3 | 3 lanes 6 wide x 60 long, fanned -18/0/+18 deg at a random player | 1.5 | push 40, lift 30, stagger 0.8 | lean back pitch 15 deg over 1.2 s, forward 0.15 s |
| Shockwave Donut | 2-3 | red donut inner r 10, outer r 22; inner disc GREEN `5EE08A` transparency 0.7 = safe | 1.4 | push 45, lift 35, stagger 1.0 | rises 4 studs, slams |
| Seedfall | 3 | r 6 circles inside r 40 of King, first on a player at `pos + velocity*0.8`; solo: 2 circles, none within 10 studs at spawn; staggered 0.15 s | 1.4 | push 30, lift 25, stagger 0.6 | none (red streaks overhead) |
| Triple Stomp | 3 | 3 circles r 9 at 10/22/34 studs toward nearest player, numbered 1-2-3 (white BillboardGui); land at warn, +0.5, +1.0 s | 1.3 | push 45, lift 35, stagger 1.0 | two quick stomps |
Decks: P1 {Stomp, Sweep, Volley}; P2 adds Donut; P3 {Sweep, Volley, Seedfall, Donut, Triple Stomp, Stomp}. Phase 1 King stands on throne; P2-3 walk pad to pad (walkSpeed 10, pause 3) only when not winding up or recovering.
Dodge check: 18 studs in 1.5 s = 12 studs/s, walk is 16.

## 1.4 Recover window (S) - the "punish" rhythm
After Stomp, Sweep, Donut, Triple Stomp land: `stunnedUntil = now + recover[phase]`, no new telegraph during it. Damage x1.5. Client: 3 yellow stars orbit the head, King Highlight rim gold `FFD23D` pulsing 0.5 s, floating text "HIT HIM!" once per recovery.

## 1.5 Phases (M)
- P1 "Sleepy King" 100% -> 66%.
- P2 "Shield King" 66% -> 33%: lackeys spawn in a ring r 32 around the King (not far cauldrons), shield bubble up, King takes zero damage but keeps attacking. Last lackey popped = BIG STUN 6 s, x2 damage, 12 candy-corn pickups.
- P3 "Angry King" 33% -> 0: red Highlight `FF3B30`; weak-spot tired window every 15 s lasts 5 s, x2 damage (change from 20 s); last 10% HP: interval x0.85.
- Phase freeze at 66% and 33%: `transitionUntil = now + 2.5`; King and everyone invulnerable (grace set to all players), no landAttack. Client: camera shake 1.5 for 1.2 s, vignette flash 0.25 s (P2 `A855F7`, P3 `FF3B30`), banner "PHASE 2: SHIELD!" / "PHASE 3: ENRAGED!" (title font 90 px, slides from top 0.3 s, holds 1.2 s), Growl sound pitch 0.7, King squash scale 1.15 -> 1.0 in 0.15 s, 12 candy-corn pickups (1% of payout each, any player may collect).

## 1.6 Getting hit - never death (S)
Hit = existing push/lift + stagger. `victim:SetAttribute("KingGraceUntil", now + 1.5)`; `landAttack` skips victims in grace. Humanoid.Health untouched. No candy loss. Client shows STAGGER icon. Also: King can only be hit if within 90 deg of its facing or distance < 6 (stops back-face-tanking), BonkRange stays 11.

## 1.7 Finale and reward (S)
Finale 1.5 -> 2.5 s slow-mo, 3 white flashes, burst 120+40 sparkles, rain 80 pickups worth 8 candy (lawn glitters). Top 3 get 2nd crate (exists), every qualified player gets one Participation Crate (min Rare). Show "YOU: dmg" row under the top-5 list at all times. Pity counter exists (`pity = 5`): results text "Next guaranteed Epic in N". Consolation 25% unchanged.

## Task 1 acceptance
1. Solo fight lasts 90-150 s; King uses at least 3 different attacks in 60 s, no two telegraphs at once, no same attack twice in a row.
2. Every attack shows a red shape for >= 1.2 s (1.5 s solo) before damage; standing in the donut centre, between volley lanes, or outside circles takes zero damage.
3. Phase changes at 66% and 33% freeze 2.5 s with banner, roar, shake; nobody takes damage during it.
4. After Stomp/Sweep/Donut/Triple the King shows stars and "HIT HIM!" for 2.5/2.0/1.5 s and takes x1.5; with 4 bots casts come ~1.3x as often and Seedfall shows 4 circles.
5. Getting hit never changes Humanoid.Health, staggers 0.6-1.0 s, and cannot repeat within 1.5 s; the kill shows a 2.5 s finale, 80 rain pickups, crates.

---
# TASK 2: guard signature attacks + scythe combat interaction

## 2.1 Global guard rules (S)
Twist only fires when thief is 14-60 studs from guard (`GuardTwists.minDist = 14`, `maxDist = 60`); `minChase = 3` s; cooldown 7-9 s as now; one twist at a time; none during `GuardMercyUntil`; `mercy = 1`. Shape sits at the thief's predicted position `pos + moveDir * speed * warn` (running straight is wrong, sidestepping is right). First-ever steal of a player: telegraph shows but cannot hit (keeps `g.cosmetic`; remove the rule blocking twist until minChase on later steals). At warn start: guard 0.5 s procedural arm-raise/lean-back (CFrame pitch -15 deg), lunge forward in last 0.2 s; "!" billboard over the thief; per-kind sound pitch. Slow cap in `Progress.slow` raised 2.0 -> 2.5 s. If the thief dodges, the guard is "winded" (stops moving) 1.0 s. Telegraph colour per kind (client 7405-7412 currently only colours Bat/Sticky): use the table.

## 2.2 Seven attacks (M)
| Zone / guard | Verb | Shape | Warn (s) | Effect on hit | Colour |
|---|---|---|---|---|---|
| 1 Scarecrow | Crow Dive | circle r 6, full predict | 1.5 | slow 0.5 for 1.5 s, feather puff | `FF9A2E` |
| 2 Skeleton Knight | Bone Throw | lane 4 wide x 44, aimed at current pos, spinning bone | 1.3 | push 12, slow 0.6 for 1.5 s | `C9B4F0` |
| 3 Tree Ent | Root Snare | circle r 7, predicted; roots rise in last 0.3 s | 1.4 | root (speed 0) 0.8 s, then mercy | `A8DC6A` |
| 4 Swamp Toad | Tongue | circle r 7, predict 1.0 s, neon line from mouth to circle | 1.2 | pull 10 toward nest, slow 0.6 for 1.0 s | `9A6BE8` |
| 5 Vampire | Bat Ambush | circle r 7, 18 ahead; guard bat-poof teleports there only if within 24 of its position | 1.5 | slow 0.5 for 1.5 s | `A855F7` |
| 6 Candy Golem | Sticky Puddles | 2 circles r 6, spacing 10, 14 ahead, last 6 s | 1.2 | slow 0.4 while inside | `FF6EC7` |
| 7 Pumpkin King guard | Boulder Roll | 2 lanes at +/-14 deg around aim, 5 wide x 44, speed 50 (safe gap in middle) | 1.5 | push 14, dizzy 1 s, slow 0.6 | `FFD23D` |

## 2.3 Scythe combat interaction (S/M)
- 3-hit chain per player on the King (bonk handler SV:7209-7254): next hit within 1.0 s = chain+1, otherwise 1. Hit 3 = FINISHER: damage x1.5, chain resets, bigger arc FX, text "x3!". Total multiplier capped at x3 (`min(mult, 3)` with crit). Per-second swing cap `KingSwingsPerSecond` stays 4. Config `KingNight.combo = {window = 1.0, finisher = 1.5}`.
- King hit feedback (client 5458): white Highlight flash FillTransparency 0 -> 1 in 0.12 s; King scale 1.0 -> 0.96 -> 1.0 in 0.1 s; damage text size by amount (crit text "CRIT!" `FFB020`); HP bar shakes 4 px for 0.1 s; sound pitch rises with chain; hit-pause 60 ms (local swing track speed 0.2) on the local player only. Merge floaters within 0.3 s (one number per hit).
- Hits in a recovery window show gold rim and "x1.5" tag (from Task 1).

## Task 2 acceptance
1. Run each zone guard once: telegraph shows >= 1.2 s in the table colour, a "!" over the thief, and the guard lean-back pose.
2. A twist never fires within 14 studs; walking straight into the predicted spot hits, sidestepping avoids it.
3. Tree Ent root lasts 0.8 s and does not guarantee a catch; every hit effect is felt (>= 1.5 s slow at 0.5-0.6 or a 10-14 stud shove).
4. First-ever steal shows the telegraph with no hit.
5. Three hits within 1 s on the King trigger the finisher (x1.5, "x3!"); each hit shows flash + squash + merged number + 60 ms local hit-pause.
