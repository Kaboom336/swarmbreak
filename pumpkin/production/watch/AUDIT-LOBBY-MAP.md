# AUDIT: LOBBY + MAP + LIGHTING (2026-10-10)

Owner verdict: the new lobby "doesn't feel very premium". **Agreed, and it is fixable in about 1 day.** The lobby is a weaker copy of the Steal an Egg (SAE) hub: lime studs, terracotta checker walls, a neon-lime cap, X-brace fences, navy signs and a purple swirl pool. It has none of SAE's mass (giant player pets) and almost no Halloween identity. The camera sees mostly flat nuclear lime plus purple roads.

## Evidence
- **Builder:** `pumpkin\giant\scene\Lobby.luau`.
- **Our frames:**
  - `tool-results\mcp-Roblox_Studio-blob-1791684201110-xqymoc.jpg` (hub from the south, current build)
  - `...-1791683641670-gh82nh.jpg` (centrepiece close-up, carrying)
  - `...-1791683605120-8n8bny.jpg` (Meadow)
  - `rec\play_000.mp4` contact sheet, 28 s steps (0:00-5:08)
- **Reference frames:**
  - SAE: `refs\videos\sae-new-frames\h_0018`, `h_0346`, `h_1460`
  - SAE Halloween castle: `refs\aspects\halloween\media\R5JWbUcVDSk\f_0001`
  - PS99 Halloween: `OXZS_F-eSKM\f_0003`
  - +1 Tongue Evolution (TE): `tongue-evolution-frames\t_0494`, `t_0620`
  - Grow a Garden (GAG) and Steal a Brainrot (SAB): `grow-a-garden-frames\f_008s`, `f_0215s`, `steal-a-brainrot-frames\f_010s`, `f_236s`
  - Bibles: `BIBLE-*.md` §7
- **Live read-only queries** (Server/Client, hub box X 1320-1680, Z -80..160):

