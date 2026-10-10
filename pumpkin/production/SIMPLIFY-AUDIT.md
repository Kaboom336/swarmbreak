# Simplify audit: Pumpkin Patch Panic vs Steal an Egg (first 10 minutes)

Date: 2026-10-09. Owner verdict: "the game is too complex". Read-only audit.

Sources:
- Code: `giant/src/ServerScriptService/Patch.server.luau` (S), `giant/src/StarterPlayerScripts/Patch.client.luau` (C), `giant/src/ReplicatedStorage/PatchConfig.luau` (P). Line numbers are from today's files.
- Play: Watch_1..6 screenshots (Zion, r16) and `scratchpad/arena/r16-watch-notes.md`.
- Reference: `refs/STUDY-STEAL-AN-EGG.md` and sheets s002 (0:18-0:34), s009 (2:24-2:40).

## 0. Headline numbers (first 10 minutes)

| What the new player meets | Ours | Steal an Egg | Target after cuts |
|---|---|---|---|
| Core systems / mechanics | 30 | 10 | 12 |
| Currencies / visible counters | 7 (+3 more inside panels) | 2 (speed, money) | 2 (candy, candy/s) + carry |
| Left HUD buttons (always on) | 5 (Tools, Index, Haunt, Lock, Sound) + Drop, mobile RUN, mobile SWING; Shop when IDs are set | 2 (Shop, Index) + Drop while carrying | 2 (Shop, Index) + Drop |
| Panels / popups | 7 (Daily, Tools, Upgrades, Index, Haunt + skill tree, Shop, Reveal) | 4-5, all optional, none forced on join | 3 (Shop, Index, Reveal) |
| Prompt types (verbs on E) | 10 (Place, Pick up, Steal plot, LOCK, Steal Hoard, Brew, Sell, Tools, Upgrades, Unlock gate) + Pick up loose | 3 (Steal/hold E, Hatch, Place pet) + walk-in shop | 4 (Place, Steal Hoard, Shop, Unlock gate) |
| NPCs / stalls / world objects to learn | 12+ | 5 (guards, Trails Shop, gift box, treadmill, upgrade sign) | 6 |
| Timed events | 7 | 1 (day/night egg reset) | 1 (midnight reset) |
| Tutorial steps | 9 steps, 8 different verbs, 6 different places | 6 banners, one verb each, over ~5.5 min | 5 steps over ~3 min |

Steal an Egg (SaE) loop in the reference: banner "Steal an Egg!" (0:34) -> hold E at a sleeping "ZZ" guard (0:52) -> RUN!! -> "You stole an EGG!" (1:28) -> "Go to your Pen!" (1:30) -> "Hatch the Egg!" (1:44) -> "Place your Pet!" (1:54) -> "+$5" pops (2:04). Only then: "Not enough speed" (2:44), first reset (3:08), Trails Shop (3:40), Shop (4:12), "Upgrade your Pen!" (5:00), treadmill (5:36). Inventory, Free Gift and Sell come after minute 11.

## 1. Inventory: what a new player meets in the first 10 minutes

