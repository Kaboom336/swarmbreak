# AUDIT: MODELS + ANIMATIONS (ASPECT=MODELS-ANIM)

Date: 2026-10-10. The auditor made no game edits. Studio queries were read-only, on the Server datamodel during the live Play session.

**Evidence used**
- Code:
  - `giant/scene/VoxelModels.luau` (the builder for all pets and guards).
  - `src/ServerScriptService/Patch.server.luau`: Looks 1764-1947, stack/carry 1950-1996, hatch 2429-2512, guards 4490-4670, fight 4804-4902, scythe 6474-6600, King 6985-7219.
  - `src/StarterPlayerScripts/Patch.client.luau`: scythe swing 3357-3493, hatch 6090-6340, pet roam 6376-6426, carry halo 6427+.
  - `src/ReplicatedStorage/PatchConfig.luau`: Pets 213, PetSizes 228, PetFinishes 1086, MysterySizes 1251, PetRoam 1262.
- Our screenshots (in `tool-results/`):
  - `...1791678264934-atuiud.jpg`: the current voxel pet and guard line-up.
  - `...1791675482342-393qte.jpg`: the voxel Scarecrow next to an older Scarecrow, plus the hub King statue.
  - `...1791643847651-8jv9de.jpg`: the previous guard set.
  - `...1791665556227-4ult12.jpg`: the King fight.
  - `...1791683641670-gh82nh.jpg`: the carry halo.
- Playtest: `watch/rec/play_000.mp4` contact sheet; AUDIT-SEG0 A07 and A32.
- References:
  - `refs/aspects/models/REFERENCES.md` and `HOWTO.md`.
  - SaE frames `refs/videos/v2-sae-everypet-sheets/s006.jpg` (1:32-1:38, the egg is carried in the arms at chest height).
  - PS99 `v2-ps99-index-sheets/s003.jpg`.

## 0. Live census (Server, during play)

| Model | Parts | Welds when placed | Size (studs) | Notes |
|---|---|---|---|---|
| PumpkinPup / GoldenPup | 39 | 39 | 5.4 x 5.5 x 7.2 | GoldenPup is only a recolour |
| Crow | 42 | 42 | 4.8 x 8.5 x 6.6 | |
| Ghosty | 52 | 52 | 5.4 x 6.7 x 4.8 | |
| BlackCat | 49 | 49 | 4.8 x 9.1 x 5.4 | |
| KingCat | 70 | 70 | 8.4 x 9.1 x 5.4 | BlackCat body plus wings and a crown |
| CandyBat | 39 | 39 | 8.4 x 8.5 x **3.0** | a flat card |
| BonePup | 48 | 48 | | |
| FrostOwl | 50 | 50 | | |
| LavaSlime | 68 | 68 | | 22 Neon parts |
| Moth | 51 | 51 | 7.2 x 6.7 x **3.6** | a flat card |
| Toad | 43 | | | |
| GummyBear | 42 | | | |
| PumpkinDragon | 65 | | | |
| Kinglet | 90 | | | |
| **MysteryPumpkin** (nest egg) | **169** | **169** | 6.6 x 7.9 x 6.6 | **18 are live in the nests = 3,042 parts + 3,042 Welds** |
| Scarecrow guard (Zone1) | 37 | 37 WeldConstraints | 13 x 16 x 7 | |
| SkeletonKnight guard | 63 | | | |
| TreeEnt guard | 182 | | | |
| SwampToad guard | 98 | | | |
| Vampire guard | 93 | | | |
| CandyGolem guard | 92 | | | |
| PumpkinKing (Zone7 *guard*) | 233 | | 22.8 x 28.9 x 16.8 | **not** used for the boss |
| Pumpkin King **boss** | 1 MeshPart `Market.KingFace` (20 x 17 x 19) | | | a pumpkin head on a static purple cylinder |

Where the parts are (workspace total 13,102 parts and 4,640 joints):

