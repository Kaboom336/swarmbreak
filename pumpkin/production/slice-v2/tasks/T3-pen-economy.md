# T3 — pen, hatch, Candy, first upgrade and preview

DRAFT future task. After T2 accepted contract; exclusive config/server/client ownership. Reuse save/session and UI utilities. No commit/publish/spend or owner-data reset. Geometry remains frozen.

## Files touched (future only)

- `pumpkin/giant/src/ReplicatedStorage/PatchConfig.luau` (final slice tuning)
- `pumpkin/giant/src/ServerScriptService/Patch.server.luau` (pen/economy/save/tutorial)
- `pumpkin/giant/src/ServerScriptService/IslandRuns.luau` (reservation/recovery adapter only)
- `pumpkin/giant/src/StarterPlayerScripts/Patch.client.luau` (minimal real-state controls)
- `pumpkin/production/slice-v2/CONTRACT.md` (versioned update), `evidence/T3-loop.md`

## Work

1. Implement itemId state Returned/Recovery→CarriedHome→Seated→Waiting→Hatched. Own-pen Place moves once into reserved slot; explicit Hatch starts6s deadline. First outcome guaranteed Orange/Common1/s, later roll probabilities/rates per SLICE-V2. Freeze outcome before hatch; no RNG on restore.
2. Persist itemId/state/outcome/rarity/variant/event eligibility/deadline, Boots and Zone2 ownership with existing session locks/retry/release. Rejoin reconstructs one item in recovery/pen; a completed hatch becomes one pet. Pending hatch earns0; offline waiting may complete but offline Candy is0. Every transition conserves items and releases/respects reservations.
3. Server one-second Candy ticks only from Hatched pets. Remove HoardMult and weight/Gold/Shiny/stamp/pass/Spooky multipliers in slice. Keep saved legacy fields readable without letting disabled systems affect clean-profile income. Display real aggregate rate and per-pet rate.
4. Single Shop sells Boots30 exactly once, level1 only, +2 speed; no scythe purchases. Portal's locked state sells island2 preview120 after Boots. Repeated requests debit once, shortage rejects; direct island2 entry/rewards remain unavailable. Preserve existing IDs, no bulk profile migration.
5. Real-state tutorial five steps Enter/Steal/Hatch/Buy/Unlock; carry arrow always points to own home. Place/return/wait are states, not extra quests. Shop+Index menus only; Index read-only/no claim. No fake balance/free Candy or visible future-feature tiles.
6. Full pen prevents new run; catch keeps item; reset/disconnect restore committed item without claiming successful escape. Duplicate Place/Hatch/Collect/return/Buy/Unlock must not mint anything. Collect only dismisses presentation. Event variant field supports T4, not a separate event currency.

## Acceptance

- Disposable fresh route completes portal theft→escape→Place→Hatch→actual Candy tick→Boots→island2 preview using real input. Record reward<30s, earner<120s, run20–45s, first buy/preview timings; keep funded boundary tests separate from pacing.
- Handler/state tests: concurrent return/place, duplicate hatch/Collect, shortage/replayed purchase, wrong pen/run, invalid payload, full pen/reservation, catch/death/reset/disconnect at each transition, waiting-hatch rejoin. Exactly one item/outcome/debit; no waiting/offline income.
- Test guaranteed Common/Pup floor and eight filled slots; upgrades felt on travel and rate text agrees with Candy deltas. No compulsory lucky roll or Index grant. Adjust proposed costs only with recorded evidence and update spec/contract.
- Compile O0/O1/O2 debug2; Studio solo/two clients; no old schedules/earnings after10min. UNKNOWN art/device/fun remains for T4/T5.

Next: working loop before art; T4 changes presentation/season overlay, not route collision or economy.
