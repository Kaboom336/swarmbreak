# Pumpkin magic direction — proposal, 2026-10-06

Status update, 2026-10-07: the user's instruction to continue authorizes the bounded [first magic garden slice](../production/garden-slice-contract.md). The growth/awakening/guidance/burst proposal is being implemented for playtesting. Other alternatives, future forms and exact balance constants remain proposals; runtime quality and user approval remain pending. The previous catapult prototype is preserved and gated off.

Latest explicit requirement: pumpkins must **grow to visibly different sizes, including big pumpkins**, while the basic gameplay remains simple. This proposal puts growth in the core loop, with form ascension later.

The [garden, collection and art review](GARDEN-ART-COLLECTION-DESIGN.md) details the compact patch/orchard/shrine, proposed form rarity labels, model and effect examples, recent Halloween references and remaining gameplay risks. It keeps size independent from form and scopes the initial slice before later collection content. These are design proposals, not a new build or gameplay validation.

Illustrated boards: [three directions](concepts/magic-options-v1.png), [gameplay storyboard](concepts/magic-loop-v1.png), [models and transformation](concepts/magic-art-v1.png). Board 1 is deliberately a mood comparison and is more ornate than the production target. Board 2 shows the later Gust experiment; the simpler first slice uses movement-facing guidance and chain seedbursts. Its generic form labels are illustrative; the written form proposal below governs. Board 3 is the closer target for achievable chunky art. Images are not executable art assets.

New [growth board](concepts/magic-growth-v2.png): size comparisons are illustrative, not fixed world dimensions. Its water/plant labels suggest later optional gardening; the first slice uses automatic vines with no mandatory watering or planting menu. Size stays separate from magic form; later forms can change spell behavior.

Fresh design review flagged multi-input complexity, missing first-slice cooperation and unclear shell rules. The latest user request adds growing pumpkins of visibly different sizes and closer study of comparable games. The revised proposal defines automatic vine regrowth, a harvest-now-or-grow-bigger choice, movement-facing guidance, a single active Recall action, optional early burst, size-dependent contact charges, and chain seedbursts in the first two-player slice. These revisions address design clarity; they have not passed a gameplay or fun test. See [growth and comparable-game review](GROWTH-COMPARABLES-20261006.md) for dated evidence, exclusions and tests.

## What we are making

User requirements: Halloween and/or magic; unique but familiar; pumpkins, harvesting, gold upgrades and spell transformations; a convincing playing-together feeling inspired by Build the Pyramid; bright, juicy, kid-friendly quality; free assets/templates only; never insert scripted Creator Store items; agent handles builds; commit only after user acceptance.

Recommendation: **Living Pumpkin Spells**. You are a pumpkin witch. Your pumpkins grow on owned vines in a shared public patch while you play. Harvest a small one now or leave one growing larger, bring it to life, then travel beside it while directing it through a haunted garden. Your pumpkin visibly cracks as its spell is used. Choose where to release its final seedburst, earn gold, improve growth, and eventually transform your pumpkin into a new magic form.

Latest user constraint: **simple to understand**. One-sentence introduction: “Pick a pumpkin, wake it with magic, and guide it through ghosts to earn gold.” Start with one spell and one clearly described upgrade. Use a single contextual Harvest/Cast action with normal movement; automatic burst on exhaustion means the optional Burst action is not needed to succeed. No recipes, energy currency, required spell combinations or simultaneous upgrade menus in the first session. Rewards and village contribution happen automatically. Introduce a second spell only after the basic loop is understood. Test touch steering early: if moving and aiming simultaneously is awkward, use movement-facing guidance with generous ghost assist rather than demanding twin-stick precision.

Familiarity comes from harvest, simple directional controls, obvious gold rewards, a nearby upgrade shop and visible forms. The distinctive interaction is a physical living pumpkin shaped by spells while players move together. A stationary launcher with a wand skin would miss this promise.

## Compare three complete alternatives

