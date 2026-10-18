# Steal a Treasure — week 1 base loop

**GAME:** Steal a Treasure. **PITCH (10 words):** Buy treasures, earn cash, expand your base, and steal riches.
**CORE VERB:** Buy. **REFERENCE HITS:** Steal a Brainrot + Steal an Egg. **RECIPE:** Steal / tycoon.

**FIRST MINUTE:** Targets: first reward <30s, first owned earner <120s. Start $600; starter costs $600 and earns $5/s. Purchase triggers ownership; delivery starts income. Three tutorial banners: **Buy a treasure! → Collect your cash! → Unlock a pedestal!** One arrow, no join popup. Five learning groups: buy, collect, expand (slots/speed), steal/carry, defend (lock/slap); PvP gated behind three purchases for both sides.

**LOOP:** Shared carpet → E buy → treasure walks home → $/s piles up → step on Collect → buy/unlock. Target trip 15–45s, stations 3–15s apart; actual human timings NOT RUN. Every placed treasure pops +$ every 1s. Price = 120/140/160/180/200 × effective income/s across tiers (bible range 110–200). Growth aspiration x2 per 1–1.5 minutes is not a measured result; see OFFLINE-RESULT.txt for modeled growth.

**ECONOMY:** One cash currency. 25 definitions, five each: Common green #3CDC3C, Rare blue #0B75F0, Epic purple #B44CFF, Legendary yellow #FFD21E, Mythic red #E01010. Spawn rarity weights 65/23/9/2.7/0.3%; every 3s. Normal/Gold/Diamond odds 96/3/1%; Gold income ×1.5, Diamond ×2; price scales too to preserve payback. Ten pedestals, four open; sequential unlocks $100 / $1,500 / $5,000 / $25,000 / $62,500 / $156,250. Speed +2 per level; $100 ×2.5^level, ten levels. Offline income at current rate, capped at 1h per absence; banked automatically on load.

**CLOCK:** Shared guaranteed Legendary every 5min. Lock 60s, then 60s cooldown; no extension while locked. Steal hold 2s; carry speed 10 vs default 16. Drop, damage, owner slap, death or disconnect returns the treasure. Crossing home assigns the reserved pedestal. Owner is warned at grab and delivery.

**HUD:** Cash + income top centre (locked direction overrides bible bottom-left); Shop placeholder and Index on left; Drop only while carrying. One objective banner and arrow, RUN!! while carrying, 3s toast, offline-cap line, one Legendary clock. Index: 25 rows, discovered names or ???. White stroked type, rarity colours on labels.

**WORLD / ART:** One flat grass-colour part, central straight carpet, central spawn, eight 56×48-stud plots in two rows, ten pedestals each. Next $100 price pad visible in each base. All earners are plain anchored 3-stud blocks, one replaceable factory; mutations recolour only. No external art, reveal, sound, terrain detail or polish in this task.

**LIMITS / LATER / ROBUX:** Five learning groups, two persistent HUD buttons, three prompt actions (Buy/Steal/Lock), no join popup. Locked direction overrides bible's ten-minute PvP gate with three purchases. Shop has no commerce. Rebirth, selling, events, zones, paid offers and real art wait for a later approved task.

**CHECKS:** Lune Rules/save/economy suite + serialized place structure suite; Studio EDIT BaseTest and Zion's two-player plan in TESTS.md. Blind frame judges, device checks and Zion's 10min playtest NOT RUN. Build-only greybox, not a launch approval.
