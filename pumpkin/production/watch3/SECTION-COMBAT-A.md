# SECTION-COMBAT-A: King fight + guard attacks (angle A: arcade, readable, kid-friendly)

Style target: Pet Sim 99 / Bee Swarm bosses. Big colored ground shapes, 1.2-1.6 s wind-ups, one new idea per phase, getting hit = shove + lose a little candy (never death, never a respawn), and a loud loot payoff. All server-authoritative; telegraphs are client Parts/adornments already drawn by the `Telegraph` remote (Patch.client.luau:7312-7478).

## 1. What exists today (evidence)
- King: 3 HP phases (66% / 33%) at Patch.server.luau:7676-7697. Attacks are only `Slam` (circle) and `Volley` (3 lanes), strictly alternating (7713). Both use the SAME wind-up `KingNight.windup = 1.2` (attack(), 7482/7485), so `SlamWarn/VolleyWarn/KingGrace/KingDizzy/KingLastHit` in PatchConfig.luau:858-866 and 1416-1418 are dead values.
- Phase 1 the King does not move at all (walkKing returns when phase==1, 7426); phase 1 = stand and trade hits, no vulnerable/safe rhythm. Phase 2 = shield: King takes ZERO damage until every Lantern Lackey (spawned at far cauldrons, 7538) is popped = errand/downtime, not fight. Phase 3 = same two attacks, only faster; a 6 s stun every 20 s (7698).
- Hit = knockback (push 50, lift 40) + 1 s stagger (7411-7413). No candy loss, no post-hit invulnerability (KingGrace unused), so back-to-back shapes can chain-hit.
- Hit feedback on King: only spark burst + damage text (client 5458-5472). No flash, flinch, HP-bar reaction. Phase change = a toast + a 0.4 s sound (5578-5587): no moment.
- Combo is a client-only label (client 4958-4977, shows at x3). It changes nothing: damage is flat `tool.damage * 1/2 (stun) * crit(10% x3)`.
- Rewards: candy + 1-2 crates + 3 s rain of 40 candy (defeatKing 7359-7392). Fine in value, but the finale is 1.5 s and generic.
- Guards: all 7 already have a "twist" (PatchConfig.luau:1256-1336, server 5546-5717): Crow, Bone, Root, Tongue, Bat, Sticky, Boulder. Problems: (a) nearly all are "slow 0.6 for 1-1.5 s" (Progress.slow caps at 2 s, 8659) = barely felt; (b) the Zone1 guard never twists on a player's first steal (`g.cosmetic`), then twists are blocked until 3 s into chase (`minChase`); (c) client telegraph is the SAME red circle for 4 of the 7 (7405-7412), no guard animation/wind-up pose, no sound cue pitched per guard beyond `pitch`; (d) thief is hit while carrying only, nothing drops (only the bonk catch drops loot).

## 2. What top games do
- Pet Sim / Bee Swarm bosses: one huge colored decal per attack, color = meaning (red hurts, yellow/green = safe or hit-me), 1.2-2 s wind-up, boss "tires" after the big move and the whole server piles on during that window, damage numbers + screen shake + boss flash on every hit, phase change freezes the fight for ~2 s with a banner and a roar, loot bursts out as physical pickups.
- Damage never kills kids: it shoves them, stuns ~1 s, and costs a sliver of currency that lands on the floor and can be picked back up.

## 3. Exact fix spec (ordered by impact)

### A. Boss rhythm: attack -> recover window (S) [highest impact]
Each phase attack ends in a RECOVER window where the King is "dizzy": `king.stunnedUntil = now + recover` right after landAttack in attack() (7530). Existing x2 damage on stun applies. Client shows 3 yellow stars orbiting the head (Highlight FillColor `FFD23D` pulse 0.5 s) and sets the HP bar outline gold.
- recover seconds: P1 2.5, P2 2.0, P3 1.5.
- Config: `Config.KingNight.recover = {2.5, 2.0, 1.5}`. Do not start next attack until `stunnedUntil` passes (the loop already checks it, 7710).

### B. Phase 1 "Sleepy King" 100% -> 66% (M)
King stays on the throne (no walking), AttackEvery 5.0 s, alternating:
1. SLAM: red circle r = 14 centered on King, windup 1.5 s (fill grows over windup; last 0.2 s flash white `FFFFFF`). King rises 7 studs over 0.25 s then slams 0.15 s (existing tweens). On land: knockback push 50 / lift 40, stagger 1.0 s.
2. SEED SPIT: 3 circles r = 5 centered on up to 3 different random players (fewer players = repeat the nearest), windup 1.3 s, seed ball arcs in over last 0.45 s (existing 7447). Land: push 30, lift 25, stagger 0.8 s.
HP: keep. Dodge check: walk speed ~16 studs/s * 1.5 s = 24 studs > r14. Fair.

