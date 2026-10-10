# BOSS PLAN: "KING NIGHT" (merged from arena r20-boss, PA + PB)

One boss, the Pumpkin King. No per-zone bosses; World 2 gets a reskin later.

## Start
- Fixed clock: every :00 and :20 (server time). Replaces the Jack meter, `BloodMoonGap` and the locks-off window.
- HUD chip always on: "KING NIGHT in 4:32". At T-60 s: red sky, siren, ONE queued banner "PUMPKIN KING RISES! PET + LOOT!", red arrow at the King, and a "JOIN RAID" button that moves you to the plaza.

## Why go
- Paid crate for every fighter with **15+ hits or 3%+ of damage** (hit count protects low-scythe kids): 1 Boss pumpkin delivered straight to your pen, rarity 55% Rare / 33% Epic / 10% Legendary / 2% Mythic, plus candy = 8 min of your best zone's small-pumpkin farming.
- Mythic includes the boss-only **Pumpkin Kinglet** pet (12 studs, kg roll). Pity: guaranteed Kinglet on your 10th crate.
- Top 3: one extra Boss pumpkin roll. Finisher (last hit): +5% Kinglet chance.
- MVP: Cleaver **skin** (cosmetic only, no damage change). Lobby board shows the loot table.

## Fight (target 4 min, fail at 5:00)
- HP: keep `kingPlayerHp`, set `KingHpPerDamage` = 30 swings, `KingHpPerPlayer` = 200.
- P1 100-66%: Slam (red ring fills 1.5 s, 14 studs) and Volley (3 lanes of shadows, 1.2 s) alternating every 6 s.
- P2 66-33%: Shield; 2 lackeys per player (max 12), 1 hit each, drop a candy burst. Shared "SHIELD 4/12" bar. Breaking it = 6 s WEAK SPOT (existing stun, damage x2, glowing face).
- P3 <33%: attacks every 3.5 s, double slam ring; weak spot reopens every 20 s for 6 s.
- Every hit: floating number (orange crit). Wide top HP bar with 66/33 ticks; live top-5 board.
- Hit by an attack = knockback + 1 s stagger only. No death, no lost items, no dizzy.

## End
1.5 s slow-mo freeze, existing swell-and-burst, 3 s candy rain, results card: your damage, rank, crate reveal (reuse pet reveal card), top-3 podium. Fail: "King escaped!", every qualifier gets a 25% candy consolation, no crate.

## Reuse
`startBloodMoon` loop (phase at 66/33%), `landAttack` circles, `spawnLackeys`/`lackeyPopped`, stun x2, `king.damage`, `kingHitEvent`, `publishTopDamage` (3 to 5), dps clamp (keep: anti-autoclicker), `defeatKing` finale, `rainCandy`, debug "king" action.

## Cut
Jack meter trigger, locks-off window, dizzy, `KingPoolShare` pool payout, MVP-only tool grant, sweep beam, bomb freebies, combo counter.

## Build checklist (~3.5 h)
1. [ ] Clock scheduler + HUD chip + T-60 s announce + JOIN button (45 min)
2. [ ] Tune Config: HP, `AttackEvery` {6, 4.5, 3.5}, `KingSeconds` 300, 3-lane volley (30 min)
3. [ ] P3 weak-spot timer reusing stun; remove dizzy (30 min)
4. [ ] Crate grant in `defeatKing`: qualifier rule, rarity roll, pity counter in save, pen delivery (pens full = R20 swap/sell prompt) (60 min)
5. [ ] Results card + top-5 + loot board (45 min)
6. [ ] Playtest 1, 4, 8 players with tier 1 and tier 7 scythes; fight lasts 3-5 min (20 min)
