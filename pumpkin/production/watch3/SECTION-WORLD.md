# SECTION-WORLD: level-design plan for the hub and zones 1-7

Owner: "the models around here have no thought behind them" (Z14) and "things are placed anywhere instead of planned" (Z17); also Z15 prompts overlap, Z16 floating text inside things, W1 quest panel over the gate sign.

Evidence key: HUB = shots/hub-v4-studs.jpg. NOW = current play view (Graveyard gate, tool-results ...paih14.jpg). MEAD = shots/after-batch3-meadow.jpg. R0@Ns / R1@Ns / R2@Ns = rec/play_000 / 001 / 002.mp4 at N seconds. Code: scene/Lobby.luau, LaunchLook.luau (WallProps, ~lines 409-520), LaunchLook2.luau (stations ~line 285), LaunchLook4.luau (palette 202-208), PatchConfig.luau Zones (lines 315-438), Patch.server.luau gateSign/unlock prompt (4542-4730), MAP-CONTRACT.md.

Important finding: scene/BigMap.luau, PatchMap.luau, Revamp1.luau, Polish6.luau, Dressing10.luau are the OLD radial map (centre 0,0, ring R=130, 110 random trees, 18 random graves, 4 diagonal roads). BigMap and PatchMap begin with `workspace.Garden:Destroy()`. They must never be re-run and none of their layout survives into the lane map. The zone prop dressing seen in play (trees, graves, mini pumpkins) was placed live by execute_luau and is NOT in the repo, so the cut list below is by evidence and by rule, and the new build must be committed as scene/WorldPlan.luau.

---

## 1. Flaws found (evidence)

W-1 **Props have no job.** Every prop in the lane is scattered and none of them frames a path, marks a nest or points at a goal. R0@100s Meadow: pumpkins and a few pines sprinkled at random, two pine trees glued to the wall, nothing says "go here". MAP-COMPARE 1.9 counts about 30 mini pumpkins in Meadow, 30 lilac gravestones evenly spaced in Graveyard, about 20 trees plus mushrooms filling the Woods lane.
W-2 **Wrong-zone props.** MEAD and R0@100s: gravestones and an iron fence sit in the MEADOW; R1@150s: pine-orange trees and gravemarkers share the Graveyard with Moon pumpkins. A prop does not tell you which zone you are in, so zones do not read as places.
W-3 **No hero landmark in any zone.** From each gate (NOW, R1@20s, R2@80s) the horizon is a wall and flat floor. There is nothing to run toward and no teaser of the next zone. Tongue Evolution and Steal an Egg both give each area one silhouette you can read from 100+ studs.
W-4 **Nest is not framed.** R0@175s / R1@150s: one oversized flat straw disc about 20 studs wide with a "ZzZ" and 3 tiny "?" pumpkins, sitting in empty floor. Nothing draws the eye to the prize (SECTION-MODELS F9).
W-5 **Spawn view is wasted.** Spawn is (1500, 0.3, 130) facing -Z (Lobby.luau:279). You see the King and two lantern posts (HUB), which is good, but the lane mouth and Zone 1 are BEHIND you; there is no moment where the player is shown "this is where you go". The hub ring has 8 gravestone/jack pairs 3 studs tall at r39 around the plinth (Lobby.luau:266-269): too small to read from the spawn.
W-6 **Stations have no logic.** SHOP, SELL, UPGRADES were moved "inward 25 studs from the nearest boundary" (LaunchLook2) by formula, not by flow. In HUB, SHOP and SELL titles float at the screen edges over the wall with the cauldron on one side only; spend and earn are not grouped, and nothing tells the player the order spawn -> sell -> shop -> pen -> lane.
W-7 **Signs collide.** NOW: the gate billboard "Graveyard / 2 new pets + New pets / 2,500 candy" (Patch.server.luau:4604-4660, 300x120 px at MaxDistance 60) sits directly under the quest panel "Pumpkin Meadow [ ] Smash 7/50 ... Next gate -25%" (ZION W1). Cause: the sign is low and near the camera, the UI panel is tall and centre top. Second text line is garbled ("New pets" duplicated) and "-25%" is negative.
W-8 **Text inside geometry (Z16).** Hub title "PUMPKIN KING" is only 1 stud above the crown (HUB), and MEAD shows "YOUR PATCH" billboard hidden behind the King's glow/arch. R1@150s: pen sign "1. R(...)" overlaps the quest banner. Gate sign MaxDistance 60 clips at the gate you are walking toward.
W-9 **Prompts overlap (Z15).** Every nest, gate wall, stall and pen prompt uses hold-E with MaxActivationDistance up to 14 (Patch.server.luau:4668-4676); stalls are within 25-34 studs, so two prompts can be live at once.
W-10 **Props block or hide the important thing.** R1@150s: a giant tree-like orange/green pillar covers a third of the screen at the hub exit (gate tower in the camera path); R0@150s in the same place. Lantern posts pinch the spawn path to 20 studs (x 1490 / 1510, Lobby.luau:270-273).
W-11 **No size progression.** Guard heights run 6, 9, 13, 16, 18, 20, 24 (PatchConfig Zones) but landmarks are all the same small scale (NOW: tombstones and a fence 2-4 studs). Steal an Egg escalates (0.7 ch chicken to 6-8 ch crocodile).
W-12 **Zones are visually one corridor.** Same 120-wide, wall-both-sides box 7 times (R2@80s). Hue changes (SECTION-PALETTE) fix colour only; the silhouette inside never changes.
W-13 **Pens have no backdrop or breathing room.** Back-row pens (z -42) leave a 60-stud gap in front of the south wall that is empty; the King has no background (HUB: purple wall behind him, same hue as his cape, SECTION-MODELS F17).
W-14 **Stud floors/walls are visually flat at distance** (R2@150s hub from the air is readable, but the lane is lime to white to lime with no ground detail), so path edges and nest areas have nothing to anchor on.