### C. Phase 2 "Shield King" 66% -> 33% (M)
Phase-change moment (see E). Then:
- SHIELD change: lackeys spawn in a ring r = 32 around the King (not far cauldrons): count = clamp(2 * players, 2, 8), lackey hp 1 (existing). Shield bubble already shown (client 7481+). While shield is up the King still attacks (shield = no damage, but fight stays alive). Popping the last lackey = BIG STUN 6 s (Config.StunSeconds), x2 damage, candy-corn burst (12 pickups, 1% of payout each). This turns the old errand into a ring-around-the-boss mini-game.
- Attacks, AttackEvery 4.0 s, alternating:
  1. SHOCKWAVE DONUT: red donut inner r = 10, outer r = 22 around King, windup 1.4 s. SAFE spot = stand close to him (draw inner circle GREEN `5EE08A` transparency 0.7). Hit: push 45, lift 35, stagger 1.0.
  2. SEED LANES (existing Volley): 3 lanes 6 wide x 60 long, spacing 14, aimed forward, windup 1.3 s. Hit: push 40, lift 30, stagger 0.8.
- King walks pad to pad (existing walkSpeed 10, padPause 3), NEVER while winding up (attackBusy check exists, 7475).

### D. Phase 3 "Angry King" 33% -> 0 (M)
Banner red. AttackEvery 3.2 s. King glow = red Highlight `FF3B30`.
1. TRIPLE STOMP: 3 circles r = 9 in a line from King toward the nearest player, centers at 10 / 22 / 34 studs, windup 1.2 s for the first, each next lands +0.5 s later (draw all three at once, number them 1-2-3 in white BillboardGui). Hit: push 45, lift 35, stagger 1.0.
2. CANDY STORM: 8 small circles r = 4 at random arena positions (within 40 of King), staggered 0.15 s apart, each windup 1.0 s. Hit: push 25, lift 20, stagger 0.6. Fun, forgiving (many small dodgeable dots).
- Every 15 s (was 20): "TIRED" window 5 s, glowing pumpkin weak-spot ring above the head, x2 damage (existing logic 7698; change `weakEvery = 15`, plus a StunSeconds-style value 5).
- Enrage last 10%: AttackEvery 2.6 s.

### E. Phase transition moment (M)
At 66% and 33%: `king.transitionUntil = now + 2.5`; attack loop and damage both pause (King invulnerable, grey damage text "ROAR!"), landAttack not called. Server fires kingDoneEvent("phase2"/"phase3") (exists). Client: camera shake 1.5 for 1.2 s, FOV 70 -> 78 -> 70 over 1 s, full-screen vignette color flash (P2 purple `A855F7`, P3 red `FF3B30`) 0.25 s, big banner "PHASE 2: SHIELD!" / "PHASE 3: ENRAGED!" (title font, 90 px, slides in from top 0.3 s, holds 1.2 s), roar sound `Config.Sounds.Growl` at pitch 0.7. King squashes (scale 1.15 for 0.15 s then 1.0). Everyone gets invulnerability for those 2.5 s (set `ForceField` style attribute `KingGraceUntil`).
Also drops 12 candy-corn pickups ("loot burst", 1% of payout each).

### F. Getting hit: knockback + drop candy, never death (S)
In landAttack effect (7396-7421) after knockback:
- Candy drop: lose `min(2% of current candy, 0.1 * Progress.bossCandy(player))`, spawn it as 6 gold pickups around the victim (reuse RainPumpkin spawner at 7289-7325 with RainCandy value split) that stay 12 s and ANY player can collect. No loss if candy < 100.
- Grace: `victim:SetAttribute("KingGraceUntil", now + Config.KingGrace)`, KingGrace = 1.5 (config already exists). landAttack skips victims in grace. Stagger 1.0 s via existing Progress.slow(player, 0, ...).
- Humanoid.Health is never touched. Client shows "-N candy" red float text + the existing STAGGER icon.

### G. Hit feedback on the King (S)
On kingHitEvent (client 5458): King Highlight FillTransparency 0 -> 1 in 0.12 s white; King scale 1.0 -> 0.96 -> 1.0 over 0.1 s; damage text size by amount (small <200, medium, large >= 20% of tool damage crit) with crit text "CRIT!" `FFB020`; the HP bar segment shakes 4 px for 0.1 s; sound pitch rises with combo (existing). Every 10th hit by a player: a bigger "CRACK!" burst (30 sparkles). All client-only. Add 60 ms hit-stop on the local player's swing animation (scale track speed 0.2 for 0.06 s).

### H. Scythe combo and stagger (M)
Server-tracked 3-hit chain per player on the King (in bonk handler 7209-7254): hit within 1.0 s of the previous = chain +1; resets to 1 otherwise.
- Hit 1, 2: damage x1.0.
- Hit 3 ("FINISHER"): damage x1.5, then chain resets. Client: bigger arc FX + damage text "x3!". Keep per-second cap `KingSwingsPerSecond` at 4 and raise by 1.5 for finishers only if desired; otherwise cap stays (finisher counted within window).
- STAGGER meter: each finisher adds 8, hits during the recover/tired window add +3 per hit; meter 0-100 shown as a thin yellow bar under the HP bar (shared by everyone). At 100: "KING DIZZY!" 4 s, x2 damage, meter resets; the King cannot start a new wind-up while dizzy (already-started telegraphs still land). Meter decays 2/s so a lone spammer cannot trivialise it. Config: `KingNight.combo = {window = 1.0, finisher = 1.5, staggerFinisher = 8, staggerWeak = 3, staggerMax = 100, dizzy = 4, decay = 2}`.
- Critical chance stays 10% x3 (do not stack with finisher beyond x3 total cap: `min(mult, 3)`).

