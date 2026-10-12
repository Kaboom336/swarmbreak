# JUDGE3 — independent visual audit

**Verdict: no screen earns 8/10.** The strongest screens reach 6.5. The weakest look like decorated greyboxes. Clear lettering and polished reward icons cannot carry empty environments or an idle scene labelled as combat.

## Evidence and calibration

- **Checked:** all 15 top-level `v3/*.png` excluding `.v3a` and `-sbs`, individually at original encoded size. Also inspected native-size side-by-side boards: unchanged concept on the left, matching refs3 frames in the middle, matching refs2 frames on the right. Temporary inspection boards were assembled without resampling; no source artwork was changed.
- Read [REFS3.md](../refs3/REFS3.md), [REFS2.md](../refs2/REFS2.md), the local project playbook and the Roblox production skill. Visually inspected all 31 matching refs3 JPEGs and the three refs2 JPEGs for each corresponding screen family. Reused families are identified below.
- **Owner-reported:** earlier 8/10 judgements were rejected as generous. Those judgements are not acceptance evidence. I did not author or revise these images; their prior score files were not used to set these scores.
- **Observed** means something visible in the supplied image. Scores and proposed fixes are **judge inference**, not measured player click rates. Current chart positions, actual runtime fidelity, animation timing, phone usability and game performance are **UNKNOWN** in this audit. The supplied reference ledger gives source dates; this audit does not independently certify today's top 20.
- **10:** indistinguishable from a top-20 Roblox screenshot today. **8:** believable popular-game screenshot that earns a click. **6:** visibly AI/amateur concept, generic or baseplate-heavy. **4:** programmer art. Half points distinguish borderline cases; they do not imply measurement precision.
- Scores assess the **whole supplied screen**, including scene, UI, action and consistency. Storyboards/strips are assessed through their depicted gameplay views; their format is not itself a penalty. Merely copying a simpler refs2 game's floor does not satisfy the stronger refs3 bar. Conversely, studs, flat colours and sparse scenes are not automatically wrong: the missing ingredient is authored hierarchy, surface contrast and convincing activity.

## Score table

| Screen | Score / 10 | Main reason it misses 8 |
|---|---:|---|
| first-5-min.png | 5.0 | Legible sequence inside a generic empty field; state continuity breaks |
| guards-and-king.png | 5.0 | Static throne display, bare arena, no visible guards |
| guards-and-king-fight.png | 4.5 | No fight visible; join prompt and skip text contradict active health |
| hatch-reveal-mass.png | 6.5 | Reward spectacle works, but repeated models/states look staged |
| hatch-reveal.png | 6.0 | Modal substitutes for a physical emergence moment |
| hub-perspective.png | 6.0 | Readable landmarks; repetitive plots and unfinished surroundings |
| hud-desktop.png | 5.0 | Readable icons over a baseplate; active tool/target state absent |
| hud-phone.png | 5.0 | Clear controls, weak context and poorly separated corner stack |
| panels-index.png | 6.5 | Coherent grid, generic shell and decorative rather than useful states |
| panels-shop-index.png | 6.5 | Strong card art, weak benefit/ownership/affordability hierarchy |
| pets.png | 6.5 | Appealing hero pets, catalogue staging and inconsistent HUD/data |
| scythes.png | 5.5 | Held blade reads; colour variants and display staging dominate |
| zone1-perspective.png | 4.5 | Bare corridor and repeated floor occupy the scene |
| zones-strip.png | 5.5 | Recognisable gates; woods/swamp remain recoloured corridors |
| zones-strip-2.png | 5.5 | Strong palettes, three copies of the same empty route |

## Per-screen gaps and exact drawing fixes

### hub-perspective.png — 6.0/10

**Best screen-fit benchmark:** BGSI Nightmare Town for layered plaza construction; Adopt Me for seasonal local lighting. Compared all `refs3/hub-base-*.jpg` and `refs2/hub-perspective-ref-{1,2,3}.jpg`.

