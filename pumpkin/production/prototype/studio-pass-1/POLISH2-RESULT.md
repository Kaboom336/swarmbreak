# Meadow polish2

Applied with apply_patch; no commit or publish. Canonical place: `slice-v2/prototype/guardian-greybox.rbxl`. Before Rojo, byte-verified backup `guardian-greybox.pre-polish2.rbxl` (SHA256 701C133C39201E0157938039C97B65F7EAECD988D043FA9BF112CFE365C450B8). Rebuilt place SHA256 202B84DE8D21F3DE305EC46C07BF88EF39949AF2469806EA64EDC50B8256ACBA.

Both guard anchors moved from (-7,48,99) to (-7,48,110). Nest and its 9-stud steal prompt remain fixed. Dropped-loot guard x offset stays -7. The new post remains on the summit floor and within nest detection range. `POLISH2-CLEARANCE.json` records 3.6047 studs conservative separation: 242 idle/patrol pose samples, all yaws, and the full 3-stud arrival allowance. This proves the sampled idle/patrol envelope, not arbitrary combat/chase paths.

Beam widths 4.4/1.8 before 1.8x model scale, unlit Brightness 3, opacity .80/.62/0, five-second +/-7% width pulse. Grass saturation/value and path warmth increased; GardenWarm sky haze reduced and grade strengthened. UI sources unchanged.

Checked: 66 scripts compile O0/O1/O2; all unrelated sources including the eight suite implementations preserved; serialized Workspace and rebuilt collision/floor/tag parity. Existing check.luau, keeper-clearance.luau, policy/core/coordinator/reset checks pass (see polish2-*.log). No live Studio connection: all eight runtime suite results, actual beam pulse and UI readability remain UNKNOWN after this edit. Follow POLISH-STUDIO-CHECKS.md; do not inherit earlier Studio PASS results.

POLISH-SBS.jpg was visually inspected after rebuilding the AFTER column with identical portal/camp cameras and the original BEFORE images. Grass/path change and portal beam now read clearly in the proxy. The camp camera projects the beam over part of the Keeper; measured spatial clearance is separate from that screen overlap. Kits and Roblox effects still require Studio. Compared against the previously supplied Grow a Garden / Steal a Brainrot references for focal-object hierarchy; no new external reference assets used.

Lesson: when enlarging an objective, measure posed bounds plus arrival tolerance, because anchor distance alone misses clipping.
