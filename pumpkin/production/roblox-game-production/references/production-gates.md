# Production gates

These gates define evidence, not a fixed development schedule. Scale them to the game's genre and current milestone. Timing and frame-rate targets are project hypotheses to measure, not promises of commercial success.

## 1. Prove the interaction

Make one full action → consequence → reward → next action. The player should understand the object and next action without a wall of instructions. Test the intended decision, not just whether pressing a button increments a number. For a cooperative premise, include another player in this first slice: shared visible state, individual contribution, a joint payoff, and a workable solo route.

Define server ownership of inventory, money, progress, launch/hit resolution and rewards. Validate remote types, finite values, proximity, cooldowns and ownership. Test duplicate actions, simultaneous contributions, leaving mid-action, reconnecting and round reset so state or currency cannot duplicate.

## 2. Prove one finished scene

Use a chosen licensed kit for surroundings and a deliberate hero silhouette. Primitive parts remain useful for collision and temporary layout; they are not the finished visible art when the user's target demands authored meshes.

Inspect at intended camera distance: spawn vista, player action, impact, reward and upgrade reveal. Remove generic filler that competes with the hero. Keep lighting readable before adding bloom. Make world landmarks explain navigation. Readability must survive a phone viewport, missing audio, and reduced effects.

Give the signature interaction anticipation, clear contact and a short recovery. Tune input and camera before multiplying particles. Use a small sound vocabulary with controlled pitch variation and positional falloff. Keep shake bounded and optional. Cinematics must release controls reliably, offer a suitable skip/reduced-motion path, and not pause unrelated players.

## 3. Prove it survives real play

Run meaningful unit/static checks and a reproducible build. Then separately test in Studio: solo, two clients, and the planned simultaneous-player load. Check late join, contested pickup/interaction, reset/death, departure, slow network, UI focus, touch and controller where supported. Use isolated test data when testing persistence; verify old-profile migration and failed-save behavior.

Profile representative gameplay and the busiest effects scene. Choose a real minimum device and frame-time/memory budget in the brief. Device emulation helps layout but is not hardware performance evidence. Pool bounded cosmetic effects, measure mesh/texture cost, streaming behavior, physics and remote traffic. Optimize demonstrated bottlenecks rather than lowering every asset blindly.

Build evidence should name source revision/dirty state and artifact hash. Passing Luau tests does not certify replication, visual quality, audio permissions, published data access or player enjoyment. Keep those statuses explicit.

## 4. Prove players want another loop

Observe a new player without explaining the game. Can they start, identify a reward, choose an upgrade, and restart? With friends, can they see how both people changed the same world? Use clips and brief questions to find confusion, dead time, repetition and weak payoff. Fix the biggest failure before more content.

Instrument first-session steps, loop completion, upgrade use, session length and return play. Compare changes against an actual baseline with adequate samples; do not mistake small sample noise for a win. For cooperative games, also inspect party behavior and solo abandonment. Analytics identify problems; playtests explain them.

## 5. Expand and prepare release

Only then add content variety, deeper progression and collections. Every upgrade should improve a felt action or a visible state; do not make numeric inflation the entire reward. Balance initial sessions separately from late-game sinks. Add purchases only when requested and the experience works without them; use authoritative receipt handling if purchases are present.

Before public release verify asset permissions, live save configuration, localization/layout, support/report routes where needed, server capacity, exploit boundaries, and a restorable prior build. Use honest in-game renders for icons, thumbnails and clips. Publish or spend on acquisition only with the user's authorization. After release prioritize first-session friction, technical failures and retention evidence over expanding the feature list.

## Official references

- [Templates](https://create.roblox.com/docs/resources/templates): select systems by fit, not by the amount of bundled content.
- [Studio MCP](https://create.roblox.com/docs/studio/mcp): direct inspection/playtesting when connected; do not assume this integration is installed.
- [Studio testing modes](https://create.roblox.com/docs/studio/testing-modes): multiple clients and device/network testing.
- [3D importer](https://create.roblox.com/docs/studio/importer): model intake and asset setup.
- [Performance](https://create.roblox.com/docs/performance-optimization/improve): measure expensive scripts, rendering and physics.
- [Funnel events](https://create.roblox.com/docs/production/analytics/funnel-events): measure the actual first-session route.