1. **Ground remains a kit demonstration.** The grey path has paving, but surrounding neon-green stud sheets and identically fenced plots dominate the foreground. [BGSI autumn plaza](../refs3/hub-base-bgsi-2.jpg) distinguishes pavement, orange planted margins and raised fountain edges. **Draw:** keep the central paving; replace plot floors with dark soil and pumpkin vines, add a pale curb along the path, and give lawn margins grass clumps and scattered autumn leaves. Reserve studs for explicitly constructed objects.
2. **The skyline ends in a perimeter wall.** Repeated stepped grey cliffs with small green blocks do not create a town. [Nightmare Town](../refs3/hub-base-bgsi-1.jpg) layers crooked houses, roofs, webs and trees around its portal. **Draw:** place an offset crooked shop roof behind the left stall, a taller barn behind the right stalls, and a twisted tree canopy partly crossing one approach; break the continuous wall with planted banks and visible distant roofs.
3. **Prop placement is excessively regular.** Mirrored pens and evenly spaced lanterns make the image feel procedurally arranged. BGSI groups candy piles, display pads and architecture into different-sized clusters. **Draw:** preserve readable plot boundaries but put a wheelbarrow/crate/hay cluster beside the shop, a seed sack/vine/watering-can cluster beside home, and a bench/lantern/leaf cluster at the fountain. Vary height and orientation; leave the route clear.
4. **Lanterns add orange pixels, little mood.** Broad daylight gives shop, nests and throne the same visual exposure; [Adopt Me street](../refs3/hub-base-adopt-me-1.jpg) has bright warm windows beneath cooler shaded structures. **Draw:** cast a visible warm pool from shop windows and nest lanterns, shade the underside of roofs and trees, and put cooler shade behind the throne. Keep the playable route bright. Preserve the fountain and large destination signs; they already read.

### zone1-perspective.png — 4.5/10

**Best benchmark:** [Fisch shore](../refs3/zone-lane-fisch-1.jpg), with [Adopt Me crypt](../refs3/zone-lane-adopt-me-1.jpg) for dressed edges. Compared both refs3 lane frames and `refs2/zone1-perspective-ref-{1,2,3}.jpg`.

1. **It is visibly a baseplate corridor.** A uniform green stud plane stretches between uninterrupted tan walls. Fisch visibly changes sand, stone bank and wooden dock surfaces/elevations. **Draw:** a narrow packed-earth trail with irregular grassy edges, a shallow side ditch, and a low planted bank. Replace tan enclosure walls with alternating wooden fence, hedgerow and low earth berm sections.
2. **Three props stand in for an environment.** Windmill, scarecrow and rare-pumpkin plinth sit isolated in empty ground. The crypt has coffins, candles, bones, steps and webbed wall recesses grouped together. **Draw:** hay bales, sacks and leaning tools at the windmill; corn rows and crows around the scarecrow; vines, stones and two small lanterns around the rare nest. Make clusters, not a uniform scatter.
3. **The endpoint has no value hierarchy.** Blue sky shines through a small grey gate; both sides and destination are equally bright. The crypt frames a destination with architecture and lighting. **Draw:** a shaded tree canopy over the graveyard gate with warm lamps at its opening; layer tomb silhouettes behind it and a foreground fence corner to establish depth.
4. **The yellow stripe is stronger than the task.** The player runs empty-handed through unrelated orbiting white balls and a candy popup, without a selected pumpkin. Fisch places interaction cues at the tool/action. **Draw:** the starter scythe visibly gripped, one nearby pumpkin with a small target ring, a short candy pickup trail originating at its broken shell, and intermittent ground arrows on the earth path instead of an uninterrupted highway stripe.

### hud-desktop.png — 5.0/10

**Best benchmark:** [RIVALS PC HUD](../refs3/hud-pc-rivals-1.jpg) for hierarchy; [Fisch action bar](../refs3/hud-pc-fisch-1.jpg) for context. Compared all `refs3/hud-pc-*.jpg` and `refs2/hud-desktop-ref-{1,2,3}.jpg`.

1. **The world under the HUD is unfinished.** Stud floor, tall orange walls and repeated pumpkins occupy nearly the entire scene. BGSI places its HUD over a plaza with houses, raised displays and contrasting ground. **Draw:** use the authored meadow ground/edge clusters described above behind this exact HUD; retain open space immediately around the player.
2. **Instruction lacks target and action evidence.** “Smash a Pumpkin!” is large, but the avatar holds nothing and none of the pumpkins is selected. RIVALS visibly shows the held weapon; Fisch shows current interaction progress. **Draw:** put the selected scythe in hand, a compact ring around the nearest pumpkin, and a narrow hit/progress treatment directly above that target. Make the instruction smaller than the target's visual read.
3. **Hotbar selection is ambiguous.** Two large dark cards and numbers do not clearly identify the active slot. RIVALS separates tool identity, ammunition and secondary keys. **Draw:** one bright outline and small “Equipped” cue on slot 1, a quieter unselected slot 2, and a small mouse/action glyph beside the equipped tool. Use flat equal-size icon cards with consistent padding.
4. **Counters float without alignment structure.** The candy and capacity icons have different visual footprints and no bounded number field; the whole HUD is heavy outlined display type. [BGSI HUD](../refs3/hud-pc-bgsi-1.jpg) has clear currency capsules despite excessive overall clutter. **Draw:** two compact aligned capsules with fixed icon wells and left-aligned values; use quieter secondary labels. Preserve the small number of menu buttons; do not copy BGSI's icon/boost overload.

