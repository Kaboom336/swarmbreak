# Meadow v4 isolated merge

The guardian/Keeper scripts and `slice-v2/prototype/guardian-greybox.rbxl` were not edited or rebuilt by this job. The standalone place is `prototype/meadow-v4.rbxl`; its Keeper is decorative and its Home links have no economy or combat.

## Exact geometry switch

After registering the three modules below in `ReplicatedStorage.MeadowV4`, add this single line immediately before `return Scene` in the existing `Scene.luau`:

```luau
Scene.meadow = require(game:GetService("ReplicatedStorage").MeadowV4.Loader).wrap(Scene.meadow)
```

The one flag is Workspace attribute `UseMeadowV4 = true`; false/nil uses the existing geometry. The adapter clears old terrain at the existing Meadow art-loader call and preserves Arena handles. It removes the test Keeper stand-in from the new art. This line is supplied for the later merge; it has **not** been applied to the active guardian source.

Files to register/copy:

- `prototype/meadow-v4/MeadowV4.luau` → `ReplicatedStorage.MeadowV4.Builder`
- `prototype/meadow-v4/MeadowV4Data.luau` → `ReplicatedStorage.MeadowV4.Data`
- `prototype/meadow-v4/Loader.luau` → `ReplicatedStorage.MeadowV4.Loader`

Register them using the `$path` entries in `prototype/meadow-v4.project.json`. Do not include `Links.server.luau`, `Camera.client.luau`, the Home spawn, or the prebuilt Workspace model in the guardian project.

## Required gameplay migration before enabling that flag

The switch replaces geometry; it cannot safely migrate the older hardcoded gameplay coordinates. The Keeper job owns those changes. Existing Arena/Server/Layout code uses summit Z32, portal Z-58 and a 160 island. New **spec** coordinates (X,Z,Y) are summit `(0,108,24)`, portal `(0,-136,0)`, envelope ±176; world local XYZ is `(X,Y,-Z)`. Retain the existing Meadow world origin.

Migrate pickup/nest, live Keeper camp/return, spawn/last-safe, drop sockets, safety checks, outside bounds, patrol/recovery waypoints and client camera/portal labels together. Protected rectangle: X[-24,24], spec Z[-156,-116]. Actual slots must come from reachable surfaces, excluding apron and jump-only decorations. Guardian sweep size must be measured before accepting eighteen-wide routes. Old Layout recipe validation is not a validation of v4 geometry.

Do not enable the flag in the gameplay place until those migrations and `STUDIO-CHECKS.md` pass. This package intentionally makes no claim that one line alone completes gameplay integration.

## Rebuild the isolated place

From production: run `prototype/meadow-v4/geometry.py` with Python, then `rojo build prototype/meadow-v4.project.json -o prototype/meadow-v4.rbxl`. Run `audit.py` and Blender `--background --factory-startup --python prototype/meadow-v4/render.py -- 4`. `compare.ps1` composes the evidence contact sheet; on this machine run its contents as a script block without changing the execution policy.

Source edits use apply_patch. Data/model exports, place builds and proof images are generated artifacts. No commit, upload or imported asset dependency. Existing native project helpers were inspected; native primitives and authored parts are reused, with no external licence added. The exact Keystone Playbook was unavailable in checked local sources; supplied greybox, real-art and reference review rules were applied without claiming it was read.
