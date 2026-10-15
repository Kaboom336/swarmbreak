# Cave v2.1 separate-place checks

**Built:** `prototype/cave-v2.rbxl`. No Studio session or multiplayer playtest was run. This is a runnable prototype with static evidence, not an accepted gameplay build.

## Checked evidence

- Source geometry reads approved `treasure/cave-v2/ROUTES.json`; native-part manifest, sloped slabs, category tags, binary generation and offline-render workflow reuse the inspected Meadow v4 pattern. Core `Config`, `Domain`, `Profiles`, `Runtime`, `Service`, `Tests` are mounted by reading existing `prototype/core` source paths; no new source copies. The separate loop uses existing Domain secure/place/open operations and volatile state. No imported art/code kit or new dependency was adopted; no separate repository license file was found for the project's own code.
- Lune build compiles every embedded script, serializes then deserializes the separate binary. `cave-v2/tests.luau` checks shared-core same-item award idempotence, refusal while pending, place/open/repeat, and native sloped slab endpoints.
- `cave-v2/AUDIT.json`: zero collision hits across 3,291 sampled avatar positions: <=2-stud longitudinal spacing, lateral centers -7/0/+7 and cardinal radius2 at body heights3.5/6.8. This tests an 18-stud corridor against all native colliders. It is a sampled audit, not an exhaustive continuous sweep or Roblox physics test. Graph audit: zero unreachable route nodes. Maximum proposed walking grade22.83 degrees.
- `cave-v2/STRUCTURAL-AUDIT.json`: one connected mountain component; zero floating colliders in an OBB contact graph rooted only in the deepest underside part (0.06stud tolerance). Zero cave24headroom hits across897 samples; zero oriented green-flight and red-fall hits across65 samples each; zero oriented track-cart body envelope hits sampled <=2stud. The bearing beam breaks with the span so the fail path stays clear. Wheels are allowed track contact. Zero missing floor ray hits across3,291 samples; maximum predicted-route to actual-floor snap2.6565stud at overlapping joins. These are static geometric checks, not structural strength, exhaustive swept physics, or Studio acceptance.
- **Continuous collision, footstep behavior at the2.6565stud maximum join variation, emergency dismount and seat replication: UNKNOWN.** Numeric0 applies only to the exact documented static methods. Runtime acceptance remains pending.
- Offline `cave-v2/build-raccepted-concept.png` renders the actual geometry manifest using the inspected Meadow renderer by read-only reference. The concept camera is approximately reconstructed, since generated concept art has no camera metadata. No Studio screenshot or exact visual parity claim. `accepted` is a snapshot name, not a gameplay acceptance verdict.

## Greybox corrections from the illustrative routes

The east cave now exits the solid camp terrace before descending; the north crosslink gains a flat lead-in before descent. The rail walking bypass and south crosslink gain flat merging sections. The pit's original short ramp intersected higher routes: its implemented climb runs north under the higher bypass, climbs west, and reaches the lower south crosslink. It is longer than the originally estimated87.1stud/5.4second recovery; those original pacing estimates do not apply to this greybox. Full route lengths and travel times need measurement.

The first audit found301 body intersections. Removing intersecting camp mass/pads and supporting lower corridors reduced them; independent review found Lune0.10.5 `CFrame.lookAt` produced an incorrect pitch for offline slabs. An explicit orthonormal basis constructor fixes native geometry and matching manifest. The second reviewed worst visual gap was the thin, rectangular underside; the final geometry uses ten connected tapered rings of faceted rock columns, physical timber trestle posts, a foreground portal shell/ring, a high camp crystal crown, and outward/downward underside crystal clusters. A landing exit stays flat before descending, preventing carts clipping the24high landing. Reviews and render snapshots remain separate from runtime acceptance.

## What exists / what is a placeholder

