# T5 — Launch HUD, actions and hatch feel

Status: DRAFT coder handoff; no commit/publish/spend. Read spec, T1 contract and whole current client before edits; reuse polished utilities rather than adding a new UI framework.

## Own files

- `pumpkin/giant/src/StarterPlayerScripts/Patch.client.luau`
- `pumpkin/production/slice/evidence/T5-ui-feel/**` (new)

After T1; parallel T2/T3/T4; final visual verification waits for delivered meshes/world. Do not edit server/config/assets/scene/Rojo. Use shared server contract, never mint money/items locally.

## Build

1. Reuse tween/chunky/viewport/sound pools/damageText/pickupPop/cleanup primitives after inspecting code. Replace navy token use with cream/grape/orange FredokaOne/stroke/bevel kit; actual data remains authoritative.
2. Desktop1920×1080: Shop/Index left; Candy/income and Carry n/3 bottom-left; one goal/ground arrow; two-slot hotbar; purple Drop only carrying. Clear gameplay centre and one toast. Delete quest/progress/Daily/Pets/Upgrades/boost/teleport/extra-timer/boss tiles and inactive handlers.
3. Mobile landscape32logical-px inset/min48tap targets, menus top-left/currency above joystick, orange SMASH/purple STEAL/JUMP. Keep movement/input focus natural; no duplicate Roblox JUMP or Sprint/Dash button. Touch STEAL invokes explicit validated hold, SMASH cannot trigger steal.
4. Match Shop first four cards FREE/150/1.2K/9K; only Iron purchase enabled in slice. Other tabs/later chevron inert, no offers or fake discounts. Index12 tiles3×4, locked real-roster silhouettes/hints, one Claim. 3/12 and three revealed entries are screenshot fixture only, not fresh entitlement.
5. Build two-hand carry for same faceless shell4-high around server-owned item root; tool grip6-shaft clear of avatar face. Root motion should not break gameplay ray/range or server ownership. Preserve named trail hooks and Rusty/Iron material identity.
6. Implement owner hatch presentation on authoritative start/completion:6/8/20 wait, then beats0/.3/.6/1/1.5/2.2, curved rind/cream seeds, Pup identity, rarity/name/green actual rate, green Collect and New. <=8rays/12chips, release controls/camera/HUD by2.2 including interruption. Neighbours see world effect, not owner card. No block fragments or generic sphere preview fallback.
7. Smash yields positional sound, bounded nudge,6–12chips, HP/number and ~.5s candy arc; merges damage numbers in.3s/max4, fades.8–1s. Candy roll.5s; input stays responsive and effects never obscure chaser/route. Don't client-pause server or multiply awards.
8. One goal state always: steal->carry->pen/hatch->Iron->gate; RUN danger replaces normal instruction; held shell arrow exclusively own HOME south. Single closed later King chip under default Q2, no fake countdown. Show actual timer only after owner resolves policy.
9. Gate collision visibility is client-specific but server ownership enforced; test real physical passage when T3/T4 integrate. Restore lighting preset after any retained effect, no scheduled King tint.

## Acceptance

- Compare hud-desktop/phone/panels/hatch sheets at locked cameras; no concept builder footer or header strips in game; current count at most two menus/one arrow/one banner/one toast/two hotbar slots.
- Touch safe areas/tap targets measured; moving while tapping controls works, GUI focus blocks unintended attacks, closed menus don't leak listeners.
- Full six-beat footage and interruption cleanup; Collect/repeated reveal events never duplicate outcome. Only correct owner sees card, shared world effect remains bounded.
- Every preview resolves approved model/portrait; missing art fails clearly. First Pup exactly orange/hatch design; Ghost shells faceless.
- Compile0/1/2 and log client warnings/errors. Mark UI emulation separately from actual hardware/performance and human fun evidence, deferred to T6.
