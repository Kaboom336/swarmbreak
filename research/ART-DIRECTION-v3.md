# Art direction v3: from render gallery to front-page look (2026-10-02)
Inputs: research/r4-ai-build.md, r4-build-craft.md, r4-genre-feel.md, import-plan.md, VIDEO-NOTES-2026-10-02.md,
game/tools/blender/RECIPE.md, renders enemies-sheet.png, weapons-sheet.png, arena/Lineup.png (+ refs-sheet, before-after-walker).
Tags: [V] verified in a cited doc, [E] estimate or taste, [PRIOR] memory of a game, not checked this run.

## 0. REVISION 2026-10-02 01:20Z after the laptop's captures of 8 top games (overrides sections 2 and 4 where they differ)
CAVEAT (Zion 01:22Z): the source videos are edited YouTube clips (cuts, zoom, effects, overlays), so the stills show highlights, not normal play. Use them for direction only, and check timings and density against unedited play or our own playtest.
Evidence: /mnt/project-files/swarmbreak-reference-overview.jpg and swarmbreak-reference-notes.md (40 stills from YouTube gameplay).
- None of the 8 games uses detailed models. Rivals is white blocks, Grow a Garden is default studs, Final Swarm is plain low-poly in daylight. They win on bright, readable light, a dense HUD and hit feedback on every shot.
- So the look becomes a **bright station at dusk**: strong warm key light and a blue sky, with neon trim as an accent, not darkness. Only Doors (horror) is dark, and we are not horror. The floor still has to be lighter than the enemies.
- Recent-games pass (10/2 01:44Z, swarmbreak-reference-notes-v3.md): arenas follow Hunty Zombie (bright, stylized, simple models, big VFX); Nest and boss interiors follow Pressure (dark, but lit by visible coloured sources). Frontlines (realistic) is not our lane.
- New priority order: (1) lighting and post (T1), (2) the Final Swarm HUD set (T6), (3) hit, kill and AoE juice (T2, T3), (4) mesh upload (wave 8), (5) mesh fidelity. Art steps 3 to 6 in section 4a (re-facet, atlas, SurfaceAppearance, bosses) move behind the in-engine screenshots and happen only if those show the meshes are the weak spot.

## 1. Honest diagnosis: why we are not front-page
0. **Nobody has seen our art in Roblox.** Zion's playtest showed grey part-built placeholders under the default night sky,
   because `Shared/Meshes.luau` has no ids and lighting/post-FX exist only at runtime (import-plan.md causes 1-3). Every
   score so far judged Blender Eevee renders with bloom, baked AO and a soft studio light. Roblox reproduces none of that
   for free. Until step A/B of import-plan.md lands, "how good does it look" has no answer.
1. **enemies-sheet.png is the weakest sheet.** (a) The render hides problems: a big white floor hotspot beside each model
   is the brightest thing in frame, so the eye goes to the floor. (b) Value: every body is near-black chitin (BODY) with
   small accent patches; on our dark floor (Theme.Floor 40,42,50) that is a black blob at gameplay distance, breaking the
   RECIPE rule "floor lighter than enemy bodies". (c) Facet noise: 3.7k-7.4k tris (Warden 7426, Queen 6843) vs 100-1500
   on refs-sheet.png; small facets read as crumpled foil, not as shape (PLAYBOOK 2026-09-30 lesson, still not applied).
   (d) Box glyphs: Walker's orange jaw, Spitter's purple jaw-slab and Brute's red fist are untapered boxes stuck on a
   faceted body; they read as placeholder parts. (e) Accents cover too little area except Queen (egg sacs) and Tank
   (shell). Best reads: Warden (one giant eye), Flyer (wasp stripes), Tank (dome + horn). Runner and Spitter are noise.
2. **weapons-sheet.png is close to the bar.** Chunky two-tone, layered glow, clear shapes (Sun Orbs, Shock Hammer,
   Heavy Cannon, Spinning Blades are good). Gaps: hue collisions (Laser Rifle, Triple Rocket, Energy Sword, Lightning Orbs
   all purple/magenta, so purple no longer means Epic); muzzles smaller than receivers on Laser Beam, Sniper, Starter
   Pistol against the "muzzle as big as receiver" rule; shared gunmetal makes rarity unreadable.
3. **arena/Lineup.png is our best image and our biggest trap.** Teal seams, amber hazard stripes, purple Nest glow: this is
   the look. But it depends on Eevee soft shadows, AO in crevices, volumetric bloom and a close 3/4 camera. In Roblox, with
   vertex colours or flat Color and default normals, it will be flatter; the enemies in it are lit by the Nest, not by the
   game's lights. Treat Lineup.png as the target screenshot, not as proof.
