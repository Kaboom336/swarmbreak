# Q4: Zion's playtest says "mid". Codex-only rebuild (Claude is paused until Wed 10/7)
Zion's notes: the loop is boring; the hill needs to be steeper and faster; dodge obstacles with a combo; the UI is bland; colours look dead; the models are boring; the map should be enclosed with better models; the pumpkin floats instead of rolling; you can jump off it; the player should be inside or holding on.

Run these in order: Q4-R, Q4-AUDIT, Q4-A, Q4-B, Q4-C, Q4-D, Q4-E. Each task merges only when the gate is green. testcmd for every task: cd pumpkin && stylua --check src tests && selene src && lune run tests/run.luau && rojo build default.project.json -o out.rbxl

## Q4-R: research first (writes pumpkin/research/Q4-REFERENCES.md, no code)
- Pick 5 top Roblox roll, slide or downhill games and +1 simulators on the charts now: for example +1 Stone Skipping, Break and Steal an Egg, slide/roll "obby race" downhill games, and Mega Marble or ball-rolling games.
- For each: how the player rides (inside a ball, holding on, or seated); camera; speed (studs/s); obstacle and dodge design; combo rules; UI palette (hex values); map enclosure (walls, canyons, tunnels); particle and sound juice.
- End with a table, "we do / they do / change", and a palette of 6 saturated colours.

## Q4-AUDIT: review every detail (runs after Q4-R, before Q4-A)
- Audit every system, screen, parameter, model, colour, sound, camera, animation, text label and timing in pumpkin/ against the Q4-R references.
- Log each issue in pumpkin/research/Q4-AUDIT.md as one row: area, what's wrong, what the reference does, the fix, severity (P1/P2/P3), and which Q4 task fixes it.
  - Cover: the first 60 s for a new player, the click feel, growth visuals, the ride, rewards, pets and eggs, the shop and passes, the HUD on desktop and mobile, sounds, the map, performance and mobile controls.
  - Aim for 60+ rows.
- Write a reusable "Roblox game-feel and quality checklist" section into PLAYBOOK.md at the repo root. It covers look, play, feel, juice, UI, onboarding, economy, monetization and mobile, with concrete numbers.
- Q4-A through Q4-D must each fix every audit row assigned to them. Unassigned P1/P2 rows become Q4-E: fixes.

## Q4-A: real rolling and the rider
- The pumpkin is a physics-looking ball that rotates around its axle by distance ÷ radius every frame, on both client and server. No floating: it is ground-snapped to the track surface with a raycast.
- The player is INSIDE: the character is hidden, and the camera sits behind and above. Show a small avatar head in a window cut-out (a BillboardGui headshot) OR make the pumpkin semi-transparent with the character inside. Pick whichever reads better from Q4-R.
- Jump is disabled during a ride (JumpPower 0 plus the seat locked); the player can't leave until the end.

## Q4-B: a steeper, faster hill with dodging and combos
- Rebuild the track as a steep downhill chute: an 18-25° slope with banked turns, built from Parts in MapFallback and kept enclosed (walls 12+ studs high, a tunnel section, a canyon).
- Speed is 60 studs/s at the start, rising to 140 or more; FOV rises with speed; add a speed-lines particle effect.
- Obstacles to dodge (seeded, server-validated like pickups): rolling logs, tombstones, low fences. A hit costs 20% speed and resets the combo.
- Combo: each clean dodge or pickup gives +1. The multiplier ×1.1 per combo step, capped at ×3, applies to the ride wins. Show a big combo meter with a pop.
- The ride lasts 10-14 s. Specs: the obstacle layout is deterministic and fair (always one free lane), plus the combo math and cap.

## Q4-C: UI and colour punch
- Use the Q4-R palette: saturated orange, purple and lime with dark outlines. Buttons get a thick stroke, a bounce on press, and a shine sweep. Numbers are bigger, with a gradient on frames only, never text.
- World: Lighting ColorCorrection Saturation +0.25, Contrast +0.1, slight Bloom, warmer sun. The ground and walls get stronger hue contrast.

## Q4-D: models and map
- Replace the plain blocks along the track with themed props built from Parts and Unions: jack-o'-lanterns, fences, gravestones, a candy arch, lamp posts with PointLights.
- The track is enclosed by walls and cliffs. The lobby is a compact plaza with a big start ramp in view.
- Never insert store items that carry scripts.

Done: the gate is green on each task, then Play captures after Wed 10/7 21:00Z for the judge round.
