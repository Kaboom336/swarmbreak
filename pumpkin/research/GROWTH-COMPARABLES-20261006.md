# Pumpkin growth and comparable games — 2026-10-06

Status: research-informed design proposal, not an approved implementation. The user asked for other popular games with a similar idea, our own twist/style, and pumpkins that grow to different sizes. Keep the basic game simple: Halloween magic, harvest, gold, earned form ascension and shared friend play; no catapults. This document supports [the magic direction proposal](MAGIC-DIRECTION-PROPOSAL.md) and supersedes older growth suggestions only within that proposed direction. No code or gameplay has changed.

The [new growth board](concepts/magic-growth-v2.png) illustrates small, big and giant proportions; these are not fixed world dimensions. Water/plant labels suggest later optional gardening, while the proposed first slice has automatic vines and no mandatory watering or planting menu. Magical forms remain distinct from size and may later change spell behavior.

## Evidence and limits

The review used official Roblox listing descriptions and Rolimon's public counter snapshots checked on 2026-10-06. The Wacky Wizards tracker result was crawled last week; Ghost Simulator's was crawled yesterday. Those two counts are not simultaneous with today's three active references. Counters fluctuate, visits are cumulative and neither metric explains retention, earnings or causality. No new gameplay footage was watched and no current in-game playtests were performed. Interaction descriptions below reflect what creators advertise; proposed strengths, risks and adaptations are design hypotheses.

