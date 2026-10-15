# Kit swap handoff for Claude / Studio

## Runtime kit integration — latest delivery

Open `prototype/guardian-greybox.rbxl` for the main game or `prototype/cave-v2.rbxl` for Cave. Source lives in `prototype/kits/`; both Meadow Rojo projects mount it. The latest binaries were patched from their existing places, not regenerated from scene manifests. Existing `.pre-kits.rbxl` backups remain untouched; this task also captured fresh `.kit-runtime-baseline.rbxl` snapshots before source mounts and before Rojo. No commit or publish. Files remain in the requested repository because Desktop is outside the writable root.

Checked: `ROBLOX-ASSETS.json` contains **71** entries (37 Meadow, 34 Cave), versus the owner-reported 72. Claude's successful Studio loads and zero-script inspection are **owner-reported**, not independently repeated here. Every listed ID is loaded at server start with up to three attempts; successful assets are cached once under `ServerStorage/KitTemplates/<island>__<name>`. No invented 72nd ID. Kenney and Quaternius CC0 licence notices and the existing exporter/builder code were read and reused.

`KitLibrary.spawn(name, island, baseCFrame, scale)` accepts a native-size multiplier or a Vector3 target box for uniform fitting. Trees use the current assembly height, including crowns. Imported models are sanitized before parenting into the game, normalized to bottom-centre pivots, anchored, tagged by island/type, and use Automatic RenderFidelity. Merged single-mesh trees receive a narrow trunk-only collision proxy for generic callers. In this swap, every imported collider/query is disabled and every original collider, named reference, light, and gameplay script stays at its existing path. Missing loads return an explicit reason and leave originals visible. Originals are hidden only after successful spawning/fitting; failed adjacent fence bays retain their art.

Meadow assignments cover 28 whole trees (CommonTree/Pine/Twisted), 62 bushes, 28 boulders, 86 whole flowers, and 43 whole mushrooms. Sparse three-piece pebble/log/stump accents use existing bush footprints; they do not create collision or drop-ray targets. Existing cluster positions are reused. Current Meadow fencing has 12 straight bays and **no spline turns**: eight flat bays fit the loaded mesh to retained post faces, preserving zero analytic endpoint mismatches; four sloped bays retain the original rails with explicit warnings because rigid kit posts cannot fit their vertical-post interfaces. `fence_corner` is cached but has no real turn to occupy. The original thin ravine deck fails the uniform `bridge_wood` fit and remains intact. No false claim that generic imported mesh faces received a Studio joint audit.

Cave replaces whole crate assemblies, loose floating rocks, scaffold columns/braces/shelves, station/shelter supports, and four whole tunnel arches. Dungeon wall/column/wall-opening/wood-support/wood-structure are assigned explicitly. The two nearest station crates become a barrel and chest; three small mushrooms dress that existing cluster. CONNECT path/fence/rail/trestle parts, crystals, cart, labels, hook targets, and gameplay geometry remain unchanged. Dungeon aperture appearance still needs camera inspection: unchanged physics does not establish visual clearance.

### Offline evidence and performance limits

`KIT-RUNTIME-OFFLINE.json` records compiled mounted scripts, unchanged saved Workspace geometry/collision and unrelated scripts, unique assembly membership, catalog coverage, fence endpoint calculations, and identical kit source mounts across the two main-place copies. Those main-place binaries already differed at task start; each was preserved separately.

| Target | Original target descendants | Projected minimum after kits | Added visible kit source triangles |
|---|---:|---:|---:|
| Main runtime Meadow | 34,601 | 35,365 | 305,951 |
| Standalone Meadow | 34,610 | 35,374 | 305,951 |
| Cave | 65,100 | 65,341 | 19,426 |

These are **offline projections**, assuming successful loads/fits; imported wrappers/SurfaceAppearances can add descendants. They include retained originals and small dressing, not the template cache or other islands. Source triangles come from the exported mesh manifest, not Roblox's renderer. The block/wedge triangle proxies before swapping are 375,860 Meadow and 683,128 Cave; curved primitives add an UNKNOWN number. Actual rendered total triangles before/after and real memory are **UNKNOWN** offline. Automatic LOD may change rendered triangles. High baseline instance counts and retained original geometry remain a performance risk; this pass does not claim a reduction.

