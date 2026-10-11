# SCYTHE TUNING: held scythe size, idle hold and swing keys (tested live in Studio)

Tested in Play mode on 2026-10-11 with the real avatar (R15, 5.79 studs tall). Changes were made only on the CLIENT, at runtime: a PreSimulation override of the arm/waist joints using exactly the Patch.client formulas, plus a rebuilt and scaled copy of `Config.buildScythe` welded with the same Grip math. An R6 dummy was posed on the server through the existing R6 channel mapping. No game files were edited and the place was not saved. Images are in `production/watch2/scythe-tuning/`.

## 1. Root causes (why it was invisible, small, or "a torch")

1. **The hold and swing pose never ran on R15 (the main bug).** This avatar's R15 joints are not `Motor6D`. They are `AnimationConstraint`s (Avatar Joint Upgrade): `RightShoulder`, `RightElbow`, `LeftShoulder`, `LeftElbow`, `Waist`, each paired with a `...BallSocket` constraint. `track()` in Patch.client.luau (line ~3854) only accepts `j:IsA("Motor6D")`, so `st.joints` was **empty**. Only the `tool.Grip` channel was driven.
   - The arm stayed in the default `ToolNoneAnim` pose (arm stuck straight forward).
   - The Grip assumes a lowered arm. With the arm forward, the shaft lay horizontal along the facing axis: pommel 3.4 studs in front, blade 2.4 studs behind the shoulder, at shoulder height.
   - From the chase camera you saw a short brown stub at the shoulder, with the blade hidden behind the head or body (`before_idle_back.jpg`, `before_idle_front.jpg`). The earlier "small axe held up like a torch" was the same forward toolnone arm with a raised Grip.
   - R6 joints are still `Motor6D`, so R6 was not affected.
2. **The blade was thin.**
   - The column body was 0.3 thick (Z) and the edge 0.34 × 0.09.
   - The vertical thickness ran from 0.72 down to 0.08.
   - From the elevated chase camera the blade is often close to edge-on, so it shrank to a sliver.
3. **The scythe was slightly short.** It was 6.0-6.4 studs, about 1.05x avatar height. Once the hold works it reads fine, but 1.15x more length gives the reaper look (7.0-7.4 studs, about 1.2-1.25x height).
4. **The old swing keys (`Config.ScythePose.swings`) were authored blind**, because the joints never moved. With the joints fixed:
   - REAP contact pointed the shaft straight away from the camera, so it was hidden behind the body.
   - The wind-up hung the blade downward (`before_reap_*_jointsfixed_oldkeys.jpg`).

## 2. Code changes (exact values)

### 2a. Joint discovery fix (Patch.client.luau, `track()`, ~line 3853)
```lua
for _, j in character:GetDescendants() do
    if names[j.Name] and (j:IsA("Motor6D") or j:IsA("AnimationConstraint")) then
        local rot = if j:IsA("Motor6D") then j.C0.Rotation else j.Attachment0.CFrame.Rotation
        table.insert(st.joints, { motor = j, index = names[j.Name], rot = rot, anim = j.Transform })
    end
end
```
- `AnimationConstraint.Transform` is writable. The existing PreAnimation reset and the PreSimulation `Transform = anim:Lerp(rot:Inverse()*R*rot, w)` work unchanged; this was verified live.
- R15 rig attachments have identity rotation, so `rot` = identity.
- Giant.client.luau's carry pose (line ~129) probably has the same `Motor6D`-only filter. Check it.

### 2b. Hold (PatchConfig `ScytheHold`)
```lua
ScytheHold = { right = 0.05, forward = 0.35, lean = -20, yaw = 0, roll = 38 }, -- was lean -12, roll 32
```
- Grip formula unchanged, but use the scaled length `Ls = s.L * 1.15` in `CFrame.new(0, Ls / 4, 0)`.
- The rotation part is identical for every tier. Resulting `tool.Grip`:

