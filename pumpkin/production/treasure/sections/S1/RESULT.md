# S1 Portal Plaza — round 3: acceptance FAILED

Arrival mask results after the authorized three renders: **24.18% lower-left / 20.49% lower-right**, against **25% each**. Portal artwork occupies **3.86% of the whole frame**. Metric regions are the bottom third of image height and outer thirds of width (bottom corner cells of a 3x3 grid), using occlusion-aware object-index masks derived from shipped part tags and imported S1 kit identities. No decorative floor or shadows count as props. Camera remains (0,5.5,154), 24mm. The coverage target is not met; no fourth render was taken.

The 8–25-stud camera-distance target is also not fully met: the framing tree roots are about 35 studs from the camera, with bushes/cart farther ahead. Moving objects forward along the shoulders brought them into the frustum but exceeded that proximity target. The next review must resolve camera framing versus that distance constraint; do not call this approved or expand into S2.

Built: two fitted 24-stud trees, 7-stud bushes, 4-stud barrels, 3.5-stud crates; two 8x3x1.5-stud planters with six large blooms each; 8-stud lantern posts; an 8-stud cart with tied sacks. Summit beam stays between the trees. Portal presentation lowered and scaled to 55%; physical pad and trigger unchanged. Left cliff now has actual face-attached vines, base rocks, and licensed kits2 wood-support/wood-structure skins on the supported mine carriers, plus a lantern pair. The mine mouth remains weak from arrival.

Artifact: `slice-v2/prototype/guardian-greybox.rbxl`; byte-verified backup **before Rojo**: `guardian-greybox.pre-s1r3.rbxl`. Only Section1 changed from that immediate backup; 71 scripts compile O0/O1/O2, 70 unrelated sources and serialized Workspace preserved. Rebuilt physical/floor/lane/tag signatures match. Existing policy/core/coordinator/reset behavior and 50-seed route checks pass (`r3-behavior.log`, `r3-legacy-check.log`). All eight live Studio suites remain **UNKNOWN after R3**.

Apron rule: R3 art wholly inside the 48-stud apron may occupy its outer shoulders, reserving a strict 32-stud central corridor across internal ground-route samples. Route geometry and buffers outside the apron remain protected. This explicitly changes the old presentation reservation, not gameplay tests or physical routes.

Contact evidence: `r3-physical-contact.json` is the final conservative physical-penetration/support audit; `r3-mesh-contact.json` records original FBX fitting. After the third render, 32 off-camera vine parts were removed to clear contact failures. `r3-offscreen-trim.json` proves their boxes are wholly outside the arrival frustum, preserving its visible mask coverage; indirect lighting may differ. The overview image predates this trim and is labelled accordingly. No final independent approval is claimed.

Proof: `SBS.jpg` = before / R2 / R3 / target; original 3 render logs and iteration 1/2 arrival images/coverage retained. Grow a Garden remains the composition reference for planted foreground framing. The generated target still wins on broad planting, scenic cliff treatment and close prop mass. Local Kenney and Quaternius CC0 licences and existing fit/spawn code were inspected; no external dependency added. Exact Keystone playbook unavailable locally; no Keystone tools connected.

Lessons added to `../LESSONS.md`: measure visible tagged pixels, place silhouettes inside the frustum, and attach vines to actual wall spans. No commit, publish, purchases, account changes or messages.

## Historical round 2

Canonical: `slice-v2/prototype/guardian-greybox.rbxl`. Byte-verified backup BEFORE Rojo: `guardian-greybox.pre-s1r2.rbxl`. Only Section1 changed from this immediate post-UI backup; all 68 other sources and serialized Workspace preserved. No commit, publish, purchases or S2 work.

Built: larger planting silhouettes, five native sunflowers plus kits2 flowers; player-scale watering barrels, crates/box-large, seed chest, log/stump, simple/corner fences, round trees/bushes and rocks. Added a supported four-wheel seed cart with cargo, shovel and tied sacks; warm post lamps; pruned orchard trees in small arrival shoulders; fitted timber cladding/header at the existing south mine opening. Existing main stair/bridge retained. Foliage uses uniform fit; barrels use the existing Kit.fit function to reach chest height (3.4 studs tall, 2.4–2.8 wide), since uniform fitting alone made them too squat. Actual FBX dimensions are recorded in mesh-contact evidence; live imported fitting still needs Studio verification.

Checked: `r2-build.log`, `AUDIT.json`: 69 mounted scripts compile at O0/O1/O2; 68 unrelated sources preserved; rebuilt physical/query/touch/floor/lane/tag signatures equal the immediate backup. All actual route buffers clear; central apron corridor 32 studs. Mine header underside is 10 studs above datum, supported outside route buffers. New art is noncollidable/nonqueryable/nontouchable.

