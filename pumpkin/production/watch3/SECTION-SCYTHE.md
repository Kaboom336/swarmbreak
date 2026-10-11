# SECTION-SCYTHE: hold, equip, walk, 3 swings (round 3, Z1 "held backwards")

No game files edited, no Studio used. All numbers below come from an offline forward-kinematics model of the R15 right arm / waist / grip (pure Python, same Euler orders and Grip maths as Patch.client.luau 4735-4749 and PatchConfig 1608). Positions are HRP object space (+X right, +Y up, -Z forward, HRP centre = origin, ground about y = -3.4, head top about y = +2.6). Model accuracy is about +/-1 stud (see section 5 calibration). Scythe length used: Ls = 7.0 (tier 3-4, L 6.1-6.3 x 1.15).

## 1. Flaws found (with evidence)

1. **The current hold is deliberately "over the back", which is exactly what the owner sees as backwards.** PatchConfig.luau:471 `ScytheHold lean -20, roll 38` gives a hand-frame shaft direction (-0.62, 0.74, +0.27): up, across the body to the LEFT, and +Z = BEHIND. Modelled on the current IDLE: hand (2.0,-1.8,-0.7), blade top (-2.1, 0.9, +0.7), blade extends up-right behind. The watch2 doc (SCYTHE-TUNING.md 2b) even describes it as "shaft from right hip to behind the left shoulder". ZION-LIST Z1 live read agrees: handle z = -1.0, blade parts z = +2..+3.2. Cause: a design choice, not a joint bug (the AnimationConstraint fix is already in, Patch.client.luau:4490).
2. **Blade is below/behind head height, so the default behind-the-back camera sees mostly body, never a silhouette** (blade at chest height, z>0 means it is hidden behind the torso from the camera).
3. **Shoulder-only arm pose** (IDLE 12/15 deg): arm hangs, so any front-facing hold is impossible; the elbow must carry the pose (IDLE[4] = 15).
4. **The three SWINGS (PatchConfig.luau:1996-2018) were authored for the over-the-back Grip.** REAP wind-up and RETURN wind-up put the blade high behind the shoulder, REAP contact points the shaft at +Z-ish and hides it; wrist (grip) channels whip 120-150 deg in 0.07 s (e.g. key 3 of RETURN: -107, -60, -30).
5. **Equip animation starts from an all-zero pose** (Patch.client.luau:4648-4654 scales every channel from 0). With the new Grip, all-zero = shaft pointing down-forward through the floor (blade root at y = -6.1 for ~2 frames). Needs a proper FROM pose.
6. **R6 mapping sign looks wrong for any elbow above ~20 deg** (Patch.client.luau:4739: `pitch = p[12] - 0.5*p[4]`). R6 puts half the elbow into the shoulder, so the hand is rotated 0.5*elbow LESS than on R15; to keep the same world shaft the wrist must add +0.5*elbow, not subtract. With elbow 90 the R6 shaft would be 90 deg off R15. (Hidden before because elbow was 15.)
7. Jump overlay (4673-4674) uses `IDLE[5]`, `IDLE[7]` so it keeps working with new IDLE; walk overlay is fine (verified, section 3).

## 2. What top games do

Reaper/farming-weapon idles in Roblox hits and Fortnite/MMO pickaxe-style tools: weapon held in FRONT of the chest, head of the tool ABOVE and AHEAD of the head so the camera behind sees a clear silhouette against the world; swings cross the screen centre in front of the player (diagonal down-across, back across, overhead slam) and the tool head is the brightest, biggest thing in frame at contact. Weapon behind the back or at the hip is only used for "sheathed".

## 3. Fix spec, ordered by impact

### S1. New hold (PatchConfig.luau:471) [S]
```lua
ScytheHold = { right = 0.05, forward = 0.35, lean = -22, yaw = 74, roll = -162 },
```
Builder formula unchanged. Resulting `tool.Grip` (K = 1.15 already in builder) per style, `CFrame.new(x,y,z, R00,R01,R02, R10,R11,R12, R20,R21,R22)`, identical rotation for all:
rotation = `-0.2621,-0.7319,-0.6290, 0.0852,0.6317,-0.7705, 0.9613,-0.2556,-0.1033`, x = 0.2693, z = 0.0414, y by style:

| Style | y |
|---|---|
| RustySickle (L 6.0) | -1.9503 |
| WoodenScythe (6.1) | -1.9791 |
| BoneScythe (6.2) | -2.0078 |
| CursedScythe (6.3) | -2.0366 |
| MoonScythe / CandyScythe (6.4) | -2.0653 |
| PumpkinKingCleaver (5.8) | -1.8928 |

(The huge yaw/roll are just the Euler form of the needed rotation; hand-frame shaft axis is no longer near the arm axis because the forearm now points forward.)

