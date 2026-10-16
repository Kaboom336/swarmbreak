# Steal a Treasure: UI audit and implemented pass

Decision: use one friendly **FredokaOne** display face, cream text with dark outlines, gold for rewards/actions, cyan for travel/collection, and Config-owned rarity colours. The biggest defect was inconsistent hierarchy and presentation, not a universal Arial font. Do not switch every element to a different novelty face.

## Evidence checked

- OBSERVED: all three `prototype/studio-pass-1/mcp-Roblox_Studio-blob-*.jpg`, `refs-contact.jpg`, and named originals in `treasure/refs-topgames/`. Screenshots show the old HUD, debug pill and huge flat action/objective bars. They do **not** contain a close pet-tag capture; that BEFORE panel in UI-SBS is explicitly a source reconstruction.
- CHECKED CODE: `prototype/core/Hud.client.luau`, `Service.luau`, Config, `Greybox.client/server`, HomeArt, Scene, Arena, Traps, KeeperEffects, StudioPass and Section1. HUD and pet captions already used GothamBold. Objective/action/placement/hint and generic label constructors omitted Font; exact engine fallback rendering is UNKNOWN. Calling the entire game Arial/SourceSans would be inaccurate.
- CHECKED: `treasure/hermes/REFS.md`; it recommends PS99 for reward presentation and Steal An Egg for the core loop. `AI-BUILDERS.md` was not found under treasure. Local project `PLAYBOOK.md` read; the separately named Keystone note and Iris memory tools were unavailable in this session.
- S1 COMPLETED BEFORE UI: `treasure/sections/S1/RESULT.md`, AUDIT and final evidence exist, and the place contains Section1. Created and byte-verified `slice-v2/prototype/guardian-greybox.pre-ui.rbxl` from that post-S1 place **before** Rojo. Merge preserves its Workspace and every unrelated source. No S2 work.
- REUSE: existing UI constructors, Config rarity palette, native Roblox UI classes, existing CC0 timber/art direction. No external UI kit, imported scripts, downloaded fonts or paid assets. Icons are code-native shapes/text. No new dependency licence required; existing licences remain intact.

## Compare with the strongest reference for each job

| Job | Named reference / observed local evidence | Our gap and concrete response |
|---|---|---|
| Floating tag | Steal a Brainrot `_Steal_a_Brainrot_2.png`: strong dark outline, stacked name/tier/income | Use a three-line outlined pet stack, rarity-only tint, gold income, bounded distance. Exact font, scale and live behaviour in that game are UNKNOWN. |
| Friendly text silhouette | Adopt Me `_Adopt_Me_3.png`: broad, playful promotional lettering | Use FredokaOne for our short labels. This is an inferred adaptation; the logo is not evidence of its in-game font. |
| Readable text over saturated scenery | Grow a Garden `_Grow_a_Garden__4.png`: high-contrast title outline | Add contextual UIStroke to letters and a separate panel border/soft edge. Promo caption treatment does not prove its HUD implementation. |
| Reward experience | PS99, as documented in Hermes REFS | Keep reveal, rarity and income together; matching its full hatch presentation is outside this UI pass. |

These crops are promotional images, not three verified live HUD captures. UI-SBS makes that limitation visible. No claim of beating or matching these games is made.

## Complete active UI/text inventory

Every dynamic string emitted through a row's constructor shares that row's fix. Text inside original imported meshes is artwork, not a TextLabel we can restyle.

