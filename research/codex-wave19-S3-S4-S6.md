# Codex S3 + S4 + S6 (2026-10-03). Cite S0-art-bible.md for every colour, font and timing
Base: integrate/wave13 at dd0a598 or later. Do S3, then S4, then S6, each on its own branch.

Rules:
- Runtime-safe APIs only.
- Failing spec first.
- WaitForChild for sibling client modules.
- No blood: goo is teal. Prices 0. Plain names.

testcmd: cd game && stylua --check src tests && selene src && lune run tests/run.luau && lune run ../tools/lint_runtime_apis.luau && rojo build default.project.json -o out.rbxl

## Zion's decisions (10/03)
- **Campaign.** The game is a campaign of maps. Each map has 15 waves and the 3 difficulty tiers that already exist in Shared/Difficulty. Beating a map on Normal unlocks the next map.
  - Order: Outpost 9 (sky islands), Frost Relay, Magma Refinery, Hive Heart.
  - Each map has its own island count and layout, plus one short story line.
  - Build only Outpost 9 for real. The other 3 maps are data stubs, locked and marked "coming soon".
- **Zones.** Zion likes the zones ("rooms"). A map's zones open during the run.
- **Enemies.** Each map has its own enemy family. A family can return on a later map. Outpost 9's family is the Nest: chunky cartoon bugs in Chitin with Goo eyes.
- **Constants for every family:**
  - 5 roles: Swarmer, Runner, Shooter, Tank, Flyer. Each map also has Elites and one boss.
  - Each role keeps its silhouette rule: Swarmer small and low, Runner long and lean, Shooter with a visible sac or barrel, Tank wide with a shell, Flyer with wings.
  - Pink Telegraph means an attack is coming.
  - The kill burst from S2 plays on every kill.
- **Models:** Mix. Store or kit base meshes for enemies and props; our own models for bosses and weapons.

## S3 Campaign + Outpost 9 map
- **Shared/Campaign.luau** (pure):
  - An ordered map list with: Id, Name, StoryLine, Family, Zones, BossKey, LightingPreset, Locked.
  - unlockedMaps(profile) and nextMap(id).
  - Profile flag MapClear_<id>_<tier>. ProfileSchema.sanitize must keep it.
- **Shared/EnemyFamilies.luau** (pure):
  - The family's role table maps each role to an Enemies key.
  - Nest: Swarmer = Walker, Runner = Runner, Shooter = Spitter, Tank = Tank, Flyer = Flyer, Elite = Brute.
  - WaveTable asks for roles, not raw keys, so a new family plugs in without code changes.
  - Spec: every family fills all 5 roles. A family can appear on more than one map.
- **Outpost 9 layout** (replaces Station Deck as the default; ArenaLayout plus ArenaBuilder):

  | Zone | Waves | Contents |
  |---|---|---|
  | Landing Pad | 1-5 | Open, readable, the gate in sight |
  | Refinery | 6-10 | Pipes, catwalks, jump pads, a dash gap and a high loop route |
  | Hive Core | 11-15 | Goo pools, a Nest wall, the boss arena at the far end |

  - The 3 zones sit on separate sky islands, about 3x today's play area in total.
  - Bridges extend with a short animation and a "NEW ZONE" banner at waves 6 and 11.
  - Spawns come from gates in the open zones only.
  - Enemies path on a walkable grid (expose it; V4 will add a flow field later).
  - Parkour uses existing movement: jump pads give a fixed launch velocity; dash gaps are 14-18 studs.
  - Landmarks visible from spawn: a radio mast with an orange beacon, a refinery tower, and the Nest's glowing teal core.
- **Lobby board:**
  - Map picker: locked maps show a padlock and "Clear <previous> on Normal".
  - Difficulty picker: tiers unlock as Difficulty already defines.
  - A party launches with the map and tier its leader chose.
- **Run end:** a cleared map writes MapClear and shows "NEW MAP UNLOCKED" on the summary.
- **Specs:**
  - Campaign unlock order.
  - Family role coverage.
  - Zone bounds don't overlap.
  - Every spawn is inside an open zone for its wave.
  - Bridges open at waves 6 and 11.
  - RunSim with Outpost 9 still clears in 12-15 min on Normal.

## S4 Cinematic boss (Swarm Queen, Hive Core, wave 15; Big Brute stays the wave-5 and wave-10 mini-boss)
1. **Intro** (client only, about 4 s):
   - Letterbox bars.
   - The camera rises from behind the Nest wall.
   - The Queen bursts out with a roar, a dust ring and a screen-shake pulse.
   - A name card in LuckiestGuy: "SWARM QUEEN, Mother of the Nest".
   - Inputs are locked for that time only. The server waits for the intro before the Queen acts.
2. **Phase 1**, 100-55% HP. Three telegraphed attacks, each with a 0.8 s Telegraph decal:
   - Tail sweep (arc)
   - Goo mortar (3 circles)
   - Charge (line)
3. **Phase transition at 55%:**
   - She screams and the arena shakes.
   - The goo pools spread (floor hazard: 8 dmg/s, teal, clearly outlined).
   - Two Nest gates open and send adds every 12 s.
   - Her attacks speed up by 20%.
4. **Kill:**
   - 1.2 s slow-mo for all clients, client time only.
   - Camera orbit.
   - Big goo pop.
   - Loot shower of Coins and Gems.
   - "OUTPOST 9 CLEARED" banner.
   - Then V5 extraction: a 20 s run to the dropship pad.
5. **Specs:**
   - The phase thresholds.
   - Every boss attack has a telegraph of 0.6 s or more.
   - The adds cap stays within PoolSize.
   - Slow-mo never touches server time.

## S6 Model slots (code side; art lands separately)
- **ModelLibrary lookup by family, role and variant**, with a fallback chain: family model → Nest model → primitive.
- **Bosses and weapons** keep our own ModelAssets ids.
- **Kit and store meshes** go in Shared/ModelAssets under a Kit section, all 0 for now. Asset ids are filled later from the laptop.
- **Scale rules** (keep enemies big and readable; Zion asked for bigger enemies):

  | Role | Height (studs) |
  |---|---|
  | Swarmer | 4-5 |
  | Runner | 5-6 |
  | Shooter | 6-7 |
  | Tank | 9-11 |
  | Flyer | 6, at hover 8 |
  | Elite | 14-18 |

- **Camera** (Play thread found the camera clipping into enemies): the camera keeps 6 studs or more of minimum zoom. An enemy within 3 studs of the camera fades to 0.5 LocalTransparencyModifier on the client. Don't change CanQuery, because combat raycasts need it.
- **Specs:**
  - Every role in every family resolves to a model or a primitive.
  - Scale bands hold.