| Measure (hub) | Value |
|---|---|
| Parts | 3,580, of which **2,768 (77%) are wall bricks** (6x6x6 cubes) |
| Materials | Plastic 3,342 (93%), Wood 130, Cobblestone 33, Concrete 32, Neon **18**, Slate 4, Metal 17 |
| Lights | **4** PointLights in the whole hub |
| Area-weighted colours | lime #68EE0A + #72F70E ≈ **75k** stud² (≈60%); terracotta #CC7258/#C2684F ≈ 30k; orange path edge #E8701A ≈ 10k; path #4B4560 ≈ 9k; pen soil lime #6CC232 8.6k; neon cap #4CFF3A 6k. **Orange, the game's own hero colour, is only on the path trim** |
| Decor props | 8 kit props of 3 studs on the King ring, 6 post lanterns, 4 dead trees and 3 pennants: **about 21 props in about 75,000 stud² (1 per 3,500 stud², about 12x12 ch)** |
| Lighting | ClockTime 14, Brightness 3, Ambient #786E82, OutdoorAmbient #808080 (neutral grey), EnvSpec 0.3 |
| Post effects | **3 stacked ColorCorrections**: MapCC (S 0.15, C 0.05), BaseGrade (S 0.22, C 0.06, tint #FFF6EC) and ColorCorrection (S 0.12, C 0.08, tint #FFF0F8). Total ≈ **+0.49 saturation and +0.19 contrast** |
| Bloom | I 0.35, Size 24, **Threshold 1.6**, so Neon barely glows |
| Atmosphere | D 0.25, Color #DCE8F5, Decay #9CCFF2: a generic blue haze with nothing Halloween |
| Scale | Hub 340 x 220 studs and lane 120 wide (hub = **2.8x lane**; SAE about 2x). The 8 pens of 36x30 cover **11.5%** of the hub floor |
| Zone floors (centre ray) | Meadow #68EE0A (**same as the hub**), Graveyard #8FA88A, Woods #38904A, Swamp #3FB7A0, Castle #5A5785, Candy #F0ABD4, King #F28C1A |

The centrepiece stack is a SwirlPool (Neon #6A2BC2, 40 wide), 3 Slate tiers (#4A4458, 6 studs), the Plinth (Slate #463C54, 16 tall) and the GiantJack mesh (20 wide). That makes it **about 36 studs tall**. From the player's camera you see a purple drum with an orange underside cut off by the top of the screen (gh82nh). Playtest note W3 says it "reads as unfinished".

---

## 1. Scores (1-10, ours vs each reference on each line)

| Checklist line | vs SAE | vs PS99 spawn | vs GAG | vs SAB | vs TE | Why |
|---|---|---|---|---|---|---|
| Ground colour and material | 4 | 3 | 4 | 4 | 3 | #72F70E plus three CCs is greener and harsher than SAE #93F43A (yellow-lime, softer light). GAG #62B04E and SAB #48C054 are calm mid-greens. PS99 limits neon grass #6BFC4E to fields framed by white/lavender floors #E0F7FF. TE uses lime but breaks it every 3-4 ch with blue paths and props. Ours is an unbroken lime sea (xqymoc) |
| Walls | 4 | 3 | 5 | 4 | 3 | A literal SAE terracotta checker with a neon-lime cap, made of 2,768 cubes. TE and PS99 use voxel cliffs with dripping grass and trees on top; SAB uses brown brick. Ours is the most "default Roblox" surface on screen and spends the part budget on it |
| Pens / plots | 5 | 4 | 4 | 4 | n/a | The SAE X-brace fence plus discs is copied correctly but carries no Halloween identity, and the soil is lime on lime, so pens vanish into the floor. GAG has rich brown soil beds and a dark fence; SAB has 2-storey shells. Our pens read as small fences on a field |
| Paths and wayfinding | 4 | 4 | 5 | 6 | 3 | 8 spokes, a ring and a main path, 8-14 wide, in purple-grey Cobblestone with an orange edge. In xqymoc they read as **asphalt roads cutting a wheel** into the lime. TE uses blue stud paths 1 stud proud that lead to rows of glowing stations. SAB uses one red carpet. SAE has no paths. Ours has the most paths and the least purpose per path |
| Centrepiece / landmark | 3 | 4 | 4 | n/a | 3 | The SAE Rift is 3 ch with a crystal silhouette, a glow and a title. TE has a pink stone arch portal plus a KOTH pyramid with a spotlight. PS99 has a Giant Pumpkin on a slime puddle with a big title. Ours is a purple ziggurat with a cylinder and a cropped blob, so it has no readable silhouette at eye level |
| Prop density | 2 | 1 | 4 | 4 | 2 | Reference budget (halloween/REFERENCES §2.2): **1 prop per 2x2 ch near paths, 1 per 4x4 ch in open ground**. We have 1 per 12x12 ch, and the props are 3 studs tall (0.6 ch), smaller than the avatar. Even our own LOBBY-SPEC §4 ("every 15-20 studs along paths") was not built |
| Lighting / sky / atmosphere | 4 | 4 | 5 | 5 | 4 | Neutral grey OutdoorAmbient, blue haze and a bloom threshold that kills Neon add up to plain daylight. Three stacked CCs over-saturate the image. The Halloween refs keep daylight but add **lilac ambient, lilac or orange horizon and glowing yellow/orange accents**. We have none of the three |
| Scale and composition | 4 | 3 | 5 | 5 | 4 | The hub is 2.8x lane width with 88% empty floor. SAE fills its hub with 6-10 ch player pets; TE fills it with station rows. Ours has nothing taller than the 30-stud walls except the centrepiece |
| Halloween identity (distinct, not a copy) | 3 | 3 | n/a | n/a | n/a | Remove the 8 jack-o-lanterns and gravestones and this is an SAE hub. The SAE Halloween castle and PS99 candy-purple world show how far the theme can be pushed while staying bright |
| Hub to zone lane transition | 4 | 5 | n/a | 5 | 5 | The Meadow floor is the same lime as the hub, so only the thin safe line marks the change. SAE uses per-zone floor and wall swaps plus a gate prop at some entries. TE uses a gap in the cliffs and a visible "Stage 1" wall. Later zones are good (Castle #5A5785, Candy #F0ABD4, King #F28C1A, with walls recoloured per zone) |

**Overall: 3.5 / 10 vs the reference lobbies.** The zone lane after Meadow is about 6/10.

---

## 2. Issues and fixes

| id | What is wrong (specific) | What the refs do | Our distinct-style fix (Halloween identity) | Severity | Effort | Simplify / cut? |
|---|---|---|---|---|---|---|
| L1 | Three ColorCorrections stack to about +0.49 saturation and +0.19 contrast. With lime #72F70E this produces the "garish" look (W1, W2) | One mild grade (HOWTO §1: S 0.15, C 0.1). PS99 is high-key but floors are pale | **One** CC only: S 0.08, C 0.12, Tint #FFF1E6. Delete MapCC and BaseGrade (or set S/C to 0) | blocker | S | Cut 2 effects |
| L2 | OutdoorAmbient #808080 (grey), Atmosphere #DCE8F5/#9CCFF2 (blue) and Bloom threshold 1.6 make the scene read as generic daylight, and the 18 Neon parts don't glow | Halloween refs: lilac ambient #8C7AA8 / #9D8DBF, lilac haze #C9B6E8 with decay #7A52BF, bloom threshold 0.9 so windows and lanterns glow (SAE castle, AM) | "Harvest dusk in daylight" preset (§4 below): ClockTime 15.6, lilac shadows, peach-lilac horizon, Neon blooms | blocker | S | – |
| L3 | Hub floor is 75k stud² of #72F70E/#68EE0A studs, which reads as default baseplate (W2) | SAE #93F43A softened by light; GAG #62B04E; SAB #48C054; PS99 frames grass with pale floors | Grass to **#6BBF3F / #64B53A** (calm, still bright). Plaza ring and paths to **lavender paving #B8BADD / #A9ABD3** (SAE castle courtyard tone, not their lime). Keep Studs only on grass | blocker | S | Recolour only |
| L4 | Pen soil #6CC232 is lime on lime, so pens disappear | GAG brown soil #B37650 with a dark rim. SAE relies on giant pets, which we can't count on at launch | **Tilled pumpkin-patch soil #7A4E33** with 3 darker furrow strips #5E3A26 (0.25 tall) per pen. Orange pumpkins pop on brown, and "patch" becomes our identity | bad | S | – |
| L5 | Walls: terracotta checker #CC7258/#C2684F with a Neon lime cap #4CFF3A is a straight SAE copy, and 2,768 part cubes = 77% of hub parts | TE and PS99 use voxel cliffs with grass tops and trees; the SAE castle uses slate-purple brick with lit windows and orange lantern blocks every 2 ch | **Graveyard stone wall**: two-tone slate purple **#4E4775 / #453E69**, cream bone cap **#E8E4D0** (not neon), **Neon lantern cubes #FFB347 (1.5³) on the cap every 24 studs**, each with a PointLight (range 10). Rebuild as 12x6 slab panels (about 10x fewer parts) | bad | S recolour / M rebuild | Cut parts (perf, see WATCH-NOTES PERF) |
| L6 | Centrepiece = neon pool + slate ziggurat + 16-tall plinth + GiantJack, about 36 studs tall and seen from below. No silhouette, no title in frame | SAE Rift (crystal plus pool plus white title, 3 ch), PS99 Giant Pumpkin on lime slime with a big title, TE arch portal | **Pumpkin King's Throne**: drop the pool and tiers. Use a low 2-tier lavender dais (5 studs total, #B8BADD top, #8A86B8 side, orange Neon trim ring #FF8A1A) ringed by 8 hay bales (#E3B04B, Fabric) with mini jack-lanterns. Scale the GiantJack to 26 wide, standing on the dais with no plinth, so its **Neon face sits at eye level, 8-20 studs up**. Add a gold crown #FFC83D (4 wedges plus a band), an orange PointLight (range 40, brightness 3), and a "PUMPKIN KING" title billboard in #FF8A1A with an aubergine #2D1F43 stroke | blocker | M | Removes 5 parts and a Neon disc |
| L7 | 8 path spurs plus a ring plus a main path in Cobblestone #4B4560 with an orange #E8701A edge read as roads, cut the lime into a wheel, and cost 10k stud² of the loudest trim | TE: few purposeful paths to station rows. SAE: none, with ground chevrons for guidance | Keep the **main path plus the ring only**, in lavender paving #B8BADD with a cream edge #E8E4D0 (no orange). Replace the 8 spurs with **stepping-stone trails**: flat round 4-stud stones #A9ABD3 every 6 studs. Guidance stays on the existing red chevrons | bad | S | Cut 8 spurs |
| L8 | Prop density is 1 per 12x12 ch, and the props are 3 studs (smaller than the avatar) | 1 per 2x2 ch near paths; hero props over 2 ch; pumpkin piles 5-9 each (PS99, GAG) | Use the 63 KitSource props (already present). **Pumpkin piles** (pumpkin_orange, _yellow, _small: 5-7 per pile, 2-6 studs) at every pen corner and both sides of every stepping-stone trail. **tree_dead_large_decorated** at 20-25 studs with `lantern_hanging`. Add crypt/coffin/candle clusters on the 4 hub corners. Target about **120-150 props**. Every kit prop 1-1.5 ch tall, not 3 studs | bad | M | Placement loop only (placeKit already exists) |
| L9 | The lantern-post runway on the main path (6 `post_lantern`) reads as a runway (lobby REFERENCES §4) and doesn't glow | Harvest-fair warmth: AM glowing windows, SAE lantern blocks | **String lights**: 4 tall dark posts (#2D1F43) each side of the main path with sagging rows of Neon bulbs #FFB347 (0.8 balls, 3 studs apart, built as short segments between posts). This is the cheapest "premium" signal at dusk-tint lighting | polish | S | Replaces 6 lanterns |
| L10 | No hub skyline: nothing but the centrepiece rises above the 30-stud wall, and the sky is generic | SAE castle spires; HOWTO §4 "far backdrop ring of giant shapes" | **Haunted Gate** over the lane mouth: two voxel towers 10x10x42 (#403D69) with stacked-cube purple spires (#7A52BF, black tip #2D1F43), lit windows Neon #FDF301 every 6 studs, and an orange banner arch "PUMPKIN PATCH →" #F28C1A. Plus a far **daytime moon**: Neon disc 160 wide, #F3E6FF, transparency 0.25, behind the far end of the lane | bad | M | – |
| L11 | Hub is 340 x 220 (2.8x the lane). Pens cover 11.5%, and walks are long and empty | SAE about 250 x 160 with pens 10-15 studs apart | Don't move contracts before launch. **Fill** instead: the props from L8 and the pumpkin patch fields from L13 eat the dead lime. Post-launch, shrink to about 280 x 180 | bad | S fill / L shrink | Shrink post-launch |
| L12 | Pens have SAE colours (brown rails #8E4312 on plum #40303A, navy sign #18294A), so there is no own identity | SAE colour-codes by section level | **Jack-lantern fence**: rails warm wood #9A5B2E, posts aubergine #2D1F43 with **Neon orange cap cubes #FF9A2E** (1x0.6x1) on every post. Upgraded fence = purple rails #7A52BF with gold caps #FFC83D. Sign board in aubergine #2D1F43 with an orange bar #F28C1A (not navy/red) | polish | S | Recolour |
| L13 | Large empty lime patches between the side pens and the walls | PS99 breakable fields; GAG beds | Two decorative **pumpkin patch fields** (tilled soil #7A4E33, 3x5 grid of kit pumpkins 3-5 studs, low fence) in the empty north-east and north-west corners. They show the game's fantasy at spawn | polish | S | – |
| L14 | Meadow floor = hub lime, so leaving safe never feels like entering a zone (xqymoc, 8n8bny) | SAE: hard floor and wall swap per zone, gate props | Meadow floor to **golden harvest grass #A6CF4A / #9CC544** with straw-yellow patches #E8C36A. Walls #8E5B3A barn-wood (2-tone #845234). The Haunted Gate (L10) is the threshold | bad | S | Recolour Zone1 |
| L15 | Huge orange low-poly tree blocks the Meadow camera (W2, 8n8bny right edge) | Props along walls, centre lane clear | Move the tree to 6+ studs from the wall line, or scale it to 0.6x | polish | S | – |
| L16 | Neon lime #4CFF3A caps run around every lane section too (8n8bny) | SAE-specific signature | Cap colour per zone (cream #E8E4D0 in the hub and Graveyard; zone accent elsewhere) or none | polish | S | – |

---

## 3. The 5 changes that most raise "premium" for the least effort

1. **Lighting preset swap (L1 + L2), effort S, about 15 lines.** One CC, lilac ambient, peach-lilac atmosphere, bloom threshold 0.95, ClockTime 15.6. This fixes the garish lime and makes every Neon item glow at once. It is the biggest perceived-quality jump per minute.
2. **Recolour pass (L3 + L4 + L5 colour + L12 + L14), effort S.** Calm grass #6BBF3F, lavender paving, tilled pen soil #7A4E33, slate-purple walls with a cream cap, the jack-lantern fence and golden Meadow. Change only `hex(...)` values in Lobby.luau lines 35, 46, 57, 88, 98, 152-154 and 206.
3. **Pumpkin King's Throne (L6), effort M.** Delete SwirlPool, Tier1-3 and Plinth height, build the low dais with hay bales, scale GiantJack to 26 at eye level, add a crown, a light and a title. This gives the hub one hero silhouette.
4. **Prop flood from KitSource (L8 + L13), effort M.** About 120-150 placeKit calls with a 1-1.5 ch minimum: pumpkin piles at every pen corner and trail, decorated dead trees with hanging lanterns, corner crypts, 2 decorative patch fields. Swap spurs for stepping stones (L7).
5. **Wall lanterns plus string lights (L5 lanterns + L9), effort S.** About 30 Neon cubes on the wall cap and 2 rows of bulb strings on the main path. With item 1's bloom this gives the "lit at dusk" premium glow the SAE castle and AM rely on.

(The Haunted Gate in L10 is next, at M effort. Do it if a half-day remains.)

---

## 4. Art direction: "Pumpkin Patch at Golden Hour" (distinct from SAE)

**Idea:** a moonlit harvest fair seen in late-afternoon light. The pumpkin patch, the lanterns and the King are the heroes. It is bright and readable for kids (never night, never black). The big shapes are orange and purple, warm yellow is the glow, and lime appears only as magic goo. That is the rule every Halloween reference follows (halloween/REFERENCES §2.1).

### Palette
| Role | Hex | Material |
|---|---|---|
| Hub grass (2-tone 8x8 tiles) | #6BBF3F / #64B53A | Plastic, Studs top |
| Plaza and path paving | #B8BADD / #A9ABD3, edge #E8E4D0 | SmoothPlastic (or Slate at 0.5 contrast) |
| Pen soil / patch fields | #7A4E33, furrows #5E3A26 | Ground or Plastic (no studs) |
| Walls (2-tone) | #4E4775 / #453E69 | Plastic slabs |
| Wall cap / bone trim | #E8E4D0 | SmoothPlastic |
| Pumpkin orange (hero) | #F28C1A, shade #D35208 | – |
| Lantern / bulb glow | #FFB347 (warm), windows #FDF301 | Neon plus PointLight |
| Spire / roof purple | #7A52BF | Plastic |
| Outline "black" | #2D1F43 (aubergine) | – |
| Gold (crown, upgrade caps) | #FFC83D | Metal (EnvSpec 0.3 already) or Neon at 0.4 transparency |
| Magic accent (cauldron goo only) | #78E580 | Neon |
| Hay bales | #E3B04B, bands #B5832E | Fabric |
| Meadow zone grass | #A6CF4A / #9CC544, straw #E8C36A | Plastic |

### Landmark props (simple parts/voxels)
1. **Pumpkin King's Throne** (centre): a low lavender dais, a ring of hay bales, the GiantJack at 26 wide at eye level with a Neon face, a gold crown, an orange light and a title.
2. **Haunted Gate** (safe line / lane mouth): twin voxel towers 42 tall with stacked-cube purple spires, yellow Neon windows and an orange "PUMPKIN PATCH →" banner arch.
3. **Witch's Cauldron Sell stand**: cauldron 10 wide in #2D1F43, a Neon goo disc #78E580, bubble particles and a green PointLight. It replaces or fronts the plain SELL stall and gives the only lime in the hub.
4. **Harvest string lights**: sagging Neon bulb rows #FFB347 between aubergine posts over the main path.
5. **Daytime moon**: a 160-stud pale-lilac Neon disc low over the far end of the lane, visible from spawn.

### Lighting (Lighting service; set Base* values that the PhaseTint client code reads)
- ClockTime **15.6**, Brightness **2.4**, ExposureCompensation 0, GlobalShadows true, ShadowSoftness 0.2
- Ambient **#8C7AA8**, OutdoorAmbient **#9D8DBF**, ColorShift_Top **#FFD9A8**, EnvironmentDiffuseScale 0.4, EnvironmentSpecularScale 0.3
- **One** ColorCorrection: Brightness 0.02, Contrast 0.12, Saturation 0.08, Tint **#FFF1E6**. Delete MapCC and BaseGrade.
- Atmosphere: Density 0.28, Offset 0.12, Color **#E7C8E8**, Decay **#B07ACF**, Glare 0.15, Haze 1.2. This gives a peach-lilac horizon and pushes the far lane back.
- Bloom: Intensity 0.8, Size 28, **Threshold 0.95**. SunRays: Intensity 0.06, Spread 0.6.
- Keep the existing cartoon skybox. Spooky Hour and Midnight tints (Patch.client.luau:3066-3170) should lerp from these new base values, so check that they read the Lighting values at start.

### Build notes (keep it simple)
- All of this is part recolours plus placeKit loops plus about 60 new primitive parts (dais, crown, towers, bulbs, lanterns). No meshes are needed. The KitSource (63 props) already covers pumpkins, trees, crypts, coffins, candles and lanterns.
- Rebuilding the walls as slabs cuts about 2,500 parts (PERF note in WATCH-NOTES). Lanterns go on the cap, not in the bricks.
- Contracts stay the same: `Patches/Pen*`, `Plot` Index, `SignPost/Board/OwnerSign`, `Market.*` names, the SpawnLocation and safe line Z 150.