| Element / source | Before: concrete problem | Implemented fix / remaining acceptance |
|---|---|---|
| Coins total and Coins/s — core HUD | GothamBold was reasonable but both lines competed; dark flat slab, no currency symbol, fixed left offset | Shared rounded gold gradient panel, coin medallion, outlined FredokaOne, compact 165x60 / normal 210x72 layout. Rate remains explicitly labelled Coins/s. Exact text hierarchy still needs Studio review. |
| SaveStatus / plot balance / Loading / STUDIO: UNSAVED | Internal persistence mode looked like a player warning and consumed premium HUD space | Hidden by default; visible only in Studio with existing `StudioPassControl.ShowDebug` (controlled by SSS.ShowDebug). Keep internal save status and persistence semantics intact. |
| Index launcher | Small teal box, no visual collection cue | Cyan rounded panel, diamond icon, 132x48 target, outlined label. |
| OpenTap mobile shortcut | Generic button; mixed treatment with native prompts | Shared cyan button treatment and 48px target; existing nearby/owner visibility and remote checks retained. |
| Index modal shell and PET INDEX title | Fixed 300x360 could overflow landscape phones; inconsistent borders | Shared panel/type; center anchor and viewport-dependent UIScale fit with margins. |
| Index entries: pet/rarity and ? / Undiscovered | Rarity not reinforced; same text treatment for all entries | Config rarity colour only for discovered entries; cream unknown state; same outlined face. Existing silhouettes and disclosure rules retained. |
| Index ViewportFrame silhouettes | Not text; preserve readable unknown outline without falsely revealing a pet | Existing discovery masking retained. Live viewport rendering/focus remains UNKNOWN. |
| Close | Unstyled default TextButton | Cyan shared panel/type; existing 90x48 target. |
| Reveal pet name / tier / income | Multiline parent label could overlap its skip child, no shared rarity language | Separate reward title region above the skip target; tier-driven text tint, 160px-high centered card fitted to width. |
| Tap to skip | Default button inconsistent with reveal | Shared cyan style; existing skip handler and generation guard retained. |
| +Coins collection pop | Box/text lacked consistent outline/depth | Shared panel/lettering, gold amount, existing bounded pop/tween/destruction retained. |
| Objective / carry 1/1 / all goal messages | Inherited default font; grey 90%-wide rectangle obscured world; weak navigation cue | Outlined FredokaOne, dark rounded panel, cyan route icon, width 72% capped 640; 48px compact / 56px normal height, raised above mobile controls. Text/carry state unchanged. |
| Enter / Return / Steal / Grab / Bump / Hold % / contextual Decoy actions | Huge orange 60%-wide bar, inherited font, no corners/depth | Gold rounded 56px target, max 440px and 62% width, arrow icon, bounded type; same selection/hold/revalidation logic and remote paths. |
| Place / free-spot rejection / Rotate / Snap ON-OFF | Default rectangular controls and mixed font, fixed vertical scale placement | Shared rounded panels and outlined type; bottom-relative positions moved above action/objective, existing key/gamepad actions retained. |
| Escape countdown / final-five-seconds warning | Existing GothamBold/stroke, fixed box, stray '?' separator | FredokaOne with UIStroke, responsive width/height, clear ESCAPE label. White/amber/red timing states retained. |
| Trap invalid-floor/sight/cooldown hints | Default small white text over arbitrary ground | Dark shared panel, capped outlined type, responsive width, raised above controls. |
| Native proximity prompts: core Open and plot Collect | Default engine visual competing with custom bars | Custom gold billboard cards for these two prompt types, touch/mouse hold forwarding, E/X native input retained, hold feedback, connection cleanup on hide/removal. Ownership, LOS, range and hold duration stay authoritative. These need live input testing. |
| Generic goal/item/pen/guardian/trap labels — server label factory | Fixed 240x48, inherited font; all through-world at 180 studs; equal visual weight | Shared billboard factory: 7-stud + 28px width / 1.5-stud +12px height, outline, arrow; ordinary tags 70 studs and occluded. Return goal 140 studs and AlwaysOnTop. Item retains stricter existing 32-stud visibility. Dynamic caller text writes remain valid. |
| Golden Acorn / FIRST RUN / nest/carry/drop captions | Tiny labels with distant clutter | Same world-size style and existing per-state range/hiding. Golden Acorn visual/steal semantics unchanged. |
| Pen vacant / owner / coin-gate text | Same generic label style; no hierarchy | Shared generic tag above the unchanged marker; owner display names preserved. No RichText enabled on user-supplied names. |
| GUARDIAN / guarding and state messages | Generic debug-like caption | Shared outlined face, occluded normal tag; actual attack warnings retain their separate timing and colours. |
| DECOY arming / expiry / state text | Generic default tag | Shared generic label factory, bounded distance and occlusion; decoy state strings unchanged. |
| Home pet name / rarity / income | Fixed 200x84; entire stack tinted; fallback 650-stud range. **Tier branch returned before parenting TextLabel**, making a real tiered pet caption empty | Factory parents text immediately; 6-stud+36px by 2.8-stud+18px billboard, max90, occluded, outline. Cream name, Config colour rarity marker, gold $ income. Bounding-box-based height and distance shrink; minimum text size1 avoids preventing world shrink. Actual zoom/pop-in still UNKNOWN. |
| Legacy non-tier pet fallback | Embedded Common/Rare colour text, unknown rate | Shared font/stroke/distance/position; existing explicit `?` rate retained instead of inventing income. |
| Meadow entry / secured-home direction / locked destination labels / ShopSign | Mixed generic text; destination labels used 145x26 at up to700 studs | Generic labels share style; home destination names use 8-stud+24px /1.4-stud+8px, cyan, max180, occluded. Existing shop structure retained. |
| MAIN/CAMP route-sign family mentioned in task; S1 WEST/BRIDGE/RIDGE boards | Thin unoutlined or inherited labels; weak arrow cue; S1 labels single face. MAIN/CAMP glyphs were not legible in supplied shots | Reuse actual S1 wooden boards; client applies wood material, cream bold outlined text plus route arrow on BOTH faces, max120 and occluded. No route/collision movement. MAIN/CAMP are not claimed as inspected live labels; any baked mesh lettering needs a source-art pass. |
| Keeper '!' warning and stun-star glyphs | Warning explicitly used removed GothamBlack enum; effect text mixed with HUD typography | World decorator applies shared supported face/stroke to unstyled text labels, preserves original warning/star colours and animated lifetime. Timings/FX geometry unchanged. |
| StudioPass debug panel, KeeperState, route timing, capture diagnostics | Developer UI, not player experience | Existing Studio-only debug gate preserved. Not polished into player HUD; no test coordinator code changed. |
| Roblox-owned chat/player list/system prompts | Engine-owned UI outside this game style module | Left to engine; no CoreGui/security changes. |