### 1a. Systems and mechanics (30)
| # | System | Where | Met when (r16 watch) |
|---|---|---|---|
| 1 | Smash wild pumpkins with a held scythe (HP bars, damage numbers, candy burst) | S wild zones ~2540; C 2507 scythe, 2675 effects; P `Seeds.hp`, `PopCandySeconds` | 0:00, step 1 |
| 2 | Carry stack (cap 2) and its HUD line "0/2 Carrying · worth" | S `refreshCarry` 1175, `stackPumpkin` 1316; P `BaseCarry` | 0:10 |
| 3 | Loose pumpkins (overflow lies 30 s, "Pick up" prompt) | S `dropLoose` 1361; P `LooseSeconds` | when full |
| 4 | Place on base plots -> income per second | S `place` 1769; C 2652 | step 3 |
| 5 | Pick up from your own plot | S `pickUp` 1821 | any time near a filled plot |
| 6 | Carving timer -> Living Jack hopping | S 1622; C 4929, 4997; P `CarveSeconds` 20 / 8 | after place ("Carving 0:07", Watch_2) |
| 7 | Size roll (x0.85-1.4) on every pumpkin | S 2362, 2541; P `SizeMin/Max` | invisible |
| 8 | 10 pumpkin types, 6 rarity names | P `Seeds`, `Rarities` | first smash |
| 9 | Hoard steal: sleeping guardian, chase, BONKED, refill | S `buildHoard` 3402; C 4890, 4962; P `Hoards`, `Guardian*` | step 2 |
| 10 | Steal from other players' bases (hold 1.5 s) | S `steal` 1843 | prompt visible from 0:00 |
| 11 | Steal rules: protected best pumpkin, new-player shield, victim cooldown, owner share | S 1855-1866; P `NewPlayerShield` 600, `VictimCooldown`, `StealOwnerShare` | hint toasts |
| 12 | Rescue a stolen / ghost-grabbed pumpkin | S 1913-1917 | Watch_5 toast |
| 13 | Lock your base (45 s, 90 s cooldown) | S `Bases.lock` 2000; C 1396; P `LockSeconds` | tutorial step 8 |
| 14 | Magic Cauldron brew -> 4 mutations (x2..x10) | S 3588; P `Mutations` | step 4 |
| 15 | Sell to the Witch (30 s of income) | S 3683; P `SellPerIncome` | step 5 |
| 16 | Tool shop: 6 scythes | S buyTool 3825, `giveTool` 4587; C 1161; P `Tools` | step 6 |
| 17 | Upgrades stall: Bigger Stack, Sharp Blade, Lucky Swing | S 3853; C 1157, 1238; P `Upgrades` | "UPGRADES" stall at spawn |
| 18 | 4 zones with candy gates and emoji ladder | S `unlockZone` 2588, gate prompt 2703; C 3061; P `Zones` | after tutorial |
| 19 | Witch's Orders: 9 tutorial + 15 rotating, 20 min refresh | S 343-510; P `TutorialOrders`, `RotatingOrders` | whole session |
| 20 | Day / Midnight cycle (150 s + 45 s) | S `runDay` 5205; C lighting 2380 | first midnight at 2:30 |
| 21 | Midnight ghost raids on bases, ghost bonking | S `spawnGhost` 4262, `stealTargets` 4242; P `Ghost*` | 2:30 (Watch_5: "A ghost grabbed your pumpkin!") |
| 22 | Giant Jack meter (server sales) | S `recomputeJack` 3672; C chip 580; P `JackGoal` | top-right chip "0/400" from 0:00 |
| 23 | Blood Moon (all locks off) | S `startBloodMoon` 5108; P `LocksOffSeconds` | when Jack fills (>= 6 min) |
| 24 | Pumpkin King boss: slam, volley, shield, Lantern Lackeys, stun, dizzy, MVP, top damage | S 4659-5108; C 4536-4835; P `King*`, `Attack*`, `Lackey*` | chip "King wakes 2:39" (Watch_6) |
| 25 | Candy rain after the King | S `rainCandy` 4834 | event |
| 26 | Pumpkin Index (10 types x 5 finishes = 50) + row bonus | C 1271, 1304; P `IndexRowBonus` | Index badge "1", "3" (Watch_4-6) |
| 27 | Haunt rebirth + Souls + 9-node skill tree | S 3923, 3976; C 1438-1735; P `Haunt*`, `Skills` | pill visible from 0:00 |
| 28 | Daily chest, 7-day strip, Cursed token | S `claimDaily` 5239; C 4089; P `Daily*` | forced popup at 0:00 (Watch_1) |
| 29 | Sprint (Shift / RUN) + jump pads | C 4403, 4469; P `WalkSpeed`, `SprintSpeed`, `Pad*` | invisible / world |
| 30 | Shop: passes and candy packs (hidden while IDs are 0) | C 1739-1860; P `GamePasses`, `Products` | hidden today |

