# Codex R1: wire in the new Nest enemy rigs (2026-10-04). Follow game-bible-v2.md
Base: integrate/wave13 head merged with art/mite-rig (cbd985b) and with L1 if L1 has landed. One branch.

Rules:
- Runtime-safe APIs only.
- Failing spec first.
- WaitForChild for sibling client modules.
- No blood.

testcmd: cd game && stylua --check src tests && selene src && lune run tests/run.luau && lune run ../tools/lint_runtime_apis.luau && rojo build default.project.json -o out.rbxl

## Inputs
- game/assets/rigs/<Role>.rbxm plus <Role>.json for Mite, Runner, Shooter, Tank and Flyer.
  - These were made with Studio's generate-mesh tool and rigged on the laptop. The Tank is being regenerated (its legs came out as wheels), so keep it swappable.
  - Rojo 7.4.4 can't read the .rbxm files. Keep them out of default.project.json.
- The laptop uploader (wave 8) uploads each .rbxm as a Model asset. The ids go in Shared/ModelAssets under the keys `enemies/Mite`, `enemies/Runner`, `enemies/Shooter`, `enemies/Tank` and `enemies/Flyer`.
  - Add these keys with 0 now. The existing ModelLibrary LoadAsset path loads them once they're non-zero.

## Rig contract (from the JSON)
- **Root:** Body is the PrimaryPart and is anchored in the file. Unanchor it on spawn and weld it to the enemy root.
- **Motor6Ds** (Part0 is Body unless noted):
  - Neck goes to Head.
  - Hip_1..Hip_n go to Leg_1..Leg_n.
  - Shooter has SacJoint.
  - Flyer has WingJoint_L and WingJoint_R, and a `HoverHeight` attribute of 8.
- **Eyes:** two Eye_Glow parts are welded to Head. They share a name, so iterate by class, not by name.

## Work
1. **Role mapping:** Shared/EnemyFamilies maps Nest roles to rig keys:

   | Role | Enemy type | Rig |
   |---|---|---|
   | Swarmer | Walker | Mite |
   | Runner | Runner | Runner |
   | Shooter | Spitter | Shooter |
   | Tank | Tank | Tank |
   | Flyer | Flyer | Flyer |

   Brute and Queen keep their current models for now.
   - EnemyBuilder prefers the rig. When the asset id is 0 or the load fails, it falls back to today's model.
   - Scale each rig to the bible size bands using the Enemies Size height; don't stretch it unevenly.
2. **EnemyAnimator rig mode,** all on the client and pooled:
   - **Hip_n leg cycle:** alternate tripod gait (odd and even legs in antiphase), lift 20-30°, rate scaled by speed using the existing WalkProfiles.
   - **Neck:** bob and look-at toward the target, ±20° yaw.
   - **Attack:** wind-up pull-back, then a lunge. Use the existing AnimCurves enemyAttackAt.
   - **Shooter:** SacJoint pulses before each spit (scale 1 to 1.25 to 1).
   - **Flyer:** WingJoint flap at 14 Hz with a ±35° pitch, plus a hover bob of ±0.5 studs around HoverHeight.
   - **Eyes:** Eye_Glow flickers brighter during the attack tell, and dims to 0.4 on death.
   - **Death:** the existing squash, goo pop and dissolve still work on rig models.
3. **Spec:**
   - Parse each rigs JSON (lune can read it) and check that it has Body, Head, Neck, at least 4 Hips with matching Legs, and 2 Eye_Glow.
   - Check the role mapping covers all 5 roles.
   - Check the gait phase table puts odd and even legs in antiphase.
4. **Result:** list the asset ids the uploader needs to fill, plus the shot list the Play thread should retake (04 wave pack, 05 crowd, 07 enemy closeups, clip c3 enemy walk).
