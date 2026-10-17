# C3: REVISIT — four rounds mounted

Delivered `prototype/cave-v2.rbxl` only through the preserving
`prototype/cave-v2/build.luau c3-*` branch. Immediate pre-C3 backup:
`prototype/cave-v2.pre-c3.rbxl`, byte-verified SHA256
`a50a0f8cefc6d7c78d26610ba2988057a017e72a754d088a9d76ed209f35b3a7`.
Final SHA256 `bc59ede5f8df4e8f30916115fb0cf379dcf94fa67554e891dff5bfca7231a23c`.
No Studio play, plain Rojo, studio.project.json, commit or publish.

## Changed

68 native cosmetic parts: supported timber station platform/frame, plank finish,
ore pile, two warm capped lamps, a double-faced RIDE board projected toward the
dock, five slate rock fallback envelopes and two groups of three faceted crystals.
The runtime stages existing CC0 Quaternius Rock_Medium_1 kit art outside CaveV2.
Tinted meshes clear TextureID/SurfaceAppearance; failed fitting retains fallback.
Lights are brightness 1, range 14, shadows off. Creation/scans/retries yield.
Every new BasePart is anchored and collision/query/touch false.

All 34 original sources, all six suite implementations, original cart physics,
seats, rails, ride/blast contracts, lanes, colliders and complete unrelated
serialized place state remain exact. Removing the C3 Workspace folder and server
script restores complete normalized baseline serialization. 35 sources compile
at O0/O1/O2. C1/C2 art and runtime mounts stay exact.

## Four rounds and visual evidence

SPEC.md, REFS.jpg, built-in generated TARGET.png/PROMPT.md and CAMERAS.json
precede implementation. BEFORE plus PRE-R1–R4 and SBS-R1–R4 compare the fixed
dock, seated-start, mid-ride and overview views. Initial seat-height study was
rejected before final camera lock; seated eye remains estimated, not engine-tested.

R1: eight frozen silhouette parts (four rock masses and station frame/platform).
R2: only station identification, two crystal flashes and ore/warm lamps.
R3: only board height, forward second flash and one off-lane mid shoulder.
R4: only projecting/rotating the board, narrowing/repositioning the mid shoulder
and its existing trio, and faceting the same six crystals. GAPS-R1–R4 record the
three gaps before each round. No fifth round.

Inherited comparison bars: Steal an Egg objective readability; Catastrophic Horse
Racing anticipation/payoff; approved v2.1 chunky slate geology. These are project
references, not fresh commercial footage observations. Side-by-side author review
finds visible rock shoulders and flashes, a warmer station pocket and more legible
station identification. **Still below bar:** the protected old sign masks the
cart's right side; the station platform/ore are peripheral; the mid crystal is
clipped by the left frame; retained box walls dominate; the TNT event itself and
seat motion are unverified. No new explosion or mechanic was added.

Native/FBX geometry uses fixed approximate lighting. Original deferred kits,
engine SurfaceGui/Fredoka rendering, bloom, fog, avatar and motion are not fully
reproduced. The visible parked cart is original scenery; the dynamically created
rideable cart is absent from these offline renders. Thus these images do not
prove real boarding-cart or seated-avatar readability. TARGET invents enclosing
geology and lighting: aspiration only, not authorization or screenshot evidence.
One R4 text-proxy orientation error was corrected in the renderer only.

## Offline checks and explicit misses

- AUDIT-r1–r4: section bounds, 47 lane reserves and one-stud margins, cosmetic
  flags, new-art eye clearance and light caps pass. R1 eight-part plan stays exact.
- CONTACT-r1–r4: zero penetration against 14,409 original physical solids, same
  conservative OBB SAT and .035 tolerance; wedge boxes overbound actual shapes.
- VERIFY.json: complete unrelated serialization and mounted-source parity pass.
- RUNTIME.json: actual mounted script with textured mesh fixtures passes fitting,
  tint clearing, flags, full-envelope lane validation, staged failure cleanup,
  retry and idempotence. Two shared-style RIDE faces are checked. Real asset
  loading/replication remains UNKNOWN.
- Existing tests, cart-board, cart-drive, rider, ride-contract, runner and kit
  library tests pass on the final build; mock logic is not engine physics.
- SUPPORT.json deliberately **FAILS** full-envelope bearing: 22/150 corner/grid
  probes miss on four rock envelopes. Their centers bear on retained terrain;
  the platform and right shoulder pass all probes. Partial overhangs remain a
  revisit item; contact/lane passes do not turn this into a support pass.
- Fresh final-artifact N8 sweep **PASS: 3,024 drops, zero failures**, with
  1,898 retained kits, 279 excluded and 16 retained types. The final dense run
  includes the original artifact/source, SelfTest, floor seam and policy checks.
  DENSE-FINAL.json and FINAL-EVIDENCE.json bind this result to the final hash.
  The unchanged stock checker runs with only its expected KitLibrary read pinned
  to the exact pre-C3 mounted version; the on-disk shared loader has later Meadow
  changes. No assertion, tolerance, timer, gameplay source or suite is weakened.

Six live Studio suites (SelfTest, DropSampleTest, BoardingTest, LoopTest,
CartRideTest, BlastPolicyTest), independent Claude review, phone performance,
fun and owner acceptance remain **UNKNOWN / NOT RUN**. No live green inherited.
Requested hermes/CAVE-REFS.md is absent; hermes/REFS.md was used. Exact separately
titled Keystone playbook was unavailable in checked local paths. Scene dumps are
gitignored, no scene JSON staged. Delivery remains in the explicitly requested repo.

## Lessons

1. When a sign passes bounds but is cropped, project its whole face into the
   locked player camera before dressing, because a valid overview hides the miss.
2. When native FontFace serialization adds defaults to unrelated labels, create
   the new sign GUI at runtime, because appearance work must preserve originals.
3. When all-height lane reserves pass, still test bearing and frusta separately,
   because safe placements can overhang terrain or disappear from the seat.