Plus reward reveal cards (C 1967), music (C 1337), the world leaderboard (S 5265). These are feedback, not rules, and are not counted.

### 1b. Currencies and counters (7 on the HUD or world)
Candy (C 667), Income/s (C 667), Carry n/cap + worth (C 812), Giant Jack n/goal (C 580), phase clock (C 580), Kings leaderstat (S 5601), Index badge count (C 1391). Inside panels: Souls, Haunts, Cursed Tokens. SaE: Speed and Money.

### 1c. HUD buttons
Always on (Watch_1-6): Tools (C 1875), Index (C 1391), Haunt (C 1926), Lock (C 1398), Sound (C 1367). Conditional: Shop (C 1911, hidden while IDs are 0), Drop (C 3869, while carrying), RUN and SWING (C 4421, 4533, touch). Other HUD: objective banner (C 3287), top-right chip (C 580), toasts (C 524), RUN!! pill + vignette (C 3851). SaE: Shop, Index, Drop while carrying, RUN!! pill, banner, timer.

### 1d. Panels and popups (7)
Daily Reward (C 4089, opens on join over the first objective, Watch_1), Tools (C 1164), Upgrades (C 1157), Pumpkin Index (C 1271), Haunt + Soul tree (C 1442), Shop (C 1784), Reward Reveal card (C 1967). Banners on top: ORDER DONE!, NEW IN YOUR INDEX!, MIDNIGHT!, BLOOD MOON!, THE PUMPKIN KING WAKES!, SHIELD UP!, THE KING IS ANGRY!, BONKED!, HAUNTED! (C 1716-4912).

### 1e. Prompt types (10 verbs, 11 prompts)
Place (S 2122), Pick up own plot (S 2125), Steal other base (S 2128), LOCK on sign post (S 2141), Steal Hoard (S 3249), Brew (S 3592), Sell (S 3689), Tools (S 3783), Upgrades (S 3783), Unlock zone gate (S 2703), Pick up loose pumpkin (S 1383).

### 1f. NPCs, stalls, world objects (12+)
Witch sell stall, Tools stall (old Seeds stall), Upgrades stall, Magic Cauldrons (at least 2 near spawn, Watch_5), Scarecrow guardian + Hoard nest, 3 more guardians behind gates, midnight Ghosts, Pumpkin King + Giant Jack, Lantern Lackeys, 3 zone gates, jump pads, leaderboard, other players' bases (Steal prompts, "Free base" signs).

### 1g. Timed events (7)
Daily chest on join; Midnight every 195 s (first at 2:30) with ghost raids; Blood Moon (locks off 120 s); Pumpkin King fight (150 s); Candy rain; Witch order refresh (20 min); Hoard refill (30 s per pumpkin).

### 1h. Tutorial (P `TutorialOrders`, 9 steps)
1 Smash 3 (zone) -> 2 Steal a Golden Pumpkin (Hoard) -> 3 Place (base) -> 4 Brew (cauldron) -> 5 Sell (Witch) -> 6 Buy Wooden Scythe (Tools stall) -> 7 Bonk 3 ghosts (only at midnight) -> 8 Lock your base -> 9 Hit the King. Eight verbs, six destinations, two steps that wait on server events (7 and 9).