| Direction | Repeatable action | Friends change play | Main risk |
|---|---|---|---|
| Living Pumpkin Spells — recommended | Harvest → awaken → guide → burst → upgrade | Gust gathers ghosts; a second player's pumpkin travels through the group; both receive contribution rewards | Guiding the pumpkin must feel responsive on touch; could otherwise become frustrating companion babysitting |
| Cauldron Crew | Harvest → choose ingredient → brew → cast a shaped potion spell → upgrade | Combine recipes and take quick optional stirring/ingredient jobs to change the resulting spell | Stationary batching and brewing waits could feel like chores; stronger magical theme, weaker physical play |
| Haunted Parade | Harvest → awaken helpers → escort a lantern float → free friendly ghosts → upgrade | Players' helpers fill a shared procession and light the route together | A procession can become passive following; needs meaningful route choices and interruptions |

These are different games, not three systems to combine. Build one first.

## Recommended moment-to-moment loop

1. **Grow and harvest:** each player's owned vines occupy the same public patch so friends can see each other's growing pumpkins. Vines regrow automatically after harvesting; no required seed shopping, planting menu or click-to-grow grind. A harvest-ready small pumpkin is available at first arrival. Pumpkins visibly swell while the player does garden outings. Harvest a small one now, or leave another growing toward the currently attainable larger size. Tap a ready pumpkin; crouch, tug, vine-pop, then a size-appropriate lift or wand tether. One pumpkin is enough for an outing. Crop ownership remains personal: other players cannot steal or destroy it. Offline growth is a later option to evaluate, not a first-slice promise.
2. **Awaken:** stand anywhere on the garden approach and cast. Wand tip draws one rune; seeds orbit, face lights, pumpkin rocks forward. A short directional preview shows where it will begin moving. No machine, station queue, angle setting or charge slider.
3. **Guide:** walk with the pumpkin in a compact garden. The pumpkin follows your movement direction with gentle ghost assistance; separate aiming is deferred. The contextual action reads **Recall** while active: one tap brings a lost pumpkin back within wand reach without consuming a new harvest. First-prototype target: a slow readable pumpkin; this is not a punishment chase.
4. **Decide:** shell capacity scales with pumpkin size and remains visibly countable. Initial tuning example: a small pumpkin has three contact charges; a big one has a few more, subject to testing. Each ghost-group contact awards gold and uses one charge; every charge loss opens another crack. Idle movement does not drain charges. Thick roots gently deflect the pumpkin instead of deducting a hidden resource. On the last contact it automatically bursts at that location. An optional early Burst sacrifices remaining contact opportunities to cover a nearby dense group or join a friend's burst. All contacts and burst free ghosts and award contribution credit; size-dependent footprints, radii and payouts need balancing. No hidden failure removes earned gold.
5. **Burst:** the pumpkin squashes, cracks flare, then a directional seedburst frees mischievous ghosts into warm wisps. Credit is awarded as interactions occur; the burst adds a clearly previewed finishing reward. The reward text names what happened. Walk back through a short loop to the patch/plaza rather than a compulsory teleport/loading cycle.
6. **Upgrade:** the first shop choice is one permanent gold growth upgrade labeled **GROW BIGGER**, previewed on an actual vine: it raises attainable pumpkin size and improves growth pace. Returning players see their investment in the next crop. Shell capacity and burst scale follow size; do not open separate upgrade trees for every property. Later new spells change actions; they are not all multipliers. Ascension is an earned, deterministic magic-form transformation with a visible requirement and before/after preview. Size and magic form are independent: a big ordinary pumpkin and a small Wisp Pumpkin must both make sense.

Starting session pacing is a hypothesis: harvest within 10 seconds; first awakened pumpkin within 25 seconds; first payout within 60 seconds; first affordable meaningful upgrade within 2–3 minutes. A guided outing should initially last roughly 15–25 seconds, tuned through playtests, not frozen as a requirement. No long forced intro or compulsory reading.