4. **Feel gap, not just model gap.** VIDEO-NOTES: the Duels team wins with simple art plus strong UI/juice (damage numbers,
   kill burst, timer with portraits). Our HUD (Hud.client.luau, 1414 lines) has no shared UI kit and our VFX are ad hoc.

## 2. Target look
**"Neon station at night, readable at a glance."** Dark steel arena with a mid-value floor (lighter than any enemy body),
teal player-side light, amber hazard trim, and a purple swarm whose glowing weak points (eyes, sacs, cores) are the
brightest thing on screen after player projectiles. Few big facets (1-3k tris per enemy), one saturated accent covering
30-40% of each enemy, bone-white spikes, one emissive glyph per type. Lighting is Future + Atmosphere + a tuned trio of
Bloom / ColorCorrection / Sky saved in the place file. Juice carries the "pro" feel: 3-layer hits, crystal-burst deaths,
build-in spawns, chunky outlined UI. Phone first: it must read at 1334x750 on Graphics Quality 1.
References (characterisations are [PRIOR], verify by watching footage):
- **Deep Rock Galactic** (off-platform): faceted low-poly bugs in dark caves, glowing weak points, flare-lit readability.
  The closest match to our enemy and lighting language.
- **RIVALS** (Nosniy Games): clean, bright competitive readability; hitmarkers, kill feed, minimal HUD.
- **Tower Defense Simulator**: swarm readable from above by silhouette and colour code; money pop on kill.

## 3. Pipeline decision
| Layer | Tool | Why |
|---|---|---|
| Enemy + weapon meshes, arena modular kit | **Stays Blender-by-script** (enemies2.py, sb2.py) | Rig part names (Motor6D, EnemyAnimator) need control no generator gives. Change: lower tri budget, wedge not box glyphs, game-camera render as judge image. |
| Regular enemy + weapon colour | **Palette-atlas texture** (one small albedo, AO baked in, UV 0:1, MeshPart.TextureID) | What we see in Blender must survive import; vertex-colour import is [unverified], a baked texture is not. One material per mesh [V spec]. |
| Arena floor/wall/grate, bosses (Queen, Warden, Brute), Legendary weapons | **SurfaceAppearance** (albedo, normal, roughness, emissive mask; 512 arena tiles, 1024 bosses) [V size guide] | Pays where the camera lingers. Material Generator may supply floor variants [V exists]. |
| All glow, light, atmosphere, particles, beams, trails, hit flash, UI | **Roblox-native, Codex Luau** | Bloom/Neon/LightEmission do glow better than baked emissive; must be tuned in-engine anyway. |
| AI 3D generator (Cube / Meshy / Tripo) | **One time-boxed trial, no adoption yet** | Trial A: 3 static arena props. Trial B: a static Queen showpiece vs our Blender Queen. Keep only if it passes the same in-engine screenshot gate, fits 3k tris, and (for B) can be split into rig parts in under an hour. Never for rigged regular enemies. |

## 4a. Art pass plan (Claude, in order; each step ends with LOOKING at the PNG)
1. **Judge image fix:** add `render_gamecam` to a new `game/tools/blender/gamecam.py` (do not edit sb2.py): camera at
   gameplay distance (~40 studs, 50-60 deg down [E]), on the arena floor colour, no hotspot, plus a greyscale copy and a
   64 px silhouette. Output `assets/renders/gamecam/<Name>.png` and `gamecam-sheet.png`. All judges use this sheet.
2. **Value pass:** lift floor value (Theme.Floor toward ~70-80 grey [E]) in the arena kit and Theme together; raise enemy
   SHELL value; accent coverage to 30-40%. Pass = greyscale sheet shows every enemy darker or lighter than floor, never equal.
3. **Re-facet enemies:** total 1.5-3k tris (regular), <=5k (bosses); replace box jaws/fists on Walker, Spitter, Brute with
   `sb2.wedge` taper 0.5; redo Runner and Spitter glyphs (Runner: long lantern tail; Spitter: swollen acid sac on back [E]).
4. **Atlas bake:** new `game/tools/blender/atlas.py`: UV-project each part onto a 64x64 palette strip, bake AO into it,
   export with TextureID path; manifest.json gains `texture` per part.
5. **Arena SurfaceAppearance set:** FloorTile, Wall, FloorGrate, Pillar: 512 maps, emissive mask on seams.
6. **Bosses:** Queen, Warden, Brute 1024 SurfaceAppearance; emissive weak point that VFX can pulse.
7. **Weapons:** re-hue to one rarity ladder (grey/blue/purple/gold) and element glow (4 hues); enlarge muzzles on Laser
   Beam, Sniper, Starter Pistol; render hotbar icons 3/4 on rarity disc.