### 1i. Problems seen in play that come from the complexity
- **The banner shows two goals at once.** With empty hands, a Place/Brew/Sell/King step shows "Smash a Pumpkin!" with "Step 4/9 · Brew..." under it (C 3790-3800; Watch_3). SaE never does this.
- **The Hoard step says "Golden" but the Zone1 Hoard is Ghost (white)** (P `Hoards.Zone1.type = "Ghost"` vs the text in P `TutorialOrders[2]` and C 3729). The nest in Watch_5 is white.
- **Step 2 comes before step 3**, so a player who still carries 2 smashed pumpkins is told "Hands full: place these, then go steal!" (C 3733). This is a detour inside step 2.
- **The Daily panel covers the first banner** at 0:00 (Watch_1). SaE opens with nothing but the banner and the arrows (s002, 0:24-0:34).
- **A midnight ghost took his only good pumpkin**, income went to 0/s, and step 7 stayed 0/3 (watch notes, Watch_5). Ghosts ignore the 600 s new-player shield: `stealTargets` (S 4242) only skips locked bases, while player stealing respects `NewPlayerShield` (S 1861).
- **Lock is useless for the first 10 minutes** (players cannot rob you for `NewPlayerShield` = 600 s), yet it has a pill, a sign prompt and a tutorial step.
- **Income fell from +65/s to +1.3/s** (watch notes, Watch_4). The likely cause is the Pick up prompt on his own plot (0.3 s hold, S 2125) firing while he walked over the base. Selling and brewing are the only reasons to pick up, so the prompt is a trap early on.
- **He idled on the Tools stall roof** during midnight (Watch_5/6): the arrows pointed at the base and ghosts, but there was no ghost near him and no clear next step.
- **Haunt costs 2.5M candy** (P `HauntCost`) but its pill is on screen from 0:00. Zion had 3.7k at ~5 min.

## 2. Verdicts: KEEP / MERGE / CUT / LATER

LATER means hidden until about 30 minutes of play or a clear trigger. The trigger is given in each row.

