# Art V2 build specification — Steal a Treasure
2026-10-18 · Roll Up the Vault + hideout · 2D and specifications only

**Build decision: cream routes, teal modular walls, gold physical toys, one unmistakable cyan getaway.** Build one complete Roll moment before multiplying content. Owner-reported, Zion at 18:44: “For the new style I think it can be more defined if that will help the creation actually make a good playable game now”.

This document supersedes Art V2's illustrative room/ball/guardian sizes where they conflict with the first playable. All new numbers below are authored construction targets, not tested performance or measurements of generated images. Gameplay numbers and existing coordinates are inspected source facts. No 3D asset generation, place edits, build invocation, Studio Play, publishing or uploads are part of this pass. Zion owns runtime testing.

## 1. Evidence and reference bar
Read: treasure/ART-V2.md, original art-v2/BOARD.jpg and CRITIC.md; HEIST-GAME.md; HEISTS-FIRST-PLAYABLE.md; Scene, Config, Game, Contracts and Heists.client in slice-v2/heists; local C:/dev/codex-lab/refs/ROBLOX-HIT-GAME-BIBLE.md; aspects REFERENCES/HOWTO notes for map, models, UI, VFX, lobby and Halloween where present. There is no CHECKLIST-named file in the aspects inventory; the Bible's checklists apply only where the heist brief agrees. The exact Keystone Roblox Process Playbook remains UNKNOWN: checked active-work and the local sources; use the owner's supplied real-art/core-moment/reference-arena rules. Do not import the Bible's old short-loop, passive income, shop or monetization recipe into this heist.

| Best selected benchmark, from local gameplay evidence | What it does well | This kit's corresponding decision / gap |
|---|---|---|
| Pet Simulator 99, videos/pet-sim-99-frames/f_012s.png | Bright pale floor, repeated toy architecture, legible stations | One ball-and-chair heist sign, open center, edge trophies. Fewer stations; no purchased systems. |
| Steal an Egg, videos/sae-new-frames/h_1034.jpg, aspects/map + models | Oversized guardian, broad readable route and state silhouette | Two thief heights, absurd brick moustache, dial cap, long hip key; red locked lane and cyan extraction. One raster frame cannot prove pursuit or steering. |
| Grow a Garden, Bible visual sections | Exceptional possession visible among ordinary items | Actual attached objects and saved best-haul heap, not decorative fake earnings. |
| Existing Art V2 HUD, 07-hud.png | Navy/cyan pills, cream haul tray, strong toy icons | Keep hierarchy; shrink tray and label the palm SHOVE. Phone safe-area usability UNKNOWN. |

“Best” means the chosen local benchmark, not a verified current chart position. The old hub 7.8 and guardian 7.6 are prior AI judgments. Fresh blind scores belong in defined/CRITIC.md; never promote the target >=8 into an observed result.

## 2. Common construction contract
- Unit: 1 ch = 5 studs, measured from floor to top of a reference thief. Coordinates are world X/Y/Z; sizes below are width X × height Y × depth Z, including visible trim. Art pivots are bottom-center; moving art has a separate root-relative pivot.
- Grid: architecture 2 studs, repeated wall/floor face modules 8 studs; props 0.25 stud; faces 0.125 stud. Never snap or move a gameplay root to satisfy this grid.
- All six Part surfaces Smooth. No studs, checkerboard noise, world outlines, fine filigree, PBR texture sets, transparent gems or reflective metal. SmoothPlastic is intentional even for “stone” and gold; Reflectance=0.
- E0 = square Part edges, no extra bevel geometry (floor, walls, trims). E1 = 0.125-stud single-segment chamfer on small hero objects. E2 = 0.25-stud single-segment chamfer on large hero objects. Cylinder rims have no extra torus unless named. Never bevel collision geometry. Parts may remain square when their silhouette already reads; chamfers require an original/reused MeshPart, not dozens of sliver Parts or runtime unions.
- P = Roblox Parts (blocks, cylinders, wedges, balls). M = MeshPart from an inspected CC0 kit or original deterministic mesh. G = future generate_mesh candidate ONLY; none is required and none is generated in this pass. Every G has a P fallback. Normalize bounds/pivot/material and inspect triangle counts before use; reject realism, baked lighting, extra objects and thin ornaments.
- Counts below are maximum visible BaseParts per instance, including MeshParts. Invisible contract roots are counted separately. Static decoration: Anchored=true; CanCollide/CanTouch/CanQuery=false. Moving visual art must add no physical mass or collisions. Do not remove physics roots, change collision groups or make the room physically decorative.
- Base palette: cream #FFF1D1, teal #167D9A, navy #182B49, gold #FFD34E, coral #FF665E, cyan #48DFFF, grass #62B04E, sky #33BEF7. Secondary only: skin #FFC58F; goblet silver #B8CDD9; floor seam #E8D8B8; white UI #FFFFFF. Each material slot has exactly one hex. Generated images approximate swatches; numeric colors here win.
- Mesh budgets: small prop <=600 triangles; crown/key/hat <=900 each; shell <=2,000; Baron <=4,000 total. Flat atlas at most 512² for character details; no more than six unique world 512² textures per scene. Prefer untextured material slots.
- Asset models live in a future ArtKit library, presentation copies in Heists.Art. Never put Models, decoration folders or extra BaseParts directly in Heists.Loot: Game.init treats EVERY direct child as a gameplay pickup.

## 3. Strict reusable kit
Sizes are final bounds, not source import scales. All rows use SmoothPlastic unless explicitly Neon. A reused mesh must fit the stated count, color and silhouette; otherwise use the listed Parts recipe.

