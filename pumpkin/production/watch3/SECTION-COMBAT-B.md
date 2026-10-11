# SECTION-COMBAT-B: King Night as a server-wide event + readable guard attacks (round 3, proposer B)
Angle: many players fight one King together (shared phases, shared contribution meter, MVP, spectacle), still fair and fun at 1 player. Server-authoritative, Part/neon telegraphs, procedural tweens only. Evidence tags: PC = PatchConfig.luau, SV = Patch.server.luau, CL = Patch.client.luau.

## 1. Flaws in the current fight (verified in code)
1. **Only two attacks, both predictable.** `attack()` alternates Slam/Volley by `turn % 2` (SV:7713). Volley lanes are always `i*14` on X, length 60 along +Z from the King, never aimed (SV:7486-7498). Learn it once, then it is free. Phase 3 only adds a stun every 20 s (SV:7692-7705); no new attack, no visible change.
2. **Config warn times are ignored.** Both attacks use `KingNight.windup = 1.2` (SV:7482, 7485); `SlamWarn 1.4` / `VolleyWarn 1.6` (PC:858-860) are dead. `KingGrace`, `KingDizzy`, `KingBase`, `KingPoolShare`, `KingLastHit` are unused leftovers (PC:861-868).
3. **No reason to read the tell, no reward for dodging.** Hit = 1 s stagger + knock (SV:7405-7414); nothing is gained by dodging, parrying or timing. Scythe is a pure DPS stick; damage cap is the only skill-less limiter (SV:7230-7237).
4. **Vulnerable windows are almost random.** Stun only via lantern shield (phase 2) or a timer every 20 s in phase 3 (SV:7698). No window follows the King's own attacks, so "attack, punish" never exists. King does not move/animate between attacks except pad walking (SV:7424).
5. **Not a social event.** Players are a damage list (`KingTop`, text only, SV:7120-7135). MVP = pure damage, so tool tier decides it; a weak-tool player who fights hard never feels credited. Nothing happens to the arena as more people join; nothing marks a phase break except a banner.
6. **Spectacle gap.** King is the same size all fight; phase 2 only adds a purple bubble (CL:7481-7530); no hazards beyond the two attacks; minions are generic ghosts spawned at cauldrons (SV:7535-7554).
7. **Solo unfairness risk if made group-scaled.** HP already scales (SV:7075), but attack pacing does not: 12 players against `AttackEvery {4.5,3.5,2.8}` get the same threat per second as one.
8. **Guard twists are not skill tests.** Aimed at the thief's *current* position with 1.2-1.5 s warn (SV:5569, no `predict` for Zone1/2/3/6/7), so "keep running straight" always dodges Crow/Root/Sticky; Zone3 Root `slow=0` for 1.5 s (PC:1284-1286) means a guaranteed bonk (guard closes 1.5 s x ~16 studs/s); Zone7 three boulder lanes at 20 deg overlap under ~17 studs, so close range is unavoidable (PC:1318-1323); twists can fire at point-blank range.

## 2. What top games do (reference)
- Fortnite / Roblox raid bosses (Tower of Hell-style hubs, "Boss fight" events in Pet Sim / Blox Fruits): one boss, whole server in the arena, shared HP bar, damage leaderboard, loot by contribution tier, boss grows/changes at HP thresholds.
- Souls-likes / Zelda: every attack has a distinct silhouette + ground tell + sound, then a recovery window you punish; parry window rewarded.
- Brawl-event bosses (Brawl Stars, Clash Royale special): 3 phases, each adds ONE new verb; arena hazards fire from the boss, not random.

## 3. Fix spec, ordered by impact (all numbers exact)
### A. Attack deck + vulnerable windows (M)  -- the core of the fight
Replace the `turn % 2` alternation with a shuffled deck per phase, never the same attack twice in a row. Use `warn` per attack (restore config use). Telegraph colour rule (CL:7367-7430): red ground shape, fills/grows over `warn`, white flash at land. Land check is existing `Progress.landAttack`.
| Attack | Phases | Shape (server `circles` entry) | warn | Effect on hit | King tell (procedural tween) |
|---|---|---|---|---|---|
| Stomp (existing Slam) | 1-3 | `{pos=kingGround, radius=24}` | 1.4 | knock 50 + lift 40, stagger 1 s | lifts 7 studs in 0.25 s (existing), lands 0.15 s |
| Claw Sweep (NEW) | 1-3 | one rect in front toward nearest player: width 22, length 34, from King edge, `cf=CFrame.lookAt` | 1.2 | knock 50 sideways | windup yaw -35 deg over 1.0 s, swing +70 deg over 0.2 s |
| Seed Volley (fix) | 1-3 | 3 lanes width 6, length 60, fanned at -18/0/+18 deg, aimed at a random alive player | 1.6 | as Slam | leans back pitch 15 deg over 1.2 s, then forward 0.15 s |
| Seedfall (NEW) | 2-3 | N circles r=7 inside arena ring, first one at a random player's `pos + velocity*0.8` | 1.4 | knock 35, stagger 0.6 s | none (sky cue: red streaks, CL part) |
| Vine Rows (NEW) | 3 | 3 lanes width 6, length 90, parallel spacing 14, alternate X/Z axis each cast | 1.5 | knock 50 | roar: scale pulse 1.0 -> 1.06 -> 1.0 in 0.4 s |
Deck weights: P1 {Stomp, Sweep, Volley}; P2 {Stomp, Sweep, Volley, Seedfall x2}; P3 {Sweep, Volley, Seedfall, Vine Rows, Stomp}. Attack interval `AttackEvery = {4.5, 3.8, 3.0}` (was 4.5/3.5/2.8) then multiplied by the player scale in D. **Never overlap**: one telegraph at a time except Seedfall circles belonging to the same cast.

