# Roblox game plan: "Swarm Break" (working title)

**Owner:** Roblox thread (cloud). Laptop build waits until the other automation lanes are done.
Source idea: Zion's Notion Home page, to-do item "First Roblox game can be similar to Final Swarm and survivor.io..." (read 2026-09-30) and the "AI Roblox Game" idea card (Horizon: Later, Priority: Medium, note: "first build a simpler obby to learn the platform").

## The idea in one line
Wave survival (like Final Swarm / survivor.io) with movement that feels good: double jump, dash, climbable spots. Rounds with a cinematic boss intro every 5 rounds, final boss at round 15 on normal. Infinite mode for the leaderboard. Weapons with rarity, unlocked by a paid random crate. Runs 10 to 30 minutes.

## Core loop
1. Spawn in a small arena with a few climbable towers and gaps.
2. Enemies come in waves. Kill them, pick up coins.
3. Between waves (10 s) buy upgrades with coins; open the shop.
4. Every 5th wave: boss intro cutscene (camera pans, name card), then the boss.
5. Win at wave 15 (normal). Leaderboard = best wave in Infinite.
6. Earn: coins in-game, weapons from crates (Robux), passes for perks.

## First playable version (ships in days, not weeks)
Keep it to what proves the loop is fun:
- One arena (Studio parts, no custom models). Two towers, one gap, one ledge you can dash to.
- Movement: double jump + dash (already in the scaffold). Climbing = later.
- Three enemy types: Walker (ground), Runner (fast, low HP), Flyer (hovers, dives). All use simple chase AI.
- One boss at wave 5 (a big Walker with more HP and a slam). A 4-second intro: camera locks, name card, music.
- Waves 1 to 5 only. Wave 5 win = "demo done" screen and restart.
- One starter gun with a fire rate and damage. Weapon rarity table exists in code but only 3 weapons defined.
- Coins, a simple HUD (wave, HP, coins), a between-wave shop with 3 upgrades (damage, speed, max HP).
- Leaderboard: best wave, saved with DataStore.
Not in v1: infinite mode, crates, cosmetics, more maps, sounds beyond free ones.

## How it earns
All numbers below are from Roblox's own docs unless marked.
- Game passes (one-time): 2x coins, starter weapon pack, extra dash. Roblox keeps 30% of Robux on every sale (SOURCE: Roblox Creator Docs, "Marketplace fee").
- Developer products (repeatable): coin packs, weapon crates, "revive". Crates must show the odds on screen (SOURCE: Roblox paid random items policy).
- Premium Payouts: Roblox pays per minute Premium members spend in the game (SOURCE: Creator Docs, "Engagement-Based Payouts"). Rate per hour is not published; UNKNOWN.
- Robux to cash: DevEx pays $0.0038 per Robux, minimum 30,000 Robux per cash-out, and the account must meet Roblox's DevEx eligibility rules (SOURCE: Roblox DevEx page; check the current terms before counting on it).
- Revenue: UNKNOWN. This is hit-driven. Most new games earn nothing; a few earn a lot. Treat it as a long bet, not cashflow.
- Ads: Roblox "Sponsored Experiences" cost Robux. Any spend needs Zion's OK.

## Tools (all free)
- Roblox Studio (Windows). Only Zion can install it and sign in.
- Rojo (MPL-2.0): syncs the files in `roblox/game/` into Studio, so Claude and Codex write code as files. Install the Rojo CLI plus the Rojo Studio plugin.
- Luau: the language. Rojo project file: `game/default.project.json`.
- Wally (MPL-2.0) for packages later if needed. Not required for v1.
- Selene + StyLua (both MPL-2.0 / MPL-2.0) for lint and format. `testcmd:` for Codex tasks = `selene src && stylua --check src`.
- Free assets: Roblox Creator Store items marked free and made by Roblox, or CC0 (Kenney.nl). Read each item's license before use. No ripped assets from other games.

## What only Zion must do
1. Have a Roblox account and be signed in to Studio on the laptop.
2. Install Roblox Studio (free). Then Claude installs Rojo and the plugin.
3. Press Publish in Studio (first publish makes the game exist) and set it to Public when ready.
4. Create the game passes and developer products in the Creator Dashboard and paste the IDs into `game/src/ReplicatedStorage/Shared/Monetization.luau` (Claude does the paste; Zion creates them, since that is account setup).
5. Any spend (ads, paid assets): say OK first.
6. DevEx cash-out later: Zion's account only.

