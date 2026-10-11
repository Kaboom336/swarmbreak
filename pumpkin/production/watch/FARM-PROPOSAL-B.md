# FARM PROPOSAL B: What you break + the reward
Baseline read from PatchConfig: Z1 hp10/candy1 ... Z7 hp7300/candy720 (x3 per zone), Rusty dmg5 (2 hits for 1 candy), golden 1/40 x20, big 25% x6, crit 10% x3. Pay is thin because the first minute is ~50 candy while pets/pumpkins cost thousands. Fix = pay more per break AND make each break a spectacle.

## 1. Breakable variety (visual skin + same hp/candy tier; server only rolls the skin id, S each skin)
Keep the zone hp/candy ladder; add a `skins` weight table per zone (cosmetic model swap, same hitbox). 4 skins per zone, 28 total, reuse one mesh family w/ recolor + 1 prop (stem/face) to stay cheap.
- Z1 Meadow: Orange 55, Squash 20, Corn bundle 15, Mini jack-o-lantern 10
- Z2 Graveyard: Ghost gourd 50, Skull pumpkin 25, Bone-wrapped 15, Coffin crate 10
- Z3-Z7: Witch cauldron, Candy-apple, Candy barrel, Crystal geode, Inferno ember (one theme skin each zone + 3 recolors)
Rule: 1 skin per zone is a "bonus chest" type (10%): hp x1.5, candy x2.5, gives bigger confetti. M for all art; S if recolor only (recommended for launch: recolors + 1 unique/zone).

## 2. Crack stages (S, client-only, driven by hp%)
Stage thresholds 100/66/33%: stage1 hairline decal + 4px shake; stage2 crack decal + stem wobble + 2 loose chunks fall; stage3 glowing split + squash 0.9 y-scale, jitter 6px. Break = 8 shards (pooled Parts, 0.6s life, 12 pooled shared) + 1 pulp puff + candy pop. Instant-kill (hp<=dmg) skips straight to full burst with 12 shards.

## 3. Golden / rare (server-rolled, M)
- Golden (existing 1/40 x20): gold shimmer + beam column visible 80 studs, unique chime, 20 candy fountain.
- NEW Rainbow Mystery 1/400: x100 candy + guaranteed Mystery pumpkin drop chance 10%. Server-wide? No, local toast only (CUT global announce).
- NEW "Ripe" (1/12): glowing, break within 4s of first hit = x2. Tiny skill hook, cheap (flag + timer). S.
- Pity: golden guaranteed if 90 breaks without one (counter per player). S.

## 4. Candy fountain (M)
Break pays through one pooled fountain per break: N coin-candies = min(candy, 12) arc out 0.35s, then magnet to the player 0.4s (stagger 25ms), each credits its share; total paid server-side instantly, visuals cosmetic. Golden: 30 pieces + upward burst. Max 60 live candy visuals per client; overflow merged into bigger pieces.

## 5. Combo / streak payout (server, S-M)
- Combo counts breaks; resets after 2.5s no break. Tiers: 5 breaks x1.1, 15 x1.25, 30 x1.5, 60 x2.0 (cap).
- Applies to candy only (not hp). HUD: big number + bar draining over 2.5s, color escalates white/yellow/orange/red; at 30 "FRENZY": +3 studs scythe trail, music pitch +2 semitones.
- Streak: breaks inside the same zone without leaving scores "Zone Streak" every 25 = flat bonus of 10x zone candy.
- AoE tie-in: existing arcTargets 3 ok; each extra target in one swing adds +0.1 combo credit.

## 6. Economy numbers
- Candy per break: raise ladder x3 across the board: 3 / 9 / 27 / 81 / 240 / 720 / 2160 (hp unchanged). Gives ~150 candy/min first minute with combo (was ~50), matching the "farming pays too little" complaint without breaking pet/pumpkin price curves (re-check first-purchase cost; keep first pumpkin buyable at ~90s).
- Respawn: 3s per spot, keep max alive 40/zone.
- Big (25% x6) -> 18% x8; crit 10% x3 -> 12% x3 with gold "CRIT" number; expected multiplier ~ +20% overall, then combo adds up to 2x.
- Target time-to-next-zone: Z1->Z2 (1000 candy) ~6 min, was ~20.
- All math server-side: client reports hit target id only; server validates range and cooldown (BonkCooldown style 0.35s).

## 7. Per-hit feedback tied to reward (S each)
Pitch ladder 1.0 -> 1.5 across combo tiers (+0.04 per break, reset on combo drop), break sound layered with candy "clink" per piece; hit-stop 45ms normal, 80ms crit/golden; damage number pop with scale 1.4->1 over 0.15s, gold for crit; camera nudge 0.6 deg on break only.

## 8. CUT
Global golden announcements, per-piece physical candy collisions, >4 skins/zone at launch, unique meshes per skin, crop-growth stages, quest for breakables, leaderboard of combos.

## Launch priority
S: ladder x3 + combo + pity + crack stages + recolor skins + pitch ladder. M: fountain, Ripe/Rainbow, chest skin.
