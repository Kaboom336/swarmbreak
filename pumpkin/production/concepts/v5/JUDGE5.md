# JUDGE5 — independent blind visual review

**Verdict: none of the 15 screens clears 8/10.** These are competent, readable concepts, but the repeated voxel fantasy kit, staged viewpoints and uneven reward/combat presentation keep them below a convincing popular-game screenshot. Strongest: shop and index (7.5). Weakest: pets and mass hatch (6).

## Evidence and calibration

Observed: all 15 v5 PNGs were inspected at original size, then against two different-game reference frames per screen in the delivered comparison images. Read REFS3.md and REFS2.md for file identities, dates and capture limitations. Did not open VERIFY.md, REVIEW.md, BUILDABILITY.md, PROMPTS.md, manifests, prior comparison sheets or artist scores. No earlier score was used.

Eight games represented: Adopt Me!, Bubble Gum Simulator INFINITY, Fisch, RIVALS, DOORS, Deepwoken, Pet Simulator 99 and Steal an Egg. The named best reference in each section means most useful in this supplied set, not a independently verified current top-20 art ranking. Current ranks and source authenticity were not re-verified online; upload dates are index-reported.

Art scores use the owner's calibration: 10 = indistinguishable from a current top-20 screenshot; 8 = believable popular-game screenshot that earns a click; 6 = visibly amateur/AI concept; 4 = programmer art. More geometry or brighter glow does not automatically beat a reference. Readability, distinctive identity, believable runtime framing and consistent assets matter together. Half points express judgement, not measurement; click-through and gameplay quality are UNKNOWN.

Buildability scores are inferred from the depicted visual scope only: 9 = routine small-team work with standard UI, low-poly meshes and reusable modules; 8 = feasible with deliberate custom art/lighting; 7 = feasible but substantial rigging, VFX or environment work. They do not prove asset availability/licences, development time, performance, completed game systems or exact rendered parity. Future lighting alone will not reproduce every painted contact shadow or highlight.

## Scores

| Screen | Art /10 | Buildability /10 |
|---|---:|---:|
| first-5-min | 7 | 8 |
| guards-and-king | 7 | 8 |
| guards-and-king-fight | 7 | 7 |
| hatch-reveal | 6.5 | 8 |
| hatch-reveal-mass | 6 | 8 |
| hub-perspective | 7 | 8 |
| hud-desktop | 7 | 9 |
| hud-phone | 6.5 | 9 |
| panels-index | 7.5 | 9 |
| panels-shop-index | 7.5 | 9 |
| pets | 6 | 9 |
| scythes | 7 | 9 |
| zone1-perspective | 7 | 8 |
| zones-strip | 7 | 7 |
| zones-strip-2 | 6.5 | 7 |

## Per-screen comparisons

### first-5-min — art 7/10; buildability 8/10

Compared: [refs2/first-5-min-ref-2.jpg](../refs2/first-5-min-ref-2.jpg) (Steal an Egg; upload 2026-09-25); [refs3/first-minutes-adopt-me-1.jpg](../refs3/first-minutes-adopt-me-1.jpg) (Adopt Me!; upload 2026-10-07). Best screen-fit reference: **Adopt Me!**. [Full-size comparison](first-5-min-cmp.jpg).

Biggest gaps:

- Adopt Me anchors its small E cue directly on the actionable coffin; ours stacks a headline, carry pill, oversized E board and arrow around an off-axis destination.
- The fence between runner and deposit pad makes the last few steps ambiguous; the Steal an Egg frame exposes the target and approach from a higher gameplay camera.
- The chase reads as two posed runners: no visible pursuit consequence or deposit reward. The inspected Adopt Me frame contains an immediate candy result.

**Fix:** Open the pad approach and show one anchored deposit cue plus the immediate reward in the actual chase camera.

**Buildability:** Reusable town modules and a carry animation are feasible; the chase, ownership and deposit states still need scripting.

### guards-and-king — art 7/10; buildability 8/10

Compared: [refs2/guards-and-king-ref-1.jpg](../refs2/guards-and-king-ref-1.jpg) (Pet Simulator 99; upload 2026-10-06); [refs3/boss-fight-deepwoken-1.jpg](../refs3/boss-fight-deepwoken-1.jpg) (Deepwoken; upload 2026-10-11). Best screen-fit reference: **Deepwoken**. [Full-size comparison](guards-and-king-cmp.jpg).