**Recovery window (punish):** after Stomp or Sweep lands, the King is "RECOVERING" for 2.5 s: `king.recoverUntil = now+2.5` (reuse `recoverUntil`, SV:7634), damage x1.5, attribute `KingRecover=true` for the client (gold rim Highlight, text "HIT HIM!"). Lantern stun stays x2 (6 s, SV:7575). Crit stays 10% x3. Rule: the King does not start the next telegraph during recovery.
**Move after attack:** keep the 4-pad walk (SV:7439) but only starts when recovery ends (`walkKing` already checks `recoverUntil`).

### B. Scythe interaction: PARRY (S/M)
A swing whose `lastBonk` falls in `[landTime-0.35, landTime]` while the player is inside the shape that is about to land = **PARRY**: that player takes no knock/stagger from this attack (skip in `landAttack`), the King takes one stun-rate hit (`swingDamage x2`, ignores the per-second cap once per cast per player), +30 contribution points, client gold ring + "PARRY!" + hit-pause 80 ms. Server only: store `king.parry[player]=true` when the bonk arrives in the window (bonk handler SV:7138-7170), consult in `landAttack` (SV:7396). Works at any range (swing needs no target). Parry never applies to guard twists (kept a pure dodge test).
Also: King hits require facing within 90 deg (dot of `look` to King > 0 or distance < 6) to stop back-turned face-tanking; BonkRange stays 11 (PC:833).

