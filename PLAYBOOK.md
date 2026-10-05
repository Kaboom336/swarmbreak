# Roblox game playbook (Iris Works)

How we make a Roblox game that can reach the front page, starting from an idea in Notion. Written from Swarm Break
(2026-09-30). Every later game starts here; every lesson from a gauntlet round gets folded in.

## 0. The rules that never change
- Zion does: the Roblox account, Studio install, first Publish, game passes / products, any Robux spend, DevEx.
- Claude in the cloud does: design, code, models (Blender), tests, docs, research. It never runs Studio from the cloud.
- Names are plain words a 12-year-old knows. No niche lore words on buttons. (Zion, 2026-09-30.)
- No blood. Enemies burst into light and sparks in their own color.
- Never invent numbers. Player counts and revenue are sourced or marked estimate / UNKNOWN.
- Placeholder prices until launch; finalize from data.

## 1. Research first (half a day)
1. Name the niche and the 3-5 games that own it. Read their store pages and fan wikis with WebFetch (YouTube is blocked in the cloud).
2. Write RESEARCH.md: a chart of the top games overall, a table of the niche leaders (loop, currencies, servers, monetization, look), and 5 design takeaways.
3. Keep COMPARISON.md running for the whole project: what they do better, what we copied, what we beat.

## 2. Design in files, small and testable
- GAME-PLAN.md (one-line idea, core loop, first playable, how it earns, sequence). LORE.md in plain words.
- Pure logic lives in ReplicatedStorage/Shared modules with Lune tests (waves, weapons, economy, evolutions, profile).
- Checks that run in the cloud: `stylua --check src tests && selene src && lune run tests/run.luau` (selene offline std in roblox_min.yml).
- Persistent data: one Profile schema (sanitize on load, autosave, save on leave), run state on top.
- Lobby first (30 players) with themed zones, then small arenas (8) via TeleportService. Friends-first is what the top games share.

## 3. Art pipeline (Blender by script, in the cloud)
- `pip install bpy` gives Blender 5 as a Python module; Cycles CPU renders work. Libraries: game/tools/blender/sb.py (primitives,
  export, manifest) and sb2.py (the v2 technique). RECIPE.md in that folder is the artist's checklist; read it before any model.
- FIRST get a reference bar: clone open-licence packs (git clone of public GitHub repos works in the cloud; Kenney starter kits,
  KayKit CC0 kits, Khronos and three.js sample models) and render them with OUR lighting into assets/renders/refs/ with a licence
  README. Measure them (refs.json): 100-1500 tris, one palette, big flat colour areas, exaggerated proportions. Every judge and
  artist compares against that sheet, not against memory.
- The v2 recipe that finally read as a game asset: faceted low-poly (voxel remesh + decimate to a budget + flat shading), pieces
  fused into one shell, armour cut from the body surface so it hugs the curve, limbs from tapered segments with joint balls,
  eyes/horns/jaws placed ON the head with on_ellipsoid, heads 30-40 percent of the body, one nameable glyph per enemy, dark body
  + one saturated accent covering real area + bone-white sharp bits + one glow, colours painted per face by rules into vertex
  colours with baked ambient occlusion multiplied in (Roblox imports vertex colours, so the shading survives), an attack pose for
  the render only, and a thumbnail-style render (dark gradient world, warm key, cool rims, glossy floor, bloom, AgX).
- One file per model (enemy_<Name>.py, weapon_<Name>.py) so several artist agents can work at once without clobbering each other;
  shared helpers only in the libraries; manifest writes under a file lock.
- Parts are named for the Motor6D rig so the animation code keeps working; `_Glow` parts become Neon in Studio.
- Render every model, LOOK at it, and publish a 3D gallery (GLB + three.js) so Zion can look.
- Laptop step: File > Import 3D (FBX, Scale Unit = Studs), Neon on `_Glow`, fill mesh ids in Shared/Meshes.luau.

