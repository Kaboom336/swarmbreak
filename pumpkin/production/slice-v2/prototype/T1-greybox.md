# T1 greybox handoff — 2026-10-12

Rebuilt `guardian-greybox.rbxl`. Local compile/layout/route/format/lint/binary checks PASS. **Studio full-loop runtime remains NOT RUN / UNKNOWN. Owner portal entry is locked until the full-loop test passes in that Play session.** No commit or publish. All edits stay in this prototype folder.

## Required full-loop gate before owner play

1. Open the rebuilt `guardian-greybox.rbxl` in Studio. Start a fresh **Play** session with a player (not Run). Do not move or press action buttons while the test runs.
2. Switch Explorer/Command Bar to **Server**. Select `ServerScriptService` and set its boolean attribute `GreyboxLoopTest` to **true**. Alternatively run this in the server Command Bar:

   ```luau
   game:GetService("ServerScriptService"):SetAttribute("GreyboxLoopTest", true)
   ```

3. Watch server Output for `[GreyboxLoopTest]` lines. The first player walks with `Humanoid:MoveTo`: home spawn -> home portal -> a route point on every assembled island piece, with S-turns through the cover gap -> nest -> reverse route -> return portal -> home aisle -> own pen. Only the normal portal functions transfer the character; route movement never teleports it. Test movement temporarily uses server network ownership and disables that player's default controls; both are restored on finish. Guardian behavior/tuning remains normal.
4. Require `GreyboxLoopTestResult` to begin **`PASS:`** and `GreyboxLoopTestSuccess` to be true before owner play. The runner calls the same `enterRun`, `stealHold`, `returnRun`, and `placeItem` functions used by native prompts and the fallback RemoteEvent. It waits at least one server second for theft, repeats theft/placement to check duplicate rejection, and verifies exactly one real placed object. A passing test leaves one ball in the first player's pen and unlocks normal portal entry in this session.
5. On `FAIL: <reason>`, do not hand over the build. Stop Play, fix/rebuild, and test in a fresh Play session. Each invocation requires an unused first-player state; repeating after a partial/completed run correctly refuses. `GreyboxLoopTest` resets to false after completion.

Failure conditions: no progress toward a waypoint for more than eight seconds; a waypoint not reached within 30 seconds; character/player loss or unexpected run reset; refusal of a legal action; missing cargo/placement; duplicate grant/placement; guardian never entering Chase **and moving during Chase**. The test needs no catch to pass; it records the actual catch count.

Results on **ServerScriptService**:

- `GreyboxLoopTestResult`: `NOT RUN`, `RUNNING`, `PASS: <reason>` or `FAIL: <reason>`.
- `GreyboxLoopTestSuccess`: boolean; false until a complete pass.
- `GreyboxLoopTestFreshToSteal`: measured fresh character spawn -> successful theft, seconds. Time spent waiting before manually starting the test is included.
- `GreyboxLoopTestPortalToPortal`: measured run assembly/entry -> arrival at return portal, seconds.
- `GreyboxLoopTestCatches`: actual catches through the return leg.

The first timing is saved at theft, and return timing/catches at the return portal, even if a later assertion fails. Output records route steps, the one-second hold, timings, catches, chase ticks/distance and final success. The test does not assert proposed pacing targets or prove native prompt rendering; those need separate runtime evidence.

## Play after PASS

Use Enter at the central blue portal, follow the route and hold Steal for one second beside the glowing ball. Dodge around cover and Return at the same blue portal. Walk to the marked pen bearing your name and Place. Native E/controller X/touch prompts and the large on-screen action button use the same server validation. If native UI does not appear, E/X also works through the fallback while its action is in range. Steal requires holding the button/key for one second; early release, focus loss or leaving range cancels.

Catch applies one second of slow, then three seconds of mercy. Cargo is retained. Each pen holds eight plain balls. No hatch, income, purchases or persistence exists in T1. Reset/fall recovery keeps committed cargo in this server session and returns it home without counting an escape; disconnect retires that player's run/cargo/placements.

## Prompt investigation: checked vs UNKNOWN

**OWNER-REPORTED:** in an earlier Studio MCP Play session the character was approximately 4.7 studs from the 10x8x2 HomePortal centred at (0,4,0), with activation distance 9 and line of sight disabled. `PromptShown` never fired and E did nothing. This session was not reproduced here; no callable Studio MCP was exposed.

**CHECKED CODE:** the old RenderStepped loop changed Enabled only on prompts carrying `PenSlot`. HomePortal has no such attribute, so that loop could not touch it. No script in this isolated Rojo mapping disabled the global prompt service, set a custom prompt style, suppressed portal Enabled, or changed portal input bindings. The old pen loop unnecessarily assigned Enabled every frame; it now changes only explicitly tagged Place prompts when the pen owner/tag changes and handles late attribute replication. Portal and run prompts are never changed by the client Enabled filter.

**Distance finding:** official docs define MaxActivationDistance relative to the player's character and prompt, but do not specify a nearest-surface rule for BasePart parents. Do not treat that rule as verified. At the reported 4.7-stud centre distance, both centre and nearest-surface distance are within 9, so that distinction cannot explain the reported absence (inference). All prompts now live under a zero-offset `ActionPoint` Attachment, making the origin explicit. Both the fallback and server validate root-to-action-centre distance <=9; neither relies on the nearest face of a large part.