---

## 2. What top games do (and what we copy)

1. **One hero per area, then three supports** (Tongue Evolution t_0494, Steal an Egg h_0018, map/REFERENCES.md 1.9). 3-6 large chunky props per zone, pushed to the walls or grouped round the nest; the middle of the lane stays clear and you see the next zone ahead.
2. **Size escalates by zone** (guard 0.7 ch to 6-8 ch; landmarks 2-3 ch to 8-10 ch). Progression is readable in the skyline.
3. **Leading lines and a funnel.** Paths, lanterns, banners and fences all point at the next goal (TE lime field with blue paths; SAE pink safe line and stations clustered within 20-30 studs of it).
4. **Frame the prize.** In SAE and TE the thing you want (egg cluster, guard) is ringed by 2-4 props and glows, so the eye finds it in under 3 seconds.
5. **Stations cluster by verb.** Earn side vs spend side, each with a floor pad 3 ch wide and a floating gold title above (map/REFERENCES.md 1.12).
6. **Text lives in bands.** Gameplay text never shares a screen position: prompts low, tags mid, zone titles high, one HUD panel. (Pet Sim 99 / Steal an Egg billboard discipline.)
7. **Backdrops are simple big shapes** (HOWTO sec 4): a ring of huge simple silhouettes, pushed back by atmosphere.

---

## 3. Fix spec (ordered by impact; S = under 1 h, M = 1-3 h, L = 3 h+)

### 3.0 Design rules that govern every placement (apply to all items below)

R1. **Three-layer test.** Every prop is Hero (1 per area), Support (2-3 per area) or Cluster (frame for a gameplay object). A prop with none of these jobs is cut.
R2. **Clear run lane.** Centre of the lane X 1467..1533 (66 wide) is empty of props from the Z0+12 gate apron to the next gate. All lane props live in the two wall bands: WEST band X 1442..1467, EAST band X 1533..1558 (props touch no closer than 2 studs to the wall at 1440/1560).
R3. **Spawn parts win.** Wild-pumpkin Spawn parts occupy X 1472..1528 only. Any prop footprint (plus 4 studs margin) overlapping a Spawn part is moved, never the Spawn. Nest cluster zones (below) exclude Spawn parts within 22 studs of the Hoard centre.
R4. **Spacing.** Min 6 studs between two Support props; 10 studs between a Support and the Hoard/guard; 14 between any two prompts' parts; 20 between any two hero/support props of the same zone along the lane axis (staggered W/E). Never two props directly across from each other (always stagger by 20-40 studs on Z).
R5. **Sight-line law.** From the gate apron (1500, Z0+12) the Hoard centre and the sleeping guard must be visible: no prop taller than 5 studs inside the 24-wide corridor between them. The next gate sign must be visible from (1500, Z0+100): no prop taller than 5 studs within 14 studs of x=1500 for Z0+135..Z0+158.
R6. **Height ladder (skyline).** Hero heights by zone: Z1 28, Z2 30, Z3 34, Z4 34, Z5 38, Z6 38, Z7 44 studs. Gate wall stays 14 tall (verify; lower if taller than 20) so each hero is seen over the gate from the previous zone.
R7. **Theming.** Props match the zone's guard and title, never another zone's. A prop in Zone N may reuse a kit mesh from another zone only if recoloured to Zone N palette and the combination is listed below.
R8. **Part budgets.** Hub decor 600 parts total; each zone 250 parts; max 6 PointLights per zone (lanterns FFC83D range 12, hero glow range 24). Props CanCollide=false except hero base (collide, 70% of footprint) so players cannot clip into models.
R9. **Face rule.** Every prop with a front (crypt door, coffin, scarecrow, tower window) faces the nearest point on the lane centre line or the gate you arrive from (-Z), never the wall.
R10. **Floor anchoring.** Every hero/support sits on a base: 2-stud darker plate or stud-checker patch 2 studs bigger than its footprint so it looks placed (SECTION-PALETTE Warm Wood/Midnight Plum for plates).