| Style | L → Ls | Grip CFrame components |
|---|---|---|
| RustySickle | 6.0 → 6.900 | `0.0343, -1.5999, 0.3289, 0.7880,-0.2106,0.5785, -0.6157,-0.2695,0.7405, 0,-0.9397,-0.3420` |
| WoodenScythe | 6.1 → 7.015 | y = -1.6286, rest same |
| BoneScythe | 6.2 → 7.130 | y = -1.6574 |
| CursedScythe | 6.3 → 7.245 | y = -1.6861 |
| MoonScythe / CandyScythe | 6.4 → 7.360 | y = -1.7149 |
| PumpkinKingCleaver | 5.8 → 6.670 | y = -1.5424 |

- IDLE angles stay as they are: `{ 12, -8, 6, 15, 4, 0, -6, 12, -3, -8, 0, 0, 0, 0 }`.
- Result: the shaft runs diagonally from the right hip to behind the left shoulder. The blade sits above and to the right of the head with its face toward the chase camera (`after_idle_back_T1.jpg`, `after_idle_front_T1.jpg`, `after_idle_back_T7.jpg`).

### 2c. Blade thickness (`buildScythe` blade loop, values before the 1.15 scale)
- Column vertical thickness: `local thickness = 0.128 + 1.024 * (1 - t0) ^ 1.2` (was `0.08 + 0.64 * …`, so 1.6x).
- BladeColumn size Z: **0.5** (was 0.3).
- Edge size: `Vector3.new(delta.Magnitude + 0.07, 0.16, 0.56)` (was Y 0.09, Z 0.34). It stays at `cf * CFrame.new(0, -thickness / 2, 0)` with the new thickness.

### 2d. Uniform scale ×1.15 (end of `buildScythe`, before the attachments and trails, or applied to every part and attachment)
- Scale every part's Size, and its offset from Handle, by `K = 1.15`, including the Handle.
- Scale the TrailRoot, TrailTip, GlowRoot and GlowTip positions by 1.15.
- Use `Ls = s.L * K` in the Grip (2b).
- Equivalent alternative: multiply `L`, `W`, `V` and every hard-coded ornament size and offset by 1.15. The post-scale was what got tested.
- Part counts are unchanged (King stays at 37).

### 2e. Swing keys (PatchConfig `SWINGS`, same timing and easing as now)
- Channel order: RS pitch, yaw, roll | R elbow | LS pitch, yaw, roll | L elbow | waist pitch, yaw, roll | grip pitch, roll, yaw.
- Key 2 is the wind-up held slightly further (anticipation). Key 5 stays `unpack(IDLE)`.
- Keys were solved by FK against blade and collar targets, a two-handed constraint (left hand on the shaft, within 0.1-1.0 studs) and no shaft-through-torso, then checked visually.

```lua
-- REAP (horizontal mow right -> left)
{ 0.09,  "outQuad",  129, 46, 6, 0, 121, -27, 30, 20, 5, -40, -18, -72, -61, 43 },
{ 0.115, "linear",   134, 48, 6, 0, 125, -27, 30, 20, 6, -44, -18, -76, -61, 43 },
{ 0.18,  "outCubic",  26, 0, -31, 55, 58, -12, 18, 16, -16, 19, -13, 76, 60, 54 },
{ 0.25,  "outQuad",   33, 29, -32, 52, 34, -2, -27, 24, -13, 45, -12, 56, 61, 47 },
-- RETURN (backhand left -> right)
{ 0.09,  "outQuad",  101, 33, -19, -2, 90, -2, 4, 44, 9, 39, 17, -123, -4, -20 },
{ 0.11,  "linear",   106, 35, -19, -2, 94, -2, 4, 44, 10, 43, 17, -127, -4, -20 },
{ 0.18,  "outCubic",  27, -13, -32, 2, 48, -21, 30, 7, -20, -21, 1, -107, -60, -30 },
{ 0.25,  "outQuad",  -50, 75, 102, 55, 67, -27, 30, 20, -4, -48, -16, -23, 41, 44 },
-- HARVEST (overhead slam landing front-right)
{ 0.14,  "outQuad",  144, -1, -23, 0, 136, -25, 27, 20, 21, -3, -4, -119, -39, 23 },
{ 0.175, "linear",   150, -1, -23, 0, 141, -25, 27, 20, 23, -3, -4, -123, -39, 23 },
{ 0.24,  "outQuart",  63, 12, -29, 0, 67, -14, 18, 13, -28, -28, 2, -110, -68, 4 },
{ 0.33,  "hold",      56, 12, -25, 0, 62, -11, 23, 11, -31, -29, 10, -105, -69, 9 },
```
What each key looks like (chase camera; positions are relative to the root, -Z is forward):
- **REAP**
  - Wind-up: both hands over the right shoulder, chest turned 40° right, blade high, broad face to the camera. Collar at about (4.1, 4.0, 3.9).
  - Contact: two-handed, shaft out front-left and low, blade hooking back. Collar at about (-4.2, -0.8, -4.0).
  - Follow-through: swept to the left, chest turned 45° left, blade arcing back toward the camera.