### C. Contribution meter, MVP, tiers (M)
- Points (not raw damage) decide rank/MVP so tool tier does not decide it: King hit **10**; hit in a recovery/stun window **15**/**20**; crit +5; lackey kill **60**; Parry **30**. Stored `king.pts[player]` (replicate `KingPts` player attribute, throttled 1/s with `publishTopDamage`).
- Reward tiers (replaces `qualified`, SV:8809): **Bronze >= 150 pts** (candy `bossCandy`), **Silver >= 400** (+1 crate), **Gold >= 800** (+2 crates), top 3 keep the existing extra crate. Win/lose scaling and consolation 0.25 stay (PC:1236). Thresholds sized for a 150-300 s fight at 1.8 hits/s (~100 hits solo ~1000 pts).
- MVP = highest `pts` among players with >= Bronze; last hitter keeps the +5% Kinglet bonus (PC:1235). Cleaver skin stays (SV:8842).
- UI (CL:7594-7640 area): under the King HP bar show a thin personal bar `pts / 800` with notches at 150/400/800 and labels Bronze/Silver/Gold, colours 205/127/50, 192/192/192, 255/200/60. Beside the top-5 list show your own row always (rank N, pts). Hit feed shows "+10", "+30 PARRY".
- Shared win: at each phase break (66% and 33%) and at the kill, `rainCandy` runs with count 12 (is 40 at kill, SV:7289) so everyone grabs falling pumpkins together.

### D. Scale by player count, fair at 1 (S)
Let `N = clamp(#players with king.counted, 1, 12)`.
- Attack interval multiplier `1 / (1 + 0.1*(N-1))`, minimum 0.5 (12 players: 0.5x so ~2 casts per 3 s group-wide; per-player threat roughly constant). Solo: multiplier 1.0, plus 0.3 s extra `warn` on every telegraph.
- Seedfall circle count `min(2 + floor(N/2), 8)`; solo: 2 circles, neither within 10 studs of the player at spawn (still lead the first).
- Lackeys per phase 2: `clamp(2*N, 2, 12)` (existing math, SV:7681); lackey HP 3 (PC:864). Solo needs only 2 kills for the stun.
- HP formula unchanged (SV:7075, PC:1412-1413); solo target 75-95 s of pure hitting is fine only if recovery windows add DPS: expected solo fight 90-150 s. Fight timer `KingSeconds=300` kept (PC:1414).
- No player deaths ever: only knock and 1 s stagger (existing). Late joiners join via `kingAddPlayer` (SV:7084).

### E. Spectacle: growth, hazards, rim (M)
- **King grows** at each phase break: size multiplier 1.0 / 1.12 / 1.25 of `KingNight.height 28` (28 -> 31.4 -> 35), tween 1.2 s Back/Out, camera shake 0.5 s (existing stomp shake), roar sound `Growl` pitch 0.85. Reach check already uses `kingFace.Size.X/2` (SV:7215).
- **Phase tint**: P2 sky tint (110,40,90), P3 (150,20,20) via the existing `look` table (PC:1217-1228) over 1.5 s.
- **Arena ring**: client-built neon ring at radius 70 around the throne, colour 255,70,40, transparency 0.5, pulses 0.5 <-> 0.3 at 1 Hz. Hazards only land inside radius 70; outside is a safe lobby. 
- **Lackeys** get a lantern look (existing ghost + orange PointLight range 12) and a ring over each while the shield is up; shield HP shown as "SHIELD n/N" (exists, CL:7636). Shared: any player's kill counts.
- Phase 3 enrage = red Highlight (exists, CL:7508-7522) plus Vine Rows and interval x0.8 over 20 s timer (weak-spot stun every 20 s stays).
- Defeat finale stays (SV:7359-7392): swell + burst + candy rain; add a 2 s results delay so the podium (top 3 + your row) shows before the rain.

### F. One signature dodgeable attack per zone guard (M)  (tune `Config.GuardTwists`, PC:1256-1336)
Global rules: twist only fires when the thief is **14-60 studs** from the guard (never point-blank; `GuardTwists.minDist=14`, `maxDist=60`); `mercy` stays 1; first twist of a chase at `GuardLaunch.minChase=3` s (PC:680). Each telegraph shape is placed at the thief's **predicted** position (`pos + moveDir * speed * warn`) so running straight into it is wrong; sidestepping is right. Guard plays a 0.5 s arm-raise (procedural pose tween, `g.warnUntil`, SV:5782) at the start of every warn.
| Zone / guard | Verb | Shape | warn | Effect | Counterplay |
|---|---|---|---|---|---|
| Z1 Scarecrow | Crow Dive | circle r=5, predict full (`predict=1.5` => `warn`) | 1.5 | slow 0.6 for 1.5 s | change direction |
| Z2 Skeleton Knight | Bone Throw | lane width 4, length 44, aimed at current pos, bone spins along it | 1.3 | push 12, slow 0.6 for 1 s | sidestep 5 studs |
| Z3 Tree Ent | Root Snare | circle r=7 at predicted pos | 1.4 | **ROOT 0.8 s** (was 1.5) then mercy | dodge out of circle |
| Z4 Swamp Toad | Tongue | circle r=7, predict 1, **a neon line from toad mouth to circle** | 1.2 | pull 10 toward nest (not into guard) | jump/sidestep away from circle |
| Z5 Vampire | Bat Ambush | circle r=7 `ahead=18`; guard teleports there only if within 24 studs of its current position | 1.5 | ambush ahead, no direct hit | turn sideways before bats land |
| Z6 Candy Golem | Sticky Puddles | 2 circles r=6 spaced 10, `ahead=14`, lifetime 6 s | 1.2 | slow 0.4 in puddle | go around the pair |
| Z7 Pumpkin King guard | Boulder Roll | **2 lanes** at +/-14 deg around the aim line, width 5, length 44, speed 50 | 1.5 | push 14, DIZZY 1 s | run straight down the safe gap |
Cooldown stays 7-9 s (PC), one twist at a time per guard, none while `GuardMercyUntil` active (SV:5555).

## 4. Effort summary
A attack deck + recovery (M), B parry (S/M), C contribution/tiers/UI (M), D scaling (S), E growth/ring/tint (M), F guard tuning + 14-60 stud rule + arm-raise (M). Suggested order: A, D, C, B, F, E.

## 5. Acceptance test (5 lines)
1. Solo: King uses at least 3 different attacks in 60 s, each with a ground tell >= 1.2 s, no overlapping telegraphs; fight lasts 90-180 s and ends in a win with Bronze or better.
2. Four bots in the arena: attacks come about 2x as often as solo, Seedfall shows 4 circles, shared HP bar drops, top-5 board and "YOU pts" bar update every second.
3. After Stomp/Sweep lands the King glows gold for 2.5 s and damage is 1.5x; a swing 0.3 s before landing inside the shape gives "PARRY!" and no knock.
4. At 66% and 33% the King grows (28 -> 31.4 -> 35 studs), tint shifts, candy rain drops, minions spawn only in phase 2; MVP is the top points player.
5. Run each zone guard once: a twist telegraph shows >= 1.2 s, never fires within 14 studs, sidestepping avoids it, running straight into it hits; Zone3 root lasts 0.8 s and does not guarantee a bonk.
