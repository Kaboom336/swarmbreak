# r4: How front-page Roblox games are built visually (craft rules for Swarm Break)
Date 2026-10-02. Method: ~16 tool calls; 5 WebSearch (snippets are titles only, so little evidence), 6 WebFetch on already-used domains (create.roblox.com, devforum.roblox.com). Marked: [V]=verified at URL, [E]=estimate/convention from general knowledge, NOT verified here.
Builds on: COMPARISON.md r2-r3, research/import-plan.md (root cause: models never uploaded; Edit mode shows only static floor/walls; post FX only at runtime), VIDEO-NOTES-2026-10-02.md ("UI and juice matter more than model detail"; @laststandinteractive Duels = low-poly bright desert + chunky pixel font + saturated colours).

## Honest gap
Searches returned no per-game art breakdowns (Rivals, Blox Fruits, Doors, Pet Simulator, Grow a Garden): no devlog evidence found. Game-specific claims below are [E] and must not be quoted as fact. Seen in our own notes: Duels video (VIDEO-NOTES). Search hits for Rivals/Doors were wiki pages only.

## Evidence base [V]
- Mesh limit 20,000 tris per mesh; watertight, quads preferred, no n-gons, no zero-thickness. https://create.roblox.com/docs/art/modeling/specifications
- Texture: max 4096x4096 supported; guide 256px for ~5x5 stud object, 512 for 10x10, 1024 for 20x20. SurfaceAppearance maps: Albedo RGB, Normal RGB (OpenGL), Roughness/Metalness/Emissive-mask 8-bit grey. One material per mesh, single UV set within 0:1. https://create.roblox.com/docs/art/modeling/texture-specifications
- Future-lighting tutorial values: LightingStyle Realistic, EnvironmentDiffuseScale 1, EnvironmentSpecularScale 1, ClockTime 17, Ambient/OutdoorAmbient (156,136,176), Atmosphere Density 0.272 Haze 1 Color (85,78,54); campfire PointLight Range 48 Brightness 2 Color (255,179,73) Shadows on. https://create.roblox.com/docs/tutorials/use-case-tutorials/lighting/enhance-outdoor-environments-with-future-lighting (tutorial gave no Bloom/CC/SunRays numbers)
- Particles: LightEmission 0..1 (1 = additive glow); Rate cap 400/s (100/s mobile); fade in/out via Transparency sequence to avoid popping; large particles cost fill-rate; check at min and max Editor Quality. https://create.roblox.com/docs/effects/particle-emitters
- Muzzle flash on DevForum: bright, very short Lifetime, tinted, size NumberSequence growing slightly, fire with `Emitter:Emit(1)`; beams plus spark particles as alternative. https://devforum.roblox.com/t/help-getting-a-good-muzzle-flash/1917951
- UIStroke: Thickness, ApplyStrokeMode (Contextual=text outline, Border=frame), LineJoinMode Round/Bevel/Miter, can take a child UIGradient; do NOT tween Thickness on text (perf). UIGradient Type Linear/Radial/Conical, Rotation, Offset. UICorner scale >=0.5 = pill. https://create.roblox.com/docs/ui/appearance-modifiers

