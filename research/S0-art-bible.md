# S0 Swarm Break art bible (2026-10-03)
Shown to Zion: https://claude.ai/artifact/J2MSVty9dHGRXpjbcuoPj1
Every S task cites this file. Where a choice isn't covered here, pick the option closest to Hunty Zombie's chunky stylized look.

## Palette (RGB, as Theme tokens)
Outpost (friendly world):
- OutpostCream 255,233,201: floors and buildings.
- OutpostShade 222,190,150: trims and edges.
- SignalOrange 255,138,43: friendly accents, bridges, lamps.

Hive (enemy world):
- Chitin 91,47,147: enemy bodies and hive growth.
- ChitinDark 62,31,107: enemy shells.
- Goo 46,230,197: enemy eyes, veins and kill bursts. Neon.

Players:
- Hero 61,165,255: players.
- Loot 255,210,63: gold for rewards and rare items.

Telegraph 255,61,110: danger and attack wind-ups only.

UI:
- UiPanel 42,33,86, with a UiStroke of 74,60,140.
- Text 255,247,236.

Sky: a dusk gradient from 255,179,122 at the horizon to 122,79,214 at the top. Cloud sea below.

Rules:
- Enemies always read darker than the floor, and players brighter than both.
- Neon is only for goo, weapons, pickups and telegraphs.
- No realistic textures: SmoothPlastic plus flat colour.

## Shapes
- Chunky and rounded, with bevels everywhere. Minimum part thickness 0.6 studs. No sticks.
- Friendly shapes are round: domes, capsules, fat pipes.
- Enemy shapes are spiky and segmented: shells, mandibles, spines.
- Silhouettes must read at 40 studs.

## Type and UI kit
- Fonts:
  - FredokaOne for titles and numbers.
  - GothamBold for body text.
  - LuckiestGuy for big banners (VICTORIOUS, LEVEL UP!).
- Panels:
  - UiPanel fill, a 3 px UiStroke, UICorner 14 px.
  - A soft drop shadow: a second frame offset +4 px, 50% black.
- Buttons:
  - Chunky pill shapes with a 4 px bottom "lip" in a darker shade.
  - Press: shrink to 0.95, then pop back.
- Scale: one UIScale = min(viewport.X/1920, viewport.Y/1080), clamped to 0.6-1.2. Every HUD element is laid out at 1920x1080 reference size.
- Icons: big simple glyph badges in circles.

## Animation timing
- Every attack: wind-up 0.15 s, strike 0.1 s, recovery 0.25 s. The enemy wind-up also lights a Telegraph decal on the ground.
- Hit react: a 0.08 s white flash and a 6° flinch. Kill: a 0.12 s squash, then a goo pop (Goo particles plus a decal). No ragdolls.
- Camera shake only on crits, kills of elites and bosses, and boss slams.

## World and map
Three floating islands joined by bridges. About 3x today's area.
- **Landing Pad**, waves 1-5: open and flat.
- **Refinery**, waves 6-10: ledges, ramps, jump pads, dash gaps, and a high loop route with XP pods.
- **Hive Core**, waves 11-15: boss arena and extract portal.

Bridges open at waves 6 and 11 (pending Zion's Q2; default yes). Landmarks: Beacon tower, Refinery stack, Hive spire.

## Enemy names (display; code keys unchanged)
- Mite (Swarmling)
- Crawler (Walker)
- Skitter (Runner)
- Spitter
- Drone (Flyer)
- Shellback (Tank)
- Big Brute (Brute)
- Swarm Queen (Queen)
- Sky King (Warden)