8. **VFX textures:** 256 px additive PNGs: spark, streak, ring, soft puff, crystal shard, hex dissolve, flipbook 4x4 burst.
9. **Thumbnails + icon:** hero + swarm + boss, 0-3 words, judged at 128 px; 3-5 variants for bandit tests.

## 4b. Codex Luau tasks (bounded: files, failing test first; testcmd `stylua --check src && selene src && lune run tests/run.luau`)
- **X1 ModelLibrary (import-plan B).** Files: `ServerStorage/ModelLibrary.luau`, `Shared/ModelAssets.luau`, EnemyBuilder,
  WeaponModels, ArenaBuilder. Test `tests/modelassets.spec.luau`: every manifest.json key present; ids are numbers; a pure
  `ModelAssets.missing()` lists ids == 0 so boot logs a loud warning.
- **X2 Lighting presets.** Files: `Shared/LightingPresets.luau` (pure data: Station, BossFight, Base, LowQuality: Lighting
  props, Atmosphere, Bloom, ColorCorrection, Sky tint), apply in ArenaBuilder + BossIntro, and the same values baked into
  `default.project.json` Lighting (import-plan C). Test `tests/lightingpresets.spec.luau`: all keys in every preset;
  Atmosphere.Color within a hue delta of Sky tint; Bloom.Threshold >= 0.8 so only Neon blooms [E]; floor luminance
  (Theme) > every Theme.Enemy Body luminance; project.json Lighting equals preset Station.
- **X3 VFX library.** Files: `Shared/VfxDefs.luau` (data: HitSpark, MuzzleFlash, DeathBurst, SpawnBuildIn, Telegraph,
  PickupMagnet, BossWeakPoint) and `StarterPlayerScripts/ClientFX.luau` (pooled emitters, `Emit(n)`). Test
  `tests/vfxdefs.spec.luau`: every Transparency sequence starts and ends at 1 [V fade rule]; Rate <= 100 [V mobile cap];
  summed worst-case emits per second under a budget; enemy telegraph colours warm and never a player hue (RECIPE rule).
- **X4 Hit and kill feedback.** Files: HitMarkers.client.luau, Effects.client.luau, `Shared/Feel.luau`. Hit = spark +
  white flash 0.06 s [E] + sound + damage number; crit variant; kill = DeathBurst + coin flying to counter. Extend
  `tests/feel.spec.luau`: flash and number timings in range, crit scale > normal, every enemy type has a DeathBurst colour.
- **X5 UI kit.** Files: `Shared/UiTheme.luau` (font, stroke, corner, gradients, rarity colours, sizes) and
  `StarterPlayerScripts/UiKit.luau` (Panel, Button with 1.05/0.95 press tween, Counter count-up, Banner, Portrait), then
  migrate Hud.client.luau screens one by one. Test `tests/uitheme.spec.luau`: text/stroke contrast >= 4.5:1; rarity colours
  equal Theme.Rarity; touch targets >= 44 px at 1334x750 [E]; no tweened stroke Thickness on text [V].
- **X6 Edit-mode arena.** Files: `default.project.json`, `Workspace/Arena/*`, `Shared/ArenaLayout.luau`. Place the static
  v2 kit from layout data so Edit mode matches Play. Test: extend `tests/arenalayout.spec.luau` (every prop key in the
  manifest, no overlaps, all inside walls).
- **X7 Capture script.** File: `game/tools/capture.luau` (Studio command bar / MCP): sets 6 fixed cameras and the preset,
  waits, screenshots. No unit test; acceptance = the 6 PNGs in section 5 exist.

## 5. What the laptop captures must verify (post to assets/renders/ingame/, judged against Lineup.png)
1. Zero placeholders: ModelLibrary boot log reports 0 fallbacks; every enemy/weapon/prop is the uploaded mesh.
2. Edit mode and Play mode screenshots of the same camera look the same (lighting saved in the file).
3. Flat facets survived import (no smoothed normals) and atlas/SurfaceAppearance colours match the Blender render.
4. Gameplay camera, wave 3, 20+ enemies: each type nameable at distance; greyscale copy shows floor vs enemy value split.
5. Glow: eyes/cores/Neon bloom without blowing to white; still read at Graphics Quality 1 (where Bloom is weak).
6. Phone emulator 1334x750: HUD readable, buttons tappable, no text under 14 px.
7. Boss intro (Queen): weak point visible, telegraph warm, player shots cool.
8. Perf: FPS and particle count with 30 enemies + full VFX on the phone emulator; log MicroProfiler frame time.
9. One 15-second clip of hit, kill, spawn build-in: the "juice" check from VIDEO-NOTES.
