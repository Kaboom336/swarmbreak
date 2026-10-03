# Codex wave 16: kits as classes, evolutions in the run

Base: integrate/wave13 304165d (H7 lobby and p2-01..04 merged). J1 first, then J2 on J1's result.

## Rules (every task)
- Failing spec first. Touch only the listed files plus one spec.
- Runtime-safe APIs only; lint_runtime_apis must pass.
- Sibling client modules always load with script.Parent:WaitForChild. List in RESULT every Instance path the code waits on.
- No blood: goo is teal or green. Prices stay 0. Plain names. No new dependencies.

testcmd: cd game && stylua --check src tests && selene src && lune run tests/run.luau && lune run ../tools/lint_runtime_apis.luau && rojo build default.project.json -o out.rbxl

## J1 Kits become real classes
- In Shared/Kits.luau, give each Kit:
  - a StartWeapon (an id from Weapons.luau);
  - a Signature: one active ability on E (gamepad ButtonX; Q stays Dash), with a cooldown, built from existing CombatEffects;
  - its existing Mods as its passive.
- The four kits: Soldier (rifle, frag burst), Brawler (melee, ground slam), Engineer (turret drop), Medic (heal pulse).
- PlayerData starts the run with the kit's StartWeapon and binds the Signature.
- The HUD shows the ability icon and a cooldown ring next to Dash.
- The lobby picker (H7) shows class name, blurb, weapon and ability. If H7 is missing, show these in the existing kit UI.
- Unlock price is 0.
- Spec tests/kits.spec.luau: every kit has a valid StartWeapon and Signature; the cooldown blocks a second cast; the run starts with the kit's weapon.

## J2 Evolutions inside the run
- When the equipped weapon is at its max card level and the matching passive card is held, the next level-up offers an EVOLVE card.
- The EVOLVE card gets a gold border through CardStyle and plays the evolve effect.
- Recipes live in Shared/Evolutions.luau as a pure table (weapon + passive -> evolved). Reuse the shop evolution stats.
- Cards that complete a recipe show a small "evolves" badge.
- A lobby/codex "Recipes" tab lists every recipe; recipes not yet found show as "???".
- Add an evolve_in_run telemetry funnel line.
- Spec tests/evolutions.spec.luau: EVOLVE is offered only when both conditions hold; it is offered only once; picking it swaps the weapon stats.