At runtime, `KitTemplates` records actual cached descendant count, template source triangles, and whole-server memory before/after/delta in MB. The island root records actual descendant counts, spawned MeshParts/source triangles, primitive proxies, fallback count, and whole-server memory before/after/delta. Other server work can affect these memory deltas; they are not isolated mesh memory. The fake-service test's zero memory delta is simulated and is not performance evidence.

PASS: library fake-service contracts (single cache, transient/permanent failures, script removal, base pivots, immutable templates, sizing, trunk-only collision, tags/fidelity, rotated fitting); production Cave swap with forced failures (original properties/references preserved, failed assemblies visible, all kit meshes noncolliding/nonquery, reruns do not duplicate); fresh baseline preservation/compiler/grouping checks; **9,102 reachable-drop samples, zero failures**; 14 ravine policy assertions; Cave shared-core contracts; core domain/ProfileStore contract suite; Rojo source build.

Historical `meadow-v4/tunnel-test.luau`, `cave-v2/connect-check.luau`, and the final snapshot assertion in `core-check.luau` fail on this task's unchanged baseline too. They compare older script inventories/snapshots. `kits/baseline-tests.luau` reproduces the same three failure reasons; those tests were not weakened. New preservation checks compare every pre-task source and collision property. The saved CONNECT audit has zero gaps/unconnected/overlaps, and its geometry is unchanged; that historical audit is not an imported-mesh audit.

Reproduce with pinned Lune 0.10.5: `run prototype/kits/build.luau`, `run prototype/kits/library-test.luau`, `run prototype/kits/swap-test.luau`, `run prototype/kits/check.luau`, `run prototype/kits/baseline-tests.luau`, `run prototype/fix3-check.luau`. The generated Rojo source check is `prototype/kit-source-rojo.rbxl`; it does not replace the latest place.

### Studio checks — Claude / Zion

1. Play each delivered place. Wait for `[KitLibrary] 71/71` (or explicit errors) and `[KitSwap]` summaries. Check cache count/names, no imported scripts, one template per key, and a blocked ID leaves the old assembly visible. Confirm measured target heights and seating, especially tiny Kenney props.
2. Compare **one** tree/rock and **one** station crate at player-camera height against `assets/kits/_sheet.jpg` before accepting bulk appearance. Named references: Quaternius CommonTree foliage and Kenney modular silhouettes; Grow a Garden readability is an inference from `treasure/hermes/REFS.md`. Deep Rock Galactic's On-site Refining remains the connection benchmark from CONNECT.md. No new independent visual acceptance is claimed. Keep lush groups at 3–7, judge phone-sized player views, and verify the 57 pre-existing clusters still read as clusters. `CAVE-REFS.md` was absent; the existing Cave CONNECT reference brief was read.
3. Walk every route and jump/drop/recover at the bridge, tunnel exits, ravine, portal, and summit. Re-run GreyboxLoopTest, GreyboxPvpTest, GreyboxTrapTest, StudioPass clearance/reachable-drop gates, and CoreLoopTest with fresh Play sessions. Confirm danger tells/treasure/portal remain visible under wider natural crowns.
4. Inspect the eight fitted flat fence bays at post faces and rail ends; inspect the four retained sloped bays. Require a zero visible gap/overlap audit in Studio before accepting these imported faces. There are no current corners to replace. Confirm original bridge planks remain; do not stretch a whole bridge across a thin deck.
5. Walk through every dungeon opening and inspect scaffold joints/grounding from the player camera; ride the full cart line, board/dismount, activate the breakable span, and verify all retained CONNECT contacts and span visibility. Ensure barrel/chest/mushrooms stay beside the station cluster rather than obscure signs or the lane.
6. Capture actual root/template instance counts, total renderer triangles, Stats memory, and device frame time **before and after** at identical cameras/graphics settings. Check Automatic fidelity on every MeshPart. Compare desktop and phone/low graphics; the offline counts above do not certify the device budget.

Undo in Play: restore each original's `KitOriginalTransparency`, remove `KitDressing`, then restart with `KitSwap` disabled. Saved place geometry is unchanged; immutable pre-kits and fresh baseline places remain available.

Lessons: When native kit sizes differ, measure the loaded model and scale from target dimensions because a shared multiplier cannot fit trees and Kenney pieces. When a rigid fence cannot fit a sloped joint, retain the fitted bay because endpoint centres alone do not prove face contacts. When a historical test fails, run it on the untouched task baseline because a stale inventory assertion is different from a new regression.