Example first three minutes, for design testing rather than a claim about implemented play: arrive beside a ready small pumpkin and an obvious growing vine; harvest, awaken and guide through the nearest ghosts. The exhausted shell bursts automatically and wisps visibly light part of the shared shrine. Return to find a replacement crop has grown while you played. A friend joins the next outing and both players notice a chain seedburst reaching another group. Spend earned gold on the single growth upgrade; the preview shows a larger attainable pumpkin. Continue with a ready small crop while another grows big, then try the big one and feel its larger contact footprint, extra shell capacity and broader burst. The economy and timings must allow this example before it becomes a production target.

## Growing sizes that change the action

Proposed size ladder: **small**, roughly waist height; **big**, roughly avatar height; **giant**, roughly three avatar heights. These are approximate concept proportions, not fixed Roblox dimensions. Start with small and big; a giant silhouette can hint at later progression without requiring giant physics in the first slice.

Size should read through silhouette, shell capacity, contact footprint, burst scale and motion weight. A big pumpkin has a heavier settle, stem lag and slower-looking squash/recovery while still responding promptly to guidance. Preserve comfortable avatar walking speed. A bigger object must not block the camera, hide ghosts or require tedious carrying. Use offset guidance/tether poses and bounded camera framing as needed. The same chunky Halloween art, clear carved face and warm shell/cool spell contrast apply at every size; growth alone must not impersonate an earned Wisp or Bramble ascension.

The choice is immediate repeated small outings versus saving a crop for a more spectacular outing. Bigger cannot automatically be the optimal gold-per-minute choice: compare active small harvesting, mixed play with one growing crop, and standing idle waiting. Tune growth pace, shell contacts and payouts so active play matters and a size upgrade feels meaningful. No balance result is known yet. Avoid penalties that erase the appeal of growing big or make newcomers' small pumpkins irrelevant.

Giant is a later risk gate: large moving bodies can destabilize physics, occlude the camera, overwhelm phone screens and consume server/network budget. Cap actual size and contact reach, keep presentation separate from authoritative contact/reward rules, and profile simultaneous large pumpkins on mobile before enabling them. Giant bursts cannot shove players, steal crop credit, monopolize newcomers' targets or obscure their actions. These are design constraints for a future implementation; no network or physics code is changed here.

## Magic and friends

Prototype only **Awaken/Guide** plus **Seedburst**. Later, test **Ghost Gust**: pull nearby mischievous ghosts into a short-lived spiral, giving a friend an obvious opportunity to steer through them. Gust works for your own pumpkin too. Support actions earn credit, so the final hit does not steal someone else's reward. Nearby unrelated players do not receive passive gold just for standing still.

First-slice friend interaction: **chain seedbursts**. Two players' bursts occurring close together in space and time join into a clearly connected, wider seed arc that can reach another ghost group. It does not move or prematurely burst anyone else's pumpkin. Both players receive contribution credit. A visible connecting rune and shared sound make cause and effect legible: “Burst together for a bigger burst.” This is optional and uses existing actions; one player remains fully playable. Distance, time window and reward limits are tuning hypotheses, not approved constants. Test whether friends notice and intentionally repeat it; do not count a stat bonus or automatic shrine fill as proof of cooperative fun.

Each player retains normal movement, their pumpkin and their progression. No required tank/healer roles or requirement to wait for another player. Two friends can harvest together, travel together and visibly combine magic immediately. Keep a shared active space; avoid a separate private lane for every player. Players cannot force another person's burst or redirect their pumpkin without permission.

Proposed larger shared goal: **relight the Halloween village**. Freed wisps automatically fill the nearest unlit landmark. Lanterns come on, ghost residents return, and one small festival structure changes silhouette at each stage. This borrows the visible collective accomplishment from the pyramid reference without inventing another resource-carrying chore. First slice contains one lantern shrine, not a giant castle. A lone player can complete a small stage. Full server persistence/event reset rules are deferred until the loop is fun; personal earned gold and unlocked forms persist independently.

## Models and visual language

