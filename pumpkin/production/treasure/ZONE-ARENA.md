# Steal a Treasure — zone loop arena

2026-10-18, revised for Zion's 14:50 shipping addition. **Recommend A: Crown Road. First playable zones 1–3; v1 zones 1–5; zones 6–15 only after the loop proves worth repeating.** Studded Blocks structure plus sparse Toy Meadow props is the easiest consistent direction.

[ONE recommendation board](zone-arena/BOARD.jpg) · [phone summary](ZONE-ARENA-SUMMARY.md). Design and 2D concepts only: no gameplay code, 3D assets, place edits, Studio Play, commits or publication.

CHECKED = inspected source/documents, not runtime proof. OWNER-REPORTED = supplied statements. **Every proposed rule, quantity, success target, cost, score, image and predicted outcome is INFERRED and UNTESTED**, including tables. UNKNOWN = actual fun, difficulty, retention, phone cost and live save behavior. Concepts are generated pictures, not screenshots of a build.

## Owner direction

OWNER-REPORTED, Zion, 2026-10-18, verbatim:
> "If meadow is easiest for you to make then go with that, I think there all styles we should learn but for the loop I dont think its that good yet, well need a lot of maps if that all so looks at other games maybe we have levels 1-15 on one map and we do the zones. that changes that we previously thought of".

OWNER-REPORTED, 14:40:
> "We also want it do actually be difficult, for a player".

OWNER-REPORTED, 14:50:
> "Maybe we should also simply the idea to get a game out already."

This supersedes HEIST-ARENA's multi-island starting scope and the earlier draft of this arena. Loop A supplied steal → outsmart → escape → earning pet, but did not establish repeatable skill enough to justify many maps. Fifteen colours alone repeat that problem. Keep the verb, introduce one readable demand per zone, and prove one complete loop before mass production.
## What was checked and reused

CHECKED supplied historical studies: [Hit Game Bible](C:/dev/codex-lab/refs/ROBLOX-HIT-GAME-BIBLE.md), [Steal an Egg](C:/dev/codex-lab/refs/BIBLE-STEAL-AN-EGG.md), [Steal a Brainrot](C:/dev/codex-lab/refs/BIBLE-STEAL-A-BRAINROT.md), [Plants vs Brainrots](C:/dev/codex-lab/refs/BIBLE-PLANTS-VS-BRAINROTS.md), [Grow a Garden](C:/dev/codex-lab/refs/BIBLE-GROW-A-GARDEN.md), [Pet Sim99](C:/dev/codex-lab/refs/BIBLE-PET-SIM-99.md), [Game Theory Checklist](C:/dev/codex-lab/refs/GAME-THEORY-CHECKLIST.md), [TikTok lessons](C:/dev/codex-lab/refs/TIKTOK-ROBLOX-LESSONS.md), map [reference study](C:/dev/codex-lab/refs/aspects/map/REFERENCES.md) and [how-to](C:/dev/codex-lab/refs/aspects/map/HOWTO.md). These are supplied footage notes, not fresh firsthand observations or current popularity rankings. Also checked [HEIST](HEIST-ARENA.md), [STYLE](STYLE-ARENA.md), [RAID](RAID-ARENA.md), [PACIFIST](PACIFIST-ARENA.md), [GDD](GDD.md), [section registry](sections/SECTIONS.md) and the current source below. Older GDD proposals are not implemented facts.

| CHECKED current source | Design consequence, INFERRED |
|---|---|
| [Greybox server](../slice-v2/prototype/Greybox.server.luau), [config](../slice-v2/prototype/GreyboxConfig.luau) | One `rules.active`, global escape attributes and one nest; 2s Steal,60s cargo clock,16/13.5 walk/carry speeds. Need item/zone registries and actor-scoped UI, not fifteen copies of this singleton. Server currently rewrites speed, so boots need integration. |
| [Domain](../prototype/core/Domain.luau), [Service](../prototype/core/Service.luau), [Config](../prototype/core/Config.luau) | Pets, pending secure/place/open, bank/collect and rarity rates1/4/8 exist. MaxPets8 blocks further entry/opening. Saved zone yield, boots purchases, bank-based access and confirmed replacement are new; no permit shop or archive in v1. Preserve first-common override. |
| [Profiles](../prototype/core/Profiles.luau) | Serial mutations and save acknowledgment/uncertainty exist. Zone clear and pet award need same acknowledged transaction; retry cannot duplicate. Migration must precede validation. |
| [KeeperAttacks](../slice-v2/prototype/KeeperAttacks.luau), [Arena](../slice-v2/prototype/Arena.luau) | Locked attacks/cover/navigation foundations exist; current dash tell0.5s and slam landing0.8s are shorter than new readability contract. Section leashes/target filters/global scheduler are new. |
| [RaidSlice](../prototype/meadow-v4/RaidSlice.luau), [Outsmart](../prototype/meadow-v4/Outsmart.luau), [Gameplay](../prototype/meadow-v4/Gameplay.luau) | Existing two authored raid forks,1.5s tell/1.2s client warning, Jump-triggered scripted vault, bait wall and bell are donors. Native-jump geometry is proposed, not existing behavior. Coordinates/drop floor/protected areas belong to old Meadow; transform motifs into new local sockets, never transplant stale collision. |
| [Cinematic movement](CINEMATIC-MOVE.md), Greybox client/banner adapters | Reuse presentation and objective banner. Cinematic movement is not proof physical dash exists. Camera stays controlled during danger, reveal skippable. |
| [Dependency ledger](../prototype/core/Packages/README.md) and actual license texts | ProfileStore Apache-2.0; RbxUtil utilities MIT. Reuse already-vendored code, retain notices. No external kit, purchase or asset copying needed; comparison art conveys no reuse rights. |