### Architecture and route pieces
| Asset name | Bounds studs | Class / max parts | Exact material/colors | Edge / recipe / reuse |
|---|---|---|---|---|
| FloorTile08 | 8 × 0.1 × 8 | P / 1 | SmoothPlastic #FFF1D1 | E0; render top at Y=0.03, no lip/collision. Prefer one tiled floor face texture over 450 separate vault tiles. Grid seams #E8D8B8, 0.03 stud visual width. |
| WallTile08 | 8 × 8 × 0.5 | P / 1 | SmoothPlastic #167D9A | E0; overlay inside existing wall bounds, three repeated courses + 1-stud top cap to reach 25; no loose brick face. |
| WallCorner | 2 × 25 × 2 | P / 1 | SmoothPlastic #FFF1D1 | E0; outside clear routes. Plain corner post, no projecting base. |
| WallCap08 | 8 × 1 × 3 | P / 1 | SmoothPlastic #FFF1D1 | E0; top perimeter only, no raised floor strips. |
| WallBand08 | 8 × 0.5 × 0.15 | P / 1 | SmoothPlastic #FFD34E | E0; height 18 or above, at most one band per wall. |
| Pillar25 | 3 × 25 × 3 | P / 3 | SmoothPlastic #FFF1D1 shaft/cap, #167D9A base | E0; flush into wall, no foot wider than 3; 16-stud spacing. No pillar in either gap. Cave column candidate K1 only if remodeled to these bounds. |
| WindowBay | 12 × 10 × 1 | P / 4 | SmoothPlastic #FFF1D1 | E0; frame only, no glass; visual clerestory bottom Y=12. Keep original solid perimeter collider behind it. |
| BreachJamb | 2 × 22 × 3 | P / 1 each | SmoothPlastic #FFF1D1 | E0; faces lie OUTSIDE x=202..224. Never reduce the aperture. |
| BreachLintel | 26 × 2 × 3 | P / 1 | SmoothPlastic #FFF1D1 | E0; underside Y=22; 22-stud clear opening. Visual only; no lower arch curve. |
| CoverSkin | 12 × 7 × 16 | P / 3 | SmoothPlastic #167D9A sides, #FFF1D1 top, #182B49 bottom | E0; exact same outer envelope as CoverA/B, no plinth overhang. Preserve cover collision/blockcast. |
| Banner | 3 × 8 × 0.125 | P / 3 | SmoothPlastic #167D9A cloth, #FFD34E broad border/emblem | E0; rectangle + wedge bottom; one stacked-ingot silhouette. No simulated cloth. |
| WallLamp | 1.5 × 3 × 1 | P / 4 | SmoothPlastic #182B49 bracket, #FFD34E cap; Neon #FFD34E lens | E0; lens <=0.6×1.2 face. PointLight recipe in §6. |
| LootPlinth | 4 × 2 × 4 | P / 2 | SmoothPlastic #167D9A base, #FFF1D1 top | E0; static piles only, perimeter band; never make extra collectible lookalikes in the playable loot field. |
| GetawayArch | 28 × 24 × 2 | P / 5 | SmoothPlastic #167D9A body, Neon #48DFFF inner marker | E0; 22 wide ×22 high clear rectangular aperture, posts outside x=291..313; underside Y=22. Sign centered above, no collision. |
| RouteArrow | 3 × 0.02 × 4 | P / 2 | SmoothPlastic #48DFFF | E0; flat arrow, at most three near southeast exit; not a competing trail across all loot. |
| GuardianLaneSkin | 9 × 0.15 × 30 | P / existing root | SmoothPlastic #FF665E, Transparency=0.35 during Tell | E0; reads existing GuardianTell CFrame and visibility. No glow, particles, curved targeting arc or shortened timing. |

### Gold toys and collectible silhouettes
The visible loose item must fit its EXISTING gameplay root cube so pickup radius does not lie. Rotate the art inside that envelope; do not resize Config.Kinds to match an illustration. Loose hat alone has the existing 6×1.5×6 presentation at the guardian; attached hat uses the 3-stud envelope.

