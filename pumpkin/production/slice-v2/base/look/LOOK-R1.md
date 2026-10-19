# Steal a Treasure — look round 1

Implemented on `pumpkin/patch-panic`. No commit; Roblox Studio was not opened.

## Checked and changed

Inspected both supplied PNGs, the existing Scene/build/BaseTest code, and BaseServer's ownership, bank, pedestal and barrier hooks. Reused this project's existing part factory and gameplay layout; no external code/assets or new licence obligations. Read the local project `PLAYBOOK.md` and Roblox production skill. The specifically named Keystone "Roblox Process Playbook" was unavailable through local note search/connected tools; its full contents remain UNKNOWN.

Target: **Steal a Brainrot**, using only `ref-map-overview.png` and `ref-base-inside.png`.

| Reference feature | Implemented in R1 (source/serialized-place evidence) |
| --- | --- |
| Bright studded grass, grey boundary | RGB 75,200,60 Plastic ground with Studs top; four grey border walls |
| Red lane and base entries | RGB 200,30,30 carpet with thin white edges; matching entrance/interior strips; invisible Entry/Home markers |
| Dark open-front bases | Eight RGB 60,65,75 shells, white window bands/mullions, pale transparent windows; flat rear-half roof slabs |
| Wooden entrance name sign | Brown framed board with white GothamBlack text; existing `Floor.Sign.Text` hook preserved through SurfaceGui.Adornee; live names normalize to `<DisplayName>'s Base` |
| Red lock lasers | 24 non-colliding Neon visual children per Barrier, shown only when its existing CanCollide state is true; old sheet hidden |
| Block pedestals and Collect pads | Dark visual blocks over unchanged authority roots; green pads; locked slots grey with existing price signs |
| Readable action pads | Green Collect, yellow Unlock, blue Upgrade, red Lock; heavy white labels with dark strokes; action labels visible within 65 studs |
| Bright daylight | ClockTime 14, Brightness 2, soft Atmosphere, built-in Sky, slight saturation; FogEnd 10000 |

Pedestal labels mirror the **real pooled base-bank total** as `Collect $X / Base total`. Existing gameplay collects at the original Collect part; decorative per-slot pads do not add collection triggers or pretend to expose individual balances. `LookVisuals` only presents existing state. Barrier dimensions, position, CanCollide ownership, player collision rules and gameplay part names/attributes/positions remain intact. No earners model source was edited.

## Verification

- `lune run slice-v2/base/check.luau`: **PASS**, 680 offline assertions (including 405 earner assertions), 20 Luau sources compile.
- `lune run slice-v2/base/build.luau`: **PASS**, 18 Luau sources plus embedded LookVisuals compile; 782 serialized-place structure assertions; 202 offline presentation-state assertions.
- Adapter tests execute its actual source with signal doubles and serialized visual parts: repeated lock/unlock, collision preservation, pedestal gating/colors, claimed/unclaimed names, bank-label changes. Engine event scheduling/replication is not covered.
- Built Workspace: **895 BaseParts**, including the starter preview, below the **2500** budget. This is the generated place count, not a guarantee for arbitrary live earner populations.
- Output: `slice-v2/base/steal-a-treasure-base.rbxl` (38,564 bytes).
- Rokit's `lune` shim failed with `ERROR home directory not found`; both requested scripts passed using the installed `C:/Users/zerha/.rokit/tool-storage/lune-org/lune/0.10.5/lune.exe` directly.
- Independent read-only code critic checked reference requirements and gameplay contracts; Entry/Home carpet occlusion and missing `$X` pedestal text were corrected. This was a code review, not a visual score.
- **Studio visuals: NOT RUN.** Studio EDIT, Play, multiplayer, device checks and 30-stud readability: **NOT RUN**. Final appearance is inferred from geometry/palette; Claude takes Studio shots and performs the visual comparison.

## Claude's visual check

Take an outside view and an inside view of one representative base against the two PNGs before further rounds. At 30 studs check action labels, price-sign overlap and window transparency; test a claimed name, locked/unlocked lasers, one pedestal unlock and collection. Confirm the front lasers disappear on expiry and the collision owner can still enter.

## Lessons

- When gameplay owns a part's color/state, give its visual a separate child, because server refreshes otherwise overwrite the look.
- When building with Lune, use CFrame.Position and FontFace, because this serializer lacks Position defaults and mishandles the legacy Font property.
- When only a pooled balance exists, label mirrored money as a base total, because per-slot amounts would be invented.
