# Swarm Break (Roblox) - Rojo project

Wave-survival shooter: double jump, dash, 15 waves with a boss every 5, then infinite mode.
Plan: ../GAME-PLAN.md. Zion's steps: ../PUBLISH-GUIDE.md and ../MONETIZATION-SETUP.md. Laptop setup for Claude: ../LAPTOP-SETUP.md.

## Layout
- `default.project.json` - Rojo tree. Remotes and the replicated `State` values are declared here, not in code.
- `src/ReplicatedStorage/Shared/` - pure data + math, no Roblox globals, unit-tested:
  Config, Enemies, WaveTable, Weapons (rarity + crate roll), Upgrades, Economy, Monetization (IDs).
- `src/ServerStorage/` - EnemyBuilder (part-built rigs with Motor6Ds per enemy type and boss),
  EnemyAI (pathfinding chase / flying / ranged / summoning), WeaponModels (held weapon models per rarity),
  PlayerData (coins, upgrades, owned weapons, passes, DataStore best wave + global top list), GameState.
- `src/ServerScriptService/` - WaveManager (game loop + spawn/boss effects), Combat (hitscan, melee cones and
  slams, beams; server-validated), OrbitalRunner (orbiting blades/suns), Shop (upgrades, equip, purchase
  prompts, ProcessReceipt), ArenaBuilder (lighting, materials, neon, props, portals), Leaderboard (wall board).
- `src/StarterPlayer/StarterPlayerScripts/` - Movement (double jump, dash charges, mobile button, feel),
  Shooting (mouse / touch / gamepad), Hud (wave, boss bar, HP, vignette, shop, hotbar, crate reel), BossIntro,
  HitMarkers, ClientFX (sounds, shake, FOV, particles), Effects (renders every server FX event), EnemyAnimator.
- Weapon catalog: 15 weapons in `Shared/Weapons.luau`: guns (hitscan), melee (cone swings, ground slam, lunges),
  orbitals (blades/suns circling you) and a sweeping beam. Art style and theme: `Shared/Theme.luau`.
- `src/Workspace/Arena/` - v1 arena as model JSON: floor, two towers with steps, ledge, pillar, walls,
  8 enemy spawns, boss spawn, player spawn, leaderboard wall.
- `tests/` - Lune test runner + specs for the Shared modules.

## Checks (run anywhere, no Studio)
```
stylua --check src
selene src
lune run tests/run.luau
lune run ../tools/content_audit.luau
lune run ../tools/lint_runtime_apis.luau
rojo build default.project.json -o out.rbxl
```
`selene.toml` uses `roblox_min.yml` (a small global list) because the full Roblox std needs a GitHub download.
On the laptop, switch `std = "roblox"` in selene.toml for the real API dump.

Codex tasks on this repo: `testcmd: cd game && stylua --check src tests && selene src && lune run tests/run.luau && lune run ../tools/lint_runtime_apis.luau && rojo build default.project.json -o out.rbxl`

## CI

GitHub Actions runs formatting, lint, unit tests, and a Rojo build on every push and pull request. The workflow uses
the tool versions pinned in `../rokit.toml`, including Rojo 7.4.4. Run the same gate locally from this folder with:

```
stylua --check src tests && selene src && lune run tests/run.luau && lune run ../tools/lint_runtime_apis.luau && rojo build default.project.json -o out.rbxl
```

## Run in Studio (laptop)
1. `rokit install` in this folder (installs rojo, selene, stylua, lune).
2. `rojo plugin install`, then `rojo serve`.
3. In Studio: Plugins > Rojo > Connect. Press Play.
4. After the first Publish: Game Settings > Security > "Enable Studio Access to API Services" (DataStores).

## Licenses
Rojo, Wally, Selene, StyLua, Lune: MPL-2.0 / MIT. No third-party assets yet; every enemy, weapon and arena piece is
plain parts made in code. Add any Creator Store or CC0 asset to ASSETS.md with its license link before use.