| System / element | Verdict | Reason, tied to the reference |
|---|---|---|
| Smash wild pumpkins | KEEP | Our one "get loot" verb, like SaE's hold-E steal. Step 1 drops to 1 pumpkin, not 3. |
| Carry stack + carry line | KEEP | SaE shows carry state (Drop + RUN!!). Keep cap 2. |
| Drop button | KEEP | Same as SaE's red Drop button, shown only while carrying. |
| Loose pumpkins | KEEP | No UI. It only matters when the stack is full. |
| Place on base -> income | KEEP | This is SaE's "Place your Pet!" -> "+$5" pops (1:54-2:04), the core payoff. |
| Pick up from own plot | LATER (when the Witch unlocks) | SaE has no pick-up from the pen early. It only feeds Sell/Brew, and it likely caused the +65/s -> +1.3/s drop. |
| Carving timer / Living Jack | KEEP | This is SaE's egg timer and hatch (1:42-1:48). Cap it at 8 s for every type in the first session. |
| Size roll | KEEP | Invisible. It adds no decisions. |
| 10 types + rarity names | KEEP | Same as SaE's rarity reveal ladder (Common $5/s ... Eternal). |
| Hoard steal + guardian chase | KEEP (make it step 3) | This is SaE's whole hook: "ZZ" guard, red "!", RUN!! (Study §8.2-8.3). Fix the "Golden" text to the real type. |
| Steal from other players | LATER (when your own shield ends, 10 min) | SaE's first 10 min steal only from NPC nests. It should match the 600 s shield we already give victims. |
| Steal rules (protected, shield, cooldown, share) | KEEP (hidden) | These are rules, not UI. They only surface as toasts once player stealing unlocks. |
| Rescue stolen pumpkin | LATER (with player stealing) | Rescue has no meaning before anyone can be robbed. |
| Lock base (pill + sign prompt) | LATER (when the shield ends) | Locking is a no-op under the shield. SaE has no lock. Remove its tutorial step. |
| Magic Cauldron / mutations | LATER (30 min) | A multiplier layer. SaE shows none in the first 10 min. Cauldrons stay as scenery without a prompt until then. |
| Sell to the Witch | LATER (all plots full, or 30 min) | SaE's Sell first shows at 15:42. Income comes from the base, as in SaE. |
| Tools pill | MERGE into Shop | SaE has one Shop pill plus a walk-in shop. Two buttons that open shop panels is one too many. |
| Tool stall + Upgrades stall | MERGE into one "SHOP" stall | One stall at spawn with two tabs (Scythes, Upgrades), like SaE's single Trails Shop. |
| Scythes (6 tiers) | KEEP | Same as SaE trails: the first purchase, with a clear number ("x3 damage"). |
| Upgrade: Bigger Stack | KEEP (rename "Upgrade your Base!") | This plays the part of SaE's "Upgrade your Pen!" beat (5:00). |
| Upgrade: Sharp Blade | CUT | It duplicates scythe tiers (both are damage). Two ways to buy the same number confuses players. |
| Upgrade: Lucky Swing | LATER (30 min) | Odds tuning, with no SaE equivalent early on. |
| Zones + gates + emoji ladder | KEEP | Copied straight from SaE (Forest 🙂 ... Cosmic 😈). The first gate (1k) becomes the post-tutorial goal. |
| Witch's Orders, tutorial | MERGE into 5 steps (section 3) | SaE uses 6 single-verb banners over 5.5 min. Ours uses 9 steps with 8 verbs. |
| Witch's Orders, rotating | LATER (after the tutorial and the first gate) | The banner then shows one rotating order at a time, never two goals. |
| Day / Midnight clock | KEEP (as the "reset") | This is SaE's moon timer and "ALL EGG RESET!" (3:08). Midnight should refill every Hoard nest. |
| Midnight ghost raids + bonking | LATER (when the shield ends) | SaE's reset never takes anything from you. Ghosts must skip shielded bases (S 4242). |
| Giant Jack meter on HUD | CUT from HUD | SaE's top-right shows only the timer. The Jack stays as a world landmark. |
| Blood Moon + Pumpkin King + Lackeys + rain | LATER (30 min, or spectate) | This is a raid layer with no SaE equivalent. New players should see it as a spectacle, not a tutorial step. |
| Kings leaderstat, Title | LATER (with the King) | It is a counter that stays at 0 in the first session. |
| Pumpkin Index | KEEP (types only) | SaE Index with a red badge. Show 10 type slots; the 5-finish grid goes LATER with brewing. |
| Index row bonus | LATER (with brewing) | It needs finishes. |
| Haunt pill + Souls + skill tree | LATER (at 50% of Haunt cost) | It costs 2.5M; Zion had 3.7k at 5 min. SaE shows no rebirth early. |
| Daily chest popup | LATER (no popup on the first visit) | SaE opens on the banner only. Its Free Gift appears at 13:20. On day 1, grant it silently with a toast. |
| Cursed token | CUT | It is a one-off currency for a LATER system. Give extra candy instead. |
| Sound pill | CUT | SaE has none. Use the Roblox menu, or one small gear icon. |
| Shop pill (passes / packs) | KEEP | It is SaE's green Shop pill, on from 0:00. Merged with Tools as described above. |
| Sprint + jump pads | KEEP | Invisible. They add fun without decisions. |
| Mobile RUN / SWING buttons | KEEP | Input only. |
| Reward reveal card | KEEP | Same as SaE's hatch reveal (2:22). |
| Leaderboard (world) | KEEP | SaE has a world board (9:52). It is passive. |
| Order / Index / event banners | MERGE into toasts | SaE uses small bottom toasts. Keep big banners for the reveal and the reset only. |

Result: 20 KEEP, 4 MERGE, 4 CUT, 14 LATER. In the first 10 minutes the player sees 2 pills (Shop, Index) + Drop, 4 prompts, 1 stall, 1 guardian, 1 timer and 2 numbers. That is SaE's footprint.

## 3. The simplified first 3 minutes (one verb, one goal)

Rules: one banner verb at a time; red arrows to exactly one place; no panel opens unless the player clicks; nothing can be taken from the player.

