# Pillar: progression-economy (upgrade ladder, gates/zones, pet rarity, rebirth, reward cadence)

## Chosen game
**Steal an Egg (fresh-account "Starting OVER Using NO ROBUX in Steal an Egg", 4JdUNbmTBtw, uploaded 2026-09-03, 22 min; all 5 frames from it).**
Why: it is our exact genre (steal, carry home, pen earns per second) and it is the cleanest visible ladder on Roblox: a straight corridor of zones, speed-gated by a treadmill whose upgrade sign always shows a cash price next to a Robux price, pets with a rarity colour and a $/s number, an Index with "???" silhouettes and a reward per set, offline pay shown on screen, and several timers always counting. Every purchase shows what it costs, what it gives, and how long until the next free thing.

## Reference frames (1280 wide)
1. **ref-1** (4:18) Treadmill "Upgrade Level 2 > Level 3" sign: red cash price $250K next to a purple Robux price 45, "+10" speed pops on each step, SELL stall and Fuse Machine in view, speed counter 10.1K bottom-left, next-event clock bottom-right. Notice: one sign, two prices, a visible number going up while you stand on it.
2. **ref-2** (7:24) Pet Index: desert page with 8 slots, a coloured silhouette per rarity with "???" until found, 2/8 complete, "Unlocked 11/106", reward box ($1.6M + 12.6K speed) with a CLAIM button; top banner "You earn $67M/Day offline!". Notice: every missing pet has a rarity colour and a reason to go find it; offline pay is told once, big.
3. **ref-3** (7:22) Mythic pet in a pen: "+$18K" popup and "$18K/s" label on the pet, "Egg 2m 1s" timer on the egg, "Upgrade Pen Level 1 > Level 2 $1M" sign in the foreground. Notice: income popup, per-second rate, hatch timer and next upgrade all within one screen of the pen, with no menu.
4. **ref-4** (14:56, zoomed) Reward timers panel: 16 s, 6m 17s and 7h 54m bars with green fill and a green play button. Notice: three different clocks (seconds, minutes, hours) so there is always something about to pay out.
5. **ref-5** (17:58) Late game pen: "+$222K", "+$5.2M", "+$321K" popups floating from different pets at the same time. Notice: the numbers are 3 orders of magnitude bigger than minute 4 ("+$168"), and the same green popup style still reads. That is what 15 minutes of ladder feels like.

## Ours must...
1. Gate spacing: arrive at Zone 2 at about 3 min, Zone 3 at 10, Zone 4 at 18, Zone 5 at 30 for an active player (checklist P1, FINISH-PLAN proposal). Gap never above 8 min before minute 30.
2. Price ladder: each zone gate costs 3-7.5x the previous (ref: PSX 10k/75k/400k/1.25m); each zone pays 3-10x more candy per smash than the one before (Zone 1 = 8, Zone 2 = 80, per FINISH-PLAN). Pet price in candy = 110-200 x its income/s so it pays back in 2-3 min.
3. Every upgrade sign shows: name, "Level N > N+1", candy price (green/orange) and, if sold, a Robux price beside it (ref-1). Never a sign with just a price.
4. Always-on "next gate" bar: a thin bar plus "%" to the next gate, visible in the HUD at all times (checklist R5, L4). Next purchase affordable in 3 min or less at every point.
5. Rarity ladder of 5-6 tiers in fixed colours (Common grey #8A8A8A, Rare blue #2C8CFC, Epic purple #B44CFF, Legendary yellow #FFD21E, Mythic red #E01010, Secret black with white stroke). Index slot for each unfound pet is a tinted silhouette of that rarity with "???" and a hint line (where it drops).
6. Index rewards at set completion (ref-2): each zone page pays a candy lump (10-20 min of income) plus a permanent small boost, and shows "Unlocked N / total" on the button.
7. Income is visible: every placed pet shows "$/s" in its rarity colour and a "+N" green popup each second (ref-3). Popup text height 3-4% of screen.
8. Three clocks, no more than three: next nest refill (5:00), next free gift (about 6 min first, then longer), and the King. Matches ref-4: seconds, minutes, hours bars. One clock on the HUD at a time in the first 10 minutes.
9. Offline pay: "While you were away" shows once on rejoin, 25-50% of rate, 2 h cap (checklist R1); our score today is 0.
10. Rebirth appears at 50% of its cost: one banner with 5-7 reward tiles, needs a Legendary (PROGRESSION-PLAN), +25% candy each, cap 10. No rebirth button in the first 30 min.
11. Surprise event every 60-120 s of play (golden pumpkin, mutation, bonus drop) so the ladder is never flat; pity counter visible ("Legendary in 4 more") on the crate (checklist P4, P5).

## Ours today (honest)
- Per the audit: a 7-minute flat dead zone, a 318k gate, 228k idle candy hoard, income 1% from smashing, gates at 4/15/32 min instead of 3/10/18; scythes buy nothing that matters (L5 = 3/10, P2 = 2/10).
- Pity is 10 crates (about 200 min) and not shown, no odds screen, no offline income at all (R1 = 0), index "???" slots have no hints, King fight pays about 8 s of income, no "next gate %" bar (R5 = 3/10).
- r3-hud shows a bare HUD: Carry 0/3, candy 0, +0/s, "King unlocks 9m 10s", "Nests 1m 37s" and a zone quest box (Smash 50 / Steal 1 / Own 1, "Next gate 25% off"). Good bones, but no shown price, no next-gate bar, two clocks at once, and no rarity colours anywhere.

## Assets needed (do not insert; free / no-script only)
- **Upgrade sign / shop kit (dark sign board, cash and Robux price buttons, Level N > N+1)**: Creator Store "shop sign gui", "upgrade button ui", "price tag billboard gui".
- **Pet rarity pack (recolour-ready pets and rarity pill labels)**: "halloween pets", "cute ghost pet", "low poly bat pet".
- **Index / collection UI kit (silhouette grid, ??? slots, claim button, progress bar)**: "inventory gui pets", "collection book ui", "index gui halloween".
- **Zone gate hero pieces (big gate with price billboard and per-zone colour)**: "halloween gate", "iron cemetery gate", "wooden arch sign".
- **Clock and reward timer UI (progress bars, countdown chips, gift icon)**: "countdown timer gui", "daily reward ui", "progress bar gui".
- **Currency and number-pop assets (candy icon, stroked green +N popup, rarity glow)**: "candy corn icon", "currency icon halloween", "floating text effect".