## 4. Gauntlet loops (the quality process)
For each piece (a model group, a system, a screen):
1. Build it.
2. Render it or test it.
3. Two or three judge agents with different lenses score it 1-10 against named top games and list concrete gaps
   (a fix must say which helper / file, where, what size and color).
4. One fixer agent applies the gaps, rebuilds, re-renders, and LOOKS at the result before reporting.
5. Repeat until a round has no major gaps (max 3 rounds), then move on. Log the lessons here.

## 5. Ship and learn
- PUBLISH-GUIDE.md lists Zion's clicks. MONETIZATION-SETUP.md lists passes and products with placeholder prices.
- After launch: check retention (D1, D7) and session length in Creator Hub before spending on ads. Weekly content drop.

## Lessons log
- 2026-09-30: part-built (blocks) models are not enough; Zion called them terrible. Real meshes, even simple ones, read far better.
- 2026-09-30: the first Blender pass looked like balloon animals: smooth blobs, floating plates. Fixes that worked: joint bulges on limbs, plates placed ON the shell with on_ellipsoid, segmented bodies, spikes and claws for edges, darker bodies with brighter accents, render from the front.
- 2026-09-30: names like Verdant / Circuit / Void / Aster-9 / Breakers read as niche; Nature / Tech / Lightning / Dark / Outpost 9 / Survivors do not.
- 2026-09-30 (later): the second Blender pass was still "terrible" to Zion, and he was right: smooth blobs + hose limbs + boxes on spheres + pastel colours + a bright grey studio render read as balloon animals whatever the judges tweaked. What fixed it was a technique change, not more rounds: reference renders as the bar (measured, in the same lighting), faceted low-poly with fused shells, armour cut from the body, big glowing eyes and an open jaw placed on the head surface, per-face rule painting with baked AO, and a dark thumbnail render with bloom. Lesson: when two fix rounds do not move the score, change the method and the reference, not the parameters.
- 2026-09-30: judges without pictures judge from memory. Give them a reference sheet rendered in the same setup.
- 2026-09-30: real stylized game assets use 100-1500 triangles; our 3-6k-tri models looked worse because detail was noise, not shape. Fewer, bigger facets read better.
- 2026-10-01: discovery now reads retention over 28 days (Day 1, Days 2-7, Days 8-28) plus first-play bounce and intentional co-play; spike-and-fade is penalised, so plan for return visits, not launch CCU. https://create.roblox.com/docs/discovery
- 2026-10-01: update spikes decay fast (Final Swarm 20,107 peak to ~2,400 in a week; 100 Waves Later 98.3% rating, 184 live). Only a steady update cadence holds players; a good rating does not. https://www.rolimons.com/game/99521272836282
- 2026-10-01: codes are marketing: give them a job (bring a friend, unlock after a milestone) and post a hype code the day before each update. https://www.pockettactics.com/build-and-kill-zombies-codes
- 2026-10-01: AI agents write server logic well and fail at space, UI layout and difficulty; keep layout as numeric data with tests, and leave tuning to a human playtest. https://medium.com/@andy.a.g/i-built-a-roblox-game-using-only-ai-agents-heres-what-happened-ed57b553facc
- 2026-10-01: bounded tasks (one target, one failing check, allowed files) beat open requests by a wide margin; even top models pass about half of open Studio tasks first try. https://github.com/Roblox/open-game-eval/blob/main/LLM_LEADERBOARD.md
- 2026-10-01: keep a numbered pitfalls file per domain and load it into every agent task; it was the biggest quality lever in a Codex vs Claude build test. https://note.com/hottarita/n/nb972e1eb21db?hl=en
- 2026-10-01: ship 3-5 thumbnails from day one; Roblox bandit-tests them by play-through rate (avg +8.5%). https://gamesbeat.com/roblox-will-let-game-devs-personalize-thumbnails-to-attract-more-players/
- 2026-10-01: design phone-first: most Roblox users are on mobile, and survivor-likes on phones are move-only with auto-aim; a desktop-only test pass misses most players. https://www.pocketgamer.biz/80-of-roblox-users-are-on-mobile-contributing-46-of-robux-revenue/
- 2026-10-01: every menu must work with a gamepad (selection + B to close), or the reward-card screen is a console dead end; the PS5 client shipped 2026-04-14. https://en.wikipedia.org/wiki/Roblox
- 2026-10-01: tutorial hints must not be a strict chain, and should appear just after the median time a player takes, not instantly; measure each step. https://create.roblox.com/docs/production/game-design/onboarding-techniques
- 2026-10-01: cap live Sound instances per client; Roblox's own test saw desync above 400 and audio cut-outs above 500 on a desktop. https://devforum.roblox.com/t/total-sound-instance-limit/3736250
- 2026-10-01: when research tools return titles only, say so and mark every number as "to verify"; a real-device profile beats an unread guide. https://create.roblox.com/docs/performance-optimization/improve
- 2026-10-02: a Blender render gallery is not the game; Zion's playtest showed grey placeholders because no mesh was uploaded. Judge only in-engine screenshots from fixed cameras. https://create.roblox.com/docs/art/modeling/3d-importer
- 2026-10-02: studio-lit renders hide value problems; near-black enemies on a dark floor vanish at gameplay distance. Judge a game-camera render plus its greyscale copy. https://create.roblox.com/docs/tutorials/use-case-tutorials/lighting/enhance-outdoor-environments-with-future-lighting
- 2026-10-02: bake colour and AO into a small palette texture (one material, UVs in 0:1) so the Blender look survives import; save SurfaceAppearance for bosses and arena tiles. https://create.roblox.com/docs/art/modeling/texture-specifications
- 2026-10-02: AI 3D generators can make static props but not our named rig parts; keep rigged enemies scripted and put any generated mesh through the same screenshot gate. https://devforum.roblox.com/t/beta-cube-3d-generation-tools-and-apis-for-creators/3558947
- 2026-10-02: glow and juice come from Roblox-native VFX: fade every particle in and out, keep Rate at or under 100/s for mobile, LightEmission plus Bloom for glow. https://create.roblox.com/docs/effects/particle-emitters
- Zion 10/2: reference YouTube videos are edited; treat captures as hints, not proof. Prefer unedited full playthroughs.
- Zion 10/2: take each aspect from the game that does it best (research/BEST-OF.md); judge each part against that game.
- Zion 10/2: keep Swarm Break's unique parts (elements, evolutions, melee weapons, co-op, bosses); borrow from every genre, never replace what is ours.
- Zion 10/2: still planning; nothing is locked. Change any part when there is a good, written reason.
- Zion 10/2 03:19: BEAT, not match. Every part must be better than the reference game at that aspect, plus one thing the reference lacks. Judges score beats/matches/worse.
- 10/2 16:20 wave 13 Play broke at load: game scripts wrote Lighting.Technology and called settings() (plugin-only). The lune tests and selene can't catch this. Rule: set engine properties in default.project.json; never use plugin or command-bar APIs in game/src; L1 lint enforces it.
- 10/2 16:28 wave 13 playtest: the HUD never loaded because Hud.client required script.Parent.UiKit without WaitForChild, which also meant "no upgrade". Rule: client siblings always load via WaitForChild. Imported enemy meshes were welded statues (no Motor6Ds), so nothing animated. Fit-in-box scaling shrank wide meshes; size enemies by height.
- 10/2 17:30 mouse stayed locked after death (Play Again unclickable): a stats push re-applied LockCenter after the camera unbound. Rule: one per-frame owner of MouseBehavior (MouseMode), free it for any modal, death, or Left Alt.