Biggest gaps:

- The king reads as a posed statue on a symmetrical staircase; Deepwoken's weapon and body fill the shared combat space and imply immediate reach.
- Pet Simulator 99 communicates entry expectations above the arena; ours has only a name and a small join state, with no visible reason to take this fight.
- Repeated crown banners and lanterns consume more visual emphasis than the guards; the guards have little separation in role or silhouette.

**Fix:** Move one guard into a distinct threatening pose near the join boundary and give the entry cue a concise reward or requirement.

**Buildability:** Modular castle parts and low-poly armour are practical; custom king/guard meshes, rigs and animations are needed.

### guards-and-king-fight — art 7/10; buildability 7/10

Compared: [refs3/boss-fight-deepwoken-2.jpg](../refs3/boss-fight-deepwoken-2.jpg) (Deepwoken; upload 2026-10-11); [refs3/boss-fight-rivals-1.jpg](../refs3/boss-fight-rivals-1.jpg) (RIVALS; upload 2026-10-11). Best screen-fit reference: **Deepwoken**. [Full-size comparison](guards-and-king-fight-cmp.jpg).

Biggest gaps:

- The red warning circle sits far to the right while the lifted weapon is over the king's left side; the frame does not explain which attack will land where. Deepwoken's swirl is visibly attached to the boss's feet.
- The tiny yellow spark at the ankle undersells the player's hit; RIVALS makes outgoing action and incoming damage conspicuous with separate arcs and wedges.
- The arena is an immaculate presentation bowl with repeated banners; Deepwoken's floor rings and strong local shadows bind the boss to a more convincing combat space.

**Fix:** Show one attack whose weapon, floor warning and impact share the same location, with a separate readable player-hit cue.

**Buildability:** A small team can build the geometry and ring effects; synchronised boss attacks, hit feedback and a large moving rig are the main production burden.

### hatch-reveal — art 6.5/10; buildability 8/10

Compared: [refs2/hatch-reveal-ref-1.jpg](../refs2/hatch-reveal-ref-1.jpg) (Steal an Egg; upload 2026-09-25); [refs3/hatch-reveal-adopt-me-1.jpg](../refs3/hatch-reveal-adopt-me-1.jpg) (Adopt Me!; upload 2026-10-07). Best screen-fit reference: **Adopt Me!**. [Full-size comparison](hatch-reveal-cmp.jpg).

Biggest gaps:

- The pet is small relative to the shell and the busy castle backdrop; the reward face competes with lanterns, waterfall highlights and the distant king.
- The two almost mirrored shell halves and neatly placed stars read as a composed illustration; Adopt Me's acquisition is grounded in an enclosing prop and a local emergence effect.
- Steal an Egg attaches income/result information to the emerged companion; ours gives only NEW/name/rarity, leaving the reward's useful consequence absent.

**Fix:** Bring the pet face closer, quiet the background and attach one useful result line to a less symmetrical shell burst.

**Buildability:** Split shell meshes, a pet model and particle stars are feasible; matching the painted light response needs a controlled camera and deliberate light placement.

### hatch-reveal-mass — art 6/10; buildability 8/10

Compared: [refs2/hatch-reveal-ref-3.jpg](../refs2/hatch-reveal-ref-3.jpg) (Pet Simulator 99; upload 2026-10-06); [refs3/hatch-reveal-bgsi-1.jpg](../refs3/hatch-reveal-bgsi-1.jpg) (Bubble Gum Simulator INFINITY; upload 2026-10-10). Best screen-fit reference: **Pet Simulator 99**. [Full-size comparison](hatch-reveal-mass-cmp.jpg).

Biggest gaps:

- The Pet Simulator 99 frame visibly presents a crowd of newly revealed pets; ours presents one pet and three tiny count icons. It does not visually sell a mass hatch.
- Most of the screen is repetitive town scenery and empty approach; the result summary is much smaller than the scenery around it.
- BGSI's chest reveal puts the luminous reward source and gain popups in the active area; ours has a generic star aura and no visible relationship between nine hatches and the single shell.

**Fix:** Use a foreground arrangement of all nine results, then highlight the rare bat and compress duplicates into the summary.

**Buildability:** The depicted single hero plus count summary is easy to build; this score does not certify a nine-pet reveal animation that the image never shows.

### hub-perspective — art 7/10; buildability 8/10

