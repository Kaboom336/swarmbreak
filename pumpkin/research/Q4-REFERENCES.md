# Q4-R references: Roblox downhill, rolling, and simulator research

Research checked 2026-10-05. This is a design-reference pass, not a claim that all five experiences are simultaneously on Roblox's front page. Roblox's live Trending chart says it reflects experiences where players have spent more time over the preceding two weeks ([Roblox Trending](https://www.roblox.com/charts/top-trending)). At the time of research, third-party live tracking placed **Break and Steal an Egg** at #10 by concurrent players ([TrendingBlox snapshot](https://www.trendingblox.com/)), while Roblox's localized listing showed **+1 Stone Skipping** at 31,545 active and 12.8M+ visits ([Roblox listing](https://www.roblox.com/de/games/111543903102439/1-Stone-Skipping?gameSearchSessionInfo=9bd3c41a-05f3-4a24-b9d9-a82ff6eebb8b&isAd=false&nativeAdData=&numberOfLoadedTiles=120&page=searchPage&placeId=111543903102439&position=1&universeId=10765298801)). Those two supply the current simulator/chart pattern. The other three are high-visit roll/slide references selected for their rider, course, and feedback design; they are not represented here as current chart leaders.

Evidence rules used below:

- `Verified` means the detail appears on the current Roblox listing, a dated Roblox/Fandom wiki, a linked gameplay video, or a current article.
- `Observed` means a visual detail can be seen in linked media, but the developer has not documented it.
- `unverified` means no reliable online source found during this pass supported the detail. Exact colour values are necessarily approximate visual samples unless the developer publishes a style guide.
- Search included the exact title's Roblox page, exact-title wiki/Fandom results, and exact-title gameplay-video/article results for every game. When no exact-title wiki or current gameplay source was found, that absence is stated rather than filled by a similarly named game.

## 1. +1 Stone Skipping — current incremental-simulator reference

Sources: [current Roblox game page](https://www.roblox.com/games/111543903102439/1-Stone-Skipping), [independent fan wiki/guide based on gameplay footage](https://stoneskipping.wiki/), [second current fan wiki/guide](https://stoneskippingguide.wiki/), and [October 2026 update article](https://rouniverse.com/articles/1-stone-skipping-updates/). The official page identifies Meow Labs and describes the bounce, Skill, Wins, pet, throwable, and rebirth loop. The first guide dates its gameplay observations to 2026-09-26 and its live-data check to 2026-10-01.

- **How the player rides:** The avatar does not ride. The avatar stands at a water lane and throws a stone or novelty object. Each bounce awards +1 Skill; better stones, pets, levels, and rebirths extend the throw. Verified by the [Roblox description](https://www.roblox.com/games/111543903102439/1-Stone-Skipping) and [fan guide](https://stoneskipping.wiki/). Any temporary camera attachment to the projectile is **unverified**.
- **Camera:** A standard avatar view before the throw is visible in promotional/gameplay imagery; the exact throw-camera logic, offsets, FOV, and whether the camera follows the stone are **unverified**.
- **Speed:** Exact stone speed in studs/s is **unverified**. Online sources describe longer throws and more bounces, not velocity telemetry.
- **Obstacle and dodge design:** There is no verified lane-dodging obstacle layer. The skill test is progression distance across sequential themed water zones—Palm Beach, Cactus Desert, Autumn Woods, Mushroom Marsh, and Frost Lake were observed by the [fan guide](https://stoneskipping.wiki/). That makes it a useful progression reference, not a dodge reference.
- **Combo rules:** This is a persistent incremental chain rather than an execution combo: every bounce gives +1 Skill, Skill raises levels, levels raise a global multiplier, farther zones award Wins, and rebirth increases future progress. A guide observed level multipliers from ×1.1 to ×111, but those live values may change ([guide](https://stoneskipping.wiki/)). There is no verified miss/reset/cap combo.
- **UI palette:** Approximate visual read from current promotional imagery: water cyan `#16C9E8`, grass/lime `#72EB45`, reward yellow `#FFD43B`, panel navy `#17243A`, white `#FFFFFF`. Exact hex values are **unverified**. The important pattern is bright environment colour, large stat counters, a persistent level/progress bar, `+1` bounce pop-ups, and clearly separated Shop/Gifts/Rebirth affordances ([current wiki imagery and HUD discussion](https://stoneskippingguide.wiki/)).
- **Map enclosure:** Open, long water lanes divided into themed zones. Walls, canyons, tunnels, banking, and containment rails are **unverified**.
- **Particle and sound juice:** `+1` pop-ups on bounces are visible in the [wiki imagery](https://stoneskippingguide.wiki/). Splash/ripple particles, bounce pitch variation, impact sound layering, and camera shake are **unverified**.

**Takeaway for Pumpkin:** Copy the one-action readability and immediate per-event number pop, not the passive straight-line play. A clean dodge in Pumpkin should read as instantly as one bounce here, while still requiring steering.

## 2. Break and Steal an Egg — current chart/collection-loop reference

Sources: [current Roblox game page](https://www.roblox.com/games/114326934417838/Break-and-Steal-an-Egg), [dated fan wiki and beginner route](https://break-and-steal-an-egg-roblox.wiki/), [BemmyBlox gameplay video](https://www.youtube.com/watch?v=uT5R6PyMrQg), [current stats/chart record](https://www.rotrends.com/game/10765288803/Break-and-Steal-an-Egg), and [current overview article](https://toptrending.games/games/break-and-steal-an-egg/). The current official description establishes the break → hatch → steal/escape → place in base → earn cash loop.

- **How the player rides:** No vehicle. The visible avatar moves on foot and carries/collects the hatched animal back to a base. The official text says to steal animals and escape guards; the fan guide describes the animal pickup and return route ([Roblox](https://www.roblox.com/games/114326934417838/Break-and-Steal-an-Egg), [guide](https://break-and-steal-an-egg-roblox.wiki/)). The exact hand/arm attachment is **unverified**.
- **Camera:** Third-person avatar camera is visible in the [gameplay video](https://www.youtube.com/watch?v=uT5R6PyMrQg). Exact offset, FOV, camera collision, and chase-state changes are **unverified**.
- **Speed:** Exact movement speed in studs/s is **unverified**. The Roblox listing confirms speed upgrades, and the fan wiki notes that direct speed upgrades were replaced by trails and later supplemented by a treadmill, but publishes no trustworthy movement telemetry ([fan wiki](https://break-and-steal-an-egg-roblox.wiki/)).
- **Obstacle and dodge design:** The dynamic obstacle is pursuit: after a successful break and pickup, guards threaten the return to base. Route planning, knowing the base landmark, and choosing an achievable egg create risk without a formal race lane. This is verified by the [official description](https://www.roblox.com/games/114326934417838/Break-and-Steal-an-Egg) and [beginner guide](https://break-and-steal-an-egg-roblox.wiki/). Guardian hit boxes and exact failure penalties are **unverified**.
- **Combo rules:** No moment-to-moment combo meter or clean-dodge multiplier was verified. The retention chain is economic: break, secure, escape, bank, upgrade, repeat. Satchel capacity allows larger runs, but exact stacking bonuses are **unverified**.
- **UI palette:** Approximate visual read from current key art/gameplay: electric blue `#27C7FF`, egg yellow `#FFD63D`, hot pink `#FF48A8`, grass green `#53D769`, ink `#181522`, white `#FFFFFF`. Exact hex values are **unverified**. Strong silhouettes, large egg/animal models, overhead prompts, cash feedback, and bright rarity presentation make each outcome legible.
- **Map enclosure:** A base-and-biome hub with guarded collection areas is supported by the [gameplay guide](https://break-and-steal-an-egg-roblox.wiki/). A fully enclosed chute, 12-stud walls, canyon, tunnel, or banked course is **unverified**.
- **Particle and sound juice:** Egg-breaking, hatch reveal, pickup, and cash-in provide four natural feedback beats in the [gameplay video](https://www.youtube.com/watch?v=uT5R6PyMrQg). The game also exposes a soundtrack panel with three classical tracks according to a [current fan wiki](https://breakstealegg.wiki/). Exact particles, sound IDs, pitch rules, screen shake, and hit effects are **unverified**.

**Takeaway for Pumpkin:** Give every run a readable chain of states and make the danger start after commitment. The Pumpkin equivalent is launch → build speed → dodge/pick up → preserve combo → cash out, with a large consequence pop when the chain breaks.

## 3. Get Fat And Roll Race — avatar-as-projectile downhill reference

Sources: [current Roblox game page](https://www.roblox.com/games/14494334042/Get-Fat-And-Roll-Race), [gameplay video](https://www.youtube.com/watch?v=4-jSDYpBANo), [current game overview and image page](https://allroblox.com/en/game/get-fat-and-roll-race/), and [developer-forum discussion describing the game as a giant-slide distance race](https://devforum.roblox.com/t/how-would-i-go-about-making-a-simulator-race-system/3318738). No reliable exact-title Roblox Wiki/Fandom page was found; wiki-only details are therefore **unverified**.

- **How the player rides:** The avatar itself grows from eating and then rolls down the hill; it is neither seated nor inside a separate ball. The official page says weight makes the player roll faster, and the [gameplay video](https://www.youtube.com/watch?v=4-jSDYpBANo) describes eating, becoming very large, then rolling downhill for money.
- **Camera:** Observed third-person chase view that keeps the growing/rolling avatar centered in [gameplay footage](https://www.youtube.com/watch?v=4-jSDYpBANo). Exact offset, FOV curve, banking, and collision behaviour are **unverified**.
- **Speed:** Exact roll speed in studs/s is **unverified**. The official page only confirms relative effects: more weight rolls faster and Premium grants +10% roll speed ([Roblox](https://www.roblox.com/games/14494334042/Get-Fat-And-Roll-Race)).
- **Obstacle and dodge design:** The verified goal is maximum distance, not clean dodges. Food collection and pets happen before the descent; the hill tests accumulated size and speed. Specific downhill hazards, lane rules, and fair openings are **unverified**.
- **Combo rules:** No clean-dodge combo is verified. The macro chain is eat → grow → roll → earn → improve pets/collection → roll farther. The visible body-size change acts as an embodied progress meter ([overview](https://allroblox.com/en/game/get-fat-and-roll-race/)).
- **UI palette:** Approximate visual read from current listing/media: lime `#76E84A`, orange `#FF8A24`, cyan `#26C8ED`, purple `#8B55F6`, reward yellow `#FFE044`, white `#FFFFFF`. Exact hex values are **unverified**. Colour is used at toy-like saturation, with scale change and distance as the primary read.
- **Map enclosure:** A broad giant hill/slide and themed unlock zones are supported by the [overview](https://allroblox.com/en/game/get-fat-and-roll-race/), which lists Italy, Japan, and Mexico zone badges. Canyon walls, tunnels, and continuous high side walls are **unverified**; the reference reads as open rather than claustrophobic.
- **Particle and sound juice:** Visible scale growth is verified by gameplay. Food pickup bursts, currency trails, rolling dust, wind layers, impact sounds, camera shake, and speed lines are **unverified**.

**Takeaway for Pumpkin:** The vehicle's physical state should make progress visible without reading UI. Pumpkin rotation rate, ground contact, speed lines, and a widening chase FOV can supply the same embodied payoff while keeping the avatar safely inside.

## 4. Ride a Box Down a Slide! — seated/loose-container slide reference

Primary title selected: the Ride a Box Fans revival, because it has 118M+ visits and explicitly identifies itself as a revival of Avilius's original. Sources: [current Roblox page](https://www.roblox.com/games/6999691637/Ride-a-Box-Down-a-Slide), [current stats page](https://www.rolimons.com/game/6999691637), [Fandom page for the original Ride a Box Down Stuff loop](https://goingto2014-roblox.fandom.com/wiki/Ride_a_Box_Down_Stuff%21), and [gameplay video](https://www.youtube.com/watch?v=pm0uwYs2Nzw). For a more recent same-genre implementation, the [Awesome Slide Games listing](https://www.roblox.com/games/14777367640/Ride-A-Box-Down-A-Slide) explicitly advertises rocks, ramps, balance, and speed.

- **How the player rides:** The player spawns a box and rides down the slide in/on it. The Fandom page says players can choose different boxes and the only goal is reaching the end; the recent listing calls it a “box-sled” ([Fandom](https://goingto2014-roblox.fandom.com/wiki/Ride_a_Box_Down_Stuff%21), [Roblox variant](https://www.roblox.com/games/14777367640/Ride-A-Box-Down-A-Slide)). Whether the revival uses a locked Seat, WeldConstraint, or loose physics contact is **unverified**. Footage showing face-plants makes loose ejection part of the genre's comedy, not a suitable Pumpkin requirement ([video](https://www.youtube.com/watch?v=pm0uwYs2Nzw)).
- **Camera:** Observed standard third-person chase camera in the [gameplay video](https://www.youtube.com/watch?v=pm0uwYs2Nzw). Exact offset, FOV response, roll damping, and collision are **unverified**.
- **Speed:** Exact box speed in studs/s is **unverified**.
- **Obstacle and dodge design:** A current variant explicitly names rocks to avoid, ramps for tricks, maintaining stability, and staying fast ([Roblox variant](https://www.roblox.com/games/14777367640/Ride-A-Box-Down-A-Slide)). Exact obstacle spacing, moving hazards, damage, deterministic layouts, and guaranteed free lanes are **unverified**.
- **Combo rules:** No combo or multiplier was verified. The verified success condition is simply reaching the end/winning ([Fandom](https://goingto2014-roblox.fandom.com/wiki/Ride_a_Box_Down_Stuff%21)).
- **UI palette:** Approximate visual read: rainbow red `#F04444`, orange `#FF8B2B`, yellow `#FFD83D`, green `#45D66B`, blue `#369AF5`, purple `#8E55DF`. Exact hex values are **unverified**. The slide itself provides the palette; the UI is secondary.
- **Map enclosure:** A long slide with set-piece “stuff” is verified at the concept level. Continuous containment walls, canyon rock, tunnels, banked turns, and safe run-off are **unverified**. The face-plant/ejection fantasy suggests inconsistent containment.
- **Particle and sound juice:** Physical crashes and ragdoll-like failure are visible in the [gameplay video](https://www.youtube.com/watch?v=pm0uwYs2Nzw). Specific dust, sparks, trails, whooshes, collision tiers, music, and landing stingers are **unverified**.

**Takeaway for Pumpkin:** Keep the legible seated/contained silhouette, ramps, and obvious obstacles, but reject accidental ejection. Lock the rider inside the pumpkin for the whole run and turn collisions into a speed/combo penalty, not a physics failure.

## 5. Mega Marble Run Pit — inside-the-ball and enclosed-course reference

Sources: [current Roblox game page](https://www.roblox.com/games/32331218/Mega-Marble-Run-Pit), [Roblox Wiki/Fandom page](https://roblox.fandom.com/wiki/Player:SeanMichaell/Mega_Marble_Run_Pit), and [4.7M-view gameplay video](https://www.youtube.com/watch?v=Z6PBkz9gq6c). The current Roblox page exists but reports no running experiences, so this is a historical high-visit design reference, not a current-CCU claim. Fandom records roughly 349M+ visits, with newer search data reporting 368M+; the discrepancy is time-of-snapshot, so no single exact current total is asserted.

- **How the player rides:** The avatar is inside a giant marble. The [gameplay video](https://www.youtube.com/watch?v=Z6PBkz9gq6c) explicitly describes being stuck inside a big marble on slides, funnels, and jumps; the [Fandom page](https://roblox.fandom.com/wiki/Player:SeanMichaell/Mega_Marble_Run_Pit) says players complete courses “in a marble.” This is the clearest rider reference for Q4-A.
- **Camera:** Third-person follow of the marble is visible in gameplay. Fandom marks camera animation disabled, but that metadata does not document the follow offset or FOV. Exact camera distance, transparency handling, damping, collision, and speed response are **unverified**.
- **Speed:** Exact speed in studs/s is **unverified**. Fandom verifies only relative acceleration: tilted sections get faster, the Yellow course gets progressively faster, and Green begins with a huge drop into fast rails ([course notes](https://roblox.fandom.com/wiki/Player:SeanMichaell/Mega_Marble_Run_Pit)).
- **Obstacle and dodge design:** Eleven courses were documented. Verified pieces include funnels, pole fields, tilted rails, large drops, jumps, repeated funnels, fall-off risk, and transitions between open and protected track. These are mostly physics/set-piece hazards rather than three-lane dodge decisions ([Fandom course descriptions](https://roblox.fandom.com/wiki/Player:SeanMichaell/Mega_Marble_Run_Pit)).
- **Combo rules:** No combo was verified. Finishing or falling to the floor awards 2–8 Credits according to Fandom, weakening the penalty for failure and keeping the toy-loop casual ([Fandom gameplay section](https://roblox.fandom.com/wiki/Player:SeanMichaell/Mega_Marble_Run_Pit)).
- **UI palette:** Colour-coded courses—Blue, Yellow, Green, Red, Purple—are verified by the [Fandom course list](https://roblox.fandom.com/wiki/Player:SeanMichaell/Mega_Marble_Run_Pit). Approximate hex values `#2388FF`, `#FFD52F`, `#43D35F`, `#F04444`, `#914FE8`; exact hex values are **unverified**. The old UI is utilitarian: lobby teleporters, Change Marble menu, Credits, and Shop.
- **Map enclosure:** Strong mixed reference. Yellow has walls protecting the whole track; Blue includes a long tunnel; Green uses a curved wall to prevent falling. Other sections deliberately expose fall risk ([Fandom](https://roblox.fandom.com/wiki/Player:SeanMichaell/Mega_Marble_Run_Pit)). This proves enclosure can alternate with spectacle rather than becoming a featureless pipe.
- **Particle and sound juice:** The gameplay video supports collision-heavy motion through funnels and jumps. A player discussion specifically praises the marble sounds ([Reddit discussion](https://www.reddit.com/r/roblox/comments/16emgfd/what_are_some_games_u_play_but_almost_everyone/)), but exact sound layers, particle emitters, trails, shake, and pitch scaling are **unverified**.

**Takeaway for Pumpkin:** Put the avatar inside, keep the pumpkin readable from a stable chase camera, and alternate canyon walls, high chute rails, and a short tunnel. Funnels and giant drops create spectacle; lane obstacles create the deliberate dodge/combo play that Mega Marble lacks.

## Cross-game conclusions

No reviewed source published trustworthy studs/s values. Therefore the brief's 60 → 140+ studs/s target should be treated as Pumpkin's own tuned specification, not a copied market norm. Likewise, no reviewed game verified the exact clean-dodge combo requested in Q4-B. That is an opportunity: combine the immediate `+1` readability of Stone Skipping with the committed escape chain of Break and Steal an Egg and the contained downhill spectacle of Mega Marble.

The rider comparison is decisive:

- **Inside a ball:** Mega Marble Run Pit — strongest read for safety, ownership, and continuous rolling.
- **Seated/in a container:** Ride a Box — readable, but loose/ejection comedy conflicts with “cannot leave until the end.”
- **Avatar is the rolling object:** Get Fat and Roll Race — very readable progression, but wrong fantasy for a pumpkin vehicle.
- **Holding/carrying:** Break and Steal an Egg — useful risk-state silhouette, but not a ride.
- **No rider; thrown projectile:** +1 Stone Skipping — useful feedback/progression reference only.

Recommendation: **avatar inside a semi-transparent pumpkin**, with the avatar head/upper torso readable through a small front window or translucent shell. This preserves Mega Marble's instantly understood “person in rolling ball” silhouette while allowing a locked seat, hidden limbs, and no accidental jump-off. A separate BillboardGui headshot is a fallback only if transparency makes the shell visually muddy.

## We do / they do / change

| Area | We do now | They do | Change for Q4 |
|---|---|---|---|
| Core loop | One ride reads as passive/boring from Zion's playtest | Stone Skipping pays every bounce; Break and Steal exposes four clear states; Get Fat converts preparation into visible distance | Make every 10–14 s run read as launch → accelerate → dodge/pickup → protect combo → cash out |
| Rider | Pumpkin floats; player can jump off; relationship is unclear | Mega Marble puts the avatar inside; Ride a Box supplies a contained silhouette; Get Fat makes the body itself roll | Put the avatar inside a semi-transparent pumpkin/window, lock the seat, hide stray limbs, disable jump, release only at finish |
| Rolling | Floating translation does not sell weight | Mega Marble and Get Fat make rotation/size the physical read | Ground-snap and rotate by distance ÷ radius every frame on client and server; add contact shadow/dust |
| Camera | Current camera lacks speed drama | Reviewed rolling games use a readable third-person chase; exact dynamic FOV is unverified | Stable behind/above chase, look-ahead into turns, roll-independent horizon, FOV rising with 60 → 140+ studs/s |
| Hill | Hill feels too shallow and slow | Mega Marble uses huge drops, tilted rails, funnels, tunnels; Ride a Box uses long descents and ramps | Build an 18–25° chute with immediate drop, banked turns, one tunnel, canyon compression, and 60 → 140+ studs/s acceleration |
| Obstacles | No satisfying dodge chain | Ride a Box advertises rocks/ramps; Break and Steal uses threat after commitment; Mega Marble uses poles/funnels/fall risk | Seed rolling logs, tombstones, and low fences; three readable lanes; always one free lane; telegraph before reaction point |
| Failure | Low consequence/readability | Box games use crashes; Mega Marble uses fall-off; Break and Steal risks losing the carried result | Keep rider attached; hit = strong bump/audio/UI flash, −20% speed, combo reset; never eject |
| Combo | None | Stone Skipping has event-by-event `+1`; reviewed titles do not verify a dodge combo | Clean dodge or pickup = +1; large pop and meter; ×1.1 per step capped at ×3; show reset clearly |
| UI | Bland | Current simulators use huge counters, saturated panels, progress bars, reward pop-ups, and obvious side actions | Large speed and combo numbers, thick dark strokes, frame-only gradients, button bounce, shine sweep; never gradient text |
| Colour | Dead/desaturated | Stone and egg games use cyan/lime/yellow/pink; box and marble courses use colour-coded routes | Use the six-colour saturated palette below plus dark ink outlines; raise world saturation/contrast as briefed |
| Enclosure | Map feels open/unfinished | Mega Marble alternates full walls, curved guards, open spectacle, and a tunnel | 12+ stud walls/cliffs, canyon, banked containment, short tunnel; preserve sky reveals at major drops |
| Models | Plain blocks | Competitors use giant eggs/animals, novelty stones, boxes, funnels, and oversized props as landmarks | Jack-o'-lanterns, gravestones, fences, candy arch, lamps with PointLights; silhouette-test every obstacle/prop |
| Juice | Limited sense of impact/speed | Bounce pop-ups, hatches/cash-ins, body growth, crashes, rolling sounds, and course colour changes provide frequent beats | Speed lines, ground dust, pickup burst, near-miss/dodge burst, layered roll/wind audio, hit thud, combo pitch rise, finish stinger |

## Six-colour saturated Q4 palette

These are proposed production colours derived from the recurring high-contrast families above; they are not claimed as exact competitor samples.

| Role | Name | Hex | Use |
|---|---|---:|---|
| Primary | Pumpkin orange | `#FF6B00` | Pumpkin shell, primary CTA, wins |
| Secondary | Electric purple | `#8B2CFF` | Combo frame, tunnel/canyon accents |
| Success | Acid lime | `#B7FF1A` | Clean dodge, pickup, multiplier gain |
| Speed | Turbo cyan | `#00D9FF` | Speed lines, speed meter, cool highlights |
| Impact | Hot magenta | `#FF2D95` | Combo pop, rare pickup, danger accent |
| Reward | Candy yellow | `#FFD400` | Coins/wins, shine sweep, finish burst |

Supporting outline/background ink: `#171225` (not one of the six saturated colours). Use ink at 3–5 px UI strokes and on prop silhouettes. Use gradients only on frames/surfaces—for example orange → magenta or purple → cyan—never on text. Keep text white `#FFFFFF` or ink `#171225` for contrast.
