# SCYTHE PROPOSAL B: swing animation and feel (procedural, no Animation assets)

Arena round 2, angle B. Author: proposer B. Scope: the client-only hold pose, 3 swing variants, trail, slash arc, and R6 support. The scythe model and Grip stay as built by `buildScythe` (Patch.server.luau 6984). Codex implements this in the Scythe block of Patch.client.luau (3732-3992).

## 1. What is wrong now (read from the code and the swing screenshot)

1. **Idle is the default `toolnone` "zombie arm".** The right arm sticks straight out and the left arm hangs dead (screenshot ...exo1d2.jpg). No real game holds a big weapon like this.
2. **Only one joint moves.** `swingTool` rotates only the right shoulder C0, by `pitch*0.55 / roll*0.35 / roll*0.7`, and it stacks that on top of `toolnone`'s 90 degree raise. Most of the motion is in `tool.Grip` (the wrist), so the scythe flips around a frozen arm. The torso, the off hand and the elbow never move.
3. **No anticipation hang and no snap.** Every segment uses the same smoothstep, so the windup and the strike move at the same speed. Good swings are slow, hold, then very fast. Reference: "Roblox Studio - Sword Combat" (847k views, youtube iaJYQaKK5vU), cut at 10 fps. The blade is raised and held for about 200-300 ms, crosses in 1 frame (under 100 ms) with a thin bright arc, follows through low, and settles over about 300 ms. The "Scythe combo" reference (953k views, nGpFa9dzpcU) shows a crescent slash arc much larger than the blade on every hit, plus a hit flash.
4. **The trail is plain.** It is white, lasts 0.2 s, has no tier colour, and stays on for a fixed window of 0.07-0.30 s whatever the variant.
5. **The whoosh fires on the click, not on the strike.** All three variants are about the same length (0.42 / 0.42 / 0.50 s), so the SLAM does not feel heavier.

## 2. Approach: drive joint `Transform` in `RunService.Stepped`, not C0

- The project already does this in Giant.client.luau 129 (the carry pose). The Animator writes `Motor6D.Transform` every frame, and a script may override it in `Stepped` (PreSimulation) after the animation step. So we never fight `toolnone` or walk, and we never have to restore C0.
- **Joints we drive:**
  - R15: `RightShoulder`, `RightElbow`, `LeftShoulder`, `LeftElbow`, `Waist`.
  - R6: see section 8.
  - Legs are never touched, so the Animate walk/run/jump keeps playing.
- **One formula for both rigs.** Cache `c0Rot = joint.C0.Rotation` once per joint. Each frame:
  `joint.Transform = animT:Lerp(c0Rot:Inverse() * R * c0Rot, w)`
  - `animT` is the joint's Transform read in the same Stepped call, before you write it.
  - `R = CFrame.fromEulerAnglesYXZ(rad(P), rad(Y), rad(Rr))`, in the parent part's axes. This applies Rr (Z) first, then P (X), then Y.
  - `w` is the hold weight: 0 to 1 over 120 ms on equip, 1 to 0 over 120 ms on unequip.
- **Angle meanings.** All angles are degrees from the rig's rest pose (arms hanging, standing straight):
  - **Shoulder (both arms):** P+ raises the arm forward and up. Y+ sweeps it toward the character's LEFT. Rr+ swings it out toward the character's RIGHT. So for the left arm, "outward" is Rr negative.
  - **Elbow:** P+ bends the forearm forward and up.
  - **Waist:** P+ leans BACK (negative leans forward). Y+ turns the chest LEFT. Rr+ tilts the right shoulder down.
- **Wrist = the existing `tool.Grip` channel.** Extend `pose()` to 3 angles:
  `pose3(base, pitch, yaw, tilt) = base * HAND:Inverse() * CFrame.Angles(rad(pitch), rad(tilt), rad(yaw)):Inverse() * HAND`
  - Pitch and yaw keep today's signs: pitch below 0 tips the top forward and down; yaw is today's "roll" and sweeps the blade around the vertical.
  - Tilt+ must lean the top toward the character's right. If it leans left, flip the sign. This is a one-time check in Studio.