### S2. New IDLE (PatchConfig.luau:1995) [S]
```lua
local IDLE = { 30, 16, 6, 90,  10, 0, -6, 15,  -2, 0, 0,  0, 0, 0 }
```
Channels: RS pitch,yaw,roll | R elbow | LS pitch,yaw,roll | L elbow | waist pitch,yaw,roll | grip pitch,roll,yaw. (Only R side and waist changed; left arm stays relaxed.)

Idle in HRP space (tier 3-4 length):
- right hand (0.9, 0.9, -2.3) (chest height, 2.3 ahead, 0.9 right)
- pommel (1.1, -0.4, -1.5) (hip height, in front, not behind)
- shaft direction (-0.08, 0.92, -0.38): 23 deg forward of vertical
- **blade root (top of shaft) (0.6, 6.0, -4.1)**: 3.4 above the head, 4 studs ahead
- **blade tip (-3.2, 3.4, -5.4)**: blade extends LEFT and forward, tip hooks DOWN; edge (concave side) faces down/toward the player, spine up/forward; broad face is seen at ~45 deg from the behind camera
- left hand relaxed (-1.8,-1.9,-1.0)
Camera check: default camera sits behind and above, blade root is higher and farther than the head so nothing occludes it; silhouette is a tall pole rising from the right hand with a hook over the head.

### S3. Equip (Patch.client.luau:4648-4654) [S]
Replace the scale-from-zero with a FROM pose (the REAP wind-up key, scythe raised on the right) so the scythe sweeps from high-right down into the hold, keeping the existing 0.28 s and overshoot (f peaks at 1.1):
```lua
local FROM = { 24,21,-20,97, 84,-24,19,29, 16,-41,-12, -2,31,17 }
-- ...
for i = 1, #p do p[i] = FROM[i] + (p[i] - FROM[i]) * f end
```
Modelled: f=0 blade root (4.3,5.8,0.5); f=0.5 (3.1,6.3,-2.3); f=1.1 (0.0,5.9,-4.3). Never goes below the floor.

### S4. Walk (no change to overlay lines 4669-4677) [verified, S/none]
With move m = 1: blade root bobs between (0.0,5.6,-5.1) and (0.9,4.9,-5.5), tip y 1.8-2.8, hand stays (0.7-1.2, 0.6-0.9, -2.2..-2.4). Jump: shaft goes vertical, root (1.2, 6.9, -1.9). All in front, nothing behind the body.

### S5. Swings (PatchConfig.luau:1996-2018), same timings, easings, trail WINDOWS [M]
Row format `{ t, ease, <14 channels> }`. Key 2 is key 1 pushed (RS pitch +4, waist yaw x1.1, grip pitch -3).
```lua
local SWINGS = {
  { -- REAP: high right, cut diagonally down across to low front-left, follow left
    { 0.09,  "outQuad",   24, 21,-20, 97,  84,-24, 19, 29,  16,-41,-12,   -2, 31, 17 },
    { 0.115, "linear",    28, 21,-20, 97,  84,-24, 19, 29,  16,-45,-12,   -5, 31, 17 },
    { 0.18,  "outCubic",   4, 48, 32, 90,  51,-13,  5, 12,  24, -5, 12,  -60,  4, 46 },
    { 0.25,  "outQuad",  -13, 60, 50, 96,  57,-11,  3, 15,  25, 32, 12,  -86, 62, 33 },
    { 0.46,  "inOutSine", unpack(IDLE) },
  },
  { -- RETURN: low left, backhand up through front-right, follow high right
    { 0.09,  "outQuad",   10, 33,-20, 77,  41, -3, -6, 35,   4, 13,-11,  -45,-23, -8 },
    { 0.11,  "linear",    14, 33,-20, 77,  41, -3, -6, 35,   4, 14,-11,  -48,-23, -8 },
    { 0.18,  "outCubic",  41, 29,-20, 63,  63,-13,  6, 23,  -7,-32, 12,  -44, 34,-32 },
    { 0.25,  "outQuad",   38, 29,-20, 93,  93,-24, 17, 25, -12,-41,-12,   14, 18,-28 },
    { 0.47,  "inOutSine", unpack(IDLE) },
  },
  { -- HARVEST: blade overhead, slam down in front, hold in the ground
    { 0.14,  "outQuad",   39, 23, -7, 96,  96,-24, 17, 33,  25,-33, -9,  -11, 24, 26 },
    { 0.175, "linear",    43, 23, -7, 96,  96,-24, 17, 33,  25,-36, -9,  -14, 24, 26 },
    { 0.24,  "outQuart", -13, 60, 50, 85,  49,-22,  9,  3,  25,-12, 12,  -60, 11, 60 },
    { 0.33,  "hold",     -17, 60, 50, 85,  47,-24, 10,  1,  25, -5, 12,  -61,  8, 60 },
    { 0.54,  "inOutSine", unpack(IDLE) },
  },
}
```
Where the blade is at each key (HRP space; "root" = shaft top where blade starts, "tip" = far end of blade after its hook, hand = right grip):