| Asset name | Bounds studs | Class / max parts | Exact material/colors | Edge / assembly / reuse |
|---|---|---|---|---|
| Coin | 1 × 1 × 0.25 (inside 1³) | P / 2 | SmoothPlastic #FFD34E face, #E8B632 rim | E0; two flat cylinders, upright while loose; no embossed text. |
| Goblet | 1.25 × 1.5 × 1.25 | P / 4 | SmoothPlastic #B8CDD9 cup/stem, #48DFFF square inset | E1 optional; cup cylinder, short stem, broad foot, one square inset. Solid cup, no transparent liquid. |
| Chair | 2.25 × 2.5 × 2.25 | P / 8 | SmoothPlastic #FF665E seat/back, #FFD34E frame | E1; seat, tall back, four stout legs, two arms. All legs >=0.25 thick. No quilt tufting. |
| Safe | 3 × 3 × 3 | P / 5 | SmoothPlastic #182B49 box, #B8CDD9 door, #FFD34E dial | E1; box, front plate, dial and two hinges. Large dial silhouette; no tiny combination numbers. |
| Crown | 3 × 3 × 3 | P / 8 or M / 2 | SmoothPlastic #FFD34E, #48DFFF one inset | E1; broad band + four wedge points + inset + two caps. Original mesh <=900 tris optional. G candidate only if wedge fallback is rejected visually; no kit match found. |
| BaronsHatLoose | 6 × 1.5 × 6 | P / 4 | SmoothPlastic #182B49 cap, #167D9A band, #FFD34E round dial | E1; collectible cap distinct from guard root. Never duplicate a permanently visible cap after it has been stolen. |
| BaronsHatAttached | 3 × 0.75 × 3 | P / 4 | SmoothPlastic #182B49 / #167D9A / #FFD34E | Uniform 0.5 scale of loose hat, same dial and orientation. |
| GoldIngot | 1.5 × 0.6 × 0.8 | P / 1 or M / 1 | SmoothPlastic #FFD34E | E0 block acceptable; E1 original chamfer optional. Decoration only, not extra pickup kinds. |
| GoldPileSmall | 4 × 2 × 4 | P / 8 | SmoothPlastic #FFD34E | E0; 5+3 ingots, one reusable silhouette, no scattered dust coins. |
| TrophyHeap | diameter 2..12, on existing 12×1×12 pad | P / <=12 | SmoothPlastic #FFD34E, #FF665E one chair accent | Existing best-haul root preserves radius clamp(1+trophy/15,1,6). Shell + <=8 ingots + tiny chair; purely represents saved trophy, never awards loot. |
| GoldBallShell | diameter 4..16 | P / 1 | SmoothPlastic #FFD34E, Reflectance=0 | Native Ball is the physics body; no duplicate collider. Optional M visual shell <=2k tris only, bounds identical. No generate_mesh needed for a sphere. |
| AttachedToyPresentation | <=19.8 diameter including decoration at max growth | P/M / <=6 hero toys +12 coin faces | Same prop palette as above | Six HERO silhouettes max, not six owned items. Remaining logical attachments persist and count. Cull their visuals only. Each selected visual must stay within radius 9.9 from ball center, in EVERY rotation. See §5. |
| PickupSpark | 0.25..0.75 | P or particle quad / <=6 transient quads | #FFD34E, LightEmission=0.4 | Flat four-point star, <=0.35s. No full-screen flash. |
| RollSweep | 0.05 thick, arc <=ball diameter | client quad / <=2 | #FFF1D1, Transparency>=0.6 | Below equator, <=0.25s, no continuous dust cloud or opaque halo. |

### Hideout and shared dressing
| Asset name | Bounds studs | Class / max parts | Exact material/colors | Edge / recipe / reuse |
|---|---|---|---|---|
| HideoutFacade | 20 × 14 × 12 | P / 7 | SmoothPlastic #167D9A walls, #FFF1D1 lintel, #182B49 rim | E0; open front, flat roof, thieves' workshop rather than castle. Reference vault proxy remains 14×10×12 at (-32,5,-14). |
| VaultDoor | diameter 10 × depth1.5 | P / 8 or M / <=3 | SmoothPlastic #182B49 plate/rim, #FFD34E dial/hinges | E2; broad 12-sided disk mesh optional, two hinges, chunky cross dial; no tiny bolts. Door opens OUT of walking space; static decorative, never locks banked progress. |
| VaultDisplayPlinth | 3 × 3 × 3 | P / 2 | SmoothPlastic #FFF1D1 top, #167D9A base | E0; three maximum inside facade. |
| HeistBoardFace | 18 × 10 × 2 | P / 5 | SmoothPlastic #FFF1D1 face, #167D9A rim, #182B49 posts | E0; preserve root center (0,6,-16) and StartHeist prompt. Billboard/surface image shows actual rolling action, not a throne icon. |
| BoardAwning | 20 × 2 × 4 | P / 6 | SmoothPlastic #FF665E / #FFF1D1 alternating stripes | E0; chunky flat sloped top, no scallop geometry required. |
| BoardBallSign | 8 × 8 × 8 ball + 3×3.3×3 chair | P / 9 | SmoothPlastic #FFD34E ball, #FF665E chair, #182B49 mask emblem via flat image | E0/E1; center above board, rigid silhouette. Two white arcs are sign graphics, not constant VFX. |
| ActivationPad | diameter6 × height0.1 | P / 2 | SmoothPlastic #167D9A rim, Neon #48DFFF face | E0; fixed mark at (0,0.05,-12), no teleport logic, one pad only. |
| HaulBoardFrame | 18 × 10 × 2 | P / 3 | SmoothPlastic #167D9A rim, #FFF1D1 face, #182B49 type | E0; preserve HaulBoard root (32,5,-16) and Sign.Text. Show server ranks only; empty rows stay blank. |
| PlayerVaultPad | 12 × 1 × 12 | P / existing root+0 art parts | SmoothPlastic #167D9A | E0; keep Game.makeVault slot formula and owned label. No fixed decor in dynamic slot zone. |
| TreeChunk | 6 × 15 × 6 | P / 4 or M / <=2 | SmoothPlastic #62B04E crown, #88613F trunk | E0 or source facets; K2/K3 candidates. Canopy outside main approach; no leaf noise. |
| BushChunk | 4 × 3 × 4 | P / 2 or M /1 | SmoothPlastic #62B04E | E0; K4 candidate; planted at edges, no collision. |
| RockChunk | 3 × 2 × 3 | P / 2 or M /1 | SmoothPlastic #8CA1AE | E0/source facets; K5. Hideout edges only. |
| StorageCrate | 3 × 3 × 3 | P / 5 or M /1 | SmoothPlastic #88613F wood, #182B49 straps | E0; K6. One edge cluster, no tiny plank grain. |
| StorageBarrel | 2 × 3 × 2 | P / 3 or M /2 | SmoothPlastic #88613F body, #182B49 hoops | E0/source facets; K7. Optional, omit before adding clutter. |
| StorageChest | 3 × 2.5 × 2 | P / 5 or M /2 | SmoothPlastic #FF665E body, #FFD34E rim | E1/source facets; K8. Decorative only, no loot-box mechanic or prompt. |
| HideoutNameSign | 12 × 2 × 0.25 | P /1 + SurfaceGui | SmoothPlastic #FFF1D1 plate, UI #182B49 | E0; YOUR VAULT / BEST HAULS, same UI type system. |