### hud-phone.png — 5.0/10

**Best benchmark:** RIVALS touch silhouettes and Adopt Me anchored interaction. Compared all three `refs3/hud-phone-*.jpg` and `refs2/hud-phone-ref-{1,2,3}.jpg`. Embedded-video resolution and actual thumb reach remain UNKNOWN.

1. **Touch controls merge into the lawn.** The green joystick and jump disc sit against nearly the same bright green floor; SMASH is conspicuously oversized relative to jump. [RIVALS touch frame](../refs3/hud-phone-rivals-1.jpg) uses solid white glyphs on dark discs. **Draw:** dark charcoal translucent discs with white glyphs, a restrained purple accent only on the contextual action, and consistent rim thickness. Keep one contextual action plus jump.
2. **Left-side information crowds the joystick.** Shop, Index, candy, capacity and the joystick form one vertical stack, with capacity immediately above the movement control. [Second RIVALS phone frame](../refs3/hud-phone-rivals-2.jpg) separates joystick and health/tool areas. **Draw:** move compact currency/capacity capsules into the upper-left safe area, leave a clear empty band above the joystick, and shrink Shop/Index to matching compact tiles below the counters.
3. **SMASH has no visibly eligible target.** The player holds a scythe, but no pumpkin has a target cue; the HOME arrows compete with the smash instruction. [Adopt Me portrait segment](../refs3/hud-phone-adopt-me-1.jpg) attaches its hand marker to an object. **Draw:** an anchored ring/hand cue on one nearby pumpkin, a short connector-free progress arc there, and HOME arrows only in the carrying state. Keep the action button spatially stable.
4. **Desktop cards were carried into the touch layout.** Numbered boxed hotbar tiles remain large and no selection is obvious; generic field geometry provides no reason to click. **Draw:** a narrow two-item strip with one selected underline, remove keyboard slot numerals from the phone version, and show the authored meadow with a clearly framed first target. Keep the thick, legible scythe glyph; that part works.

### panels-shop-index.png — 6.5/10

**Best benchmark:** [DOORS Pre-Run Shop](../refs3/shop-panel-doors-1.jpg) for decision clarity; [BGSI upgrades](../refs3/shop-panel-bgsi-1.jpg) for tier states. Compared both refs3 shop frames and `refs2/panels-shop-index-ref-{1,2,3}.jpg`.

1. **Rarity and price do not explain the purchase.** Three tools have names/costs, but only the detached Witch tooltip says “Power: 25.” DOORS places each item's practical benefit with its offer. **Draw:** one concise approved benefit line under each tool name and a small power comparison beside the selected Witch card. Use approved values; if unavailable, mark the design copy TBD rather than inventing power.
2. **Every offer looks buyable.** FREE, 9,000 and 25,000 all use the same green action, and the panel does not depict balance or ownership. DOORS shows a selected key and confirm cost; BGSI exposes tiers and costs. **Draw:** an explicit selected border on Witch, an “Owned” check for the starter tool in this depicted state, a balance capsule in the header, and a grey locked/unaffordable King button with its reason. Ensure the depicted balance and affordability agree.
3. **The bonus strip is decoration.** Three icons with sparkles say neither what qualifies nor what has been earned. BGSI tier chips and refs2's reward track express progress. **Draw:** labelled bonus icons with a short eligibility caption and clear locked/claimed indicators using approved offer rules. If no bonus rule exists, delete the strip and give the main cards more room.
4. **Too many surfaces shout at once.** Purple rim, purple card, aura, stars and thick typography compete with the fully bright world behind. DOORS uses quiet separators; BGSI dims the world around the panel. **Draw:** a dark translucent backdrop, quieter purple panel interior and thinner secondary borders. Reserve the strong aura/bright border for the selected tool. Keep the large scythe art and clear close button.

### panels-index.png — 6.5/10

**Best benchmark:** [BGSI seasonal book](../refs3/index-panel-bgsi-1.jpg), with Adopt Me search/detail states. Compared all `refs3/index-panel-*.jpg` and the shared `refs2/panels-shop-index-ref-{1,2,3}.jpg` family; refs2 frame 3 is the relevant inventory/detail analogue.

