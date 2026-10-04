# Swarm Break game bible v2 (2026-10-04, after Zion's "still at the drawing board")
This replaces earlier briefs wherever they conflict. Research behind it: r5-drawing-board.md.

## What Zion has asked for (every standing ask in one place)
- **Bar:** better than Hunty Zombie (lead reference), Final Swarm (auto-aim) and Survive the Swarm. Front-page quality, judged against those games every round.
- **Look:**
  - Real models with detail, not bland or primitive.
  - Style, colour theory, good UI, world building.
  - Bigger enemies.
  - Weapon models and animations.
  - No blood: goo is teal or green.
- **Feel:**
  - Killing enemies is really satisfying.
  - Effects are smooth and never shaky.
  - The glow is never blinding.
  - Recoil and shake are subtle.
  - The gameplay isn't too aggressive.
  - Auto-aim.
  - Upgrades that work.
  - Evolutions with animations.
- **Structure:**
  - A campaign of maps. Each map has 15 waves and 3 difficulties, and beating one unlocks the next.
  - Each map has its own island layout, its own story beat and its own enemy family. Families can return on later maps.
  - Zones ("rooms") open during a run. Parkour and dash spots.
  - The boss fight is cinematic.
- **Names and prices:** plain names, all prices 0, lobby first, co-op with friends.

## Constants (every map, every family)
- **Roles:** 5 enemy roles (Swarmer, Runner, Shooter, Tank, Flyer), plus Elites and a boss. Each role has a fixed silhouette rule and size band.
- **Signals:** pink means an attack is coming, teal means goo, and gold means loot.
- **Kill feel:** every kill plays the same layered beat:
  1. hit flash
  2. 40-80 ms hitstop
  3. knockback
  4. goo sprite burst
  5. splat decal
  6. gem pop with magnet pull
  7. 3-layer pitched sound
  8. number pop

## Look rules
- **No Neon on anything bigger than an eye or a light strip.** Glow comes from soft additive sprite particles and small PointLights.
- **Bloom:** intensity ≤ 0.5, threshold ≥ 1.5.
- **Textured, not vertex-coloured:**
  - Every mesh has a painted gradient ColorMap with baked AO.
  - One trim-sheet atlas per map.
  - Enemies are darker than the floor, with 2-3 colour zones.
- **Map detail:** a prop about every 6-10 studs (non-colliding), decals, foliage or debris, background islands, mist, ambient particles, one landmark visible from spawn. Each map has its own sky and colour grade.
- **Effects run on the client only:**
  - Pooled and driven on RenderStepped.
  - Quad or exponential easing, never linear.
  - Texture flipbooks (spark, smoke, slash, ring, goo, soft glow) instead of moving parts.
- **Animation minimum per enemy:** idle, move, telegraphed attack, hit react, a death unique to its role, and a spawn-in. Springy, with anticipation and overshoot.

## Order of work (one great slice first)
1. **L1 look and feel pass** (Codex, code only, works with any models): see codex-wave20-L1.md.
2. **Art source.** Zion picks between store packs and our own models on the open card.
   - **Store:** the Play thread finds candidates, I pick them, Codex wires them in.
   - **Own:** Blender with textured gradient maps and AO, judged against store-quality references.
3. **The first 3 minutes of Outpost 9 (Landing Pad, waves 1-3)** made great and captured on video. Zion is shown it only when it beats Hunty Zombie on the shot list.
4. **Then:** S3 zones, the S4 boss, more maps.

## Zion 10/04 03:11Z: model bar
"Our models should be good and professional, our game should feel unique, with good quality and animation, with optimization of the game in mind."

**Rules for our own models (weapons, bosses):**
- **Look:** textured gradient ColorMap with baked AO, a readable silhouette, and a unique shape language. The Nest motif shows on every model: chitin plates, goo-glass cores, orange outpost hardware.
- **Animation:** every model ships with idle, attack and hit animations.
- **Judging:** a model is shown to Zion only after it scores "matches or beats" against Hunty Zombie in a side-by-side render.

**Restyling store packs:**
- Repaint every store pack to our palette.
- Add our motif pieces.
- Never ship a pack as it comes.

**Optimization budgets:**

| Item | Triangle budget |
|---|---|
| Swarm enemy | ≤ 2.5k |
| Elite | ≤ 6k |
| Boss | ≤ 15k |
| Weapon | ≤ 3k |
| Prop | ≤ 1.5k |

- One 1024 texture atlas per map.
- No more than 60 live enemies, using pooled models and animation culling (AnimCull) beyond 120 studs.
- Effects come from pooled particles, with no per-hit Instance.new.
- The target is 60 fps on a mid phone. Performance is checked in every capture through the Studio MicroProfiler stats from the Play thread.
