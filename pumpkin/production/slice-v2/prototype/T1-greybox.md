# T1 v2 greybox — ARENA-1013 deadline revision

CHECKED: read ../../treasure/ARENA-1013.md, the Roblox production skill, prototype code and earlier T1 report. Reused the native-Part scene and item/guardian foundation; no dependency or asset imported. Recipe version5. Only this prototype folder edited; no commit or publication.

## Implemented

- Removed hide state/occupancy, concealment timers, leave-hide controls, markers, log/bush scenery, chunks I09/I10, sniff and special log-opening poke. Ordinary close guardian attacks remain.
- Four solid open rocks replace those areas. Map X,Z centres: (38,-18), (38,-38), (62,-26), (62,-46); footprints8×8, heights6–8. Each pair leaves a12-stud through passage, open sides and no enclosed interior.
- Preserved the160×160 top-down layout, hills, stones/recovery, three routes, two links, safety apron and ordinary cover.
- The60.0-second escape deadline starts on first completed nest Steal and belongs to that treasure ID. Drop/Bump/settle/Grab/recovery/handoffs preserve it.
- Portal accepts cargo immediately while server now < escapeDeadline. Exact-zero/late entry awards nothing. Empty-handed return remains available.
- All arena occupants, including late arrivals, see one countdown near screen centre, using replicated server time. Amber≤15s; red and larger≤5s. Securing clears the shared clock.
- Expiry retires the old ID, clears holders/holds, destroys item/weld, disables old prompts and resets guardian attack/path state. No completed escape or placed reward is added. A new nest ID appears3s after expiry, with no deadline until stolen. Occupants remain.
- Secured cargo is unaffected. T1 has placeholder secure/place and no durable economy/save service; ARENA-1013 SecurePending/storage reconciliation remains outside this prototype.

## Preserved difficulty

User-requested harder tuning overrides the arena document's older values: walk16, carry13.5, guardian14.5, burst15 for0.7s every4s, detect24/throw56, telegraph0.9s, cooldown2.5s, lead0.65s capped9, mercy3s. First guardian hit drops carried cargo. Last-seen search is now2s, without concealment immunity. Steal/Grab/Bump2/0.4/0.4s; shield12s, settle0.6s, Bump cooldown2s. Idle10s + warning2s drop remains. LOOT keeps one ID through contested holds.

## Geometry and cameras

Map +Z north converts to world -Z. Meadow origin(0,76,-360). Camp(0,32)/40×40/+4; west hill(-40,12)/40×40/+10; east hill(40,12)/40×40/+8; stone cutout(-32,-28)/32×24/floor-3; original cover(-10,-10)/(10,8); pad(0,-58)/32×24; arch(-24,-58). Slopes≤25°; no mandatory route jumps.

| Camp-return route | Authored 3D length |
|---|---:|
| Quick | 93.52 studs |
| Ridge | 110.48 studs |
| Grove | 129.88 studs |

Solo carrying traversal:376.78 studs, previously477.44. It retains one hill climb/descent, the stone set and a normal locked-disc dodge near camp before the detour. Measured distance is not observed completion time. The runner fails if cargo reaches its deadline before securing.

Home, pens, altitude bands and cameras are retained. Enable ServerScriptService.GreyboxCaptureCams. Workspace.GREYBOX.CaptureCameras contains marker Parts/Cameras. Home eye(0,96,172), target(0,4,-22), FOV55; Meadow eye(0,140,-228), target(0,80,-370), FOV58. Use16:9; restore CameraType Custom and subject afterward.

## Verification

CHECKED offline: nine Luau files compile O0/O1/O2; StyLua format/check passes; Selene0 errors/warnings; requested Rojo build passes. See verification.log.

- Deadline tests: before-zero success, zero rejection, original deadline through handoff, carried/dropped retirement, competing hold cleanup, no award, fresh ID/+3 refill scheduling, actual production weld/visual cleanup.
- Production scene construction: absent hide chunks/scenery, six hard covers,12-wide cutbacks, guardian attack/path cleanup, home/vistas/capture-camera cleanup.
- Fifty fixed seeds: authored floor heights/slopes/cliffs/cover, solo/PvP waypoint clearance, grounded jump lead-ins and invalid waypoint rejection.
- Production guardian state machine: carrier preference, sight/range/mercy/cooldown, close attacks, stalled navigation recovery and throws across three seeds. Navigation mocked.
- Production PvP adapter: range/sight/height/arena/safety, shield/mercy, contested holds, Bump/drop/settle/Grab, winner secure/place conservation.
- Binary source parity includes every runtime source, including Scene. Both Studio gates remain false / NOT RUN.

Studio runners UPDATED, NOT RUN: in fresh Play set GreyboxLoopTest=true, then GreyboxPvpTest=true. Each secures original cargo before deadline and checks placement. PvP asserts original ID/timestamp/deadline through Bump/Grab. Each then performs a second real Steal, waits the full60s, checks no award/holder/hold/weld/physical duplicate, one new nest ID after3s, and empty-handed return. This extra regression extends total runner time; successful cargo escape must be under60s.

UNKNOWN: Studio pass, Humanoid jump physics, navmesh, rendered countdown readability, mobile performance, real multi-client fairness, fun and owner acceptance. No live runtime or screenshots claimed. Exact Keystone Roblox Process Playbook unavailable after local search.

Recovery note: a PowerShell alias caused an edit script to overwrite sources. Runtime code was recovered from the pre-edit binary, previously reported source-matched. check.luau was reconstructed from its committed harness, updated for harder guardian/world conversion, and extended with current expiry/scene checks. Earlier constructed-ray/pen-route checks are not claimed as rerun by this harness.

Offline arena comparison: Steal an Egg keeps the guarded objective/immediate return; Steal and Hide dedicated hiding is removed per owner direction, while ordinary rock cutbacks preserve visible pursuit. Reference superiority and independent live critique remain UNKNOWN.

Pinned commands, from this folder:
- C:/Users/zerha/.rokit/tool-storage/johnnymorganz/stylua/2.0.2/stylua.exe .
- C:/Users/zerha/.rokit/tool-storage/kampfkarren/selene/0.31.0/selene.exe .
- C:/Users/zerha/.rokit/tool-storage/rojo-rbx/rojo/7.4.4/rojo.exe build greybox.project.json -o guardian-greybox.rbxl
- C:/Users/zerha/.rokit/tool-storage/lune-org/lune/0.10.5/lune.exe run check.luau
- C:/Users/zerha/.rokit/tool-storage/johnnymorganz/stylua/2.0.2/stylua.exe --check .

Lessons:
- When holders change, keep deadlines on items because carrier clocks allow refresh exploits.
- When expiry races entry, decide on one server clock because client numerals cannot award ownership.
- When editing through PowerShell, use explicit function names and stop on errors because aliases can shadow short names.
Build SHA256: F45BB4BF5E640AA38976771DB3D9840EBA186EC1113C45938EA13CB04A020501