Compared: [refs3/hub-base-bgsi-1.jpg](../refs3/hub-base-bgsi-1.jpg) (Bubble Gum Simulator INFINITY; upload 2026-10-11); [refs3/hub-base-adopt-me-1.jpg](../refs3/hub-base-adopt-me-1.jpg) (Adopt Me!; upload 2026-10-07). Best screen-fit reference: **Bubble Gum Simulator INFINITY**. [Full-size comparison](hub-perspective-cmp.jpg).

Biggest gaps:

- BGSI's crooked roofs and portal give the town a recognisable seasonal silhouette; ours repeats cubic foliage, timber houses and castle towers until it resembles a generic fantasy kit.
- The large fountain and castle dominate the route; the stealable pumpkin is pushed to the right behind fence rails, so the central sightline sells sightseeing more than stealing.
- Adopt Me separates illuminated facades from darker canopy; ours has warm lights everywhere under uniform bright daylight, reducing selective emphasis.

**Fix:** Make the rival patch the foreground focal point, break the skyline and reserve the strongest light contrast for the active destination.

**Buildability:** Modular buildings, stone paths and simple foliage are buildable; many individual blocks, lanterns and waterfalls need sensible merging and light limits.

### hud-desktop — art 7/10; buildability 9/10

Compared: [refs3/hud-pc-rivals-1.jpg](../refs3/hud-pc-rivals-1.jpg) (RIVALS; upload 2026-10-11); [refs2/hud-desktop-ref-1.jpg](../refs2/hud-desktop-ref-1.jpg) (Pet Simulator 99; upload 2026-10-06). Best screen-fit reference: **RIVALS**. [Full-size comparison](hud-desktop-cmp.jpg).

Biggest gaps:

- RIVALS separates match state, health and selected-tool information; ours repeats the hit count through text and a long bar while a detached action instruction occupies another strip.
- The Candy/Carry blocks and outlined Shop/Index tiles look like a generic simulator UI kit; Pet Simulator 99's smaller counters and distinctive sticker icons have a clearer hierarchy.
- The camera devotes substantial space to decorative king/castle scenery; the active pumpkin and scythe compete with many orange props and the nearby pet.

**Fix:** Reduce permanent counter boxes, unify hit state with the target and quiet the scenery immediately behind the smash.

**Buildability:** Standard screen UI, a target billboard and a short trail are straightforward; no unusual rendering feature is required.

### hud-phone — art 6.5/10; buildability 9/10

Compared: [refs3/hud-phone-rivals-1.jpg](../refs3/hud-phone-rivals-1.jpg) (RIVALS; upload 2026-10-11); [refs2/hud-phone-ref-1.jpg](../refs2/hud-phone-ref-1.jpg) (Steal an Egg; upload 2026-09-25). Best screen-fit reference: **Steal an Egg**. [Full-size comparison](hud-phone-cmp.jpg).

Biggest gaps:

- The joystick, two counter cards, hotbar and two large action circles form a heavy lower-screen band; Steal an Egg keeps counters and context interaction more compact.
- The scythe inside SMASH is a detailed item render rather than a strong touch glyph; RIVALS' solid white symbols remain clearer at reduced size.
- The world target label and detailed background are designed like the desktop scene; they lose emphasis when this full landscape image is viewed at phone scale.

**Fix:** Use a simple solid smash glyph, compact counters and a larger target cue while preserving clear thumb space.

**Buildability:** The shown layout uses ordinary UI controls and target rings; physical reach, safe areas and frame rate are UNKNOWN without device testing.

### panels-index — art 7.5/10; buildability 9/10

Compared: [refs3/index-panel-bgsi-1.jpg](../refs3/index-panel-bgsi-1.jpg) (Bubble Gum Simulator INFINITY; upload 2026-10-11); [refs3/index-panel-adopt-me-1.jpg](../refs3/index-panel-adopt-me-1.jpg) (Adopt Me!; upload 2026-10-07). Best screen-fit reference: **Bubble Gum Simulator INFINITY**. [Full-size comparison](panels-index-cmp.jpg).

Biggest gaps:

- BGSI's book-shaped index has a collection-specific identity; ours remains a generic purple rectangle despite the usable search, filter and detail preview.
- Nine empty silhouette cells dominate the panel, and the selected preview mostly repeats name/rarity/state rather than showing a compelling collection payoff.
- Adopt Me exposes rarity-group completion and BGSI shows claimed collection state; ours shows only a global 3/12 total without a visible category reward or completion treatment.

