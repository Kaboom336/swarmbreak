# T3 — Server-owned slice loop and no-loss state

Status: DRAFT coder handoff; no commit/publish/spend or real profile reset. Read spec, T1 contract and current complete Patch.server before edits.

## Own files

- `pumpkin/giant/src/ServerScriptService/Patch.server.luau`
- `pumpkin/production/slice/evidence/T3-server.md` (new)

After T1; parallel T2/T4/T5 (different files). No config/client/scene/test ownership; send contract problems to T1 owner before its handoff, otherwise queue fixes for T6.

## Build

1. Reuse currency/session locking/load/save/release, pen ownership, Wild.hit/pop validation, tools/gates and Index deduplication. Read their code before extraction. Do not migrate to ProfileStore/Blink just to match TOOLING recommendations.
2. Gate all late runtime work with explicit slice policy: scheduled boss/raids/Purge/Daily, cauldron/sell/full-pen modal, orders/stamps, boost/mutation/weight multipliers, future-zone spawns and hidden monetization. Scene-required old containers may be retained empty until adapters no longer wait for them.
3. Use T1 imported model contracts. Preserve invisible attributes/root expected by current BasePart code; visible art comes from meshes, not makePumpkin sphere/cube, living Jack, fallback Pup cloned under every pet name, part-built guard or scythe generator. Only validate assets needed by active slice, with portraits for locked Index.
4. Wilds award Candy only. Remove Hoards.swing implicit stealing. Enforce steal hold1s server-side, ownership/proximity/types and contested pickup once; capacity3. One Scarecrow with headstart1.2, relative speed.88, no min14 speed floor overcoming a slow carrier, return12, catch3.5.
5. Replace bonk forced-drop/20s expiration with1s stumble/3s mercy and retained carried item. Safe-line south stops threat. Death/reset/disconnect/drop conserve committed items; one owner-reserved recoverable drop, no reward mint on pickup or repeated delivery. Do not enable PvP theft.
6. Delivery entering own pen places once into free slot; explicit pen Place action remains when outside delivery volume. Seated shell is Ready; E Hatch starts6/8/20 deadline, not automatic placement. First owned hatch guaranteed Orange/Pup1/s. No pre-hatch income. Persist waiting/deadline/rolled outcome so reconnect cannot skip/reroll/duplicate.
7. Emit one authoritative hatch outcome/beat start; reveal Collect dismisses client art only. Income/rate exactly matches state, one-second ticks; cosmetic weight cannot change payout.
8. Buy150 Iron once, validate funds/types, persist old ID WoodenScythe. Other shop previews rejected. Unlock1000 Zone2 once with owner-only physical access, no Zone2 farm beyond safe completion preview. Reject remote requests bypassing locked geometry.
9. Claim first discovery200 once, persist, reject replay. Remove implicit Daily/minute events or old migration rewards from clean slice profiles. Keep isolated namespace and legacy schema fields; never wipe original game's saves.
10. Publish five tutorial stages/one target, no 50-smash hurdle or recurring quests. RUN only during threat, HOME only during carry, explicit waiting/hatching presentation states. Full pen yields one toast/blocked steal, never autosell or loss.

## Acceptance

- Server state tests exercise actual handlers: duplicate/contested steal, place/hatch/Collect, purchase, gate and Claim; money/item deltas conserved. Invalid range/type/nonfinite/spam/cooldown rejected.
- Run no-loss catch/death/drop/disconnect paths and pending-hatch restore using disposable state. Once saved, pet/tool/gate/Claim cannot disappear or grant twice.
- Deferred systems still absent after10minutes and full pen; no calls mint Candy from disabled side systems.
- Missing imported art fails rather than constructing visible primitive placeholder. Asset-independent logic may run against explicit test fixtures; don't label fixtures final art.
- Compile Studio-compatible levels0/1/2. Record static versus runtime results; real two/eight-client physics and gate passage belong to T6.