Contact: `r2-physical-contact.json`: 109 native parts and 28 kit envelopes checked; zero physical penetrations, zero kit support errors and zero unsupported native assemblies at 0.035-stud tolerance. Assembly joints connect to physical support. `r2-mesh-contact.json` checks actual imported FBX base heights. These are offline bounds/contact checks; botanical joins and intentional assembly contact are not unintended clipping. Live imported-mesh contact remains unverified.

Existing behavior checks pass in `r2-behavior.log`: policies, core save/load/replay, coordinator failure/reset/timeout and production reset. `r2-legacy-check.log` passes the 50-seed 3D walking route contract. The old Studio-prep runner's historical snapshot comparison fails on a previously changed Profiles source. Its behavior portion is reused unchanged in `prototype/s1r2-check.luau`; current preservation uses the immediate backup. No historical failure was relabelled PASS; no existing test weakened.

Matched arrival/overview: `r2-arrival.png`, `r2-overview.png`. `SBS.jpg`: before / r1 / r2 / target. `r1-*` preserves the previous delivered views. Independent blind image-only critic: cared-for junction reads, but garden scale/grouping remains too weak beside the cliff. One visual correction pass enlarged the left shrub/flowers, moved barrel/cart toward arrival and brought the right framing tree inward. Review evidence is recorded in `CRITIC.md`; initial candidate image evidence was inspected in the review conversation, while final matched images are retained on disk. No independent final acceptance claimed.

Remaining: the target has wider foreground gardens, a broad sandy plaza and a more scenic hill. Existing routes and left cliff still constrain composition; mine trim reads more clearly in overview. Beam and old non-S1 kits are labelled offline proxies. Roblox imports/materials, device performance, portal play and all eight live StudioPassAll outcomes remain **UNKNOWN after S1r2**. Review this one section before expansion.

## Historical r1 result (superseded by round 2 above)

Built ONE section for Zion's review; no commit or publish. `SBS.jpg` compares matched arrival and overview cameras with the built-in generated target. `REFS.jpg` has five official promo crops plus that target. `TARGET-PROMPT.md` records the built-in prompt; target is saved locally as `TARGET.png`. The new process, ten scene ownership envelopes, lessons and checklist are in the parent folder.

Canonical artifact: `slice-v2/prototype/guardian-greybox.rbxl`. Byte-verified backup before Rojo: `guardian-greybox.pre-section1.rbxl`. Only new Section1, Builder and KitSwap source mounts changed relative to that backup. Other pre-existing dirty work preserved. Project mapping adds the Section1 module. Asset reuse: inspected CC0 Kenney Nature/Mini Dungeon and Quaternius kits2 sources/licences; no paid assets, downloads or extra model scripts.

Checked: `AUDIT.json` and `build.log`: 67 scripts compile at O0/O1/O2; 64 unrelated sources preserved, including the eight suite implementations. Serialized Workspace equality and rebuilt collidable/query/touch/floor/lane/tag signatures match. All requested kits exist in the runtime manifest. All actual route buffers clear; the explicit low outer-apron artwork exception reserves a 32-stud central corridor. Existing apron floors and tags stay intact. Full-footprint support is sampled at intervals no larger than one stud; source-mesh base errors are recorded in `after-mesh-contact.json`.

Existing offline checks pass: policy tests, core save/load/replay contracts, StudioPass coordinator failure/reset/timeout handling, production reset logic and legacy 50-seed geometry contract. See `coordinator.log` and `legacy-check.log`. These mocked/offline checks are not live Studio suites.

Two independent blind critique rounds: blocked arrival → low portal artwork; invisible garden story → planting moved into the arrival view and made larger, with warm timber and watering barrels. `CRITIC.md` records critiques; `review1-*` preserves the intermediate candidate. No numeric quality score or visual approval is claimed.

Remaining gaps: target garden framing is richer and the hill more scenic; the real left rock wall and distant hill belong to later sections. S1's framing is deliberately compact around unchanged routes. Only new S1 source FBX meshes are reconstructed offline; existing kit substitutions elsewhere remain native proxies. Beam is an explicit proxy; Roblox lighting, texture imports, UI and actual portal play behavior need Studio.

All eight live StudioPassAll outcomes remain **UNKNOWN after S1**, not inherited PASS. `STUDIO-CHECKS.md` gives the exact test and camera recipe. No Studio integration is available in this session. Zion's scene review is the next process gate; stop before S2.