Exact Keystone Roblox Process Playbook text was not found in the accessible active-work directory, and no Keystone connector is available: UNKNOWN, not claimed read. Applied supplied real-art/core-moment/reference rules and the installed Roblox production skill. Existing local skill/source is the foundation; no scratch clone or new dependency required.

## Hit-game map study — side by side

All five games are **OWNER-NAMED references in this request**; their selection as a particular design bar and every transfer below is INFERRED. We do not pretend all five have fifteen difficulty zones.

| Game and evidence | One-map structure / size / population | Progression gate and rising difficulty/reward | Home, aspiration, clip moment; use here |
|---|---|---|---|
| **Steal an Egg — primary layout bar.** Map study §§1–3 corrects the older Bible. |12 lane sections/13 named areas, final section split Angels/Demons;120–140-stud lane width,30-stud walls,160–200-stud sections,≈1,900–2,400 total lane, all footage estimates. Walled hub about2×lane width; about8 pens visible around rear/sides, not proof of exact server cap. | Speed upgrades/treadmill/trails support deeper guarded theft; better eggs/guards. Evidence conflict: old Bible records “not enough speed” toast; newer map study sees no closed door and calls speed a soft gate. Actual universal gate behavior UNKNOWN. Never erase that conflict. Rebirth not observed; no assumed timer-entry gate. | Raised thin pink line, pens behind it, floor+wall colours advance together; large final silhouettes. Guard wake→held egg→safe line is readable muted. Copy geography/readability, not doomscrolling/treadmill economy, traps or combat. Our48-stud sections are deliberately shorter than reference. |
| **Pet Simulator99 — area aspiration bar.** Bible §§2–3/9; official historical update linked below. | Many linked themed areas on a world, not15 separate places. Local late-account tour shows city/meadow/lava/castle/tech; exact section length and shared player cap UNKNOWN. Official Tech World update explicitly added25 areas and25 eggs. | Coins buy progress in genre; exact local area coin prices UNKNOWN. Rank gates upgrades; rebirth gates features/worlds. Official Tech World requires rebirth4+area99. Stronger breakables/rewards/team, not evidence of hard pacifist movement. | Spawn shop/egg hub and visible next-area goals; not personal pens. Better egg/area and huge-pet reveal supply aspiration. Borrow readable next gate and2–3s payoff; cut swarm combat, machine stack, second currency and required world travel. |
| **Steal a Brainrot — social/base-income bar.** Bible §§2–3/6/9. |One rectangular walled plaza, central straight carpet≈4 character widths;≥8 visible bases,4/side; source estimates base≈12×8 character heights. No numbered zone ladder or measured overall length; exact server cap UNKNOWN. |Buy progressively valuable walkers; later steal from exposed bases. Rebirth1 requires$1M+two specific characters and clears cash/characters; observed lock60→70s. Study payback≈2–3min, not our forecast. Risk comes from rivals/lock windows, not a farther biome. | Home faces shared supply and other earners. Rare walker→rival race→home income is a clip. Borrow visible rivalry and rate labels, remove slaps, home theft and destructive rebirth. |
| **Plants vs Brainrots — expandable lane bar.** Bible §§2–3/6. |Parallel personal plots; planting rows≈20–25 character widths long,≈5 unlock pads observed, not15 zones. Several players visible, exact server cap UNKNOWN. Home podium platform≈10×8 character widths at player's end. | Coin pads add slots/lanes ($100/$1,500/$5,000/$25,000 slots; $100k/$2.5m/$10m lanes in studies). Better seeds/enemies→better earners;≈$10m rebirth gates fuse. Combat stat escalation is not transferable as player difficulty. | Other gardens/large earners always visible; rare catch becomes a podium earner. Borrow one new capability/space at a time, income visibility and28s tutorial clarity; cut planting/shooting/fuse. |
| **Grow a Garden — persistent home/visual score bar.** Bible §§2–3/6/10. |About6 players in the footage, named plots in rows around open grass/shared seed+sell stalls. No numbered zones/level chain, no measured zone length. Walking shop/sell≈10–15s in compiled Bible. | Coins, stock and5min restock gate rare seeds, growing/regrowing plants compound value; no rebirth/XP observed. No mechanical danger ladder. | Home itself grows into aspiration, giant/gold fruit seen by others; collect huge gold fruit is clip. Borrow safe visible ownership and growing collection, not waiting as the difficulty or copied garden props. |