- **Why idle keeps the server Grip valid.** The idle hold keeps the forearm horizontal and forward (upper arm P 20 + elbow P 70 = 90). That is the same hand frame as `toolnone`, so `Config.ScytheHold` still stands the shaft upright with no server change.
- **When to skip.** Do not drive the pose while `Carry > 0` or the `Carrying` attribute is above 0, so the carry pose wins (note that the two scripts use different attribute names). Do not drive it for characters more than 80 studs from the camera.

## 3. Idle hold ("reaper ready")

| Joint | P | Y | Rr |
|---|---|---|---|
| RightUpperArm (shoulder) | 20 | 8 | 10 |
| RightLowerArm (elbow) | 70 | - | - |
| LeftUpperArm | 8 | 0 | -8 |
| LeftLowerArm | 18 | - | - |
| Waist | -3 | -8 | 0 |
| Wrist (pitch, yaw, tilt) | -4 | 0 | +12 |

- **Result:** the shaft stands just in front of the right hip and leans about 12 degrees out to the right, so the blade clears the head and reads over the right shoulder from the chase cam. The chest turns slightly right, the off hand stays loose, and the stance leans slightly forward.
- **Breathing (always on, on top of the pose), with s = sin(2π · 0.3 · t):**
  - Waist P += 1.5·s
  - Right shoulder Rr += 1.2·sin(2π·0.3·t + 0.6)
  - Wrist tilt += 1.5·sin(2π·0.3·t + 1.2)
- **Equip draw (280 ms):**
  - Go from rest (all zeros) to idle with outBack easing (overshoot 1.7).
  - Spin the wrist yaw from 0 to 360 with outCubic.
  - Interpolate angles in degrees, not by CFrame lerp, so the full spin survives.
  - Play the existing Whoosh at pitch 1.25, volume 0.3.

## 4. Walk, run and jump layer (added to idle and, at 50%, to swings)

- **Inputs:**
  - `v` = horizontal speed of the HumanoidRootPart.
  - `m = clamp(v / 16, 0, 1.6)`.
  - `φ += dt · 9.4 · clamp(v / 16, 0.6, 1.6)`, which is about 1.5 strides/s at walk speed.
- **Offsets (smooth `m` with a 0.12 s lerp so stops do not snap):**

| Channel | Offset |
|---|---|
| Waist Y | +6·m·sin φ |
| Waist P | -4·m (lean into the run) |
| Right shoulder P | +4·m·sin φ |
| Left shoulder P | -14·m·sin φ (the free arm counter-swings) |
| Left elbow P | +10·m |
| Wrist pitch | -10·m (the scythe tips forward when running) |

- **Jump or Freefall (Humanoid state), blended in over 100 ms:**
  - Right shoulder P +15
  - Left shoulder (60, 0, -35)
  - Wrist pitch +10

## 5. The three swings (chain unchanged: step = step % 3 + 1 within `chainWindow` 1.2 s)

### Shared rules

- **Start from the current pose.** Key 0 of every swing is the pose being shown right now (store the last evaluated pose), not idle. That way a chained or cancelled swing never snaps.
- **Easing into each key:**
  - outQuad = 1-(1-x)^2
  - outCubic = 1-(1-x)^3
  - outQuart = 1-(1-x)^4
  - inOutSine = -(cos(πx)-1)/2
  - hold = no motion
