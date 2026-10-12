# Steal a Pumpkin v3 — self audit

Result: 14 generated concept PNGs across 11 requested sheet families; 14 labelled comparisons; `_sheet.jpg`. Eight families scored 8/10; hub, pets and guards/fight scored 7/10 after the three-call family cap. These are generated screenshot concepts, not captured Roblox builds or owner-approved art.

Checked: fully read REDRAW-RULES.md, REFS2.md, the TikTok delta and imagegen SKILL.md; visually inspected each requested old side-by-side and all three supplied reference frames, plus the named collectible references and original hatch identity. Passed the named local references to built-in `image_gen`; 28 successful generations, no CLI/API image generation. Inspected all final PNGs and 14 new comparisons. Main comparisons use REFS2's named best frame; mass hatch and fight variants use the corresponding action frame.

Owner-reported: reference games, capture dates and source-video metadata come from REFS2.md; not independently verified. Self-scored: appearance, readability, scale and HUD coverage. UNKNOWN: exact palette hex conformance across shaded generated pixels, actual engine camera studs, measured HUD percentage and in-engine 40px tool behavior. All UI balances, rates, odds and HP shown are illustrative concept values, not game-code changes or revenue evidence.

Exception: Windows Python available for execution lacks Pillow; the installed Pillow belongs to an inaccessible Python 3.14 runtime. Package downloads were unavailable. Comparison JPGs and contact sheet were therefore assembled with Windows System.Drawing, **not Pillow**. `_assemble.py` contains the Pillow reproduction workflow; `_assemble-windows.ps1` is the executed fallback. Selected PNG art was copied unchanged from built-in generated_images. No game code edited and no commit made.

Phone override applied: joystick + JUMP + ONE context action. `first-5-min.png` shows SMASH; `hud-phone.png` shows STEAL beside a nest. This supersedes the no-action-button rule. Biome sky colors and the three-view zone strips follow the explicit per-sheet exceptions. Scythes uses the requested seven-slot test hotbar, not the launch hotbar. Ordinary world pumpkins are faceless; nest pumpkins glow. Best attempts were retained when a later retry regressed.

## Family scores

| Sheet | Successful calls (max 3) | Selected attempt | Self score | Remaining gap |
|---|---:|---:|---:|---|
| hub-perspective | 3 | 2 | 7/10 | Billboard remains black-on-white rather than floating stroked white; missing clouds; simpler geometry than PS99. |
| zone1-perspective | 3 | 3 | 8/10 | Stud texture remains stronger than the faint-grid brief; only six ordinary pumpkins plus two nest pumpkins. |
| zones-strip | 2 | 1 | 8/10 | Three-view format reduces viewport width; giant guards sit above arches rather than on the lane. |
| hud-desktop | 1 | 1 | 8/10 | Ground and wall studs are stronger than brief; hotbar cards larger than the 80px target. |
| hud-phone | 3 | 3 | 8/10 | Minor checker pattern on floor; context prompt has a soft backing; button sizing remains a concept approximation. |
| panels-shop-index | 3 | 3 | 8/10 | Bonus bar adds unrequested reward icons; pet tile is small; exact rarity pixel values not verified. |
| hatch-reveal | 3 | 2 | 8/10 | Card is grey rather than white; Puppy head/body proportion is close rather than a production model lock. |
| pets | 3 | 2 | 7/10 | Unrequested game title/HUD and limited overlap; Pumpkin Pup proportion drifts; aura hex values not pixel verified. |
| scythes | 2 | 2 | 8/10 | Witch/King aura surrounds avatars too; details flatten at 40px though hook silhouettes remain distinct. |
| guards-and-king | 3 | 1 | 7/10 | Arena frame passes visually (8); fight variant is 7: duplicated boss portraits, purple subtitle and missing FINAL BOSS sign. |
| first-5-min | 2 | 2 | 8/10 | Chest and action target are separated; target size is smaller than requested; studs remain strong. |

Zones: calls = 1 per strip, covering Z2–Z7; Z1 is Meadow. Hatch: calls = 2 single + 1 mass. Guards: calls = 1 arena + 2 fight. Thus no requested family exceeded three successful generations. Invalid request rejected before generation is excluded.

## Additional frames

| Frame | Calls within family | Score | Gap |
|---|---:|---:|---|
| zones-strip-2 | 1 | 8/10 | Candy sky is pink by biome rule; narrow viewports reduce distant prop detail. |
| hatch-reveal-mass | 1 | 8/10 | Pets are still arranged more evenly than PS99's overlapping mass wall; Common glow trends white. |
| guards-and-king-fight | 2 | 7/10 | Both HP portraits show King; subtitle purple-filled; FINAL BOSS billboard omitted. |

