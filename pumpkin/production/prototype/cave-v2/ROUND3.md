# Cave Round 3

**Blind critic 7/10; target met in two rounds (6, 7).** [Place](../cave-v2.rbxl), [comparison](CONCEPT-COMPARE.png), [final render](build-rr3-final-concept.png), [reviews](ROUND3-CRITIC.md), [bound evidence](ROUND3-EVIDENCE.json).

Read ROUND2.md, its source/evidence, the Roblox production skill and production gates, and the local Zion work note. Reused the existing native Lune builder, Meadow manifest renderer, and cave auditors. No external dependency or asset was added. The exact Keystone Roblox Process Playbook remains unavailable in the inspected local skill/work-note locations; no claim of retrieving it.

Kept all terrain collider transforms, sizes and accepted elevation/mass. Preserved routes, hook dictionaries and native attributes, cart/loop/core script sources, and protected Meadow/map-v4/core/input files. Main additions are art-only, with route shoulders checked before surface crystal placement. Noncollidable art clipping is not certified by the collision audits.

Added mixed purple/cyan clusters of 3–7 along exterior/stepped cliffs, path shoulders, tunnel arches, camp crystal base, underside and distant islands. Hero crystal increased from 102 to 122 authored size. Exposed darker prism faces and bright native facet edges improve depth. Each added cluster has a native PointLight; lanterns use warm PointLights. More tan paving, fences on route edges, lantern pairs at turns, cliff scaffold bays, loaded ore carts, crates, TNT stacks, camp/portal banners, finer shallow voxel face detail and lighter rock tops. Existing continuous trestle bays and intentional cart gap remain intact. Ten additional small distant islands include sagging lantern bridges.

Native night lighting saves brightness 2.3, exposure +0.35, bloom intensity 0.65 and threshold 0.8. Offline lighting uses an approximate translation; same concept camera eye/target/lens and resolution as Round2. No paintover or invented render-only objects. Side/top views are supporting evidence; distant art can extend outside those unchanged frames.

Verified nine script containers compile; native binary roundtrip; manifest/native transforms within 0.0001 stud; hook attributes and gameplay source equality. Route clearance, unreachable nodes, cave headroom, cart envelope, green flight, red fall, missing floor rays and floating colliders remain zero. One mountain collider component. Collider geometry equality binds audits despite later background-only placement changes. Studio play, decorative clipping, continuous physics, multiplayer and performance remain UNKNOWN; increased art/light count needs Studio profiling.

Blind critics praised density, warm paths, infrastructure and floating-mine setting. Remaining shortcomings are light spill, repeated rock/crystal patterns, black gaps, richer purposeful mine scenes and background atmosphere. No publish, commit, purchase, account creation or external message. Files remain in the authorized production workspace; Desktop is outside the writable root.

Rebuild: direct Lune 0.10.5 runs build.luau 4, tests.luau and round2-check.luau; copy its native report to ROUND3-NATIVE-CHECK.json, then run round3-check.luau to verify native script/hook preservation and restore the archived Round2 native report. Bundled Blender Python runs audit.py and structural-audit.py. Blender runs render.py -- r3-final concept side top. compose comparison using the existing System.Drawing layout, then run round3-evidence.py after. ROUND3-PROTECTED.json and round3-baseline files are this task's original baseline, never recapture them midway.

Lessons:
- When density rises but fidelity stalls, add faceted depth and deliberate work yards because repeated glowing crystals alone feel ornamental.
- When camera stays fixed, place background islands against the visible horizon because low distant islands disappear behind the main mass.
- When adding decorative density, preserve collider geometry and distinguish static audits from Studio performance because art/light count can grow without changing route checks.