- **Interpolation:** lerp each angle in degrees, then build the CFrames.
- **Fast Hands:** divide every time by `1 + Config.SkillSwingBonus`.
- **Hit-stop:** keep the current `FarmFX.freezeUntil` logic, which holds the swing clock. While frozen, add a random ±2 degrees to wrist pitch each frame so the blade shudders in the pumpkin.
- **Recoil after a real impact** (after the freeze ends): add +8 to wrist pitch and -4 to right shoulder P, decaying linearly to 0 over 80 ms. The blade bounces off.
- **Sound:** move the Whoosh from the click to strike start (the end of the hang key) with `task.delay`. Keep `bonkEvent:FireServer()` on the click.
- **Walk layer:** applied at 50% during swings.

### Swing 1: REAP, a diagonal from high right to low left (hit 170 ms, total 460 ms)

| t ms | ease in | RUA P,Y,Rr | RLA P | LUA P,Y,Rr | LLA P | Waist P,Y,Rr | Wrist pitch,yaw,tilt |
|---|---|---|---|---|---|---|---|
| 0 | - | current | current | current | current | current | current |
| 90 | outQuad | 150,-35,35 | 35 | 40,-20,-30 | 50 | 8,-28,4 | 35,-25,0 |
| 115 | hold-ish (linear, small drift) | 155,-38,38 | 30 | 42,-20,-32 | 50 | 9,-30,4 | 40,-28,0 |
| 180 | outCubic (STRIKE) | 70,45,10 | 15 | 25,10,-25 | 30 | -12,30,-3 | -105,30,0 |
| 250 | outQuad (follow-through) | 45,65,5 | 20 | 15,15,-35 | 25 | -15,38,-4 | -115,38,0 |
| 460 | inOutSine | idle | idle | idle | idle | idle | idle |

Trail on 105-255 ms. Whoosh at 115 ms, pitch 1.0.

### Swing 2: RETURN, a backhand from left to right (hit 170 ms, total 470 ms)

| t ms | ease in | RUA | RLA | LUA | LLA | Waist | Wrist |
|---|---|---|---|---|---|---|---|
| 90 | outQuad | 95,60,-5 | 60 | 20,-10,-15 | 40 | 4,32,0 | 20,40,10 |
| 110 | linear | 98,64,-6 | 62 | 20,-10,-15 | 40 | 5,35,0 | 22,44,10 |
| 180 | outCubic (STRIKE) | 75,-45,30 | 10 | 30,15,-20 | 35 | -10,-30,-3 | -95,-32,0 |
| 250 | outQuad | 65,-62,40 | 12 | 30,18,-25 | 30 | -12,-36,-4 | -100,-40,0 |
| 470 | inOutSine | idle | idle | idle | idle | idle | idle |

Trail on 100-260 ms. Whoosh at 110 ms, pitch 1.08.

### Swing 3: HARVEST, an overhead two-hand slam (hit 240 ms, total 540 ms)

| t ms | ease in | RUA | RLA | LUA | LLA | Waist | Wrist |
|---|---|---|---|---|---|---|---|
| 140 | outQuad | 170,0,15 | 25 | 165,-15,-5 | 30 | 14,-8,0 | 30,0,0 |
| 175 | linear (hang at the top) | 175,0,16 | 22 | 170,-16,-5 | 28 | 16,-8,0 | 35,0,0 |
| 240 | outQuart (STRIKE) | 55,12,6 | 10 | 60,-25,5 | 25 | -26,2,0 | -120,0,0 |
| 330 | hold (blade embedded) | 50,12,6 | 12 | 55,-25,5 | 25 | -28,2,0 | -122,0,0 |
| 540 | inOutSine | idle | idle | idle | idle | idle | idle |

- Both hands go over the head, with the left hand reaching toward the shaft (LUA Y -15/-25 pulls it to the right). This is the only variant that reads as two-handed, which saves building IK.
- Trail on 170-340 ms, with width x1.6 (keep the current code).
- Whoosh at 175 ms, pitch 0.85.
- Shake and hit-stop stay as they are now (0.13 s).

### Silhouette checks (chase cam, screenshot each)

