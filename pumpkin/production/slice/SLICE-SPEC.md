# Steal a Pumpkin — DRAFT vertical slice

2026-10-11. Design handoff, not approval to implement, publish, spend or commit. This drafting pass writes only here.
Pitch: **Steal guarded pumpkins, hatch pets, grow your candy pen.**
Evidence: read CONCEPTS.md, all seven board TARGETs, TOOLING-ROBLOX.md, Hit Game Bible, Rojo mapping, config including overrides, active server/client loop sections, scene builders and SmokeTest. Inspected all 15 current PNGs, individually and as contact sheet. No Studio playtest, imported asset inspection or runtime scores claimed: UNKNOWN.
Keystone Roblox Process Playbook was not available through connected tools or the searched local reference/active-work copies; apply the owner-provided rules (real art, core moment first, reference arena). Fetch the full note before implementation acceptance.
Authority: requested slice > CONCEPTS.md numeric/identity locks > current PNG composition > approved boards > Bible defaults > existing code. Label all new tuning below **PROPOSED**; never treat illustrated HUD balances as measured economy.
Best-in-class: Steal an Egg for lane, guards, carry, income and onboarding; Pet Simulator 99 for impact and UI finish. Local board frames are comparison material, not shippable assets.

## 1. Scope and simplicity budget

- IN: finished hub, eight player pens, Pumpkin Meadow, 40 wild pumpkins, one nest/three pumpkins, one active Scarecrow, candy smash, steal/chase, safe return, placement, explicit hatch, reveal, earning pets, scythe shop, Index and Graveyard gate purchase.
- IN: desktop and landscape touch, solo/two-client/eight-client checks, save/rejoin, server validation, asset ledger, repeatable Rojo build and visual evidence.
- OUT: playable Graveyard or Zones 3–7, King fight, raids/PvP theft/locks, selling, upgrades, Daily, quests, rebirth, fuse, mutations, merchant, passes, Robux, offline pay, dash, teleport and extra currencies. Keep legacy saved fields loadable, with effects disabled in this slice.
- Gate opens to a short safe preview threshold and an honest “Slice complete — Graveyard next” sign. No enemies, earnings, further gate or loading transition beyond it.
- Preserve three concept stall shells: Shop active; Sell and Upgrades labelled closed/later, no prompt. One operational stall; owner decision Q1 below.
- Build one finished pen + nest + chase + reveal first. Zion checks this against concepts before duplicating eight pens or multiplying props.

| First 10 minutes | Slice count | Bible limit / status |
|---|---|---|
| Learned systems | 5 required: smash; steal/escape; pen/hatch/income; scythe buy; gate. Index optional = 6 | Default <=5, law allows 5–7: optional Index is explicit exception |
| Visible systems | 7: those six + one clock slot | <=12; closed stall art adds no functioning system |
| Core verb / earning routes | Steal / 2: smash candy + pet candy | 1 verb + 1 earning route: requested hybrid is explicit exception |
| Menu buttons / contextual | Shop, Index / Drop only carrying | 2 + Drop: pass; hotbar/touch action controls counted separately |
| HUD numbers | Candy, income/s; contextual Carry n/3 | 2 + carry: pass; one timer occupies its own slot |
| Prompt families | Steal; pen Place/Hatch state; Shop; Unlock | <=4; hatch shares the pen interaction control |
| Enemy / clock / currency | 1 Scarecrow / <=1 / 1 Candy | pass; truthful clock decision Q2 pending |
| Tutorial / join modals / loss | 5 stages / 0 / 0 | pass; reveal follows action, never join |

Do not call this Bible-compliant without recording the two learning/earning exceptions and owner resolution of the clock/stall questions. Eight decorated showcase pens in review captures must not imply free owned earners in fresh gameplay.

## 2. Pillar build contract

Paths below are relative to `pumpkin/giant/`; KEEP means reuse inspected mechanism, subject to regression checks, not proven runtime quality.

### Map/world — hub-topdown, hub-perspective, zone1-topdown, zone1-perspective

