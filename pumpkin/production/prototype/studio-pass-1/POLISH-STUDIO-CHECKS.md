# Meadow polish — Claude Studio verification

Open `slice-v2/prototype/guardian-greybox.rbxl` fresh (close the previous window). Backup: `guardian-greybox.pre-polish2.rbxl` beside it, byte-verified before Rojo. No commit or publish authorized. Cave untouched.

Polish2: both guard anchors are (-7,48,110) in map coordinates. A conservative radial-envelope check over 242 idle/patrol poses, every yaw and the full 3-stud arrival allowance leaves 3.6047 studs between Keeper and the 1.8x acorn. Check the actual idle/return movement in Studio; combat chase is outside this camp-rest clearance claim. Guard footprint has summit support; the nest remains in detection range. Nest/prompt positions and 9-stud activation range are unchanged. Beam is 4.4/1.8 studs before model scale, Brightness=3, LightInfluence=0, alpha .80/.62/0 with a five-second +/-7% width pulse. Only Nest has the beam. Inspect prompt/HUD readability at graphics 1/10 after the stronger palette; UI sources are preserved but visual acceptance remains UNKNOWN.

## Eight suites (required after this edit)

Play with the owner account so kits2 can load. Keep `CoreUseDataStore=false`. In the server Command Bar:

```lua
game:GetService("ServerScriptService"):SetAttribute("StudioPassAll", true)
```

Wait for `StudioPassBusy=false`, `StudioPassSuccess=true`, and `StudioPassResult` status PASS. Save the complete result JSON and Output errors to this directory. All eight `*StudioPassStatus` values must PASS:

1. GreyboxSelfTest
2. DropSampleTest — zero failures; save actual sample count (previous owner-reported run: 31,824).
3. GreyboxLoopTest — 3/3, at least one secure/place rather than all expiry.
4. GreyboxPvpTest
5. GreyboxTrapTest
6. CoreLoopTest — mock store; steal, secure, reveal, coins, save/load/index.
7. RavineTest
8. TunnelTest

Do not reuse the pre-polish green result as evidence. Offline PASS checks compilation and geometry/source parity only.

## Three camera shots (fresh Play after suites)

Use `workspace.CurrentCamera` in the client Command Bar, `CameraType=Scriptable`; coordinates below are absolute (Meadow origin 0,76,-360). Capture 16:9 with kits2 fully loaded, then inspect at phone size.

1. **Portal → summit**: `CFrame.lookAt(Vector3.new(0,81.5,-244),Vector3.new(0,140,-456))`, vertical `FieldOfView=45.75`. Summit beam must show above the hill from the portal; gold must read as the destination. First 30 studs of route mouths should read clearly. Beam should stay soft, paths distinct, grass saturated without clipping.
2. **Camp close-up**: `CFrame.lookAt(Vector3.new(19,138,-430),Vector3.new(-2,129,-459))`, `FieldOfView=35.1`. Check approved acorn silhouette at 1.8x asset scale, soft light/sparkles, quiet 31-stud camp radius, Keeper gold outline against turf. Keeper stays at proven scale because rig/throw sockets are fixed. Trigger idle/warn/chase/throw/lob/fan/stun/return; confirm animations and projectiles still align and prompts remain readable.
3. **Carried acorn / route mouth**: steal normally, then place camera 16 studs beside and 8 studs above the carrier root, look at root+Vector3.new(0,3,0), `FieldOfView=55`. Verify 1.2x asset scale, soft glow, no tall beam on carried/dropped loot; drop/regrab, knock/drop, recovery, secure/reveal, expiry and respawn must clean up old effects. Restore `CameraType=Custom` for traversal, confirm lane widths/cover and tunnel throws unchanged.

Save `POLISH-STUDIO-portal.png`, `POLISH-STUDIO-camp.png`, `POLISH-STUDIO-carried.png`. Verify portal/camp at graphics 1 and 10; keep no x-ray outline (`DepthMode=Occluded`). Do not adjust gameplay rules to make suites pass.

## Evidence and comparison

`POLISH-SBS.jpg`: original BEFORE images retained; AFTER re-rendered with the same portal/camp cameras from production builders plus approved acorn/Keeper native geometry. Shared proxy sun/ambient lighting; AFTER has a labelled brighter sky approximation. Imported kits2 meshes, Roblox atmosphere/post effects, PointLight glow, particles and Highlight are NOT reproduced; the beam is a tonemapped geometry proxy at neutral pulse width. Thus Studio saturation/effect quality, UI readability and all eight live suite results remain UNKNOWN after polish2.

Compared with the supplied `SBS-TOP-GAMES.jpg`: Grow a Garden uses one oversized bright focal object; Steal a Brainrot gives its hero clean ground and a strong silhouette. This pass follows that hierarchy. Remaining concern: the existing paving detail and large cover still contribute visual noise; they remain to protect the green gameplay baseline.

Lesson: when enlarging an objective, check posed geometry and arrival tolerance before placing its guard, because anchor-to-anchor distance misses clipping.