- REAP at 115 ms: the blade is behind and above the right shoulder, and the chest is visibly turned right.
- REAP at 180 ms: the blade is in front at pumpkin height, left of centre, and the chest is turned left.
- RETURN at 110 ms: the arm is across the chest and the blade is on the left.
- HARVEST at 175 ms: both hands are above the head and the torso leans back.
- HARVEST at 330 ms: the torso leans forward about 28 degrees and the blade tip touches the ground in front.

If a check fails, tune the wrist values first. They are the least certain numbers because they depend on the forearm's direction.

## 6. Slash trail (replaces the single white trail)

### Core trail

Edit `SwingTrail` in `buildScythe`, or set the same properties client-side in `hookTool`.

| Property | Value |
|---|---|
| Attachments | TrailRoot moved 0.15 stud toward the shaft along the blade. TrailTip moved 0.25 stud past the blade tip. |
| Lifetime | 0.14 (SLAM 0.18) |
| MinLength | 0.02 |
| FaceCamera | false |
| LightEmission | 1 |
| LightInfluence | 0 |
| Brightness | 1.6 |
| Color | ColorSequence (0 = white, 1 = tier `def.color`), so the trailing edge carries the tier colour |
| Transparency | NumberSequence (0, 0) (0.25, 0.25) (1, 1) |
| WidthScale | NumberSequence (0, 1) (1, 0.15) |
| Texture | none (solid, which fits the stud-block style) |

### Glow trail

Add a second Trail, "SwingGlow", only for tier 4 and up (the tiers that already have a neon edge). This makes it a visible reward for upgrading.

| Property | Value |
|---|---|
| Attachments | Root 0.35 stud further toward the shaft, tip 0.4 stud past the blade tip |
| Lifetime | 0.22 |
| Color | tier colour only |
| Transparency | (0, 0.6) (1, 1) |
| LightEmission | 1 |
| Brightness | 1 |
| WidthScale | (0, 1) (1, 0.4) |
| When off | Skip it on touch devices and when `UserGameSettings().SavedQualityLevel` is 3 or below |

Toggle both trails with the per-variant trail windows in section 5, not the fixed 0.07-0.30 s window.

## 7. Slash arc VFX (crescent, built from Beams, no asset)

### When it shows

- Only on a confirmed `FarmFX.impact` (a hit) and on every HARVEST.
- Never on misses, and never for other players. The brief says the graphics are already too much.

### The rig

- Pool 3 rigs. Each rig is one Part: Anchored, Transparency 1, Size 0.2, CanCollide, CanQuery and CanTouch all false. Parent it to workspace, client-side only.
- Each rig has 3 Attachments on the arc and 2 Beams: beam 1 runs A(φ=+80) to A(0), beam 2 runs A(0) to A(-80).
- **Arc points** in the rig's local XZ plane (forward is -Z): pos(φ) = (r·sin φ, 0, -r·cos φ), with r = 4.2.
- **Attachment axes:** set each attachment's Axis to the direction of travel, `-(cos φ, 0, sin φ)`. Use SecondaryAxis = +Y.
- **Curve sizes:** CurveSize0 = CurveSize1 = 0.485·r, which is 2.04 for r = 4.2. This is the Bezier constant for an 80 degree circle segment, 4/3·tan(20°)·r. If the arc bulges inward, negate CurveSize1. This is a one-time check.
- **Beam properties:**

| Property | Value |
|---|---|
| Segments | 12 |
| FaceCamera | false |
| LightEmission | 1 |
| LightInfluence | 0 |
| Brightness | 1.5 |
| Texture | none |
| Beam 1 width | Width0 0.15, Width1 1.0 |
| Beam 2 width | Width0 1.0, Width1 0.1 (together they make the crescent) |
| Color | white to the tier colour along the length |

### Placement

`rig.CFrame = HRP.CFrame * CFrame.new(0, yOff, 0) * CFrame.Angles(0, 0, rad(tilt))`