- Hub **248 × 160 studs**, lane **120 × 160**, Meadow walls **25** high, all main/side paths **>=12** clear; exactly **8 pens**, four west/four east, each **38 × 28**; exactly **8 plaza lanterns**. Throne landmark **40** high beside **5.5** avatar (7.3×). Do not put the throne in the sole route to Meadow.
- Hub grass **#8CC765/#84BD5E**, cream path **#FBF1DC**, grape walls **#7A4FD0/#8A63DE**, orange caps **#FF8A1F**, rails **#FFF8EC**, wood **#B07A4A**, gold **#FFC83D**.
- Meadow grass **#9ED66A/#96CE62**, tan walls **#E8B87A/#F0C88E**, orange caps **#FF8A1F**; cream side paths. South HOME safe line, north **2 Graveyard / 1,000 Candy** gate. Nest **15–25 studs** north of entry, one **11-stud** guard beside it, three ghost-lavender shells, max **40** round wilds. Five prop families: hay, windmill, pumpkin sign, decorative scarecrows, lanterns.
- PROPOSED coordinate datum: ground `O=(Config.MapCenterX, groundY, Config.SafeLineZ)`; retain X=1500/SafeLineZ=150. North is +Z. Hub local X=-124..124, Z=-160..0; Meadow X=-60..60, Z=0..160; nest (0,0,20), guard (+11,0,20); gate Z=160. All camera coordinates below relative to O.
- PROPOSED pen centres X=±88, Z=-24/-60/-96/-132; dimensions 38 in X, 28 in Z. Rails face inward; eight internal slots preserve `Progression.baseSlots=8`. Allocate closest available north pen first; never transfer another player's pen. Grounded collision roots don't count as visible art.
- Warm peach/lavender sunset must survive default third-person and phone views. Board starting preset: ClockTime **17.5–18.5**, contrast **+0.1**, saturation **+0.15**, Bloom **0.4–0.6**, haze density **0.35**; tune to concept readability, not to a dark horror scene. No King/night tint cycle.
- KEEP `src/ReplicatedStorage/PatchConfig.luau` lane datum/zone IDs; server `Lane.zone`, pen ownership, gate range/closest-point helpers. KEEP scene contract names `Garden/Patches`, `Zones/Zone1/Spawns`, `Hoard`, `Market/Seeds`, `SpawnLocation`.
- REPLACE visible geometry/layout from `scene/Lobby.luau`, `scene/WorldPlan.luau`, `scene/LaunchLook.luau` through `LaunchLook5.luau` with one imported scene plus `scene/SliceScene.luau` asset placement/validation. Old patch chain must not run afterward.
- DELETE legacy map/patch/pyramid/road dressing from the slice build: `scene/BuildScene.luau`, `BigMap.luau`, `PatchMap.luau`, `Pyramid.luau`, `Revamp1.luau`, `Dressing10.luau`, `Polish6.luau` execution. Archive source; no broad disk deletion.
- DELETE active execution of `scene/install.luau`, `install-server.luau`, `install-client.luau` (embedded obsolete script sources). KEEP `scene/compile-check.luau`; REPLACE slice assertions in `econ-sim.luau`, `combat-check.luau`, `SmokeTest.luau`, not their wider historical evidence.

### Models/art — collectibles, pets, scythes, hatch-reveal, guards-and-king