### CC0 candidates actually present in assets/kits2
Use local files, not new downloads or accounts. Bounds must be normalized to table targets. Candidates are NOT adopted/imported by this pass; asset IDs in staging are null/UNKNOWN.

| Key | Exact path relative to assets/kits2 | Inspected manifest count / use |
|---|---|---|
| K1 | cave/kenney_mini-dungeon__column__cave.fbx | Candidate only: shape must be simplified; custom Parts pillar is safer for exact clearance. |
| K2 | meadow/kenney_nature-kit__tree_oak__meadow.fbx | 2 MeshParts; broad foliage/trunk split. |
| K3 | meadow/kenney_nature-kit__tree_pineTallA__meadow.fbx | 2 MeshParts; alternative to K2, not a second tree language. |
| K4 | meadow/kenney_nature-kit__plant_bush__meadow.fbx | 1 MeshPart; edge bush. |
| K5 | meadow/kenney_nature-kit__stone_largeA__meadow.fbx | 1 MeshPart; edge rock. |
| K6 | meadow/kenney_survival-kit__box-large__meadow.fbx | 1 MeshPart; crate. |
| K7 | meadow/kenney_mini-dungeon__barrel__meadow.fbx | 2 MeshParts /148 triangles; barrel. |
| K8 | meadow/kenney_mini-dungeon__chest__meadow.fbx | 2 MeshParts /284 triangles; chest. |