Warm orange pumpkin against cool violet/teal surroundings; cyan for your guide spell, lavender gust, gold rewards. Distinguish spells by shape as well as color. Chunky ribs, oversized curled stem, readable carved face, rounded wand silhouette, simple ghost expressions. Keep broad surfaces and material variation; avoid detailed textures that disappear on phones.

First hero: one original pumpkin mesh with intact, cracked and exhausted states; separate stem, face/emissive insert and a small reusable set of rind fragments. Animate the hero, not an unchanging sphere wrapped in particles. First transformation preview: **Wisp Pumpkin**, pale cream body, cyan face, curled leaf fins. Later proposed **Bramble Pumpkin**, heavier ribs, vine crown and root accents. Each changes silhouette and spell behavior; exact progression and balance remain open.

Use one environment family for graves, fences, trees and lanterns. Free KayKit Halloween Bits is CC0 and includes 60+ raw models; candy, tractor, scarecrow and maze extras are paid and excluded. Kenney Graveyard is an alternative family, not an excuse to mix every kit. Custom hero, wand, transformation variants and shrine still require authored production models. Concept pictures do not supply these meshes.

The world should contain a patch, a visible nearby shop, one looping haunted garden with a fork, and a shared shrine. Foliage frames the path; it must not hide ghosts. A distant silhouette suggests future expansion. No vast empty terrain or elaborate castle before the core interaction is accepted.

## Animation, VFX, SFX and camera specification

All timings below are initial art-direction targets, subject to responsive in-engine testing.

| Beat | Model / animation | VFX | SFX / camera |
|---|---|---|---|
| Ripe pumpkin | Small squash, stem wiggle | Brief leaf accent, no constant sparkle fountain | Soft pluck cue within reach |
| Harvest | Crouch → tug → weight settles into arms | Vine snap and 2–3 leaves | Dry pop + low woody body; no shake |
| Awaken | Wand anticipation about 0.15–0.25s; face opens; pumpkin tips into motion | One rune, seed orbit converges, small directional wake | Rising airy whisper → friendly bell; camera stays playable |
| Guide | Pumpkin rolls at travel speed; stem lags turns; avatar arm tracks aim | Short tapered ribbon, ground direction cue | Quiet rolling texture, intermittent wand ticks; no constant camera shake |
| Ghost contact | Ghost squashes away; pumpkin compresses and sheds a fragment at meaningful thresholds | Small contact star, then warm wisp travels toward shrine | Rounded thunk + pitched ghost chirp; brief optional local impulse |
| Gust combination | Friend sweeps wand; readable ghost spiral, pumpkin visibly follows new route | Single lavender corkscrew and connected cyan/orange trail | Whoosh into two-note combo cue; names briefly identify both contributors |
| Crack warning | Shell panels separate slightly; face becomes strained | Emission in cracks, counted pulses rather than global glow | Readable ticks for remaining size-dependent charges; no full-screen red danger wash |
| Seedburst | Squash → split → rind falls → seeds arc outward | Clear directional result; clear most effects within about 0.7s | Woody crack + soft bass pop + seed patter; short local shake with reduction option |
| Payout | One readable result near action | Small gold arc into HUD; no swarm of labels | Brief rising coin motif, pitch variation bounded |
| Ascension | Pumpkin floats, old shell opens, new form settles and holds a hero pose | One orbit ring, shaped ribbons, controlled reveal; no whiteout | Three-note musical motif; optional 3–4s ceremony, replay skippable |

Effects have distance culling, local burst caps and a reduced setting. First measure concurrent spells on target mobile devices; do not assert an arbitrary particle cap proves performance. Limit prominent audio voices, attenuate distant casts, and duck ambience briefly during a local ascension. Music should be original or separately verified licensed audio; the impact pack alone is not a soundtrack or full magic sound set.