**Mitigations added, not a proven original cause:** explicitly enable ProximityPromptService, set MaxPromptsVisible=8, and set each prompt Enabled=true, Style=Default, Exclusivity=AlwaysShow, RequiresLineOfSight=false, keyboard E, controller X, and clickable UI. Prompts are under workspace Attachments; StreamingEnabled remains false. Native hold-end cleanup now allows the matching Triggered event to consume its hold first, and completion waits out a short server timing remainder before revalidating. Holds are cleared as soon as server range is left. These hold fixes affect actions after input; they do not explain missing PromptShown.

**Fallback:** an always available, large touch-friendly button is shown for the nearest legal action within 9 studs, independently of PromptShown/global service visibility. `GreyboxAction` sends intent only; the server selects the current run or own pen and checks phase, ownership, range, cargo, capacity, active hold and token before changing state. It never accepts client-supplied item identity or rewards. Manual actions are blocked during the loop test.

To diagnose the next Studio session, watch client `[GreyboxPrompt]` logs:

- `client ready`: service Enabled and MaxPromptsVisible. Local player attribute `GreyboxClientReady` confirms client startup (inspect on Client; it is not server evidence).
- `SHOWN`: exact prompt path; `GreyboxPromptShownCount` counts native events.
- `portal range`: character-to-centre, nearest oriented-box surface and camera distances, prompt Enabled, service Enabled, prompt cap, style, and current native shown state. `GreyboxPortalCentreDistance` / `GreyboxPortalSurfaceDistance` hold the sampled distances.

A portal range log with no later SHOWN event narrows the failure to native visibility/session behavior. Missing client-ready output instead points to LocalScript startup/import/session issues. Check the current live client instance, camera visibility, service settings and script errors before attributing it to engine distance rules. Native rendering, E/controller input and touch hold remain UNKNOWN until observed.

Primary API references checked: [ProximityPrompt](https://create.roblox.com/docs/reference/engine/classes/ProximityPrompt), [official API source for activation distance](https://github.com/Roblox/creator-docs/blob/main/content/en-us/reference/engine/classes/ProximityPrompt.yaml), [ProximityPromptService](https://create.roblox.com/docs/reference/engine/classes/ProximityPromptService), and [proximity prompt guide](https://create.roblox.com/docs/ui/proximity-prompts).

## Files and verification

- `Greybox.server.luau`: runtime geometry, named validated actions, remote routing, loop-test gate/trigger, normal guardian and self-test.
- `Greybox.client.luau`: goal/highlight, tagged pen filtering, prompt diagnostics, range button and hold controls.
- `LoopTest.luau`: shared scalar route and real-character full-loop runner.
- `Layout.luau` / `GreyboxConfig.luau`: existing seeded recipes/tuning retained.
- `greybox.project.json`: Rojo mapping including the loop-test runner and locked initial attributes.
- `check.luau`: compilation, layout/route audit, source mapping and initial-gate assertions.
- `guardian-greybox.rbxl` / `sourcemap.json`: rebuilt place and refreshed map.
- `selene.toml` / `roblox_min.yml`: existing offline lint standard retained.

**CHECKED locally:** Lune 0.10.5 compiled all six Luau files at O0/O1/O2 with debug level 2. Shared layout replay/50-seed validation and malformed snap/route rejection passed. The actual full-loop scalar route passed sampled floor/rail/cover clearance for 50 seeds, including the reversed segments. StyLua 2.0.2 formatting/check passed. Selene 0.31.0 reported 0 errors, 0 warnings, 0 parse errors. Rojo 7.4.4 rebuilt the place with the exact required command. Lune deserialized it and verified matching server/client/config/layout/test sources and initial NOT RUN/false attributes. These checks do not run Roblox character physics, navmesh, guardian chase or native UI.

Place SHA256: `FA39C9B7C5B041C327546B20EA41F82CF11E82A1F15EE0914843364C25A42EF1`.

Run from this prototype folder:

```powershell
& C:/Users/zerha/.rokit/tool-storage/johnnymorganz/stylua/2.0.2/stylua.exe .
& C:/Users/zerha/.rokit/tool-storage/rojo-rbx/rojo/7.4.4/rojo.exe build greybox.project.json -o guardian-greybox.rbxl
& C:/Users/zerha/.rokit/tool-storage/lune-org/lune/0.10.5/lune.exe run check.luau
& C:/Users/zerha/.rokit/tool-storage/johnnymorganz/stylua/2.0.2/stylua.exe --check .
& C:/Users/zerha/.rokit/tool-storage/kampfkarren/selene/0.31.0/selene.exe .
```

Existing prototype/layout/check code was reused; no third-party framework, asset or dependency was added, so no new licence obligation was introduced. No edits outside this folder and no commit. Build stays at the requested path rather than Desktop.

Named comparison targets from the existing plan remain Steal an Egg (guarded pickup/reverse escape), BGSI (hub/portal clarity), and Pet Simulator 99 (later reveal). This change protects the existing loop; no arena, visual comparison, independent critic, device pass or owner acceptance is claimed. Studio full-loop success, timings, catches, prompt rendering, multiplayer isolation and feel remain UNKNOWN. The complete Keystone Roblox Process Playbook was not available in the local coordination/project search or exposed tools; the supplied greybox-core-moment rule was applied.

Lessons:

- When native action UI disappears, log client startup, prompt/service state and distances because server proximity alone cannot prove native visibility.
- When adding a full-loop test, reuse production action functions and require a real placed object because a grant-only test misses return/placement failures.
- When a build has only static evidence, ship its runtime gate as NOT RUN because compilation cannot establish movement or guardian behavior.