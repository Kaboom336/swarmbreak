# Meadow Keeper attack kit — design before implementation

2026-10-13 animation update: [library retarget review](anim/mocap/REVIEW.md).
Selected library-derived lob/slam/chase, existing hand-keyed fan; attack deadlines and damage rules unchanged.
Runtime lob presentation is now the documented cylindrical log, using the shared overhead support socket.

Owner-reported problem: weak motion and a small, easy-to-dodge rock. Reuse the approved rig, authoritative guardian, existing knock/drop callback, safe zones, mercy and leash. No map edits, uploads, commits or security changes.

| Situation | Attack / tell | Escape / tuning starting point |
|---|---|---|
| Thief within 12 horizontal studs, similar floor height | Slam: deep crouch, jump, heavy landing at 0.80s; amber expanding shockwave | Jump over the moving rim, not the whole disc; 22-stud maximum radius, 24 studs/s expansion, 1.2-stud rim half-width, feet >2.5 studs above floor escape |
| Medium range 12–32 studs | Three acorns: shoulder sweep and three visible red lanes, locked velocity lead | Change direction or move between lanes; ±16° fan, 2.4-stud diameter, 0.62s release, 0.70s flight; swept collision, cover stops individual acorns |
| Far range or clustered thieves | Big boulder: wide load and fast outward release, red landing ring fixed at aim lock | Leave the 8-stud splash ring; 0.62s release, 0.90s flight, ring visible for 1.52s (exceeds requested 0.6s); 4-stud projectile; splash knocks/drops groups |

Selection: prioritize close slam on comparable floor height, then boulder if another running thief is within 10 studs of the target, distance >32, or target feet are >1.5 studs above/below the Keeper floor; otherwise fan. Per-attack cooldowns: slam 9s, fan 8s, lob 10s; shared start interval 5.5s; no fallback small rock. A cooling attack may defer while pursuit continues. Fan lead is 1.25s clamped to 18 studs; lob lead 1.25s clamped to 16 studs, both locked before release. These anticipate the attack's full deadline so straight running alone does not always evade it; changing direction still works. No homing. Recovery remains planted until the damage phase ends. Optional dash omitted: existing short broken lanes and unknown wall-stun tuning do not justify another attack yet. Ranged predicted landings within 12 studs defer; predicted fan landing elevation must also stay within 1.5 studs of the Keeper floor. Jumping in the close slam zone does not switch to a fan.

All attacks require valid arena floor, sight and safe-zone clearance; each victim must be in Run, outside safety, on compatible elevation, and satisfy existing hitPlayer mercy/shield rules. Once-per-victim per attack, even on hitches. Cover blocks splash sight and individual acorns. Shockwave can hit only at its expanding rim; crossing it while airborne avoids it. Reset destroys all attack parts; committed attacks cannot start a second windup. Existing return/leash checks still govern pursuit.

60-second balance target: **ESTIMATE, not playtest evidence**: unskilled solo about 2 accepted hits; skilled 0–1. Shared pacing permits at most 11 starts in 60s; assuming ~18% / 0–9% accepted-hit probability gives ~2 / 0–1 hits. Probabilities are hypotheses, not measured statistics. Validate with at least ten solo escapes at each skill level; tune shared interval/radius/lead first, never hide tells or remove mercy. No guarantee that current greybox loop tests model human dodging.

Proof will include animation GIFs, pair judging, a v3 sheet and telegraph storyboard. Studio runtime, phone readability and actual hit rates remain UNTESTED.
# Current reviewer kit v4 — 2026-10-13 (supersedes v3 below)

Lob is now an **8-stud rolling log**, retaining the fixed **8-stud splash radius** and matching red ring. Collision uses its conservative 8-stud sphere; the visible wooden cylinder is 8 long × 6 wide with cut ends and bark ridges. Held log uses the same hand socket and .620 release as flight. Larger outside overhead load clears the head/hat in offline sampling; its translated rigid arm still reads detached in the critic's strip.

Fan reuses the existing locally authored golden-acorn mesh, recolored brown with green cap/stem, scaled to small projectiles. Three ±16° lanes, .620 release and .700 flight remain. Meshes are local; conservative authoritative collision bodies remain on server. Spin trails and cover/hit pops are presentation.

Charge: alternate mid-range solo fan opportunities with dash when 12–28 horizontal studs away and the 12s dash cooldown permits. Feet scrape/shuffle, head lowers, red 4-stud lane; **.500s planted tell**, then locked straight direction at **48 studs/s for at most 24 studs**. Swept guardian-box wall collision stops immediately and starts **1.55s stun**, stars and impact feedback. No steering after lock. No floor, abrupt floor changes, safety or pursuit-leash boundary stop without wall stun. Existing hitPlayer acceptance/mercy/shield/drop rules and once/victim apply. Dash cannot overlap another attack; reset cancels it and its lane. Shared interval stays 5.5s.

Slam keeps .800 landing and 22-stud/24-studs/s moving rim, with deeper crouch, 3.8-stud authored torso jump and landing compression. Actual rigid model does not deform; “squash” is a compressed pose. Native wedge-mesh shockwave and its dust follow the same radius/speed; the damaging server ring is still authoritative.

All attack/key-move effects and named silent sound hooks: [anim/FX-REVIEW.md](anim/FX-REVIEW.md). Studio/audio/mobile/multiplayer are UNKNOWN. Offline blind scores are modest, not acceptance. Balance probabilities below remain historical hypotheses, not measured dash balance.

---
