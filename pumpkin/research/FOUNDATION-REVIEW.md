# Pumpkin: free foundation and production decision

Checked 2026-10-06. User budget: free assets and templates only. Preserve the current prototype and uncommitted launch-control changes. No source game was purchased, no new Store model inserted, and no candidate template's runtime verified in this review.

## Decision

Rebuild the playable loop and map around cooperative pumpkin farming and catapulting. Keep useful tested infrastructure after checking its behavior against the new requirements. Do not erase the repo or keep adding shops to the old solo downhill loop as if that solves the direction change.

The user means [Build the Pyramid! by Janitors Studios](https://www.roblox.com/games/123720558354386/Build-the-Pyramid). Its official description confirms carrying blocks, working together, training speed/strength and completing pyramids. That supports borrowing a visible shared task, repeated contributions and progression that changes the work. It does not expose the original code. No verified free source for that exact game was found. Marketplace lookalikes are not established as its template; the paid candidates are excluded by the budget.

Suggested Pumpkin equivalent: a pumpkin patch and catapult terrace overlook a haunted valley. Each player's ghost hits push back a visible shared ghost wave and charge a giant ward at the plaza. Everyone sees the ward's state change; contributors receive a clear payout at completion. This shared ward is a proposed design choice, not a requirement the user already specified. Keep it completable solo and scale the wave to active participation. Friends can farm and fire in parallel without waiting for one launcher.

## First playable milestone

One compact authored scene, one pumpkin type, one adjustable launch interaction, one ghost target group, one shared ward cycle and one upgrade. Complete: harvest → carry → aim/launch → ghost hits and pumpkin damage/burst → individual gold plus shared progress → upgrade → repeat. A spell ascension is the next presentation milestone once this loop is fun; pets, extra zones and a large shop catalog wait.

Proposed first-session targets: show the next action on spawn; first harvest within 15 seconds; first launch/reward within 60 seconds; first meaningful upgrade within 3 minutes. Measure these with a new player before treating them as settled balance. Two friends must see each other's carry/launch/hits, contribute to the same objective, and receive the final payoff once. No loot stealing or required waiting for friends.

## Free reuse shortlist

| Source | What it supplies | Decision and evidence |
|---|---|---|
| Existing Pumpkin modules | Data/profile migration, server validation, input/UI patterns, economy logic and local checks | First code donor. Existing tests are useful; old ride/map/economy assumptions still need re-evaluation. No blanket claim that saving or visual quality is finished. |
| [Roblox official templates](https://create.roblox.com/docs/resources/templates) | Reusable sample projects; Racing has modular track/car; Pirate Island has cannons; Mansion of Wonder has a track ride and enemy shooting | Technical reference for trajectories/targets/rounds, not the entire cooperative foundation. Study relevant source; do not insert unknown scripted Store models. |
| [Legacy Intro to Studio catapult source](https://github.com/Roblox/creator-docs/blob/main/content/en-us/tutorials/first-experience/index.md) | A documented catapult/target teaching example | Reference only. The current first-experience curriculum has changed. Its Store catapult is not certified script-free and must not be inserted. |
| [Slime Factory Tycoon](https://github.com/DLinacre/slime-factory-tycoon) | MIT repository with Rojo and simulator modules, according to its README | Optional donor only. README/license reviewed; source behavior/tests not audited. Private simulator progression is a poor substitute for shared work. Retain MIT notice if any code is adopted. |
| [KayKit Halloween Bits](https://kaylousberg.itch.io/halloween-bits) | Free CC0 tier: 60+ graveyard meshes, raw OBJ/FBX/GLTF and atlas | Preferred environment vocabulary. Free files still need intake/import/performance checks. Candy, tractor, scarecrow and maze extras are paid and excluded. The earlier Desktop art board overstated the free tier. |
| [Kenney Graveyard Kit](https://kenney.nl/assets/graveyard-kit) | 90 CC0 models | Alternative cohesive environment kit, selected filler only if compatible with the main style. Do not blend several kits indiscriminately. |
| [Kenney Particle Pack](https://kenney.nl/assets/particle-pack) | CC0 effect sprites | Dust, impact rings, launch streaks and readable magic. Import selected sprites and record uploaded IDs. |
| [Kenney Impact Sounds](https://kenney.nl/assets/impact-sounds) | 130 CC0 audio files | Starting vocabulary for carry/launch/impact feedback, subject to listening, editing and in-game permissions. Not yet auditioned or imported. |

These are reviewed source options, not a claim that their archives have been downloaded, inspected or integrated. Before adoption, record selected file names, retained license, checksum/source version, import details and actual playtest result.

## Art direction and quality bar

Warm orange hero pumpkins, cool violet/blue valley, lime success and gold rewards. Use chunky paths, fences, trees, gravestones and lanterns to frame the route. The patch, catapults, ghosts and spell plaza must each read as distinct landmarks from normal camera distance. The patch belongs at the rear/end of the route as requested; give players a short return path rather than a long empty walk.

Custom focal art: a expressive ribbed pumpkin with healthy/cracked/burst states, a readable launcher arm and sling, a friendly ghost silhouette and a transforming ascension pumpkin. Free raw meshes can start the silhouette; deliberately adapt/modell it rather than covering a sphere with particles. Parts can provide invisible collision and temporary layout. The finished scene cannot be plain visible blocks with orange paint.

Prioritize launch anticipation, sling release, visible trajectory, chunky ghost reaction, falling rind, satisfying gold feedback and quick restart. Limit screen shake; provide reduced motion/effects. Cinematic spells should gather magic into the pumpkin, change its silhouette, reveal its name and return control cleanly. A bigger number with a glow ring is insufficient.

## Build and review route

Use the reusable [Roblox Game Production skill](../production/roblox-game-production/SKILL.md). Its brief and quality gates apply to future genres as well as Pumpkin. Maintain this file as the worked example, not a universal Halloween specification.

After gameplay changes, run format/lint/Luau checks and build Desktop `PUMPKIN-TEST.rbxl`. Report exactly what changed and a short playtest route. Judge screenshots/clips against the object silhouette, composed scene, motion, readability and shared play; state what looks cheap and fix one major area at a time. Commit only after the user says it is good.

Run Studio solo and two-client tests before calling the new slice verified; also test simultaneous contributions, late joins, leaving with a carried pumpkin, resetting during launch and duplicate rewards. Mobile controls and busy-effect performance require separate evidence. The previous 106 local tests do not establish these outcomes.

[Roblox's built-in Studio MCP](https://create.roblox.com/docs/studio/mcp) can provide screenshots, console access and playtesting through an AI client. It is not currently connected in this session. No relevant Roblox Studio plugin was returned by the plugin search. Establishing a real Studio connection would remove much of the present screenshot-only feedback delay; until then, rely on user captures and mark runtime checks pending.

## Still to establish

- Actual in-game or timestamped video study of Janitors' social rhythm; official listing reviewed, videos not watched in this pass.
- Archive intake and selected model/audio imports, with license and permission ledger.
- A new cooperative scene and server-authoritative shared loop; this review does not implement it.
- Studio/runtime, visual and device evidence; no claim of consistent commercial success from a workflow alone.
