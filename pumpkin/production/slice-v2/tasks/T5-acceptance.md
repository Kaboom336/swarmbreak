# T5 — integration, owner playtest and acceptance evidence

DRAFT future task. After T1–T4 handoffs; no concurrent writers. No commit/publish/spend or owner-save reset. Codex builds/tests; Claude handles Studio/design review; Zion checks the10-minute experience.

## Files touched (future only)

- `pumpkin/giant/scene/SliceSmokeTest.luau`, `econ-sim.luau`, `combat-check.luau`, `compile-check.luau`
- `pumpkin/giant/sync.project.json` and integration fixes only in T2–T4 named config/run/server/client/scene files
- `pumpkin/production/slice-v2/ACCEPTANCE.md`, `evidence/T5/**`, local `.rbxl` build in this folder
- Do not execute unchanged `scene/SmokeTest.luau` or modify original `pumpkin/src`.

## Checks

1. Build from frozen source/packages, record hash and dirty state. Compile O0/O1/O2 debug2, verify final loaded values/costs/feature gates and explicit run/save schema. Harness requires Studio + isolated namespace, cleans up on failure and never Admin-resets real data.
2. Sweep50 seeds/preset, replay deterministically, inspect3–5-piece/84–112 path contracts. Walk10 varied layouts with guardian both ways, including longest/shortest/turn/fallback. Repeat assembly and concurrent slot resets; no leaked parts/listeners/rewards.
3. Human fresh spawn, zero grants/teleports/debug speed: log first stolen item<30s, first Candy tick<120s, portal-to-portal run20–45s, first upgrade and preview. Run easy guaranteed-Pup fixture separately, label it; actual first human route stays unassisted. Report exact misses as failures, not averaged success.
4. Solo/two/eight clients plus ninth admission behavior: unique pens/runs, independence, repeated portal touches, other-player cargo/pen rejection, insufficient/replayed buy/unlock, invalid types/nonfinite/spam/proximity. Capacity handles ninth without stealing a slot.
5. Catch/drop/reset/death/leave/rejoin before/after steal, transfer, placement, hatch deadline, reveal and spending. Committed item/pet survives once, no reroll/duplicate; reservations reconcile. Interrupted transfer returns/reconstructs safely. Full pen cannot begin theft and never autosells.
6. Run10min: only specified systems/menus/prompts/clock; zero extra earnings/quests/King/raids/events income. Preview unlock persists but cannot enter/earn island2. Record actual first10min count, not only feature flags.
7. Event expiry during run, before steal, after steal and during hatch; owned variants remain, new expired rolls unavailable, base fallback works, geometry unchanged. Test offline/rejoin grants0 Candy and preserves pending item/deadline.
8. Desktop/landscape touch, mute/reduced-motion/skip/interruption checks. Real low-end device profiling separately from emulation: FPS/frame time/memory/mesh/texture/physics/remote costs; no invented performance pass. Target hardware selection may remain UNKNOWN, explicitly blocking device acceptance only.
9. Side-by-side raw current captures with named local SAE/BGSI/PS99 anchors for home, guardian dodge/theft, escape, pet/reveal and shop/preview. Fresh independent critic names working parts and necessary changes/deletions. Fix concrete failures and recapture affected evidence; no self-certified critic score.
10. Zion plays10min without developer explanation, can find next action and wants another run. Record owner verdict and outstanding questions from QUESTIONS. No further island content or monetization as acceptance repair.

## Deliver

`ACCEPTANCE.md` states STATIC/BUILD, STUDIO, VISUAL/INDEPENDENT, OWNER, DEVICE separately with evidence links, seeds, timings and file hash. A built place is not proof the loop is fun. Overall status stays incomplete if a required gate fails; show actual playable local file and one shortest route to check it. No publish or commit.

Final summary: outcome first, what was checked, remaining UNKNOWN, and1–3 concrete “When X, do Y, because Z” lessons. Keep all authored reports/builds under slice-v2 while this path restriction applies.
