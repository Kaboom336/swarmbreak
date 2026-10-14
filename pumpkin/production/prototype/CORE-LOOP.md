# Steal a Treasure — core loop

Local deliverable: `prototype/guardian-greybox.rbxl`. Original preserved byte-for-byte in `guardian-greybox.pre-core.rbxl`. No commit, upload, account changes or publication. Authored edits use apply_patch; Rojo/Lune generate binary artifacts. The existing canonical `slice-v2/prototype/guardian-greybox.rbxl` receives the same built bytes.

## Contract and scope

Checked: treasure/GDD.md, BUILD-PLAN.md B2, ROADMAP-TO-LAUNCH.md B, existing LootRules/server/client/placement/test code, HomeArt mesh loader/payload and local Data.luau donor. Reused the existing arena, plots, reviewed Pup/Crow/Acorn/OpenAcorn geometry and narrow UpdateAsync/session-lock patterns. No external package or asset was adopted; no new external licence dependency. The exact Keystone Roblox Process Playbook and Iris tools were unavailable; supplied owner rules and local BIBLE-KEYSTONE-SUMMARY were read instead. Owner-reported art approval is not fresh runtime evidence.

Player fantasy: steal one acorn, survive the contested return, open it at home, see a pet earning Coins. Desktop E, landscape touch native prompts and controller X; free local tooling/assets; no Creator Store scripts. One Meadow loop is the milestone. Upgrades, new islands, collection archival/64 storage and decor management are outside this requested implementation. The eight-pet limit refuses new runs safely; it never deletes a pet.

The explicit request overrides GDD's automatic Open: Place leaves a closed acorn; hold E (0.6 seconds) or tap the contextual touch Open button. A tap sends intent only; the server still validates 0.6 seconds of continuous range/sight before committing Open. Pads appear only at the player's chosen legal position; no fixed pad rows. Plot ownership, height, footprint, spacing, entrance reserve and proximity remain server-validated. First secured winner receives Pup/Common/1 Coins/s. Subsequent frozen server rolls use Common 70 / Rare 25 / Epic 5 / Legendary 0 in `core/Config.luau`; Legendary is supported but disabled to preserve Meadow's GDD odds. Epic/Legendary names/rates reuse Pup/Crow geometry as proposed variants, not newly approved species.

The same acorn ID, roll and deadline survive drop/Grab/Bump. SecurePending is an atomic item flag before yielding: expiry, drop and rival pickup cannot alter it. Save the resolved pending cargo before acknowledging secure return/refill. Unknown writes retry the same operation/revision; they never drop a potentially awarded item to another player. Secured cargo and placed unopened acorns restore on reconnect. Open commits the pet and discovery before reveal/income. Duplicate Open/Collect cannot mint rewards.

GDD protection is explicit: **home pets and Coins are safe**. Only provisional island cargo is stealable. No plot-raiding mechanic, pet theft, paid immunity or new lock timer was added. Existing island shields, mercy, deadline, protected apron and Bump/Grab rules remain. Their prior tuning is preserved; this batch does not silently retune the Keeper or routes.

## Modules and saving

`core/Domain.luau`: pure versioned profile, finite input checks, weighted roll, secure/place/open, income and collect. `Profiles.luau`: injectable store, retries, per-profile serialization, 180-second lease, token/revision fencing and unknown-write reconciliation. `Service.luau`: owned plot/prompt/HUD adapter; `Runtime.luau`: Roblox services and isolated Studio store. `Tests.luau` / `Test.server.luau`: mock store test and Studio attribute trigger. `Hud.client.luau`: actual Coins, income rate, plot bank, collect pop, skippable reveal card and real Pup/Crow viewport silhouettes. Existing HomeArt renders committed server metadata instead of assigning pets from an ID hash. Rare+ receives occluded outlines, bounded glow and rising sparkles; Common has no persistent aura.

