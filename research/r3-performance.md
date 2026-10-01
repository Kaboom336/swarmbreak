## R3: Performance on low-end phones (2026-10-01)

**Evidence status (read first).** The three searches I ran (4 total) returned result titles and URLs only, no text snippets. The owner is away and I was told not to WebFetch create.roblox.com or any new domain, so I could NOT read any performance page. No Roblox number below is quoted from a source. Every external limit is a "to verify" item; only the code facts about our game are verified (read from game/src).

### What the searches surfaced (titles only, unread)
- Roblox "Design for performance": https://create.roblox.com/docs/performance-optimization/design
- Roblox "Improve performance": https://create.roblox.com/docs/performance-optimization/improve
- Roblox "Particle emitters": https://create.roblox.com/docs/effects/particle-emitters
- Community mesh/triangle budget guides: https://www.alpha3d.io/knowledge-base/roblox-meshpart-polygon-limit , https://meshlox.com/learn/roblox-mesh-size-limits , https://devforum.roblox.com/t/reasonable-amount-of-triangles-for-models/1529723
- Mass-NPC threads (titles suggest humanoid cost, network and physics lag): https://devforum.roblox.com/t/humanoid-optimisation-and-500-npcs/312738 , https://devforum.roblox.com/t/methods-of-reducing-network-and-physics-lag-with-large-numbers-of-humanoids/371319 , https://devforum.roblox.com/t/how-to-optimize-humanoids/389801 , https://devforum.roblox.com/t/humanoids-are-more-performant-than-animation-controllers-when-playing-animations/4170689
- Network ownership threads (NPC ownership flipping to players despite SetNetworkOwner): https://devforum.roblox.com/t/networkowner-becoming-players-despite-setting-to-server/3257406 , https://devforum.roblox.com/t/permanent-server-network-ownership/2626460
- Particle rate threads: https://devforum.roblox.com/t/does-the-particleemitter-rate-have-a-significant-affect-on-performance/3006334 , https://devforum.roblox.com/t/particle-emitter-limit-on-low-graphics-is-impacting-my-game/2159584 (title says low graphics quality caps particles; unverified)
- Optimisation overviews: https://kitsblox.com/blog/roblox-performance-optimization-advanced , https://www.creation.dev/blog/roblox-game-performance

### Our current state (verified in code)
| Area | Fact | File |
|---|---|---|
| Server cap | MaxAlive = 30; WaveManager gates spawns on EnemyAI.aliveCount() | game/src/ReplicatedStorage/Shared/Config.luau:9, ServerScriptService/WaveManager.server.luau:104,194 |
| Ownership | Ground enemies: root:SetNetworkOwner(nil); flying are Anchored and moved by CFrame writes | ServerStorage/EnemyAI.luau:174,195,265+ |
| AI loop | One Heartbeat loop over `live`; per enemy calls nearestPlayerRoot (iterates Players, FindFirstChildOfClass + FindFirstChild every call) | EnemyAI.luau:40-54, 265 |
| Ground movement | One task.spawn(groundMover) per enemy, own Path object, ComputeAsync + MoveTo, also calls nearestPlayerRoot | EnemyAI.luau:103-125, 212 |
| Humanoid | Every enemy has an R15 Humanoid with a custom rig; DisplayDistanceType None | EnemyAI.luau:176-186 |
| Client anim | EnemyAnimator Heartbeat sets Motor6D.C0 per joint (up to ~15 sets plus Leg_1..8) per enemy per frame; defines a closure `set` inside the loop per enemy | StarterPlayerScripts/EnemyAnimator.client.luau:52-90 |
| Emitters | Each enemy gets a glow ParticleEmitter Rate = 12 plus a PointLight Range 6 on head (so up to ~30 emitters + 30 lights live) | ServerStorage/EnemyBuilder.luau:80-95 |
| Client FX | Debris:AddItem holders; ParticleEmitter created per effect | StarterPlayerScripts/ClientFX.luau:146-210 |
| StreamingEnabled | No setting found in game/default.project.json or src (grep); arena looks small and fixed | game/ |
| Tri budget | Enemies 4-7k tris each (brief); no tri count recorded in ASSETS.md (grep empty) | game/ASSETS.md |