| Swing / key | root | tip | hand | reads as |
|---|---|---|---|---|
| REAP 1 wind-up (t .09) | (4.3, 5.8, 0.5) | (2.9, 6.1, -4.0) | (1.4,1.4,-0.9) | torso turned 41 deg right, blade high right of the head, hooking forward; visible above-right from behind |
| REAP 3 contact (.18) | (-2.6, -0.8, -5.7) | (1.4, -3.4, -5.3) | (0.6,1.0,-1.6) | blade low and in front, left of centre, tip at ground; sweep path root passes (1.8,6.5,-2.5) > (-1.1,5.0,-4.6) > (-2.8,2.1,-5.5) |
| REAP 4 follow (.25) | (-5.7, 1.1, -2.9) | (-2.9, 1.4, -6.7) | (-0.4,0.8,-1.5) | blade horizontal across the front-left at hip height; body turned 32 deg left |
| RETURN 1 wind-up | (-5.1, 0.9, -4.3) | (-6.0, 1.2, 0.4) | (-0.6,0.0,-1.3) | blade held out low left |
| RETURN 3 contact | (4.0, -1.2, -5.9) | (-0.3, -3.2, -6.5) | (0.5,0.4,-2.0) | blade low front-right, tip at ground, sweeping left to right (mid path root (-0.9,-0.5,-7.1)) |
| RETURN 4 follow | (6.5, 3.0, -1.3) | (3.5, 6.0, -3.4) | (1.4,1.0,-1.3) | blade rises high on the right, finishing near the idle side |
| HARVEST 1 wind-up | (1.5, 7.2, 1.2) | (0.4, 7.2, -3.4) | (1.2,2.1,-0.7) | scythe straight up, both arms high, blade 4.6 above the head |
| HARVEST 3 contact | (-0.1, -2.8, -5.6) | (4.6, -2.1, -5.2) | (1.1,0.8,-1.6) | blade slams into the ground 5.5 studs ahead, broad blade laid across to the right |
| HARVEST 4 hold | (-0.1, -3.2, -5.4) | (4.6, -2.2, -5.2) | (1.0,0.7,-1.7) | held planted during hit-stop |

Interpolation check (linear between keys, 7 samples each): max shaft/blade penetration into the body ellipse is 0.6 stud for 1 frame (RETURN contact > follow); everything else clear. All three contacts keep the whole blade in the half-space z < -2.5.
Notes: the two-handed look is kept (left hand within about 0.1-1.2 studs of the shaft at contact keys). HARVEST contact keys use shoulder yaw 60 / roll 50 (the extreme the solver allowed); if the arm looks twisted in Studio, pull yaw to 45 and compensate with grip yaw +10.

### S6. R6 [S]
Patch.client.luau:4739 change to `local pitch = p[12] + (st.r6 and 0.5 * p[4] or 0)` (the sign). Then R6 hand has the same world orientation as R15, only the hand sits about 0.8 stud closer/lower. Check on an R6 dummy: idle blade must be above and ahead of the head.

### S7. Optional [S]
Tier 1 RustySickle body B5653A on a brown shaft still blends (see watch2 note 4); lighter steel for tier 1 belongs to the palette section.

## 4. Order of work
S1+S2 (two lines, check idle first) > S5 swings > S3 equip > S6 R6 sign.

## 5. Calibration (do this once in Studio, 5 minutes)
The model is derived from R15 default proportions scaled 1.1; Z1's live read of the old hold was about 1.5 studs further back than the model predicts. Margins are therefore large. After applying S1+S2 print `root:ToObjectSpace(Handle.CFrame * CFrame.new(0, Ls/2, 0)).Position` and the BladeColumn tip. Idle expected (0.6, 6.0, -4.1) +/-1; if blade root z is above -2.5 or y below 4.5, tune only ScytheHold lean (each degree moves the root about 0.1 stud) rather than the arm angles. For contacts, tune the grip channels (indices 12-14) first; they move the blade without moving the hands.

## 6. Acceptance test (5 lines)
1. Equip: scythe sweeps from high right down into hold in about 0.3 s, never below the floor, no flash behind the back.
2. Idle, default camera behind: pole rises from right hand, blade clearly above-ahead of the head, hooking down over the left, visible without rotating the camera.
3. Walk and jump: blade stays in front (root z < -1.5) the whole cycle; no part crosses behind the torso.
4. Click 3 times: REAP then RETURN then HARVEST; every contact key puts the blade in z < -2.5 below hip height, crossing the screen centre in front, harvest drives into the ground; no 1-frame jumps.
5. Same on an R6 dummy and another player's avatar viewed from the side: shaft direction matches R15 within 15 deg.
