# map-world TARGET (hub + zone look, layout, landmarks, lighting)

## Chosen game and why
**Steal an Egg (Sept 2026 build, 12 lane sections).** It is the only top game whose map IS the mechanic: one straight walled lane, a hub with fenced plots at the mouth, and every zone re-skinned so the player knows "where am I and how dangerous is it" at a glance. Our identity (steal from guarded nests, walking boss) maps 1:1 onto it. We copy the structure, not the art: our palette is Halloween (purple/orange/black), not lime and terracotta.

Sources (YouTube, 854x480 upscaled to 1280): R = "I Started Over With EVERY EGG" JS0aO66-ixo (uploaded 2026-09-20). H = "I Spent 100 Days in STEAL AN EGG" 0sqILTHsdU8 (uploaded 2026-09-23). Full detail already lives in `refs\aspects\map\REFERENCES.md`; this folder is the 5-frame digest.

## Frames (what to notice)
1. **ref-1** (H 0:18, hub looking out): three landmarks readable at once, each with a giant floating word (SELL, THE RIFT, TRAILS SHOP) and each a different silhouette and colour. A purple crystal on a dark pool is the one tall "look at me" prop. Floor is flat, saturated and studded; walls are plain; a beam of light rises from the far end of the lane.
2. **ref-2** (H 24:20, aerial from the first zone back to the hub): the hub is about twice as wide as the lane, plots stick out both sides of the lane mouth, and the lane narrows into a corridor. A giant purple pet towers over the fences and acts as the skyline.
3. **ref-3** (R 8:02, Snow zone): a zone change = floor colour + wall colour + prop set swap in one section (white floor, ice props, pink-tinted wall), no door, no loading. Big RUN!! alert in the HUD.
4. **ref-4** (R 4:56, Jungle): zone title appears as a big white word plus a coloured HUD line with an emoji. Floor goes a darker green checker, palms appear on the horizon. Walls stay in the same family so the lane still reads as one place.
5. **ref-5** (H 17:12, Cosmic): the most extreme zone: black floor with neon grid, star sky, torii gate at the far end, a bright guide line down the middle. Shows how far a zone can swing in mood while staying on the same lane.

## Ours must...
1. Hub is a flat open plaza at least 2x the lane width (ours 248 x 160 studs against a lane about 120 wide); nothing taller than 6 studs blocks the line of sight from spawn to the lane mouth, except the one hero landmark.
2. Exactly one hero landmark visible from spawn within 2 s (Pumpkin King, 40+ studs tall) plus at least 3 secondary landmarks (Sell, Shop, Index/Fuse), each with a word sign at least 6 studs tall in a unique colour.
3. Landmark silhouettes read at 150+ studs away on a phone-size screen (test at 640 px wide); each one differs by shape AND hue.
4. Lane is straight and walled on both sides, 120 studs wide, walls at least 25 studs high with a 1-stud bright cap line (neon orange or violet) so it reads as a corridor from the sky.
5. Zones follow each other with no door and no load: 4 zones at launch, each 160-200 studs long, each with its own floor colour, wall colour and 5+ unique props. Neighbouring floors differ by at least 40 degrees of hue or 30% lightness.
6. Zone name appears as a HUD line with emoji plus a one-time 1.5 s big word on entry, in the zone's accent colour.
7. Palette discipline: one dominant base (deep purple #3B2350 family), one hero accent (pumpkin orange #FF8A1A), one glow colour (sickly yellow-green or violet) for things that matter; at most 3 hues on screen outside zone-specific props.
8. Lighting: dusk. ClockTime 17.5-18.5 in the hub, Future lighting, Atmosphere density 0.35+ with purple haze, ColorCorrection contrast +0.1 and saturation +0.15, Bloom 0.4-0.6, SunRays low. Every lantern, pumpkin face and pool carries a PointLight or Neon so the hub glows against a darker sky.
9. One distinct night-pulse moment every 3-5 min (sky darkens, ground stays lit, a toast announces the Pumpkin King waking), like the reference's night phase.
10. Zone entries use a wooden "recommended power" sign on a post instead of a hard wall; nothing blocks the player in the first 3 min.
11. Part budget: hub under 6k parts, each zone under 3k; no free-standing prop smaller than 1.5 studs unless it is a collectible.

## Ours today (honest)
- Hub (hub-v5-palette.jpg): the Pumpkin King statue works as a landmark, but the sky is default bright Roblox blue, the grass is flat studded green and the paths are pale pink/white; it reads as a prototype, not Halloween.
- Zone plan (r3-zone1-plan.jpg): a long corridor with lavender and tan walls and a checker floor; zones differ by colour only, there are no zone landmarks, and the horizon is a flat lavender void.
- Lighting is essentially untouched (no Atmosphere haze, no glow; lantern posts are the only warm light); the Halloween mood lives in the purple walls only.

## Assets needed (Creator Store, free, no-script; do not insert yet)
| Need | Search terms |
|---|---|
| Hero landmark pieces (haunted house, gate arch, giant tree, crypt for the Sell/Shop/Index stations) | "haunted house low poly", "halloween gate arch", "spooky dead tree" |
| Zone prop packs (graveyard, pumpkin patch, witch swamp, bone/ice zone) | "graveyard pack low poly", "halloween props pack", "swamp mushrooms stylized", "tombstone set" |
| Lighting and skies (dusk skybox, moon, fog, purple haze) | "halloween skybox", "spooky night sky", "purple atmosphere sky" |
| Lanterns, candles, torches (glow carriers) | "jack o lantern glow", "halloween lamp post", "candle cluster" |
| Floor and wall materials (dark soil, cobblestone, purple brick) | "cobblestone path texture", "dark grass texture", "halloween ground material" |
| Hub plot dressing (fence, skeleton signs, hay, crates) | "wooden fence halloween", "scarecrow low poly", "hay bale", "wooden sign post" |
