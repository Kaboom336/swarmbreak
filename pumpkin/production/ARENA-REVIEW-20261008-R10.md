# Arena round 10: polish, movement, boss (2026-10-08)

Trigger: Zion played round 9 ("loop is a lot more fun") and asked for polish, faster movement and a better boss, plus anything else the game needs.

Proposals (scratchpad arena/r10): PBoss (3-phase raid), PFeel (movement and juice), PMissing (retention and first 10 seconds).

## Built (in Studio, repo src/ and scene/)
- Movement: WalkSpeed 24, sprint 34 on Shift / mobile RUN with FOV kick, -1 speed per carried pumpkin (floor 20), JumpPower 55. Jump pads on each road (scene/Dressing10.luau) using a short LinearVelocity.
- King raid: HP 40 + 100/player, 150 s. Red-circle Slam (r 24, 1.4 s warn) and Seed Volley (circle under each player, 1.6 s). Hits knock back + 1 s dizzy. Phase 2 at 66%: shield + Lantern Lackeys at cauldrons; popping all stuns him 6 s (x2 damage). Phase 3 at 33%: faster attacks, red glow. Swell-and-burst finale, MVP crown, last-hit bonus, top-3 board, fail refills the Jack 50%.
- Mallet: 3-step swing, combo counter, mobile BONK button.
- Index: 6 seeds x 5 finishes, NEW banners, +10% per finished row, server announce for Cursed sales. Saved in DataStore field `index`.
- Upgrades longer: Stack 6, Mallet 10, Green Thumb 5, cost = base x n^1.6.
- Ghosts: sheet skirt + trail. Road jack-o'-lanterns. Brighter midnight. Banner queue.

## Not built yet (from proposals)
- Music crossfades (need auditioned free audio), button hover juice, candy fly-to-counter.
- Witch's Orders / NEXT goal chain, patch expansion, Haunt rebirth, login chest, offline growth (needs publish + saving).
- Vine Sweep and Rolling Jacks King attacks.
- PMissing suggested 12-player servers; decide at publish.