External primary-source spot checks on2026-10-18: [BIG Games Tech World post](https://www.biggames.io/post/pet-simulator-99-update-6) (dated2024-02-24) supports25 linked areas/eggs and rebirth4+area99 world gate; [BIG Games area index](https://db.biggames.io/wiki/areas) groups areas by progression/world. The [Steal an Egg Roblox listing](https://www.roblox.com/games/107778070777162/Steal-An-Egg) resolves but does not establish layout dimensions, population or current gameplay. Dimensions above come from supplied study estimates, never these listings. No live ranking claims.

**Compare to best before building:** Steal an Egg wins simple straight-line orientation; PS99 wins next-area aspiration; Grow a Garden wins visible owned progress. Our differentiator must be a learnable outsmart escape. A fifteen-colour lane alone loses to those references. Checklist's3–10× income/zone is a heuristic: choose2× for15 tiers pending economy tests, not an invented claim of compliance. Its early loss-free heuristic conflicts with Zion's hard-game direction: allow losing unbanked cargo, protect banked progress. TikTok lessons inform muted readability, not a guarantee of virality.


## Shared minimal core — applies to A, B and C

**Steal and escape.** Eight players share one map. Existing 2s Steal → visible Keeper tell → run/jump/bait around cover → cross home line before original60s → durable secure acknowledgement → place/open earning pet → collect Coins. One carry/player. Banked pets/Coins stay safe. Rivals race source and recover naturally dropped cargo; remove Bump acceptance/input and player collision blocking. No attacks or forced rival drops. Solo must still be hard.

Normal supply: one source item/zone, refill3s after resolution. **Accepted critic correction:** Z1 alone refills3s after pickup while older Z1 cargo remains out. One available source at a time, maximum8 unresolved Z1 cargo, one held/pending item per actor. Each cargo retains its own ID, roll, deadline and receipt; never replace an older active cargo globally. This NEW lifecycle work bounds supply cadence, not personal waiting/starvation. Eight-player onboarding is still a shipping gate. Later zones retain meaningful competition. No fake tutorial reward or second economy.

Walking/viewing is open; stealing in Z(n) requires one durable home bank from Z(n−1). No coin permits, rebirth gate, time gate or speed wall. The clear flag accompanies acknowledged bank receipt and original cargo-zone; recovery never changes yield. Cargo-zone Keeper follows its local section plus one adjacent section; foreign guardians ignore returning cargo. Assigned return raid sockets supply danger without15-way dogpiles. These target filters are new work.

**First10minutes: four taught systems:** movement/read tell/steal-escape; place/open pet; collect/buy boots; next zone after a bank. One banner, one contextual action and original actor-scoped cargo clock. No combat hotbar or new meter. Reuse cinematic running and sound, no forced danger camera; reveal skippable. Show next prize's earning floor and home direction.

**Boots v1:** baseline empty/carry16/13.5; rank2 18/15.5 for60Coins; rank3 20/17.5 for240. Ordered permanent purchases, integrated with server speed rewrite. These prices are tuning seeds, not measured pacing. Baseline must retain a viable learned route through1–5. Boots ease margin but cannot skip timing. Native jump over a low rail supplies vault-like movement without another button. Current raid vault is scripted interpolation: reuse route/cue lesson, not claim native physics already exists.

**Cut from v1:** dash button, decoy/shield shop, bell interaction, rebirth, mastery cards, archive UI, second currency, multiple islands/portals. Keep Outsmart wall-bait identity. Optional bell can return later, once/cargo with no timer refresh. Dash/decoy/shield are later investigations, never required for any zone. No attack-strength stat: stronger means route knowledge and bounded speed.

**Capacity integration is mandatory:** actual cap8, not64. Before a full-capacity run, reserve a selected old pet, showing its actual rate and the next reward floor/range. At Open, show both actual earning rates and require explicit confirmation before replacement. Decline preserves ownership and prevents run entry. Reservation does not remove pet. canEnter, secure AND open must support it; dialog at Open alone cannot work. On acknowledged Open, accrue existing earned bank, replace once, retain durable award receipt independently of current pets. Failure/save uncertainty never deletes old pet. Reconnect restores reservation or safely cancels before award; pending cargo protected. This intentional player-confirmed retirement avoids an archive system. Persist immutable award-zone/base-yield through restore/display/accrual; old pets keep original rates after migration.

**Reset:** no required rebirth or periodic world reset. After15, optional cosmetic best-time/mastery replay can preserve access/pets/Coins, only if voluntary-repeat evidence supports building it. Waiting and lost progress are not difficulty.

## Hard but fair — every design

Each threat gives shape/motion AND sound before commitment: minimum1.2s fully visible warning; raid1.5s; keep longer existing windups. Locked direction/landing, no aim snap, unseen spawn or late-stream damage before a full cue. Current dash0.5s, slam landing0.8s and general1s warning do NOT comply; retune required subset, omit unused attacks. Check earliest possible projectile contact, not just animation start.

One dangerous commitment per affected player INCLUDING collateral, plus recovery mercy; shared arbiter is NEW. Proposed ceilings8awake Keepers+4raid runners are not phone benchmarks. Serial squad passes stay in one cargo episode with full movement/recovery gaps; skip saturated deployment, never queue surprise attacks. Each zone uses one new demand and at most2learned demands. Later second Keeper is a handoff: first stops, second fully tells. No fifteen attacks stacked.

Every vault has low catch floor and timed walking bend. Bend avoids falling, not all skill. Starter movement must have reachable solutions; no invisible boundaries/death pits. Empty-handed staging previews whole next pattern. Proposed3s retry returns failed actor empty-handed to eligible local staging, never banks/teleports cargo. Carrying into staging drops item at legal danger-side socket before protection; same ID/roll/deadline. Reset/rejoin cannot refresh clock or reward. Failure loses provisional cargo/time, banked progress safe. Report queue/save/technical failures separately from skill failures.

## Fifteen-zone reward and difficulty ladder

**All success percentages are INFERRED targets, NOT telemetry.** Full Steal→durable home bank, conditional on first encountering an eligible zone after empty-handed preview. New=first attempt at that zone; practiced=five prior completions, recording total failed attempts too. Compare matched boots/loadout, then baseline/under-geared separately. Equal targets across layouts need separate tuning, not presumed equivalence. From7 onward new players should fail more often than succeed. These are not odds of a fresh account reaching15.

Common yield=zone base×existing rarity factor1/4/8 at provisional70/25/5 odds; first pet Common. Rates below are Common floor of an opened pet, never cargo income. Next base doubles; show current and next floor so failure is worth retrying. Earlier Epic can exceed later Common; do not promise every hatch improves income. Use approved Pup/Crow rig family/recolours, not15new rigs.

|Zone / stolen treasure / floor+wall palette|Common Coins/s|New / practiced|ONE new demand and fair response|Named difficulty reference, INFERRED transfer|
|---|---:|---:|---|---|
|1 Lime / golden acorn|1|90% /98%|Keeper wakes/aimed throw; broad cover, visible windup.|Steal an Egg guard wake/escape.|
|2 Mint / copper acorn|2|84% /96%|Faster pursuit introduces locked dash; read arrow, bait solid wall, cut aside.|Steal an Egg speed risk + current Outsmart.|
|3 Yellow / honey acorn|4|77% /93%|Runner pair commits one of two forks; full tell, take open side.|Huss Valley crossing/timing analogy + RaidSlice donor.|
|4 Peach / amber acorn|8|70% /90%|Three refuges become two; see gap, cross during recovery.|99 Nights safe-ring excursion analogy.|
|5 Leaf / royal acorn|16|62% /86%|Tighter low-rail landing; native jump or timed walking bend, low catch shelf.|Huss Valley movement analogy.|
|6 Cyan / geode|32|54% /82%|Narrower dash corridor; locked cue reveals cutback before commitment.|Evade movement/chase analogy; corridor ours.|
|7 Blue / azure geode|64|47% /78%|Second serial raid pass; two preview beats/full recovery gap.|Huss Valley repeated crossing analogy.|
|8 Violet / amethyst geode|128|40% /74%|Narrower landing; marked edge, catch shelf or timed broad bend.|PARKOUR Legacy mastery analogy, not copied physics.|
|9 Pink / rose geode|256|34% /70%|Longer aimed throw covers old refuge; visible final landing, switch cover during recovery.|Evade route-learning analogy; throw composition ours.|
|10 Indigo / prism geode|512|29% /66%|Deeper side bay exposes longer escape leg; preview gap/recovery cycle.|Steal an Egg deeper guarded return.|
|11 Cream / gold coffer|1,024|24% /62%|Third serial raid pass; three preview beats, never simultaneous damage lanes.|Huss Valley repeat timing analogy.|
|12 Coral / ruby coffer|2,048|20% /58%|Second Keeper handoff at marked boundary; first stops, second fully tells.|99 Nights escalation analogy; handoff NEW.|
|13 Sky / sapphire coffer|4,096|16% /54%|Alternating left/right raid closures; preview full order, learn safe commitment.|DOORS learn-warning analogy, not matching attack claim.|
|14 Orange / sun coffer|8,192|13% /50%|Cover ends earlier in visible recovery cycle; commit to next refuge at correct beat.|Evade route analogy; optional rival loose-loot contest from Steal a Brainrot.|
|15 Gold / crown coffer|16,384|10% /46%|Two-beat fork changes safe opening; preview both beats, reposition then commit.|Huss Valley timing + Steal an Egg final aspiration; composition NEW.|

No reflector/vent/moving-gate/seal scripts: late difficulty reuses aimed throw, dash, cover, jump and serial raid. Each new constraint must actually change a decision, not simply travel. Specifically inspect4/8/10/14; if players do not alter timing/route choice, the step fails the brief. Narrower opportunities come from placement/phase, never shorter invisible attacks.

Reference status: five comparison Bibles and Steal an Egg are OWNER-NAMED here. Huss Valley/99 Nights are additional supplied research games. Evade/PARKOUR Legacy/DOORS are INFERRED selections inherited from RAID-ARENA's listing study. [Evade listing](https://www.roblox.com/games/9872472334/Evade), [PARKOUR Legacy](https://www.roblox.com/games/445664957/PARKOUR-Legacy), [DOORS](https://www.roblox.com/games/6516141723/DOORS) support broad framing only. No gameplay played/watched here; exact equivalence UNKNOWN. Analogies never establish copied enemy mechanics.

## A / anonymous X — Crown Road — WINNER

One FLAT northbound lane120wide,15×48deep bands=720studs,30high side walls. Floor AND wall colour change together. No opaque internal cross walls. Alternating treasure bays INSIDE lane sides, local Keeper, centre clear for return/vista. Home240wide×192deep:8 existing64×48plots rotated to48wide×64deep, two rows of4 with64deep aisle. Four plots span192, leaving48total side margin; two64deep rows+64aisle=192. Gates/fences fit INSIDE envelope; actual clearance unverified.

```text
                     NORTH
               [crown above end wall]
               |15 gold coffer      |
               |14..11 toy citadel  |30high side walls
               |10..06 crystals     |48deep per band
               |05 low rail/vault   |120wide
               |04 less cover       |alternating side loot bays
               |03 two-fork raid    |no internal vista wall
               |02 dash bait        |
               |01 wake/acorn       |
      ===== thin pink safe lip + flush ramps =====
      [P1][P2][P3][P4]   pets at home
      ----- broad aisle / collect / boots ------
      [P5][P6][P7][P8]   SOUTH walled home
```

Crown silhouette above final wall visible from home; next prize/threat readable on approach, not all tiny far loot. V1 lane240studs+home; plainly closed end, no fake playable prompts6–15. Full-map concepts show future direction. No obligatory slope/staircase despite image drift.

**30s hook target:** take acorn, see farmer wake, dodge cover, cross home line; Z2 brings signature dash→cutback→wall stars. First earned Coin<120s target. **5min target:**2–4banks, pet income, one boots buy, Z3attempt/retry. All pace UNKNOWN. TikTok moment muted: held treasure→looming locked dash→last-second cut→stars→home/pet payoff. No posting authorized or virality claim.

Each bay uses15-row ladder/max3demands. Early one squad pair, Z7second serial pass, Z11third, Z12Keeper handoff. Select up to3return encounter sockets, no every-zone dogpile. Preview composition before Steal. Rivals race/recover loose items; solo difficulty independent of rivals. Same container/yield table, speed/practice/jump/bait progression, no mandatory reset.

Later boots ranks4–15 may continue toward empty51/carry41.5 with an explicit table based on actual earnings; v1 rank3=20/17.5 means do not blindly apply the old formula. Deepest nest≈696from home:51.6s at starter13.5;16.8s at later41.5 BEFORE dodges. Z5≈216/17.5=12.3s. Arithmetic is not proof60s fits hard route; shorten bands before adding travel systems. Starter15 not promised feasible; warning/gear recommendation visible, no invisible entry gate.

Reuse Keeper subset, Outsmart bait/stun, raid runner/lane cues, acknowledged saves/pet loop, banner/sound/cinematic running. Registry/yield/capacity/UI/speed/arbiter are actual integration. Old coordinate bounds/portal scripts are not reusable unchanged.

**SHIPPABLE CORE:** home+Z1–5; wake/throw, dash bait, single raid fork, reduced cover, native low rail/bypass; boots1–3, bank-based access, confirmed pet replacement. First acceptance Z1+home, first playable1–3. Later6–15 are compositions/crystal+gold kits; optional bell/dash/decoy/shield/mastery only after evidence. **Effort rank1, smallest viable core.** Blind pack's4–7builder-days was optimistic per engineer. Revised planning allowance **6–10 focused builder-days v1;12–18total for15**,6h/day including art/code/offline checks, excluding owner/runtime/device review, unmeasured/no promise. Re-estimate after one slice. Biggest risk: repetition/early queues plus authority refactor, not placing rectangles.

## B / anonymous Y — Switchback Courtyards

Three parallel60wide strips of five48deep bands, two U-turn courts.30outer walls, low internal dividers; home south, same8plots. Treasure on outer bays, Keeper local strip, raid fork visible from BOTH court approaches. Crown over gold strip; one next marker at turn. Dividers must prevent shortcuts while preserving default-camera cues.

```text
 [05] -> court -> [06] [15 crown]
 [04]            [07] [14]
 [03]            [08] [13]
 [02]            [09] [12]
 [01]            [10] -> court -> [11]
 ========== HOME P1..P8 / safe lip ==========
```

Order1→5north,6→10south,11→15north. V1 ONE strip only. **30s hook:** acorn/wake/escape home. **5min:** bank/boots/turn-side bait/raid fork. Same15treasures/yields/targets: Z2dash before corner,Z3court fork,Z4turn cover reduction,Z5inside-court vault;6–10narrow corner/double-pass/landing/cover-switch/outer bay;11–15triple court-pass/handoff/alternating lanes/early cover end/two-beat court exit. Every demand retained, never hidden by bend. Max3demands/common arbiter, foreign guards ignore return.

Same boots/practice/optional later pacifist tools; no-rebirth v1; rivals only race/recover; home earning safe. Reuse core/Keeper/raid/bait/pets/run/banner/sound; extra court transforms/camera/divider/drop checks. Full return≈936studs (≈240more than A),22.6s at future41.5 before dodges. Aspiration less direct; no new overlook camera in v1.

**SHIPPABLE CORE:** one5-zone strip+home, exactly A's limited systems; two strips/turns later, tools/reset deferred. Cut portals/tunnels/verticality. Old Meadow cover/fork/vault motifs become1–5, not ten entire sections. **Effort rank2:**7–12days v1;15–23total for15, same unmeasured assumptions. Biggest risk: initially almost A, then paying camera/navigation cost without a better loop. Hard turns may feel like camera failure.

## C / anonymous Z — Crown Rings

Central safe home, three48wide rings of5sequential arc zones, four radial return spokes,30high outer wall/low inner boundaries. Hub radius≥150 to fit8plots/aisles, so ring-centre radii210/270/330; earlier100/160/220would not fit. Each72degree arc≈264/339/415studs, MUCH longer than A's48band. Author short encounter bays within arcs; remaining empty travel is a cost, not free space.

```text
      (11—12—13—14—15) outer gold
        (06—07—08—09—10) crystal
          (01—02—03—04—05) meadow
                [HOME P1..P8]
            four radial escape spokes
```

Schematic only, actual order circles hub. Loot at arc centre, local Keeper; squad controls spoke with visible timed alternative. **30s hook:** inner acorn→central home. **5min:** bank/open/boots, choose differently timed spoke. Crown towers show outer aspiration; next marker essential, weakest1–15order.

Same15containers/rates/targets: Z1inner wake,Z2arc dash,Z3spoke fork,Z4fewer spoke refuges,Z5spoke vault,Z6narrow arc,Z7double pass,Z8landing shelf,Z9cover-switch,Z10outer bay,Z11triple pass,Z12ring handoff,Z13alternating spoke lanes,Z14early cover end,Z15two-beat spoke fork. Max3demands, no neighbouring raid collateral. Home sole bank beyond safe lip. Radial return≈210–400studs; local timing must stay hard as speed improves. Same tools/practice, no-rebirth v1, rivals race/recover.

Reuse core/Keeper/raid/bait/pets/run/banner/sound; new polar region/drop math, spoke transforms/collision/crossing arbitration/guidance. **SHIPPABLE CORE:** inner5-zone ring+home; outer rings/tools later. Cut portals/rebirth/vertical islands/old underside. Meadow motifs become arc bays. **Effort rank3:**10–16days v1;19–28total for15, unmeasured/excludes acceptance. Biggest risk oversized footprint/confusing order/shared-spoke unfairness. Reject for near-term shipping despite route-choice appeal.

## Easiest visual style and old Meadow disposition

|Style|Build effort, INFERRED|Phone cost, UNKNOWN until equal-density measurement|Decision|
|---|---|---|---|
|Studded Blocks|Fastest slab floors/walls, block/wedge cover/rail, three chapter kits. Use native/surface studs, never geometry studs by the thousand.|Fewer unique assets may help; patterns can alias. AI/pets/transparent tells may dominate. No guaranteed FPS win.|Structural winner for15consistent zones.|
|Toy Meadow|Existing STYLE-ARENA visual winner. Sphere trees/simple toy forms are cheap;15sculpted organic gardens take longer. Existing approved assets reduce effort.|Smooth spheres not inherently expensive. Prop density, shadows, unique meshes and transparency matter more.|Small existing-inspired tree/acorn/farmer kit for1–5.|

**Choose Studded Blocks structure with sparse Toy Meadow props.** This changes STYLE-ARENA's full-island choice for the repeated-lane problem, not a claim Toy looks worse. Compare A beside Steal an Egg lane clarity and PS99 toy forms: A has not proved equivalent visual quality or replay appeal. Meadow1–5, recoloured block crystals6–10, cream/gold blocks/crown11–15. One Keeper rig/costume recolours, three treasure-shell families, approved pet rigs. No dense foliage, realistic cliff chips, local decorative lights, waterfalls or15bespoke biomes. Proposed ceiling6cosmetic clusters/zone is a starting hypothesis, not profiling. Measure8players×8pets plus cargo/guards/runners on actual chosen phone.

Ten-section Meadow becomes motifs: S1arrival→home/Z1; S2west bait→Z2; S7camp/nest→Z1–3; S5ridge fork→Z3 and low railZ5; S3tunnel CUT v1, later optional visible route only; S4ravine→Z5low catch floor; S6spiral/shelf→flatZ8landing; S8underside/roots/waterfalls CUT; S9plots→home art; S10portal row→one boots/next-zone display. Reuse approved assets/rights, not reference-game models or stale whole-map coordinates. Existing licenses stay with vendored source. No new dependency/clone needed.

## Three blind critics and decision

Three separate agents saw only anonymous [SHIPPING-BLIND-PACK](zone-arena/SHIPPING-BLIND-PACK.md), no recommendation/other reviews; engineer also inspected assigned current code. Simulated AI lenses, not real children, professional interviews or tests. Mapping disclosed after reports: X=A,Y=B,Z=C. All scores **INFERRED**. Difficulty means hard/fair/learnable, not punishment.

|Critic|A overall / difficulty / simplicity|B overall / difficulty / simplicity|C overall / difficulty / simplicity|Choice|
|---|---|---|---|---|
|[TikTok-age player](zone-arena/SHIPPING-CRITIC-PLAYER.md)|8 /7 /9|7 /7 /7|6 /6 /4|A: clear hook; first pickup availability risk.|
|[Retention designer](zone-arena/SHIPPING-CRITIC-RETENTION.md)|8 /7 /8|7 /7 /6|6 /6 /4|A: validate8-player opening first.|
|[Engineer on code](zone-arena/SHIPPING-CRITIC-ENGINEER.md)|8 /7 /8|6 /7 /6|4 /6 /3|A: stored yields/capacity/registry critical.|
|Mean, arithmetic only|8.00 /7.00 /8.33|6.67 /7.00 /6.33|5.33 /6.00 /3.67|**A unanimous; candidate, no launch pass.**|

Adopted AFTER scores: bounded Z1refill-on-pickup, one-zone acceptance gate, no optional bell v1, stored yields and full entry/secure/open replacement, native-jump distinction. Not re-scored: critics did not validate corrections. Engineer challenged optimistic estimates; revised ranges are still unmeasured. Historical CRITIC/DIFFICULTY-CRITIC files predate shipping cut and are not final verdicts.

## Numbered future build plan — design only today

1. **One shared owner freezes contract:** zone/item/actor IDs, transforms/drop sockets, home-only secure, original60s, warning/mercy budget, no attacks, Z1supply exception. Save migration persists immutable earning basis, bank flags, boots and receipts, preserving legacy pets/Coins. Define capacity reservation through entry/secure/open/reconnect before adding content.
2. **Two Codex lanes PARALLEL, Z1+home only:** A owns data-only layout/socket/palette and final-direction art/geometry contracts. B owns isolated registry/economy/UI/speed/threat adapters and meaningful offline fixtures. One owner alone edits/composes Domain/Profiles/Greybox authority. No simultaneous serialized place edits. Validate concurrent Z1cargo and a second zone-shaped fixture even before dressingZ2. Do not clone singleton runtimes or create another economy.
3. **Integrate complete loop, then first playableZ1–3:** prove saved yield/accrual, acknowledged secure/place/open/collect, boots buy, capacity replacement and cargo conservation. A addsZ2bait/Z3fork configurations while B verifies tell/readiness/mercy/access; one owner integrates. Checks: simultaneous steal/rival recovery, duplicate/replayed awards, uncertain saves/disconnect, cap reservation/replacement, old earnings, one-carry, deadline tie, checkpoint exploit and collateral overlap. Static/offline pass is not proof playable/fun.
4. **Zion/Claude review before scaling:** ONE matched default-camera view versus Steal an Egg/PS99. Zion performs actual game testing; AI never starts Studio Play. Observe solo+8-player pickup denials, first durable bank/first Coin, seen warning, failure causes, retry duration, voluntary repeat and selected-phone camera/performance. Separate technical/queue failures. If supply/authority cannot support8, reduce opening population or redesign supply before readiness claims. If1–3dull/unfair, fix/reduce before more zones.
5. **v1 addsZ4–5 only, A/B PARALLEL:** A fits reduced-cover and low rail/catch shelf/timed bend from existing motifs. B validates baseline/boots-cap routes and concurrent cargo/raid caps. One owner composes. No bell/archive/dash/decoy/shield/new map to finish first10minutes. Re-estimate actual effort after step3. Shipping scope1–5 is not publication authorization.
6. **Then4–15 in small batches:**4–5already proven. A develops representativeZ8crystal/shelf, B composes narrower dash/serial raids; integrate6–10 only after representative acceptance. A then developsZ15gold/crown/fork; B composes12handoff/13alternating closure/15two-beat raid, then11–15. Same small vocabulary. Explicit high-rank boots/economy table requires observed earnings. Geometry and isolated rule work parallel; one owner handles integration. No mass dressing before Zion checks one.
7. **Acceptance before release decision:** source/offline correctness, owner solo/multiplayer skill attempts, default phone camera, actual phone profiling and voluntary repeat. Record novice/practiced/gear cohorts with counts and uncertainty;90/40/10%at1/8/15 are hypotheses. If practice does not help, widen readable opportunity/recovery; if upgrades trivialize, cap traversal while retaining phase choices. Shorten empty returns/ship fewer meaningful zones before adding systems. Publishing needs separate explicit authorization.

## Concepts and evidence limits

Built-in image generation, no API/paid fallback. Selected five: [whole map](zone-arena/01-overview-v2.png), [home down zones](zone-arena/02-home.png), [zone1](zone-arena/03-zone-01-v2.png), [zone8](zone-arena/04-zone-08-v2.png), [zone15](zone-arena/05-zone-15-v2.png). [BOARD.jpg](zone-arena/BOARD.jpg) combines these with small external labels/ONE recommendation. [PROMPTS.md](zone-arena/PROMPTS.md) records prompts/provenance. Individual concepts have no annotations. Overview aerial by request; four others approximate trailing player camera/daylight, not engine-verified FOV. Requested repo folder used; Desktop outside writable scope.

Visual QA: images remain approximate. Do not measure studs from pixels, copy background terrain/unrelated pictured pets, build geometry studs, infer attack behavior from stills or build stepped terrain from perspective. Home pens only behind safe lip; flat lane and text geometry govern. Overview's dense off-map scenery is excluded from build. Z8frame looks north toward crown while escape is south behind camera; it illustrates the obstacle, not a completed return. Z15same northward orientation. Pictures depict full15-zone future, not v1available content. No actual difficulty/phone/retention evidence here.

## Lessons

- When shipping a zone ladder, prove one zone on final cargo/save authority first, because singleton state and rarity-only yield cannot scale by copying art.
- When difficulty rises, add a readable choice and short retry, because longer walking alone creates no skill.
- When everyone needs zone1, bound shared supply first, because a solo hook can become an eight-player queue.


