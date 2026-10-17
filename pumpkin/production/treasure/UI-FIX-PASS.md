# Steal a Treasure: UI fix pass

2026-10-17. Source-only Lune mount into `slice-v2/prototype/guardian-greybox.rbxl`; no Rojo build, commit, publish, or Play-session save.

## Delivered changes

- `slice-v2/prototype/Greybox.client.luau`: reserve a 60-pixel objective gutter and position the 24-pixel icon within it. Roblox padding also offsets child icons; previously the icon occupied the beginning of the text area. The icon now ends 20 pixels before the text area. The goal belongs to GreyboxGoal, not TreasureCoreHud. Goal wording and responsive sizing are unchanged.
- `prototype/meadow-v4/Section7.luau`: construct SHELF and SPIRAL lettering on both faces using the existing shared style. Private `S7Caption` metadata prevents generic RouteLabel decoration from rebuilding these faces. The +X arrival sees the Back face, which the original one-face constructor did not populate. Local AlwaysOnTop lettering within 70 studs clears the overlapping post; no board, post, bolt or other world geometry moves.
- `slice-v2/prototype/HomeArt.client.luau`: give the visible SummitAcorn's GoldenBody a shared-style `Golden Acorn` billboard, 4.5 studs above its center and visible within 70 studs. It follows the existing cosmetic model through nest/carry/drop updates and is destroyed with that model. Hide the duplicate GoalCaption on the locally hidden authoritative root. The label faces the camera, sits above the cosmetic stem, and respects world occlusion.

## Enter button investigation

Checked Greybox's registration, PromptShown/PromptHidden tracking, per-frame nearest-prompt selection, the fallback button, TreasureUIWorld, TreasureCoreHud and StudioPass capture cameras. The fallback already requires an enabled legal prompt, the player's HumanoidRootPart and distance <= that prompt's MaxActivationDistance. Selection is cleared every frame when those conditions fail. Prompt triggers, input and all of this selection logic remain byte-for-byte unchanged.

**Inferred capture artifact:** StudioPass captures change CameraType/CFrame without moving the avatar. The supplied S5 base and S7 arrival views still display the Home goal, `Enter the central portal`, consistent with the avatar remaining at Home while the camera tours Meadow. A camera's distance from a portal does not establish the player's distance. No real-player out-of-range failure was established, so no prompt visibility/trigger change was made, as requested. Screen-capture tooling outside StudioPass and a live avatar walk-away remain **UNKNOWN**; there is no connected Studio tool in this session.

## Evidence and limits

Inspected `S5/studio-r4-base.jpg`, `S7/studio-r4-arrival.jpg` and `S3/studio-r4-middle-bright.jpg`. The S3 image confirms icon/text overlap; S7 confirms blank approach-facing boards and the absent acorn label. The reverse-face/replication explanation is code-supported inference, not a recorded live replication trace. The short original acorn-caption range and locally hidden root are checked code; their precise contribution to the reported missing label is not isolated live.

Reuse: existing UIStyle.sign/billboard/panel and the existing offline suites; no dependency, external code, art, font, upload or licence added. The established project UI is the reference for this maintenance patch. `treasure/UI-AUDIT.md` names Steal a Brainrot's floating-tag outline as the strongest local reference for floating tags, explicitly based on promotional crops rather than verified live HUDs. This patch retains that outlined shared style; no new side-by-side score or independent visual verdict is claimed. New screenshots, device readability, real-player prompts and StudioPassAll remain **UNKNOWN**, pending Claude's fresh Studio review.

The exact Keystone Roblox Process Playbook was not available through this session's tools or the checked local active-work filename inventory; it was not claimed read. Applied the installed Roblox production skill and existing project pipeline within this narrow maintenance scope.

## Verification

- Backup created and byte-verified **before source edits/mount**: `slice-v2/prototype/guardian-greybox.pre-uifix.rbxl`.
- Backup SHA256: `d611899d5a7b80af92235439c8c2f69f38332b7556dff98494a665f9d605b527`.
- Mounted SHA256: `5ee7eff93109e87c614cc7f813b58bd0b4369bde74bef56110be54aac0399d81`.
- `ui-fix-build.luau`: **PASS**, 81 scripts at O0/O1/O2; actual objective/acorn constructors; both actual summit sign faces survive repeated actual generic decoration. Neutralizing only the three changed sources makes the entire serialized place equal to the backup. Thus Workspace geometry/properties, all other source, gameplay, trigger/input logic, saving, tests, captures and assembled sections are preserved.
- Existing offline behavior suite: **PASS** (`ui-fix-behavior.log`).
- Existing 50-seed suite: **PASS** (`ui-fix-50-seed.log`), including placement, PvP/trap and walking-floor/cliff/cover contracts. This suite uses legacy Layout; it does not establish Meadow live navigation, timing or device performance.
- Existing offline offset/late-kit/failure-isolation contracts: **PASS** (`ui-fix-contracts.log`, `UI-FIX-CONTRACTS.json`).
- Existing production N8 DropSample: **PASS, 31,824 samples / 20 routes / zero failures**. Final reports contain 14,904 + 8,280 + 8,640 samples. Merge verifies complete exact-once route coverage and the mounted SHA256 for all three reports (`UI-FIX-DROPS.json`, `ui-fix-drop-merge.log`). Each worker used 194 kit swaps with zero fallbacks. Conservative kit bounds and offline rays do not establish mesh-triangle or Studio physics behavior.

Evidence-routing correction: the first wrapper renamed the shared DropSample basename too early, so worker JSON files collided. Worker 2's report was preserved before worker 1 completed, and worker 1's report was then preserved. Worker 3's initial log records a successful run, but its overwritten JSON is not used as final evidence. The wrapper now routes each worker's write to its own filename; worker 3 was rerun successfully to produce its complete report (`ui-fix-drop-3-retry.log`). No gameplay source, existing suite or sample lattice was changed by this correction. The final merged evidence uses `ui-fix-drop-1.log`, `ui-fix-drop-2.log` and `ui-fix-drop-3-retry.log`.

Commands use the pinned executable `C:/Users/zerha/.rokit/tool-storage/lune-org/lune/0.10.5/lune.exe`; the PATH Rokit shim failed with `home directory not found` before the backup run, so the installed binary was used directly. `ui-fix-checks.luau` invokes existing suites without editing them and routes evidence to this pass's filenames.

## Claude's review route

Open canonical fresh. Walk the avatar away from HomePortal, back into range, then turn away; distinguish avatar movement from camera-only tours. At the S7 arrival approach, check both route labels, post clearance and Golden Acorn readability. Steal/drop/carry to verify the label follows once without duplicates; check Open/pet captions still work. Inspect the long objective at desktop and phone widths. Run the existing StudioPassAll suites. Do not save a running Play session over canonical.

## Lessons

- When a capture shows a distant interaction, check avatar position and phase before changing prompt rules, because capture cameras can move independently.
- When padding a text widget with a child icon, position the icon inside the reserved gutter, because UIPadding offsets children too.
- When a sign must read from either approach, construct both faces directly, because deferred decoration and attribute replication need not arrive together.