## Pumpkin game lessons (10/5, reusable for every simulator)
- Start from a proven, small genre (+1 per click → spend size on a roll). Judge every round against named front-page games, with a screenshot shot list per build.
- The cash-in must be active, not passive. Ride and smash (steer into bonuses, smash walls, combo text) made the loop fun; the plain roll did not.
- Payout must keep scaling with power: walls past the track (log curve), plus wins × size^0.25, plus a pure Economy.simulate pacing spec (Forest 2-4 min, rebirth 8-15, Graveyard 20-40).
- Ride feel: 7-10 s ride at every size, a gentle first 1.5 s, targets 0.7 s apart with beacons 2 s ahead, and the client predicts its own pumpkin each frame (server steps look jumpy).
- Steering: poll IsKeyDown inside the loop as well as using ContextActionService; a sunk action silently killed steering once.
- Camera: one shared framing function (2.2 × diameter + 8), a damped spring with a capped change per frame, hit-stop that keeps following the moving object, and a raycast that fades blockers. Invisicam stops jamming at huge sizes but hides the avatar.
- UI: a UIGradient tints TextLabel text too. Put gradients only on frames and give text objects a flat fill. Every label is white with a dark stroke.
- Money safety: credit guaranteed rewards in the same step that consumes the resource; settle only bonuses at the end.
- Workflow: Codex builds, Claude reviews and merges (fixing P1/P2 itself), Play captures in Studio, then judge, then the next task. About 1 round per 30-40 minutes.