| Location | Parts | Joints |
|---|---|---|
| Garden/Zones | 4,910 | 4,178 |
| Ground | 3,234 | 0 |
| Art | 3,079 | 0 |
| Patches | 1,316 | 278 |
| Wild | 280 | 0 |

- The Zones figure contains the 18 nest MysteryPumpkins (3,042 parts) and the 7 guards (805 parts).
- The 9 pets in the pens add about 470 parts.
- **Models are about 4,300 of the 13.1k parts and about 4,000 of the joints.** The MysteryPumpkin alone is 23% of all parts and about 70% of all joints.

Why the counts are high:
- `build()` (VoxelModels.luau:59-121) merges cells greedily only in X/Z within one layer, and stacks a layer only when the whole layer is identical.
- Grooves, faces and neon "?" pixels break every merge.
- `Looks.attach` (Patch.server:1850-1869) then adds one `Weld` per part.
- `guardLook` (4519-4534) adds one `WeldConstraint` per part.
- `ServerStorage.VoxelOut` is a full duplicate of PetModels and GuardModels. It is not rendered, but it is dead weight.

## 1. Scores 1-10 (our game vs the reference on each line; refs = SaE / PS99 / SaB / GaG)

| # | Checklist line | SaE | PS99 | SaB | GaG | Evidence |
|---|---|---|---|---|---|---|
| 1 | One consistent model style | 6 | 5 | 6 | 6 | Pets and guards are uniform voxel. But the King boss is a smooth mesh pumpkin, the ghosts are a smooth mesh (`PolishAssets.GhostMesh`), the Jack fallback uses ball eyes, and the hub uses photo-stone paths. Three styles show at once. |
| 2 | Pet cuteness and faces | 5 | 3 | 5 | 5 | Eyes are one voxel (0.6 stud) on a 9-14-voxel head (8-10% of the head width). SaE eyes are larger with a white glint. PS99 pets have big glossy eyes and rounded meshes. There are no glints, cheeks or mouths, although HOWTO §1 asks for all three. Cat, Owl and Gummy read fine; Pup, Crow and Toad look like Minecraft mobs. |
| 3 | Silhouette variety | 6 | 4 | 6 | 5 | The 16 shapes are distinct. But KingCat is BlackCat + wings, GoldenPup is PumpkinPup recoloured, and CandyBat and Moth are 3-3.6 stud thick cards that vanish edge-on. |
| 4 | Size progression (rarity and weight) | 5 | 4 | 6 | 5 | Pets are 3.6-7.4 studs (live Pen2). SaE is 0.5-1 ch for Common and 2-4 ch for Mythic+, so our Common is right but the top end is too timid: Mythic is capped at 15 studs and nothing like the 8-12 ch SaE Kaiju. **The pen pumpkin grows to 15-40 studs (MysterySizes.heights, PatchConfig:1259) and then hatches into a 3.6-stud pet**: a 4-10x size *drop* at the payoff moment. |
| 5 | Rarity readable on the model | 3 | 2 | 4 | 4 | All pets are flat Plastic with no aura, glow, particles or outline by tier. Only the tag text shows rarity. Gold/Shiny turns **every part Neon gold**, eyes included, so gold pets lose their faces (Patch.server:1934-1944). |
| 6 | Pet idle motion | 3 | 2 | 4 | 4 | The idle bob is `abs(sin(t*3))*0.06` studs (client 6418), about 1% of height and invisible. There is no breathing, look-around, blink or tilt. |
| 7 | Pet walk motion | 4 | 3 | 5 | 5 | The model is rigid and slides with a 0.25-stud `abs(sin(9t))` hop (client 6417). There is no forward tilt or squash. Facing snaps instantly to each new waypoint (6414-6416), and the legs never move. |
| 8 | Hatch animation | 7 | 6 | 7 | 7 | Good: a 1.6 s rock that accelerates to ±15° with a white glow, a flash, 6-10 shell slabs, a camera punch and a reveal card (client 6104-6339). Missing: the pet does not *pop* in (no scale-up or rise; it appears at full size the frame the shell vanishes), and the size drop from row 4. |
| 9 | Guard/enemy looks | 5 | n/a | 5 | n/a | Vampire, Golem and Ent read well (atuiud.jpg). The **Zone1 Scarecrow**, the first guard every player sees, is a T-pose with a flat orange slab head and 2 dots, and is worse than the older part-built Scarecrow that had a jack face (393qte.jpg vs 8jv9de.jpg). SwampToad is a green dome. |
| 10 | Guard motion | 3 | n/a | 4 | n/a | Asleep: a static -7° slump with no breathing; only the Zzz tag bobs. Awake: the "!" tag plus a roar, but **the eyes never turn red**, because `setAwake` looks for parts named "Eye" (4658-4660) and every voxel part is named "V". Chase: an anchored root moved by the server each Heartbeat (4664-4669), with a 0.35-stud waddle and ±5° roll; it replicates at network rate, which is choppier than client-rendered pets. Fight/stun: the guard just freezes, with no hit, stagger or dizzy pose. Bonk: knockback only, and the guard plays no swing. |
| 11 | Boss looks (Pumpkin King) | 2 | n/a | 3 | n/a | The boss is one smooth pumpkin MeshPart on a plain purple cylinder (4ult12.jpg; AUDIT-SEG0 A32 "reads as a mushroom"). There is no body, crown, cape or arms. A proper voxel PumpkinKing (crown, cape, neon face, 233 parts) already exists, but it is only used as the Zone7 guard. |
| 12 | Boss motion | 3 | n/a | 3 | n/a | Walk: the head slides to 4 pads with no bob or steps, leaving the cylinder behind (7050-7092). Slam: a 0.25 s rise of 7 studs and a 0.15 s drop (7132-7150), which is fine. Stun: a 25° bounce tilt, which is fine. Death: a 1.4x swell, which is fine. It reads as a hopping ball. |
| 13 | Tool (scythe) looks | 6 | 4 | 6 | 5 | The 5-segment arc blade is big and reads well, and the tier colour and 6% size per tier work (gh82nh.jpg). Tiers look alike apart from colour; PS99 and SaB tools change shape per tier. |
| 14 | Tool swing | 4 | 3 | 4 | 4 | Only `tool.Grip` is keyframed (5 keys, 0.42 s, smoothstep, trail between 0.07 and 0.3 s; client 3374-3424). The arm stays in the default tool-out pose, so the blade spins around a frozen fist. There is no body twist or step. |
| 15 | Pickup and carry pose | 3 | n/a | 4 | n/a | There is no pose: the stack is welded above the head and shrunk to a max side of 4 studs (`MysterySizes.carry`). A see-through Neon ball halo is drawn around it. SaE carries the egg **at chest height in both arms**, with the arms forward (sae-everypet s006, 1:32-1:38). Our default arm swing plus a floating ball reads as unfinished. |
| 16 | Steal fight (tap duel) | 3 | n/a | 4 | n/a | The player is anchored and the guard frozen while a UI bar fills (4833-4886). Nothing physical happens between the two models. |
| 17 | Nest and hatch-pumpkin props | 5 | 5 | n/a | 5 | The MysteryPumpkin's stepped octagon with a neon "?" is on-style and readable. The nest straw is 9 plain parts. 169 parts per egg is the problem. |
| 18 | Performance of models | 2 | 3 | 3 | 3 | See §0. The nest eggs are the single biggest part sink in the place. |

