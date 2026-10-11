# +1 Pumpkin Every Click: overnight build brief (2026-10-05)

Zion picked this game at 02:03Z. **Launch target: 3:15 PM ET today (19:15Z).** Branch `pumpkin/main`, folder `pumpkin/` (Rojo project, Lune tests). Swarm Break (`game/`) is parked; do not touch it.

Reference games (Roblox charts, Oct 2026):
- **+1 Stone Skipping**: the loop, the pass set, the number-heavy HUD.
- **Break and Steal an Egg**: the bright map and chunky UI.

Screens are in /mnt/project-files/roblox/research/r7-media/.

## The game in one line
Click to grow your pumpkin **+1 size**, push it down the hill, smash through walls for **Wins**, hatch pets that multiply your gains, rebirth, and unlock spookier zones.

## Core loop (numbers are starting values; keep them in Config.luau)
1. **Grow.** Each click or tap (or holding the GROW button) gives +1 Size × multipliers.
   - Rate limit: 10 clicks/s, enforced on the server.
   - The pumpkin is welded above the player's head and scales with Size (visual scale = 1 + log10(Size+1) × 1.5, capped at 12).
2. **Roll.** Step onto the zone's start pad to launch the pumpkin down a straight sloped track.
   - Roll speed and power come from Size.
   - The track has **walls every 50 studs**; wall HP grows ×1.6 per wall.
   - The pumpkin smashes a wall if its power ≥ the wall's HP; otherwise it stops there.
   - Server-authoritative: compute the result with a pure function first (`Roll.simulate(size, zone)` → walls broken, distance), then play it back as an animation of 2-8 s.
   - Wins = walls broken × zone win multiplier.
   - Size resets to 0 after a roll. That's the core tension: grow bigger, then cash in.
3. **Zones** (unlocked by total Wins):
   - Pumpkin Patch: 0;
   - Haunted Forest: 500, ×3 wins;
   - Graveyard: 5,000, ×10;
   - Witch Castle: 50,000, ×30.
   - Each zone has its own track and walls. The map art is placed by the Studio operator (see "Map"); code finds parts by name or tag.
4. **Pets (eggs).**
   - Eggs cost Wins and sit in each zone: Candy Egg (Patch) 100, Spooky Egg (Forest) 1,500, Bone Egg (Graveyard) 15,000.
   - Rarities: Common 60%, Uncommon 25%, Rare 10%, Epic 4.5%, Legendary 0.5%.
   - Each pet is a Size multiplier from ×1.2 (Common) to ×5 (Legendary), plus zone-tier scaling. Equip 3 (4 with the pass); multipliers add together.
   - Inventory cap 50 (100 with the Storage product). Delete / equip best.
   - Pets float and follow the player (simple bobbing parts or meshes, whatever is in ServerStorage.PetModels; placeholder neon spheres with faces if none).
   - Staged hatch reveal: egg shake → crack → flash → pet with a rarity-coloured glow (Rare and up get a longer show).
5. **Rebirth.**
   - Cost: 1,000 Wins × 2^rebirths.
   - Resets Wins, Size and zone unlocks, and keeps pets.
   - Gives +0.5× permanent Size multiplier per rebirth.
6. **Daily and social:**
   - a daily reward (7-day streak calendar);
   - a codes box (a server-side code list in Config, e.g. "SPOOKY" → 500 Wins, "RELEASE" → Lucky potion);
   - global leaderboards for Wins and Biggest Pumpkin (OrderedDataStore), on board parts in the lobby;
   - in-game leaderstats for Wins and Rebirths.
7. **Monetization** (placeholder IDs = 0 in Monetization.luau; Zion creates the real passes and products and fills in the IDs):
   - **Game passes:**
     - 2x Size: 199
     - Auto Click: 149
     - 2x Wins: 249
     - +1 Pet Equip: 99
     - VIP (chat tag, ×1.5 everything, VIP zone pad): 399
     - Fast Hatch / Triple Hatch: 149
   - **Dev products:**
     - Lucky Potion (10 min, 2× luck): 49
     - Size Boost (+10,000 Size now): 25
     - Win Pack: 99
     - Skip Wall: 39
   - Use MarketplaceService.ProcessReceipt correctly: idempotent, recorded in the profile before granting.
   - When an ID is 0, prompts are hidden. No pay-to-win beyond what the reference games do; there is no PvP.

