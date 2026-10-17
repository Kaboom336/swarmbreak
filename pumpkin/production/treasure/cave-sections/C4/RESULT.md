# C4: REVISIT — four rounds mounted

Delivered `prototype/cave-v2.rbxl` only through the preserving
`prototype/cave-v2/build.luau c4-*` entry. No Studio play, plain Rojo,
studio.project.json, commit, publish, purchase or external message.
Byte-verified immediate backup: `prototype/cave-v2.pre-c4.rbxl`, SHA256
`bc59ede5f8df4e8f30916115fb0cf379dcf94fa67554e891dff5bfca7231a23c`.
Final SHA256 `6d3f246d27d1648a3a7a9c38b8617d8db0439f1a8e04394c93449da1f540c852`.

## C3 leftover

The supplied live shot's blank panel is original `CaveV2.CartSign`, not the C3
RIDE board. Shrunk 17×7 to 7×2.8, turned -75 degrees and lowered to keep its
bottom at the original post contact height. The Front CART face meets the
supplied dock approach (horizontal facing dot 0.99986). Original children,
flags, material and all C3 source/art remain exact. `r4-dock.png` shows the cart
vista clear of the former broad blank back; `C3-FIX.jpg` pairs the supplied
live reference with this explicitly labelled offline view. CART is peripheral/partly cropped.
The dynamic rideable cart/occupant is absent offline; live readability UNKNOWN.

## Four rounds

SPEC, locked cameras, REFS and generated TARGET precede implementation. TARGET
uses the five C4 camera compositions and approved v2.1 geology. An extra dock
camera verifies C3. An initial sign-occluded approach was rejected before lock.
Eyes/flight viewpoint are estimates, not an engine-measured trajectory.

| Round | Changes, limited to three recorded gaps | Native cosmetics |
|---|---|---:|
| R1 | Five supported slate silhouette masses only | 5 |
| R2 | Existing warning/status reverse faces and read-only burst/cracks; two crystal trios; two capped lamps | 25 |
| R3 | Lower same flashes, move lamp feet to native terrain, support/landing focus labels | 25 |
| R4 | Lower/facet same flashes, actual-ramp CLIMB OUT label, refine same focus labels | 43 |

R1 bearing separation was technically corrected from .06 to .02 before freeze;
all five forms then stay exact. GAPS-R1–R4 retain decisions before editing;
PRE/SBS and phone boards compare matched views. Before/R1/R2 saved text export
was completed after initial renders so existing front faces participate in the
final comparison. A final renderer-only correction sizes BillboardGui proxies
in screen pixels. No place art changed afterward. Four-round cap reached.

PRE/SBS sheet composition was finalized at close-out from retained immutable
previous-state captures and TARGET; GAPS decisions were written before edits.
This late composition is a process limitation, not a claim that the final
assembled PRE sheets existed before each round.

Reuse: inspected C3 builder/runtime, KitLibrary, actual local CC0 Quaternius
Rock_Medium_1 FBX and licence. Tinted meshes clear TextureID/SurfaceAppearance.
Staging, fit validation, retries and fallback follow C3; scans yield. Two new
PointLights: brightness 1, range 14, shadows off. Every new BasePart is anchored,
collision/query/touch false. Original CartSign query flag remains exact.

Presentation mirrors actual source Text and observes existing span Transparency.
Each opening emits 12 dust + 8 chip particles, lifetime max .6 seconds, Rate 0,
disabled outside emission. No Explosion, damage, physics, effect light, timer or
gameplay-state write. Crack GUIs attach to 60 nearby native rail fragments and
follow actual 2s CRACKS/open state. Three focus labels retain world occlusion
and 90-stud maximum distance. Engine replication/performance remains UNKNOWN.

## Checked

- VERIFY: all 35 original source bodies and complete unrelated serialization
  exact after removing C4 mounts and restoring only CartSign Size/CFrame.
  All 37 mounted sources compile O0/O1/O2. C1–C3, six suite bodies, timing,
  support-break gap, landing, rails, switch, carts, lanes and colliders exact.
