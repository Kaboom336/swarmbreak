# Pumpkin production gauntlet

Execution contract, 2026-10-07. User requested execution, not only a generated prompt. This contract scopes the current game; the reusable workflow lives in `roblox-game-production/`. No game acceptance is implied by this document.

## 1. Mission

Deliver a simple Halloween magic garden that is satisfying solo and visibly better with friends. Current candidate: grow pumpkins of different sizes, harvest, awaken and guide them through ghosts, burst, earn gold and grow bigger. Test this candidate before expanding it. Catapults are superseded. Preserve historical source and assets.

The immediate milestone is an editor-visible garden and one proven outing, not a larger feature list. Compare particular qualities against named references using the [quality card](PUMPKIN-QUALITY-CARD.md). A beautiful concept board does not prove the built game.

## 2. Bar and acceptance criteria

- Q1 — Editor and package: the identified Desktop file opens to the intended editable garden with ground, spawn, useful camera framing and recognizable focal meshes before Play. During Play there is exactly one active scene and no historical roll/catapult UI. Verify both editor and Play captures plus hierarchy inspection; tests alone cannot pass this criterion.
- Q2 — Comprehension and rhythm: a first-time player identifies the next action, completes harvest → cast → contact → burst → reward and can choose the next improvement without coaching. Record their actions, confusion and waiting in a continuous session. Timing values remain tuning hypotheses. If basic direction is unclear, revise the loop before adding content.
- Q3 — Hero and growth: small and big pumpkins are visibly different at normal play distance. A player recognizes ready growth, ownership, shell damage and exhaustion without relying on a large text panel. Camera and controls remain useful with the big pumpkin. Inspect matched-distance captures and a moving clip.
- Q4 — Spell feel: awakening, contact, cracking and burst each have a distinct visual/motion/sound beat. A burst has a readable origin, direction and result, and clears before the next decision. Test sound on/off and reduced effects; compare captured beats with a named, timestamped reference. Placeholder ping audio and unverified seams remain open art tasks.
- Q5 — Shared play: two friends deliberately trigger a chain, recognize how both contributed, repeat it intentionally and see the shrine change. No forced partner burst or passive proximity credit. Solo progress remains complete. Record both clients and server outcomes; a shared meter or source branch alone is insufficient.
- Q6 — Interface and performance: actual phone and desktop views keep next actions readable, controls clear of CoreGui and camera comfortable. Measure representative solo and busy multiplayer sessions on identified devices/settings. Set project budgets from those measurements before scaling content; do not invent frame-rate proof from unit tests.
- Q7 — Authority and release evidence: relevant source/tests/build pass for the submitted artifact; reward ownership, duplicate grants, death/reset, session fencing and save/rejoin have direct evidence appropriate to their risk. Imported assets have provenance and inspected descendants. Obtain fresh authority review for consequential changes. Preserve the free-only/no-script-import/no-commit-before-user-approval boundaries.

## 3. Roles

Root owns scope, criteria, reference evidence, integration decisions and the workbench. A separate implementer owns each substantive submission. A fresh critic reviews direct artifacts without implementer narrative; a second independent critic reviews consequential authority/persistence changes. User evaluates the actual product and authorizes commits. Follow `references/gauntlet-execution.md` for dispatch and review isolation.

## 4. Loop

Inspect → select the largest evidenced defect in one area → implement → verify and build → capture → fresh critique → repair → new fresh critique. Integrate reviewed slices, then review the full outing for regressions and coherence. Prioritize startup and gameplay failures, then comprehension, feel and presentation. Expand forms, giant sizes or new zones only after the first outing clears its applicable gates.

Missing evidence yields PENDING, not an invented defect or a pass. A failed hypothesis can change the design: record what players did, what changed and what the next experiment will test. Do not accumulate features to conceal a weak core action.

## 5. Delegation contract

Every task includes: one observable outcome; owned paths; source brief; verbatim criteria; reference pointers; preserved work; required checks/captures; build destination; current blockers. The implementer returns changed paths, raw evidence and a criterion-to-evidence map. Assign shared-file integration explicitly. Preserve current user decisions across repairs.

Next implementation contract: Q1. Make the garden editable before Play using a single canonical scene definition and an idempotent runtime initializer. Preserve dynamic crops, ghost animation, safe spawn-before-yield ordering and private script-free art. Do not create duplicate ghosts/shrines, add legacy map geometry or manufacture a fake finished ground. Investigate Studio baking first; Lune's unsupported Terrain/Model methods are not interchangeable with Studio APIs. Verify editor → Play → Stop → Play and solo/two-client startup. Build with `garden.project.json` only.

## 6. Critic contract

Return PASS, FAIL or PENDING first. For every Q criterion in the task, cite the inspected artifact/capture/check and give a reproducible defect or missing evidence. Inspect the submission, not previous verdicts or implementer claims. Compare matching contexts: ordinary gameplay distance, equivalent interaction phase, recorded viewport and sound state. Reject spectacle that obscures the target or disguises an unreadable action. Do not infer fun, retention or commercial quality from listing counters, art boards or source correctness.

## 7. Parallel work

Parallelize independent research, asset inspection and nonoverlapping implementation only when capacity is available. Keep dependent mutations/reviews sequential. Do not reuse an old critic to grade a retry. If agent capacity is unavailable, record the failed dispatch and advance root-owned inspection/contracts/evidence; substantive independently reviewed work stays pending.

## 8. Durable ledger

`workbench.md` is the entry point for current state. Keep one canonical current project/file/hash. Each slice records owner, attempt, criteria, verdict, raw checks, capture links, open defects, blocker and next action. Historical records remain explicitly historical. The quality card links references and observations to concrete build captures; unknowns remain unknown.

## 9. Stops and escalation

Continue active work through repairs; do not stop after an arbitrary four-minute interval. Stop the dependent action at a genuine missing permission, unavailable Studio evidence, reviewer-capacity block or explicit user decision, while completing independent authorized work. Retry external failures only after conditions change. Ask only for the minimal unblock. No unattended loop, publication, purchases or commit is established by this contract.

## 10. Done and report

A slice is accepted only when every applicable criterion has direct evidence, fresh independent approval and any required user decision. Report the concrete change, build/check result, largest remaining quality gap and next test. A process-document pass does not accept the game. This project reaches its first product milestone when Q1–Q7 pass for the same identified build and the user says the result is good; later projects choose their own representative milestone and budgets.