| Time | Banner (verb) | Arrows to | What happens / feedback | Code touchpoint |
|---|---|---|---|---|
| 0:00 | **Smash a Pumpkin!** (1/1) | Nearest Orange in the Meadow | No Daily popup. HUD: Shop, Index, candy, candy/s, moon timer. Rusty Sickle in hand. 4 swings pop it, candy bursts and "+1 🎃" shows over the head. | P `TutorialOrders[1].need = 1`; C 4089 skip on first visit |
| 0:15 | **Go to your Base!** | Your base (YOUR BASE marker) | The carry line reads "1/2 Carrying". Arrows never point anywhere else while you carry. | C `goHome` 3674 |
| 0:30 | **Place your Pumpkin!** | The first empty plot (glowing) | Place prompt only. "Carving 0:08" billboard, then a flash and the Jack comes alive. Green "+1" pops every second. | P `CarveSeconds` 8 in session 1; S `place` 1769 |
| 0:45 | **Steal from the Scarecrow!** | The Hoard nest (Scarecrow, cyan "Z z Z") | Hold E 1.5 s. Red "!", roar, RUN!! pill, red vignette, Drop button. Arrows point home. The guardian runs at 80% speed, so the first steal nearly always succeeds. | P `TutorialOrders[2]` text fixed to "Ghost"; C 4890 |
| 1:15 | **Go to your Base!** / **Place it!** | Your base, then a free plot | "You stole a GHOST PUMPKIN!" toast. Reveal card: "Rare · Ghost · about +60/s" (15 x HoardMult 3 x size 1.4; Zion saw +65/s). Income jumps from about +1/s to about +60/s. This is SaE's "Golden Chicken $5/s" moment (2:22). | S hoard deliver; C reveal 1967 |
| 1:45 | **Buy a Scythe!** | The single SHOP stall | Walk in: the panel opens on the Scythes tab with the Wooden Scythe (250) glowing; you already have well over 250 (Zion had 1.7k at this point). Buy, "Equipped!", confetti. Damage goes from 5 to 15. | Merged Tools/Upgrades stall; P `TutorialOrders[6]` moved up |
| 2:15 | **Smash a Pumpkin!** (5) | Meadow, bigger pumpkins | With 3x damage, Sunny/Ghost wilds pop in 1-4 swings. Each one goes home to a plot (Place stays the only base prompt). | P zone weights unchanged |
| 2:30 | (timer banner) **Midnight!** "in 5s... ALL PUMPKINS RESET!" | none | Lights dim (softer than today), Hoard nests refill, ghosts skip shielded bases. The player is told "The Scarecrow's nest is full again!" | S `runDay` 5205; S 4242 add shield check |
| 2:45 | **Upgrade your Base!** | SHOP stall, Upgrades tab | Buy Bigger Stack Lv1 (40 x 1^2 = 40): "Carry 3!". Tutorial done: title "Patch Keeper", +150. | P `Upgrades.Stack` |
| 3:00+ | **Unlock the Graveyard! 😐** | Zone 2 gate | The post-tutorial goal is the 1k gate (SaE's "Not enough speed" moment at 2:44). After that, one rotating order at a time. | C 3753 (already exists) |

New tutorial order list (5 steps, replacing 9): Smash 1 -> Place 1 -> Steal from the Hoard 1 -> Buy the Wooden Scythe -> Buy Bigger Stack. Brew, Sell, Bonk ghosts, Lock and Hit the King leave the tutorial and become the first rotating orders after their LATER unlocks.

Unlock schedule after the first 3 minutes:
- ~5 min: Graveyard gate (1k).
- 10 min (shield ends): player stealing, Lock pill + prompt, ghost raids, Rescue and Bonk orders. Each arrives with one banner, e.g. "Ghosts can raid you now! Lock your Base!".
- All plots full, or 30 min: Witch Sell + Pick up.
- 30 min: Cauldron brewing, finishes in the Index, Lucky Swing, the King as a tutorial-free event.
- 50% of Haunt cost: Haunt pill + skill tree.