Camera follows the avatar with pumpkin and next choice visible. Avoid a cinematic lock during steering. Shake reinforces major contact only. UI: gold, current form and a small shared landmark indicator; context-sensitive Harvest/Cast, plus Burst when active. Reuse normal joystick/movement. Shop cards show current versus next effect, affordability and one purchase action. Safe areas and button sizes must be checked on a real phone viewport. Icons need a consistent authored family; do not ship generated text or icons cropped from these boards.

## Learn from references without copying blindly

The [2026-10-06 comparable-game review](GROWTH-COMPARABLES-20261006.md) studies Grow a Garden, Build the Pyramid and Bee Swarm Simulator as currently active references; Wacky Wizards and Ghost Simulator are historical/mechanical references with much smaller recent player snapshots. Official listing descriptions and dated tracker counters support the observations. No new footage was watched and no games were playtested in this pass. Borrow growth legibility, visible shared accomplishment and earned magical change selectively; do not merge seed commerce, strength training, bee management, potion recipes, pets and biome gates into the first loop. Popularity does not establish why a game succeeds or prove our adaptation will work.

Existing FAVORITES-INSPO.md reports 58 videos reviewed in a previous pass. This pass reread that analysis; it did not rewatch all 58. Browser inspection found the saved ClaudeimusMax collection now listed at 137 videos. No specifically named “good quality Roblox ideas” collection was verified in the inspected collection grid; do not claim that folder has been reviewed.

- Microbot assembly: small pieces converge into a coherent hero; apply to awakening seeds, not endless orbit clutter.
- Haymaker / authored attack examples: wind-up, contact, directional recovery; apply to burst and gust, rather than undifferentiated particle clouds.
- Moon Animator examples: poses and camera beats tell a story; apply to harvest and transformation while preserving control during normal play.
- Crate/chest reveals: isolate and hold the result; use for earned deterministic ascension, not random paid rewards.
- Halloween scene reference: cool environment and warm hero separation; do not flood the whole scene with bloom.
- AI game critiques: custom focal models and coherent UI matter, and empty-server play must still work. Attractive concept art is not proof of either.

For every newly studied example record: source, observation type, the concrete interaction or visual sequence, why it helps the player, our adaptation, and a test that could disprove it. Save short time-coded observations when playback is available. Judge adaptations in the actual game; views and polish alone do not establish that our loop is good.

## Foundation and next production gate

No verified free template currently matches this design. Reuse inspected saving, authoritative economy, input and build systems from this repository where they fit. A generic simulator template should not dictate the core verb. Raw CC0 art and verified sound assets can accelerate secondary content. Never insert a Creator Store model until its complete descendants are inspected and script-free.

Next implementation milestone, after direction selection: a shared public patch with owned automatically regrowing vines and an initially ready small crop, one pumpkin magic form in small and big sizes, a few simple ghost groups, movement-facing guide/automatic burst, chain seedbursts, one permanent gold growth upgrade, and one shrine that visibly changes. Giant remains a later preview. Then test two friends doing the loop together. Accept only if a new player understands it without explanation, guide works on touch, friends materially change the action, growth continues during outings, sizes change play visibly without camera obstruction, every state reads at gameplay distance, and solo is fun. Compare gold per minute for active harvesting and waiting before setting economy values. Static tests cannot satisfy these visual/fun gates.

No new rbxl is delivered for this design-only change. The existing Desktop PUMPKIN-TEST.rbxl still contains the prior prototype. Do not treat it as the magic concept. Build and provide a specific playtest route after the selected gameplay is implemented.

## Verified free source candidates

- https://kaylousberg.itch.io/halloween-bits — free-tier environment meshes; checked 2026-10-06.
- https://kenney.nl/assets/graveyard-kit — alternative environment vocabulary; earlier research, recheck at intake.
- https://kenney.nl/assets/particle-pack — 80 CC0 512px sprites; checked 2026-10-06; adapt to our motif.
- https://kenney.nl/assets/impact-sounds — 130 CC0 audio files; checked 2026-10-06; base foley, not a complete magic sound set.

Illustrations are design proposals, not screenshots, implemented features, performance evidence or free-pack contents. Written specification governs where generated details disagree.