- AUDIT R1–R4: bounds, 47 unchanged lane reserves plus one-stud margins, flags,
  new-art eye clearance, light caps and frozen R1 pass.
- CONTACT R1–R4: zero penetration against 14,409 original physical solids with
  unchanged conservative OBB SAT/.035 tolerance. Wedge boxes overbound.
- SUPPORT: 175/175 native-bearing probes pass for rock envelopes and relocated
  lamp feet. Crystal/actual FBX visual joints still need review; envelope support
  cannot prove every rendered surface touches its neighbour.
- RUNTIME: actual mounted producer passes textured MeshPart fixture, atlas
  clearing, fit/envelope validation, flags, staging failure cleanup, retry,
  idempotence and R1 freeze. Real asset loading remains UNKNOWN.
- EFFECTS: actual mounted module passes observable-signal fixture: zero protected
  writes, live text mirrors, crack state, one burst/opening, repeat event, lifetime
  cap and idempotence. A fixture is not an engine particle/performance test.
- Existing domain, board, drive, rider, ride-contract, runner and kit-library
  tests pass. Initial nonexistent `prototype/kits/tests.luau` command was rejected;
  the actual existing `library-test.luau` passes.
- Artifact-only check passes source/scene/manifest, production kit clearance/query,
  SelfTest, strict floor seams and policies. Stock historical check first rejected
  the authorized CartSign delta. Adapter changes only those two expected cosmetic
  fields and pins expected KitLibrary read to the unchanged mounted cave version
  (working tree has later Meadow edits). No assertion, tolerance, timer, policy,
  gameplay source or suite body is changed.

Fresh final-artifact N8 sweep: **PASS, 3,024 samples / zero failures**.
`DENSE-FINAL.json` binds the fresh report/log/input to the final place hash;
`FINAL-EVIDENCE.json` seals the artifacts. Retained kits 1,898, excluded 279,
16 retained types. This is the completed fresh run, not inherited Studio evidence.

## Remaining visual review

Inherited bars: Catastrophic Horse Racing anticipation/payoff; Steal an Egg
objective/exit clarity; approved v2.1 chunky slate geology. These are project
reference choices, not newly watched commercial footage. Author comparison finds
a clearer CART face, added rock/crystal framing, support/landing cues and a named
existing recovery ramp. TARGET is generated aspiration, never build evidence.

**REVISIT:** protected flat pit walls dominate; frozen tall/narrow shoulders read
as pillars; flashes remain peripheral/partly cropped and exact mesh joints need
a live look. New recovery lamps have little visible return: do not multiply
hidden detail. Target's enclosing/distant geology and rich lighting exceed scope.

Static shots retain intact span/rails and omit the dynamic cart, seated avatar,
timed cracks and burst. They do not prove big air, warning timing, landing success
or fair climb feel. SurfaceGui fonts/strokes, light falloff, retained deferred kit
art, fog and bloom are approximate. Fixed-pixel UI has a matched-size offline
proxy; it is not a GUI screenshot. No fake geometry or camera cut establishes a clip.

Independent Claude/owner visual acceptance and six live Studio suites
(SelfTest, DropSampleTest, BoardingTest, LoopTest, CartRideTest, BlastPolicyTest)
remain **UNKNOWN / NOT RUN**. No independent critic acceptance claimed. Claude
should later compare dock, approach → real support break → air/landing → slow
fall/pit climb using these cameras. No fifth round or other-section expansion.

Scene JSON/review places are gitignored and not staged. Requested
`treasure/hermes/CAVE-REFS.md` is absent; REFS.md was read. Exact Keystone Roblox
Process Playbook was not found locally or in connected Notion search; returned
AI Roblox Game page has no process playbook. Owner process/production skill apply.
Files stay in the explicitly requested repository.

## Lessons

1. When a blank sign blocks a cart, check its face/player-camera footprint,
   because safe bounds do not establish readable approach framing.
2. When all-height floor reserves reject posts, reuse existing faces/read-only
   signals, because cosmetics must preserve fair recovery space.
3. When BillboardGui uses fixed pixels, size offline proxies in screen pixels,
   because world-size lettering exaggerates near-camera clutter.