## Look and feel (mandatory; read research/LESSONS-swarm-break.md and research/r6-ui-method.md)
- **Halloween-bright:** saturated orange, purple and lime on a dark-teal night sky. Cartoon, not horror. No blood or gore.
- **UI depth stack** on every panel and button (UIGradient face, a blue-shifted shadow frame, a top highlight, one UIStroke thickness of 3 everywhere, rounded corners of 12). Big chunky buttons of at least 56 px on mobile.
- **HUD:**
  - top centre: big Size and Wins numbers with icons;
  - left: Shop, Pets, Rebirth and Codes buttons stacked;
  - bottom centre: a giant GROW button (also any tap or click in the world);
  - right: a zone and next-unlock bar.
  - The HUD must never cover the pumpkin or the track centre.
- **Juice:**
  - a "+N" popup at the pumpkin on every click (pooled, rising, scale-pop);
  - the pumpkin squash-and-stretch on every grow;
  - wall smash: chunky orange debris parts (pooled, 0.6 s), a shake, a "+X WINS" burst and a sound;
  - milestone banners such as "SIZE 1K!";
  - the camera follows the roll with a slight FOV push.
- **Sounds:** use built-in rbxasset sounds only (clicks, pops, smash).

## Map (the Studio operator, not Codex)
- Codex only provides the logic and expects tagged parts. Each zone needs:
  - a `ZoneStart_<Zone>` pad;
  - a `Track_<Zone>` model whose walls are named `Wall_1..Wall_N` (the code can also generate wall parts along the track if missing);
  - an `Egg_<EggName>` stand;
  - a `ZoneGate_<Zone>` barrier.
  - The lobby needs `Leaderboard_Wins` and `Leaderboard_Size` boards.
- Codex must also ship a **code fallback map builder** (ServerScriptService/MapFallback): if those parts are missing, build a clean, simple, bright layout from parts (a hill track per zone, walls, pads, gates). The game must be fully playable without any Studio work.

## Data
- ProfileStore-style session-locked DataStore wrapper written in-house (no third-party require-by-ID).
- Autosave every 60 s and on leave, with retry and backoff.
- In Studio without API access, fall back to an in-memory store.

## Tasks for Codex (in order; T2-T4 can run in parallel after T1 merges)
All tasks share: `testcmd: cd pumpkin && stylua --check src tests && selene src && lune run tests/run.luau && rojo build default.project.json -o out.rbxl`
Keep all pure logic in `src/ReplicatedStorage/Shared/*.luau` with Lune specs. Roblox-only code stays thin.

- **T1 Foundation:**
  - Config, Monetization (IDs 0), the Data wrapper, the Remotes builder;
  - the server Grow handler with rate limit and multipliers, plus leaderstats;
  - the pumpkin-on-head visual;
  - the GROW button and click-anywhere input;
  - the "+N" popups;
  - a basic HUD (Size, Wins).
  - Specs: grow math, rate limit, multiplier stacking, the scale curve.
- **T2 Roll and zones:**
  - Roll.simulate (pure), the server roll flow, the playback animation, wall smash juice;
  - zones and unlocks, gates;
  - MapFallback builder.
  - Specs: simulate determinism, wall HP curve, wins math, zone unlock thresholds.
- **T3 Pets and eggs:**
  - egg purchase, weighted roll (pure, with seeded RNG for tests);
  - inventory, equip best, delete;
  - pet follow;
  - staged hatch reveal UI;
  - Triple Hatch and Lucky Potion hooks.
  - Specs: rarity odds (10k-sample within ±1.5%), multiplier sum, inventory cap.
- **T4 Economy and social:**
  - Rebirth (pure cost and multiplier);
  - daily streak (pure date math, UTC);
  - codes (pure, one use per player);
  - global leaderboards, the shop UI;
  - ProcessReceipt (idempotent);
  - pass effects wired in.
  - Specs: rebirth math, streak rollover and reset, code reuse blocked, receipt idempotency (pure ledger).
- **T5 Polish pass (after T2-T4):**
  - the UI depth stack on every panel;
  - mobile layout at 667×375 and 1920×1080, with no overlap (a pure HudLayout spec);
  - milestone banners;
  - settings (SFX on or off);
  - a first-60-seconds flow: arrow to the GROW button → "Grow to 10 then roll!" → arrow to the start pad → first wall smashed within 30 s.
  - Specs: HudLayout no-overlap at both sizes, every button ≥ 56 px on mobile.

## Done means
- The gate is green.
- The game is fully playable from the fallback map in Studio Play with no errors.
- The first wall is smashed within 30 s of joining.
- Zion can publish after filling in the pass IDs.
