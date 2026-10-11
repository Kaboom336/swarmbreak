# L1 results — look and feel

Implemented in the existing three Patch files. No commit, network access, scene edits, save schema changes, or King/guard attack changes.

## Per item

1. **Z12 fonts:** FredokaOne Regular display roles and numbers; GothamSSm Bold body; upright faces; fixed integer viewport sizing; contextual black strokes. Removed legacy constraint consumers that would otherwise crash after TextScaled removal. Candy gets a gold vertical gradient. Runtime normalization covers legacy and admin UI as well.
2. **Z13 pumpkins:** removed the extra block stem and every wild candy emoji billboard. Retained existing KayKit carriers and native mesh stems; added welded dark ribs and carved faces, nearly uniform squash, saturated Sunny tint, and increasing tier widths. Geometry/reward/save attributes remain independent.
3. **Z19 swing:** every scythe selects all eligible targets in a 110-degree forward arc, nine studs to their centres, nearest six maximum. Server selects targets, validates zone access and retains cooldown/teleport checks. Each target receives its own damage number, hit and pop effects. Bigger pooled candy streams fly to the counter; successive pops and collections rise in pitch. Chain payouts add 5% per extra target, capped at 25%.
   **Economy choice:** total swing damage is shared across targets beyond the previous farming damage budget: one target-equivalent for early scythes, three for tier 3+. Full damage on six targets failed the arrival tolerance in the stress model. Shared damage plus the bonus passed. Single-target damage is unchanged. This tradeoff needs a Studio feel check.
4. **Z15 interaction:** dropped pumpkins use server walkover polling with load, life, range, capacity and theft checks. Rain candy keeps touch collection with added server checks. Entering your own pen automatically fills empty unlocked slots through the existing delivery path; full pens retain an explicit swap choice. Nest pumpkins accept a swing or zero-hold tap, with server facing/range/line-of-sight checks. Gates have one zero-hold prompt and retain server cost/access checks. Relevant prompts use line of sight and global exclusivity. Tutorial hints now describe taps/swings.
5. **Z16 floating text:** shared bounds calculations place labels above their subjects, including rotated models; separate hatch/income margins prevent overlap. Static world tags refresh as models grow or change. Seed carriers and pen parts avoid measuring the entire nest/pen. Key labels are AlwaysOnTop. Wild name/HP boxes were enlarged to fit their fixed fonts.
6. **Models:** rarity heights 3.2/3.9/4.7/5.7/7.0 with weight and width limits; reduced roam for tall pets; rarity rim colours and Rare+ aura; Meadow guard height 11; contrasting pen discs and gold locked rims; larger gold lock with silver shackle/keyhole; tier-sized carried pumpkins on the back/head. Gold/Shiny finishes preserve base colour detail.

## Evidence and reference comparison

Checked the supplied Zion list, all three section notes, local PLAYBOOK, existing code and asset records. Existing local research records KayKit Halloween Bits as CC0; no new external assets were adopted.

| Local reference/spec | Previous implementation | L1 implementation |
| --- | --- | --- |
| Pet Simulator 99 rounded display type and dark strokes | Gotham Heavy everywhere, italic number request, scaled glyphs | Fredoka display / Bold body, upright integer sizes |
| SECTION-MODELS pumpkin readability | extra square stem, emoji marker, squash variants | native stem, ribs/face, restrained squash and tier width |
| PS99 reward feedback cited in supplied notes | tier-3 arc only, merged damage number | all-tool arc, separate numbers, larger pooled candy stream |

These are code/spec comparisons, not inspected Studio screenshots. Visual quality and satisfying play remain **UNKNOWN** until the Studio route below.

## Checks

- `stylua src` and `stylua --check src`: pass.
- Required three-file `scene/compile-check.luau`: all OK at optimization levels 0/1/2 with debug locals retained.
- `selene src`: 0 errors, 0 warnings, 0 parse errors.
- `scene/econ-sim.luau`: pass.
- `l1-econ-check.luau`: existing simulator executed with full six-target chains and actual shared damage/bonus policy; pass. Modeled gate arrivals remain within its 25% tolerance. No scene source was changed.
- `l1-farm-check.luau`: actual server selector passes boundary, access, height, rear/range exclusion, per-target pop, cap and damage-budget tests.
- `l1-presentation-check.luau`: fixed fonts/sizes and rotated/replaced subject bounds pass mocked regression tests.
- `l1-locals-check.cjs`: lexical top-level declaration counts server **133**, client **128**, Config **5**. Largest function/do declaration totals are 29/60/41, with ample room for parameters and loop variables. Compile checks also pass.
- Two independent static critic reviews caught and resolved constraint crashes, counter role override, undersized HP boxes, parent-model bounds, shared margins, missing nest swing pickup and fixed pop pitch.

## Studio checklist

- [ ] Desktop and phone: HUD, Shop, Index, gates, damage numbers and PatchDebug/admin use clear upright fonts; no clipping or errors on resize.
- [ ] Meadow and Graveyard: no block stems or candy emojis; pumpkins read clearly at 30 studs; big and tier silhouettes differ.
- [ ] Starter scythe: swing at six pumpkins, then turn away or stand past nine studs; only valid arc targets react, with separate numbers. Check shared damage feels good, chain bonuses and counter streams. Spam swing and confirm cooldown still holds.
- [ ] Walk over a dropped pumpkin/candy; check full capacity, death and unloaded-player rejection. Swing/tap a nest from front, rear and behind a wall. Only one prompt appears at the spot.
- [ ] Enter your own pen carrying several pumpkins: empty slots fill automatically. Another pen does not accept them; full pens offer a choice rather than replacing pets automatically.
- [ ] Hatch Common through Mythic; inspect rarity sizes/rims, pen contrast and locks. Carry mixed tiers; check scythe/view clearance and enlarged pets' spacing.
- [ ] Inspect hatch/income tags, guards, gate/stall signs after growth and respawn: labels remain above geometry.
- [ ] Rejoin an existing save with pets and carried pumpkins. Exercise existing PatchDebug/admin commands; smoke-test King/guard behavior for regressions.

## Lessons

- When removing TextScaled constraints, update every consumer, because stale nil accesses can stop the HUD.
- When widening a farming arc, simulate the new target count, because the old economy model can pass while validating obsolete behavior.
- When positioning billboards, measure the subject and distinguish tag margins, because aggregate pen bounds and shared offsets misplace labels.