## Why the fonts and tags looked weak

The screenshot's broad grey/orange bars gave ordinary UI most of the frame's attention. Their default type had neither the weight nor outline to sit comfortably over bright 3D scenery. Adding a novelty font alone would leave the oversized bars, equal-weight rows and missing symbols intact. FredokaOne supplies a coherent friendly silhouette; LuckiestGuy/Bangers would overstate long instructions. GothamBlack is listed as removed in current Roblox docs; it is not a sound new dependency. Exact reference font IDs remain UNKNOWN.

Fixed pixel billboards neither express object scale nor recede naturally. The pet code also tinted the whole stack instead of separating identity, rarity and economic value, and its tier branch had a genuine parenting bug. Our mixed stud/pixel sizes provide world scaling with a small readability floor; MaxDistance controls clutter, and only the important return marker is intentionally visible through scenery. Pets do not reveal themselves through walls.

Roblox confirms that BillboardGui scale dimensions are **studs**, unlike normal GUI scale; offsets are pixels. AlwaysOnTop controls occlusion. [BillboardGui documentation](https://create.roblox.com/docs/reference/engine/classes/BillboardGui). Supported font names and GothamBlack removal were checked in the [Font enum documentation](https://create.roblox.com/docs/reference/engine/enums/Font).

## Proof and checks

- `UI-SBS.jpg`: real before crops, a clearly labelled pet source reconstruction, offline after mockups, three named reference crops. Comic Sans Bold is an explicitly labelled **local rendering proxy**, not a claim that FredokaOne was rendered offline. No Studio screenshot fabricated. `ui-proof.ps1` reproduces the board.
- `UI-CHECKS.json` / `ui-build.luau`: 69 mounted scripts compile at O0/O1/O2; 63 unrelated sources unchanged, including S1, gameplay rules and eight suite implementations. Serialized Workspace byte equality. Real-instance checks for text vs panel stroke, corners/gradient/icon, billboard scale/range/occlusion, two-sided wood sign, and the executed tiered-pet caption branch.
- Selene: shared style, world/prompt decorator, core HUD, Greybox client and HomeArt have zero errors, warnings or parse errors. `git diff --check` passes for edited tracked UI sources.
- `slice-v2/prototype/check.luau`: PASS, including 50-seed geometry, place/ownership, solo/PvP/drop/guardian/trap and conservation contracts (physics/navigation mocked).
- `prototype/studio-pass-check.luau coordinator-only`: PASS policy, core save/load/replay, coordinator/reset/failure/timeout and real-store refusal checks.
- Running that verifier **without** `coordinator-only` fails its historical `prototype/guardian-greybox.pre-studioprep.rbxl` vs `prototype/guardian-greybox.rbxl` source-freeze assertion (reported `ReplicatedStorage.TreasureCore.Profiles`). Those are older, noncanonical artifacts; the UI merge touches neither. Its checks were not weakened. Current canonical preservation is checked against the fresh post-S1 pre-ui backup.
- Actual Studio rendering, focus, touch/hold behaviour, portrait/landscape layout and all eight live suites after UI: **UNKNOWN**. Previous green results are not inherited.

## Studio review recipe

Open `slice-v2/prototype/guardian-greybox.rbxl`; use owner account and mock persistence. Run StudioPassAll and retain actual output. Capture home HUD, Meadow objective/return goal, one pet of each configured tier, index/reveal, and both faces of a route board. Check 390x844 portrait, 844x390 landscape and desktop; verify E/X and touch press/release/cancel, Collect ownership, safe-area spacing, text clipping, modal close/skip, rotated camera, and tags at 10/40/90/140 studs. Turn SSS.ShowDebug on/off: save pill must only appear in Studio while on. Reject any unreadable text or control overlap before visual acceptance.

Self-review: before crops preserve aspect ratio; no Photoshop-style scene improvement was passed off as runtime. Compared with Brainrot, our tag still lacks a verified live scale/spacing result; compared with Adopt Me, exact face shape is not shown by the offline font proxy. Simplify the icon or reduce label length if actual phone rendering is cramped. Independent visual critic/owner acceptance remains pending; no independent score invented. No commit, publish, accounts, spending or external messages.