### 3.1 [S] Cut list (do first; unblock everything else)

Delete (not hide) from workspace.Garden:
- **Zone random props, all zones:** every prop in Garden.Art / Garden.Zones with 1467 < X < 1533 that is not a Spawn, GateWall, GateSign, Hoard, guard, or nest part. Includes the scattered mini pumpkins, crop rows, loose mushrooms, lone fence pieces, "pine orange" trees stuck on walls in Meadow (R0@100s), gravestones/fence in Meadow (MEAD), pine/orange trees in Graveyard (R1@150s), pines and gravemarkers mixed in Woods.
- **Hub:** (a) the ring of 8 small gravestone/jack-o'-lantern props at r39 (Lobby.luau:266-269) -> replaced by 4 big cardinal jacks below. (b) WallProps clusters at (1340,65) and (1660,65) (LaunchLook.luau:497-500); keep the 4 corner clusters (1340/1660, -63 and 135) but delete their gravestone/post_lantern member and add the corner themes in 3.2. (c) lanterns at x=1490/1510 z=110/125/140 (Lobby.luau:270-273): move to x=1485/1515 (leaves a 30-wide spawn path).
- **Already hidden but still in the file/world:** DaytimeMoon (LaunchLook2), StringLights, WallLanterns glass duplicates, PenFurrows, WallGlow, Bracket, GlowPool: delete the instances so nothing re-enables them.
- **Legacy radial map leftovers:** audit with a script and delete everything under Garden whose position is outside X 1330..1670 for Z < 150, and outside X 1440..1560 for Z >= 150 (these include JumpPads and RoadLanterns from Dressing10.luau if any survived).
- **Any BillboardGui child on a wild pumpkin except Golden / Big** (candy emoji; SECTION-MODELS F5).
- **Gate sign line "2 new pets + New pets"** (Patch.server.luau:4594): replace with nothing on the billboard (benefit text stays in the prompt only).

Verify with one execute_luau pass afterwards: count Garden descendant BaseParts per zone <= 250 and print any with |X-1500| < 33 that is not tagged Spawn/Hoard/Guard/Gate.

### 3.2 [M] Hub plan (X 1330..1670, Z -70..150; safe line Z 150; lane mouth X 1440..1560)

**Purpose of the hub:** teach the loop in a 25 second walk: *arrive -> see the King (the goal) -> sell/spend -> go to your pen -> go through the arch to the lane.* One dominant hero (the King), three stations grouped by verb, one path network, nothing else competing.

**Flow (arrows are the walking order):**
1. Spawn plate (1500, 0.3, 130), faces -Z. First view: lantern pair, 14-wide cream path, King (hero, 1.4 scale) on the lavender dais at (1500,0,40) with a pumpkin-moon backdrop behind him.
2. Spawn -> left or right to stations on the way (all within 25-30 studs of the spawn, SAE rule) -> down the path to the ring -> spur to your pen gate -> back up to the lane.
3. Lane mouth: HauntedGate arch at (1500, 0, 150) with Zone 1 hero (hay tower) peeking over it. Turning around from the King you see the arch framing the lane: that is the "turn around" beat.