1. **The collection has a generic shop-shaped shell.** A purple rounded rectangle plus a book icon does not have BGSI's recognisable open-book silhouette. **Draw:** a pumpkin field journal with a visible central binding, small leaf-shaped category tabs and subtle paper pages; retain the readable grid rather than covering it with ornamental texture.
2. **The selected pet is not visibly selected.** A Pumpkin Pup preview floats outside the grid, but its tile shares the same star marker as every unknown tile. [Adopt Me backpack](../refs3/index-panel-adopt-me-2.jpg) couples search, item and tooltip. **Draw:** a clear selected ring on the Pup tile, move the detail preview into a reserved side column, and replace decorative universal stars with distinct discovered checks and unfilled unknown markers.
3. **Navigation stops at two broad tabs.** No search, rarity filter or scroll/page state is drawn. Adopt Me visibly searches “mumm”; [Journal](../refs3/index-panel-adopt-me-1.jpg) groups rarity. **Draw:** a compact search field and rarity dropdown above the grid, with one clearly selected category and a scroll indicator if the collection extends beyond these twelve slots. Do not add unnecessary categories.
4. **3/12 is the entire progression story.** The unknown silhouettes are mostly similar squat blobs; none shows where it is found, and no category completion state exists. BGSI depicts season, variant and claimed collection reward. **Draw:** distinct silhouette contours for the locked species, a selected locked-item preview with an approved location hint, and category progress under its tab. Show a completed/claimed state only where supported by the design; use the same candy icon as the HUD.

### hatch-reveal.png — 6.0/10

**Best benchmark:** [Adopt Me acquisition](../refs3/hatch-reveal-adopt-me-1.jpg) for physical emergence, [BGSI chest](../refs3/hatch-reveal-bgsi-1.jpg) for light response. Compared all three refs3 reveal frames and `refs2/hatch-reveal-ref-{1,2,3}.jpg`. These refs3 moments are acquisition/chest/catch analogues, not verified egg-hatch animation.

1. **The card replaces the reveal.** Shell halves are visible but the only Pup is a card illustration; the large modal covers the place where it should emerge. Adopt Me keeps the acquired companion in the enclosure. **Draw:** the Pup physically standing between the shell halves, face and feet unobscured; reduce the result panel to a lower or side card containing NEW, name, rarity and approved income.
2. **The nest has no identity.** Gold ring, empty stud lawn and cyan fence are almost the whole setting. Adopt Me uses webbed recesses, candles and architectural enclosure. **Draw:** a woven vine-and-straw nest on a soil pad, a small pumpkin lantern, a nearby seed crate and locally shaded fencing. Make the opened shell's former position clear.
3. **“Burst open” has no physical burst.** The shell interior is uniformly orange; there is no readable lip illumination, contact dust or light response on ground. BGSI's bright chest opening is visibly located inside a solid object. **Draw:** warm light from the split interior, a highlighted shell lip, a few angular shell chips and a small dust puff at the nest. Avoid a full-screen haze.
4. **Result and cinematic controls conflict.** A giant Ok button appears alongside “Tap to skip”; 60% Chance occupies result space. [Fisch catch](../refs3/hatch-reveal-fisch-1.jpg) tells why the acquired result matters. **Draw:** this as the completed result state with one “Continue” action, remove skip text from that state, and prioritise NEW and the pet benefit. Put odds in a pre-hatch/detail state, not the centre of this reveal.

### hatch-reveal-mass.png — 6.5/10

**Best available benchmarks:** refs3 Adopt Me acquisition/BGSI opening for emergence/light, refs2 hatch frame 3 for a mass display and frame 2 for reward grouping. Compared the same three refs3 and three refs2 reveal frames. A literal mass-hatch motion reference in refs3 is absent; timing remains UNKNOWN.