- **RETURN:** the mirror of REAP.
  - Wind-up: over the left shoulder.
  - Contact: front-right, low.
  - Follow-through: blade sweeps around behind the right side.
- **HARVEST**
  - Wind-up: both arms straight overhead, blade towering above. Collar at (0.6, 5.5, 4.4), tip near y = 10.
  - Contact: leans forward 28°, shaft forward-right, blade drives down into the ground.
  - A centred slam was tried and rejected: the body hid it from the chase camera (`rejected_harvest_contact_centered_back.jpg`).
- **Interpolation:**
  - A body-overlap check ran on the linear interpolation between keys. It found only a 1-frame graze at mid-strike in REAP.
  - The grip channel turns about 150° during the 0.07 s strike, which reads as a wrist whip.

### 2f. R6
- Use the same tables through the existing R6 mapping (shoulder pitch += 0.5·elbow, RootJoint = half the waist, grip pitch -= 0.5·p[4]). No separate numbers are needed.
- Verified on an R6 dummy:
  - Idle: diagonal across the back (`after_R6_idle_back.jpg`).
  - REAP wind-up: over the right shoulder, blade up (`after_R6_reap_windup_back.jpg`).
  - REAP contact: low left sweep (`after_R6_reap_contact_back.jpg`). It sits slightly lower and closer to the body than on R15, because R6 has no elbow, but it reads correctly.
- R6 already found its Motor6Ds, so it needs only 2b-2e.

## 3. Images (production/watch2/scythe-tuning/)
- Before:
  - `before_idle_back.jpg` and `before_idle_front.jpg`: current build, shaft horizontal at the shoulder, blade hidden.
  - `before_reap_windup_jointsfixed_oldkeys.jpg` and `before_reap_contact_jointsfixed_oldkeys.jpg`: old keys once the joints work.
- Steps:
  - `step1_jointsfixed_idle_back.jpg`: joint fix only.
  - `step2_scaled_chunky_idle_back.jpg` and `step2_scaled_chunky_idle_front.jpg`: plus scale ×1.15 and the thicker blade.
- After, idle: `after_idle_back_T1.jpg`, `after_idle_front_T1.jpg`, `after_idle_back_T7.jpg` (the final hold, lean -20 and roll 38).
- After, REAP: `after_reap_windup_back.jpg`, `after_reap_contact_back.jpg`, `after_reap_contact_front.jpg`, `after_reap_follow_back.jpg`.
- After, RETURN: `after_return_windup_back.jpg`, `after_return_contact_back.jpg`, `after_return_follow_back.jpg`.
- After, HARVEST: `after_harvest_windup_back.jpg`, `after_harvest_contact_back.jpg`, `after_harvest_contact_side.jpg`.
- After, R6: `after_R6_idle_back.jpg`, `after_R6_reap_windup_back.jpg`, `after_R6_reap_contact_back.jpg`.

## 4. Notes
- The swing images use tier 4 (Cursed). The idle images use tiers 1 and 7.
- RustySickle's body (B5653A) and shaft (8B5A2B) are both brown and blend together. Consider a lighter steel-grey body for tier 1 so the blade separates from the shaft.
- The physics-based AnimationConstraint joints follow the written Transform with no visible lag.
