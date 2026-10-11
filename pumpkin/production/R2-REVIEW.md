# R2 Review: giant/src e41715d..HEAD (launch blockers and high severity only)

No hard launch blocker found in static review. Remotes (DailyStatus, ClaimIndex), scythe part budget, removed-name references and joint restore logic checked and look sound. Findings below are ranked.

## H1 (High, needs Studio verification) Play-area rescue can loop-teleport legit players
- ServerScriptService/Patch.server.luau:10040-10131 (`Helpers.inPlayArea`, 0.25 s Heartbeat -> `Helpers.recover`)
- Scenario: regions are built only from `garden.Ground` bounds (CanCollide parts, +/-2 studs X/Z, Y -18..+100). Pens (`Soil` is a separate floor in `Bases.safeLanding`, line 2178), the throne/King arena, market, or any elevated platform that lies outside the Ground AABBs makes `inPlayArea` false. The player is yanked to spawn every 0.25 s and drops stolen pumpkins (`Bases.dropStolen`) each time. If spawn itself is outside, `findLanding` returns nil and the player is silently stuck outside the invisible barriers.
- Fix: include `patchFolder` Soil parts and throne/market floors in `regions`, or add a 3-strike grace (only recover after 1.5 s outside). Print a warn when a spawned character is outside. Smoke-test: walk to every pen, throne, market, zone gate.
- Also: the barrier shell is derived from the union AABB, so any "Ground" child with a stray far-away part inflates all four walls.

## H2 (Medium-High) Camera forced to Custom every second
- StarterPlayerScripts/Patch.client.luau:8690-8714 (`restoreCamera`, Heartbeat 1 s, `CurrentCamera` signal)
- Scenario: any Scriptable-camera effect (Giant.client.luau:508/533 uses Scriptable; any future King or hatch cutscene) is stomped within 1 s, and it also fires `CameraMaxZoomDistance` writes.
- Fix: drop the 1 s polling loop. Keep CharacterAdded plus `CameraReset` attribute only, and skip if `camera.CameraType == Scriptable` while a cutscene flag is set.

## M1 (Medium) Unguarded nil on AnimationConstraint
- Patch.client.luau:4493-4495 `j.Attachment0.CFrame.Rotation` inside `track()`.
- Scenario: a rig whose AnimationConstraint has no Attachment0 (custom or loading avatar, accessory-like constraint named RightElbow, etc.) throws inside `PreSimulation` (line 4692), aborting the loop for ALL players that frame, repeatedly. Every swing animation for everyone dies.
- Fix: `if j:IsA("AnimationConstraint") and not j.Attachment0 then continue end`. Wrap `track(tool)` in pcall in the per-player loop (line ~4694).

## M2 (Medium) Per-frame cost / quality
- Patch.client.luau:4429 `UserSettings():GetService(...)` runs every frame during every tracked swing; cache once.
- Patch.client.luau:8599-8640 HUD Heartbeat does `pen:GetDescendants()` 4x/s on the whole pen. Cache via DescendantAdded or only check on `CarveAt` attribute changes.
- Patch.client.luau:4692 loop calls `track()` for every player within 80 studs each frame, which allocates per `carried()` call. Fine for small servers, watch at 20+ players.

## M3 (Medium) Infinite-yield risk
- Patch.client.luau:2097 `ReplicatedStorage:WaitForChild("PatchScytheIcons")` and `:WaitForChild(tool.id)` (inside task.spawn, so no load block; only a warn and a blank card). Server creates the folder at Patch.server.luau:6963, but a buildScythe `assert(count < 40)` failure for any tier aborts the whole scythe `do` block, including tool grants. Part counts computed by hand (king 38, candy 36) pass; any future style edit can break all scythes. Add a pcall around icon creation.
- Patch.client.luau:6998/7009 `WaitForChild("DailyStatus")` is pcall-wrapped; fine.

## Checked, no issue
- DailyStatus (Patch.server.luau:7785) is read-only, gated by `isLoaded`; no client-trusted reward. ClaimIndex dedupes server-side and pays from server `Income` (unchanged logic).
- Joints: `release()` on Unequipped, Died, CharacterRemoving, and distance cull restores Transform and Grip; connections disconnected. `idleGrip` and `chains` are weak tables.
- ScytheHitArc pool is fixed (3 rigs), no per-hit instance leak. Viewport cap 40 with Destroying decrement; outline clones are destroyed with the parent view.
- Removed names: World2 portal block removed on the server, `Config.World2` still defined; `HoardLeashPad` still defined, only unused in the chase condition; `Bases.safeLanding` kept; `Bases.findLanding` and `Helpers.inPlayArea` defined at the end of the file but only called at runtime, so ordering is fine.
