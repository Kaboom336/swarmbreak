# T1 — playable Studio greybox first

DRAFT future coder task, not authorized execution now. Read SLICE-V2 and ISLAND-PIECES. No art, game-code edits, real saves, commits, uploads or publishing in this milestone. Codex prepares isolated prototype source/build; Claude handles Studio assembly/play evidence. Never run legacy installers.

## Files touched (future only)

- `pumpkin/production/slice-v2/prototype/greybox.project.json`
- `pumpkin/production/slice-v2/prototype/GreyboxConfig.luau`
- `pumpkin/production/slice-v2/prototype/Greybox.server.luau`
- `pumpkin/production/slice-v2/prototype/Greybox.client.luau`
- `pumpkin/production/slice-v2/prototype/guardian-greybox.rbxl`
- `pumpkin/production/slice-v2/evidence/T1-greybox.md`, clips/captures alongside it.

These are disposable prototype scripts inside the isolated greybox, never edits to `pumpkin/giant/src` or imports into the current game. No dependency downloads or new framework. Save/build under this task folder, not Desktop (current path restriction wins).

## Build one core moment

1. Separate local place: home240×192, eight38×28 plain pens, shop block, central portal, island96×144. Label geometry clearly as GREYBOX. Build four authored templates P01/P02/P06/P07; short variants permit3–5-piece recipes. No generated mesh/art sourcing.
2. Server assembles deterministic shuffled recipes with snap/bounds checks and safe fallback. Provide developer-only seed replay controls outside player HUD; do not count QA controls as game features.
3. Local portal moves player to their run slot; one block guardian warns, patrols/approaches, then chases after a1s Steal. Player must visibly dodge around cover, steal one glowing plain ball placeholder and reverse the same route to portal.
4. Catch slows1s, retains loot, grants3s mercy. Return ends guardian threat; own pen can accept that one item as a plain placeholder. This task ends at placement; hatch/income/upgrade are T3, no fake economy in greybox.
5. Slot/run token protects pickup/return/placement from replay. No persistent storage. Full/reset/quit clean up transient state safely. Minimal goal, carry state and own-pen marker; no combat, jump puzzle, scythe or UI framework.

## Acceptance and handoff

- Deliver a local `.rbxl` that opens and plays without terminal work, plus short route: Play → portal → dodge → hold Steal → reverse path → portal → own pen Place. Confirm no scripts depend on an online asset/account.
- Solo: time fresh spawn→steal **<30s**, run portal→portal **20–45s**; log exact observations and seed, including misses. No debug teleport/grant in the timed route. Demonstrate at least3 different valid layouts and replay one seed identically.
- Two clients: distinct pens/slots, no theft of another run item, no reshuffle underneath an active player. Catch/reset/duplicate portal touch never grants twice. Walk all enabled recipes both ways; guardian uses route, not old lane bounds.
- Zion plays ONE run and answers whether dodging/escaping feels worth repeating. Record approval or concrete requested changes; this is the gate to T2, not a self-awarded pass. Art remains intentionally unjudged at this stage.
- Evidence: actual Studio server/client logs, clip/seed/timings, place hash, source dirty state. If Studio unavailable, deliver build and mark runtime/owner check UNKNOWN; do not report T1 accepted.

Next: freeze the working piece geometry and state transitions for T2. Do not multiply final art or start island2.
