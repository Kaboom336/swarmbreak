# Codex wave 11: surplus-budget queue (Zion 2026-10-02: use spare Codex, nothing wasted)
Base: integrate/wave8 e95bb4f (or main once wave 8 merges). Sources: research/BEST-OF.md, /mnt/project-files/swarmbreak-hunty-zombie-deep.md, swarmbreak-watch-round3.md.
Each task is independent; run 2 at a time. Rules: failing spec first, only listed files plus one new spec, no blood (goo teal/green), all prices 0, plain names, no new dependencies.
testcmd (every task): cd game && stylua --check src tests && selene src && lune run tests/run.luau && rojo build default.project.json -o out.rbxl

## B1 Difficulty tiers (Hunty SELECT panel needs it)
Shared/Difficulty.luau: Normal, Hard, Nightmare: enemy HP/damage/spawn-rate multipliers, reward multiplier, unlock rule (beat previous tier). Wire into wave spawner scaling.
Spec tests/difficulty.spec.luau: multipliers increase strictly by tier; rewards scale with risk; locked tiers rejected.

## B2 Three maps as data (Hunty "a different place per map", DRG caves)
Shared/Maps.luau: Station Deck (bright dusk), Hive Caves (DRG purple/teal, crystal lights), Overgrown Hangar (sunbeams). Each: lighting preset key, spawn points, prop list, boss. Layout generator reads it.
Spec tests/maps.spec.luau: every map has a valid preset, >= 6 spawns inside bounds, a boss, unique name.

## B3 Run XP bar + timer (Vampire Survivors)
Full-width XP bar at the bottom, top-centre run timer; reads from T8 level-up XP. Shared/HudLayout.luau entries.
Spec: bar fill = xp/needed clamped 0-1; timer formats mm:ss; no overlap with other HUD entries.

## B4 Ammo on the gun (DRG)
World-space SurfaceGui counter on each gun model (falls back to HUD ammo when no model). Shared/WeaponDisplay.luau maps weapon key to anchor part name.
Spec: every weapon in the weapon table has a display entry; low-ammo colour threshold.

## B5 Stacking items (Risk of Rain 2)
Shared/Items.luau: 12 passive items with linear or hyperbolic stacking (e.g. +10% fire rate per stack, crit chance hyperbolic). Offered as a card type in T8 level-ups.
Spec tests/items.spec.luau: stacking formulas monotonic; hyperbolic never reaches 100%; ids unique.

## B6 Weapon skins (Rivals)
Shared/Skins.luau + server equip/save: skin per weapon, rarity frame colour (Theme.Rarity), unlock via Gems or crates, prices 0. Skins change colours and materials only, never silhouette.
Spec tests/skins.spec.luau: every skin references a real weapon; rarity valid; equip rejects unowned.

## B7 Status cosmetics in lobby (Hunty #7)
Auras (particle presets) and title tags above heads in the Base only; unlocked by achievements/mastery. Shared/Cosmetics.luau.
Spec: each cosmetic has an unlock rule; auras obey VfxDefs rate cap.

## B8 Procedural weapon animations (Rivals)
Client: equip swing-in, recoil kick, reload dip, idle sway, sprint lower; tween values in Shared/WeaponAnim.luau.
Spec: all durations in sane ranges; recoil returns to rest; per-weapon overrides valid.

## B9 Enemy tells (Doors)
Shared/EnemyTells.luau: per enemy a warning (sound key, glow pulse, 0.4-0.8 s windup) before attacks; Spitter and bosses show ground AoE circle.
Spec: every enemy type has a tell; windup in range; tell colours warm, never player hues.

## B10 Combo counter
Kills within 2 s chain a combo; on-screen counter with tier names (x5, x10, x25); small coin bonus per tier. Shared/Combo.luau pure.
Spec: chain resets after window; bonus capped; tiers ascending.

## B11 World events (Fisch, Anime Vanguards)
Shared/WorldEvents.luau: timed events ("A hive has opened in Sector 3", "Double Shards for 10 min") with banner + countdown; server schedule picks one every N waves.
Spec: no two events overlap; durations positive; every event has banner text.

## B12 Save safety
DataStore wrapper: versioned save schema with migrations, retry with backoff, session lock, autosave + on-leave save; Shared/SaveSchema.luau.
Spec tests/saveschema.spec.luau: migrating v1->latest keeps currencies; unknown fields dropped safely; default profile valid.
Also add tests/no_toplevel_datastore.spec.luau: scan src/ text and fail if any GetDataStore/GetOrderedDataStore call sits outside a function or pcall at module top level (unpublished Studio places throw there; see e95bb4f).

Order: B12, B1, B2, B3, B9, B5, B10, B4, B8, B6, B11, B7.