**Sight lines**
- Spawn (1500,130) looking -Z: lantern pair at x 1485/1515 (frame), King centre, moon backdrop (see below) directly behind the King's head, SHOP title top-left, SELL title top-right. Nothing taller than 6 studs stands within 20 studs either side of x=1500 between Z 128 and Z 70.
- King dais (1500,40) looking +Z: arch + Zone 1 hero over the gate; the 14-wide path as a leading line; the stations left/right as a pair.
- Each pen gate (front at the pen's centre line facing the King): looks at the King down its own spur; pen sign face to the path.

**Stations** (all with 18-stud neon pad at 0.4 transparency, title 24 studs up, face +X/-X toward x=1500). Targets; verify live positions with execute_luau and only move a stall if it breaks spacing:
- SPEND side (west, the "get stronger" side): SHOP at (1412, 0, 118); UPGRADES at (1412, 0, 84). 34 apart.
- EARN side (east, the "cash in" side): SELL at (1588, 0, 118) with its green cauldron; leave (1588, 0, 84) as the daily/gift or leaderboard slot (Daily is a UI button now; if no object, put the LifetimeBoard here).
- Prompt part of each station: at the counter front, 2 studs toward the path, 3 studs above floor, MaxActivationDistance 8. No two stations within 30 studs of each other, so no two prompts overlap (R4).
- Pen footprint check: east pens at (1645, 30/95) span X 1630..1660; SELL at 1588 +-9 clears by 33 studs.

**Landmarks**
- **Hero: the Pumpkin King** on dais (1500,0,40), keep the 3-step lavender throne. Add a backdrop (the south wall is purple like his cape, W-13): a pumpkin moon disc 44 studs across, SmoothPlastic FFE9B0 (not Neon), centre (1500, 40, -73), facing +Z, half hidden behind the 30-tall south wall so only the top two thirds clear the wall. It silhouettes his head. Warm uplight FFB060 range 40 on the dais.
- **Support 1: the four cardinal jack posts** at ring radius 40 around the King: (1500,0,0), (1540,0,40), (1500,0,80), (1460,0,40): each a 6-stud jack-o'-lantern on a 3-stud cream post (neon face FFC83D). They mark the ring road crossings and the path directions.
- **Support 2: the arch + banners at the lane mouth**: two 16-stud pennant poles at (1450, 0, 144) and (1550, 0, 144) with orange cloth banners facing -Z (toward spawn) reading no text; they mark where the lane starts.
- **Support 3: corner "harvest corners"** at (1340,-63), (1660,-63), (1340,135), (1660,135): hay bale (5x3x3) + 2 pumpkins (2.5 and 3.5) + a 7-stud post lantern; the SE and SW corners also each carry one 20-stud bare tree (Lobby.luau:274-276), kept only at these four corners.

**Prop clusters with intent**
- Spawn lantern pair: frame the first view (x 1485/1515, z 128).
- Station pads: each a 3-prop cluster: pad, stall, 2 pumpkins/hay bales behind the stall (never in front, so the prompt sight line stays clear).
- Pen gate lanterns: 2 posts, jack lantern 1.2 studs, at each 10-stud front gate (SECTION-MODELS 7) so you can find your own pen from the ring road.
- Ring road jacks every 90 degrees (above). Nothing else on the ring.

**Signs and text (hub)**
- Station titles: BillboardGui at y 24, 32x6 studs, MaxDistance 120 (not 350), drawn LAST (ZIndex high), colour per station (SELL 39D8F0, SHOP FFC83D, UPGRADES 7A52BF). Horizontal separation >= 34 studs so they never touch.
- "PUMPKIN KING": billboard 6 studs ABOVE the crown top (not 1), y = king top + 6, size 16x3 studs, MaxDistance 200.
- Pen sign (LobbyPen SignPost): board centre y 7.5, label at y 10.7, MaxDistance 90 (was 140), faces the path spur; stays clear of the pen gate gap by 4 studs.
- No sign in the lane mouth except the arch banner pair (no text).

### 3.3 [M] The lane and the zone template (applies to Z1..Z7; Z0 = 150 + 160 * (n-1); lane X 1440..1560)

Z0 values: Z1 150, Z2 310, Z3 470, Z4 630, Z5 790, Z6 950, Z7 1110. Zone end = Z0 + 160. All z below are offsets from Z0.

| z offset | Role | What is here |
|---|---|---|
| 0 to +14 | **Gate apron** | GateWall at z+0 (Z2-Z7), 2 gate pillars at x 1452 and 1548 (16 tall, zone accent top lantern), GateSign anchor centre (1500, 22, Z0-3) on the player-facing (-Z) side, UnlockPrompt on the wall at y 3. Z1 uses the hub arch instead. |
| +14 to +40 | **Reveal** | Empty. First look at the zone. 2 small Support props (one per side) at z+32 start the side bands. |
| +40 to +90 | **Field** | Spawn grid X 1472..1528. 2 Support props on alternating sides at z+55 (W) and z+80 (E). |
| +92 to +116 | **Nest** | Hoard centre at (1500 + s * 30, Z0+104) where s = -1 (west) for Z1, Z3, Z5, Z7 and +1 (east) for Z2, Z4, Z6. Guard sleeps 6 studs behind (toward the near wall) and 4 toward +Z. Frame cluster (3 props) round the Hoard. Spawn exclusion r22. |
| +120 to +150 | **Promise** | Hero landmark at (1500 - s * 56, Z0+136): the wall band OPPOSITE the nest side, footprint <= 22 wide, so the nest side is balanced against the hero and the centre stays open. |
| +150 to +160 | **Gate approach** | Empty apron 10 studs deep before the next GateWall: clear floor, 2 floor chevrons pointing +Z (zone accent, 6x1, 0.05 high). Next gate sign visible from 60 studs away. |

Purpose: reveal -> hunt -> choose a target -> steal -> see the next gate. A player running Z0 -> Z0+160 gets one new picture every 25-30 studs, always on alternating sides, which breaks the "same corridor" feel (W-12) with only 6 props per zone.

**Sight lines per gate (what you see standing at (1500, 2, Z0+4) facing +Z):**
- Down the lane: empty floor with gold chevron lead, pumpkins on the floor in the spawn grid, the Hoard + sleeping guard 100 studs ahead on one side with its frame cluster glowing (R5), the hero landmark filling the opposite wall band at the far end, and over the next gate wall the TOP of the next zone's hero (R6 heights).
- From the previous zone's far end looking +Z: you see the gate wall, its sign at y 22, and over it the next hero's top third. That is the carrot.

**Props for each zone (hero 1 + supports 3; nest frame 3)**

Zone palette, floor/wall and accent per SECTION-PALETTE 3c. Kit mesh names are in ServerStorage.KitSource: gravestone, grave_A/B, gravemarker_A/B, crypt, shrine_candles, tree_dead_large (+ _decorated), tree_dead_medium, tree_pine_*, fence, fence_seperate, post_lantern, lantern_standing, candle_triple, skull_candle, bone_A, pillar, arch, pumpkin_orange(_jackolantern), pumpkin_yellow_jackolantern, haybale. Anything not in the kit is built with VoxelKit (chunky, studded, 2 colours) like MysteryPumpkin.

- **Z1 Pumpkin Meadow** (Z0 150, guard Scarecrow, nest WEST, hero EAST). Hero: **Hay Tower**, 3 stacked hay tiers 20/14/8 wide x 6 tall + 6-stud pumpkin on top and a crow on a pole = 28 tall, at (1556, 0, 286), E8D27A hay with 6B4430 ties. Supports: (a) two 12-stud scarecrow posts (T-pole, straw hat) at (1450,0,182) and (1550,0,222), arms toward lane; (b) 3 hay bales stacked 5x3x3 at (1452,0,256); (c) arrow signpost 7 tall at (1456,0,200) pointing +Z with no text. Nest frame: 3 bundled hay bales + a wooden crate at radius 12 around the Hoard (open on the gate side, -Z), plus a straw ring (not a 20-wide disc: 9 wide, #E2C066 with 6A4A22 rim). Cut: gravestones, fence, pines.
- **Z2 Graveyard** (Z0 310, guard SkeletonKnight, nest EAST, hero WEST). Hero: **Crypt**, kit crypt scaled to 30 tall at (1444, 0, 446), door facing +X/lane, lit window FFC83D. Supports: (a) two rows of 3 big tombstones (4x6x1.5, D7CDEB / 8E7FC4) along the east band at z+60..+90, staggered, headstones tilted 4 degrees; (b) iron fence run 20 long (fence_seperate x2) at (1535,0,372) forming the nest's north edge; (c) 2 dead trees 16 tall at (1452,0,342) and (1548,0,352) at the entry. Nest frame: skull_candle x3 at radius 10 (flame FFC83D), bone_A pile at the guard's feet. Cut: orange/yellow pines, lilac gravestone grid.
- **Z3 Haunted Woods** (Z0 470, guard TreeEnt, nest WEST, hero EAST). Hero: **Elder Tree**, tree_dead_large_decorated scaled to 34 tall with two lit carved eyes (FFC83D, 2x3) at (1556, 0, 606). Supports: (a) 5 trees (3 dead 14-18, 2 pines 16) as a tree line in the wall bands only, spaced 24 apart; (b) 3 mushroom clusters (red caps D8433E / white dots, 3 mushrooms 3-5 tall each) at the nest edge and at z+60 east and z+85 west; (c) a fallen log 10 long across the west band at z+28. Nest frame: ring of 6 knee-high stumps (2 tall) radius 11, root arcs on floor. Cut: 20 trees filling the lane.
- **Z4 Witch Swamp** (Z0 630, guard SwampToad, nest EAST, hero WEST). Hero: **Giant Cauldron**, 22 diameter / 34 tall incl. legs and a ladder, green neon brew top 78E580 (the only neon in the zone), PointLight 78E580 range 24 at (1444, 0, 766). Supports: (a) lily-pad ring: 5 flat discs 6 wide in 3A8F4E, 0.2 high, around the nest to mark it as a pond; (b) 3 purple mushroom clusters (7A4FD0 caps) at z+55 W, z+75 E, z+30 E; (c) 2 crooked lamp posts with green lights at the gate pillars. Nest frame: pond disc 26 wide, 0.1 high under the nest, #A8D8C0. Cut: red mushrooms, loose pumpkins.
- **Z5 Vampire Castle** (Z0 790, guard Vampire, nest WEST, hero EAST). Hero: **Gate Tower** 38 tall, two crenellated towers 10 wide joined by a bridge, wine A8406A with pale FFE08A windows, bat banner (no text), at (1552,0,926). Supports: (a) 3 standing coffins (4x9x3, tilted 8 degrees, lids leaning) at the nest's east edge; (b) four candelabra (candle_triple scaled to 6 tall, flame FFC83D) alternating along the walls at z+40, z+70, z+95, z+125; (c) two red-black banner poles 14 tall at the gate pillars. Nest frame: red carpet 6 x 24 from the lane to the nest (leading line) + 2 candelabra. Cut: blue/periwinkle tile stripes, lone gravestones.
- **Z6 Candy Kingdom** (Z0 950, guard CandyGolem, nest EAST, hero WEST). Hero: **Cake Tower**, 3 tiers (pink F4C4DE / white FFF8EC / purple C79BEA, 16/12/8 wide x 8 tall) + cherry 6 across = 38 tall at (1444,0,1086). Supports: (a) 3 lollipop trees: stick 10 tall + 8-wide swirl disc (FF5FA8 / FFF8EC); (b) candy-cane posts 8 tall x 6 flanking the nest; (c) 5 gumdrop mounds (half spheres 4-6 wide, 9EF0C8 / FF5FA8 / FFC83D) in the wall bands. Nest frame: ring of 8 candy canes radius 10 (red stripe pairs). Cut: neon anything, grass-green.
- **Z7 Pumpkin King's Throne** (Z0 1110, guard PumpkinKing walking boss, nest WEST, hero EAST... hero here is centred at the far end as the final vista; the next gate does not exist, so centre is allowed). Hero: **the Throne**: 3-tier dais (24/18/12 wide, 3 tall each, 2D1F43 to 5A3A8E) + 44-tall carved pumpkin throne at (1500, 0, 1250), with two 24-tall obelisks at x 1470 and 1530. Supports: (a) 4 brazier posts 7 tall with flames FFC83D along x 1452/1548 at z+60, z+95; (b) two banner walls 18 tall at z+120 each side; (c) skull pile cluster at the nest. Nest frame: ring of 8 jack posts radius 11 around KingSeed. Boss walk path: leave X 1467..1533 empty for the boss's entrance from the dais to z+60.

### 3.4 [S] Signs, billboards and prompts: where each goes and why

Vertical bands (world Y over the floor; never share a band within 8 studs XZ of each other):
| Band | Y | What lives there | MaxDistance |
|---|---|---|---|
| Prompts | 2-5 | all ProximityPrompts (gate wall, nest, stalls, pen) | MaxActivation 8 (gate 12) |
| Tags | 6-12 | pet tags, nest/guard "ZzZ" (2 above head), pen sign, wild Golden/Big tag (top + 1.5) | 45-90 |
| Titles | 18-26 | gate sign (22), station titles (24) | 90-120 |
| Skyline | 34+ | King title (crown + 6), Z7 throne title (if any) | 200 |

- **Gate sign** (Patch.server.luau:4589-4660): anchor centre (1500, 22, Z0 - 3), 24x10 studs (BillboardGui UDim2.fromOffset 300x120 stays), MaxDistance 90 (was 60), AlwaysOnTop false. Content: title line only ("Graveyard") plus the gold price pill. The "2 new pets + ..." line moves to the prompt text. This stops W-7: the sign sits at screen y 22 studs up and the quest panel is moved down-left by the UI section; the sign never competes for the same pixels.
- **UnlockPrompt**: on the GateWall at y 3, centre of the wall, ActionText "Unlock", ObjectText = price. It is the ONLY prompt within 14 studs of the gate. Nest prompts are >= 80 studs away, so no overlap.
- **Nest prompt part**: 3 studs above floor on the nest edge facing the lane (-Z side), 10 studs from the guard centre; ZzZ billboard at guard head + 2, floats 0.6 s loop; guard "GUARD 34 studs - RUN!" alert is a HUD banner, not a world billboard.
- **Pen sign**: see hub; faces the spur, not the fence.
- **No billboard centre may be inside a part's bounding box**: placement function `offsetAbove(model, 2..6)` = model top + margin, never a hard-coded Y. Audit script: for each BillboardGui adornee, assert (adornee.Position.Y + StudsOffset.Y) > bbox top of any intersecting model.
- **Hero landmarks carry no text** (except Z7); the zone title text is in the gate sign and HUD only.

### 3.5 [S] Cluster and spacing cheat sheet (numbers a coder can paste)

- Hero footprint <= 22 x 22; Support footprint <= 8 x 8 (tombstone 4 x 1.5; hay tower 20); Cluster props each <= 4 studs and placed at radius 10-12 from the Hoard centre, spaced evenly with 1 gap of 12 studs on the -Z (gate) side.
- Stagger: successive Support props along Z at 20 to 40 stud steps alternate W/E; never opposite each other.
- Yaw: Support props face the lane centre +-15 degrees (R9); random yaw only for rocks/mushrooms/stumps.
- Min gap to Spawn parts 4 studs; to Hoard 10; to GateWall 8 (apron 14 free).
- Floor chevrons: every 40 studs along Z at x=1500, 6 x 1 x 0.05, zone accent colour, point +Z, only in the "Reveal" and "Gate approach" bands so they do not sit on pumpkins.
- Maximum 4 dead trees per hub or zone. No prop appears in two zones.

### 3.6 [L] Delivery order (one commit: scene/WorldPlan.luau + the Cut script)

1. Cut script (3.1) and audit. **[S]**
2. Hub: stations/signs fixes, King backdrop, jack posts, banner pair, delete small ring. **[M]**
3. Zone template: gate apron, side-band Supports 1-2 per zone with kit meshes only (Z1-Z3). **[M]**
4. Heroes, in order Z1 Hay Tower, Z2 Crypt, Z3 Elder Tree, Z4 Cauldron, Z5 Tower, Z6 Cake, Z7 Throne; each ~1 h with VoxelKit. **[L]**
5. Nest frames and floor chevrons; spawn exclusion (R3); readback audit. **[M]**
6. Sign/prompt pass (3.4). **[S]**

---

## 4. Acceptance test (5 lines)

1. Spawn: in the first screenshot you see ONLY the King, the moon backdrop behind his head, two lanterns, the cream path, and SHOP/SELL titles; the King's title is clear of his crown.
2. Hub walk: stations are grouped (spend west, earn east), pads 34 studs apart, and standing at any one stall shows exactly one E prompt.
3. Pick any gate: 3 s after arrival you can point at the sleeping guard, its nest cluster and the zone hero landmark; the next gate's sign is readable at 60 studs and the next hero peeks over the wall.
4. Zero zone props within X 1467..1533 except Spawn/Hoard/guard; the script audit prints no part from a wrong-zone kit item.
5. No gate or station billboard overlaps the quest panel or another billboard in a 1080p capture from the gate apron, and no billboard sits inside a model.