Local LICENSE-quaternius.txt and LICENSE-kenney-survival.txt identify CC0. Kenney confirms [Mini Dungeon](https://kenney.nl/assets/mini-dungeon) and [Nature Kit](https://kenney.nl/assets/nature-kit) are CC0. Preserve local notices/source ledger even though attribution is optional. No extracted trademarked reference assets. The local Quaternius licence is for Stylized Nature MegaKit FREE; do not substitute a paid pack or assume it licenses another download.

The kits2 exporter preserves source material slots and embeds flat palette PNGs. Do not simply set Color on an imported textured mesh: its existing TextureID can retain meadow/cave color. Clear the flat palette texture or replace its per-slot albedo with the exact target hex, preserve separate trunk/leaves, then inspect the import. Existing KitLibrary is a reusable loader candidate; do not mount its island scene, old palettes or unknown IDs wholesale. Reuse primitive geometry where recoloring/import would cost more than the shape warrants.

## 4. Characters: exact construction
**Baron Bumble = 10 studs /2 ch; reference thief =5 studs /1 ch.** This replaces the older 1.8-ch drawing target to match the existing 8×10×8 Guardian gameplay envelope. Do not resize that root or player avatars. Character art bounds, without pose lean: 6.4 wide ×10 high ×4.8 deep; all fits the existing guardian width/depth. Root remains centered at Y=5 and moves under Game.moveGuard.

| Piece | Exact size X/Y/Z; floor-based vertical band | Parts ceiling / colors |
|---|---|---|
| Boots ×2 | 1.6×0.65×2.4; Y0..0.65 | 2, navy #182B49 |
| Legs ×2 | 1.6×1.65×2; Y0.65..2.3 | 2, navy #182B49 |
| Torso | 4.8×3.3×2.8; Y2.3..5.6 | 1, teal #167D9A |
| Upper sleeves ×2 | 0.8×2×2.4; Y3.6..5.6; outer shoulder span6.4 | 2, teal #167D9A, never navy |
| Lower hands ×2 | 0.8×1.3×2; Y2.3..3.6 | 2, skin #FFC58F |
| Head | 3.6×2.7×3; Y5.6..8.3, no neck | 1, skin #FFC58F |
| Ears ×2 | 0.4×0.8×0.5 | 2, skin #FFC58F |
| Moustache halves ×2 | 2.4×1×0.65; total width4.8 at Y5.8..6.8 | 2, cream #FFF1D1; two straight cuboids, no curls |
| Nose | 0.8³, center Y6.8, proud of face | 1, coral #FF665E |
| Eyes ×2 | 0.5×0.6×0.05, front plane, center Y7.3 | 2, navy #182B49; lids via face atlas |
| Brows ×2 | 1.1×0.35×0.12 | 2, cream #FFF1D1 |
| Belt + buckle | belt4.8×0.45×2.85, buckle0.8×0.6×0.15 | 2, navy #182B49 / gold #FFD34E |
| Cap top, band, brim | aggregate5.6×1.7×4; Y8.3..10 | 3, navy #182B49 / teal #167D9A |
| Cap safe-dial badge | diameter1.1 ×0.12 deep, front only | 1, gold #FFD34E; six navy #182B49 dial marks in atlas |
| Left sleeve patch | 0.55×0.8×0.05 | 1, coral #FF665E; anatomical LEFT only |
| Waistcoat buttons | four diameter0.25×0.08, 2 columns ×2 rows | 4, gold #FFD34E |
| Right hip key | aggregate1.4×3.5×0.3; top Y3.9, bottomY0.4; centerX=+2.8 facing local -Z | <=6, gold #FFD34E; one polygonal ring mesh + shaft +2 teeth + link; simplify to <=6 |
| Invisible presentation root | reuse Guardian binding; no new physical body | <=1 |
Total maximum37 BaseParts including optional art root, <=4k triangles. FOUR buttons are canonical across all selected sheets; supersede the first generation's six-button target. An original chamfer mesh may merge each same-color body piece without changing dimensions. No generate_mesh is needed; if later used for cap/moustache, it must replace pieces within these budgets, not introduce a sculpted character.

Facing convention: local forward -Z, anatomical right +X, anatomical left -X. Front drawing: key viewer-left, patch viewer-right. Back drawing reverses their screen sides. Right-side view must show key, not left-sleeve patch. The collectible hat replaces the visual cap while loose on his head; once stolen, show bald/flat head, not a second unstealable hat. Art reads the original baron:hat state.

Reference thief bounds: 3 wide ×5 high ×2 deep; boots0..0.5, legs0.5..2, torso2..3.5, head3.5..4.6, beanie4.6..5. Torso2×1.5×1, head1.5×1.1×1.25, two 0.5-wide block arms and legs. <=16 Parts, black/cream stripes via a flat atlas, navy #182B49 trousers/beanie, skin #FFC58F. This is a scale mannequin/costume reference, not authorization to rescale real avatars or change Humanoid movement.

State animation is cosmetic and driven by Guardian Phase attributes: Sleep closed lids +two cyan Zs, Chase short steps, Tell planted feet and backwards lean <=8°, Charge forward lean<=15°, Recover crouched/head-shake. Visuals never delay the 1.2s tell, 0.65s charge or 2.5s recovery. Red lane is the authoritative locked direction, not a homing VFX arrow. During Charge only, a client presentation guide may retain that locked 9×30 footprint as two coral edge lines and three white chevrons on transparent floor; it signals a committed attack, never safety. This is a new cosmetic guide, not the existing GuardianTell root (which is visible red only during Tell). Capture the Tell CFrame, never retarget it after lock, remove at Recover; no force, timing or targeting changes. Guide budget <=8 noncolliding Parts/quads, SmoothPlastic #FF665E borders/#FFFFFF chevrons, Y=0.18, no bloom.

## 5. Layout, clearance and composition

Capacity caveat from inspected source: zero-based owned-vault slots8/9 are at X=-8/+8,Z24, so their12-stud pads overlap the desired18-stud central approach. Later rows can also extend beyond the hideout floor. The open-center picture is therefore a six-pad composition target, not an occupancy guarantee. Do not change max players, pad slot formula or floor silently; resolve capacity/layout as a separate gameplay decision before scaling the hideout.

Hat binding caveat: source guardStep places the mounted loose hat ROOT at Guardian.Position+(0,6,0), Y11 at spawn. The specified visual cap occupies Y8.3..10. Preserve the root and pickup contract; use a Guardian-relative visual offset while the exact source mounted branch (Loose and no settleUntil) is true. Mirror that branch with a read-only presentation flag. After pickup/spill follow the item root, uniformly scaling the cap into the loose1.5-height or attached0.75-height envelope. The visual pickup offset needs Zion's later check; no gameplay root moves in this art pass.

Keep the inspected Scene coordinate system: north = -Z, east = +X, floor topY=0.

| Space / preserved root | Exact inspected bounds or coordinate | Art constraint |
|---|---|---|
| HideoutFloor |110×2×100 at (0,-1,0), X -55..55, Z -50..50 | Main approach x=-9..9, z=-10..28 stays empty. Spawn (0,0.5,22); return (0,4,12). |
| HeistBoard / Vault / HaulBoard | (0,6,-16) /(-32,5,-14)/(32,5,-16) | Keep roots, prompts and Sign.Text descendants; art centers on them. |
| Dynamic owned pads | X=-40+(slot%6)*16; Z=40-floor(slot/6)*16; 12×1×12 | Do not pre-fill the slots with plants/stalls. Six-across rows must retain signs and trophy space. Higher rows can extend beyond floor at high occupancy in current code: capacity/floor expansion is a separate gameplay/layout issue, not silently fixed by art. |
| VaultFloor |160×2×180 at (240,-1,0), X160..320,Z-90..90 | Preserve floor physics, open-roof room,25-stud perimeter. No smaller concept room. |
| Perimeter |West/East centeredX158.5/321.5, 3 thick; North/South Z-91.5/91.5 | No new collision windows/doors or outer escape; decorative windows do not punch collider holes. |
| CoverA / CoverB |12×7×16 at(210,3.5,3)/(270,3.5,-30) | Cover silhouettes retain exact physical bounds and charge-blocking behavior. |
| Partition |DoorLeft X160..202; DoorRight X224..290; Z45.5..48.5 | Existing collision height16. Visual dressing can rise to22; lintel underside22. |
| Central breach |clear X202..224 =22 studs | Ball center at max radius must stay X210..216 physically; with 19.8 visual envelope X211.9..214.1. No trim in gap; do not show a rounded arch narrowing the sides. |
| East bypass |clear X290..320 =30 studs | Ball center X298..312 physically; 19.8 visual envelope X299.9..310.1. Preserve ALL30, including around turn. |
| Extraction foyer |south of partition, Z48.5..90 | Keep center corridor from breach to (302,80) open; turn staging area X284..320,Z52..88, no plinths. |
| Entry / ExitPortal |Entry(214,0.16,70); exit22×20×2 at(302,10,80), noncolliding | Exit root is an extraction trigger marker, NOT a door collider. Keep radius13 bank test and escort radius ball.radius+16. Art aperture22 wide×22 high aligns with it. |
| Guardian |8×10×8 at(240,5,-60) | Art fits root; preserve walls/cover blockcast list and movement limits. |
| Loot |120 roots on10×12 source rows, plus baron:hat | Preserve every LootId, Kind, root size, origin and cover adjustment. No reducing gameplay to14 piles. |

**Capped ball:** Config.StartRadius=2, MaxRadius=8 => physical diameter4..16, not Art V2's earlier 3.25..7.5 concept. Collision-free attachments still need a visible clearance rule: all displayed vertices remain within radius9.9. In Game.resize an attachment center is radius+kind.size×0.3 from ball center; for size3 at cap this is8.9, leaving only1 stud of radial depth. Sink/rotate/scale the selected presentation to fit that radial shell; do not put a full3-stud cube tangential corner outside9.9. Use projected bounding-sphere checks over rotations, not just the loose prop's bounding box. When growing, enforce max visual radius=ball.radius+1.9; at small size prefer coin faces and delay large hero silhouettes until their real pickup tier. Never shrink physics, delete owned items or change collection threshold to achieve this.

Loose pickup budget is121 maximum roots, not a decoration density. 120/28,800×100=0.417 ordinary pickup roots per100 square studs, with about10-stud column/12-stud row spacing as source facts. Decorative edge clusters: vault<=14 =>0.049 per100 square studs; hideout<=8 =>0.073 per100 square studs on11,000. A cluster is one plinth/pile or plant/crate grouping, not one individual ingot. At most one cluster in any100-square-stud edge patch. Architecture repetition does not count as a cluster, but still counts toward parts/triangles.

Routes stay empty of decoration; loose gameplay loot can be swept. Main ball lanes target>=22 clear width; bypass30; hideout approach18, side pedestrian approaches>=8. No canopy, lamp, banner, door leaf or key projection belowY22 over ball routes. Full ball requires no shrinking or mandatory lost haul. For a 90° turn keep the east foyer clear and use the9.9-stud visible-envelope swept path, not a narrow centerline.

Sightlines: from spawn see the heist board face and ball/chair sign without another station overlapping. From breach/bypass approach see GETAWAY at(302,80), its header atY22..24; no second bright portal. Wall loot plinths remain secondary gold silhouettes. Camera target FOV70, ordinary third-person; illustration camera about15 high,24 behind, down25°. A future max-ball zoom must keep the next aperture and full width visible; do not lock an attractive concept camera that hides steering. No permanent UI in central x=.25..75,y=.25..75.

Performance targets, unverified: vault<=55k visible triangles and<=1,200 visible art BaseParts incl loose toy components; hideout<=45k and<=600; character<=4k; <=4 visible local lights; <=40 transient particles total. Six hero attachments +12 coin faces per visible ball, with distance LOD. These are ceilings, not evidence of phone FPS. No baseplate made of hundreds of collision tiles.

## 6. Exact daytime lighting and post
Set these values once in a future lighting module; remove competing correction stacks. They are authored defaults requiring Zion's later visual/device check. Current Roblox documents [LightingStyle](https://create.roblox.com/docs/environment/lighting); use Soft, not a guessed legacy Technology override.

| Object | Exact values |
|---|---|
| Lighting | LightingStyle=Soft; PrioritizeLightingQuality=false; ClockTime=13.5; GeographicLatitude=35; Brightness=2; ExposureCompensation=-0.15; Ambient=#C8D2DF; OutdoorAmbient=#B9D1DF; ColorShift_Top=#FFE3A8; ColorShift_Bottom=#000000; EnvironmentDiffuseScale=0.3; EnvironmentSpecularScale=0.15; GlobalShadows=true; ShadowSoftness=0.3 (stored value; ignored by Soft lighting); FogStart=1000; FogEnd=10000; FogColor=#C8E9FF. |
| Atmosphere | Density=0.08; Offset=0; Color=#D9EEFF; Decay=#B9D1DF; Glare=0; Haze=0. No fog wall. Atmosphere supersedes distance-fog appearance. |
| ColorCorrectionEffect | Enabled=true; Brightness=0; Contrast=0.05; Saturation=0.08; TintColor=#FFFFFF. |
| BloomEffect strict preset | Enabled=false; Intensity=0; Size=12; Threshold=2.5. Selective authored glow below is the required replacement. |
| Optional global bloom candidate, never default | Enabled=true; Intensity=0.12; Size=12; Threshold=2.5. May be accepted only if later capture shows cream, eyes, UI and sky do not halo. |
| SunRaysEffect / DepthOfFieldEffect / BlurEffect | Enabled=false; no action-view blur or sun shafts. A menu may dim via UI only. |
| WallLamp PointLight | Color=#FFD34E; Brightness=0.6; Range=10; Shadows=false. Lamp lens is the only lamp Neon surface. <=4 enabled/visible lamps around camera. |
| Sky | Preserve an existing licensed/default sky; target cyan #33BEF7 appearance, SunAngularSize=11, MoonAngularSize=0, StarCount=0, CelestialBodiesShown=true. Skybox texture IDs UNKNOWN; do not invent IDs or import a random scripted sky. No cycling time script. |

**Bloom-only-on-neon/gold is an art requirement, not a capability of standard BloomEffect.** [Roblox Bloom](https://create.roblox.com/docs/environment/post-processing-effects) applies a global brightness threshold, not an object/tag whitelist. Therefore the strict preset disables global bloom. Author localized 0.15-stud gold/cyan edge halos only for tagged Neon lamp lenses, activation pad, getaway edge and a brief gold pickup flash: transparent sprite/quad, matching #FFD34E or #48DFFF, alpha<=0.2, <=1.1× emitter size, LightEmission=0.4, no glare on cream. These preserve the requested selective glow appearance without claiming a selective engine effect. UI never blooms. Keep halo art out of the red charge lane and loot silhouettes. If this selective layer is unavailable, omit glow; never turn on low-threshold global bloom as a shortcut.

Light comes from open roof and clerestory-shaped wall dressing, with ambient fill keeping the guardian face readable. Wall lamps are warm accents, not the room's primary illumination. No black corners, mirror gold, night or heavy haze. This updates the local HOWTO's older high-bloom/purple Halloween preset for a cream/gold daytime heist.

## 7. UI kit matching the concept HUD
Reference resolution844×390 landscape AFTER device/core safe insets. Use ScreenGui.ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets for controls. Scale sizes by safeHeight/390, cap text scale1.35; minimum text14 px and interactive target56 px (44 absolute fallback). Enlarge layout/reflow instead of shrinking below minima. Preserve native movement/jump/core UI. Use UI constraints and anchors, not a fixed1080p canvas.

Type: Enum.Font.FredokaOne for titles, actions and haul count; Enum.Font.GothamBold for values/timer/body. White #FFFFFF on navy pills uses navy #182B49 UIStroke1.5px; navy text on cream has no text stroke. Panel stroke2px navy, cyan accent rim2px. No emoji substitute for chair/cup/crown/palm icons; one authored1024² atlas, max two UI atlases. No world outlines.

| Element | Position/size in safe viewport or pixels at390h | Type / shape / colors |
|---|---|---|
| Goal |x.32..68,y.04..13 |FredokaOne18; navy #182B49 pill, cyan #48DFFF2px rim, white label ROLL TO THE EXIT. One objective only. |
| Timer |right aligned at(.98,.04),112×36 |GothamBold22, navy pill/cyan rim, white clock icon + m:ss from HeistSeconds. Coral #FF665E digits under10s; no giant center countdown. |
| Haul tray |left(.02,.55), width=min(.22w,186px),height74 |Cream #FFF1D1, navy2px stroke,10px corner radius; three icons24px; FredokaOne18 count, GothamBold16 value. End above y.75. |
| Bank home pill |left(.02,.55), max186×44 |Cream/navy, GothamBold18; VAULT $actual bank. During Run, small bank line in haul tray, no second currency or rate. |
| Shove action |center(.89,.61), diameter64; reflow if overlaps native controls |Cyan #48DFFF outer ring, teal #167D9A disc, navy2px outer stroke; white palm28px and SHOVE14px. UICorner=0.5 scale. Label Q / X on desktop/controller; single button uses existing HeistShove action. |
| Shove cooldown |same circle |2 seconds from server acceptance; radial navy overlay alpha.45; never disable input locally longer than server cooldown. No invented energy bar. |
| Feedback |center(.5,.80), max.48w×24 |GothamBold14 white/navy1.5px; one line2s, latest event wins; clear of sticks/jump. |
| Banked payout |only after BankPulse, center(.5,.42),max.56w×62 |FredokaOne28 gold #FFD34E/navy2px; +$actual BANKED, up to3s, original0.35s Back pop. Never fire from extraction contact alone. |
| Heist modal |center, width=min(.82w,700),height=.76h |Cream #FFF1D1, teal #167D9A4px rim,14px radius; header FredokaOne24 navy; close coral #FF665E56² with white X24. Hide other optional HUD. |
| Heist card |one full-width Roll card in first playable |Rounded10px, navy name20, image height.42 modal; green #52D83B button56h, white FredokaOne20, navy1.5px text stroke; navy2px border,4px dark teal #12647B pressed base. Label BREAK IN. |
| Future second card |only when King's Bed exists |Same card; original two-card concept is visual vocabulary, not a promise Bed is playable. No live PLAY button for absent content. |

Button states: hover brighten via white overlay0.08; pressed move content down2px/base becomes2px; disabled fill#8CA1AE, navy type, no pulsing. Default green action only for valid start; no shop/Robux buttons. Keyboard/controller selection uses a3px cyan focus ring OUTSIDE button. Press animation<=0.12s.

Data contracts: keep Action remote Shove/Move, HeistShove CAS binding Q/ButtonX,10Hz movement intent and all existing player attributes. Timer splits out of Goal visually, not into a new clock. Current source has Haul (value) but no item-count attribute; future builder may add a read-only server HaulItems mirror from #ball.items, with no economy change. Until then omit “24 ITEMS”; do not invent a count or equate dollars with items. Show at most three icon samples of actually carried kinds. Board values/leaderboard mock numbers in images are not defaults; initial state is actual $0/empty rows. The selected hideout's YOUR HAUL HERE is an aspirational preview, not saved ownership; gameplay-owned trophy art appears only from saved data. Its central alcove dresses the existing StartHeist prompt; pressing the prompt starts play, walking through the illustrated door is not a new trigger or collision change.

## 8. Numbered conversion plan — later work, two Codex lanes
This is a handoff plan, not authority to edit the place in this art-only task.

1. Freeze baseline: hash slice-v2/heists sources and rbxl; inventory root names/CFrames/attributes,121 LootIds, Config values and save mounts. Re-read Game/Contracts before implementation. Keep original greybox as a separate recoverable artifact.
2. Build ONE representative kit slice in source only: floor/wall/pillar, cover, breach jamb/lintel, one ball with coin/chair, one Baron. Produce an offline construction render/contact sheet against this board before stamping the room. Zion/Claude judge the single moment before mass rollout.
3. **Lane A — architecture/kit:** owns future ArtKit.luau, ArtScene.luau and static art placement data. Author primitives, normalize chosen CC0 meshes, recolor slots, document licence/IDs, preserve collider envelopes and both clear routes. No Game/Config/Rules/SaveDomain/client edits. Deliver asset manifest with bounds, parts, triangles, pivot and material slots.
4. **Lane B — moving art/UI:** owns future ArtPresentation.client.luau and Heists.client.luau. Bind guardian poses to Phase, ChargeDirection, TelegraphStarted and ImpactDue; follow ball/item roots, show only six selected hero attachments +12 coin faces per ball, style HUD and board. No collisions, forces, rewards, cooldown or save changes. Stubs consume stable names/LootIds from step1 so this proceeds alongside A.
5. **Integrator only** touches Game.luau/build.luau/Scene.luau mounting and any read-only presentation attributes. Do not let both lanes patch these files. Keep authoritative roots as existing direct children of Heists; new static art stays under Heists.Art. Existing HeistCollision=true parts remain the ONLY blockcast/raycast wall list. Preserve HeistBoard.StartHeist and every Sign.Text used by Game.
6. Bind presentation without replacing pickup Parts with Models: Game.init stores fixture.part and Game.resize welds that Part. Use client-only anchored visual copies under Art following existing root CFrames; locally hide grey roots with LocalTransparencyModifier where appropriate. Keep true roots/welds. Do not put art welds under item roots: resetRoom destroys their direct WeldConstraints, and resize destroys item.weld. A read-only ArtState/ArtOwner mirror may be set in reset/collect/spill/finishBank so presentation doesn't guess ownership from appearance.
7. Respect lifecycle: root Transparency is reset to0 in resetRoom and set1 on bank; client visuals must mirror that hide/reset state and survive spill/reattach. Attachments follow the ball through growth/rotation, loose objects return to fixture origins, failed banking stays frozen, timeout spills real cargo. Cap presentation to radius ball.radius+1.9. Do not pool away a logical item, change item.angle, rewrite collection distance or hide spilled loose loot for LOD. Stolen baron hat disappears from guardian presentation.
8. Dress full room only after the slice review: preserve160×180 floor, CoverA/B, DoorLeft/Right, Entry, ExitPortal, Guardian, GuardianTell, Eye1/Eye2 and all pickup roots. The old eyes may be locally hidden; their named roots remain for Game movement updates. Keep physical shell/network owner nil, CustomPhysicalProperties(.7,.7,.15,1,1), HeistBalls/HeistPlayers groups and root sizes. Use static parametric placements, no runtime unions.
9. Offline acceptance: run existing check.luau after authorized implementation; require unchanged contract behavior, source compile and binary roundtrip when builder is eventually invoked. Add meaningful static envelope/inventory checks:22/30 clear apertures, no art in swept route,16 physical diameter/19.8 visible envelope,121 unique IDs, no decorative collision/query parts, scene budget totals and skinning lifecycle bindings. Report checks as offline, never runtime passes.
10. Zion-only validation: default camera, full ball through breach AND bypass, corner/shove/brake recovery, readable1.2s locked lane, guardian hits cover, hat can be taken, friends spill/steal back, save failure freezes/retries same haul, real bank pulse/trophy, timeout/rejoin behavior, phone/controller safe areas. Runtime/FPS/fun remain UNKNOWN until his evidence. No Codex Studio Play. If steering fails, fix core feel before Bed or more art.

Protected gameplay values: run240s; radius2..8; growthvolume.22; speed27; PushRange8; shove cooldown2; tell1.2/charge.65/recover2.5; guardian speed10/charge45; retries3; Coin100, Goblet500, Chair1500, Safe5000, Crown12000, Hat25000; original volume and radius thresholds. Keep ownership/conservation, spill max3 on bump, settling/steal-back, bank receipt idempotency, acknowledgement before visible award, separate StealTreasure_Heists_v1 namespace, Mock mode, core Profiles/MockStore/UIStyle/ProfileStore mounts and licence. Cosmetic presentation cannot bypass any of these.

## 9. Review artifacts, limits and lessons
Final independent visual scores: hub7.7, guardian states8.1, buildable vault7.8, turnaround7.8. Only the state sheet reaches8. Three remain below the target and are UNRESOLVED, not approved art. Two broad focused redraw rounds and one state button-only correction are preserved; see the critic's actual category arithmetic. Remaining priorities are stronger hideout identity/preview readability, maximum-haul route/silhouette read and less crowded construction communication. Do not stamp out more content from these three sheets as if the visual bar passed.

Four built-in image-generation outputs: defined/01-hub-hideout.png;02-guardian-states.png;03-roll-up-vault-buildable.png;04-baron-turnaround.png. Prompts in defined/PROMPTS.md; montage in defined/BOARD.jpg; named-reference comparisons in defined/REFERENCE-COMPARE.jpg; one independent critic in defined/CRITIC.md. The critic remains blind to author prompts/spec while scoring. Numerical callouts in generated art are illustrative, not measured clearance proof; this written spec controls the later build.

The buildable vault image is a visual kit example, not a reconstructed screenshot of Scene coordinates. No exact-layout, guardian AI, physical response or engine-lighting claim follows from it. Mock count/value combinations and rows are illustrative. Image discrepancies and review outcomes are recorded in the critic/QA; do not silently use them as assembly instructions.

- When a toy grows, specify its collision AND visible envelope, because noncolliding attachments can still look wedged in a door.
- When art must replace a working greybox, keep logical roots and IDs separate from presentation, because collection, welds, spills and saves already depend on them.
- When a rendering effect cannot mask objects, use a local authored effect, because a brightness threshold is not a selective bloom switch.

