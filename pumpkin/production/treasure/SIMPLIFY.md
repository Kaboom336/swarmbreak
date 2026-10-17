# Simplify and smooth — audit before implementation

2026-10-17. Owner, verbatim: "try to simplfy and smoot out the game".
Keep Outsmart and raid slice 1. Players never attack. Launch scope is a
**proposal: Meadow + raid**, not approval to ship more islands or change rules.

## Evidence and limits

CHECKED: GDD.md, ROADMAP-TO-LAUNCH.md, RAID-SLICE-1.md, UI-PASS.md,
CUTSCENES.md, CINEMATIC-MOVE.md, PACIFIST-ARENA.md and production/SOUND-KIT.md.
The requested treasure/SOUND-KIT.md does not exist; the production-root file
is the active source. Inspected all 42 requested JPGs (root JPGs and every
sections/*/studio-*.jpg), grouped in simplify-screen-audit-0.png through -3.png.
Read existing shared UI, camera, input, mount and offline-check code.
The separately named Keystone Roblox Process Playbook is unavailable in tools
and the checked local active-work directory; its exact contents are UNKNOWN.
Applied the owner's supplied real-art, core-moment and reference rules.

These are historical live screenshots, not captures of this pass. ui-live-home
already has the top banner but still shows `> Meadow / Enter` and bottom Enter.
Earlier S7 pictures show the Guardian state; S9 shows vacant pens. Current
UIWorld already suppresses vacant pens and cleans Keeper captions, so those
are existing fixes to preserve, not new work to claim. S3 pictures show exposure
clipping; later dimmed shots improve it. No Studio play, child observation,
new visual review, live timing, audio review or device test was performed.
The child's questions below are **inferred**, not playtest quotations.

## First three minutes, through a new 10–14 year old's eyes

Times describe a review route, not measured completion times. The real first
pet/income timing is UNKNOWN; old roadmap claims of missing economy conflict
with newer implemented Core/Hud sources and must not be treated as current truth.

| Moment / inferred question | Friction checked or inferred | Decision / reason |
|---|---|---|
| Arrival: where do I go? | Central portal, locked island row, plots, Coins, Index, settings, world caption and bottom Enter compete. | **Merge** the existing action into the top objective's location, with one visible instruction. Keep Coins/Index/settings available; do not invent a tutorial menu. |
| Arrival: is this a developer test? | `> Meadow / Enter`, `> GUARDIAN / guarding`, `> Pen 2 / vacant` look like diagnostic strings. | **Hide** redundant portal and empty-pen labels locally; **simplify** Keeper and occupied plot plates using existing mirrors. Keep !/?, charge/jump and raid warnings. Never hide a safety cue. |
| Arrival: what are all these islands? | S10 shows Cave plus coming-soon/locked destinations before the first successful run. | **Hide** only redundant noninteractive coming-soon captions locally. **PROPOSAL** below for the actual selectors; don't disable a working portal. |
| Enter: why two instructions? | Top goal plus bottom Enter/action, with world Enter text, repeat the same verb in ui-live-home. | **Merge** action and objective into one top slot. Existing button, keyboard/gamepad/touch handlers, selection, range and hold stay intact. Countdown stays in that slot during carrying. Refusal feedback wins over generic goals. |
| Enter: why did my view move? | Arrival 3.2s, repeat arrival 2s, Keeper look 2s, steal orbit 2s and finish 2.4s; controls/timer still run. New movement skips shots, making them flash. | **Simplify** to brief title-only beats and **cut** repeat arrival and Keeper exposition. Keep actual attack tells. No camera takeover during a timed getaway. Audio continues from authoritative outcome signals. |
| Approach: which route matters? | S2/S3 repeat SHORTCUT/EXIT markers, many lamps, S5 WALK sign, S7 ALL/SHELF and ground route marks. | **Keep** junction/destination and hazard signs. **Hide** exact duplicate cosmetic route captions in the same local view, without removing floor, cover, lights or collision. Extra lamp/rock pruning needs Claude's actual view review; don't guess which geometry is expendable. |
| Approach: is that treasure or a light? | S7 r2 acorn blown out; r4 silhouette is clearer. Lanterns and bright beam compete. | **Keep** the corrected focal acorn and lighting; **cut** no physical prop from these old captures alone. No fresh exposure claim. |
| Steal: what do I press? | Existing continuous two-second hold and percent completion; GDD's one-second example is stale. | **Keep** the real hold and progress; **simplify** one-line goal, no fabricated timing. Hold tuning could affect success/fairness, so is a proposal only. |
| Escape: can I fight? | Guardian threats, Bump contest and new runners could read as enemies to defeat. | **Keep** Outsmart: sidestep committed attacks, use cover, switch raid lanes or normal Jump. **Cut** no threat. No attacks, HP, defeat reward or new control. Existing player contest is an owner-rule ambiguity listed below. |
| Escape: why did I lose the acorn? | Provisional ownership, 60s clock, first-hit retention, mercy, drop/settle/Grab, idle-drop and tunnel hazards are many exceptions. | **Keep** same-item/deadline, warning and safe-return rules. **Simplify** goal to the portal and retain real refusal/recovery feedback. Rule reductions are proposals only; don't conceal warnings to pretend rules disappeared. |
| Escape: must I wait for the raid? | Two runners, finite command/tell/charge/recovery, optional wall vault. | **Keep** lane chevrons/chirp, complete client warning, walking connection, bypass and native Jump. Never shorten the 1.2s minimum complete warning or make the raid mandatory. Idle attack/recovery tuning is gameplay, not this pass. |
| Escape: too much screen? | Countdown, action, banner, title card, nameplate and camera movement can coincide. | **Merge** timer with the single actionable instruction. **Cut** Keeper exposition and camera motion; short payoff title only. Preserve red countdown and tactical cues. |
| Home: what next? | Escape celebration can hide the direction to own plot. Carry persists into placement; free placement adds rotate/snap controls. | **Simplify** finish beat; **keep** explicit place goal, own-plot highlight, placement controls and validation. Never remove touch Rotate/Snap while leaving those rules active. |
| Pet: did I actually get it? | Open/skip/reveal, rarity, income, coin flights and Index can compete. | **Keep** server-confirmed pet/name/income card and skip, real Coins and Coins/s. No fake first reward. **Keep** optional Index access, no popup on join. Automatic opening or collection changes need owner decision. |
| Coins: why zero / why upgrade? | Actual plot collection and feeding may differ from GDD's passive-income promise; old roadmap is stale. | **Keep** honest replicated counters and collection prompts. **PROPOSAL** to unify collection/opening below. No inferred Coins, changed yield, price or unlock. |
| Repeat: do I need all systems? | Decoy planning after three escapes, Feed, Index, other islands, placement options; some may rarely matter. | **Keep** optional post-unlock Decoy and Outsmart. **Hide** vacant/debug labels, **cut** repeat arrival. **PROPOSAL** to defer unused systems at launch after measured use, rather than delete real functionality based on no play data. |

## Side by side: simpler first-minute reference bars

Official listings checked 2026-10-17; local UI-SBS and reference imagery checked.
These establish descriptions and visual hierarchy, not observed current first
three minutes or measured retention. Exact live tutorials/HUD are UNKNOWN.

| Reference | What is supported | Apply to this one Meadow slice |
|---|---|---|
| [Steal a Brainrot](https://www.roblox.com/games/109983668079237/Steal-a-Brainrot) | Listing presents buy/steal → earn money, then rebirth/gear. | One coveted thing → visible home earner. Keep one active verb; don't copy its slaps/combat. Our layered mercy/idle/trap rules require more teaching. |
| [Grow a Garden](https://www.roblox.com/games/126884695634066/Grow-a-Garden) | Listing presents buy seed → plant → grow → harvest. | One object and a visible consequence at each step. Keep placement/reward readable; don't front-load every destination and economy option. Our repeated camera beats interrupt that flow. |

Best comparison for economic clarity: Steal a Brainrot; for object-to-reward
legibility: Grow a Garden. This pass is one candidate for Zion/Claude to judge;
no independent critic verdict or reference parity is claimed.

## Build boundary recorded before edits

Reuse inspected local UIStyle/UIPresentation, native button/input path,
Cutscenes controller, Lune overlays and accepted offline harnesses. No new
external code/assets; existing MIT/Apache and CC0 notices remain unchanged.
Back up changed sources and both complete places before touching them. Apply
client presentation only, mount Meadow via Lune and shared changes into Cave
through cave-v2/build.luau. Prove complete undo equality, exact Workspace and
server trees. Do not launch Studio, regenerate maps, commit or publish.

## PROPOSALS — owner decision required; NOT BUILT

1. Launch Meadow + existing raid only; defer Cave and later island access rather
   than teach five destinations. Preserve Cave build for future review.
2. Resolve “players never attack” against existing PvP **Bump**. Removing Bump
   changes contest rules; this pass must not silently disable it or rename it
   to imply the underlying action changed. No new attack is added.
3. After real novice failures, consider one simpler pre-escape-loss explanation
   or removing idle-drop if it rarely prevents stalling. Preserve 60s deadline,
   durable secure and fairness until explicitly approved.
4. Consider automatic opening/collection and a default placement orientation,
   removing a step only if the intended economy/plot behavior is approved.
   Current collection, placement, opening, saves and earnings stay exact.
5. Consider one first-run threat vocabulary, with Decoy/extra tunnel rules later;
   retain the approved raid and Outsmart. Any changed unlock, hazard, hold,
   cooldown, warning, shield, mercy, charge or recovery time needs a rule review.
6. Cut systems that measured play shows are unused; usage is UNKNOWN now.
   No new upgrade, trap, map, pet system, tutorial quest or scoring layer.

## Review route and lessons

Claude: fresh canonical Meadow, enter → hold Steal → Outsmart/raid bypass →
escape → own plot → open/skip → collect actual Coins. Check desktop, phone
portrait/landscape and controller; record overlapping UI, late warnings, input
focus, readability and first real income. Zion judges this one before scaling.
Offline checks cannot establish smooth feel, fairness or fun.

## Implementation and offline evidence

Implemented after this audit: shared top instruction slot with the original
action button underneath a noninteractive text mirror; hold progress and real
countdown share its caption. Refusals stay visible. Input/hold/selection/remote
code is otherwise exact against the immediate backup. Removal restores the
original button caption. No new input controller or gameplay attribute exists.

Portal `Meadow / Enter` and noninteractive coming-soon captions are hidden
locally. Existing vacant-pen suppression and readable Keeper warnings remain.
No route/hazard sign, prop, floor, light or collision was deleted. Repeated route
signs and lamp density remain a Claude visual-review candidate: screenshots
alone do not establish which repeated sign is unnecessary at a junction.

First arrival is now a 1s title only; repeat arrival and Keeper exposition are
suppressed. Steal/geode titles last 0.65s, escape/cart blast 0.9s. All keep the
live camera; skip, expiry, binding cleanup and watchdog remain. These durations
affect presentation only. Guardian, tunnel, raid and mercy tells are unchanged.
Existing camera movement/FOV, audio, reward card/skip, Coins/Index/settings and
all preferences remain available. Shared changes are mounted in Cave without
changing Cave gameplay or expanding launch scope.

Backups: `simplify-backup-20261017/` (eight original files, including complete
places). Build: `simplify-meadow-build.luau` and
`prototype/cave-v2/build.luau simplify`. Reports `SIMPLIFY-BUILD-*.json` prove
all 101 Meadow / 54 Cave scripts compile at O0/O1/O2, exact full overlay undo,
and exact saved server/Workspace trees against the immediate backup.

`simplify-check.luau` guards the allowlist, module/client parity and original
input source. `simplify-ui-client-check.luau` executes actual Objective/UIWorld
with real UIStyle at four safe-area sizes; it checks action/timer/refusal/drop/
home placement and cleanup. These service fixtures do not prove engine hit
testing, text rendering or device behavior.

`simplify-cutscenes-check.luau` reuses the original guarded real-client service
fixture with current presentation expectations: no camera leases, shorter
expiry, no repeat/wake, skip, binding/capture, success replication ordering and
actual CinematicMovement composition. Obsolete assertions requiring long
camera takes or repeat arrivals are explicitly superseded, not claimed passing.

`simplify-existing-checks.luau` retains existing gameplay assertions: contracts,
50-seed routes, behavior/reset/coordinator, three complete N8 DropSample shards,
raid lifecycle/client/vault, shared core, sound, movement/settings and Cave N8.
Cart drive/boarding run directly. Outputs are isolated in `simplify-evidence/`.
The accepted raid-era capabilities/roster adapters are reused. Added adapters
give old movement fixtures actual UIStyle/safe-area services, compare UI's
place preservation to the immediate backup, and allow only the four independently
guarded shared presentation sources in raid's old source whitelist. UI's old
literal Greybox presentation assertion uses its matching pre-edit snapshot;
the new current-client contract separately proves every input line unchanged.
Sound's historical pre-feature full-place preamble is replaced by the stronger
current complete allowlist proof; its authority and mixer fixtures are retained.

`simplify-legacy-check.luau` re-executes the three known obsolete archival checks
against both immediate backup and final with matching client source snapshots.
Their failures are recorded as failures, never feature passes. The obsolete
core alias equality is also checked separately from passing core domain tests.
Final statuses, hashes and sample coverage are sealed in `SIMPLIFY-FINAL.json`.
No Studio play, fresh screenshots, independent live review or owner acceptance.

- When screenshots predate a UI fix, check mounted code before claiming a new
  fix, because older labels may already be suppressed.
- When merging an action with a goal, retain the original button and handlers,
  because a prettier prompt must not change hold or controller behavior.
- When a chase timer keeps running, remove camera exposition before shortening
  safety tells, because presentation can be cut without changing fairness.