### Budget table (our numbers vs. limits to verify)
Raw worst case on screen: 30 enemies x 4-7k = 120k-210k enemy tris (estimate from our own brief, arithmetic only), before arena, weapons, FX. Whether that is OK on a low-end phone is UNVERIFIED; I have no sourced Roblox figure. Proposed internal limits, all ESTIMATES to be replaced after reading the Roblox pages and profiling on a real low-end device:
- Enemy tris: target <=2.5k for common types, <=7k only for bosses (estimate; hit the shared mesh cache by reusing MeshIds).
- Concurrent alive: keep 30 on server, but add a client-side render budget (see change 4). Estimate: low-end phone comfortable at ~15-20 fully animated enemies.
- Emitters: 0 per ordinary enemy; shared pooled emitters for hit/death FX, cap ~10 live (estimate).
- Lights: 0 per enemy (PointLight on each head is a dynamic-light cost; unverified magnitude).
- Per-enemy server work: O(enemies x players) target search every frame is small at 30x4 but the pathfinding coroutine per enemy is the larger risk (ComputeAsync cost not measured).

### Risks, ranked
1. Client animation cost: ~30 enemies x ~15 CFrame multiplies and C0 writes per frame, on the phone that is also rendering. No distance or visibility culling. Joint writes also dirty replication/physics state locally. (Code fact; magnitude unmeasured.)
2. Emitters + lights per enemy are always on, regardless of distance. Cheap to remove.
3. Per-enemy Path + Humanoid:MoveTo. Network ownership is already nil (good: avoids ownership flips and exploiter control, theme of the threads above, unread), but server Humanoid physics for 30 is the real server cost; unmeasured. Server step time should be profiled with the MicroProfiler / Script Performance (not run: no Studio here).
4. No StreamingEnabled: fine if the arena is small; revisit only if the arena grows. Unverified that it helps mobile memory.
5. Telemetry blind spot: we do not record client FPS or device class, so we cannot see low-end failure in the wild.

### Must-read later (not fetched)
- https://create.roblox.com/docs/performance-optimization/design
- https://create.roblox.com/docs/performance-optimization/improve
- https://create.roblox.com/docs/effects/particle-emitters
- https://create.roblox.com/docs/workspace/streaming
- https://devforum.roblox.com/t/humanoid-optimisation-and-500-npcs/312738
- https://devforum.roblox.com/t/methods-of-reducing-network-and-physics-lag-with-large-numbers-of-humanoids/371319
- https://meshlox.com/learn/roblox-mesh-size-limits
- https://www.creation.dev/blog/roblox-game-performance

### Concrete changes (verify limits via Must-read before tuning numbers)
1. **Remove per-enemy glow emitter and PointLight; replace with a Neon eye part or one shared pooled emitter.** Files: ServerStorage/EnemyBuilder.luau:80-95. Evidence: https://create.roblox.com/docs/effects/particle-emitters (unread, title only). Effort S. Claude (art look must be kept).
2. **Distance/visibility culling in EnemyAnimator: skip joint writes beyond N studs or off-screen, update far enemies at 1/3 rate; hoist `set` closure out of the loop.** File: StarterPlayerScripts/EnemyAnimator.client.luau:52-90. Evidence: https://create.roblox.com/docs/performance-optimization/improve (unread). Effort S. Codex (pure Luau; cull function unit-testable).
3. **Cache player roots once per frame in EnemyAI (build list of live roots, share between Heartbeat and groundMover); stagger pathfinding recompute per enemy by id.** File: ServerStorage/EnemyAI.luau:40-54,103-125,265. Evidence: https://devforum.roblox.com/t/methods-of-reducing-network-and-physics-lag-with-large-numbers-of-humanoids/371319 (unread, title). Effort M. Codex.
4. **Add a quality tier (Config.Quality): auto-lower on low FPS (sample Heartbeat dt 5 s window), reducing emitter rates, anim distance, and FX count; expose Low/High in settings.** Files: ReplicatedStorage/Shared/Config.luau, ClientFX.luau, Settings. Evidence: https://devforum.roblox.com/t/particle-emitter-limit-on-low-graphics-is-impacting-my-game/2159584 (unread, title). Effort M. Codex (tier selection pure function with spec in game/tests).
5. **Record triangle count per enemy mesh in ASSETS.md and add a tools/ check that fails if a non-boss exceeds the budget (start 2.5k, estimate).** Files: game/ASSETS.md, game/tools. Evidence: https://www.alpha3d.io/knowledge-base/roblox-meshpart-polygon-limit (unread). Effort S. Codex.
6. **Telemetry: log average client FPS + platform per wave so low-end regressions are visible.** Evidence: https://create.roblox.com/docs/production/analytics/retention (used in r2-critique, verified for analytics generally, not FPS). Effort S. Codex.
7. **Profile on a real low-end phone (or Studio emulator) with 30 enemies and write the measured numbers back into this file replacing the estimates.** Evidence: none, this is the fix for the evidence gap. Effort M. Claude (judgment, needs a human device).