## Sequence
1. Now: plan + code scaffold (this thread, cloud, no laptop).
2. When the automation lanes are done: coordinator starts a laptop session. Zion installs Studio. Claude installs Rojo, syncs, and playtests. Codex gets bounded code tasks via Iris with `testcmd:`.
3. Playable demo (waves 1 to 5). Zion playtests. Then boss polish, infinite mode, crates.
4. Publish public. Clipper posts gameplay clips on PrankStar TikTok to get first players.

## Update 2026-09-30
Plan written from Notion. Scaffold started in `roblox/game/`. Waiting on nothing from Zion yet.
Review pass 2026-09-30: fixed 10 Studio-only findings (Rojo path, flyer melee range, aim inset, revive receipt always granted, deferred boss summons, arena obstacles moved off spawn lines + pathfinding for ground enemies, CFrame in model JSON, players present at script start, shop panel height, dash listener cleanup). Checks still clean.

## Update 2026-09-30 (art, weapons, feel)
Zion: real models and effects, a cinematic game people want to spend Robux on; weapons beyond guns, inspired by Final Swarm and survivor.io.
- No external assets reachable from the cloud (Creator Store, Kenney and GitHub are blocked here), so every model is built from parts in code with neon, lights and particles. Mesh imports are an optional laptop pass (game/ASSETS.md).
- Enemies: 8 rigs (Walker, Runner spider, Flyer with wings, Tank beetle with shell, Spitter with acid sacs; bosses Brute, Swarm Queen, Sky King with crowns and auras), animated procedurally on the client.
- Weapons: 15 across 4 kinds. Hitscan guns, melee (Rusty Blade, Shock Hammer slam, Energy Sword lunge, Dark Scythe scythe), orbitals (Spinning Blades, Lightning Orbs, Sun Orbs), beam (Laser Beam). Each has a held model.
- Feel: muzzle flashes, tracers, hit sparks, death bursts, spawn portals, boss gate, camera shake, FOV kicks, low-HP vignette, hurt flash, crate reel, wave/boss sounds (Roblox built-in sounds; music slot empty).
- Arena: "Overrun Station" theme: slate floor with neon grid, metal walls with trims, catwalks with rails, crates, barrels, pillars, hazard lights, atmosphere, bloom, color correction.
Staged for later: drones/companions, boomerang projectiles, weapon upgrades/evolutions, more maps, mesh art pass, music.
Review pass 2 (2026-09-30): 14 findings fixed (rig ground height, weapon grip orientation and muzzle end, death burst NaN, server network ownership for enemies, RequiresNeck on flyers, decorative parts no longer block bullets, beam flicker, pathfinding cost, orbital map leak, hotbar crash on unknown weapon). Checks clean: StyLua, selene, 28 files compile, 18 tests.
Open questions with defaults: OPEN-QUESTIONS.md.

## Update 2026-09-30 (research, names, Blender models)
- Research: RESEARCH.md compares Final Swarm, Survive The Swarm, Bullet Heaven and Build and Kill Zombies with the top charts.
  Takeaways used: lobby first with big servers, pick-1-of-3 on wave clear (built, see below), chest tiers, weekly updates.
- Names simplified everywhere: elements Nature / Tech / Lightning / Dark, Gems (forever currency), Shards, the Base,
  Outpost 9, the Nest, Survivors; plain weapon names (Shotgun, Sniper Rifle, Energy Sword, Dark Scythe...).
- Evolution system wired end to end: Gems + shards persist, bosses drop shards, every 5th wave drops a Tech shard,
  evolve from the shop, element effects in combat (heal on kill, poison slow, bounce, chain, haste, lifesteal, pull),
  element visuals on the held weapon.
- Models: made in Blender by script in the cloud (game/tools/blender). 8 enemies, 15 weapons, 12 arena pieces exported
  as FBX + GLB with renders and contact sheets in assets/renders. Second pass done on the enemies (segmented bodies,
  plates and spikes on the shell, big wings, claws). More passes as we go.
- Wave rewards: after every wave clear each player picks 1 of 3 cards (12 cards in Shared/WaveRewards: Stat, Weapon
  and Utility kinds; weapon cards only show for the weapon kind you hold; boss clears favour Weapon and Utility cards;
  a card stops showing at its max stacks). Tap a card or press 1-3 during the shop timer; the first card is taken for
  you when the timer runs out. Boosts fold into the run's damage, fire rate, speed, max HP, coins, Gems, dash cooldown
  and weapon range/pellets/orbs/swing, and reset with the run.
- Still to do: lobby place (Break Room -> the Base) as a second place, skinned walk cycles,
  particle textures, music, then the laptop step (import meshes, playtest, publish).
