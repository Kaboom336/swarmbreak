# Reviewer FX v4 — checked evidence / honest limits

2026-10-13 follow-up: [library animation review](mocap/REVIEW.md) contains the current selected poses and honest blind scores.
The earlier runtime boulder discrepancy is corrected to the log. Throw .620, slam .800 and dash .500 clocks still drive gameplay/FX.
New GIFs are matched pose/prop fixtures; native FX playback and audio remain UNKNOWN.

Reused and read the approved Keeper rig, sampler, renderer, authoritative attack kit, hit callback integration, and local golden-acorn mesh/import code. No third-party dependency, uploaded art or copied reference asset; no new licence dependency. Exact Keystone playbook unavailable through exposed tools/local copies; repository `pumpkin-loop/PLAYBOOK.md` read. Existing local models/fx images are historical pet effects, not reusable runtime code.

## What exists

| Event | Native presentation |
|---|---|
| lobWindup / lobRelease / lobImpact | dust; spinning carrier Trail; dust burst, ten debris chunks, light, crater decal and near-player shake |
| fanWindup / fanRelease / AcornPop | low dust; three brown/green real acorn meshes with spin trails; small cover/contact pops |
| slamWindup / slamRelease | crouch dust; crater/debris/light/shake, expanding wedge ring mesh plus dust, same 22 radius / 24 speed as gameplay |
| dashWindup / dashRelease / WallStun | scrape dust and .5s lowered pose; speed lines and dust trail; literal star orbit/burst and full 1.55s gameplay stun |
| Warn / PlayerHit | orange ! with Back-eased UIScale pop/settle; literal yellow star burst, spark particles and light |
| Chase / Return / Celebrate / Stun | named transition hooks, small dust or stun stars; same animation clock |
| Reset | destroys guardian-owned effect hosts; ordinary effects also expire through Debris |

Damage remains server-side, once/victim, via the existing accepted-hit callback. SFX hooks clone named Sound objects to world hosts; camera shake runs after Roblox's camera update with 65-stud attenuation. Presentation culls beyond 140 camera studs. These limits are implementation values, not measured performance. The larger visible log is 8×6×6 with a conservative 8-stud collision sphere; target/splash ring remains radius 8. No changed safety/mercy/shield rules.

## Audio TODO — no verified free IDs, intentionally silent

All following Sound objects have `SoundId=""`, a TODO attribute, and descriptive names under client `PlayerScripts.KeeperSounds_TODO`. No guessed audio IDs and no sound licence claim. Assign only verified Roblox free audio before audible review:

`lobWindup`, `lobRelease`, `lobImpact`, `LogBlocked`, `fanWindup`, `fanRelease`, `AcornPop`, `slamWindup`, `slamRelease`, `dashWindup`, `dashRelease`, `WallStun`, `Warn`, `PlayerHit`, `Chase`, `Return`, `Celebrate`, `Stun`.

Built-in Roblox smoke/sparkle texture paths are presentation textures, not audio assets. Official API checks: [ParticleEmitter](https://create.roblox.com/docs/reference/engine/classes/ParticleEmitter), [Trail](https://create.roblox.com/docs/reference/engine/classes/Trail), [camera render priority](https://create.roblox.com/docs/reference/engine/enums/RenderPriority).

## Blind arena — two independent critics, still strips only

Neutral IDs withheld implementation/mapping: A slam, B warning + separate accepted-player-hit fixture, C lob, D dash, E fan. Critics viewed five chronological samples per strip, no source/storyboard/prior scores. Reference bar: Vesteria Ethera, World // Zero bosses, TDS attack readability. **No current reference footage was viewed**; side-by-side performance parity is UNKNOWN. [Official Vesteria Ethera database](https://db.playvesteria.com/monsters/ethera) supplies a textual mechanics lead (shockwaves/projectiles), not visual proof. Our storyboard is prior/current comparison, not fabricated screenshots of those games.

| Proof | Critic 1 | Critic 2 | Visible gap |
|---|---:|---:|---|
| lob (C) | 4.5/10 | 5/10 | log/ring reads; translated arm looks detached, overhead prop clips preview, impact lacks force |
| fan (E) | 4.8/10 | 4/10 | distinct three directions; tiny acorns/thin lanes/trails lose phone readability |
| slam (A) | 5/10 | 6/10 | large radius reads; bright static outer ring confuses active rim, modest impact force |
| dash (D) | 3/10 | 3/10 | travel reads; preview line underrepresents native 4-stud lane, contact and speed lines weak |
| warn/hit (B), first | 2.5/10 | 2/10 | tiny sparks/stars, unclear recipient, weak pose contrast |
| warn/hit (B), revised | 5.5/10 | 5/10 | ! and player-owned stars clearer; tiny player and thin warning remain |

One weakest-item correction: stronger warning anticipation/arm/hat overlap, larger bounced ! in offline proof, larger runtime star billboards; render a separate blue player fixture surrounded by expanding stars. Re-rendered B and both critics re-inspected it. The category clarification (warning/hit, not a damage attack) changed the final scoring basis, so the increase is **not purely a measured improvement**. A later dash proof correction makes wall fixture/stars visible; D's original conservative score stands unless rejudged.

## Verification

CHECKED: real kit tests including dash .499 hold/.9 swept contact, full 1.55s wall stun, accepted-hit FX, safety/leash stop and reset; real Arena integration; current built module/client/event parity; 12 clip data, driver marker/hitch/cancel/package checks; posed fists/held/flight clearance; existing 50-seed layout/ownership/deadline/PvP/trap/navigation mocks; Selene zero diagnostics, StyLua and git whitespace checks. Main greybox backed up before Rojo. No commits/publishing/security changes or map-job writes.

The log clearance fixture uses a **5-stud enclosing sphere**, larger than the log's actual circumsphere, for all sampled poses/flight/yaws. Its tightest sampled flight margin is about **0.139 studs**; fan about **0.068 studs**. These are checked offline geometry results, not guarantees between samples or on every terrain. Validate release/hat separation in Studio.

GIFs decode through existing ffmpeg; still samples were visually inspected. **UNKNOWN:** continuous playback feel, Roblox particles/mesh loader, sound, camera shake, real-device cost, wall collision/terrain and multiplayer/late join, human hit rate and owner acceptance. New effects are not ready to call best-in-class. Model remains rigid; landing “squash” is a compression pose rather than deformation.

## Lessons

1. When an effect must read on a phone, judge at gameplay size, because tiny stars/trails can vanish despite detailed code.
2. When enlarging a held projectile, sample the entire pose/flight envelope with a conservative bounding volume, because hand clearance alone misses hat intersections.
3. When sound licence/availability is unverified, use named silent hooks, because a guessed ID cannot establish free usable audio.
