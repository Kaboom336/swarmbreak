# Pillar: models-art (pets, enemies, props, tools/weapons, collectibles: style, scale, readability, animation)

## Chosen game
**Steal an Egg (updates 2026-09-05 to 2026-10-10: Rift boss, Mounts/Rideable Pets 10 Oct, Enchanted Forest 3 Oct; frames are 720p grabs, 1280 wide, from FgqJESTt0dg, EnbiWqK76qw, IKoKllLzvX4, o1LK80i_Vmo).**
Why: it is our own loop (steal from guarded nests, hatch pets, big guards) and has the most consistent art system in the top charts: one studded-brick look for everything (guards, eggs, props, walls), a huge scale ladder, and loud neon accents so the important thing always reads. Pet Simulator 99 is the polish benchmark for chibi pets, but not for guards, props and boss.

## Reference frames
1. **ref-1** (Rift boss video 7:06) Gorilla King guard close-up. Every surface carries studs, 2-3 flat colours (near-black body, cream face, yellow fists and crown), glowing red eyes, a row of white teeth. Notice: the silhouette (big shoulders, fists, crown) reads from far away.
2. **ref-2** (8:14) A pet following the player down a corridor. The pet (orange raptor) is about 1.0-1.3x avatar height, walks right behind with a shadow under it; torches, palms and water frame the lane. Notice: the pet is the warmest colour on screen against cool blue-grey walls.
3. **ref-3** (how-to video 8:36) Egg "Ready!" in the pen. A big stepped violet egg (about 2x avatar), tag "Egg", bold white "Ready!", an "E / Hatch!" prompt at its base, one glowing square rune as accent. Notice: tag and prompt are 3 lines of white text; the model itself carries the rarity colour.
4. **ref-4** (mounts video 9:50) Spirit World Guardian: a rideable creature with cyan glow, name tag plus red "[F] Dismount" button, a purple armoured creature with gold bands on the left, and a "Steal" prompt over the eggs. Notice: rare pieces have additive glow and sparkle, common ones do not.
5. **ref-5** (forest video 11:40) Collectibles: emerald and sapphire butterflies at about 0.5-1x avatar wingspan, additive glow, neon blue/pink on dark green ground, toast bottom-centre "Caught an Emerald Butterfly! (16 owned)". Notice: collectible colour is brighter than all terrain and glows.

## Ours must...
1. One look for all world pieces: studs on every large model (bump about 0.25 stud, roughly 8 per 5-stud cube); no smooth plastic next to studded bricks. Pets may stay rounded only if they obey rules 2 and 4.
2. Colour budget per model: 2-3 flat base colours plus ONE neon accent (eyes, rune, core). Rarity by accent and glow: common none, rare cyan, epic purple, legendary gold, mythic rainbow shimmer.
3. Scale ladder (avatar = 1.0): small pumpkin 0.3, big pumpkin 0.8, pet following 0.6-1.0, nest egg 1.0-1.5, pen egg grows to 2, guard 1.5-3, boss 6+. Check each model against the avatar in the same screenshot.
4. Faces: two black square eyes with 1 white highlight, no mouth except a teeth row on aggressive guards; guards get glowing eyes in 1 neon colour.
5. Pets idle with a 0.3-0.5 stud bob every 1.2 s, follow 3-4 studs behind, never clip into the avatar, blob shadow under each.
6. Every interactable carries a 3-line stack: name (bold white, thick stroke), state ("Ready!", "54s"), action prompt in a key circle ("E Hatch"). Readable at 30 studs (22 px or more on 1080p).
7. Guards sleep with 2-3 blue "Z" letters above (0.6-1 stud tall, light cyan to royal blue) and a wake tell (eyes go neon, 0.5 s roar).
8. Collectibles (candy, pumpkins, bats) are the brightest colour in the scene, have additive glow, bob in a 1-2 s loop; pickup toast plus +1 count text bottom-centre.
9. The scythe is the hero prop: blade colour = tier colour, held at about 0.8x avatar height, 0.2 s swing arc trail in tier colour.
10. Silhouette test: at 10% scale in flat grey you can still tell King, pet, egg, nest and pumpkin apart.

## Ours today (honest)
- Pets (art\pets-15.jpg) are smooth chibi meshes: cute, readable, good colour spread, but they do not match the studded purple/green world or any brick style around them.
- The scythe (scythe-s1-hold.jpg, r3-farm.jpg) is an orange blocky slab, one colour, no trail; pumpkins in the farm are low-detail orange blobs and the white one is a flat ellipse.
- Nests/guards in r3-zone1-plan.jpg are tiny tan block stacks and a tiny pumpkin sign: no sleeping guard, no big egg, no neon accent, nothing taller than the avatar.
- Style fork for Zion: keep chibi pets (PS99 look) or move everything to studded bricks (SAE look). Recommendation: studded for guards, boss, props, eggs; chibi pets allowed only with rules 2 and 4.

## Assets needed
- **Guard/enemy and boss model pack (big animals, golems, pumpkin giants)**: Creator Store "voxel monster", "halloween creature model", "brick animal pack".
- **Pet pack (10-15 Halloween pets with idle/walk)**: "halloween pets", "cute ghost pet", "chibi bat pet", "pet follow script".
- **Egg and nest set (stepped eggs, glass dome, nest rim, rune glow)**: "monster egg", "egg nest", "easter egg model low poly".
- **Props pack (fences, graveyard, hay, lanterns, tombstones, pumpkins)**: "halloween props pack", "graveyard kit", "pumpkin patch props", "spooky fence".
- **Tools and collectibles (scythe tiers, candy, bats, loot beams)**: "scythe model", "candy corn model", "floating collectible glow", "tool trail effect".
- **Name tag and animation kit (billboard name/state/prompt, idle loops)**: "billboard gui name tag", "pet idle animation", "proximity prompt style".
