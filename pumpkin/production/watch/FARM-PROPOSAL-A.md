# FARM PROPOSAL A: Swing and hit feel first

Current state (read from code): one swing anim (0.42s, wind up right, slash left), BonkCooldown 0.55s, server `Wild.hit` takes nearest pumpkin in BonkRange 11, tier>=3 also hits up to 2 more within arcRange 6 (dot>=0.5). Single Whoosh/Bonk sound, no hit-stop, no combo. The foundation exists; this proposal is mostly juice plus a streak.

## 1. Swing system: 3-hit combo chain (client anim, server validates)
| Hit | Anim (Grip keys in `KEYS`) | Total anim | Hit frame | Dmg mult | Arc |
|---|---|---|---|---|---|
| 1 Forehand | wind up right, slash right-to-left (existing keys) | 0.36s | 0.14s | 1.0 | 110 deg, 11 studs |
| 2 Backhand | wind up left, slash left-to-right (mirror roll signs: 32/-34) | 0.36s | 0.12s | 1.0 | 110 deg, 11 studs |
| 3 Overhead slam | raise pitch -150 over 0.14s, slam to +20 | 0.52s | 0.20s | 1.6 | 360 deg ring, radius 8 (ground shockwave) |

- Chain: each swing accepted on a 0.40s cooldown (was 0.55; Fast Hands divides as today). Pressing again within 0.65s of the last swing advances the combo; later resets to hit 1. Hit 3 adds 0.15s recovery, then resets. Cycle = 0.40 + 0.40 + 0.55 = 1.35s for avg damage 1.2x, so about +60% DPS vs today. Hold-to-swing on PC/mobile (auto-repeat while the button is held) so tapping is not required. [S]
- Server: `Wild.hit(player, root, comboStep)`; step 1-3 clamped, must not arrive faster than 0.34s after the previous (anti-spam); multiplier applied in `swingDamage`. [S]
- Area sweep for ALL tiers (replace `order >= 3` gate): hits 1-2 hit up to 3 pumpkins in the 110 deg arc, hit 3 hits up to 6 in the ring. Tier raises count: arcTargets = 3 + floor(tier/3), max 5; hit 3 = arcTargets + 2. Per-target damage is full (no split) so crowding pumpkins is the skill. [S]
- Hitbox arc is server-side dot product, not parts: arc dot >= 0.34 (110 deg) for hits 1-2, no dot for hit 3. Add 0.15s lag grace on range (+1.5 studs). [S]
- Trail: reuse `SwingTrail`, enabled 0.07-0.30s; mirror attachment for backhand, third is vertical trail, wider (width x1.6). [S]

## 2. Feedback stack per hit (client, off `wildHitEvent`)
| Layer | Normal hit | Crit | Break (pop) | Overhead hit 3 |
|---|---|---|---|---|
| Hit-stop | 45ms | 80ms | 110ms | 130ms |
| Camera nudge | none | 0.8 deg pitch kick, 90ms | FOV +3 punch 120ms | FOV +5, 2 stud shake 150ms |
| Number pop | white, size 28 | gold, size 40, "CRIT!" | candy "+N" flies to counter (exists) | combo count text "x3" |
| Squash | pumpkin scales 0.88 Y for 70ms (tween back, Back easing) | 0.8 Y | burst | ring pulse |

- Hit-stop implementation: freeze the swing `RenderStepped` clock (hold `started` offset) and set pumpkin `Anchored` tween to pause for N ms; no yielding, no timeScale tricks. Lock attacker animation only, never gameplay. [S]
- Sound ladder: Whoosh pitch 0.95/1.05/0.85 (hit 1/2/3), volume 0.5. Hit impact: Bonk pitched `1.0 + 0.06 * min(streak,12)` (a semitone per hit, rises 12 steps then holds), volume 0.5 + 0.03*streak (cap 0.9). Break: Pick pitched 0.9 + 0.04*streak plus Coin tick at 1.2. Overhead adds Roar at pitch 1.6, volume 0.4 as thud layer. Streak resets after 1.2s idle (client). Layering 2 sounds per hit max, each from a small pool of 6 reused Sound objects. [S]
- Free SFX to source: need one wet "crunch/squish" and one deep thud (search Roblox library, audio only; ProSoundEffects style as Whoosh). [S]
- Particles: one pooled ParticleEmitter per swing hit (Emit 6 at hit, 14 at break, 30 at hit 3), colour = pumpkin tint; 4 chunk Parts reused from a pool of 24 (not new Instances) arcing with simple velocity for 0.5s then returned. [M]

## 3. What breaks (crack stages)
Keep one pumpkin model per zone; make it break visibly. Stage swap by hp fraction: 100% intact, <66% crack decal 1 (SurfaceGui-free: swap MeshPart TextureID), <33% crack decal 2 + wobble. Break: 6 chunk pieces (pooled) + 2 seed/leaf sprites + candy pop. Fruit variants are CUT for launch (art cost); zone tint and size already differ. Crack textures: one 3-frame atlas, 3 quads. [M]

## 4. Reward tuning (server, `pop`)
- Zone candy x2 across the board (z1 candy 1 -> 2, z2 3 -> 6, z3 9 -> 18, etc.; hp unchanged). Farming pays about 2x per pumpkin; combined with +60% DPS, income per minute is about 3.2x. Re-check zone 6-8 progression sim (`Config.Progression` note) before launch. [S]
- Streak bonus: smashes (pops, not hits) in a row with no gap > 3.0s: +4% candy per streak, cap +40% at 10. Server-owned counter per player, reset on timeout. Shown as "x7 STREAK +28%" under the counter. [S]
- Combo finisher: a hit-3 that pops 3+ pumpkins gives +25% candy on those pops ("SWEEP!"). Naturally rewards the area slam. [S]
- Keep existing bigChance 25% (x6) and golden 1/40 (x20); add a bright gold flash + longer 140ms hit-stop on golden. [S]

## 5. Mobile
Tap = swing, hold = auto-chain. Hit-stop and shake scale to 60% when `UserInputService.TouchEnabled`. Particles halved. [S]

## 6. CUT for launch
Fruit/gourd variants per zone, per-zone unique break SFX, ragdoll pumpkin physics, camera orbit on slam, tool-specific combos (one combo for all tools), slow-mo.

## 7. Effort and order
1. Combo + server step + damage mult + area for all tiers [S]
2. Hit-stop + sound ladder + number pop [S]
3. Streak bonus + candy x2 [S]
4. Pooled chunks/particles + crack stages [M]
Total: about 1 day for Codex for 1-3, plus half a day for 4.

## Risks
Candy x2 changes gate cost pacing: re-run sim. Hit-stop must freeze visuals only; server timings unaffected.