1. **All nine results are “NEW,” including repeated species.** Five Pups, two Ghostys and two Bats have identical discovery badges. This reads like a pasted presentation, whereas the reference reward panels distinguish item information and grouping. **Draw:** one discovery badge per newly discovered species, duplicate counts on compact result tiles, and a highlighted best result with a quiet batch total.
2. **Duplicate models change anatomy.** The front-right Pup has a long projecting muzzle; upper Pups have different nose/face proportions. Ghostys are smooth cube ghosts here but visibly faceted/studded elsewhere in v3. References repeat recognisable species forms. **Draw:** one exact Pup geometry and face ratio reused at each position; one Ghosty construction reused across reveal, index and pets. Vary pose/rotation, not species anatomy.
3. **Everything celebrates at the same intensity.** Common white rays, rare blue glow, epic purple glow and multicoloured confetti fill the image without a single reward focal point. Adopt Me bounds light to its emergence; the BGSI chest has a specific light source. **Draw:** the best result centred and largest, dimmer smaller duplicate results behind it, tightly bounded rarity accents and confetti only around the hero. Keep name labels in separate nonoverlapping bands.
4. **The batch has weak physical anchoring.** Two shell fragments on the sides do not explain nine emerging pets; some pets sit on the ground while others hover. **Draw:** an intentional temporary reveal stage with evenly aligned floating result positions above the nest and a clearly defined lower result strip; illuminate the nest from the reveal source. Use one “Continue” control for a completed batch, or one skip cue for an in-progress cinematic, never both states together.

### pets.png — 6.5/10

**Best benchmark:** BGSI varied companion contours, Adopt Me selective emission. Compared all three `refs3/pets-lineup-*.jpg` and `refs2/pets-ref-{1,2,3}.jpg`.

1. **Several pets share a cube face/body template.** Pup, Bat, Owl and Black Cat mainly change accessories on chunky heads. [BGSI group](../refs3/pets-lineup-bgsi-1.jpg) changes body proportions, swept horns and broad wings. **Draw:** Bat with a narrow suspended body and broad wing span; Owl with a rounded feather mantle and tiny feet; Cat with long ear points and a distinct tail; Pup with low shoulders and a clear muzzle. Preserve the King's crown and Dragon's vine horns as strong hero cues.
2. **The scene is a frontal catalogue.** Almost every pet faces camera in an arranged arc; the route and following relationship disappear. Adopt Me's two companions occupy a lived-in street; BGSI groups overlap at different heights. **Draw:** the player moving toward a visible destination, Pup following close to one side, two smaller companions behind, and one large hero farther back. Keep a walkable sightline rather than filling it with pets.
3. **Aura replaces material contrast.** The dragon's rainbow wings and broad flame outlines compete with face and body. [Adopt Me pair](../refs3/pets-lineup-adopt-me-1.jpg) retains readable surfaces around selective neon. **Draw:** matte fur/feathers, a glossy crown/gem and emissive eyes or seams; restrict the dragon glow to wing veins and eyes. Give wings visible opaque structure and consistent contact shadows.
4. **HUD and value labels look like placeholders.** Every Common through Secret pet says `$1.5/s`; this screen switches Shop/Index to flat rectangles and changes capacity icon/hotbar treatment. Refs expose actual differing status/value cues, though their economies are not ours. **Draw:** reuse the desktop HUD component shapes, candy icon and type scale exactly; use approved per-species values or omit values until approved. Distinguish equipped status from possession; do not invent escalating incomes.

### scythes.png — 5.5/10

**Best benchmark:** [RIVALS held scythe](../refs3/tool-held-rivals-1.jpg) for silhouette; [DOORS canisters](../refs3/tool-held-doors-1.jpg) for material/grip. Compared all three refs3 tool frames and `refs2/scythes-ref-{1,2,3}.jpg`. Canisters are a material analogue; no first-person camera change is proposed.

1. **Seven icons are mostly recolours.** Similar shaft/hook silhouettes rely on purple/red/pink/gold to communicate upgrades. RIVALS has an immediately readable hook outline. **Draw:** Rusty with a chipped narrow crescent, Witch with a broad bat-wing blade and crooked shaft, King with a crown-shaped head and heavy curved blade. Reuse those exact contours in hotbar and shop; reduce decorative studs at small scale.
2. **The grip is hidden and the weapon is idle.** Purple aura obscures the hand/shaft junction; the blade poses like a display asset rather than showing use. [Fisch held tool](../refs3/tool-held-fisch-1.jpg) has an action direction. **Draw:** fingers/hand clearly wrapping the grip, shaft positioned through the hand, torso turned into a swing and a short curved trail ending at a pumpkin impact.
3. **Surfaces lack a controlled material hierarchy.** Rivets/studs and flame rims do more work than wood/metal distinction. DOORS shows patterned metal, facets and local light on held objects. **Draw:** a matte wood shaft with wraps, steel blade with one bevel highlight and darker inner face, and an emissive inset on Witch/King. Cast a small coloured reflection on the hand and nearby ground rather than a whole-body flame curtain.
4. **It is a showroom on a baseplate.** Two tool pedestals and seven equally prominent slots compete with the held item; no selected state is clear. **Draw:** retain one equipped Witch and one contextual upgrade display near the shop, mark its matching hotbar slot selected, and place the player in the authored meadow. Move the full tool lineup to an asset sheet if needed; do not make gameplay resemble an asset sheet.