**Which models look like programmer art (blunt list)**
1. **The Pumpkin King boss**: a mesh pumpkin on a cylinder that slides around. This is the worst asset in the game, and it is the endgame event.
2. **The Living Jack fallback** (`dressJack`, 1688-1762): ball eyes, a 2-wedge V mouth and stick legs. It shows whenever a pet model is missing, and the red jack is visible in 393qte.jpg.
3. **The Zone1 Scarecrow guard** (voxel): a T-pose, a featureless slab face and 2 pixel eyes. It is the first enemy every player meets.
4. **The carry halo**: a translucent neon ball.
5. **The shell slabs**: flat SmoothPlastic bricks that do not match the voxel pumpkin.
6. **SwampToad**: a dome.
7. **GoldenPup**: a pure recolour sold as Epic.
8. **Gold/Shiny finish**: an all-Neon blob with no face.
9. **CandyBat and Moth**: paper-thin from the side.

Close to reference quality: Vampire, CandyGolem, TreeEnt, FrostOwl, BlackCat, GummyBear, Ghosty, Kinglet, and the voxel PumpkinKing model.

## 2. Issues

| id | What is wrong (specific) | What refs do | Our distinct-style fix (Halloween identity) | Sev | Eff | Simplify/cut? |
|---|---|---|---|---|---|---|
| M01 | The boss is a mesh pumpkin head on a cylinder; the head slides off the pedestal to walk (Patch.server 7050-7092; 4ult12.jpg). | SaE late bosses are armoured voxel creatures, 3-4 ch. SaB bosses are full characters. | Use the existing **GuardModels.PumpkinKing** voxel model (crown, cape, neon carved face) scaled to about 30 studs as the boss. Weld it to an invisible root that is moved the same way as `kingFace`. Give the Zone7 guard a smaller recolour (or the Kinglet scaled up). Delete the purple cylinder and put a throne under the idle King. | blocker | M | Yes: one model for the statue and the boss |
| M02 | 18 nest MysteryPumpkins = 3,042 parts + 3,042 Welds, about 23% of the place's parts and about 70% of its joints. | SaE eggs are single models; PS99 eggs are single meshes. | The carrier is *already* a pumpkin MeshPart (`makePumpkin`). Keep it visible and drop the 169-part look: add a tinted Neon "?" `SurfaceGui` or Decal on its front, plus the existing PointLight and sparkles. **Result: −3,000 parts and −3,000 welds.** If the voxel look must stay, union it once in Edit (1 UnionOperation with UsePartColor=false, plus a separate Neon "?" part, about 3 parts). | blocker (perf) | S | Yes |
| M03 | The pen pumpkin is 15-40 studs (`MysterySizes.heights`, `penMin = 15`), and the pet hatches at 3.6-7.4 studs: the reward shrinks 4-10x. | SaE: the egg grows by weight and the pet comes out egg-sized or bigger (Kaiju 10-12 ch). | Set pet height to about the pen pumpkin height × 0.8, or cap pen pumpkins at 1.2× the pet's future height. Raise `Plots.maxPetHeight` from 15 to about 30 so Legendary and Mythic tower over the player (SaE 2-4 ch). | blocker | S | |
| M04 | There is no carry pose. Loot is welded above the head and shrunk to 4 studs inside a neon ball halo (`stackPumpkin` 1960-1987; client 6427+). | SaE: the egg is held at the chest in both arms, arms forward, about 1 ch (sae-everypet s006). | Add one R15 "Carry" animation: both arms forward and up 70° (2 keys, looped, priority Action). Put the **first** pumpkin in front of the chest at about 3 studs, and stack extras above it. Replace the halo with a thin gold `Highlight` outline on the carried item (DepthMode AlwaysOnTop for the guard's view). | bad | S | Yes: cut the halo ball |
| M05 | Guard eyes never glow red on wake: `setAwake` and `guardLook` look for parts named "Eye", but `build()` names every part "V" (VoxelModels:102). | SaE: a red "!" plus a visible wake. | In `build()`, name each part after its palette key (`p.Name = ch`) and treat the eye keys (`k`, `e`, `y`) as eyes. Wake = eyes Neon red + a 0.25 s hop + 10% scale punch. | bad | S | |
| M06 | Gold/Shiny turns every part Neon, eyes included: a glowing blob with no face (1934-1944). | SaE Golden is gold-coloured with eyes kept; GaG Gold is a glow. | With parts named by key (M05), skip the eye and dark keys. Use `Foil` gold (#FFD606) plus one PointLight and a sparkle emitter (HOWTO §5), not Neon on everything. | bad | S | |
| M07 | Rarity is invisible on the model (flat Plastic for all tiers). | PS99: Huge/Titanic sizes, rainbow and gold shines. SaE: mutation materials, big Mythic pets. | Give each tier one layer: Rare = soft colour outline Highlight (FillTransparency 1), Epic = plus a slow sparkle (Rate 3), Legendary = plus a gold rim and a floating 0.5-stud bob, Mythic = plus a purple ground-ring decal and wisps. Use the rarity colours of the tags. | bad | S | |
| M08 | The pet idle is invisible (0.06 studs). The walk is a rigid slide with an instant turn and no tilt (client 6399-6425). | PS99 pets bounce and squash constantly; SaE pets roam and turn smoothly. | In the same RenderStepped: hop 0.6 studs with an `abs(sin)` period of 0.33 s, pitch forward 8° while moving, slerp the rotation at 0.15 per frame, and land with a 2-frame -0.1 dip. Idle: a 0.2-stud sine bob at 0.8 Hz plus a ±6° yaw look-around every 3-5 s. No rigs needed. | bad | S | |
| M09 | The pet appears at full size the instant the shell bursts (no pop). | SaE: the pet rises out of the burst. PS99: the pet scales in with a bounce. | Client-side, on Carved: offset the PetLook 2 studs down and fade it in, then tween up with Back easing in 0.35 s; add a 0.1 s squash via a CFrame Y offset. | polish | S | |
| M10 | Guards move on the server (anchored root CFrame per Heartbeat), so they stutter on clients; sleep is static; the fight and stun have no body motion. | SaE: smooth chase, a sleeping breathe and Z letters. | Replicate `pos/look/state` as attributes and render on the client like the pets. Sleep: 2.5 s Sine breathe (scale-like Y bob 0.15 plus pitch ±2°). Fight: the guard leans in and shakes ±4° at 12 Hz. Stun: 25° tilt plus orbiting star billboards. Bonk: a 0.2 s forward lunge. | bad | M | |
| M11 | The Zone1 Scarecrow is the first enemy and the weakest model (slab head, 2 dots, T-pose). | The SaE Forest chicken is tiny and cute, with a face. | Rebuild the head as a carved jack-o'-lantern (neon triangle eyes + grin, as on the Kinglet face), arms angled down 30°, and a crow on one shoulder. Keep it at 37-60 parts. | bad | S | |
| M12 | Tool swing is Grip-only: the blade rotates around a frozen arm (client 3374-3424). | SaB/PS99 use a full arm-and-torso slash animation. | Add one R15 "ScytheSlash" Animation: wind-up 0.08 s, slash 0.12 s, recover 0.2 s, with the torso twisting 25°. Keep the Grip keys for the blade arc on top, and the trail. | bad | S | |
| M13 | The Jack fallback (ball eyes, wedge mouth, stick legs) appears when a model is missing. | No fallback art is ever visible. | Make every seed map to a voxel pet. Have a startup assert print missing ones, and fall back to PumpkinPup, never dressJack. | polish | S | Yes: cut dressJack visuals |
| M14 | CandyBat and Moth are 3-3.6 studs deep (one wing plane); KingCat is BlackCat + wings; GoldenPup is a recolour at Epic. | PS99 and SaE: each rarity step is a new silhouette. | Give the bat and moth a 2-voxel-thick body bulge and wings angled 20° back. Cut GoldenPup as its own Epic pet and make it the Gold *finish* of the Pup. Give the Epic slot a new silhouette (for example a voxel witch-hat Spider). | polish | S | |
| M15 | Faces: 1-voxel eyes with no glint or blush, against our own HOWTO §1. | SaE has a white highlight voxel; PS99 has big eyes. | Make eyes 2x2 voxels (or 1x2) with a 1-voxel white glint, and add pink cheek voxels on the cute pets (Pup, Cat, Owl, Gummy, Ghosty). Keep the Halloween pets "spooky-cute" with neon orange eyes on BlackCat and Ghosty. | polish | S | |
| M16 | Pets use Plastic with Studs tops, but HOWTO §1 says SmoothPlastic for pets. Studs on 0.6 voxels add noise and block unions. | The studied frames show stud ground and clean pets. | Set pets to SmoothPlastic and keep studs on world props only. This also enables M17. | polish | S | |
| M17 | Each placed pet = 40-90 parts + as many Welds; the guards = 805 parts + 805 WeldConstraints. | Top sims use 1-3 MeshParts per pet. | Bake once in Edit: per model, `GeometryService:UnionAsync` of all non-Neon parts (UsePartColor=false keeps the voxel colours) gives 1 union + Neon parts + Root, about 3-8 parts and as many welds. Alternatively, export to Blender, decimate the coplanar faces, and import as one MeshPart. Pets go from 470 to about 50 parts; guards from 805 to about 40. | bad (perf) | M | Yes |
| M18 | `ServerStorage.VoxelOut` duplicates every model. | | Delete it after M17. | polish | S | Yes |
| M19 | Mixed styles: smooth mesh ghosts and the mesh King next to voxel pets, plus photo-stone paths. | SaE is 100% stud voxel. | Build the ghosts as voxel sheets (reuse Ghosty at 1.5x with a lantern) and the King per M01, so everything that moves is voxel. | polish | M | |

## 3. Five changes that most raise "premium" for the least effort

1. **Swap the boss to the voxel PumpkinKing (M01)** and remove the cylinder.
   - The model already exists, so this is about an hour of wiring.
   - It turns the worst asset into the best one, and it is the endgame headline.
2. **Kill the 169-part nest eggs (M02).**
   - Show the carrier MeshPart pumpkin with a neon "?" decal and the existing glow and sparkles.
   - This cuts about 3,000 parts and 3,000 welds (23% of parts, about 70% of joints) in roughly 20 lines.
   - It is the biggest performance win available before launch.
3. **Fix the hatch payoff size and the pop (M03 + M09).**
   - Pets come out at least as big as the pumpkin, with Mythic at 20-30 studs.
   - The pet rises and bounces out of the shell.
   - This is the dopamine moment of the whole loop.
4. **Make pets feel alive (M08 + M07).**
   - Add the bigger hop, forward tilt, smooth turning, idle look-around and per-rarity aura layers.
   - These are about 30 client lines with no rigs, and they turn statues into pets.
5. **Carry pose + scythe slash animation (M04 + M12).**
   - Add two short R15 animations (arms-forward carry and a body slash) and delete the halo ball.
   - The player sees their own avatar 100% of the time, so this is the most visible feel upgrade.

Also cheap bug fixes, about 10 minutes together:
- M05: wake eyes (name the parts by palette key).
- M06: gold pets keep their faces.
- M11: a face on the Zone1 Scarecrow.

## 4. Part-count plan (target: −4,000 parts, −3,900 joints)

| Step | Parts saved | Joints saved |
|---|---|---|
| Nest eggs → carrier mesh + decal (M02) | about 3,000 | about 3,000 |
| Pets baked to union + neon (M17); 9 live now, about 50 pets on a full server | about 420 now, 2,000+ on a full server | same |
| Guards baked (M17) | about 765 | about 765 |
| `VoxelOut` deleted | about 1,600 in storage (not rendered) | |
| Mesher upgrade: extend greedy merge along Y in `build()` (3D box merge), for models that stay as parts | 30-50% on the remaining voxel parts | |

Outside this aspect, but noted: Ground (3,234) and Art (3,079) are the other half of the 12.4k parts. Anchored static parts with no welds should be merged or unioned in the MAP pass.