API sources checked: [InsertService LoadAsset](https://create.roblox.com/docs/reference/engine/classes/InsertService), [Model ScaleTo/GetScale](https://create.roblox.com/docs/reference/engine/classes/Model), and [RenderFidelity](https://github.com/Roblox/creator-docs/blob/main/content/en-us/reference/engine/enums/RenderFidelity.yaml). The exact Keystone Roblox Process Playbook was unavailable in the bounded local check; supplied lessons and the existing local handoffs/CONNECT playbook were used without claiming the missing note was read.

---

The following is the earlier import-planning record, superseded by the runtime delivery above.

Read cave-v2/CONNECT.md first. The latest binary was preserved in cave-v2.pre-kits.rbxl; Meadow and main core places also have .pre-kits.rbxl backups. This task mounted source only; no geometry was swapped and CONNECT joints/colliders remain unchanged. Source and Workspace preservation evidence: KITS-OFFLINE.json. Studio runtime/appearance: UNKNOWN.

Import assets/kits/<island>/*.fbx as Models of MeshParts into ServerStorage/ImportedKits/<island>. Use manifest.json for names, shared base pivots, measured sizes and material colours; each material is a separate mesh, each mesh has one material. Configure importer units/scale so its bounding dimensions match sizeStuds (X,Y,Z); files use Y-up and 1 metre = 3.5714286 studs. Validate one oak, one rock and one crate first. Inspect assets/kits/_sheet.jpg alongside the existing Meadow/Cave views. Kenney Nature Kit is the modular silhouette reference; Quaternius CommonTree_1 is the foliage reference. CONNECT's Deep Rock Galactic connection benchmark still governs route infrastructure. These are inspected kit/reference choices, not an independent visual acceptance.

Windows source Nature FBX files are ASCII; Blender converted their equivalent licensed OBJ files. The manifest records actualSource. No vendor scripts ran. CC0 notices are copied beside the exports. Roblox import reference: https://create.roblox.com/docs/studio/importer.

## Replacements by prop type

Names below are exact names/prefix families from the saved places, not guessed Studio tags. The complete per-type assignment ledger follows this plan. Imported stem is pack__model; island folder supplies its palette.

| Island / code-built family | Imported kit | Rule |
|---|---|---|
| Meadow LookHillTree*, TunnelHillTree*, R5Oak* | kenney_nature-kit__tree_oak | Group trunk/crowns for each tree first; replace the whole noncolliding assembly. Quaternius CommonTree_1 is a detailed alternative after foliage/device review. |
| Meadow LookHillBush, TunnelHillBush, R5Bush* | kenney_nature-kit__plant_bush | Cluster crown/foot/side by location; keep occupied footprint. |
| Meadow LookHillFlower*, R5Flower* | kenney_nature-kit__flower_yellowA | One whole flower per stem; optional quaternius-nature__Flower_3_Group for flower beds. |
| Meadow LookHillBoulder, R5Boulder*, LookRockFragment | kenney_nature-kit__rock_largeA | Group facets/moss for each boulder; retain original collider separately. |
| Meadow small rock relief, skylight outcrops, pale tops | quaternius-nature__Rock_Medium_1 / kenney_nature-kit__rock_largeC | Decorative skins only. Keep skylight openings, tunnel clearance and mountain silhouette. |
| Meadow R5FencePost/R5FenceRail | kenney_nature-kit__fence_simple / fence_corner | Whole bay; fit endpoints to current posts, keep rails noncolliding. Never replace a post and rail independently with a whole fence. |
| Meadow bridge timber/guards | kenney_nature-kit__bridge_wood | Candidate for dressing only; preserve playable bridge, timed drop hooks and exact collision carriers. |
| Meadow grass/moss/vines/roots | quaternius-nature__Bush_Common or plant_bush | Sparse decorative clusters, not blanket replacement of turf, mountain cap or collision skins. Keep custom fitted vines where a bush changes the silhouette. |
| Meadow TunnelMushroom* | quaternius-nature__Mushroom_Common | Pair stem/glow as one mushroom; preserve lights under a named attachment. |
| Meadow portal stones | kenney_nature-kit__stone_largeA | Dressing candidate only; portal field, spiral, beacon, spawn and trigger stay custom. |
| Meadow mountain/cliff masses | kenney_nature-kit__cliff_block_rock / cliff_corner_rock | Small facade accents only; retain every mountain/ramp/tunnel collider. |
| Meadow lanterns, banners, windmill, castle, waterfalls | KEEP custom | No suitable complete lantern/banner/windmill/castle/waterfall in selected kits; dungeon walls do not reproduce the approved silhouette. |
| Meadow Acorn*, GoldenAcorn, Keeper*, route pads/tells | KEEP custom | Gameplay/focal art and route geometry; never swap by broad name matching. |
| Cave MineCrate, DressedCrate/Crate*, FramingCrate, R3SupplyCrate/R3YardCrate* | kenney_survival-kit__box / box-large | Replace whole crate including binding/diagonal bands; do not spawn a full crate per band. |
| Cave loose decorative rock, FloatingRock | quaternius-nature__Rock_Medium_1 / kenney_nature-kit__rock_largeC | Skin only; retain colliders and intentionally floating placements. |
| Cave CavernSidewall, CaveThickRoof, StackedMesaRock, mountain skins/underside | kenney_nature-kit__cliff_block_rock / cliff_corner_rock | Accent pieces only. Keep structural volumes and approved silhouettes. |
| Cave CaveArchStone/Voussoir, TunnelArchPier/Voussoir | kenney_mini-dungeon__wall-opening | Candidate whole arch assembly; fit opening and preserve collision clearance. Retain carved text as separate attachment. |
| Cave CaveMouthTimber/Lintel, scaffold/timber station, camp shelter beams | kenney_mini-dungeon__wood-support / wood-structure | Candidate decorative assembly, with original height/bay dimensions and retained gameplay carrier. |
| Cave shelter roof/station roof | kenney_survival-kit__tent | Candidate only for a complete decorative shelter; preserve original roof collider, station clearance and text/light attachments. |
| Cave ConnectFence* | kenney_nature-kit__fence_simple | Reference art only for this pass. KEEP fitted CONNECT fence segments until a new joint audit proves replacement endpoints; canned bays cannot replace trimmed profiles directly. |
| Cave ConnectSurface*, ConnectStoneStepRiser, ConnectRaisedEdging, ConnectFittedButtressSkin | KEEP fitted CONNECT modules | Do not swap the shared joint contours with generic stairs, path tiles or walls. |
| Cave ConnectSteelRail/Sleeper/Stringer/Terminal/GroundedTrestle, cart art | KEEP custom | No rail or cart kit exists. Preserve terminal profiles, ground contacts, seat, moving cart model and breakable-span follower. |
| Cave TinyMoss | kenney_nature-kit__plant_bush | Low noncolliding accent; never obstruct cart/sight corridors. |
| Cave barrel/chest new dressing | kenney_survival-kit__barrel / kenney_mini-dungeon__chest | Available imports; no existing barrel type was found, so add only after the first swap review. |
| Cave crystals/geode, TNT/dynamite, lanterns, hooks, signs, portal | KEEP custom | No matching complete kit. Keep crystal neon/glass treatment, readable TNT red, lights, telegraph attributes and prompt identity. |
| Both terrain, collision supports, paths, destination pads, spawn/treasure/guardian | KEEP custom | Kit catalog availability does not authorize changing gameplay geometry. |

## Replacement script plan

1. Claude saves a fresh Studio backup before import. Store models in ServerStorage; scripts use an explicit assignment table, never execute imported scripts. Strip any LuaSourceContainer from imported models. Name imports by manifest stem.
2. Dry run: enumerate MeadowV4/CaveV2 descendants by exact Name and the existing MeadowV4Category/CaveCategory attributes. Use the per-type ledger; protect all gameplay objects and colliders. Assign CollectionService tag KitSwapCandidate and attributes KitModel, KitAssemblyId only after manually grouping a whole tree, flower, crate, arch or fence bay. Repeated names are not unique IDs.
3. For each tagged assembly record original GetPivot()/CFrame, bounding box, collision properties, attributes, attachments/lights/prompts and parent. The source FBX shared base origin must be reconstructed as Model.WorldPivot after Studio import; Studio's automatic bounding-box centre pivot is not the authored base.
4. Clone the chosen imported Model. Use Model:ScaleTo only for uniform scale; resize individual MeshParts only when a measured fitting rule permits it. Set the replacement base pivot to original.CFrame * CFrame.new(0,-original.Size.Y/2,0) for a single part. For assemblies use the bounding box base transformed through its rotation, then PivotTo(baseFrame). This keeps the old world frame/orientation while accounting for the different base origin. Keep the original CFrame in KitOriginalCFrame; don't use a mesh centre as a base.
5. New visual MeshParts: Anchored=true, CanCollide=false, CanTouch=false, CanQuery=false. Preserve original invisible collision carriers unchanged; leave named script references at their existing paths. Transfer decorative lights/labels only via explicit attachments. Never delete colliders or hook targets to make the art fit.
6. Place replaced original visual assemblies in Workspace/KitSwapBackup, hide only approved noncolliding visual parts, and record an undo ledger (original parent/properties and replacement path). Attributes KitSwapVersion and KitAssemblyId make reruns idempotent. Fail the dry run for ambiguous grouping, missing templates, colliding candidates, or unexpected descendants.
7. Make one Meadow tree/rock and one Cave crate. Zion checks against the contact sheet and named references. Then bulk swap that accepted type only. Rerun clearance/route/cart/span checks; walk and ride in Studio, inspect floor/base seating and device frame time. CONNECT infrastructure needs its exact endpoint/overlap audits before any art swap there.

## Runtime handoff

CoreLoopTest now includes the offline ProfileStore contract suite plus a real isolated ProfileStore.Mock save/ack/release/rejoin check in Studio. Studio defaults to .Mock; real QA mode refuses ProfileStore's implicit offline fallback. New store: TreasureQA_Core_v1_ProfileStore. Schema 1 remains inside data; migration reads the original TreasureQA_Core_v1 after its session lease expires. Retire old servers before migration; the two store names cannot fence an old deployment that resumes later. Original records are never rewritten by migration. Read https://madstudioroblox.github.io/ProfileStore/api/ for the copied API.

Keeper slamRelease (the actual landing) and lobImpact use bounded distance-scaled Shake. Cave TNTHook/DynamiteGuardianHook shake after PayoffPreview begins, never during windup. Those cave hooks remain cosmetic previews, not newly implemented combat. HUD reveal/coin pops and Coins use Spring; Trove owns render bindings/connections and Signal routes local impacts. Player attribute ReducedMotion disables shake/pops and snaps the coin count.

Offline checks certify source/geometry preservation and FBX constraints. Real DataStore, session handover across live servers, Studio imports, camera/UI feel and device performance remain UNKNOWN. No commit/publish/Studio control.

Lessons: When a library changes the storage envelope, migrate into a separate store because treating legacy data as native can reset it. When a kit uses multiple colours, split it by material because one MeshPart needs one material. When routes already have fitted joints, retain those modules because generic art can reopen audited gaps.

## Complete saved prop-type ledger

Every saved BasePart name is assigned below. Route segment digits and CONNECT facet suffixes are collapsed into types; exact saved names remain in KITS-OFFLINE.json. KEEP covers protected custom geometry and types with no suitable exported kit. Candidate mappings are not automatic authorization to replace a collider.

| Island | Saved type/name family | Kit | Replacement unit / protection |
|---|---|---|---|
| meadow | AcornCap | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | AcornNest | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | AcornStem | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | BridgeThrowTell | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | BridgeTimberPlank | kenney_nature-kit__bridge_wood | candidate dressing; keep playable carrier |
| meadow | CastleBattlement | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | CastleKeep | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | CastleTower | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | ContinuousCyanRim | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | CyanPortalField | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | FarWaterfall | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | ForkCourt | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | GoldenAcorn | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | GrassShoulder | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | GreyCliffBlock | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | HomeStubSpawn | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | KeeperArm | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | KeeperBoot | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | KeeperCoat | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | KeeperEye | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | KeeperGreenApron | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | KeeperHatBrim | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | KeeperHatCrown | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | KeeperHead | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | LanternAmber | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | LanternCap | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | LanternPost | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | LookContinuousTurf | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | LookHillBankGrass | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | LookHillBankRock | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | LookHillBoulder | kenney_nature-kit__rock_largeA | decorative assembly; retain collider |
| meadow | LookHillBush | kenney_nature-kit__plant_bush | whole bush assembly |
| meadow | LookHillEarthBank | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | LookHillFlowerPetal | kenney_nature-kit__flower_yellowA | whole flower assembly |
| meadow | LookHillFlowerStem | kenney_nature-kit__flower_yellowA | whole flower assembly |
| meadow | LookHillGrassBank | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | LookHillTreeCrown | kenney_nature-kit__tree_oak | whole tree assembly |
| meadow | LookHillTreeTrunk | kenney_nature-kit__tree_oak | whole tree assembly |
| meadow | LookLightRockTop | quaternius-nature__Rock_Medium_1 | skin only; protect opening/clearance |
| meadow | LookRockFragment | kenney_nature-kit__rock_largeA | decorative assembly; retain collider |
| meadow | LookRockMoss | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | LookSkylightOutcrop | quaternius-nature__Rock_Medium_1 | skin only; protect opening/clearance |
| meadow | MountainMossTop | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | OptionalJumpLanding* | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | PortalPad | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | PortalSpiral | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | PortalStone | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | ProtectedPortalApron | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | R5BannerEmblem | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | R5BannerPole | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | R5BoulderFacet | kenney_nature-kit__rock_largeA | decorative assembly; retain collider |
| meadow | R5BoulderFoot | kenney_nature-kit__rock_largeA | decorative assembly; retain collider |
| meadow | R5BoulderMoss | kenney_nature-kit__rock_largeA | decorative assembly; retain collider |
| meadow | R5BoulderShoulder | kenney_nature-kit__rock_largeA | decorative assembly; retain collider |
| meadow | R5BridgeGuardBeam | kenney_nature-kit__bridge_wood | candidate dressing; keep playable carrier |
| meadow | R5BushCrown | kenney_nature-kit__plant_bush | whole bush assembly |
| meadow | R5BushFoot | kenney_nature-kit__plant_bush | whole bush assembly |
| meadow | R5BushSide | kenney_nature-kit__plant_bush | whole bush assembly |
| meadow | R5FencePost | kenney_nature-kit__fence_simple | whole bay; fit endpoints |
| meadow | R5FenceRail | kenney_nature-kit__fence_simple | whole bay; fit endpoints |
| meadow | R5FlowerCentre | kenney_nature-kit__flower_yellowA | whole flower assembly |
| meadow | R5FlowerLeaves | kenney_nature-kit__flower_yellowA | whole flower assembly |
| meadow | R5FlowerPetals | kenney_nature-kit__flower_yellowA | whole flower assembly |
| meadow | R5FlowerStem | kenney_nature-kit__flower_yellowA | whole flower assembly |
| meadow | R5HangingApex | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | R5IntentionalFloatingRock | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | R5IrregularRockFace | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | R5LampFoot | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | R5LeafBanner | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | R5LipRoot | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | R5MountainTier* | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | R5OakCrown | kenney_nature-kit__tree_oak | whole tree assembly |
| meadow | R5OakTrunk | kenney_nature-kit__tree_oak | whole tree assembly |
| meadow | R5SecondaryHangingPoint | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | RavineAngledButtress | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | RavinePaleStoneFacet | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | RemoteIslandMoss | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | RemoteIslandStone | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | RidgeThrowCourt | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | Round4HangingLipMoss | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | Round4HangingMossCluster | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | Round4HangingMossLight | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | Round4HangingMossTip | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | Round4JumpAmberEdge | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | Round4JumpPalePad | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | Round4OverhangLip | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | Round4PaleRockTop | quaternius-nature__Rock_Medium_1 | skin only; protect opening/clearance |
| meadow | Round4RockMoss | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | Round4ShelfLightFacet | quaternius-nature__Rock_Medium_1 | skin only; protect opening/clearance |
| meadow | Round4ShelfMossDrop | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | Round4ShelfMossLedge | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | Round4ShelfRockRelief | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | Round4StackedRock | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | Round4TaperChunk | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | SolidMountainStone | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | SolidRampBody | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | SolidRampWedge | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | StonePathEdge | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | SummitCampEW | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | SummitCampNS | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | TaperedIslandStone | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | ThickMossLip | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | TunnelArchMossColony | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | TunnelArchedRockRib | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | TunnelBlueCrystal | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | TunnelClosedVault | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | TunnelDirtStone | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | TunnelEntranceVine | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | TunnelExitAmberCrystal | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | TunnelExitArchCrown | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | TunnelExitArchShoulder | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | TunnelExitMoss | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | TunnelExitVine | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | TunnelFoundation | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | TunnelHillBush | kenney_nature-kit__plant_bush | whole bush assembly |
| meadow | TunnelHillEarth | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | TunnelHillGrass | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | TunnelHillTreeCrown | kenney_nature-kit__tree_oak | whole tree assembly |
| meadow | TunnelHillTreeTrunk | kenney_nature-kit__tree_oak | whole tree assembly |
| meadow | TunnelHillTurf | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | TunnelInnerRockFacet | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | TunnelMouthCliffFace | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | TunnelMud | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | TunnelMushroomGlow | quaternius-nature__Mushroom_Common | whole mushroom; retain glow |
| meadow | TunnelMushroomStem | quaternius-nature__Mushroom_Common | whole mushroom; retain glow |
| meadow | TunnelPuddle | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | TunnelRockCourse | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | TunnelRoughRockCore | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | TunnelShaftOfLight | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | TunnelSkylightGlow | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | TunnelSkylightRockRim | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | TunnelStalactite | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | TunnelValleyJoin | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | TunnelValleyJoin_Cobble | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | TunnelValleyRetainedJoin | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | TunnelValleyRetainedJoin_Cobble | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | TunnelVineLeaf | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | TunnelWallMoss | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | TunnelWallRoot | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | TunnelWarmExitLight | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | WaterfallFoam | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | WindingCobble | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | WindingRavineStream | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | WindmillRoof | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | WindmillSail | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | WindmillTower | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | bridge* | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | bridge_south* | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | east* | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | east_climb* | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | east_descent* | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | fork_link* | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | jump_access* | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | jump_recovery* | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | north_crosslink* | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | portal_north* | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | ravine_floor_loop* | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | ravine_ramp* | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | shelf* | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | shelf_link* | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | south_crosslink* | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | spiral* | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | summit_radial* | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | tunnel_south* | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | tunnel_trunk* | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| meadow | west* | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | BailSign | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | BreakableSpan | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | BroadLanding | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | CampShelterBeam | kenney_mini-dungeon__wood-support | whole timber assembly |
| cave | CampShelterRoof | kenney_survival-kit__tent | whole shelter candidate; retain roof collider |
| cave | CampShelterTimber | kenney_mini-dungeon__wood-support | whole timber assembly |
| cave | CartLanternCap | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | CartSign | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | CartSignChain | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | CartStationBracket | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | CartStationHangingSign | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | CartStationLantern | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | CartStationTimber | kenney_mini-dungeon__wood-support | whole timber assembly |
| cave | CaveArchCarvedName | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | CaveArchStone | kenney_mini-dungeon__wall-opening | whole arch; preserve opening |
| cave | CaveArchVoussoir | kenney_mini-dungeon__wall-opening | whole arch; preserve opening |
| cave | CaveMouthLintel | kenney_mini-dungeon__wood-support | whole timber assembly |
| cave | CaveMouthTimber | kenney_mini-dungeon__wood-support | whole timber assembly |
| cave | CaveSign | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | CaveThickRoof | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | CavernSidewall | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | CliffInsetBlock | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | CliffScaffoldBrace | kenney_mini-dungeon__wood-support | whole timber assembly |
| cave | CliffScaffoldPost | kenney_mini-dungeon__wood-support | whole timber assembly |
| cave | CliffScaffoldShelf | kenney_mini-dungeon__wood-support | whole timber assembly |
| cave | CliffSteppedLedge | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | ConnectFencePost | KEEP custom | fitted CONNECT joint/contact profile |
| cave | ConnectFenceRail | KEEP custom | fitted CONNECT joint/contact profile |
| cave | ConnectFittedButtressSkin | KEEP custom | fitted CONNECT joint/contact profile |
| cave | ConnectGroundedTrestle | KEEP custom | fitted CONNECT joint/contact profile |
| cave | ConnectRailSleeper | KEEP custom | fitted CONNECT joint/contact profile |
| cave | ConnectRailStringer | KEEP custom | fitted CONNECT joint/contact profile |
| cave | ConnectRailTerminal | KEEP custom | fitted CONNECT joint/contact profile |
| cave | ConnectRaisedEdging | KEEP custom | fitted CONNECT joint/contact profile |
| cave | ConnectSteelRail | KEEP custom | fitted CONNECT joint/contact profile |
| cave | ConnectStoneStepRiser | KEEP custom | fitted CONNECT joint/contact profile |
| cave | ConnectSurface_BroadLanding* | KEEP custom | fitted CONNECT joint/contact profile |
| cave | ConnectSurface_GeodeCamp* | KEEP custom | fitted CONNECT joint/contact profile |
| cave | ConnectSurface_PaddedSidingFloor* | KEEP custom | fitted CONNECT joint/contact profile |
| cave | ConnectSurface_PitFloor* | KEEP custom | fitted CONNECT joint/contact profile |
| cave | ConnectSurface_SafetyApron* | KEEP custom | fitted CONNECT joint/contact profile |
| cave | ConnectSurface_cartApproach* | KEEP custom | fitted CONNECT joint/contact profile |
| cave | ConnectSurface_cave* | KEEP custom | fitted CONNECT joint/contact profile |
| cave | ConnectSurface_crosslinkNorth* | KEEP custom | fitted CONNECT joint/contact profile |
| cave | ConnectSurface_crosslinkSouth* | KEEP custom | fitted CONNECT joint/contact profile |
| cave | ConnectSurface_main* | KEEP custom | fitted CONNECT joint/contact profile |
| cave | ConnectSurface_pitRecovery* | KEEP custom | fitted CONNECT joint/contact profile |
| cave | ConnectSurface_railWalkBypass* | KEEP custom | fitted CONNECT joint/contact profile |
| cave | ConnectSurface_trackDeck* | KEEP custom | fitted CONNECT joint/contact profile |
| cave | CrateBinding | kenney_survival-kit__box-large | whole crate including bands |
| cave | CrateDiagonal | kenney_survival-kit__box-large | whole crate including bands |
| cave | CrateIronBand | kenney_survival-kit__box-large | whole crate including bands |
| cave | CrystalDarkFace | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | CrystalFacetEdge | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | CrystalInsetFacet | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | CrystalNeedle | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | CrystalPoint | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | CrystalPrismFace | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | CrystalShaft | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | CrystalTipEdge | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | DestinationFabric | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | DressedCrate | kenney_survival-kit__box-large | whole crate including bands |
| cave | DynamiteBundle | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | DynamiteGuardianHook | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | FloatingRock | quaternius-nature__Rock_Medium_1 | decorative skin |
| cave | FramingCrate | kenney_survival-kit__box-large | whole crate including bands |
| cave | FramingTNT | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | Geode | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | GeodeCamp | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | HangingRockLobe | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | InvertedMountainFacet | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | JumpReady | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | LandingRockBearing | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | LanternCornerFrame | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | LanternHanger | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | LanternIronCap | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | MainGatewayFabric | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | MainGatewayFoot | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | MainGatewayLintel | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | MainGatewayPennant | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | MainGatewayTimber | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | MainSign | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | MineCrate | kenney_survival-kit__box-large | whole crate including bands |
| cave | OreCartChassis | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | OreCartEnd | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | OreCartSide | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | OreCartWheel | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | PaddedBumper | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | PaddedSidingFloor | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | ParkedMineOreCart | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | ParkedOreCartWheel | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | PitFloor | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | PortalBeacon | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | PortalCyanRing | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | PortalSlateLintel | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | PortalSlatePillar | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | PortalSpawn | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | PortalSpiral | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | R3CliffVoxelSkin | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | R3CrateBinding | kenney_survival-kit__box-large | whole crate including bands |
| cave | R3DistantIsland | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | R3OreCartEnd | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | R3OreCartFloor | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | R3OreCartSide | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | R3OreCartWheel | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | R3RockTopChips | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | R3SupplyCrate | kenney_survival-kit__box-large | whole crate including bands |
| cave | R3TNTStack | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | R3YardCrate | kenney_survival-kit__box-large | whole crate including bands |
| cave | R3YardCrateBand | kenney_survival-kit__box-large | whole crate including bands |
| cave | RailSwitchHook | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | ReadableLanternPool | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | ReadableLanternPost | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | RecoverySign | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | RouteRockButtress | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | SafetyApron | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | ShatterCavernHook | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | ShelterLantern | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | SideUndersideCrystal | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | SideUndersideCrystalTip | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | SpanBearingBeam | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | SpanBearingPier | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | StackedMesaRock | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | StationOreCartChassis | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | StationOreCartEnd | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | StationOreCartWall | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | StationOreCartWheel | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | StationRoof | kenney_survival-kit__tent | whole shelter candidate; retain roof collider |
| cave | SupportBlastHook | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | TNTBinding | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | TNTHook | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | TinyMoss | kenney_nature-kit__plant_bush | low decorative accent |
| cave | TunnelArchPier | kenney_mini-dungeon__wall-opening | whole arch; preserve opening |
| cave | TunnelArchVoussoir | kenney_mini-dungeon__wall-opening | whole arch; preserve opening |
| cave | UndersideCrystalShaft | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | UndersideCrystalTip | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | cartApproach* | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | cave* | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | crosslinkNorth* | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | crosslinkSouth* | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | main* | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | pitRecovery* | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
| cave | railWalkBypass* | KEEP custom | gameplay, fitted terrain/route, focal art or no matching kit |