## Craft checklist (18 rules)
GEOMETRY / MATERIALS
1. Ship uploaded MeshParts, never placeholders: nothing else matters until import-plan step A/B is done. Add a boot-time check that logs/warns when any ModelAssets id is 0 so a placeholder build cannot go to playtest silently. [V basis: import-plan.md]
2. Budget enemies low: aim well under the 20k cap [V]; our target of roughly 500-3000 tris per enemy, since 20+ are on screen at once, is [E].
3. Use a flat-colour/palette-atlas look first: one small albedo (palette strip) per model, UVs inside 0:1, one material per mesh [V spec]. Cheapest route to "stylized, cohesive"; PBR painting is optional polish [E].
4. Use SurfaceAppearance only where it pays (hero weapon, boss, key props). 256/512 textures for small things per the doc's size guide [V]; keep roughness mid-high so Future lighting gives soft highlights not mirrors [E].
5. Emissive for glow: put eyes, cores, crystals on the Emissive map or Neon parts (we already set `_Glow` to Neon) so Bloom catches them; this is the single biggest "reads as pro" cue in dark arenas [E].
6. Build the arena from a small kit of modular meshes plus Terrain/large parts, with decoration clusters (rocks, crates, lamps) placed by rule, not scattered uniformly [E]. Persist a static pass in Edit mode so owner sees it without pressing F5 (import-plan cause #2) [V basis].

LIGHTING / ATMOSPHERE
7. Use Future lighting with LightingStyle Realistic; start from the doc's values (Diffuse/Specular scale 1, Atmosphere Density ~0.27, Haze 1) and tune [V]. Set it in the saved place file, not only at runtime, so Edit mode matches Play.
8. Pick a value hierarchy: floor mid-dark, enemies lighter/more saturated than floor, pickups and projectiles brightest (also r2-look.md rim/outline note). Check on a greyscale screenshot [E].
9. Coloured local lights, few: warm PointLight on key props (doc used Range 48, Brightness 2, warm orange [V]), shadows only on a handful; no per-enemy PointLight (COMPARISON item 6 already flags the cost) [E].
10. Post-processing trio: Bloom (low threshold only for neon), ColorCorrection (slight saturation + contrast lift), mild SunRays; the doc gives no numbers [V gap], so tune by eye against 3 reference screenshots and record final values in this repo [E].
11. Replace default night sky with a deliberate Skybox/Sky (stars + tint matching Atmosphere Color) so horizon fog and sky agree; mismatched fog vs sky is the classic amateur tell [E].

VFX
12. Every hit gets 3 layers: spark burst (Emit N, LightEmission 1), brief flash, and a sound; muzzle flash = bright, very short lifetime, size grows slightly, fired via Emit(1) [V DevForum].
13. Fade every particle (Transparency sequence start and end) and keep Rate low, vary size/transparency instead [V]. Keep total emitters on screen bounded for mobile (100/s cap) [V].
14. Trails/Beams for bullets, dash and boss attacks; beam + spark pairing suggested on DevForum [V]. Use additive textures with soft round/streak PNGs, not default squares [E].
15. Spawn/death "build-in" and dissolve effects (parts assemble with glow and dust; no blood, crystal burst on death) [V basis: VIDEO-NOTES A/B]; tween Size/Transparency with Quad/Back easing [E].

UI
16. Chunky display font, white fill, dark UIStroke (Contextual, Round join) on all text; set stroke once, never tween text-stroke Thickness [V]. Specific font pick (e.g. Luckiest Guy / FredokaOne / GothamBlack) is [E]; verify availability in Enum.Font first.
17. Panels: UICorner + vertical UIGradient + Border-mode UIStroke gives the "chunky candy" look; one accent colour per resource (gold, gem, health) used consistently [V props, E style].
18. Button juice: hover/press scale tween (about 1.05 / 0.95, est.), click sound, number count-up on rewards, popped damage numbers, kill feed; matches Duels video features [V basis: VIDEO-NOTES A].

## Games/creators to study (unverified; need real devlogs)
Rivals (Nosniy Games), Blox Fruits, Doors (LSPLASH), Pet Simulator / Grow a Garden UI packs (https://adrianart.itch.io/gag-ui-pack seen in r2-look.md), Duels devlog by @laststandinteractive (VIDEO-NOTES). Characterisations of their lighting/UI are [E] only.

## Must-read later (unread)
- https://create.roblox.com/docs/environment/lighting (fetch parked on permission prompt)
- https://create.roblox.com/docs/art/modeling/surface-appearance
- https://create.roblox.com/docs/effects/beams and /trails
- https://create.roblox.com/docs/environment/post-processing-effects (path unverified)
- https://devforum.roblox.com/t/full-in-depth-tutorial-on-how-to-use-pbr-materials-to-create-realistic-objects-in-roblox/1574778
- https://nilo.io/articles/advanced-roblox-custom-meshes and https://www.alivegames.io/posts/roblox-texture-optimization-best-practices (new domains)
- https://vizzbees.com/blog/roblox-ui-design-ideas (seen in r2-look.md domain list)
- Search for "Doors devlog LSPLASH art", "Rivals developer interview art style" (not run)