### guards-and-king.png — 5.0/10

**Best benchmark:** [Deepwoken boss staging](../refs3/boss-fight-deepwoken-1.jpg), with refs2 boss introduction for join information. Compared all three `refs3/boss-fight-*.jpg` and `refs2/guards-and-king-ref-{1,2,3}.jpg`.

1. **No guards are visible.** A single pumpkin-headed king stands squarely in front of a throne. Deepwoken's boss visibly confronts nearby participants. **Draw:** two smaller shield guards flanking the entrance in different ready poses, with the King leaning forward and one raised sceptre; preserve a clear join opening and player scale.
2. **The arena is empty green/purple stud sheets.** White farm fences and plain grey enclosure walls do not support the royal boss setting. Deepwoken uses a wood ring, stone rim and structured bounds. **Draw:** purple stone paving with gold radial trim, inset team-colour edge bands if needed, a low carved stone boundary and crown banners above recessed wall bays. Keep central combat space unobstructed.
3. **An expressionless pumpkin supplies no threat.** Crown and armour read, but a blank orange head plus upright pose reads as a statue. The refs show clear threatening silhouettes/weapon reach. **Draw:** carved angular eye/mouth shapes with bounded warm light, a tilted head, one forward foot and a sceptre extending into the arena. Distinguish guards through smaller heads and simpler armour.
4. **Admission information floats in the sky.** “120k Luck,” “50%” and a lone E key mimic refs2 but give no stable in-world join point or reward context. **Draw:** a compact board at the entrance showing approved requirement/reward information, and “E — Join” anchored to an actual gate marker. Keep the King name as the main title; use approved requirements or TBD, not borrowed numbers as finished game facts.

### guards-and-king-fight.png — 4.5/10

**Best benchmark:** [Deepwoken impact](../refs3/boss-fight-deepwoken-2.jpg), [RIVALS attack/damage cues](../refs3/boss-fight-rivals-1.jpg). Compared the same three refs3 combat and three refs2 guards/king frames.

1. **No combat is depicted.** King stays on the throne platform, player stands far away empty-handed, arena is vacant. Deepwoken puts boss feet, reaching weapon and players in one action plane. **Draw:** King on the arena floor mid-sceptre slam, player with scythe inside the encounter, and a second player dodging at the edge. Compose the weapon, target and impact in the same frame.
2. **The UI asserts incompatible states.** Partly depleted health, “E Join Fight,” “BREACHED” and “Tap to skip” all coexist. **Draw:** one active-fight state: narrow King health bar, selected scythe slot and player health; remove join and skip. Reduce breach notice to a small fading side cue or draw it separately as an intro state.
3. **Text dominates instead of threat.** The huge breach heading overlaps the King's crown zone, and duplicate boss portraits bookend a large bar. Deepwoken's narrow boss bar leaves room for its body/weapon. **Draw:** one small portrait, a narrow top bar with readable health, and the King's enlarged action silhouette below it. The event headline must not be the focal object.
4. **There is no contact feedback or authored floor.** The green/purple split is bare and no attack direction is visible. Deepwoken locates its swirl at the foot impact; RIVALS distinguishes a white arc from a red incoming-hit wedge. **Draw:** a gold-edged stone floor, a thin pre-impact ring, debris/dust precisely at the sceptre contact, a white outgoing scythe arc and a small red directional damage wedge. Keep the player's escape space visible.

### first-5-min.png — 5.0/10

**Best benchmark:** [Adopt Me target/reward frame](../refs3/first-minutes-adopt-me-1.jpg), [DOORS opening held item](../refs3/first-minutes-doors-1.jpg). Compared all three refs3 first-minutes frames and `refs2/first-5-min-ref-{1,2,3}.jpg`. BGSI's third reference is an opening quality choice, not gameplay onboarding; none certifies a first-ever five-minute session.