- Three routes, independent rail bypass, pit floor and climb-out, open crosslinks, roofed cave sections with actual skylight gaps; grey-blue/purple rock and dark slate inverted mountain. Camp landmark and rails/lanterns/crates/scaffolding/native ore cart props.
- Two runtime seat carts follow track at24 or12stud/s. Dock wait2/3s; explicit brake and emergency-dismount prompts. Broken span16stud; committed24-speed jump uses fixed arc; low-speed choice falls to the pit. Green commitment locks flight speed; ordinary seat departures are deferred during flight. Physics/seat replication are **untested**.
- Support hook:0.4hold,1s fuse+2s cracks,20s minimum broken state, occupancy-gated repair. Switch hook:2s amber warning, driver override, padded24-wide siding, harmless3.5s diversion,12s cooldown. Basic prototype states exist; final empty-only fairness/queue behavior remain untested.
- TNT hook:1s preview/15s cooldown. Guardian dynamite hook:1.5s lock preview+1s fuse/7s cooldown. Shatter hook:bursts1/1.8/2.6s, each1s tell/20s cooldown. They are visibly colored, **non-damaging placeholder hooks**. Guardian locomotion, actual dynamite projectile, support debris, blast force, shields, mercy, contested pickup priority, item-drop sockets and shatter pressure rings are not implemented here.
- Loop:2s steal, same cargo ID and60s clock during ride/pit rescue, portal secure, core place/open prompt, repeated secure refusal handled honestly. Death/disconnect returns the sole geode; drop/handoff and production core integration remain future work.

## Comparison and reference status

`cave-v2/CONCEPT-COMPARE.png` places concept v2.1 beside the hash-matched offline native-geometry render. The first blind correction removed camp/route intersections and fixed native transforms; the second strengthened the inverted-mountain silhouette. Further review exposed buried crystals and prompted structural/envelope audits. Final art parity remains weaker than the generated concept; this is a greybox.

Fresh final critic: **PASS documented static scope**, greybox source/geometry **8/10**, visual concept comparison **5.5/10**. LOOK concept critic **8.5/10**. Runtime **UNKNOWN**. Zero sampled hits and graph reachability do not certify continuous collision or smooth footsteps. Full verdict: cave-v2/CRITIC-D.md; final source/artifact hashes: cave-v2/FINAL-EVIDENCE.json.

Real Roblox mine/cart gameplay reference: **none viewed**. Searches surfaced cart ride around nothing and Cart Ride Through A Mine Tycoon; the gameplay screenshot candidate download failed and the primary developer-forum image page returned a robot challenge. No current top-ranking or footage claim, and no fabricated reference side-by-side. Search evidence is in treasure/cave-v2/LOOK-V2.1-REVIEW.md.

## Studio route and acceptance checks

1. Open `cave-v2.rbxl`; Play. From portal, check crown silhouette; walk main to camp. Check all three route signs from the carrier camera. Steal2s, carry down each path and secure in cyan apron; place/open via portal prompt before repeating.
2. Board both seats;24/12 speed toggle. Blast marked support. Green jump lands on broad floor; red continuation reaches pit. Walk the entire climb-out. Emergency dismount before launch goes to bypass; seat jumping during flight waits for landing. Verify both carts, boarding, respawn, queues and8clients.
3. Preview all five hooks muted; confirm visible individual timings. Switch next cart, override during amber warning, then deliberately take padded siding and dismount. Confirm no prototype hook damages an avatar or geode.
4. Sweep each18wide lane and cave24headroom with avatar/camera; verify roof joints, bypass/cart transitions, pit recovery and every rail node. Check support contact, underside joins, gap sockets, dead ends and all float/clip counts in Studio. Check carrier death, reset, disconnect, deadline and repeated secure/open behavior.
5. No publication or live persistence is authorized. Keep this separate from `guardian-greybox.rbxl` and Meadow work.

## Lessons

1. When an offline engine supplies transforms, test a real tilted endpoint because a compiling helper can still produce the wrong geometry.
2. When routes share different heights, exit terraces and flatten merges before descending because broad slabs can block an otherwise plausible centerline.
3. When a pit recovery crosses other routes, audit the whole avatar corridor because centerline-only clearance misses shoulder collisions.
