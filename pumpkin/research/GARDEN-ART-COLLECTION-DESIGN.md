# Pumpkin garden, forms and effects — proposal, 2026-10-06

Status: design review only. This extends [the magic direction](MAGIC-DIRECTION-PROPOSAL.md) and [growth comparison](GROWTH-COMPARABLES-20261006.md). No gameplay, models, builds or timings below are implemented or accepted. Keep **grow → harvest → awaken → guide → burst → earn gold → grow bigger**. There are no catapults, required watering, recipes, pets or imported minigames. Forms add variety later; they must not delay proving the simple loop.

Illustrations: [garden composition](concepts/garden-layout-v1.png), [pumpkin form models](concepts/pumpkin-forms-v2.png), and [effects storyboard](concepts/magic-effects-v1.png). These are visual proposals, not a measured level plan or production assets. The garden board includes later foliage, pond and restoration stages; first-slice scenery is reduced. Its shop signage mentioning seeds does not add seed buying to the proposed loop. Path widths, tree placement and planting boundaries must be authored around actual small/big pumpkin clearance, with wider open spaces for later giants. Decorative fences cannot split friends or constrain rolling. The effect board shows pose and state order, not tested effect counts, exact shapes or audio playback. The form board's first generated size-comparison strip was inaccurate and was removed in v2. Wisp and Harvest King's illustrated cracked states remain too subtle for gameplay: production shells need wider openings, displaced panels and countable light pulses tested at phone distance.

## What is actually in the garden?

Build a compact shared Halloween place with three visible destinations: your growing patch, a short haunted outing and the lantern shrine. From the patch, a player should see the shop and the first ghost opportunity. A winding return path brings friends back together. Use layered silhouettes and purposeful props instead of a large empty floor or repeated private lanes.

Owned vines sit beside one another in a public patch. Start with a ready small pumpkin and another visibly growing crop; ownership is readable without fencing friends apart. A smiling scarecrow caretaker points toward the next useful destination. It is an animated landmark, not a quest giver with another menu. The shop is a modeled canvas stall with chunky wooden posts, stitched canopy and an actual small/big pumpkin comparison. Its first purchase is **GROW BIGGER**; a later form display can occupy the same stall.

The **Haunted Orchard** is one looping path with a short fork. Ghosts peek from a crooked lantern tree, a tipped wheelbarrow and a barrel. These modeled props animate a reveal so targets appear to inhabit the garden. Broad gaps preserve steering, target visibility and room for friends; roots frame the route and gently deflect rather than punish. A small pond and oversized mushrooms add reflections, color and atmosphere only. They introduce no fishing, gathering or separate currencies.

Freed wisps travel toward a shared lantern shrine. Its proposed stages are **lantern lit → garland returns → festival awakens**: one central lantern lights; a visible garland rises around its frame; small ghost residents and a canopy complete the silhouette. Contribution happens automatically through existing actions. A solo player can complete a small stage, and friends see who helped. Larger village restoration is a later possibility, not content required now.

| Garden model | Purpose / animation | VFX / SFX | Priority |
|---|---|---|---|
| Vine, leaf and soil mound | Show owned crop growth; stem stretches, leaves open, pumpkin swells | Brief ripe leaf flick / dry pluck | Initial slice |
| Scarecrow caretaker | Orient arrivals; friendly head turn and pointing pose | Small lantern blink / cloth creak | Initial, simple pose first |
| Canvas growth stall | Make one upgrade concrete; hanging sign rocks and preview changes | Contained purchase sparkle / woody bell | Initial slice |
| Lantern tree and barrel | Frame readable ghost groups; branch sway, lid lift before reveal | Local cool wisp / hollow knock | Initial; one reveal family first |
| Wheelbarrow | Give another ghost group a distinct home; wheel wobble | Brief dust puff / squeak | Later dressing |
| Shrine, garland and canopy | Shared visible accomplishment; stage-specific silhouette change | Wisps converge, lamps light in order / short shared chord | Initial shrine; richer stages later |
| Pond, mushroom clusters, fence | Frame route without narrowing it; subtle water/foliage motion | Low localized mist / quiet ambience | Later polish |

These are authored prop briefs, not a shopping list of free assets. Custom hero meshes, shop and shrine establish identity. Verified licensed raw kits may supply secondary fence/grave vocabulary after palette, scale and material cleanup; they cannot replace the focal models or provide scripted systems.