1. **The route is explained by headings rather than grounded targets.** Similar orange pumpkins fill the first panel, with arrows between them. Adopt Me places E on a specific coffin and reward text in that view. **Draw:** one distinct first pumpkin beside a broken fence, an anchored target cue, and a visible home nest beyond it. In the smash-result panel keep the broken target and candy reward in the same camera view.
2. **The steal moment lacks an owner or opposition.** Rare pumpkin sits on a stone display, indistinguishable from harvesting a public pickup. **Draw:** an opponent-owned patch sign, a visible rival or guard looking toward the nest, the thief carrying the pumpkin and a clear escape/home sightline. Show the social risk through pose and spatial relation, not another paragraph.
3. **State continuity breaks.** Candy rises to 1 after collecting, then returns to 0; the blue Rare pumpkin produces a Common Pup; final income uses dollars while HUD uses candy. Approved mechanics explaining these changes are UNKNOWN. **Draw:** a continuity-preserving counter sequence, any approved spend visibly at its transition, matching shell/result rarity cues and one currency icon/name. Keep the same avatar, tool and world arrangement across related panels.
4. **Six panels multiply a greybox environment.** Same tall orange walls, green studs, windmill and scarecrow recur, without crafted home/nest detail. DOORS immediately presents a tangible prop in an authored room; Adopt Me dresses the action surroundings. **Draw:** a single consistent meadow-to-home route with soil/grass/path transitions and edge clusters. Make the held starter scythe, carried pumpkin and newly planted companion physically present; keep the context action switching in one stable button position. That switching is a useful part to preserve.

### zones-strip.png — 5.5/10

**Best benchmark:** refs3 Fisch ground/elevation and Adopt Me crypt edge dressing; refs2 Angels lane for authored route surfaces. Compared both refs3 lane frames and `refs2/zones-strip-ref-{1,2,3}.jpg` for all three depicted zones.

1. **Woods and swamp still use artificial carpet floors.** Graveyard paving is an improvement, but dark-green studs and teal studs do not read as forest soil or a crossing through wet ground. **Draw:** Graveyard cracked stones with moss seams; Woods earth with exposed roots/leaf litter; Swamp a narrow raised plank walkway over dark water with reeds and muddy banks. Keep a readable traversal corridor.
2. **Identical corridor construction defeats biome identity.** All three use parallel high walls, a yellow centre stripe, monumental gate and same centred running avatar. Fisch layers shore, bank and dock. **Draw:** staggered crypt walls for Graveyard, an overhead tree canopy and low side bank for Woods, and an offset short bridge/bank for Swamp. Change cross-section and elevation, not just wall colour.
3. **Edge props are sparse and mirrored.** Graveyard tombs align like showroom markers; Woods has a few detached branches; Swamp uses block stumps rather than convincing habitat. Adopt Me's crypt groups candles, bones, coffins and webs. **Draw:** Graveyard tomb/candle/root clusters; Woods fern/log/mushroom clusters; Swamp reed/lily-pad/bubble clusters. Put one cluster close to camera and smaller groups farther away for depth.
4. **Landmark statues dominate empty routes.** Skeleton, tree giant and frog are recognisable, but there are no steal targets, defenders or carried rewards. **Draw:** one visibly distinct pumpkin nest and one small themed guard in each zone, with an anchored action cue on the nearest target. Replace the persistent yellow stripe with sparse directional markers that stop at the active destination.

### zones-strip-2.png — 5.5/10

**Best benchmark:** refs3 crypt for architecture/local light, Fisch for surface variety; refs2 Angels lane for a designed route. Compared the same two refs3 and three refs2 zone frames. These are structural analogues, not literal references for Vampire Castle/Candy Kingdom/King's Throne.

1. **All three foregrounds are huge empty stud sheets.** Red, lavender and purple floors change hue without changing construction. **Draw:** Vampire worn flagstones with a dark inset runner; Candy irregular biscuit tiles with icing edge trim; Throne large purple stone slabs with gold inlay. Make a clear material boundary at each route edge.
2. **The layout is the same shot three times.** Giant figure on the left, matched lamps, centred arch and yellow stripe repeat exactly. **Draw:** Vampire a narrow approach beneath a balcony; Candy a curved path around a giant confection display; Throne a short stepped court framed by an off-centre banner. Keep player-scale cameras but vary the landmark's distance and placement.
3. **Colour grading substitutes for local lighting.** Red lamps and pink/amber skies change mood, but broad ground surfaces remain nearly uniform. Adopt Me's crypt lights real recesses and props. **Draw:** red light pools beneath Vampire lamps with cool moonlit stone outside them; soft pink light under Candy awnings with shadows under trim; warm Throne brazier pools over cool purple paving. Keep hue boundaries and non-glowing surfaces readable.
4. **The figures and lanes feel uninhabited.** Vampire has a blank face, Candy is a generic armoured figure with a peppermint badge, and King repeats the hub monarch; no pumpkins or interactive nests appear. **Draw:** Vampire carved/expressive face and bat-wing cape, Candy a confection-built guard with a unique body contour, and King an active gatekeeper pose. Add an approved themed pumpkin target/nest and one small nearby player/guard interaction per zone, with edge details such as candle groups, sweet jars or royal crates.

