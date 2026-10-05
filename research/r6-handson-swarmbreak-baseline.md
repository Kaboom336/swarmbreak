# R6 hands-on: Swarm Break baseline @ 5f826a4 (2026-10-05)

**How I played:** a clean build (no capture harness), played in Studio as a brand-new player:
- default profile, Starter Pistol;
- moved with WASD (virtual keys) and click-to-move, shot with the left mouse button;
- no teleports and no edits to HP or position.

The pad terrain was pasted back from LandingPad.rbxm, because the art-only terrain isn't in the build.

**Caveat:** the laptop screen was locked, so I drove the game through Studio's MCP input tools rather than a physical mouse. Screenshots are Studio play-window captures.

## First 60 s: what a new player sees

| Time | What happens |
|---|---|
| 0 s | **Lobby spawn** (`base-01`). Three large flat purple text boards: MAP SELECT, DIFFICULTY SELECT, STAGE SELECT (a 14-line list). Plain cylinders and blocks on a white floor, a washed-out sky. The HUD is all present: Gold 0 / Gems 40, LV 0, a "Waiting for players" banner, "Click to shoot" hint, 4 stat buttons and 3 right-side buttons (Q / $ / S). |
| 5–30 s | Nothing tells the player where to go. The **START HERE / "Stand for 3 seconds"** ring sits behind the boards and is only visible after turning around (`base-02`). The lobby rocks clip into the lobby edge. |
| Ring | Standing on it starts a 3 s countdown → teleport to the Landing Pad (stage 1). |
| +3 s | "starting" phase, 3 s. |
| +6 s | **Wave 1 fighting** (`base-03`). Four purple mites run up the runway from the north gate, **directly toward the player at the centre**. |
| +2–3 s | **First kill.** **Auto-fire with auto-aim kills on its own; no aiming is needed.** |
| +3 s | **First reward:** a level-up card panel (3 cards with Banish / Reroll / Skip) pops over the fight (`base-04`). It auto-picks after 8 s. |
| ~12–15 s per wave | Each wave is 4 small packs. "Alive 0" fires 4 times about 3 s apart. "WAVE CLEAR +10 GOLD" banner, then a 12 s shop intermission ("Shop open 12s"). |

**First kill at roughly 8–9 s after the teleport. First reward roughly 1 s later.**

## Pacing (measured from the client log, 3 consecutive stage 1 runs)

| Phase | Time |
|---|---|
| Wave 1 fighting | 12.6 / 12.6 / 12.8 s |
| Wave 2 fighting | 12.8 / 11.2 / 12.4 s |
| Wave 3 (finale) | 22.8 / 22.8 / 24.9 s |
| Intermission | 12.1 s |
| Starting countdown | 3 s |
| Chest | 2.2 s, then "Victorious" |
| Whole stage 1 | ≈ 80 s from teleport to the Victory screen |

**After "over", the run restarts by itself about 30 s later**, so an idle player loops stage 1 forever.

**Finding:** a player who never touches the mouse still wins stage 1, because auto-fire and auto-aim do everything. There's no failure pressure in the first 80 s.

## One hit, frame by frame

What I could measure on the client while holding the fire button through wave 1, from instances added and the camera log:
- **Enemy on spawn:** a BillboardGui health bar plus a Highlight outline (the outline appears 0.1 s after spawn and lasts about 1.4 s, then goes).
- **Per shot:** no new particle or spark instances appeared on the client, so the hit VFX are pooled (not visible in the add-log). The screen shows a thin tracer and a small cyan or white spark.
- **Kill:** **CoinDrop and XPDrop parts** spawn at about 0.35 s and are picked up about 6 s later (magnet). A small radial streak burst (seen in art-final2).
- **Damage numbers:** none seen.
- **Hit-freeze:** none measured.
- **Camera:** distance 12.3–13.7 studs and FOV fixed at 70 during the fight. **No measurable shake or punch on hit or kill.**
- **Sound:** one Sound added per enemy spawn and one global Sound at the start.
- **Average enemy lifetime:** 2.6 s from spawn to death.

## Controls and HUD
- **Desktop:**
  - fire: click or hold (with auto-aim);
  - dash: Q (shown as "DASH 1 Q"), grenade: E (FRAG);
  - cards: 1/2/3;
  - shop: $, quests: Q, settings: S;
  - Reaper kit (if owned): R for the ultimate.
- **HUD:**
  - top: a bar showing LV, WAVE, "N LEFT" and a timer;
  - top left: currency;
  - bottom centre: an HP bar;
  - bottom left: loadout tiles;
  - bottom right: 4 stat-upgrade tiles.
- I didn't test mobile; the emulator isn't reachable while the screen is locked.

## Progression and return hooks
- Gold and Gems, level-up cards each level, and a wave-clear gold bonus.
- An end-of-run chest (a "Gem" crate with a weapon unlock).
- 15 stages × 3 maps, with difficulty tiers unlocked by clearing.
- A daily modifier ("Today: Double Coins" / "Big Bosses").
- Quests and shop buttons.
- No daily-login popup or codes box seen in the first minutes.

## Look vs the references
- **Arena:** the kit models are cohesive (see the art-final2 scores).
- **Lobby:** still primitive: flat text boards, cylinders, and no lighting accents.
- **Enemy readability:** good. Saturated purple mites against the warm pad.
- **Hit feel:** very weak compared with the references (see `r6-tiktok-refs.md` and `r6-ai-dev-videos.md`):
  - no damage numbers;
  - no camera punch;
  - no hit-freeze;
  - small effects.