Arena frame alone is 8/10; guards-and-king family is conservatively 7/10 because its fight frame has duplicate boss portraits and incomplete world-sign wording.

## Checklist audit

P = visual pass, M = partial, F = fail, N = not applicable. 8/10 is an artist judgement, not pixel-certified palette compliance. `*` = explicit per-sheet/owner exception; `~` = recognisable identity/palette with precise conformance UNKNOWN. Criteria: 1 screenshot, 2 day/flat palette, 3 props/scale, 4 stroked text, 5 HUD, 6 panels/reveals, 7 identity, 8 reference comparison.

| Frame | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
|---|---|---|---|---|---|---|---|---|
| hub-perspective | P | M | P | F | N | N | P | M |
| zone1-perspective | P | P | P | P | N | P | P | P |
| zones-strip | P* | P* | P | P | N | N | P | P |
| zones-strip-2 | P* | P* | P | P | N | N | P | P |
| hud-desktop | P | P | P | P | P | N | P | P |
| hud-phone | P | P | P | P | P* | P | P | P |
| panels-shop-index | P | P | P | P | N | P | P~ | P |
| hatch-reveal | P | P | P | P | N | P | P~ | P |
| hatch-reveal-mass | P | P | P | P | N | P | P~ | P |
| pets | F | P | M | P | M | P | M | M |
| scythes | P | P | P* | P | P* | P | P | P |
| guards-and-king | P | P | P | M | P | P | P | M |
| guards-and-king-fight | P | P | P | M | P | P | P | M |
| first-5-min | P | P | P | P | P* | N | P | P |

## Retry findings

- Hub: 1 clutter/density failed (6); 2 simplified layout (7); 3 fixed floating text but restored extra props and faces on banners (7). Kept 2.
- Meadow: 1 carved nest faces failed (6); 2 fixed faces but lost collectible feedback (7); 3 restored pickup ring/text and speed trail (8).
- Phone: 1 oversized SMASH scene/control labels (7); 2 STEAL state had invented price and stick hotbar (7); 3 removed price, restored hooked scythe and JUMP label (8).
- Panels: 1 unwanted goal/face ornaments (7); 2 undiscovered rarity borders/words missing (7); 3 differentiated rarity cards and simple tools (8).
- Hatch: single 1 extra currency/hotbar (7); single 2 clean popup/skip (8); mass 1 identity and skip pass, overlap remains weaker than PS99 (8).
- Pets: 1 wrong Common/Mythic aura colors (6); 2 correct color families/rates but unwanted title/HUD (7); 3 cleaner frame but copied billion-scale income and purple Mythic aura (6). Kept 2.
- Scythes: 1 shrine/extra clutter (7); 2 sparse scale and small icon test (8).
- Guards: arena 1 (8); fight 1 carved lamp faces/typo (6); fight 2 removed those but duplicated HP portraits/sign omission (7).
- First 15 seconds: 1 wrong egg hotbar/no navigation icons (7); 2 correct two tools and requested controls (8).
- Desktop and both zone strips: first attempts retained (8).

## Lessons

- When reference screenshots contain faces or foreign currency, explicitly forbid those elements, because the generator imports their semantics along with style.
- When identity is locked, pass a crop of the original character, because whole storyboards encourage layout and lighting drift.
- When a retry loses a correct detail, retain the better earlier attempt, because additional generations do not guarantee improvement.

## v3b redraw round — 2026-10-11

Completed with **built-in image_gen.imagegen**, no API/CLI fallback. Seven originals were copied to `<sheet>.v3a.png` before replacement; `panels-index.png` is new. No game code edits or commits. Passing v3 artwork stayed unchanged. All eight changed/new finals received **8/10 from an independent art critic**, after comparison with supplied best-in-class Pet Simulator 99 and Steal an Egg frames. These are visual judgements, not owner approval or engine screenshots.

The owner's current instructions override the older rules: mobile is landscape with joystick + JUMP + one context action; first-5-min has six landscape frames; hub has eight occupied pens, three giant props, lanterns/path tiles; desktop has denser wild pumpkin rows; Graveyard uses cobble. The unchanged sheets' contact-sheet scores now use fresh JUDGE.md rather than the stale earlier manifest.