Source checks on October 6 found [KayKit Halloween Bits](https://kaylousberg.itch.io/halloween-bits) offering 60+ free CC0 raw models; its paid candy, tractor, scarecrow and maze extras are excluded. Alternatives/support include [Kenney Graveyard](https://kenney.nl/assets/graveyard-kit) (90 CC0 models), [Particle Pack](https://kenney.nl/assets/particle-pack) (80 CC0 sprites) and [Impact Sounds](https://kenney.nl/assets/impact-sounds) (130 CC0 sounds). These counts do not establish that our wheelbarrow, hero forms or shrine exist in those packs. Inspect exact contents before adoption; author signature meshes and verify any additional audio separately.

## Collection: rarity describes a form, size describes growth

Keep two readable axes: **size + form**. Rarity is a label on the form, not a third stat, extra mutation roll or hidden luck system. Every form can eventually be small, big or giant. Initial gameplay proves only Classic Jack in small and big sizes; giant stays a preview until camera, performance and fairness pass.

Proposed unlocks use earned gold and visible personal milestones, with requirements shown before purchase. No paid chance, gacha, compulsory party, overnight waiting requirement or seasonal deadline is proposed. Exact prices and milestones require economy tests. Halloween identity can remain available beyond an event; returning should feel inviting rather than coerced.

| Proposed form / rarity | Model example and material | How the existing action changes | Release order |
|---|---|---|---|
| **Classic Jack — Common** | Broad orange ribs, oversized curled stem, warm carved grin; satin shell and dark face recess | Familiar contact charges end in the directional seedburst taught at arrival. | Initial hero |
| **Wisp — Rare** | Pale cream shell, cyan face, curled leaf fins; solid body with a translucent fin accent | A short delayed echo follows the final burst along its direction, reaching ghosts just beyond the first arc without another input. | First later collection proof |
| **Bramble — Epic** | Deep green/orange rib pattern, chunky vine crown and flexible/retracting root accents that preserve rolling clearance; rougher shell with bright crack seams | Contact briefly gathers a bounded nearby ghost group toward the pumpkin, creating a clear route opportunity for you or a friend. | Later concept |
| **Harvest King — Legendary** | Orange/cream shell, broad leaf crown, restrained gold trim, confident face; satin body and small metallic accents | An occasional clearly signaled wide burst covers an extra nearby group while ordinary outings retain the same controls. | Later concept |

These behaviors are distinct hypotheses, not balanced abilities or a promise that rare always earns more per minute. Wisp's echo must not obscure the first result; Bramble must not pull every target away from newcomers; Harvest King's frequency and reach need bounds. Shared contribution credit includes useful support, rather than awarding everything to the final hit. No form adds another mandatory button.

Model each form in intact, cracked and burst states. Keep the face readable as cracks open; attach rind fragments to the rib pattern instead of exploding a generic sphere. Preserve form identity across sizes through stem, crown and face proportion. Giant enlarges the character, not every particle or crown until it fills the screen. An optional witch hat, wand or cape can support the fantasy without forcing an avatar costume.

## Effects that explain what happened

The pumpkin's pose leads the effect: anticipate, make contact, show a directional result, clear. Warm rind and gold contrast with cool ghosts and spells. Use shape, readable text and motion as well as color for rarity. Mist stays near scenery; bloom stays concentrated around meaningful changes. Epic forms do not continuously fill the garden with particles.

All times are proposed authoring targets, subject to responsiveness tests.

| Beat | Model / animation example | VFX and sound example |
|---|---|---|
| Growth | Smooth rib expansion, stem uncurl, leaf opening; brief ripe settle | One leaf accent and soft pluck; no permanent sparkle fountain |
| Harvest | About 0.4–0.7s crouch/tug/weight settle; larger crop uses a wand tether | Vine snap, two or three leaves, low woody pop |
| Awakening | About 0.15–0.25s anticipation; face opens and shell tips forward | Seeds converge into one rune, short directional wake, whisper into friendly bell |
| Ghost reveal | About 0.3–0.5s barrel lid/tree reaction; ghost peeks then presents its face | Local wisp curl and hollow knock; target reads before contact |
| Contact | Quick shell squash and ghost recoil; meaningful charge loss opens a crack | One shaped star, warm wisp toward shrine, rounded thunk and ghost chirp |
| Crack → burst | Countable seam pulses; squash, split, falling rind; major effect clears in about 0.7s | Directional seed arcs, woody crack, soft bass pop and seed patter |
| Friend chain | Existing bursts connect; neither player loses control of their pumpkin | One connecting rune, wider seed arc, two-note cue and brief contributor names |
| Rare-form reveal | Isolate the unlocked model and hold its silhouette, about 1–2s | Leaf-fin/crown-shaped accent, explicit form and rarity text, distinct short motif |
| Ascension | Optional 3–4s float, old shell opening, new form settling; repeat ceremony skippable | One orbit ring and controlled ribbons, three-note motif; no whiteout |

Rarity reveal is the presentation of a deterministic unlock, not a surprise roll. Normal steering keeps the avatar, pumpkin and next ghost visible; cinematic framing belongs only to optional transformation. Reduce shake and effects, attenuate distant sounds and limit overlapping prominent audio. Profile simultaneous small/big pumpkins, chains, shrine arrivals and later giant effects on target phones: record frame time, effect overdraw, camera obstruction, physics stability and replication behavior. No unmeasured particle count or invented device budget constitutes a pass.

## Recent Halloween references: observed lessons and limits

The current official [Adopt Me Ghost Gallery notes, October 3, 2026](https://www.playadopt.me/news/halloween-ghost-gallery-notes) describe haunted furniture, ghosts, a boss, Manor/Crypt spaces and four collectible silhouettes. A visually inspected official promotional header uses broad expressive faces, round dark glossy eyes, warm/cool character contrast, and distinct jester-dragon crown, ghost translucence and mummy-wrap silhouettes. Adapt the *legibility*: Jack's ribs, Wisp's fins and Bramble's crown should identify them at gameplay distance. This was a promotional still, not observed animated VFX or a playtest.

The official [Monster Mansion notes, September 25, 2026](https://www.playadopt.me/news/monster-mansion-notes) supply a current animated-house/spooky-furniture fantasy reference. Translate that idea into one barrel or tree reacting before a ghost appears, not a mansion minigame. The [Where Bear return notes, October 24, 2025](https://www.playadopt.me/news/halloween-where-bear-return-notes) describe creator-observed cooperation against Patchy changing server/chat behavior. This is historical qualitative testimony, not measured retention or proof that our chain burst works.

Unreleased or unverified Halloween updates are excluded from the visual reference bar. A search-index result for Fisch exposed an event schedule that the independent review could not reproduce in the live listing; that schedule is not relied upon here. These references are useful current/historical candidates, not an evidence-backed ranking of “winning” Halloween effects. Popularity alone cannot identify which visual choice caused success.

For broader historical context, Roblox's official [Halloween Spotlight, October 23, 2025](https://about.roblox.com/en-nz/newsroom/2025/10/halloween-spotlight) lists Adopt Me's transformed island, minigames and pets; Dress To Impress's Halloween clothes, runway effects and story quest; Restaurant Tycoon 3's seasonal food and spooky furniture; and PETAPETA's monster/pumpkin collection. This is a 2025 editorial listing, not a 2026 event, visual review or performance comparison. Our inference is to carry Halloween through the existing loop's objects, setting and feedback: animate haunted props and make pumpkin forms expressive, rather than importing those games' unrelated minigames.

The previously reviewed [TikTok inspiration analysis](FAVORITES-INSPO.md) offers sequence examples: hand microbots converge into a coherent shape; Haymaker uses anticipation/contact/directional recovery; pose-driven attacks make arcs follow authored motion; reward reveals isolate a result. Apply those to awakening, cracking and earned ascension. This pass reused the written analysis, without newly watching those clips. Older catapult-specific recommendations there do not govern this garden.

## Overall game review and production order

The proposal has a clear noun, visible growth goal and short repeatable action. Return motivation is seeing a bigger crop, earning the next distinct form and finishing a shared garden stage. Its main unresolved risks are companion steering feeling like babysitting, waiting outperforming active play, forms reading as cosmetic multipliers, and shared shrine progress hiding independent solo chores. Neither research nor attractive concepts settles them.

Historical `art/map-wide-night.jpg` and `art/play-roll.jpg` were visually inspected in this review. The first shows a broad flat dark-green platform, repeated bright neon wall lanes and sparse pumpkin props; the second shows a featureless orange ball with a large HUD and wall numbers dominating the view. They illustrate the old presentation gap: authored focal models, compact purposeful space and restrained UI are needed. These captures are **not** evidence of the current magic build or new runtime fun.

Today's source inspection also shows the rejected prototype remains in code. This is a source-level assessment, not a fresh runtime test:

| Current evidence | Proposed target / gap |
|---|---|
| Configuration still names `Pumpkin Roll` and sets `GameplayMode = 'Coop'`; `Coop.server` iterates `scene.launchers` | Remove the launcher premise when implementation is authorized; deliver the owned-vine magic loop. A Coop label does not establish useful cooperation. |
| Shop prompt still offers “bigger pumpkins or stronger launches” | One visible **GROW BIGGER** crop upgrade; no launch upgrade in the target. |
| Current wave/counter structure uses static ghost targets | Authored prop reveals, readable living-pumpkin contacts and explicit friend chain contribution need implementation and testing. |
| No implemented target evidence for owned vines, spell guidance, earned rarity forms or animated haunted props | The design and concept boards describe future work; they do not establish these systems exist. |

Build one art-complete slice first: Classic Jack small/big, owned vines, one growth purchase, readable ghost reveal, automatic burst/Recall, friend chain and one shrine. Then test Wisp as the first earned collection change. Bramble, Harvest King, giant physics and richer scenery follow only after that proves worthwhile.

Acceptance requires a newcomer understanding the loop unaided; touch guidance and camera staying comfortable; visible crop growth during outings; active small/mixed-size play remaining worthwhile against idle waiting; two friends intentionally repeating a chain and recognizing support credit; and small pumpkins remaining useful beside larger ones. Solo must work immediately. Record actual play and performance evidence before claiming this is a good game. No new runtime evidence or magic-game build is delivered by this design review.