## GLOBAL GAPS — top 8, in priority order

1. **Ground is unfinished.** Green/purple/teal stud sheets dominate meadow, combat and most lanes. Draw authored grass/soil, flagstones and planks with curbs, banks and edges. Fisch's sand/dock and BGSI's plaza are the relevant comparison; adding a texture over the same featureless plane is insufficient.
2. **Boundaries and depth are generic.** Tall rectangular walls, straight axes and evenly spaced oversized props recur. Draw overlapping foreground edges, middle-distance buildings/canopies and softer distant landmarks; vary roof and bank height. BGSI/Adopt Me achieve depth through construction, not just haze.
3. **Action is missing.** “Fight” shows no attack; “steal” shows no ownership or threat; “reveal” hides the physical reward. Draw a target, actor pose, contact/transition and useful result in the same view. Deepwoken impact and Adopt Me contextual action are the strongest evidence.
4. **Assets and labels do not stay consistent.** Pup anatomy, Ghosty construction, King chest gem, starter tool, HUD shapes and currency language change between screens; rarity/value labels repeat without credible state. Establish one visual model/icon per item and reuse it exactly. Depict approved values consistently or leave them out.
5. **Scenes lack clustered supporting props.** Empty distances are filled with isolated pumpkins, lamps or giant statues. Draw purposeful groups of plants, crates, tools, candles, signs and architecture at route edges. Density must support a place and an action; there is no universal “20 props” requirement.
6. **Lighting and materials lack hierarchy.** Broad noon brightness plus full-body flame rims make everything plastic and equally emphatic. Draw matte ground/wood, controlled metal bevels, deep recesses and bounded emissive accents with visible local light spill. DOORS and Adopt Me show useful contrast without requiring photorealism.
7. **UI is decorated more than it is stateful.** Universal stars, identical green buys, ambiguous hotbar selection, detached tooltips and incompatible join/fight/skip states undermine screenshot credibility. Draw explicit selected, owned, unknown, locked, affordable and completed states; give each pictured moment one coherent state.
8. **Pumpkin's identity is mostly signs and recolours.** Straight gates, cube pets and farm fences could belong to many simulators. Draw the distinctive steal-and-carry moment, vine/straw hatch nests, carved royal pumpkins and a readable rival patch. Preserve the best existing silhouettes and signs; remove repeated decoration that does not reinforce those elements.

## What an 8 needs — this game's checklist

- [ ] A believable player-camera frame with finished ground, trimmed route edges, layered skyline and purposeful prop clusters; no vast bare floor/wall dominating the composition.
- [ ] An unmistakable **steal a pumpkin** moment: owner/rival cue, carried pumpkin, danger and visible home destination.
- [ ] One consistent avatar, pet/tool model, icon set, currency language and HUD across all relevant views.
- [ ] Held tool and eligible target visible; compact selected/progress feedback; phone controls separated from counters and readable against the world.
- [ ] Physical pet emergence and a readable reward result; boss actually attacking on the arena floor, with contact effects and dodge space.
- [ ] Shop/index decisions readable through benefit, selected/owned/locked state and collection detail, with quieter secondary decoration.
- [ ] Varied biome surfaces, spatial construction and light contrast; pets/tools recognisable by contour before aura or text.
- [ ] At equal display size beside BGSI/Adopt Me/Fisch/RIVALS/Deepwoken/DOORS screen-fit examples, the frame reads as a coherent game capture without explanation. This is a judgement gate, not a promise of clicks.

**Recommended first revision:** one hub frame with authored ground, layered buildings and clustered edges, keeping the existing fountain and destination signs. Judge that against BGSI and Adopt Me before multiplying changes into the batch. No revision was drawn in this task.

## Lessons

- When a screen feels empty, repair ground boundaries and clustered geometry before adding glow, because light effects do not create a place.
- When judging an action screen, require visible target/contact/result, because a headline and health bar can disguise an idle asset display.
- When producing a multi-screen set, reuse exact models and UI states, because anatomical and currency drift makes polished images feel fabricated.

**Scope delivered:** this audit only. No game-code edits, source-image changes, redraws or commit.
