# Slice task queue

Prep only, 2026-10-11. No implementation, commit, upload or publication authorized by this file. Paths below are relative to `pumpkin/`. Read SLICE-SPEC.md including its bottom defaults before starting.

## Execution and merge order

1. **T1 alone:** freeze final-loaded config and CONTRACT.md. T3/T5 agree names/types before handoff. Resolve the proposed smoke contracts listed in `giant/scene/SliceSmokeTest.luau`; do not create a second networking layer.
2. **T2, T3 and T5 may start together after T1.** T2 owns `giant/assets/slice/**`, ASSET-LEDGER.md and evidence/T2-art/**; T3 owns Patch.server.luau and evidence/T3-server.md; T5 owns Patch.client.luau and evidence/T5-ui-feel/**. No shared writes. T5 can prepare logic/layout now; final visual acceptance waits for T2/T4.
3. **T2 core checkpoint:** Claude compares one finished Pup/shell/nest/pen/Scarecrow/Rusty/Iron set side by side with the concepts and Steal an Egg / Pet Simulator 99 boards. Zion checks one before the eight pens/roster expansion. Independent T3/T5 work can continue while this review is pending.
4. **T4 starts after T2's approved immutable full catalogue/manifest.** It owns `giant/scene/SliceScene.luau`, `giant/assets/slice-world/**` and evidence/T4-world/**. It may overlap unfinished T3/T5; never edit T2 assets. Complete T5 visual checks after T4's world delivery.
5. **T6 alone after T2–T5 finish and release ownership.** Integrator owns sync.project.json, the specified scene checks, ACCEPTANCE.md/evidence and necessary config/server/client/scene fixes. Include this new SliceSmokeTest in the test handoff; preserve the old smoke's historical report, never run its Admin reset on owner data.

Expected local integration order ("merge" means reviewed incorporation; **no git commit now**): **T1 → T2 → T3 → T4 → T5 → T6**. T3/T5 completion may arrive earlier; hold acceptance until their dependencies exist. T2's catalogue is immutable before T4 reads it. If a contract changes, stop dependent writers, let the contract owner resolve it, and record the change; T6 receives exclusive shared-file ownership only at the end.

Do not touch unrelated dirty files, original `pumpkin/src`, or existing game code during this prep. Claude owns Studio/browser/design work; Codex owns code/build/research. No new framework, accounts, downloads or payments in prep. No task may edit ASSETS.md/QUEUE.md concurrently; follow-up corrections belong to the coordinator.

## Defaults that override older brief text

- Three stall shells; only Shop operates, Sell/Upgrades say Unlocks later and have no prompts.
- **One real nest-refill clock**, top right. Older T1/T5 "King later" clock text is stale. No fake timer or boss scheduling.
- Reward **<30 s**, first earner **<120 s**, measured from actual spawn. Storyboard 8/15/20/26 seconds is guidance. Reports retain exact measured values; strict bottom defaults resolve earlier `<=` wording.

## Three-line quick acceptance per task

These are fast rejection checks for Claude, not replacements for each brief's complete acceptance.

### T1

1. Load the final returned PatchConfig; confirm Iron150/gate1000/HP13, first break1/later8, Pup1/Crow4 and usable tiers only Rusty/Iron; compile O0/O1/O2 debug2.
2. Read CONTRACT.md: QA namespace is isolated, pen states/explicit Hatch/events/assets/pivots are exact, 12 visible pets/six rarity tokens and legacy IDs remain loadable.
3. Check bottom defaults: three shells/one Shop, one real refill clock, strict pacing limits; flag runtime UNKNOWN and freeze the handoff before other writers start.

### T2

1. Open ledger/manifest: every used piece has original licence/provenance and actual zero-script hierarchy inspection; exclude the script-bearing Store ScareCrow candidate.
2. Compare one core set against hatch-reveal/collectibles/scythes/guards sheets at avatar5.5: Pup3.2, guard11, shells3/4/8, Iron silver; confirm Zion checkpoint before multiplication.
3. Resolve all catalogue entries as world models or portraits; record approved manifest hash, licences and scale captures, with device performance UNKNOWN.

### T3

1. Disposable solo route: smash pays Candy only, held steal wakes guard, catch keeps shell, HOME stops threat, placement stays Seated until explicit Hatch.
2. Replay place/Hatch/Collect/buy/claim/unlock and invalid range/type inputs: one item/outcome/debit only; restore pending hatch on disposable rejoin, no original-save reset.
3. Confirm Pup1/s starts after hatch, Iron150 and gate1000 persist; run10min/full-pen check with no late systems, income multipliers or Candy side channels.

### T4

1. Run scene validator and overhead count: hub248×160/Meadow120×160/walls25/paths≥12, eight38×28 pens/eight lamps/40 wilds/three nest shells/one guard11/throne40.
2. Walk spawn→nest→south HOME→own pen→north gate: no blocked paths, invisible collision roots, sunset/readable landmarks and safe preview completion sign.
3. Compare four hub/Meadow views to concepts, rerun assembly for idempotence, and deliver separate world-package hash without editing T2 catalogue or Rojo mapping.

### T5

1. Desktop/landscape-touch check: Shop/Index only, one banner/arrow/toast/refill clock, two hotbar slots, purple Drop, 32px inset/48px targets, no duplicate JUMP.
2. Record actual six hatch beats after6/8/20 wait; show faceless curved shell/Pup/Common/+1, owner-only card and cleanup within2.2s including interruption.
3. Check Shop FREE/150/1.2K/9K and Index3×4 use real state/approved previews; touch while moving, menu focus blocks attacks, no client awards or leaked listeners.

### T6

1. Build/hash Rojo from disk with approved packages, compile O0/O1/O2 debug2; run SliceSmokeTest smoke and fresh human pacing separately, retain client/server logs and cleanup evidence.
2. Run solo/two/eight/ninth-player, no-loss/rejoin/duplicate checks and physical gate passage; record reward<30/earner<120 plus repeat15–45s/gate3–5min and any misses.
3. ACCEPTANCE.md links seven independent pillar scores≥8/10/no missing core item, side-by-side concept/reference captures and Zion core/full-slice decisions; distinguish static/Studio/visual/owner/device evidence.

## Coverage boundary

The new smoke test covers the requested solo end-to-end route and a human pacing observer. It does not certify every spec section4 test: contention, invalid remote payloads, save/rejoin, full pen, eight clients,10-minute leakage, UI pixel measurements, six-beat visual review and physical per-client gate collision remain T6 checks. A solo smoke PASS is not slice acceptance.

Full Keystone Roblox Process Playbook: UNKNOWN/not found in searched local copies or supplied spec; owner-provided core-art/reference rules applied. Fetch the full note before implementation acceptance, as SLICE-SPEC already requires.

Prep verification (2026-10-11): new smoke server and embedded client compile O0/O1/O2 with debug2; exact header bootstrap extraction succeeds; StyLua check passes. Five mocked fail-closed checks pass (outside Studio, invalid mode, missing QA in smoke/pacing, missing isolated namespace) without instance creation. These are static/guard checks, **not Studio route evidence**. Builders must provide the top-of-file contracts before runtime. No existing game file edited; no commit.