### I. Big rewards (S)
- Finale: `KingNight.finale` 1.5 -> 2.5 s (slow-mo animation exists), 3 white flashes, then burst: 120 + 40 sparkles (client 5550-5551) PLUS 80 rain candy (RainCount 40 -> 80, RainCandy 5 -> 8) so the lawn glitters; top 3 each get a 2nd crate (exists) and everyone qualified gets 1 "Participation Crate" (min Rare). Show crate pop with rarity beam.
- Guarantee: pity counter already exists (`KingNight.pity = 5`): every 5th qualified fight is a guaranteed Epic+ crate, shown in results text "Next guaranteed Epic in N".
- "Almost won" consolation stays 25%.

### J. Zone guards: one telegraphed attack each, dodgeable, felt (M)
Keep the existing 7 twist concepts (they fit the themes), but fix feel. Common rules: wind-up shown with colour = theme, guard plays a 0.4 s procedural lean-back (CFrame pitch -15 deg) then lunges forward in the last 0.2 s; sound cue per kind; a "!" billboard above the thief during wind-up; grace after any hit = 1.0 s (exists `mercy = 1`); effect must be felt: min slow 0.5 for >= 1.5 s (cap raised to 2.5 s) or a 12-stud shove.

| Zone | Guard | Attack | Shape / numbers | Effect on hit | Color |
|---|---|---|---|---|---|
| 1 Meadow | Scarecrow | CROW DIVE (crows swoop onto thief spot) | circle r 6 at thief position +0 predict, warn 1.5 | slow 0.5 for 1.8 s + 1 floating feather puff; also cut cosmetic block: on first-ever steal only crows' warn shows without hit | `FF9A2E` |
| 2 Graveyard | Skeleton Knight | BONE THROW | lane 3 wide x 40 long from guard to thief, warn 1.3 | shove 12 + slow 0.6 for 1.5 s; widen lane to 4 | `C9B4F0` |
| 3 Woods | Tree Ent | ROOT GRAB | circle r 8, warn 1.4 (roots rise visibly last 0.3 s) | root (speed 0) 1.2 s | `A8DC6A` |
| 4 Swamp | Swamp Toad | TONGUE PULL | circle r 7 at predicted spot (predict 1 s), warn 1.2 | pull 10 studs toward nest + slow 0.6 for 1.0 s | `9A6BE8` |
| 5 Castle | Vampire | BAT RUSH | circle r 7, 18 ahead of thief, warn 1.5, guard teleports there in a bat poof | slow 0.5 for 1.5 s | `A855F7` |
| 6 Candy | Candy Golem | STICKY PUDDLES | 2 puddles r 6, spacing 10, warn 1.2, lifetime 6 s | slow 0.4 while standing in them | `FF6EC7` |
| 7 Throne | Pumpkin King | BOULDER FAN | 3 lanes 6 wide x 40 long, fan 20 deg, warn 1.5, boulder speed 50 | shove 14 + dizzy 1 s, slow 0.6 | `FFD23D` |

New for all: after the first twist is dodged, the guard is "winded" 1.0 s (stops moving) and gives a satisfying sound; if the thief gets hit, the guard drops no pumpkins but an extra 0.5 s stagger so rubber-banding is fair. Telegraph color must match the table (client 7405-7412 only colours Bat/Sticky; add per-kind color table).

### K. Cleanup (S)
Delete duplicate/dead Config values (PatchConfig.luau:858-866 vs 1412-1419) and wire `SlamWarn = 1.5`, `VolleyWarn = 1.3` into attack() instead of the shared `KingNight.windup`. Document that later assignments at 1412-1419 override the first block.

## 4. Acceptance test (5 lines)
1. 2 testers + scythe Tier 3: the fight lasts 60-120 s; P1 -> P2 -> P3 each starts with a 2.5 s roar/banner/freeze and nobody takes damage during it.
2. Every King attack shows a coloured ground shape for 1.2-1.5 s before any damage; standing at the marked safe spot (donut centre, gap between lanes, outside a circle) takes zero damage.
3. Getting hit never reduces Humanoid.Health; it shoves, staggers 0.6-1.0 s, drops up to 2% candy as pickups, and you cannot be hit twice within 1.5 s.
4. After every attack the King is dizzy 1.5-2.5 s (x2 damage, stars) and 3-hit scythe chains show a finisher that fills a visible stagger bar; a full bar produces a 4 s dizzy.
5. Killing the King shows a 2.5 s finale, 80+ rain pickups, a crate pop for each qualified player, and each of the 7 guards lands one distinct telegraphed twist (colour per table) that a walking thief can dodge.
