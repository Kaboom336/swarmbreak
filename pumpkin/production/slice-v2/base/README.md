# Steal a Treasure: base-loop greybox

Standalone week-1 build on `pumpkin/patch-panic`, scoped to this folder. Open [steal-a-treasure-base.rbxl](steal-a-treasure-base.rbxl) in Studio EDIT when ready. Codex did not open Studio, run Play, publish or commit. No other folders were edited. The task's explicit folder destination overrides the general Desktop preference.

**Read the evidence:** [OFFLINE-RESULT.txt](OFFLINE-RESULT.txt), [BUILD-RESULT.txt](BUILD-RESULT.txt), [SPEC.md](SPEC.md), [TESTS.md](TESTS.md). Timing results are simulated. Studio EDIT, multiplayer, mobile, visual quality and fun remain NOT RUN.

## What exists

- Shared walking carpet, weighted five-rarity roll, 25 treasure definitions, Gold/Diamond recolours, price/rate/name billboards, Buy E prompt and server-driven delivery.
- Eight plots × ten pedestals; four open initially. Sequential unlock pad, uncollected cash, per-second income pops, step-to-collect, ten speed levels.
- Two-second server-timed stealing after both players buy three times; reserved home slot, slower carrying, RUN!!/Drop, owner warnings, home placement. Damage/death/leaving/Drop returns the item. Slap tool after three purchases lets the owner recover a nearby stolen item; one server-validated action per 1.2s, range 7 studs.
- Sixty-second lock and sixty-second post-lock cooldown, physical front barrier with owner collision exemptions, enclosing flat walls and server intrusion ejection. Shared five-minute guaranteed Legendary clock.
- Cash/rate top centre, Shop placeholder, Index, three-stage tutorial with one arrow, offline-cap line. No popup on join.
- Strict save schema, deep copies, ProfileStore-style local mock, session-leased live DataStore adapter, periodic saves, leave/shutdown saves, 1h offline income per absence. Separate namespace `TreasureBase_v1`.

## Files / run

`Config` is data; `Rules` and `SaveDomain` are pure injected modules. `Scene` creates the greybox; `EarnerModel` owns replaceable part visuals. `Base.server` owns all economy and gameplay transitions; `Base.client` renders HUD/effects and sends only intents. `Profiles` is a small custom DataStore adapter, not the ProfileStore vendor package; `MockStore` implements StartSessionAsync/Data/Save/EndSession for offline and default Studio use. `Economy` models one active player.

From production: `lune run slice-v2/base/check.luau`, then `lune run slice-v2/base/build.luau`. If the Rokit shim cannot resolve home, use the direct installed 0.10.5 binary shown in TESTS.md. All source edits use apply_patch; build/test tools generate only files here. Build compiles every local source and checks the serialized DataModel. EDIT test instructions and Zion's two-player route are in TESTS.md.

## Placeholder and known gaps

Def 1 now has one script-built Copper Compass voxel character with Gold/Diamond recolours and a client-only two-frame leg bob. Other definitions remain placeholders. See [the comparison](earners/SBS-copper-compass.jpg), [self-judge and reproduction steps](earners/JUDGE.md), and [model checks](earners/CHECK-RESULT.txt). Offline render proof is not a Studio or runtime pass. Zion checks this one before expansion.

- Plain parts only, no imported art, sound, polished movement animation, reveal, carry vignette or final map. Walking earners translate anchored blocks. Claude owns the Terrain/CC0 kit look pass. The arrow is one billboard marker, not ground chevrons. Final giant countdown presentation is pending.
- Shop is intentionally inert. No rebirth, selling/replacement, paid products, zone expansion or other late systems. A full ten-slot base cannot replace earners yet. Offline income is capped per absence, not a daily allowance.
- Cross-profile theft is not crash-atomic. No transfer journal yet: public persistence with valuable inventories is blocked. Save outages warn; expired leases block actions and kick. A crash can lose changes since the last successful save (periodic interval 45s; mutation-triggered saves also attempted). No claim of production-grade ProfileStore equivalence.
- Timings model an attentive player, deterministic rolls, continuous movement and 0.25s income steps. Runtime income ticks at whole seconds and pad collection needs a touch edge. Real players can miss a moving starter, wait for affordable offers or spend differently. Eight seed/plot runs are regression checks, not statistical evidence of all sessions.
- The bible's early doubling aspiration is not met by the sample's fivefold rate growth ($5/s → $25/s in 10min). Required first-buy/placement/unlock targets pass offline; growth and full-base progression need Zion's playtest before retuning.
- Runtime APIs, touch reliability, prompt event ordering, character collisions, UI replication and device layout are unverified in Studio. The serialized structure test does not certify these.

## References / reuse / licences

Read local hit bible sections 1, 3a, 7 and 9, Brainrot study (non-new-player caveat), Egg study, existing `slice-v2/heists/{build,check,SaveDomain,Scene}.luau`, and the local project's `C:/dev/codex-lab/pumpkin-loop/PLAYBOOK.md`. The specifically named Keystone "Roblox Process Playbook" was not available through the connected tools/local note search; its exact contents are UNKNOWN. The user-supplied playbook summary and local project playbook guided this greybox.

Reuse ledger: fresh DataModel/compile/roundtrip build and offline assertion patterns copied and adapted from this project's heists slice; SaveDomain deep-copy/finite-validation pattern copied locally; MockStore contract adapted from inspected `prototype/core/MockStore.luau`. No cross-folder imports, vendor package, external kit, mesh, asset ID or third-party source was added. No project-level licence was found; these internal project patterns are reused under the user's express authorization, not presented as an open-source licence grant. Lune and Roblox remain installed tooling/platform dependencies.

Current API checks: Roblox's [client/server security guidance](https://create.roblox.com/docs/scripting/security/client-server-boundary) requires independent validation for prompts; [DataStore documentation](https://create.roblox.com/docs/cloud-services/data-stores) describes UpdateAsync. The implementation checks server distance, item state, affordability, ownership, free slots, held time, lock status and cooldowns; client-supplied amounts, multipliers and positions are never accepted. Anchored earners avoid client physics ownership. Carry travel checks reject large jumps, but this is not a comprehensive character anti-cheat.

## Reference comparison (source studies, not fresh visual testing)

| Moment | Best-in-class reference | This greybox | Evidence / next check |
|---|---|---|---|
| Buy / delivery | Steal a Brainrot shared carpet, E, walks home | Same interaction, anchored placeholders | Offline Rules pass; runtime NOT RUN |
| Income / next goal | Brainrot collection pads; Egg +$ each second | Piles, pad banking, 1s pops, visible $100 unlock | Simulation + structural assertions; readability NOT RUN |
| Carry | Egg RUN!!, Drop, chevrons, vignette | RUN!!, Drop, single home arrow; no vignette | Two-player/UI review NOT RUN |
| Defence | Brainrot lock + owner slap | 60s lock, 60s cooldown, gated slap | Rule timer assertions; collisions/Slap NOT RUN |
| First session | Bible reward <30s, earner <120s | Sample reward 13.5s, placement 10.75s | Simulated only; blind judges and Zion review NOT RUN |

Make-one checkpoint: this is the one base-loop prototype for Zion/Claude review. No final-art expansion or independent visual arena was performed.

## Lessons

1. When serializing Roblox parts with Lune, write canonical CFrame and inspect the deserialized place, because transient Position fields can disappear.
2. When an action uses a hold prompt, validate elapsed server time and continuous proximity, because prompt settings alone are not authority.
3. When testing a simulated economy, state walking/collection policy and seed, because cash and first-unlock times depend on player choices.
