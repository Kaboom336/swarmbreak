# Arena round 4 — review of Feed the Giant (2026-10-07)

3 independent reviewers (design, systems/feel, map/art) read the code and 5 fresh Studio screenshots. Evidence: one full round played by Zion (65 gold = 8×5 + 25, no console errors).

## Keep (all three agree)
- The feed moment: hold E, pumpkin becomes a lit jack that stays, seeds arc in, giant squash-swells, full ring awakens.
- Dusk palette and the straight spawn → arch → giant view.
- Server decides who carries what.

## Batch 1 — look and bugs (building now)
1. Sockets: stone dish, no glow when idle; ghost pumpkin + glow only while you carry. (map, systems)
2. Giant as hero: bigger start, stepped altar, orange outline + uplight, more embers. (map)
3. Patch reads as soil: dark sunken dirt, sprouts, wooden fence. (map)
4. Remove white blob props; group dressing into small scenes; candle flames. (map)
5. Move the arch so carries walk under it. (map)
6. Bugs: socket prompts show to everyone after round 1 (Feed.server.luau clearSockets); giant sinks into the altar at the end of the awaken (client reset before server); late joiners see a small giant; Pick sound never plays; pumpkin vanishes if you die mid-carry. (systems)

## Batch 2 — reasons to keep playing
7. Spend and save gold: seed stand with Faster Grow / Bigger Pumpkins / Strong Arms; save with the existing Data.luau. (design, systems)
8. Random pumpkin sizes when ripe: Normal / Big / rare Giant, worth more gold. (design)
9. Awaken counter: each awaken unlocks a new giant form and a bigger ring. (design)
10. First minute: 3 ripe pumpkins at start, a glowing trail from spawn to the patch. (design)

## Batch 3 — friends
11. Rare Giant pumpkins need two carriers; team bonus when 2+ players fill a ring. Needs a 2-client physics test first. (design; physics risk flagged in round 1)

Full reviewer notes: arena scratch folder r4/REVIEW-*.md.
