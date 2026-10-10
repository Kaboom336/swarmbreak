# MAP-COMPARE: Steal an Egg vs our Steal a Pumpkin greybox

Date: 2026-10-10. Read-only study. Owner ask (Zion): "look at steal an egg's model and map, see how they did their models and take that lead, also this map is a little off so compare there as well."

Sources
- Reference video `C:\dev\codex-lab\refs\videos\steal-an-egg.mp4` (854x480). Contact sheets `steal-an-egg-sheets\sNNN.jpg` (cited `s009#4 (2:30)`), full frames `steal-an-egg-frames\fHHMMSS.jpg`. New frames for this study are in `C:\dev\codex-lab\refs\videos\steal-an-egg-frames\map\`: `mSSSS.jpg` = single frame at SSSS seconds, `q1-q5.jpg` = 2x2 composites, `z*.png` = zoomed crops used for the measurements.
- Study notes `C:\dev\codex-lab\refs\BIBLE-STEAL-AN-EGG.md` sections 6-8.
- Our Studio screenshots (tool-results `mcp-Roblox_Studio-blob-*`): lane `c9bbd9`, hub `k8cybn`/`0buzv3`, aerial `syburq`, graveyard `3620np`, woods `sp4cl8`, pen close `3x1nmz`, hub at player height `yr04b7`, models `omwncl`/`h58g3b`.

How I measured: in every frame I measured things in **character heights (ch)**: the avatar's height on screen at the same depth. Our avatar is about 5 studs tall, so **1 ch = 5 studs** in all the fixes below. I sampled hex values as 5x5 pixel averages from the frames. Measurements from video have about ±20% error because of perspective and compression. The values I could not measure are marked "est".

One important finding about scale: their stud bumps are smaller relative to the avatar than ours. They show about 8 bumps per ch, and we show 5 (z0168, z0040). Their whole world therefore reads finer-grained. The checker, the wall cells and the props all sit on that finer grid.

---

## 1. Element by element

### 1.1 Ground: stud texture and checker
- **THEIRS:** Saturated lime stud carpet. The checker is barely visible.
  - Two tones sampled: #75FB0F and #6CF20A (m0168), and #6AF110 and #6FF40E. That is about a 3-5% value difference.
  - Checker cell is about 0.4-0.5 ch, and each cell holds 3-4 stud bumps (z0452, z0168: the yellow path is about 1 ch wide and 2.5 cells across).
  - From normal camera distance it reads as one uniform green field with fine texture (f000040, m0151, m0160).
  - The other zones use the same small checker in their own colour: sand (m0168 path, s047), white snow (m0462), blue Abyss (m0466), navy Cosmic (s027#4).
- **OURS:**
  - 20x20 stud tiles, which is a 4 ch cell, so about 8-10x too big.
  - The two tones #4AEF06 and #60F30F are 8-10% apart, so you see big chunky squares everywhere (lane `c9bbd9`, aerial `syburq`).
  - Stud bumps are 1 per stud (5 per ch).
- **EXACT FIX:**
  - Checker cell **4x4 studs** (0.8 ch, 4 bumps per cell, which matches their bump count per cell). For an exact match, use 2.5-stud cells with a stud Texture at StudsPerTile 0.6.
  - Hub tones **A #72F70E / B #68EE0A**: at most 5% apart, same hue.
  - Keep the Studs surface. Build each zone floor as 1 large part with a 2-tone checker `Texture` (StudsPerTileU/V = 8, so each cell is 4 studs) instead of hundreds of 20-stud tiles.

### 1.2 Walls: height, brick size, colour and top edge
- **THEIRS:**
  - **Height** about 6 ch. In the Desert/Lake corridor (z0280) the wall is about 346 px tall against a 58 px avatar at the same depth.
  - **Height-to-width ratio** about 0.25 of the corridor width.
  - **Colour:** dusty terracotta/salmon, **#CA735B / #C16953** (m0168), not orange. The bible sample was #D2713E/#CA7654.
  - **Checker:** low contrast and small. Cells are about 0.5 ch with 4-5 stud bumps each, the same grid as the floor (z0160). Studs are visible on the wall face.
  - **Top edge:** a **neon lime strip**, clearly visible against the sky (s007#2, m0130, s027#7-#9, q2 bottom-right).
  - **Per-zone recolour:** later zones change the wall colour to match the floor.
    - Volcano: dark slate.
    - Abyss: blue, #163375 / #192A60 (m0462, m0466).
    - Cosmic: navy with white 5-point stars (s027#1).
    - Desert approach: maroon, #7A404F (m0280).
    - Desert: sand checker (s047).
- **OURS:**
  - **Height** 44 studs = 8.8 ch.
  - **Bricks** 11-stud checker blocks (2.2 ch cells, so only 4 rows tall).
  - **Colour** bright orange, #FF8D10 vs #D35204: strong contrast and fully saturated.
  - **Top edge** a thin neon purple/pink line.
  - **Per zone:** the same orange wall everywhere.
  - Result: the wall dominates every shot (`yr04b7`, `3620np`).
- **EXACT FIX:**
  - **Height** **30 studs** (6 ch).
  - **Cells** **4x4 studs** with studs on the face (same Texture approach as the floor).
  - **Hub/Forest colours** **#CC7258 / #C2684F**.
  - **Top cap** **Neon #4CFF3A**, 1.5 studs tall, full wall thickness.
  - **Per-zone wall colours** (both tones within 5% of each other):
    - Meadow: terracotta (as above).
    - Graveyard: grey-violet #6E6A86 / #66627D.
    - Haunted Woods: deep green #2F5A3A / #2A5234.
    - Witch Swamp: dark purple #3B2A5C / #352553, with small lime star or moon decals like their Cosmic stars.

### 1.3 Corridor width and overall scale
- **THEIRS:**
  - The corridor is about **24 ch wide (about 118 studs at our scale)**: z0280, 1370 px wall-to-wall vs a 58 px avatar at the same depth.
  - The bible estimated 25-30 ch. Treat the range as 22-28 ch.
  - It is one straight walled lane, and the zones join with no doors (s026#5-#9, s027#9).
  - Spawn to safe line is about 20 ch (bible §6).
  - Pen to the Forest nests takes 12-14 s on foot at speed 10 (2:28-2:40).
- **OURS:**
  - 160 studs wide (32 ch).
  - Every element (pens, props, guard) looks small inside a huge box (aerial `syburq`).
- **EXACT FIX:**
  - Corridor and hub width **120 studs** (24 ch).
  - Zone length can stay at about 160 studs (32 ch). That gives about 10 s per zone at WalkSpeed 16, which feels like theirs.
  - After narrowing the walls, recentre every prop and the nest cluster.

### 1.4 Hub: size and openness
- **THEIRS:**
  - A big, open lime field.
  - Pens are fenced paddocks standing side by side with walkable grass between them (s002#2, m0092, s060#2-#3).
  - The skyline is dominated by **giant voxel display pets, 20-40 ch tall** (yellow brachiosaurus "308,572Kg", green serpent with glowing lime scales, white crystal dragon: s008#2-#6, s002#6). These are players' heavy pets, scaled by weight.
  - Centre props:
    - "TRAILS SHOP" stall on a glowing yellow pad.
    - "SELL" stall plus a blue "Fuse Machine 0/3" box (s037#7).
    - "FREE!" gift box (s002#7).
    - Cyan-framed "MOST MONEY/s" leaderboard (q5).
  - The central field is mostly empty grass.
- **OURS:**
  - 160 x 170 studs.
  - 4 pens jammed along each wall with about 8-stud gaps.
  - One stall and a white spawn disc in the middle.
  - No landmarks, so nothing on the skyline (`k8cybn`, `syburq`).
- **EXACT FIX:**
  - Hub **120 wide x 150 long**.
  - **2 rows of 4 pens**, each **30 wide (along the wall) x 26 deep**, with **8-stud gaps** between pens (4x30 + 3x8 = 144 studs).
  - Pens back onto the side walls, leaving a **68-stud open central lane**.
  - In the lane, in this order from the spawn end: shop stall, sell stall, free-gift box, leaderboard. Space them at least 20 studs apart.
  - Add **1-3 giant voxel landmark pets, 60-120 studs tall** (12-24 ch: for example a giant jack-o'-lantern cat and a bat serpent with glowing orange scales). Stand them behind or between the pens so they show above the walls from every zone.

### 1.5 Pen: size, shape, fence, floor, pedestals, signs and house icon
- **THEIRS** (f000330, f000150, f000154, m0304, s028#2-#9, m0786):
  - **Size and shape:** the starting pen is a rectangle about 7-9 ch wide (about 35-45 studs) and about 6-7 ch deep. Upgrades add extra fenced sections, so it becomes a long L shape (m0786, s044#7).
  - **Floor:** the same lime ground as the hub, with no special floor.
  - **Fence:** 3-rail fence.
    - **Posts:** tall chunky dark plum blocks, #432434 / #502838, about 1.2 ch tall and 0.3 ch square. Stud bumps show on the post faces, and the posts stick out above the top rail.
    - **Rails:** thick boards, orange-brown #DC470D / shadow #A23302.
    - **Post spacing** about 1.6 ch.
    - **Gate:** an opening of about 1.6 ch.
    - Other players' pens show white rails on navy posts (m0092, s002#2). Own and other pens are coloured differently.
  - **Pedestals:** pale peach-pink studded blocks, #FCDACC / #DFA9A1 (f000150). There is only **one** at the start: the tutorial hatch spot.
    - After that, eggs sit **on the grass anywhere in the pen** and pets **roam freely** inside it (s007#4-#6, s043#1-#4, s036#7-#9).
  - **Signs:**
    - Navy post sign "Unlock: [icon] $1K" with a red price bar at the gate (f000330, s007#3).
    - Navy "Upgrade Pen Level 2 > Level 3 $75M" sign on the fence (s028#5).
  - **House icon:** an orange house billboard above your own pen, readable from the zones (s006#2-#3, s014#5).
- **OURS:**
  - 34x34 square.
  - **Rails:** pure red #CE0B01.
  - **Posts:** thin plum posts about 0.8 studs, spaced about 5 studs (dense, picket-like).
  - **Pedestals:** a 3x3 grid of 5x5 lilac-pink slabs (#FED3E8 / #D398C9) about 1 stud tall, 9 studs apart. The pen reads as a parking lot of slabs (`3x1nmz`).
  - **Floor:** some pens have a white or pink floor (`k8cybn` right row).
  - No signs, no house icon.
- **EXACT FIX:**
  - **Pen size:** **30 x 26 studs** at Level 1. Upgrades add a **+30 x 26 section** on the side away from the wall.
  - **Floor:** the hub lime with the same checker. Delete the pink/white floors.
  - **Posts:**
    - Size **1.5 x 6 x 1.5 studs**, colour #45243A, Studs surface on all faces.
    - Spacing **8 studs**.
    - Height 6, so they stick **0.8 studs above the top rail**.
  - **Rails:**
    - **3 rails**, each **0.9 tall x 0.5 thick**.
    - Rail centres at heights **1.6 / 3.2 / 4.8**.
    - Colour **#D8470E** (shadow side automatic).
    - Other players' pens use **white #F2F2F2 rails on navy #1F2A55 posts**.
  - **Gate:** an **8-stud gate** on the lane side.
  - **Pedestals:**
    - **Start with 3** in a row, **6 x 4 x 2 studs**, colour **#F9D6C8**, Studs surface, 4 studs apart along the back fence.
    - Further slots unlock one at a time. Show each as a navy "Unlock $X" sign (**3 x 2 studs** board on a 4-stud post, red price bar) standing where the next pedestal will go.
    - Hatched pets **walk freely** inside the pen (radius = the pen interior) instead of standing frozen on slabs.
  - **House icon:** a BillboardGui **6x6 studs**, **20 studs above** your pen gate, AlwaysOnTop, own pen only.
  - **Upgrade sign:** a navy "Upgrade Pen" sign on the front fence.

### 1.6 Spacing between pens
- **THEIRS:** pens are separated by grass lanes of about 2-3 ch (s002#2, s060#2, m0092). You can always walk around a pen.
- **OURS:** about 8 studs, but the fences visually touch from most angles (`k8cybn`, `syburq`).
- **EXACT FIX:** an **8-stud gap** between pens in the same row, plus a **68-stud open centre lane** between the rows (1.4). With the thicker, sparser posts this reads as separate paddocks.

### 1.7 Safe line
- **THEIRS:**
  - A **pink-red raised studded strip**, #F35583 with lighter segments #F185A8. It is about 1 stud wide and slightly proud of the ground, built from segments about 2-3 studs long that alternate tone (z0040, f000040, s003#2).
  - It runs the full corridor width.
  - A large blue/white italic **"SAFE ZONE"** ground decal sits just on the hub side (s009#3, s014#6, s060#3).
  - Crossing it fires "You stole an EGG!".
- **OURS:** a thin red neon line, flush with the ground (`c9bbd9`, `k8cybn`). It reads like a laser, not a boundary.
- **EXACT FIX:**
  - The strip:
    - Size **2 studs wide x 0.4 tall x 120 long**, Material Plastic with studs (not Neon).
    - Built from **3-stud segments** alternating **#F35583 / #F585A8**.
  - The decal:
    - A **"SAFE ZONE"** decal **40 x 8 studs** on the hub side, 6 studs back from the line.
    - Colour #2FA8FF with a white outline, italic heavy font.

### 1.8 Zone transitions and titles
- **THEIRS:**
  - **Transitions:** hard floor-colour edges straight across the corridor, often matched by a wall colour change at the same line (m0280 lime to maroon, m0462 snow to navy, s027#9 sand to blue).
  - Some edges have a thin sand strip or a sand path (m0168, s010#3).
  - An invisible gate stops you entering a zone you are too slow for: "You don't have enough speed!" (m0164, s010#2).
  - **Titles:** a **HUD line** directly under the objective banner (y about 17-21% of the screen) on a faint dark band, shown while you are in the zone.
    - Grey for early zones, coloured for later ones, with an emoji ("Forest 🙂", "Lake 😐", "Jungle 😬" purple, "Volcano 😧" red, "Abyss Ocean 😱" purple, "Desert 😮" blue, "Cosmic 👹").
    - Seen in m0151, m0280, m0462, s026#5-#9.
  - **No world-space floating titles.**
- **OURS:**
  - **Titles:** huge **world-space billboards** floating mid-corridor ("Graveyard 😐", "Haunted Woods 😬"). They overlap the next zone, you see several at once, and they hide the view (`3620np`, `sp4cl8`, `k8cybn`).
  - **Transitions:** the floor-colour change exists, but the walls stay orange.
- **EXACT FIX:**
  - **Remove the zone billboards.**
  - Show the zone name in the **HUD under the objective banner**:
    - Text height 4% of the screen.
    - Meadow in grey #8E9AA0; later zones coloured: Graveyard lavender #B48CFF, Woods green #3CFF7A, Swamp purple #C040FF.
    - Same emoji ladder as now.
    - Change the text when the player's Z position crosses a zone edge.
  - At each edge change floor and wall colour on the same line.
  - Add a **4-stud transition strip** in a blend colour (for example a dirt strip #8A5A3A between Meadow and Graveyard).
  - Optional speed gate later.

### 1.9 Zone floor and prop density
- **THEIRS:** zones are mostly **empty floor**.
  - Each zone has about **3-6 large chunky studded props**, pushed to the walls or grouped near the nest cluster.
  - Forest has two or three 3-tier stacked bush cubes about 1-1.5 ch tall, 2-3 bamboo stalks (green studded columns 3-4 ch tall on a cyan base), and an orange studded signpost (m0151, m0160, z0160, s009#7-#9).
  - Lake has a sand edge and palm trees.
  - Desert has stepped pyramids 2-3 ch tall (s017#5, s047).
  - Abyss has a pile of giant bones (m0466).
  - Snow has cyan ice crystals (m0462).
  - The centre of the lane stays clear and you see the next zone ahead.
- **OURS:**
  - **Meadow:** about 30 tiny pumpkins (about 0.3 ch) plus bushes plus crop rows, sprinkled everywhere (`c9bbd9`).
  - **Graveyard:** about 30 small lilac gravestones evenly spaced (`3620np`).
  - **Woods:** about 20 trees and red mushrooms filling the lane (`sp4cl8`).
  - All of it is small and evenly scattered, so the zones read as noise.
- **EXACT FIX:**
  - **Per zone, 5-8 props**, each **1-3 ch (5-15 studs) tall**, chunky, studded, 2 colours.
  - Place props **within 25 studs of the walls**, or as a frame around the nest cluster.
  - Keep a **clear 40-stud-wide run lane** down the middle.
  - Suggested props:
    - **Meadow:** 3 stacked hay-bale/bush cubes (6 studs), 2 scarecrow posts (12 studs), 1 signpost.
    - **Graveyard:** 6 big tombstones (4 x 6 x 1.5 studs), 1 crypt (14 studs).
    - **Woods:** 5 big dead trees (14-18 studs) along the walls.
    - **Swamp:** 2 cauldrons and 3 mushroom clusters.
  - Delete the scattered mini pumpkins, crop rows and mushrooms.
  - Floor colours: keep one colour per zone on the 4-stud checker at no more than 5% contrast.

### 1.10 Nests: count, size and spacing
- **THEIRS:**
  - **Count:** **5-8 nests per zone** in a loose cluster around the sleeping guard.
  - **Spacing:** about 2-4 ch apart (10-20 studs). The cluster is often pushed toward one wall (m0160, s011#7-#8, s047#2-#7).
  - **Nest:** a brown voxel twig ring about 0.7 ch across (about 3.5 studs), less than 0.2 ch tall.
  - **Egg:** about 0.3-0.5 ch (1.5-2.5 studs).
  - Eggs glow: white or gold with a soft bloom (m0160, s009#8).
- **OURS:** **1 nest per zone** (map facts), so there is nothing to choose from and no cluster silhouette.
- **EXACT FIX:**
  - **7 nests per zone** in a cluster of **radius 18 studs**, nests **10-14 studs apart**.
  - Put the cluster centre **at 60-70% of the zone length**, offset **20 studs toward one wall** (alternate sides per zone).
  - Nest: **3.5 studs** across, 0.8 tall, twig colour #8A4A2A / #6E3A20.
  - Pumpkin: **2.2 studs**, PointLight or Neon rind glow, range 8.
  - Better pumpkin tiers can appear deeper in the cluster.

### 1.11 Guard: size against the character, and placement
- **THEIRS:** guard size **escalates by zone**.
  - Forest: white voxel chicken, **0.7 ch** (s003#4-#6).
  - Volcano: boar with flame spikes, about **3 ch long** (s016#8, s017#1).
  - Abyss: white whale, about 1.5 ch (m0466).
  - Desert: green crocodile, **6-8 ch long**, about 2 ch tall (s047#2-#7).
  - Cosmic: gorilla king, **3 ch tall** (s027#3).
  - **Placement:** the guard sleeps **inside or at the edge of the nest cluster**, within 1-3 ch of the nearest nest.
  - Huge cyan 3D "Z Z" letters, up to 1.5 ch, float above it.
- **OURS:** the generated guards are all about 1-1.3 ch (frog, tree, knight, scarecrow, skeleton, ghost in `omwncl`/`h58g3b`), so there is no escalation.
- **EXACT FIX:** heights (or lengths for long creatures):

  | Zone | Size | Studs |
  |---|---|---|
  | Meadow | **0.8 ch** | **4** |
  | Graveyard | **1.5 ch** | **8** |
  | Woods | **2.5 ch** | **12** tall |
  | Swamp | **4-6 ch** | **20-30** long |

  - Place each guard **at the cluster centre**, with the nearest nest **6 studs** away.
  - Give it cyan "Z" letters **4-7 studs** tall, bobbing 12 studs above it.

### 1.12 Shop stall
- **THEIRS:**
  - An open stall: brown wooden posts about 1.5-2 ch tall, a red/white striped awning with a scalloped edge, and a counter.
  - It stands on a **glowing yellow circular pad** (soft gradient, about 3 ch across).
  - A **floating gold 3D title "TRAILS SHOP"** (yellow #FFD21A, orange shading, letters about 0.8 ch tall) hovers above the awning (s008#3, s002#6, m0452, s014#9).
  - "SELL" is a second stall of the same kind (s037#7).
- **OURS:**
  - The stall shape is close: posts, red/white awning, counter (`k8cybn`, `yr04b7`).
  - The pad is a flat solid yellow disc.
  - **No title.**
- **EXACT FIX:**
  - Add a **"SHOP" title** above the awning:
    - SurfaceGui or BillboardGui, **4-stud letters**, centred **5 studs above** the awning.
    - Fill #FFD21A with an #E07800 stroke, slow bob.
  - Pad:
    - **16-stud** diameter.
    - Make the pad a **Neon #FFE14A disc at 0.35 transparency** plus a soft outer ring.
  - Add a second **"SELL"** stall 24 studs away.

### 1.13 Lighting, sky and saturation
- **THEIRS:**
  - **Sky:** bright cyan **#34BFF6** at the top, pale lavender-white **#DFD6E7** at the horizon, white puffy clouds (m0168, s007#2, s016#5).
  - **Light:** always daytime with soft shadows and maximum saturation.
  - **Bloom:** only on neon (glowing scales, eggs).
  - **Haze:** slight, at the corridor end only. No colour cast.
- **OURS:**
  - The sky top is fine (#2791E9).
  - The **horizon and atmosphere are salmon/orange**: #B7A3A6 in the lane and **#CF8375 everywhere in the aerial** (`syburq`). That tints the whole map orange, which is very different from the reference.
  - There are no clouds.
- **EXACT FIX:**
  - **Atmosphere:**
    - Density 0.25, Offset 0.1.
    - **Color #DCE8F5**, **Decay #9CCFF2**.
    - Glare 0, Haze 0.5.
  - **Clouds:** add a `Clouds` object: Cover 0.55, Density 0.6, Color white.
  - **Lighting:**
    - ClockTime 14, Brightness 3.
    - OutdoorAmbient #808080.
    - EnvironmentDiffuseScale 1, EnvironmentSpecularScale 0.3.
    - ShadowSoftness 0.3.
  - **Effects:**
    - ColorCorrection: Saturation +0.15, Contrast +0.05, TintColor white.
    - Bloom: Intensity 0.6, Size 24, Threshold 0.95, so only neon glows.

---

## 2. How their models are made, and how to make ours match

### 2.1 What their models are
- **Construction:** **brick-built voxel**.
  - Every pet, egg, guard and prop looks assembled from small Roblox bricks.
  - **Stud bumps show on the faces** of most of them: crocodile (s047#2-#6), gold "?" egg (s043#8), beehive egg (s036#9), posts, bushes, bamboo.
  - No smooth or organic meshes, no outlines, no textures or prints.
- **Voxel resolution:**
  - About **6-10 cubes across the body** for small pets: Golden Chicken, Fox (s028#4).
  - About 20-40 cubes long for big guards and landmarks (crocodile, serpent). Big models do not add detail; they use the same cube style at a larger size.
  - The bible estimate is 50-300 cubes per pet.
- **Shape language:**
  - Boxy, stepped silhouettes.
  - Round forms are made by **stacked, inset rings** (beehive eggs, s036#9; pumpkin-like stepped spheres).
  - Animal anatomy is reduced to blocks: box body, box head, stick legs, stepped tail.
- **Proportions:**
  - Small pets have a **big head** (about 40-50% of the height): chicken, fox.
  - Big guards are **long and low** (crocodile 3:1, boar 2.5:1) or **hulking upright** (gorilla king, with tiny head and huge shoulders).
  - Meme brainrot pets are an object plus an animal: banana with a dolphin head, pepper with sunglasses and hands, elephant shaped like a strawberry.
- **Colours:**
  - **2-3 flat saturated colours per model.**
  - One body colour covers about 70%: chicken yellow, fox red with a white chest, crocodile sage green with white teeth, gorilla navy with a white mane and a gold crown.
  - Only Roblox lighting shades them.
  - Mutations swap the whole palette: Golden = all gold, Silver = all grey.
  - Neon accents are rare and meaningful: lime scales on the serpent, green radiation eyes on the crocodile, white eyes on the gorilla.
- **Faces:**
  - **Minimal.** Two small **black square eyes** of 1-2 voxels, sometimes with a white 1-voxel highlight (fox).
  - Often **no mouth**. A crocodile gets a row of white square teeth, and some guards get glowing rectangle eyes.
  - No eyebrows, no expressive cartoon mouths, no glossy pupils.
- **Pets vs eggs vs guards:**
  - **Pets:** 0.5-4 ch tall depending on weight, and they roam.
  - **Eggs:**
    - Zone eggs are simple stepped ovoids about 0.3-0.5 ch on nests, each zone with its own colour or pattern (white, red/white striped cube, lava black with orange, navy cube with a glowing top, sandstone pyramid).
    - The premium egg is a gold voxel "?" block, 0.8-3 ch.
  - **Guards:** **animals, not people** (chicken, boar, whale, crocodile, gorilla). They grow with zone depth (see 1.11), sleep, and wake with a red "!".
  - **Landmarks:** weight-scaled pets up to 20-40 ch.
- **Size against the avatar:**

  | Model | Size |
  |---|---|
  | Forest egg | 0.4 ch |
  | Chicken pet | 0.5 ch |
  | Fox pet | 1 ch |
  | Chilli pet | 1.5-2 ch |
  | Strawberry Elephant pet | 3-4 ch |
  | Forest guard | 0.7 ch |
  | Desert guard | 6-8 ch long |

### 2.2 Where ours drift from that (`omwncl`, `h58g3b`)
- **Frog (witch hat):** a smooth, glossy, sculpted mesh with realistic eyes. It breaks the style completely and should be replaced.
- **Knight, skeleton and scarecrow:** humanoid people, not creatures.
  - The knight has a human face with eyebrows.
  - The scarecrow has a **printed plaid texture** and denim overalls.
  - They are too detailed, and too many colours (5-7 each).
- **Tree:** an angry carved face with eyebrows and a mouth, and a cluster of purple dots on top: too much detail.
- **Ghost king and voxel frog:** closest to the target (blocky, few colours). The ghost has a lantern prop and blush, which are extras.
- **Sizes:** all about 1-1.3 ch, with no growth across zones.

### 2.3 Prompt wording and approach for Roblox Studio's AI mesh generator
**Approach, in priority order:**
1. **Guards and hero pets:** build them from **Parts (true voxels)**, not generated meshes.
   - Use 0.5-stud cubes for pets and 1-stud cubes for guards and landmarks, with the Studs surface on.
   - Use `generate_procedural_model` or a voxel-grid script. This is the only way to get their visible stud bumps on every face.
   - Use the mesh generator only for silhouette ideas, then rebuild in cubes.
2. If we keep using generated meshes, **force the style in every prompt**, then **recolour after generation**:
   - Strip textures: TextureID = "", one Color per MeshPart where segmentable (`segment_mesh`).
   - Set the size to the ch targets above.
3. Run every model through the same palette sheet: one main colour, one accent, black eyes, plus one optional neon.

**Prompt template (paste and fill the brackets):**
> "Blocky voxel [CREATURE], built from chunky cube bricks like a Roblox brick model, low resolution about [8] cubes across the body, stepped boxy silhouette, flat solid colours only: [MAIN] body, [ACCENT] [PART], small black square eyes made of single cubes, [no mouth | a row of white square teeth], big head about 40 percent of total height, short stubby block legs, toy-like and cute-menacing, visible round studs on top surfaces, no textures, no printed patterns, no clothing, no gradients, no outlines, no realistic detail."

**Add for guards:** "sleeping pose, lying down, eyes closed as flat black lines, curled up" (they sleep). Use "long and low four-legged beast" for the big zones.

**Add for pets:** "standing, idle, facing forward".

**Always avoid** (state it plainly in the prompt):
- smooth
- glossy
- realistic eyes
- eyebrows
- human face
- armour
- plaid
- fabric
- lantern or other held props
- more than 3 colours

**Halloween cast that fits their rules** (animals and creatures, escalating size):

| Zone | Guard | Colours | Size |
|---|---|---|---|
| Meadow | voxel **black crow** | black with orange beak | 0.8 ch |
| Graveyard | voxel **skeleton dog** | bone white, black eye squares | 1.5 ch |
| Haunted Woods | voxel **wolf** | grey-purple, glowing lime eyes | 2.5 ch tall |
| Witch Swamp | voxel **swamp toad king** | olive green, gold crown, long and low | 5 ch long |

- Pets: pumpkin-headed critters (pumpkin cat, bat, spider, ghost pup), 0.5-1.5 ch at Common, up to 3-4 ch for top rarity. Scale by weight like theirs.
- Pumpkins as eggs: stepped-ring voxel pumpkins with a glowing jack-o'-lantern face cut as square holes. Zone tiers: orange, white ghost pumpkin, purple, lime-glow. The premium pumpkin is gold with a "?".

---

## 3. Top 10 changes, ranked by how much they make the map read like Steal an Egg

1. **Ground and wall checker:**
   - Floor cells from 20 to **4 studs**, two lime tones at most 5% apart (#72F70E / #68EE0A).
   - Walls get the same 4-stud low-contrast cells.
   - This changes every single frame from "giant tiles" to their fine stud carpet.
2. **Walls:**
   - Height **30 studs** (from 44).
   - Colour **dusty terracotta #CC7258 / #C2684F** instead of bright orange.
   - Top cap **Neon lime #4CFF3A**, 1.5 studs (from purple).
   - **Per-zone wall colours** that change at the same line as the floor.
3. **Kill the salmon atmosphere:** Atmosphere Color #DCE8F5 / Decay #9CCFF2, add white Clouds, ColorCorrection Saturation +0.15. The sky becomes their cyan #34BFF6 look.
4. **Re-scale the map to the avatar:** corridor and hub **120 studs wide** (24 ch) instead of 160. Hub 150 long with 2 rows of 4 pens (30x26), 8-stud gaps and a 68-stud centre lane.
5. **Rebuild the pens as their paddocks:**
   - Lime floor (no pink/white floors).
   - **1.5x6x1.5 plum posts every 8 studs**, 3 thick **#D8470E** rails, an 8-stud gate.
   - **3 starting peach pedestals 6x4x2**, plus navy "Unlock $X" signs.
   - Pets roam inside the pen.
   - House icon 20 studs above your own pen.
6. **Zone titles move to the HUD** under the objective banner (grey, then coloured, with emoji). Delete the floating world billboards that clutter every corridor shot.
7. **Nest clusters:** **7 nests per zone** (3.5-stud twig rings, 10-14 studs apart, radius 18) around the guard, offset toward one wall, with glowing 2.2-stud pumpkins.
8. **Guards become voxel animals that grow by zone:** 4, then 8, then 12, then 25+ studs, each with giant cyan "Z Z" letters. Replace the smooth frog and the humanoid knight, skeleton and scarecrow, and rebuild in part-voxels with studs, 2-3 flat colours and square black eyes.
9. **Declutter the zones:**
   - Cut to **5-8 big (5-15 stud) studded props** per zone along the walls.
   - Keep a 40-stud clear run lane.
   - Delete the scattered mini pumpkins, crop rows, mushrooms and evenly spaced gravestones.
10. **Hub identity:**
    - 1-3 **giant voxel landmark pets (60-120 studs)** on the skyline.
    - Floating gold 3D **"SHOP"** title over the stall on a glowing neon pad.
    - Safe line as a **2-stud pink #F35583 studded strip** plus a "SAFE ZONE" ground decal instead of the thin red neon laser.