**Fix:** Give the index a Pumpkin scrapbook identity and one clear category-completion treatment while preserving its search and preview.

**Buildability:** Screen UI and viewport previews are practical; bespoke icon art and consistent pet models are the principal content work.

### panels-shop-index — art 7.5/10; buildability 9/10

Compared: [refs3/shop-panel-doors-1.jpg](../refs3/shop-panel-doors-1.jpg) (DOORS; upload 2026-10-02); [refs2/panels-shop-index-ref-1.jpg](../refs2/panels-shop-index-ref-1.jpg) (Pet Simulator 99; upload 2026-10-06). Best screen-fit reference: **DOORS**. [Full-size comparison](panels-shop-index-cmp.jpg).

Biggest gaps:

- DOORS gives every offer a concrete function; ours explains Witch but calls King only 'Royal scythe', which is decorative rather than informative.
- 'Selected' is bright yellow above an unaffordable item while the avatar still holds Rusty; selected-preview versus equipped state is insufficiently distinguished.
- Pet Simulator 99's bright item stickers and button surfaces have stronger separation; Witch's dark head partly sinks into its purple card, and the red shortage line is cramped at the bottom.

**Fix:** Label Witch as a preview, state King's benefit and enlarge the unavailable-state area with stronger item contrast.

**Buildability:** Three product cards, state styling and model renders are highly buildable with standard Roblox UI.

### pets — art 6/10; buildability 9/10

Compared: [refs3/pets-lineup-bgsi-1.jpg](../refs3/pets-lineup-bgsi-1.jpg) (Bubble Gum Simulator INFINITY; upload 2026-10-11); [refs3/pets-lineup-adopt-me-1.jpg](../refs3/pets-lineup-adopt-me-1.jpg) (Adopt Me!; upload 2026-10-07). Best screen-fit reference: **Bubble Gum Simulator INFINITY**. [Full-size comparison](pets-cmp.jpg).

Biggest gaps:

- BGSI's horns, crowns, swept wings and body sizes produce distinct companion identities; ours shows three small, similarly weighted followers with much weaker scale and material variation.
- The pets face away from the viewer, hiding nearly every face; Adopt Me's inspected pair communicate character through visible faces, different proportions and bounded neon.
- The bat sits against the hotbar and '3 Equipped' occupies a numbered tool slot; pet team state and tool selection visually overlap.

**Fix:** Show a three-quarter follower arrangement with visible faces, distinct silhouettes and a separate compact team indicator.

**Buildability:** Three low-poly followers are easy for a small team; smooth following, bobbing and wing animation require routine scripting.

### scythes — art 7/10; buildability 9/10

Compared: [refs3/tool-held-rivals-1.jpg](../refs3/tool-held-rivals-1.jpg) (RIVALS; upload 2026-10-11); [refs3/tool-held-doors-1.jpg](../refs3/tool-held-doors-1.jpg) (DOORS; upload 2026-10-02). Best screen-fit reference: **RIVALS**. [Full-size comparison](scythes-cmp.jpg).

Biggest gaps:

- RIVALS' hooked tool keeps a recognisable shape in the viewport corner; ours relies on purple emission and a staged broadside swing to sell the selected tool.
- DOORS' held canisters show strong local material and light response; ours has a mostly flat brown shaft/dark purple head with a narrow glow that barely affects the target.
- The shop displays and equipped icon do not convincingly match the held tool's proportions; the large pumpkin crack sells the impact more strongly than the weapon does.

**Fix:** Use one consistent scythe mesh in hand, display and hotbar, with distinct shaft/head materials and a restrained directional impact.

**Buildability:** Small meshes, grip animation and trail effects are feasible; three consistent render variants are manageable content work.

### zone1-perspective — art 7/10; buildability 8/10

Compared: [refs3/zone-lane-fisch-1.jpg](../refs3/zone-lane-fisch-1.jpg) (Fisch; upload 2026-10-10); [refs3/zone-lane-adopt-me-1.jpg](../refs3/zone-lane-adopt-me-1.jpg) (Adopt Me!; upload 2026-10-07). Best screen-fit reference: **Fisch**. [Full-size comparison](zone1-perspective-cmp.jpg).

Biggest gaps:

- Fisch's shore uses broad sand/wood/water contrasts; ours repeats small grass cubes, loose stones and orange pumpkins across both margins, making the target less special.
- Adopt Me's crypt has a coherent enclosing silhouette and local candle light; ours mixes sunny farm, castle-style wall and graveyard without a strong lighting transition.
- The back-facing runner is caught in a staged smash with the target off the travel lane; a taller real gameplay camera would explain the playable width and route more clearly.

**Fix:** Clear the active pumpkin's immediate surroundings and introduce a distinct graveyard light/material transition from the actual follow camera.

**Buildability:** Farm modules and a low-poly graveyard gate are feasible; authored ground materials and merged foliage are needed to reproduce the density efficiently.

### zones-strip — art 7/10; buildability 7/10

Compared: [refs2/zones-strip-ref-1.jpg](../refs2/zones-strip-ref-1.jpg) (Steal an Egg; upload 2026-09-03); [refs3/zone-lane-fisch-1.jpg](../refs3/zone-lane-fisch-1.jpg) (Fisch; upload 2026-10-10). Best screen-fit reference: **Fisch**. [Full-size comparison](zones-strip-cmp.jpg).

Biggest gaps:

- Fisch distinguishes traversable dock, shore and water with broad surfaces; ours packs rope posts, lanterns and platforms into the same narrow corridor, making routes harder to parse.
- Steal an Egg identifies its zone instantly with a large name and broad floor change; ours splits attention among three small destination signs and several distant hero props.
- The camera sits well left of the avatar to expose the scene; it reads as a staged environment showcase, leaving the steal platform approach and escape direction unclear.

**Fix:** Show the steal platform from the player follow camera, widen its route and establish one dominant swamp landmark.

**Buildability:** The boardwalk kit is feasible, but custom tree/frog heroes, many props and fog/light balance create more work than the meadow.

### zones-strip-2 — art 6.5/10; buildability 7/10

Compared: [refs2/zones-strip-ref-2.jpg](../refs2/zones-strip-ref-2.jpg) (Steal an Egg; upload 2026-09-23); [refs3/zone-lane-adopt-me-1.jpg](../refs3/zone-lane-adopt-me-1.jpg) (Adopt Me!; upload 2026-10-07). Best screen-fit reference: **Adopt Me!**. [Full-size comparison](zones-strip-2-cmp.jpg).

Biggest gaps:

- Steal an Egg's prehistoric frame uses a coherent floor, oversized bones and one lane; ours shows dark castle, candy castle and king castle together without a clean zone hierarchy.
- The candy lane is largely the same stone/castle/waterfall world with pink trim; Adopt Me's crypt changes enclosure and lighting as well as props, creating a more convincing separate place.
- The frame omits the ordinary HUD while depicting stealing progress, and the avatar/scythe/pet repeat the same posed arrangement; it feels like a promotional mockup.

**Fix:** Give Candy a distinct ground/enclosure treatment and isolate its active route in a consistent gameplay camera and HUD.

**Buildability:** The modular castle can be reused, but three hero landmarks and themed props raise the custom-art burden; phone performance is unverified.

## Comparison files and limits

Each comparison is 2560 pixels wide: our full uncropped concept is scaled proportionally to 1280 pixels wide and centred on top; the two uncropped reference frames sit below at 1280 × 720 each, side by side, labelled with game and upload date. This preserves full encoded reference resolution rather than shrinking their text into thumbnails. All 15 originals were also inspected separately at native resolution. Windows System.Drawing was used after Python was unavailable on PATH and the located interpreter returned Access Denied; no packages or security settings were changed.

The BGSI frame in the mass-hatch comparison is a chest reward analogue, not a second literal mass hatch. Adopt Me's hatch comparison is companion acquisition. RIVALS is a combat-feedback analogue, not a boss. DOORS' canisters are a material/grip analogue, not a scythe. The zone references compare navigation and theme separation, not identical biome subject matter. Embedded mobile footage has uncertain intrinsic resolution. Creator overlays (HARU, General Strategy, etc.) are source-video graphics and were not treated as game UI. Stills cannot establish animation timing, input feel, retention or first-ever-player onboarding.

Only JUDGE5.md and the 15 requested *-cmp.jpg files were written. No game/source/concept edits or commit.

## Lessons

- When a scene looks polished but staged, compare it from the player camera, because extra scenery can conceal weak route and action clarity.
- When judging a mass reward, require visible multiple results, because a count label alone does not create the payoff.
- When scoring concept art, separate buildability from screenshot credibility, because easy-to-build assets can still look generic.
