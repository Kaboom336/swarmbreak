# S1 runtime acceptance — UNKNOWN until run

Open canonical `slice-v2/prototype/guardian-greybox.rbxl` fresh. Round-2 restore point: `guardian-greybox.pre-s1r2.rbxl` (SHA256 D639550E06F4A0CC90527EA63C5E86D3B1D60DE2E127BDFA292C0A2EAA1995CB). No commit/publish. Run as asset-owning account; keep CoreUseDataStore=false.

In server Command Bar: `game:GetService("ServerScriptService"):SetAttribute("StudioPassAll",true)`.

Require StudioPassBusy=false, StudioPassSuccess=true, and all eight statuses PASS: GreyboxSelfTest, DropSampleTest (save actual count, zero failures), GreyboxLoopTest (3/3 including a secure/place), GreyboxPvpTest, GreyboxTrapTest, CoreLoopTest (mock), RavineTest, TunnelTest. Save the complete JSON and Output errors. Prior pre-polish green is not current acceptance evidence.

With kits loaded, inspect MeadowV4's S1KitsLoaded == S1KitsExpected. All S1 models use existing kits2 manifest IDs. No missing-template fallback should be accepted visually. Walk each departure and return through pool; prove the unchanged portal trigger still communicates correctly through its new art. Check floor contacts at graphics 1/10, labels from both approach directions, no lamp/flower clipping and no residual native/kit duplicates.

Client camera, Meadow origin (0,76,-360):

```lua
local c=workspace.CurrentCamera
c.CameraType=Enum.CameraType.Scriptable
c.FieldOfView=45.75
c.CFrame=CFrame.lookAt(Vector3.new(0,81.5,-206),Vector3.new(0,100,-456))
-- overview, vertical FOV 32.27:
-- c.FieldOfView=32.27
-- c.CFrame=CFrame.lookAt(Vector3.new(92,164,-155),Vector3.new(0,80,-238))
```

Capture arrival and overview, also phone aspect and graphics 1. Restore CameraType.Custom before playing. Judge visible route choices and summit beam, cared-for garden grouping and portal readability. Offline render uses native geometry + original S1 FBX meshes; other sections retain native kit proxies. Beam is explicitly approximated, not Roblox VFX. Runtime/visual approval remains UNKNOWN until this checklist is completed.
