# SECTION-MODELS: pets, pens, wild pumpkins, guards, King, carried pumpkins
Evidence key: R1@Ns = rec/play_000.mp4 frame at N seconds (R1@125s pen close-up, R1@100s Graveyard, R1@75s Meadow guard); HUB = shots/hub-v4-studs.jpg; NOW = current play-view jpg (Graveyard gate). Code in giant/src and giant/scene. I could not see the walking King boss or a hatch reveal in the closed clip (play_001 is unfinished), so boss notes come from code and the hub statue.

## 1. Flaws found
F1 **Every pet is the same size, so rarity cannot be read by size.** Config PetSizes asks for 3.5 to 12 studs, but Plots.minPetHeight/maxPetHeight clamp it to 2.5 to 3.8 (PatchConfig.luau:139-141) and maxPetWidth 4.2 caps it again (Patch.server Looks.hatch ~2076-2092). Voxel aspect ratios put nearly every pet at the 3.8 ceiling: a Common Crow and a Mythic Lava Slime are the same height. R1@125s: Pumpkin Pup and Bone Pup are both small on 6.6-stud discs.
F2 **Rarity is only a name colour.** No disc ring, no glow below Epic (aura is Epic+ only, client ~8160 block). Bone Pup (Rare) reads like a Common.
F3 **Gold/Shiny finish flat-repaints the whole model** (PetFinishes, Looks.hatch ~2100): Gold Pup (already yellow) becomes identical to a Gold mutation, and ribs/belly detail is lost.
F4 **Wild pumpkins are smooth KayKit meshes flat-recoloured, not voxel**, while pets, guards, King, fence are studded voxel. Ghost = 232,236,246, Moon = blue, CandyCorn = pink: in the Graveyard they read as clouds/blobs, not pumpkins (NOW; R1@100s: white "clouds" with a green Ghost standing on one). No ribs, no face, no shading. Style clash with the voxel world.
F5 **A candy emoji billboard on every wild pumpkin** (Patch.server ~4276-4290, MaxDistance 60). Thirty per zone is red-white confetti noise (NOW, R1@75s); it hides the pumpkin and signals nothing. Only Golden and Big ones deserve a marker.
F6 **Tier sizes barely differ**: scale 1.15 to 2.35 (x2 if Big) plus 3 random squashes; Moon (hp 700) and Candy Corn (hp 2500) look the same size, only colour differs.
F7 **Zone 1 guard is human-sized**: Zone1 guardHeight = 6 (PatchConfig ~334) while the model sheet expects ~3x a player (def.height 17.5). R1@75s: the Meadow scarecrow is a tiny orange speck beside an orange nest, on lime floor and orange wall; nothing says danger until the red "GUARD 42 studs" banner.
F8 **Sleeping guard has no pose change and the ZzZ crowds the head**; the Zone 2 guard (R1@150s) is a green blob near the floor hue; Graveyard skeleton is near-white on a near-white floor.
F9 **Nest = flat orange straw disc + small "?" pumpkins** (R1@75s), same hue as walls and Meadow pumpkins, so the prize does not pop.
F10 **Pen floor and discs have almost no contrast** (R1@125s): tan planks vs #92674A discs (scene/Lobby.luau:136-142); the dark rims barely show.
F11 **Locked slot = grey disc with a dark box padlock** (slotLook ~2370: Padlock 1.8x1.6x0.8 #3A3A44, thin gold shackle). It looks like a briefcase (R1@125s, several on screen). Price only on the next slot, so other locked slots say nothing.
F12 **Pet idle is a 0.18-stud bob and 3 degree tilt** (Patch.client ~8169). They walk at 4-6 studs/s then stand 1-3 s. No squash/stretch, hop, or per-species life (Ghosty does not float, Bat does not flap).
F13 **Roam range is +-3 studs (Plots.wander)** on 6.6-stud discs 8 studs apart; once pets get bigger (fix 1) they will cross onto neighbours.
F14 **Pen sign**: navy board + red bar, billboard 7x2 studs, MaxDistance 140 (Lobby.luau:150-166). Readable but competes with zone/HUD banners (ZION W1) and has no personality.
F15 **Fence**: thin 1x1x5.5 dark posts #40303A, orange X-braces #8E4312 (legible), but the 10-stud front gate is unmarked.
F16 **Carried pumpkins lose identity.** stackPumpkin (Patch.server ~2144) rescales every carried pumpkin to 2.6 (first) or 1.8 (rest) and drops billboards, so Mythic and Orange look the same. The chest pumpkin sits rigidly 1.8 studs in front of the root (0,0.6,-1.8) with no sway; R1@75s: a huge orange ball covers the avatar and scythe. Carried pets shrink to 1.8 studs.
F17 **King statue**: great head, but purple cape vs purple wall/plinth = low contrast (HUB); crown tiny; label flat yellow. Walking boss model (VoxelModels.luau:1132, 19x15x24 voxels at 1.2) not live-checked: verify the eye state reads at 40+ studs.
F18 **Mystery dome while hatching** (R1@125s): translucent dome over a white cloud-like blob, same look problem as F4. The purple READY dome is good.

## 2. What top games do
- Steal a Brainrot / Steal an Egg / Pet Sim: rarity = size AND colour AND aura. Mythic is 2-3x the height of a Common, has a ring/glow on its pad.
- Pets idle with a squash-hop every few seconds, blink or flap; never frozen.
- World collectibles share ONE art style with characters; value is readable from 30 studs by colour band + size; one marker only for jackpots (golden/big).
- Carried objects sit on the back/head, sway with movement, show tier colour.
- Zone guard silhouettes are huge, saturated and contrast the floor.

## 3. Fix spec (ordered by impact)
1. **[S] Pet size by rarity.** Replace the flat clamp with a table (studs, before width cap): Common 3.2, Rare 3.9, Epic 4.7, Legendary 5.7, Mythic 7.0; weight modifier (kg/median)^0.2 clamped 0.9 to 1.25. maxPetWidth by rarity 4.4 / 5.0 / 5.6 / 6.2 / 7.0. Hatch height = min(rarity height, widthCap * box.Y / max(box.X, box.Z)). Overhang over the disc rim up to 0.5 stud OK. Plots.wander 3 to 2.0 when height > 5.5. (F1, F13)
2. **[S] Rarity ground ring** under each pet: neon cylinder 0.15 thick, diameter 7.4, Transparency 0.55: Common none, Rare #3FA9FF, Epic #B45CFF, Legendary #FFB400, Mythic #FF3B6B (Legendary/Mythic pulse 0.55 to 0.35 at 1 Hz). Same colours on name label and reveal card. PointLight range 8 brightness 0.8 for Legendary+. (F2)
3. **[M] Voxel wild pumpkins with real silhouettes.** Build each type once with VoxelKit (like MysteryPumpkin: stepped rings, rib grooves, stem #3F8A2E) and clone. Body / rib: Orange #F28C1B / #C9650E; Sunny #FFD23F / #D9A31C; Ghost #EDEFFA / #B9BEDA with black carved eyes+mouth and thin neon #9FE8FF rim; Moon #4E7BFF / #2F52C8 with #FFF3A0 crescent; CandyCorn bands #FF6FC0 / #FFB23F / #FFFFFF; Golden #FFC83C neon sparkle; Shadow #4B1E7A / #2A0F4A with glowing #C06BFF eyes; Crystal #5AEBFF transparency 0.2; Inferno #FF5522 with neon #FFD060 cracks; KingSeed gold with tiny crown. Tier width in studs (before Big x2): 3.0 / 3.5 / 4.0 / 4.5 / 5.0 / 5.5 / 6.0 / 6.5 / 7.0 / 8.0. Random squash only on Y (0.9 to 1.1). (F4, F6, F18)
4. **[S] Candy icon only on value.** Keep the candy billboard only for Golden or Big wild pumpkins (56 px, MaxDistance 45); remove from the rest. (F5)
5. **[S] Guards.** Zone1 guardHeight 6 to 11. Scarecrow head orange (255,140,30) to straw #E8D27A with dark hat so it stops merging with orange walls. Skeleton legs/belt darken from (150,155,170) to #50546A. Sleep pose: head down 15 degrees, arms hanging; ZzZ billboard 2 studs above the head, float loop 0.6 s, colour #DDEBFF, MaxDistance 60. Awake: arms up 25 degrees, lean 8 degrees forward, eyes neon #FF2A2A. (F7, F8)
6. **[S] Nest pop.** Straw ring #E2C066 with dark #6A4A22 outer ring on a purple #5A2D86 base ring; 3 MysteryPumpkins at 1.4x with neon "?" 0.8 stud, PointLight #FFE070 range 14 brightness 1.2, sparkle every 0.5 s. (F9)
7. **[S] Pen floor/disc contrast.** Floor planks #6E4E34; disc top #C98B52 (Wood); rim #3A2414, diameter +0.8; locked disc stone #6E6E78 with #FFC83C 0.2 ring. Fence posts #2A1F33 with #FF8A1F top cap, rails #A5541A; mark the 10-stud gate with two lantern posts (jack-o-lantern 1.2 studs, neon #FFB84A). (F10, F15)
8. **[S] Padlock.** Body 2.6 x 2.2 x 1.0 #F2C12E, shackle 0.35 thick arch ~1.8 high #C8CCD6, keyhole #2B2B2B; lock icon without text on non-next slots. (F11)
9. **[M] Idle life.** Replace idle `abs(sin(t*3))*0.18` with a squash-hop every 2 to 4 s (0.9 stud peak, 0.35 s; scale Y 0.88 on launch, 1.1 at peak, 0.9 on land; 0.1 s dust puff) and a 1 Hz breathing scale 1.0 to 1.03. Per species Config.PetIdle: Ghosty float +0.8 stud, sway +-8 degrees; CandyBat flap (tag wing voxels, weld C0 +-25 degrees at 6 Hz) hover +0.6; Crow/Owl head bob; Slime squash 0.85/1.15 at 2 Hz. Roam idle 0.6 to 2.0 s (was 1 to 3). (F12)
10. **[S] Gold/Shiny keep detail.** Lerp base palette keys 60% toward the finish colour (keep eyes/ribs/belly); Shiny adds Sparkles #E0FFFF; Gold gets a slow shine sweep; skip Gold on GoldenPup (use neon #FFE070 outline). (F3)
11. **[M] Carried pumpkins.** Size by tier (Orange 1.9 up to 2.8 Mythic), keep tier colour and stem. Chest slot to the back (0, 0.4, 1.4) so it stops hiding avatar/scythe; head stack at 3.4 + n*1.9. Client sway on weld C0: x `sin(t*8)*0.12`, y `abs(sin(t*8))*0.15` when speed > 4. Carried pets min 2.4 studs. (F16)
12. **[S] King statue.** Gold trim 0.4 stud along the cape edge, crown 30% larger with tip jewel #FF3B6B, warm uplight #FFB060 range 40 from below; boss eyes neon #FFE070 idle, #FF2A2A raging. (F17)
13. **[S] Pen sign.** Board 8 x 4.5 navy #18294A with #FFC83C 0.3-stud frame, owner name on top, row of top-3 pet icons (24 px) under it; MaxDistance 140 to 90. (F14)

## 4. Acceptance test
1. Hatch one of each rarity: from the pen camera a Mythic is at least 2x the height of a Common with a coloured ring matching its name colour.
2. At the Graveyard gate every wild pumpkin reads as a pumpkin (stem, ribs, tier colour); no white cloud blobs; candy icon only on Golden/Big.
3. In Meadow the scarecrow and nest are visible within 3 s of looking, contrast floor and wall, and ZzZ is legible.
4. In a full 12-disc pen discs stand out from the floor, locked discs show a gold padlock (not a briefcase), idle pets hop every 2 to 4 s, no pet clips into a neighbour disc.
5. Carry 3 mixed-tier pumpkins while sprinting: each shows its tier colour, the stack sways, nothing blocks the scythe or view.