| Reference | Source-grounded loop | Dated popularity context |
|---|---|---|
| Grow a Garden | Buy seeds, plant, grow, harvest for profit, show finds to friends; listing advertises offline growth. [Official listing](https://www.roblox.com/games/126884695634066) | 13,678 players; 35.959 billion visits in today's [tracker snapshot](https://www.rolimons.com/game/126884695634066). Currently active growth reference. |
| Build the Pyramid | Collect and carry blocks, build together in a shared server, train speed/strength and complete the pyramid. [Official listing](https://www.roblox.com/games/123720558354386) | 14,772 players; 30.775 million visits in today's [tracker snapshot](https://www.rolimons.com/game/123720558354386). Currently active shared-building reference. |
| Bee Swarm Simulator | Collect pollen, make honey, collect bees with distinct traits, do quests and unlock more of the mountain. [Official listing](https://www.roblox.com/games/1537690962) | 23,489 players; 4.593 billion visits in today's [tracker snapshot](https://www.rolimons.com/game/1537690962). Currently active collection/progression reference. |
| Wacky Wizards | Combine ingredients, brew and drink potions with different visible effects; more ingredients can strengthen a potion. [Official listing](https://www.roblox.com/games/6888253864) | 485 players; 1.016 billion visits; recorded all-time peak 144,073 in the [tracker result crawled last week](https://www.rolimons.com/game/6888253864). Historical magic reference, not evidence of a current leading game. |
| Ghost Simulator | Capture ghosts, upgrade equipment, acquire pets, encounter bosses and biomes. [Official listing](https://www.roblox.com/games/2685347741) | 26 players; 142.211 million visits in the [tracker result crawled yesterday](https://www.rolimons.com/game/2685347741). Historical Halloween-adjacent progression reference. |

## What each comparison changes

### Grow a Garden: growth as a visible reason to return

The advertised loop makes an understandable object change over time and connects harvesting to profit and showing friends. Hypothesis: seeing a crop get bigger can make progress legible without teaching another control. Risk for Pumpkin: timers can turn the session into passive waiting, and harvesting alone does not provide our magical action.

Borrow automatic visible regrowth and a harvest-now-or-grow-bigger decision. Our adaptation is a personal vine in a shared patch, with another crop growing while the player guides an awakened pumpkin through ghosts. Exclude required seed commerce, extensive planting menus, copied rare-mutation lists and a first-session offline-growth promise. Test whether players notice growth after an outing, understand ownership and choose between small and big without explanation. Compare gold per minute while actively harvesting versus idling for size; a waiting strategy that overwhelms active play falsifies the proposed balance.

### Build the Pyramid: a shared result everyone can see

The official pitch places repeated collection/carrying inside shared construction. Hypothesis: a changing landmark makes another player's contribution concrete. Risk: a shared progress meter can conceal repetitive independent chores; its existence alone does not prove friends change the action.

Borrow a shrine that visibly lights and changes as freed wisps arrive. Our active social twist is chain seedbursts: nearby bursts connect and reach another ghost group, so friends can intentionally coordinate using their existing action. Exclude block carrying, strength training and a massive construction project. Test whether two friends can explain who helped, deliberately repeat a chain and care about the shrine's changed silhouette. If they only perform separate loops near each other, revise cooperation before adding a larger village.

### Bee Swarm Simulator: a clear repeatable verb with later depth

The official progression connects pollen/honey to bees, quests and new areas. Hypothesis: depth can sit behind a familiar repeated action and visible companions. Risk: stacking collections, currencies, quests and gates immediately would obscure Pumpkin's first loop.

Borrow the separation between a simple core action and later earned variety. Pumpkin keeps one gold currency and adds deterministic magic forms later, with a visible before/after requirement. Exclude a swarm roster, pet economy, mountain-gate clone and compulsory quest checklist in the first slice. Test whether a player can name the current goal and next improvement without opening multiple menus. A new form should visibly change a useful spell behavior, not merely its multiplier.

### Wacky Wizards: magic must produce a readable change

The advertised ingredient-to-potion loop promises different visible outcomes. Hypothesis: transformation is a strong payoff when the result is immediately recognizable. Risk: recipe experimentation and station work become another game; mixing that structure into guiding pumpkins would complicate controls and pacing.

Borrow a short authored magical reveal and distinctive form silhouettes. Keep Wisp and Bramble as deterministic earned form proposals, separate from physical size. Exclude ingredient combinations and cauldron waits from Living Pumpkin Spells. Cauldron Crew remains an alternative direction, not an approved feature bundle. Test whether players distinguish a size increase from a magical ascension at ordinary gameplay distance, with sound disabled.

### Ghost Simulator: thematic targets and understandable equipment progress

The listing ties ghost capture to equipment, pets, bosses and biomes. Hypothesis: friendly mischievous ghosts make the reward verb fit a Halloween world. Risk: merely reskinning a capture simulator supplies theme but little distinctive play, while copying all later systems overwhelms the opening.

Borrow clear ghost targets and a compact haunted setting. Our twist is the growing physical pumpkin that takes contacts, cracks, bursts and combines with a friend's magic. Exclude vacuum equipment, a pet roster, boss gates and many biomes in the first slice. Test whether a new player describes the action as growing and guiding a living pumpkin; if they only describe generic collection, improve the pumpkin's visible state and movement feedback.

## Proposed growth loop and our own style

**Grow → harvest → awaken → guide → burst → earn gold → improve growth**, with shared wisps lighting a nearby shrine. An initially ready small crop avoids starting with a wait. Owned vines regrow automatically inside the same public patch. An outing gives another crop time to grow; an available small pumpkin supports another immediate outing while one is left to get big. No mandatory clicking to grow, seed menu or extra energy currency.

One permanent gold growth upgrade labeled **GROW BIGGER** raises attainable size and growth pace, shown through the vine and a before/after pumpkin preview. It must produce a noticeable next crop, not an opaque percentage. Size is independent of earned deterministic magic form: ordinary, Wisp and later Bramble forms can each exist at different sizes. Form ascension follows later. Do not add a recipe tree, pet collection and a new resource to make progression seem deeper.

| Proposed size | Readable effect | First-slice treatment |
|---|---|---|
| Small — roughly waist height | Tight contact footprint, a few visible shell charges, compact seedburst, nimble-looking roll | Initial harvest-ready crop; three charges is a tuning example. |
| Big — roughly avatar height | Larger footprint, more shell capacity, wider burst, heavier settle and stem lag | Reachable through the single growth upgrade; responsive steering and comfortable avatar speed stay essential. |
| Giant — roughly three avatar heights | Spectacular silhouette and heavier motion; bounded reach and effects | Later preview only until physics, phone readability, camera and authority are tested. |

These proportions are conceptual rather than fixed Roblox dimensions. Growth changes silhouette and play; form ascension changes magical identity and behavior. Chunky pumpkin ribs, expressive carved faces, curled stems, warm orange shells and cool violet/teal surroundings keep the result unmistakably Halloween. Size-dependent cracks and a clear directional seed arc carry information without a screen full of labels. Do not slow the avatar annoyingly to sell weight or let a large pumpkin block the camera.

Giant introduces physical stability, replication and mobile performance risks. Cap size and contact reach; separate visual presentation from server-authoritative interactions and rewards when implementation begins. Prevent oversized effects from stealing targets/credit or obstructing newcomers. Players cannot harvest another person's vines, shove their pumpkin or force their burst. Shared goals and contribution rewards should invite cooperation without compulsory roles or passive nearby gold.

## Smallest meaningful test

Propose one public patch with owned regrowing vines; an initially ready small crop; small and big versions of one magic form; movement-facing guidance, Recall and automatic exhaustion burst; optional early Burst; one gold growth upgrade; chain bursts; and one visibly changing shrine. No catapults or additional compulsory inputs. Giant remains a silhouette preview and all three direction alternatives remain unapproved.

Test a new solo player and two friends on touch controls. Record comprehension, crop choice, outing time, first upgrade time, gold per minute for active versus waiting strategies, intentional chain repeats, camera obstruction and frame/network behavior. A short first-three-minute scenario is in the [direction proposal](MAGIC-DIRECTION-PROPOSAL.md); it is a hypothesis to validate, not delivered gameplay. Accept growth only if players see and value getting bigger while active outings remain worthwhile. Accept cooperation only if friends intentionally change each other's successful action and recognize their shared result. Research counters and attractive concept art cannot pass those gates.