Store: **TreasureQA_Core_v1**, separate from legacy data. Version 1 saves pets/IDs/rarity/local plot pose, discovered index, Coins, uncollected plot bank, pending cargo, escapes, Meadow access and first-use shield/hit flags. Unknown/future or malformed profiles are refused, not overwritten with defaults. Updates use non-yielding callbacks; network retries happen outside callbacks. References: [Roblox Data stores](https://create.roblox.com/docs/cloud-services/data-stores).

Autosave every 45 seconds, PlayerRemoving, parallel BindToClose saves (bounded shutdown wait). Collected Coins and secure/place/open actions save before success. Ordinary online ticks accrue while a normal save yields; uncertain/expired sessions suspend actions and earning until safe reconciliation. No offline earning. A crash can lose uncollected ticks since the last acknowledged autosave; saved collected Coins/pets/cargo are recoverable. DataStore outages and actual crash/rejoin remain Studio QA gates.

Studio defaults to an isolated in-memory store and HUD **STUDIO: UNSAVED**. It can be played without publishing or changing security settings. For an already configured separate QA experience, set ServerScriptService `CoreUseDataStore=true` before Play to exercise the real QA store. If that explicit test store cannot load, play is refused; failed real data is never replaced or mixed with volatile data. No live/default fallback or security change was made.

`CoreRequireLegacyGates=false` permits normal prototype play without running harnesses first; it does not mark any test successful. Set it true to restore the prior gate lock. Existing Loop/PvP/Trap runners keep their original attributes and source. Their fixture placements bypass persistent core awards, preventing fake test pets/Coins from entering a profile. Use a fresh Play session after those fixtures before judging the real loop.

## Offline evidence

Final local status: **Rojo PASS; embedded Luau and O0/O1/O2 syntax PASS; mock core/service suite PASS; existing offline regression suite PASS; tunnel/Keeper checks PASS; Selene 0 errors/0 warnings; StyLua PASS; git diff whitespace check PASS. Studio, real DataStore, real clients, visual critic and device tests NOT RUN.** Thirty-three unrelated source containers and the original three Studio runners are preserved from the pre-core backup.

SHA256 main: `539E8059883A32DC878B067A5A888DE7DA00DB9623946EFAE0889415B8C76243`. SHA256 pre-core: `AED7A19D4382C1888DF20120B08F09D6F9120A8811140710A97AE3C4030C53EF`.

Rebuild from production: run Rojo build on `slice-v2/prototype/greybox.project.json` with output `prototype/core-rojo.rbxl`, then Lune `prototype/core-build.luau`, then `prototype/core-check.luau`. Do not rerun `core-backup.luau`: it deliberately refuses to overwrite the preserved original. The intermediate Rojo place is a build input; open the delivered main place for the full preserved scene.

- Rojo 7.4.4 builds the mapped source. `core-build.luau` mounts only the reviewed changes into the pre-core place, preserving existing geometry, lighting, Keeper and all unrelated scripts. All embedded Luau scripts compile.
- `core-check.luau`: O0/O1/O2 syntax; real Rules handoff/secure/place plus mock profile Open/earn/collect/save/load; first winner guarantee, duplicate actions, same deadline/roll, lost write responses, recovery, lease takeover/fencing, malformed schema, capacity, service range/owner/phase gates, fractional frames and online ticks during yielding saves. Existing test-runner sources remain byte-identical to the backup.
- Existing `slice-v2/prototype/check.luau`: placement on eight plots, PvP conservation, deadlines, traps, guardian/navigation/route mocks and source parity. Its placement-only mock now explicitly sets testRunning, isolating legacy fixtures from the new persistence adapter.
- Tunnel callback and Keeper sweep checks pass. Selene/StyLua run on the changed runtime sources. These checks are static/mocked evidence, not Studio play or replication evidence.

## Studio must verify — NOT RUN

Open **guardian-greybox.rbxl**, start a fresh Play session:

1. Enter Meadow, steal the golden acorn, return through cyan safety. Confirm one secured acorn, own gate return, no Coins for carrying/theft and no reroll on Bump/drop/Grab. Place at a legal point; a closed acorn and small pad remain. Rejected placement retains cargo.
2. Hold E or tap the contextual touch Open button. Confirm cap lifts/crack cue, one reveal card with correct Pup/Common/+1 Coins/s, then one approved Pup model on the same pad. Leave range or break sight during the opening hold/dwell: no pet or consumed cargo. Skip dismisses only presentation; movement/camera stay usable. Common has no lingering body aura. Repeat for Crow/Rare/+4 and Golden Pup/Epic/+8; use an isolated rarity fixture for Legendary (weight 0 in normal Meadow).
3. Plot bank increases by the real sum once per online second. Walk across the gate collector or activate Collect. One +Coins pop, bank resets and HUD Coins increases exactly. Another player cannot Open/place/collect from this plot; owning players see only their own Open/collect prompts. Unopened cargo and offline time earn zero.
4. Index begins with dark actual Pup/Crow silhouettes and ?. Discovered entries reveal names/rarities and colour after Open. Verify delayed EditableMesh creation, mesh limits/permissions, no duplicated acorn caps/stems, pad alignment and readable name/rate billboards. Mesh creation failures remain an art/runtime failure, not a successful final-art claim.
5. Server Command Bar: `game.ServerScriptService:SetAttribute("CoreLoopTest", true)`. Require **CoreLoopTestSuccess=true** and a PASS result. This uses an isolated mock store, not a real DataStore or player profile.
6. Fresh session: run `GreyboxLoopTest`, `GreyboxPvpTest`, `GreyboxTrapTest` sequentially with SetAttribute, waiting for each Success/Result. Keep conservation PASS. These prior tests remain expected to pass; fresh Studio results are UNKNOWN.
7. Separate configured QA store only: save/rejoin after secure, after Place, after Open and after Collect. Correct pet ID, position on whichever plot is assigned, Coins, bank, index and flags must restore once. Stop/restart while a save response is missing, deny loading, overlap sessions, expire the lease and simulate DataStore failure. Never acknowledge a new pet/cargo without recoverable data. Inspect leave/shutdown retries and logs; don't enable Studio access on a live experience for this test.
8. Real two clients: original provisional ID changes hands, winner alone opens one pet; loser gains no pet/Coins/first-pet consumption. Reset/disconnect before safety drops for rivals; after safety saved cargo recovers. No attack/expiry during pending save. Eight-client plot uniqueness/capacity, late join and malicious prompt spam remain runtime gates.
9. Phone landscape and controller: 48px buttons, native Open/Collect controls, readable billboards/card/Index, no HUD overlap, focus/skip/close and reduced-motion settings. Existing full reveal is bounded at 2.2 seconds. Actual phone performance, pacing and fun remain UNKNOWN.

## Named reference comparison — inspection, not a critic verdict

Read local BIBLE-STEAL-AN-EGG, BIBLE-PET-SIM-99 and treasure/REFS. Compare the first built loop only before scaling:

| Reference anchor | Implementation | Studio gap |
| --- | --- | --- |
| Steal an Egg: clear steal → safe line → pen → earner | Original contested acorn, retained ID, own-plot Place/Open, server rate | Real two-client legibility, collection cue, novice travel/first earner time |
| Pet Simulator 99: bold short hatch/reward identity | Same-pad cap pop, 2.2s skippable name/rarity/rate card, bounded Rare+ FX | Mesh availability/size, shell seam motion, phone crop/contrast and screenshots |

No independent Claude/critic, visual score, owner acceptance or actual Studio test is claimed. Preserve one loop for Zion's review before adding content. Full shell halves/final reveal polish, reduced-motion controls, upgrades and larger archival collections are follow-up work, not hidden acceptance claims.

Lessons: When a save response can be lost, retry the same ID/revision because a new award can duplicate cargo. When network saves yield, preserve accrued online ticks because replacing a snapshot can erase income. When geometry is already approved, reuse its loader with server metadata because hashing IDs invents pet ownership.