| Sheet | Fresh v3a judge | v3b scores by attempt | Selected | Best comparison |
|---|---:|---|---:|---|
| hub-perspective | 7 | 7 → 8 | 2 | PS99H, hub ref-1 |
| hud-desktop | 7 | 7 → 7 → 8 | 3 | PS99H, desktop ref-1 |
| panels-shop-index | 7 | 7 → 8 | 2 | PS99H, panel ref-1 |
| panels-index (new) | — | 7 → 8 | 2 | PS99H, inventory/panel ref-3 |
| scythes | 7 | 8 | 1 | PS99H, scythes ref-2 |
| zones-strip | 7 | 8 | 1 | SAE1, zones ref-1 |
| hud-phone | 5 | 8 | 1 | SAEM, phone ref-1 |
| first-5-min | 6 | 7 → 8 | 2 | SAEM, first-5-min ref-2 |

14 successful generations total; maximum three per image in this round. One hub request was rejected before generation because six references exceeded the five-reference limit; it produced no artwork and is excluded from attempt counts. Full final/iteration prompts and native output paths: PROMPTS-v3b.json.

### REDRAW-RULES checklist against references

P = visual pass; P* = explicit owner/per-sheet exception; N = not applicable. Criteria 1 screenshot, 2 daytime/flat palette, 3 props/scale, 4 stroked text, 5 HUD, 6 panels/reveals, 7 identity, 8 side-by-side reference comparison. Exact hex/pixel/font equivalence remains **UNKNOWN**; P reflects recognizable palette/identity and visual reading.

| Sheet | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | Score |
|---|---|---|---|---|---|---|---|---|---|
| hub-perspective | P | P | P* | P | N | P | P | P | 8 |
| hud-desktop | P | P | P* | P | P | N | P | P | 8 |
| panels-shop-index | P | P | P | P | P* | P | P | P | 8 |
| panels-index | P | P | P | P | P* | P | P | P | 8 |
| scythes | P | P | P | P | P* | P | P | P | 8 |
| zones-strip | P* | P | P* | P | N | N | P | P | 8 |
| hud-phone | P | P | P | P | P* | P | P | P | 8 |
| first-5-min | P* | P | P | P | P* | P | P | P | 8 |

### Evidence and remaining gaps

- Hub: counted four occupied pens on each side. Fountain, HOME/PENS sign and matching armored Pumpkin King throne occupy the middle. Actual throne dimension of about 40 studs is a concept intention, not a measurable engine dimension. Blue/gold pumpkin auras remain subtle.
- Desktop: first attempt fenced the wild field; second restored loose rows but lost the goal; third restored the sole goal while retaining clear centre, windmill and distant nest.
- Shop: one Shop panel, Scythes selected. Corrected red Shop/cyan Index kit and scythe/pumpkin hotbar; detached Witch tooltip covers no labels.
- Index: one Index panel, twelve cards, three discovered, 3/12. Restored full Pup, matching Ghosty and Candy Bat; removed misleading pointer. Star badge counts are uniform across tiers.
- Scythes: one player holds Witch; Rusty/King stand tools have larger auras. Physical crop at **40 px per hotbar slot** inspected by parent and independent critic: all seven handles/hooks/numbers remain readable (`_inputs/scythes-40px-check.png`). Held Witch/Epic label and incidental Pup income are absent.
- Zones: grey cobble / dark forest green / saturated teal-lime floors separate immediately. Swamp water reads cleaner than “murky,” but the cauldron/lime edges establish its identity.
- Phone: native **1844×853**, width/height 2.161782, within **0.23%** of 19.5:9. Joystick bottom-left, two tools bottom-centre, one larger SMASH and one JUMP bottom-right. Native generation is a close aspect approximation, not a pixel-exact 19.5:9 export.
- Tutorial: native **1507×1044**, two columns/three rows, whole-grid ratio 1.443487 within **0.07%** of 13:9; six viewports near 19.5:9 with thin separators. Carry 1/1, blue hatch shells and one changing context action are correct. Candy rises from 0 to 1 then resets to 0 without a pictured spend; retained as a minor concept continuity caveat. No first-session timings were playtested.
- All eight `*-sbs.jpg` files and the fifteen-sheet `_sheet.jpg` rebuilt and visually inspected. Comparisons preserve aspect by resizing only; final PNG artwork is copied unchanged from built-in outputs. Audit-v3b.json records image dimensions, hashes and deliverable checks.
- Supplied reference frames were used for visual comparison only; no external asset kit or game code was adopted. Exact font files and reference-video licensing were not established.

### Lessons from v3b

- When gameplay identity is locked, use passing game sheets and limit incidental pets, because unrelated screenshot references can import new faces and shapes.
- When editing a world behind HUD, explicitly preserve every UI element and recheck it, because a density correction can remove a correct goal or change tool slots.
- When six mobile frames must share an aspect, specify both the individual viewport ratio and the whole-grid ratio, because “landscape” alone can flatten the storyboard.