## Roblox game-feel and quality checklist

Use this before calling any Roblox feature or build “done.” These are production defaults, not universal laws: tune them with real-device playtests and record any deliberate exception. Roblox targets 60 FPS (16.67 ms/frame) and recommends choosing a real low-end baseline device; Studio emulation is useful for layout but not representative of device memory ([Roblox performance](https://create.roblox.com/docs/performance-optimization), [design for performance](https://create.roblox.com/docs/performance-optimization/design)).

### Look

- Give hero models a deliberate value stack - lit face, base colour, darker underside/creases - plus one accent; flat single-colour SmoothPlastic is a blockout, not a finished collectible.
- Reserve maximum saturation, neon, emissive cores, rim light, and rarity auras for interactive or valuable states. Colourful scenery must remain quieter than the next action.
- Use a consistent 3D separation language for hero objects: dark form outline or controlled rim for silhouette, coloured rim only for state/rarity, and a mobile distance/performance cutoff.
- Make glow communicate state, not merely decorate it. Verify emissive detail and bounded local light in bright sun, shadow/tunnel, and reduced-effects mode without washing out the model.
- Pick one primary, one secondary, three semantic accents, and one near-black outline. Give every colour a role; do not accumulate near-duplicates.
- Keep important text flat white/near-white or near-black with 2–3 px contrast stroke. Put gradients on frames/surfaces, never on text.
- Test every gameplay silhouette at the real camera distance, in grayscale, and at low graphics. A target or obstacle must remain distinguishable for at least 1.2 s at maximum normal speed.
- Compose the spawn camera around one dominant landmark and the first action. The player should not need to rotate the camera to find the core loop.
- Enclose playable edges with intentional geometry. Use walls/cliffs at least 1.5× the player's jump height where escape is not gameplay, and reveal the sky deliberately at spectacle beats.

### Play

- State the loop as visible verbs: prepare → commit → make decisions → cash out → upgrade. Each stage needs a distinct world/UI state.
- Get a new player to the first meaningful input in ≤5 s, the first skill decision in ≤15 s, and the first complete reward loop in ≤45 s. Instrument each timestamp rather than guessing.
- For lane/obstacle games, guarantee at least one valid route per wave. At maximum speed, give 1.2–2.0 s from clear telegraph to required input.
- Keep authoritative outcomes on the server, but predict/interpolate the local player's motion every frame. Reconciliation must not visibly jump during normal latency.
- Prevent accidental exits from committed sequences. Save and restore movement, jump, camera, visibility, and input state on success, death, disconnect, and abort.

### Feel

- Make movement playful before rewards: author lean, squash/stretch, secondary lag, bump, airtime, and landing reactions while keeping hitboxes and control timing deterministic.
- Measure dead travel between cash-out and the next ramp, upgrade, and collection destination; compact the loop or add expressive fast traversal when any core return trip exceeds 6 seconds.
- Every accepted primary action gets visual, motion, and audio acknowledgement within one rendered frame when locally predictable; rejected actions must not play success feedback.
- Primary buttons depress 4–6 px in ≤60 ms and rebound in 140–200 ms. Use one shared hover/focus/pressed/disabled implementation.
- For rolling objects, accumulate axle rotation as `distance / radius`, ground-snap with a raycast, and keep visual clearance ≤0.15 stud unless the art requires more.
- Tie speed FOV, wind, particles, and audio to measured velocity, not elapsed progress. Smooth camera/FOV changes over roughly 0.15–0.35 s; use shorter impulses only for hits.
- Bound camera shake and hit-stop: a routine hit-stop should be 0.03–0.06 s, never obscure the next decision, and have a reduced-effects mode.

### Juice

- Maintain an action-feedback matrix covering every core verb. Each accepted action needs at least two immediate channels (motion, VFX, sound, or UI) and one unambiguous result state.
- Build a themed particle vocabulary with specified motif, direction, lifetime, and colour; every physical contact needs a world-space response, not only floating text.
- Give recurring characters, vehicles, pets, eggs, hazards, and rewards distinct idle and reaction silhouettes; tweening scale alone is not a complete animation set.
- Give important actions a three-beat response: anticipation (ready/telegraph), contact (flash/sound/impulse), result (number/reward/state change).
- Pool repeated effects. Set hard per-client caps for popups, particles, debris, sounds, and lights; old tweens/connections must be cancelled when a pooled object is reused.
- Use milestone effects for actionable thresholds—new upgrade, affordable egg, reachable wall—not arbitrary large numbers alone.
- A combo event needs a unique positive pop, meter movement, pitch step, and clear reset. Displayed, calculated, and persisted reward values must match exactly.
- On the baseline mobile device, profile the busiest intended scene and hold the 60 FPS target/16.67 ms frame budget; define a reduced-effects tier before shipping.

### UI

- Define hero-number, action-label, and body-copy tokens. Use thick type, flat glyph fill, 2-4 px ink stroke, and short lines; place gradients/shine on backing plates or depth faces, never directly on text.
- Use shared micro/reward/rare pop tiers with bounded overshoot, settle, stroke flash, shine, number tick, and reduced-motion variants; do not let simultaneous celebrations hide gameplay.
- World guidance uses one animated language - chevron or ribbon, target halo, short verb, and optional distance - and disappears permanently once the player proves the action.
- At speed, use tapered beacons plus ground markers and distinct pickup/danger silhouettes; pulse inside the reaction window and remove cues immediately after they pass the player.
- Keep the action corridor clear. Use fixed slots for currencies, objective, combo, controls, and reward bursts; no two systems may borrow the same center-screen rectangle.
- Make primary mobile actions at least 56×56 px and continuous steering controls at least 72×72 px. Critical play text should be at least 18 px equivalent; avoid 10–12 px copy during action.
- Respect device safe insets and Roblox/CoreGui controls. Test at minimum 667×375, 1920×1080, one tall/notched phone, and one tablet profile.
- Every modal needs a close button, outside/back behavior, gamepad selection graph, default selected object, disabled state, and scroll test.
- Use plain benefit-led labels (`2× Size`, not `DoubleSize`). A purchase row states benefit, duration/permanence, price, ownership, and stacking rule before opening a platform prompt.

### Onboarding

- Teach one essential at a time with world highlights/arrows and as few words as possible. Delay shops, gifts, pets, and prestige until the core action has been performed once.
- Use contextual hints first. Show a timed hint only after the measured median completion time—typically start an experiment at median +1 s—not immediately ([Roblox onboarding techniques](https://create.roblox.com/docs/production/game-design/onboarding-techniques)).
- Never consume a scarce resource for a zero-reward tutorial attempt. Block the action with a specific requirement or preserve the resource.
- End onboarding after the player sees the reward land, not when the server merely starts or computes the action. Finish with an authored celebration and the next reachable goal.
- Track a funnel at minimum: joined → first input → first skill decision → first finish → first spend/upgrade. Review drop-off by device and control type.

### Economy

- Put every tuning number in one shared configuration source and test the exact award formula. Round currency once, at the final award step.
- Show the next affordable goal and estimated runs/actions to reach it. Simulate the first 5, 15, and 30 minutes, then verify with playtest telemetry.
- Define every multiplier's scope (gain, reward, luck, or all) and stacking rule (additive or multiplicative). Never apply a “Size” multiplier silently to Wins.
- Credit guaranteed rewards in the same transaction that consumes the resource; settle optional bonuses later with idempotent receipts/ledgers.
- Prestige/reset screens list what resets, what stays, the exact new multiplier, and require confirmation for destructive changes.

### Monetization

- Query and display the purchaser's current localized/platform price; never treat a configured or research-snapshot Robux price as authoritative when regional, personalized, or subscription pricing can differ.
- A starter pack previews every item and its permanence, includes a named cosmetic/collectible plus useful non-required progression, states honest component value, and can only be purchased once.
- A permanent 2x currency pass and any repeatable timed sample state exact scope, duration, stacking cap, and free-path pacing; grant an earned free sample before selling acceleration where practical.
- Escalating-price tracks must be finite and fully previewed, with every step price, cumulative spend, reset rule, stop point, duplicate protection, and hard cap visible before purchase; do not use hidden future rewards or endless escalation for children.
- A limited-time offer needs a genuine content/eligibility end, absolute end time plus countdown, no auto-open, no fake evergreen urgency, and a clean archived state after expiry.
- Hide offers whose IDs are unset, and run a pre-publish validation that fails/report-lists missing IDs. Never show placeholder prices as live offers.
- Let the player experience the core loop and first reward before spotlighting a purchase. Contextual offers must follow a demonstrated need, not interrupt onboarding.
- Separate passes, consumables, and bundles or make their category explicit. Do not keep two HUD buttons that open the same undifferentiated store.
- Purchase UI states the benefit, duration, ownership, stacking, and price; successful delivery is server-authoritative and idempotent.
- Provide a useful free path and verify pacing without paid boosts. Monetization may accelerate a legible loop; it must not repair an unfun one.

### Retention

- Keep two horizons visible after the first loop: one reachable next goal this session and one concrete return goal such as a rotating challenge, collection set, or authored event.
- Let return content visibly change the world - plaza dressing, route modifier, landmark, collectible, or reward track - instead of adding another timer badge to the HUD.
- Preserve the stable core route while rotating bounded novelty. Track D1/D7 return, challenge participation, and completion by device; do not infer retention from reward claims alone.

### Mobile and performance

- Test controls on a real baseline phone throughout development. Studio's emulator validates aspect ratio and controls, not representative memory usage.
- Keep simultaneous camera and action touches working. Use lane-snap or a visible analog intent/dead zone for precision steering; never rely on keyboard polling alone.
- Consider instance streaming for larger worlds; prefetch committed ride paths and test that required collision/visual geometry is present ([Roblox streaming](https://create.roblox.com/docs/workspace/streaming)).
- Prefer client-only cosmetic effects when the server needs only outcome/location. Reduce distant players' effects and disable unnecessary shadow casting on lights and props ([Roblox improve performance](https://create.roblox.com/docs/performance-optimization/improve)).
- Run a 10-minute stress/soak pass. After effects settle, InstanceCount and LuaHeap should return to a stable band; investigate growing connections, tweens, sounds, or pooled objects.