| Variant | yOff | tilt | Draw direction |
|---|---|---|---|
| REAP | 1.0 | +30 (right side high) | right to left |
| RETURN | 0.9 | -20 | left to right: swap the beam order, reverse the axes |
| HARVEST | 1.5 | 90, which makes the arc vertical in front: top, then front, then ground | top to front |

### Animation (on RenderStepped, while the rig is in use)

- Enable beam 1 at 0 ms and beam 2 at 35 ms, so the arc "draws".
- Over 160 ms, fade Transparency from 0.05 to 1 and grow r from 4.2 to 4.8. Move the attachments and keep the curve sizes at 0.485·r.
- Return the rig to the pool afterwards.

## 8. R6 support

`Humanoid.RigType == Enum.HumanoidRigType.R6`. The joints are `Right Shoulder` and `Left Shoulder` in Torso, and `RootJoint` in HumanoidRootPart. The same `c0Rot` conjugation formula works, because R6 C0s are rotated (shoulders by Y 90, RootJoint by (-90, 0, 180)).

- **Shoulders:** fold the elbow into the shoulder with `P_r6 = P_shoulder + 0.5 · P_elbow`, keeping Y and Rr as they are.
- **Grip compensation:** on R6 the hand frame loses `0.5 · P_elbow` of forward rotation, so add `wristPitch += -0.5 · P_elbow`. For example, idle gets -35 more, which puts the shaft upright again.
- **Waist to RootJoint:** use Y × 0.5 and P × 0.5, and ignore Rr. RootJoint turns the legs as well, so half strength keeps the feet from visibly twisting.
- **Trail and arc:** work unchanged, because they are tool and world space.
- **The carry pose:** Giant.client.luau writes `Angles(165, 0, ±12)` straight into Transform without conjugating. That is fine on R15 but rotates around the wrong axis on R6. Not in scope; flagged for the carry owner.

## 9. Code shape (one system, replaces `swingTool`'s RenderStepped pose code)

```lua
-- per character: state = { pose = POSE_IDLE(copy), swing = nil|{keys, t0, step}, w = 0, phase = 0, joints = {} }
-- Animation clock (RenderStepped): advance swing time minus hit-stop pause, evaluate keys -> state.pose
-- Stepped: for each tracked character with a held Scythe and not carrying:
--   ramp w; add breathing + walk layer; for each joint: j.Transform = j.Transform:Lerp(c0Inv*R*c0, w)
--   tool.Grip = pose3(idleGrip, wrist.pitch, wrist.yaw, wrist.tilt)
-- Trail windows, the hit frame, FarmFX.impact and freezeUntil stay exactly as they are now
-- (hitFrame: REAP 0.17, RETURN 0.17, HARVEST 0.24).
```

- Keep `FarmFX.steps`, the chain, the hold-to-swing loop and the remote `Swing` replay unchanged. Other players simply get the same state machine.
- The pose data is three key tables plus one idle table, about 60 lines.
- The system is about 140 lines in total. That is fewer moving parts than now, because the C0 save/restore and the shoulder lookup per swing go away.

## 10. Acceptance (phone and desktop)

1. **Idle on R15 and R6:** the shaft is upright beside the right hip, the blade is clear of the head, and there is no straight-out arm. Screenshot it.
2. **Each swing at its checkpoint times** in section 5 matches its silhouette. Capture with the Studio MCP: start play, click, then capture after a timed delay.
3. **Hold to swing for 10 s:** no pose pop between chained swings, and the 3-step order is correct.
4. **Walking while swinging:** the legs keep walking and the torso does not fight.
5. **Carrying a pumpkin:** the carry pose wins and there is no scythe pose.
6. **A second client sees** the idle and the swings of the other player.
7. **Phone (device simulator):** with the glow trail off, the arc only appears on hits, and the frame time does not change by more than 0.3 ms with 8 scythe holders on screen.
