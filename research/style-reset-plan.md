# Swarm Break style reset (2026-10-03, after Zion's playtest of 087839f)
Zion's verdict: no style, weak models, few animations, old and badly sized UI, small and boring map, a boss that isn't cinematic, aggressive feel, levelling speed off, janky recoil shake, a floating gate, and a stalled round.
The goal is still to beat Hunty Zombie, Final Swarm and Survive the Swarm.

## Already fixed (475b4d5, 382 tests)
- **Stalled round with 2 invisible enemies.** Enemies destroyed without dying stayed in the alive count. EnemyWatchdog now drops them, kills enemies that fell or escaped the map, and moves stuck chasers back to a portal.
- **Floating gate.** The boss gate model was pivoted about 10 studs up. Arena assets now centre their bounding box on the target.
- **Janky recoil shake.** Auto-fire shook the camera on every shot and every hit. Both are gone. Kills, crits and bosses still shake, and the recoil kick is halved.

## Why it still has "no style"
1. **There's no art bible.** Each wave picked colours and shapes on its own, so the look is a patchwork.
2. **The models are scripted blockouts** (Blender scripts and part rigs). The reference games use hand-made or store models with real silhouettes.
3. **Animation is procedural code only.** There are no authored clips for player combat, enemy attacks, deaths or evolutions.
4. **The UI is built in code from default buttons,** with no design system, scale rules or custom font treatment.

## Plan: wave S (style first). Codex builds, Claude judges against footage before Zion sees it
- **S0 Art bible** (Claude, first). Palette, shape language, materials, UI kit, animation timing and reference frames for each of the 3 games. Every later task cites it.
- **S1 UI redesign.** A UiKit 2.0 with chunky rounded panels, a bold display font, gradients and strokes, and icon badges. One UIScale rule sized to the viewport. Redo the HUD, cards, summary and lobby boards with it. Spec: nothing overlaps or gets clipped at phone, 1366 and 1920 sizes.
- **S2 Animation pass.** Player fire, a 3-hit melee combo, dash and hit-react. Enemy attack wind-up, hit flinch and death (a goo pop, not a ragdoll). An evolution cinematic: slow-mo, camera push-in, element burst, weapon morph. Built as authored clips if Zion picks the store route (Q5), otherwise procedural Motor6D curves.
- **S3 Bigger map with parkour.** About 3x the play area, in 3 zones with landmarks. Ramps, ledges, jump pads, dash gaps and a high loop route. Enemies still path through the middle. The boss arena sits at the far end.
- **S4 Cinematic boss.** An intro cut, 2 phases with telegraphed attacks, an arena event in phase 2 (floor hazards, adds from the gate) and a slow-mo kill cam with a loot shower. Then V5's extraction.
- **S5 Balance and levelling.** A pure run simulator spec covering:
  - Levels every 12-20 s for the first 2 minutes, slowing after that.
  - Contact damage and the number of attackers capped, so it stops feeling aggressive.
  - A time-to-kill target per weapon.
- **S6 Models.** Depends on Q2: a new enemy set, the player weapons and props.
- **Order** (Iris max_parallel 1): S0 → S5 (cheap, data only) → S1 → S2 → S3 → S4 → S6 → V4 crowd → V5 extraction.
  - V4 waits until after S5, because more enemies would feel even more aggressive.
- **Before Zion sees anything:** the Play thread captures the shot list on each build, and Claude judges it. Zion is flagged only when a build beats the last one visibly.

## Creative decisions for Zion (one word each, recommendation marked)
1. **Art style:** Cartoon (Hunty-like chunky stylized, RECOMMENDED) / Pastel (Survive the Swarm candy) / Neon (dark sci-fi glow).
2. **Models:** Store (Creator Store models plus our own recolours) / Blender (keep making our own) / Mix (store base meshes for enemies and props, our own for bosses and weapons; RECOMMENDED). The earlier rule was "make our own in Blender". Three rounds of that came out weak.
3. **Enemies:** Bugs (keep the Nest and hive, RECOMMENDED, which sets us apart from the zombie games) / Zombies / Robots.
4. **Map:** One (one big arena with zones and parkour, RECOMMENDED first) / Biomes (several smaller maps).
5. **Animations:** Store (free Creator Store animation packs plus custom clips, RECOMMENDED) / Code (procedural only).