- Round ribbed/stemmed **faceless** wild, ghost, nest and carry shells. Whole-shell glow only; drawn facial highlights in the Meadow nest are overridden by CONCEPTS.md. Wild baseline **3 studs** high (zone perspective inset); wrapped candy **1.5 studs wide** (guide governs the drawing's ruler); hay **4×4×6**, lantern **7** high. No cube hidden inside the visible open shell.
- Pen hatch shell **8×8×8** from hatch inset; curved removable rind segments and cream seeds; nest **2–3 blocks high**, physical stud height UNKNOWN—PROPOSED **1.5**. Carry uses the same shell design at PROPOSED **4** high; fitted into both hands, not stacked over head.
- Pumpkin Pup is exactly hatch-reveal identity: orange **#FF8A1F**, green stem, cream muzzle/chest/paws **#FFF8EC**, black eyes with square white highlights, black nose, four short legs, tongue. Common **3.2**, Rare **3.9**, Epic **4.7**, Legendary **5.7**, Mythic **7** studs against **5.5** avatar; size is cosmetic, not an income multiplier.
- Rarity tokens: Common **#B8B8B8**, Rare **#3D8BFF**, Epic **#A64DFF**, Legendary **#FFC83D**, Mythic **#FF3B3B**, Secret rainbow. No Uncommon tier; no rarity assigned by shell state. Roster exactly the **12** names in pets.png; retain 15 legacy IDs for save compatibility but exclude Moth, Toad, Kinglet from this Index.
- Hub review staging uses Pup/Crow/Ghosty/Black Cat/Candy Bat/Golden Pup/Bone Pup/Frost Owl. Unowned staging is cosmetic and removed when a pen is assigned; live owners show earned pets only. Index screenshot's three discoveries and 3/12 are a fixture, not starter entitlement.
- Seven scythe designs, **~6-stud shafts**, **3–5** large blade sections with seams (four in example), **2–3 colours + glow**. Build Rusty/Iron usable; Bone/Witch preview renders; Vampire/Candy/King later portraits only. Iron silver/grey, not wood-orange. Author mesh sections in Blender; no runtime wedge generator.
- KEEP config final pet rarity overrides, `PetSizes`, pose/grip/trail attachment contracts, server `Looks.source` clone sanitation, root/pivot/front conventions. KEEP client viewport rendering and bob infrastructure after refit.
- REPLACE `scene/VoxelModels.luau`/`VoxelKit.luau` visible output, config `buildScythe` and `makeWrappedCandy`, server `makePumpkin`/`Looks.wild`/`Looks.hatch` and `guardLook` visual adapters with imported models. Preserve invisible physics roots/attributes expected by loop code.
- DELETE visible primitive fallbacks (living Jack, generic sphere pet/pumpkin, part-built guard/tool) from finished acceptance path; missing art fails loudly. Keep generator source archived, not executed. `scene/ScytheLab.luau` becomes an imported-tool pose inspection fixture.

### UI/HUD — hud-desktop, hud-phone, panels-shop-index, hatch-reveal

- Desktop **1920×1080**, two Shop/Index menus left, Candy + income/s + Carry n/3 bottom-left, **one** top goal and **one** glowing ground arrow, two-slot hotbar scythe/pumpkin. Red RUN replaces normal goal during danger; **purple Drop**. No builder footer/title-strip UI.
- Phone landscape: Shop/Index top-left, currency above joystick, orange SMASH, purple STEAL/JUMP bottom-right. **32 logical px** safe inset, **48 logical px** minimum hit targets. No additional Sprint/Dash/Teleport buttons; no duplicated Roblox JUMP.
- Cream/grape/orange beveled kit: cream **#FBF1DC**, grape **#7A4FD0/#8A63DE**, orange **#FF8A1F**, dark strokes, green confirm. Purple X overrides board red X. FredokaOne; **3 px** contextual stroke at 1080p, **4–5** for banners; left <=**15%** width, bottom <=**8%** height excluding mobile controls.
- Board-derived panel starting size **0.5w×0.62h**, title **13%** panel height, overlap **25%**, radius **0.08**, outer stroke **4 px**. Open **0.3 s**, close **0.18 s**, hover **1.08×**, press **0.9×**. Preserve concept card proportions when fitting one panel at a time.
- Shop Scythes tab shows Rusty FREE, Iron **150**, Bone **1.2K**, Witch **9K**; latter two locked in this slice, later-tier chevron disabled. Other illustrated tabs have no function. Index **3 columns×4 rows=12**; one Claim, silhouettes/hints for undiscovered. Counters use real state; never hardcode 3/12 or +12/s.
- At most **one** small toast; yellow **#FFE14A**, **28 px**, **3 px** stroke, rises **40 px**, fades **1.2 s** (board). Counter roll **0.5 s**, icon pop **1.25×/0.15 s**. No persistent next-gate progress bar: concept overrides progression board.
- KEEP `src/StarterPlayerScripts/Patch.client.luau` `UI.tween`, `chunky`, `Palette.renderModel`, cleanup/centre ownership, carry/zone subscriptions. REPLACE token/layout/font/icon policies, HUD construction, IndexUI grid, shop composition, hotbar, mobile action wiring and reveal card.
- DELETE slice UI handlers/tiles for Daily, Pets menu, quests, boost/pass badges, Upgrades, Haunt, teleport, boss HP, multiple clocks and toast stacks. Do not render `panels-upgrades-daily.png` until a later milestone.

### Core loop feel — first-5-min, hatch-reveal, collectibles; PS99 board impacts

- Wild smash -> visible candy arc -> counter; nest steal -> Scarecrow wake -> carry home -> place -> E Hatch! -> wait -> shell opens -> pet income -> scythe -> gate. Smash never awards a carry item; nest shell state never reveals pet rarity early.
- Reveal beats **0/.3/.6/1/1.5/2.2 s after wait**: place pose, cracks, open curved shell, pet pop, rarity/name/rate + green Collect, New! pet in pen. Waits exactly **6 s new-player**, **8 s Orange**, **20 s standard**. Current new-player window **1,800 s** retained unless separately tuned.
- <=**8 rays**, <=**12 spark chips**; reveal is local to owner, neighbour sees world animation. Collect only dismisses presentation; it cannot mint another pet/payment. Restore input/HUD/camera by 2.2 s, including death/disconnect interruption.
- Board impact target: **6–12 chips**, normal burst **25–40%** screen width, floater **0.8–1 s**, merge within **0.3 s**, max **4** damage floaters; candy arcs **~0.5 s** (Bible). Use brief bounded camera nudge, never pause server simulation; audio pitch ramps **3–5%** per consecutive hit, resets after **1.5 s**.
- KEEP server `Wild.hit/pop`, hit cooldown/arc/server reward ownership; client `burst`, `damageText`, `pickupPop`, sounds and bounded shake as foundations. REPLACE cuboid cracking/seed presentation, carry pose and hatch sequencing in both Patch scripts. Keep true `Hatched`/`Reveal` events, not guessed timers.
- DELETE auto-steal via `Hoards.swing`: SMASH/E/STEAL must not take a nest accidentally. DELETE auto-hatch timer start on placement; begin timer only on owner pen interaction. PROPOSED automatic delivery on entering owned pen remains; same pen control says Place outside its delivery volume, then Hatch when seated.

### Combat/guard — zone1-perspective/topdown, guards-and-king Scarecrow only

- One **11-stud** mesh guard, sleep **2–3 cyan Zs** at **0.6–1 stud**; awake red !, roar **0.5 s**, head start **1.2 s** (current config). KEEP state machine wake/chase/return, ground ray, south safe-line leash and server range validation; imported silhouette must fit its movement root.
- PROPOSED: steal hold **1.0 s** consistently on keyboard/touch; current `seat` uses zero despite config HoardHold=1. Restore server elapsed-hold/proximity validation. Only one thief acquires a contested shell; guardian threat applies to carrying thieves, not bystanders.
- KEEP speed ratio **0.88** Zone1, base walk **16**, carry slowdown **1/item**, catch radius **3.5**, return speed **12** as initial code tuning. Remove min-speed **14** floor where it can overtake a loaded starter. Test geometry: visual contact and catch agree within **0.5 stud** (board telegraph principle).
- REPLACE server `bonk`: no forced drop/return-to-nest or loss; PROPOSED **1 s** stumble, held pumpkin retained, **3 s** mercy. Death/reset restores carried inventory or deposits it safely into own pen once; no duplicates, no loss. Voluntary Drop leaves recoverable owner-reserved pumpkin; no expiration loss.
- DELETE Zone1 Crow twist/hazard and combat rewards from slice; no guard HP/combat lesson, no hidden boss activation. Delete King/raid runtime scheduling in slice mode, retain compatibility fields. King landmark stays static; no 6-second face opening, HP bar or boss rewards here.

### Progression/economy — first-5-min, panels-shop-index, pets

- Concept prices **0/150/1,200/9,000/60,000/400,000/2,500,000 Candy**. Usable first two only. Gate **1,000** replaces final config **2,500** override. Preserve IDs `RustySickle`/`WoodenScythe` (display Iron) and Zone2 ownership flag; no bulk migration/removal of future-zone data.
- First nest hatch guaranteed **Pumpkin Pup / Common / +1 Candy/s**. Subsequent PROPOSED Zone1 rolls retain Orange/Pup **1/s** and Sunny/Crow **4/s**; weights **50/50** from current equal-pick mechanism. Three ghost-lavender nest shells conceal these outcomes. No Ghosty awarded from shell colour; future pet preview stays locked.
- Set slice HoardMult **1** to honour +1/s; remove weight/Gold/Shiny/stamp/order/pass income multipliers. Income starts on hatch completion (current code earns while waiting). Every pet displays rate and +N every **1 s**; one combined Candy counter.
- Conflict: storyboard smash shows **+1**, final config Zone1 pays **8**, hp **13** (ceil(5×2.5)), Rusty damage **5**, Iron **15**. PROPOSED first tutorial break pays **1**, subsequent breaks **8**, three Rusty hits/one Iron hit, cooldown **0.55 s**, respawn **8 s**; first-reward exception must be explained in tuning evidence, never silently called a concept number.
- PROPOSED first discovery Claim **200 Candy once**, no forced panel, no other Index rewards within slice; remove current 540-income-second/milestone reward ladder. Claim must persist and reject duplicates. This optional claim cannot be required to finish tutorial.
- PROPOSED deterministic balance model: one pumpkin at a time, movement/search **2 s/break**; Rusty cycle 3×.55+2=**3.65 s**, Iron .55+2=**2.55 s**. Incremental Iron throughput 8/2.55−8/3.65=**~0.95 Candy/s**, 150 payback **~159 s**, within Bible 1–3 min. This is arithmetic, not observed play.
- Gate requires earned gross **1,150** after Iron spend (or **950** with Claim). Measure active first gate **3–5 min**, first earner <=**120 s**, first reward <=**30 s**; rerun model with actual travel/steals/refill/contention. No freedebug Candy or lucky crit assumed. If targets fail, tune proposed rewards/search cadence, not locked concept price or geometry.
- KEEP active server load/save/session lock/retry/release safeguards, currency checks, tool/zone purchase, Index deduplication and legacy restore IDs. REPLACE slice tuning in `PatchConfig.luau`, tutorial/order reward coupling, income multipliers and optional Index reward calculation in `Patch.server.luau`.
- DELETE scheduled events, autosell/full-pen modal, rotating orders, migration compensation popups and economic side channels from slice execution. Full pen keeps theft unavailable with one toast; eight slots are free, no slot shop. Existing profiles use isolated slice namespace; no real-save overwrite.

### First five minutes — first-5-min, HUD sheets, hatch-reveal

- Exactly five tutorial stages: **Steal a Pumpkin!** (smash on route is a nonblocking opportunity); **Carry it to your patch!**; **Hatch it!**; **Buy the Iron Scythe!**; **Unlock the Graveyard!**. During chase RUN replaces stage text; during carry arrow only targets owned HOME. Placement/wait/reveal are states of stage 3, not extra quest systems.
- Concept target timeline **0:00 spawn / 0:08 smash / 0:15 steal / 0:20 place / 0:26 hatch / 3:00–5:00 gate**. These are targets, not measurements. Six-second wait plus 2.2-second reveal puts reveal END at **28.2 s** if hatch begins at 20; 26 is pet-pop vicinity, not end of presentation.
- Layout feasibility UNKNOWN: south spawn across 160-stud hub, throne detour, nest 15–25 beyond entry, return to assigned pen can miss 8/20/26 at walk16. Keep full scene geometry, time real route before promising storyboard. Q3 governs strict timing priority; no hidden teleport or 50-smash prerequisite.
- KEEP order persistence/migration mechanisms where applicable; REPLACE `TutorialOrders`, `nextOrders/publishOrders` objectives and client guide target selection. DELETE quest list/progress count, free Daily auto-grant, join modals and automatic future-feature unlocks.

## 3. Asset intake plan — real meshes, then runtime placement

No visible code-built primitive art, including generate_procedural_model. Invisible collision/interaction roots and UI/VFX primitives are allowed. Source candidates below are procurement plans; no asset ID or downloaded file is claimed vetted.
Reuse-first check: local `ServerStorage.KitSource/KitTemplates`, PetModels/GuardModels and KayKit templates are candidates, not approved final art. Verify mesh silhouette, package licence and no scripts before adopting; old generated voxel output fails the final-art rule.
Studio [generate_mesh](https://create.roblox.com/docs/studio/mcp) is documented; availability/quota/cost in this session UNKNOWN. Use only existing free allowance, otherwise Blender. Claude handles Studio/import/design review; Codex supplies intake files, adapters, tests. No accounts, paid tools, upload/publish without owner authorization.

| Model/prop | Source and exact generation/authoring brief |
|---|---|
| Wild/ghost/nest/carry shell; opening rind and seeds | Blender hero. “Round lobed studded faceless pumpkin, green stem, #FF8A1F rind, no cube core; hollow shell divided into curved removable segments, cream seeds; recolour whole shell ghost lavender #8A63DE, no facial glow.” Reuse same authored mesh at 3/4/8-stud states. |
| Pumpkin Pup | generate_mesh prompt: “Chubby orange studded voxel puppy matching hatch-reveal.png, green head stem, big black eyes with square white highlights, cream muzzle chest paws, black nose, short four legs, tiny tongue; 3.2-stud height, two to three base colours, toy plastic, no outlines.” Blender correct silhouette/topology before approval. |
| Crow, Ghosty, Black Cat, Candy Bat, Golden Pup, Bone Pup, Frost Owl | Blender from pets.png; exact stepped species silhouettes, stud surfaces, 2–3 colours, locked rarity heights. Seven authored companions/preview models; no generic sphere substitution. |
| Lava Slime, King Cat, Gummy Bear, Pumpkin Dragon | Blender rendered portraits + silhouettes from pets.png for Index only; no live future-zone rigs in slice. |
| Active Scarecrow | generate_mesh prompt: “11-stud studded toy Scarecrow, wide straw hat with purple band, orange pumpkin character head, brown stitched coat, straw hands, separate walkable feet and arms; strong T silhouette; match zone1-perspective guard and guards-and-king Scarecrow, not a pole decoration.” Blender separates rig pieces/Eye attachments. |
| Throne landmark, crown/head, fists, banner | Blender hero from hub-perspective: “40-stud grape-and-gold pumpkin throne, orange crowned smiling head, gold hands, wide stepped silhouette, banners, no boss chest crystal.” Static landmark; no fight rig. |
| Rusty/Iron scythes; Bone/Witch previews; later portraits | Blender four broad blade sections with studs/seams, ~6-stud shaft, grip/collar/tape or rivets; Rusty brown/Iron silver-grey; match scythes.png. Later five tiers have no gameplay dependency. |
| Straw nest/pen floor, hay/crates, wood sign, pen rails/posts/gates | Creator Store searches “hay bale low poly”, “straw nest”, “wooden crate”, “wooden sign post”, “halloween fence”; script-free mesh candidates, recolour cream/grape/gold. Blender fallback for exact 38×28 pen assembly. |
| Meadow windmill, wall pumpkin sign, decorative pole scarecrows | Searches “low poly windmill”, “pumpkin sign”, “scarecrow low poly”; one windmill, authored sign face is allowed on decor only. Decorative scarecrows have no guard hooks. Blender restyle to concept if kit is smooth. |
| Hub/Meadow lanterns, stall shells/awnings | Searches “halloween lamp post”, “market stall striped awning”; lantern height7, exactly8 plaza placements; Shop/Sell/Upgrades share shell, orange/cream stripes/grape signage. Strip every script before use. |
| Floors, walls, caps, path sections | Blender modular studded slab/wall mesh kit, apply exact pillar palettes and dimensions; invisible simple collisions. Runtime clones assets; never synthesizes visible Parts into art. |
| Trees, shrubs, grass tufts, perimeter rocks | [Kenney Nature Kit](https://kenney.nl/assets/nature-kit) CC0 verified page; [Quaternius Ultimate Stylized Nature](https://quaternius.com/packs/ultimatestylizednature.html) CC0 verified page. Inspect meshes first, Blender bevel/stud/restyle before use; no generic filler blocking paths. |
| Graveyard gate/skull pillars; threshold tombstones/dead trees | Searches “iron cemetery gate”, “halloween gate arch”, “tombstone low poly”, “spooky dead tree”; script-free mesh only, Blender unify purple stone, cream skull, lavender accent. No full Graveyard kit/world build. |
| Wrapped candy + icons/arrow/rays/particles | Blender candy 1.5-wide orange/gold mesh; render currency/scythe/pet portraits from accepted models. Kenney UI candidates; Store “sunburst rays texture”, “sparkle star”, “tutorial arrow 3d” image/mesh only. One authored arrow mesh. |
| Impact, candy tick, wake, reveal, UI and ambience audio | Existing Config.Sounds IDs first: inspect creator/usage permission and audition in the test place. Fallback Creator Store audio searches “wood whoosh”, “cartoon impact”, “coin collect”, “creature growl”, “reward jingle”, “ui click pop”; audio only, no model scripts. Record rights and audibility; no guessed IDs or account-dependent Mixamo workflow. |

Asset ledger per accepted piece: original URL/creator/asset ID or local authoring source, licence file, cost, script-scan result, mesh/texture counts, dimensions, destination, concept/shot ID, approval. Inspect imported hierarchy for LuaSourceContainer and reject before parenting into live scene; don't trust automatic stripping. Do not import kit code.
TOOLING reuse choice: retain existing Rojo/network/save/UI foundations first; no speculative Vide/Blink/ProfileStore migration. If a demonstrated need requires a library, read source and licence/pin version first (board reports MIT/Apache, not reverified here).

## 4. Gates and evidence

G0: contract/tuning/fixture resolved; one finished pen/nest/chase/reveal matched side by side, then Zion checkpoint before many. G1: all mesh sources/licences/no-script scans pass. G2: reproducible build/compile. G3: SmokeTest + fresh human route + multiplayer/touch. G4: independent visual critics per pillar and Zion 10-minute check.
Adapt `scene/SmokeTest.luau`, don't run unchanged: it currently Admin-resets/saves a profile, injects gate Candy, teleports, auto-hatches, opens Zones2–7, runs King and claims Daily. Its PASS cannot certify this slice, physical client gate passage, first-session timings or client-console cleanliness.

Required SmokeTest steps (each emits PASS/FAIL + observed value; failed prerequisite stops dependent claims):
1. Disposable isolated slice save, Loaded/character/Candy0/Rusty, eight pens and no join popup; no Admin reset against real profiles. Harness gated to Studio with guaranteed cleanup.
2. Real Bonk remote at field target: server HP falls, break pays exact configured Candy, one award on simultaneous last hit, never nests stolen by smash; respawn8 and max40. Reject remote spam, wrong types, nonfinite payload, remote range/facing/cooldown violations.
3. Real held Steal: one winner/two clients, Carry increments, one awake Scarecrow, head start1.2, HOME arrow south; carry capacity3 enforced. Forced catch preserves shell/Candy; guard never crosses safe line.
4. Return physically to owned pen: one placement, carry decremented, no auto-hatch; stranger pen/place/hatch rejected; full pen no loss. Real E Hatch starts6/8/20 wait by correct policy.
5. Hatch once -> PetLook Pup first, Common token, exactly+1/s within1 tick, reveal six beats and ends2.2; duplicate Hatch/Collect doesn't duplicate pet. Owner/neighbour clients see appropriate effects; controls/camera restored on reset.
6. Buy Iron via actual Shop control with insufficient/sufficient funds; debit150 once, saved ownership, damage15 vs Rusty5, one/two-hand grip/trail valid; locked previews cannot buy. Separate funded validation fixture from untampered timing run.
7. Gate actual UnlockPrompt: price1000 on world/server/UI, rejection at999, one debit at1000, Zone2 flag persists, owner client physically crosses into safe preview, another locked client cannot. No next-zone earnings/content.
8. Claim first discovery200 once; duplicate/rejoin grants0. Save/rejoin preserves Candy/tools/pen/Index/gate/pending hatch; disconnect/death/drop/contested pickup conserves item count. Eight players have distinct pens; ninth gets clear capacity handling, not shared ownership.
9. At10 minutes still no boss/Daily/Sell/Upgrades/raid/PvP/quest/second clock. Collect server AND client errors/warnings; no unexpected errors or warnings, leaked harness or remote listeners. Test 32px inset/48px hit targets and blocked GUI input via touch emulation.
10. Separate no-debug walk route records spawn→first Candy, steal→safe line→pen, hatch start/end, first income, Iron buy and gate. <=30s reward, <=120s earner, 15–45s repeat trip and 3–5min gate; log storyboard target misses honestly. No teleport/grant in this timed run.

Side-by-side shot plan: coordinates **PROPOSED framing**, not extracted cameras. Use datum O above, `lookAt(position,target)`, FOV50 unless stated, desktop1920×1080, compare gameplay crop without concept headers/rulers. Lock camera/preset/state, name files after sheets, retain raw and paired PNGs.

| Concept sheet / shot | Camera local position -> target / state |
|---|---|
| hub-topdown | (0,260,-80) -> (0,0,-80); FOV50, up=-Z, all8 pens/all8 lamps visible |
| hub-perspective | (0,42,-180) -> (0,17,-75); empty HUD, same-baseline avatar by throne |
| zone1-topdown | (0,250,80) -> (0,0,80); up=-Z, count40/3/1, north gate/south HOME |
| zone1-perspective | (0,9,-10) -> (0,5,65); FOV65; avatar escaping south, guard/nest visible |
| hud-desktop / hud-phone | (0,9,42) -> (0,4,15); FOV70, south-facing carry; phone native landscape +640-wide readability comparison |
| panels-shop-index | same HUD camera; separate Shop and Index captures, plus paired comparison; first four cards, 12 tiles; 3/12 fixture explicitly labelled |
| hatch-reveal | relative to pen shell P: P+(10,7,-14) -> P+(0,3,0); capture all six beat offsets, HUD/card as concept |
| collectibles | inspection stage, shell at P; P+(0,6,-14) -> P+(0,2,0); each state +5.5 avatar/candy scale |
| scythes | stage P+(10,7,-16) -> P+(0,3,0); front/back held Rusty/Iron, side silhouette, four blade sections |
| pets | stage P+(0,7,-18) -> P+(0,3,0); Pup closeup +same-baseline hub pet lineup, locked portrait sheet |
| guards-and-king | stage P+(0,14,-35) -> P+(0,6,0); Scarecrow11/avatar5.5; separate throne40 baseline shot, no boss fight claim |
| first-5-min | default player follow camera (behind12/up7, FOV70), six actual moments; gate shot local (0,8,140)->(0,8,160) |
| zones-strip / panels-upgrades-daily | DEFERRED: no slice build/capture required; check they don't leak live features. Graveyard gate preview only uses first panel mood. |

Independent critic checklist: each pillar has five items worth0/1/2 (missing/partial/matches), must score **>=8/10 individually**, zero missing core item, no averaging weak pillars away. Compare anonymized concept/build crops plus named best-in-class board frame. Claude/fresh independent reviewers judge after implementation; this draft assigns no score.
- Map/world: exact bounds/counts; unobstructed12-stud route; throne/gate phone silhouettes; palette/sunset match; HOME/nest direction.
- Models/art: Pup identity; round faceless/hollow shells; baseline size ladder; authored mesh/studs/material consistency; distinctive guard/scythe silhouettes.
- UI/HUD: two menus/clear centre; phone touch safety; cream/bevel/stroke kit; exact12-tile/four-card layouts; truthful rarity/counter/clock states.
- Core feel: input/contact timing; sound+burst+floater; candy arc/counter response; carry tension/readable chaser; six-beat reveal with clean recovery.
- Combat/guard: wake tell/head start; visual contact agrees; readable south escape; no-progress-loss catch/reset; contention/safe-line correctness.
- Economy: prices/rates match; felt Iron improvement/payback; gate3–5min without cheats; repeatable income/Claim saves; no hidden multipliers or late systems.
- First five minutes: first action/one objective; reward<=30; earner<=120; state-correct HOME/Hatch cues; observed gate goal without explanation.
Attach scene/build hash, dirty revision, asset ledger, raw captures, paired captures, device/layout and timing logs, SmokeTest report and critic decisions under `production/slice/evidence/`. Emulation is layout evidence; actual low-end device FPS/memory budget remains UNKNOWN until owner names target hardware.

## 5. Coder task order (implementation only after draft review)

| Task | Owns future files | Dependencies / acceptance |
|---|---|---|
| [T1 contract/config](tasks/T1-contract-config.md) | PatchConfig.luau; slice CONTRACT.md | First; final-loaded slice values, schema/asset/remotes contracts; no config override drift |
| [T2 mesh intake](tasks/T2-mesh-intake.md) | giant/assets/slice/**; slice asset/evidence intake files | AfterT1; one hero approved before many, script-free/licensed/scale verified |
| [T3 authoritative loop](tasks/T3-authoritative-loop.md) | Patch.server.luau only | AfterT1; can parallelT2/T5; no-loss full loop, duplicate/security/save checks |
| [T4 world assembly](tasks/T4-world-assembly.md) | giant/scene/SliceScene.luau; assets/slice-world/** | AfterT2 approved asset handoff; parallelT3/T5; exact layout/runtime contracts, no primitive art |
| [T5 client feel/UI](tasks/T5-client-feel-ui.md) | Patch.client.luau only | AfterT1, final visual test afterT2/T4; parallelT2/T3/T4; both HUDs +six-beat reveal |
| [T6 integration/acceptance](tasks/T6-integration-acceptance.md) | sync.project.json; SmokeTest/econ-sim/combat-check/compile-check/ScytheLab; fixes in Patch scripts/config only after owners finish | AfterT2–T5; build, real routes, shots, independent scores>=8, Zion checkpoint |

No two workers write the same file; T1 exclusively owns config until handoff, T2 asset catalog immutable before T4, T4 writes a different world package, T6 takes integration ownership only after all workers stop. Rojo is script source of truth. Archive obsolete builders/installers outside active assembly; Feed.server/Giant.client/GiantConfig are already excluded by sync.project.json and stay excluded.

## Owner questions (maximum three)

1. Keep all three concept stall shells with Sell/Upgrades closed, or require Bible's one visible stall? Draft keeps shells; only Shop functions.
2. Should the concept King chip say “King later” in this slice, or should one genuine 5:00 nest-refill clock use that corner? Draft uses truthful “King later” with no fake countdown; either choice needs an acknowledged HUD deviation, boss waits.
3. Must the full south-spawn hub hit the 8/15/20/26-second storyboard exactly, or are Bible <=30s reward/<=120s earner gates acceptable while measuring travel? Draft keeps full geometry and treats storyboard as aspiration; no speed/teleport cheat.

Lessons: When config appends overrides, test the returned table because initial gate/rarity entries can be stale. When timed storyboards span large scenes, measure the route because art timestamps don't prove travel. When an automated test grants funds or teleports, keep its proof separate because it cannot establish onboarding pace.

## Defaults chosen by Claude (2026-10-11, Zion can override)
- Q1: keep three stall shells; Shop works; Sell and Upgrades show 'Unlocks later', no prompt.
- Q2: the one clock is a real nest-refill timer (Bible law 8), shown in the top-right chip; King timer returns when the King fight ships.
- Q3: accept Bible timing limits (first reward < 30 s, first earner < 2 min), measured in a real playthrough; storyboard timings are a guide.

