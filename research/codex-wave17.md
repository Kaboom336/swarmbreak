# Codex wave 17 (V): the visual wave

Base: integrate/wave13 d3e85db or later. Order (one at a time): V1, V2, J2, V3, V4, V5. Each later task's clone is the
integrate/wave13 head at its start, merged with the previous task's branch if it is not merged yet.

## Rules (every task)
- Failing spec first. Touch only what the task needs plus its spec.
- Runtime-safe APIs only; lint_runtime_apis must pass. No settings(), no Lighting.Technology writes.
- Sibling client modules always load with script.Parent:WaitForChild. List in RESULT every Instance path the code waits on.
- No blood: goo is teal or green. Prices stay 0. Plain names. No new dependencies.

testcmd: cd game && stylua --check src tests && selene src && lune run tests/run.luau && lune run ../tools/lint_runtime_apis.luau && rojo build default.project.json -o out.rbxl

## V1 Arena colour, high contrast
- Arena floor: saturated deep violet (about 70,40,140). Add 3 or 4 wide, bright lane stripes radiating from the centre, in neon teal and amber (Neon material, thin, CanCollide false).
- Walls and props: pastel lilac and white blocks. Keep H1's open, readable space.
- Enemy bodies: pale (white, lilac, pale green). Keep the Theme accents on eyes and backs.
- Lighting: a bright preset (ClockTime about 14), low Atmosphere density, and a soft purple-pink Atmosphere colour.
- Put all of it in LightingPresets and Theme as data. The lobby keeps its own preset.
- Spec: floor-to-enemy luminance contrast is at least 0.35 for every enemy type, computed by a pure function in Theme.

## V2 Level-up card chrome (on top of H9's CardStyle)
Each card shows:
- A big icon glyph at the top.
- A coloured category bar: WEAPON red, PASSIVE blue, ELEMENT in the element's colour, UPGRADE green.
- Its name coloured by rarity.
- The effect line in RichText, with keywords coloured (fire, chain, pierce, slow, heal and the like).
- A stat tag with a green up arrow in a corner.
- An "Lv N" badge at top right.

Buttons under the 3 cards:
- REROLL: 1 free per run, plus 1 more every 5 levels.
- SKIP: gives back +10% XP.
- BANISH: 2 per run. Removes that card from this run's pool.

The selected card gets a bright border. On the server, reroll, skip and banish go through PickReward's guard, as new actions in WaveRewards and LevelUp.
Spec: counts and limits hold; a banished id never returns in that run; a reroll never repeats the same 3 cards.

## J2 Evolutions inside the run (after V2; uses V2's card chrome)
- When the equipped weapon is at its max card level and the matching passive card is held, the next level-up offers an EVOLVE card. It has a gold border via CardStyle and plays the evolve effect.
- Recipes go in Shared/Evolutions.luau as a pure table (weapon + passive -> evolved). Reuse the shop's evolution stats.
- Weapon cards show a "CAN EVOLVE INTO" strip under the card, with the evolved weapon's icon. Cards that complete a recipe get a gold "EVOLVES" tag.
- A "Recipes" tab in the lobby/codex lists every recipe. Recipes not found yet show "???".
- Telemetry: an evolve_in_run funnel line.
- Spec tests/evolutions.spec.luau: EVOLVE is offered only when both conditions hold; it is offered only once; picking it swaps the weapon stats.

## V3 HUD build view
- Top: a thin, full-width XP bar along the very top edge. Under it, centred, "LV n", "WAVE n" and a wave/boss progress bar.
- Bottom left: the weapon row. The equipped weapon is in slot 1, then its evolved or element state. Square slots with a level number and a rarity border.
- Bottom right: the passive row, one slot per upgrade family, stacked with its level number.
- Bottom centre: a big HP bar showing current / max.
- Currencies stay on the left as one column of big icons.
- Move the existing elements; do not duplicate them. HudLayout stays pure.
- Spec: nothing overlaps at 1366x768, at 1920x1080, or in phone safe areas.

## V4 Swarm density with scale contrast
Add Swarmling, a cheap crowd enemy:
- No Humanoid. One body part plus 2 limb parts, about 6 studs tall.
- Pale colours, dies in 1 or 2 hits, does low damage.
- The server moves all of them in one batch loop with workspace:BulkMoveTo, steering toward the nearest player in the run. Reuse EnemyAI's targeting rules (InArena, WaitingForIntermission).
- Bob and limb swing come from EnemyAnimCurves on the client.
- Drops XP only. Goes through EnemyIndex and FxRouter like the other enemies.

Waves and caps:
- Swarmlings start at wave 2, in streams of 10 to 20 from the portals.
- Cap: MaxAlive 60 regular enemies, plus a separate cap of 100 swarmlings.
- Elites: Tank and Brute are 1.3x their current height. Bosses are 1.2x. Keep the Fit width caps.
- Perf spec: a pure step function advances 100 swarmlings in one batch call.
- RESULT must say to check FPS in the next capture.

## V5 Extraction ending and Bail Out
When the boss of the final normal wave dies:
1. A "VICTORIOUS" banner.
2. An extract portal ring appears near the centre. Standing in it for 20 s extracts you while the swarm keeps spawning.
3. An "EXTRACTED!" screen shows a big reward multiplier (1.0, plus 0.1 per wave, plus a no-death bonus), coins and gems, and the buttons Play again and Return to lobby. Return sets InArena false and sends the player to the lobby spawn.

Bail Out: a round button on the right (key B; Q stays Dash). Holding it for 1.5 s leaves the run, keeps 50% of that run's rewards and goes to the summary.
Infinite mode stays available; taking the portal is the choice to stop.
Spec: the multiplier maths; the bail-out share; the portal timer; the portal is offered only once.
