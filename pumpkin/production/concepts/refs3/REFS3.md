# Steal a Pumpkin — fresh reference research

Research date: **2026-10-12 UTC**. Scope: references only; no game-code edits or commit. Owner-reported: v3 is below the owner's 8/10 bar. The labels and earlier self-scores on v3 are not owner approval.

## What was checked

- Inspected `v3/_sheet.jpg` and the v3 audit; screen-specific inspection and comparisons follow below.
- Retrieved Roblox's public Explore chart API, Computer / US, on October 12. Raw responses: [page 1](chart-api-1.json), [page 2](chart-api-2.json); [capture record](chart-capture.json). These are a snapshot, not permanent ranks or revenue evidence.
- Searched current Halloween coverage, official game descriptions, the 2026 Innovation Awards, DevForum showcase topics, and YouTube best-looking/graphics videos. Checked selected video upload dates with `yt-dlp --print "%(upload_date)s"`. Eligibility window: September 1–October 12, inclusive.
- Read the Roblox production skill and its source-evaluation rules, and local `PLAYBOOK.md`. The exact Keystone “Roblox Process Playbook” could not be located in the available local files or connected search; its owner-supplied requirements (real art, core moment, named comparisons) govern this study.
- Evidence labels: **API** = directly retrieved official data; **official** = developer/platform page; **observed** = inspected video frame; **inferred** = design transfer; **UNKNOWN** = not verified. No source here proves player retention, real orders or received payments.

## Current chart evidence

Source: [Roblox Explore API](https://apis.roblox.com/explore-api/v1/get-sorts?sessionId=refs3research&device=computer&country=US), continuation token in the saved first response.

| Requested chart | Directly observed snapshot |
|---|---|
| Top Trending | Huss Valley #1; Adopt Me #2; BGSI #88 |
| Up-and-coming | Huss Valley #1; Bricklayer #2; WRONG WAY! #3; Anime Zero #4 |
| Top Earning | Adopt Me #1; RIVALS #5; Fisch #9; DOORS #29; BGSI #94 |
| Most Engaging | API sort `Most_engaging_V4` is displayed as **Most Popular**: Jujutsu Shenanigans #1; Huss Valley #2; RIVALS #4; Adopt Me #7; Fisch #9; DOORS #11. Preserve the displayed name; don't invent a separate current shelf. |

Chart membership measures popularity signals, not art quality. Top Earning is an ordinal shelf, not a dollar amount. Deepwoken's current rank is UNKNOWN in these two returned pages.

Additional cross-checks: [RBLXSTAT October 12 trending snapshot](https://rblxstat.com/lists/trending-roblox-games), [RoStats October 3 up-and-coming snapshot](https://rostats.io/top/up-and-coming), [chart naming/freshness explanation](https://marpla-analytics.com/en/guide/market/roblox-charts). Their dates and markets differ; do not combine their player counts.

## Ten candidates, six selected

All five forbidden games are excluded from candidates and captures: **Pet Simulator 99, Steal an Egg, Steal a Brainrot, Grow a Garden, Plants vs Brainrots**. Break and Steal an Egg is also omitted because it would repeat the existing egg reference direction.

| Candidate | Why it is worth studying / evidence | Decision and role |
|---|---|---|
| **Adopt Me!** | API: Trending #2, Earning #1. Official October 9 description confirms Hauntlet, Poltergeist Box and journal stickers. Strong seasonal pet presentation and a built-out social town. [Official game](https://www.roblox.com/games/920587237/Adopt-Me), [developer news](https://www.playadopt.me/) | **Select:** hub, shop/index, pets, seasonal reveal. Pet-care hit; relevant even though it is not a steal game. |
| **Fisch** | API: Earning #9, Revisited #3. The developer explains a concrete cast–bite–reel loop. Useful held-tool silhouettes, landscape staging and compact task UI. [Official game](https://www.roblox.com/games/16732694052/Fisch) | **Select:** terrain/lane, PC HUD, tool held, task/reward presentation. Simulator hit. |
| **Bubble Gum Simulator INFINITY** | API: Trending #88, Earning #94. Official description confirms Nightmare Town, three Halloween eggs and Spooky Shop. A direct hatch/team reference with current seasonal content. [Official game](https://www.roblox.com/games/85896571713843/Bubble-Gum-Simulator-INFINITY) | **Select:** hub, hatch, shop/index, pet grouping. Simulator hit; not claimed to be a chart leader. |
| **DOORS** | API: Earning #29. Roblox's 2026 Best Use of Audio winner: cues communicate danger as well as mood. Its lighting and environmental interactions are useful polish references. [Official awards](https://about.roblox.com/newsroom/2026/09/2026-roblox-innovation-awards), [official game](https://www.roblox.com/games/6516141723/DOORS) | **Select:** material contrast, atmospheric depth, first actions, held prop, threat staging. Audio award is not a visual-art award. |
| **RIVALS** | API: Earning #5, Most Popular #4. Roblox's 2026 Best Shooter winner, described by Roblox as polished competitive FPS. Strong action readability and device-specific control evidence. [Official awards](https://about.roblox.com/newsroom/2026/09/2026-roblox-innovation-awards) | **Select:** PC/phone HUD, tool-in-hand, combat feedback. Transfer hierarchy and silhouette, not gun theme. |
| **Deepwoken** | Official page lists ruined sanctuaries, dungeons, weapons and ability combat. Pocket Gamer praises its moody atmosphere while acknowledging mixed reception. [Official game](https://www.roblox.com/games/4111023553/Deepwoken), [visual review](https://www.pocketgamer.com/roblox/best-looking-games/) | **Select:** boss/combat, terrain/lighting, held weapon. Art/polish reference; no claim that it is universally well reviewed. |
| **Huss Valley** | API: #1 Trending and Up-and-coming, #2 Most Popular. Clearly a current breakout worth checking for immediate action readability. [Official snapshot](chart-api-1.json), [trending cross-check](https://rblxstat.com/lists/trending-roblox-games) | Reserve: combat hit; selected set already covers action and adds more material variety. Visual superiority is UNKNOWN without a frame study. |
| **Animal Hospital (Anomaly)** | Roblox's 2026 creative-direction, new-game, People's Choice and Builderman winner. Distinctive hospital/patient identity; an example of a recognisable premise expressed immediately. [Official awards](https://about.roblox.com/newsroom/2026/09/2026-roblox-innovation-awards) | Reserve: excellent identity benchmark, less direct fit for pets/hatching and outdoor lanes. |
| **PHIGHTING!** | DevForum specifically discusses its dimensional UI; developer describes modern reinterpretations of Roblox gears and maps. Useful graphic shapes and readable weapon identities. [DevForum UI discussion](https://devforum.roblox.com/t/how-can-you-make-ui-like-the-roblox-game-phighting/2081137), [official game](https://www.roblox.com/games/7138009149/PHIGHTING) | Reserve: distinctive UI reference, but current selected footage supports the required boss and phone screens more directly. |
| **FRONTLINES** | A March 16, 2026 YouTube graphics comparison calls out its realistic FPS visuals; GameSpot praises both its appearance and play. [2026 graphics video](https://www.youtube.com/watch?v=GvZCD2M3wQA), [GameSpot review](https://www.gamespot.com/gallery/best-roblox-shooter-games/2900-7142/) | Reserve: material/animation ceiling; realistic military presentation would pull Pumpkin away from its friendly seasonal style. The March video is research only, ineligible for frames. |

Selection mix: **three collection/simulation hits + three art/action/polish references**. This is a screen-fit judgement, not an overall best-game ranking.

DevForum discovery included [current showcase topics](https://devforum.roblox.com/tag/showcase) and [showcase page 1](https://devforum.roblox.com/tag/showcase?match_all_tags=true&page=1&tags%5B%5D=showcase), including atmospheric lighting and grass demonstrations. A technical showcase is not evidence of a successful playable game. The 2026 graphics video was more useful than year-labelled generic “10/10 games” lists; neither supplies eligible recent capture footage.

## Halloween: live versus announced

- **Official, live:** Adopt Me's current game page and developer home page advertise Halloween: Hauntlet Returns, Poltergeist pets and journal stickers. BGSI's current official game description advertises Nightmare Town, new eggs, hatchable secrets and Spooky Shop.
- **Observed update footage:** DOORS Stairwell Access Granted gameplay from October 2; this is an October update reference, not proof that it is a Halloween event.
- **Secondary schedule, not a verified live hit:** Dandy's World October 2, 99 Nights October 3, Dress to Impress October 10 are reported by [October event coverage](https://olagg.io/en/novedades/eventos-de-halloween-2026-en-roblox-fechas-y-juegos-confirmados). Their event mechanics were not independently captured here.
- **Upcoming, not live on October 12:** that schedule places FischFright 3 on October 17. Fisch frames below show the current Nate quest instead. A promised event is not proof of a successful update.

## Capture method and rights

Used `bash C:/dev/codex-lab/refs/tools/study.sh search ...` to discover candidates. Its hardcoded output directory is outside the writable workspace, so `get` and `clean` run through a workspace copy: only output path, 720p selection, Node runtime/TLS relay and stream-copy cut behavior changed. Every section starts at 00:00; full-resolution JPEGs are extracted separately at exact source timestamps using FFmpeg. Contact-sheet timestamps are section-local and are not substituted for source timestamps.

480p small card text was visibly soft in the test; accepted frames use source-resolution 720p sections. FFmpeg's Windows Schannel credential error required a loopback relay to Node's certificate-verified HTTPS fetch. No passwords, cookies or login were used. Temporary video downloads are removed with the study script's `clean` command after extraction.

Video frames are visual study material, **not licensed production assets**. Do not ship another game's meshes, textures, UI art or footage. yt-dlp is an Unlicense tool; FFmpeg build is GPL and tool-only. The helper tools are not game dependencies.

## Frame ledger and screen comparisons

The completed frame ledger below records URL, yt-dlp upload date, timestamp, file and visible feature. Design recommendations are inferred from those observed frames and our inspected v3 concepts. No frame demonstrates retention, input latency, animation timing beyond its captured moment, or performance on our own phone build.

### Eight accepted source videos

| Game / video | Upload date (yt-dlp) | Sections inspected |
|---|---|---|
| [THE ULTIMATE GUIDE TO THE HALLOWEEN EVENT IN BUBBLEGUM SIMULATOR INFINITY!](https://www.youtube.com/watch?v=Fe-04b8SQf8) — Lzxism | 2026-10-11 | 00:00–06:49 |
| [Collecting Halloween Pets! Using Crypt Keys! | Adopt Me Halloween 2026 Roblox | Riivv3r](https://www.youtube.com/watch?v=q90HCeJSKAk) — Riivv3r | 2026-10-07 | 00:00–04:00 |
| [I hatched 8,000,000 of the Worst Eggs in Halloween | Bubble Gum Simulator Infinity](https://www.youtube.com/watch?v=qnC4WKS9gqY) — Knackix | 2026-10-11 | 00:00–04:00; 04:00–07:08 |
| [FULL GUIDE To NATES BLADE QUEST In Fisch Roblox!](https://www.youtube.com/watch?v=NZcqxxrt-e4) — Carbon Meister Plays | 2026-10-10 | 00:00–05:00 |
| [How GOOD is the #1 MOBILE PLAYER in Roblox Rivals?](https://www.youtube.com/watch?v=1OOfL2QjI-0) — Viecti | 2026-10-11 | 00:00–05:00 |
| [DOORS The Stairwell ACCESS GRANTED Update Full Gameplay!!! | The Stairwell Extended and Evolved](https://www.youtube.com/watch?v=Pz8ffoAMd6o) — Magician Rblx | 2026-10-02 | 00:00–05:00; 15:00–17:00 |
| [This PvE Can make Anyone IMMORTAL! - Deepwoken Build Showcase](https://www.youtube.com/watch?v=UeRKESkr2Ag) — Infekted | 2026-10-11 | 00:00–07:30 |
| [HALLOWEEN IS HERE IN BUBBLEGUM SIMULATOR INFINITY](https://www.youtube.com/watch?v=yICyhi4p0DA) — Lzxism | 2026-10-10 | 00:00–05:01 |

One additional exploratory Adopt Me video (`qpf7Y3YTp6g`, upload 2026-10-03) was downloaded and rejected from the final set; its intro and event montage were less useful. Thus **9 distinct videos were downloaded during exploration, 8 retained as sources**. This is one over the requested approximate download cap; no tenth video was downloaded. Multiple sections and the 480p test reuse the same video IDs. All video files, including rejected/test files, are cleaned.

### Every delivered frame

All files below are full encoded video frames at **1280 × 720**, JPEG quality 2, with no crop, recolouring, generated replacement or timestamp overlay. Creator captions, sidebars and graphics already inside the source are retained. Some embedded mobile clips have lower intrinsic detail than their 720p video container; the original phone device and capture resolution are UNKNOWN.

| Frame | Source URL at timestamp | Upload date | Source timestamp | Observed feature / limitation |
|---|---|---|---|---|
| [hub-base-bgsi-1.jpg](hub-base-bgsi-1.jpg) | [YouTube](https://www.youtube.com/watch?v=Fe-04b8SQf8&t=173s) | 2026-10-11 | 02:53 | Nightmare Town portal, crooked houses, branching plaza |
| [hub-base-adopt-me-1.jpg](hub-base-adopt-me-1.jpg) | [YouTube](https://www.youtube.com/watch?v=q90HCeJSKAk&t=7s) | 2026-10-07 | 00:07 | Layered Halloween streets, glowing signs and window trim |
| [hub-base-bgsi-2.jpg](hub-base-bgsi-2.jpg) | [YouTube](https://www.youtube.com/watch?v=qnC4WKS9gqY&t=5s) | 2026-10-11 | 00:05 | Autumn plaza fountain, warm foliage and contrasting pavement |
| [zone-lane-fisch-1.jpg](zone-lane-fisch-1.jpg) | [YouTube](https://www.youtube.com/watch?v=NZcqxxrt-e4&t=13s) | 2026-10-10 | 00:13 | Textured sand, wooden dock, rocky bank and lantern spacing |
| [zone-lane-adopt-me-1.jpg](zone-lane-adopt-me-1.jpg) | [YouTube](https://www.youtube.com/watch?v=q90HCeJSKAk&t=101s) | 2026-10-07 | 01:41 | Crypt corridor, raised tombs, candles, bone props and bright destination |
| [hud-pc-rivals-1.jpg](hud-pc-rivals-1.jpg) | [YouTube](https://www.youtube.com/watch?v=1OOfL2QjI-0&t=93s) | 2026-10-11 | 01:33 | PC view: separated score/time, health, ammo and loadout |
| [hud-pc-bgsi-1.jpg](hud-pc-bgsi-1.jpg) | [YouTube](https://www.youtube.com/watch?v=Fe-04b8SQf8&t=89s) | 2026-10-11 | 01:29 | Discrete currency capsules and menu/boost groups; crowded late-game counterexample |
| [hud-pc-fisch-1.jpg](hud-pc-fisch-1.jpg) | [YouTube](https://www.youtube.com/watch?v=NZcqxxrt-e4&t=209s) | 2026-10-10 | 03:29 | Fishing progress bar tied to the current interaction |
| [hud-phone-rivals-1.jpg](hud-phone-rivals-1.jpg) | [YouTube](https://www.youtube.com/watch?v=1OOfL2QjI-0&t=101s) | 2026-10-11 | 01:41 | Embedded mobile-player clip with explicit right-side touch icons |
| [hud-phone-rivals-2.jpg](hud-phone-rivals-2.jpg) | [YouTube](https://www.youtube.com/watch?v=1OOfL2QjI-0&t=213s) | 2026-10-11 | 03:33 | Embedded mobile-player clip: joystick, health and held scythe |
| [hud-phone-adopt-me-1.jpg](hud-phone-adopt-me-1.jpg) | [YouTube](https://www.youtube.com/watch?v=q90HCeJSKAk&t=237s) | 2026-10-07 | 03:57 | Portrait gameplay segment with contextual hand icon; device model UNKNOWN; pink sidebars retained |
| [shop-panel-doors-1.jpg](shop-panel-doors-1.jpg) | [YouTube](https://www.youtube.com/watch?v=Pz8ffoAMd6o&t=13s) | 2026-10-02 | 00:13 | Pre-Run Shop: item description, price, selected-key state and confirm total |
| [shop-panel-bgsi-1.jpg](shop-panel-bgsi-1.jpg) | [YouTube](https://www.youtube.com/watch?v=Fe-04b8SQf8&t=339s) | 2026-10-11 | 05:39 | Halloween Upgrades: row-based benefits, tier indicators and costs |
| [index-panel-bgsi-1.jpg](index-panel-bgsi-1.jpg) | [YouTube](https://www.youtube.com/watch?v=qnC4WKS9gqY&t=353s) | 2026-10-11 | 05:53 | Actual open-book collection index with Normal/Shiny and seasonal tabs |
| [index-panel-adopt-me-1.jpg](index-panel-adopt-me-1.jpg) | [YouTube](https://www.youtube.com/watch?v=q90HCeJSKAk&t=15s) | 2026-10-07 | 00:15 | Journal categories then rarity-grouped list; text remains at full video resolution |
| [index-panel-adopt-me-2.jpg](index-panel-adopt-me-2.jpg) | [YouTube](https://www.youtube.com/watch?v=q90HCeJSKAk&t=185s) | 2026-10-07 | 03:05 | Backpack search and Mummy Spider rarity tooltip |
| [pets-lineup-bgsi-1.jpg](pets-lineup-bgsi-1.jpg) | [YouTube](https://www.youtube.com/watch?v=qnC4WKS9gqY&t=297s) | 2026-10-11 | 04:57 | Several huge pet bodies overlap: crowned silhouettes, horns, wings and material variation |
| [pets-lineup-adopt-me-1.jpg](pets-lineup-adopt-me-1.jpg) | [YouTube](https://www.youtube.com/watch?v=q90HCeJSKAk&t=9s) | 2026-10-07 | 00:09 | Two differently proportioned companions, contextual status and selective neon |
| [pets-lineup-bgsi-2.jpg](pets-lineup-bgsi-2.jpg) | [YouTube](https://www.youtube.com/watch?v=Fe-04b8SQf8&t=401s) | 2026-10-11 | 06:41 | Huge red companion and purple stars; useful scale contrast, also a visibility warning |
| [tool-held-rivals-1.jpg](tool-held-rivals-1.jpg) | [YouTube](https://www.youtube.com/watch?v=1OOfL2QjI-0&t=213s) | 2026-10-11 | 03:33 | Mobile first-person held scythe has a recognisable purple hook in the viewport corner |
| [tool-held-fisch-1.jpg](tool-held-fisch-1.jpg) | [YouTube](https://www.youtube.com/watch?v=NZcqxxrt-e4&t=207s) | 2026-10-10 | 03:27 | Held rod/blade outline, red cave light and casting line |
| [tool-held-doors-1.jpg](tool-held-doors-1.jpg) | [YouTube](https://www.youtube.com/watch?v=Pz8ffoAMd6o&t=961s) | 2026-10-02 | 16:01 | Held canisters in orange-lit metal lift: chamfered forms, material pattern and hand/grip cue; held-item analogue |
| [boss-fight-deepwoken-1.jpg](boss-fight-deepwoken-1.jpg) | [YouTube](https://www.youtube.com/watch?v=UeRKESkr2Ag&t=167s) | 2026-10-11 | 02:47 | Actual boss: huge weapon/body, player spacing and round arena with floor detail |
| [boss-fight-deepwoken-2.jpg](boss-fight-deepwoken-2.jpg) | [YouTube](https://www.youtube.com/watch?v=UeRKESkr2Ag&t=175s) | 2026-10-11 | 02:55 | Actual boss ground-impact swirl and foot-level contact effect |
| [boss-fight-rivals-1.jpg](boss-fight-rivals-1.jpg) | [YouTube](https://www.youtube.com/watch?v=1OOfL2QjI-0&t=207s) | 2026-10-11 | 03:27 | White attack arc, red incoming-damage wedge and opponent focus; PvP combat analogue, not a boss |
| [first-minutes-adopt-me-1.jpg](first-minutes-adopt-me-1.jpg) | [YouTube](https://www.youtube.com/watch?v=q90HCeJSKAk&t=93s) | 2026-10-07 | 01:33 | Coffin E prompt and immediate candy reward in a decorated corridor; experienced-player interaction, not FTUE |
| [first-minutes-bgsi-1.jpg](first-minutes-bgsi-1.jpg) | [YouTube](https://www.youtube.com/watch?v=yICyhi4p0DA&t=15s) | 2026-10-10 | 00:15 | Opening Play flow followed by Quality / Optimized choice with device icons; not a gameplay FTUE |
| [first-minutes-doors-1.jpg](first-minutes-doors-1.jpg) | [YouTube](https://www.youtube.com/watch?v=Pz8ffoAMd6o&t=17s) | 2026-10-02 | 00:17 | Immediate held object after pre-run shop; opening run action, not first-ever player session |
| [hatch-reveal-adopt-me-1.jpg](hatch-reveal-adopt-me-1.jpg) | [YouTube](https://www.youtube.com/watch?v=q90HCeJSKAk&t=183s) | 2026-10-07 | 03:03 | Mummy Spider acquisition: emerged companion, name and newborn state; acquisition analogue, not egg hatch |
| [hatch-reveal-fisch-1.jpg](hatch-reveal-fisch-1.jpg) | [YouTube](https://www.youtube.com/watch?v=NZcqxxrt-e4&t=213s) | 2026-10-10 | 03:33 | Caught fish held up with catch and new-best-weight message; reward reveal analogue |
| [hatch-reveal-bgsi-1.jpg](hatch-reveal-bgsi-1.jpg) | [YouTube](https://www.youtube.com/watch?v=yICyhi4p0DA&t=195s) | 2026-10-10 | 03:15 | Chest opens with gold light, sparkle, currency and potion rewards; chest reveal analogue, not egg hatch |

The study contact-sheet sampler rounds time into two-second bins. Final JPEG timestamps were chosen separately (usually one second after the sheet bin) and visually checked; the ledger lists actual FFmpeg seek times. For the 04:00 and 15:00 sections, extraction subtracts 240 and 900 seconds respectively. Source time is never confused with section-local time. [Machine-readable ledger](frames.json).

**Coverage limits:** No accepted recent clip established an egg shake/crack/reveal sequence; hatch/reveal frames show actual companion acquisition, a chest opening and a catch reward. RIVALS supplies a combat-feedback analogue, not a second literal boss. The first-minutes set shows an opening menu/run and early interactions performed by experienced accounts; first-ever-player FTUE and time-to-first-reward remain UNKNOWN. These limits apply to the recommendations below.

## Five concrete gaps per screen

These are **visual comparisons to the supplied v3 concepts**, not claims about the running Pumpkin game. The third column is an inferred art direction to test, not an instruction to change game systems. “Best” means the most useful frame in this captured set for that screen, not a universal Roblox winner. Existing Pumpkin identity, friendly Halloween tone and one context action on phone remain the design constraints.

### Hub/base — best reference: BGSI Nightmare Town

Compare [BGSI](hub-base-bgsi-1.jpg), [Adopt Me](hub-base-adopt-me-1.jpg), and [our v3 hub](../v3/hub-perspective.png).

| Reference does | v3 shows | Concrete transfer to test |
|---|---|---|
| BGSI separates purple pavement, raised planted edges and pale display platforms. | Repeated green stud floor and a single grey approach. | Give the travel path, nest platforms and garden margins three distinct surface treatments. |
| BGSI crooked roofs, webs and lamps form an irregular middle-distance skyline. | Buildings and pens are spaced in a highly regular mirror arrangement. | Break the skyline with two offset roof heights and a canopy crossing one approach. |
| Adopt Me uses warm windows under a cooler blue canopy and sky. | Broad daylight with little local light contrast. | Light shop windows and nests locally; keep the main route readable. |
| BGSI mixes houses, rocks, candy piles, pots and one portal within each sightline. | Large stretches of open lawn between the few hero props. | Put clusters of three related small props beside routes, rather than isolated scattered pumpkins. |
| BGSI's portal silhouette and curved junction provide layered destinations. | Straight central axis ending at the throne. | Add a nearer framing arch/branch and a partial distant landmark behind it. |

### Zone lane — best reference: Fisch shoreline

Compare [Fisch](zone-lane-fisch-1.jpg), [Adopt Me crypt](zone-lane-adopt-me-1.jpg), [our meadow](../v3/zone1-perspective.png), and [our zone strips](../v3/zones-strip.png).

| Reference does | v3 shows | Concrete transfer to test |
|---|---|---|
| Fisch sand has ripples and the dock has narrow wooden boards. | A uniform stud repeat across the meadow. | Use subtle earth/sand variation along the lane and visible planks on bridges. |
| Fisch's shore, bank and dock occupy different heights. | Almost one floor plane between destination gates. | Add a low bank, a dip and a raised edge without blocking the travel corridor. |
| The crypt places bones, candles and raised tombs against the walls. | Sparse ground props with long empty boundaries. | Build dense edge clusters and leave the playable centre clear. |
| The crypt's lit far window creates a specific destination value contrast. | A uniformly bright sky behind the gate silhouette. | Give each lane a light/dark endpoint contrast rather than only a different sky colour. |
| Fisch distant palms, banks and fog overlap the horizon. | Bare retaining walls and simple far geometry. | Layer foreground foliage, a middle landmark and a softer far boundary. |

### PC HUD — best reference: RIVALS PC view

Compare [RIVALS](hud-pc-rivals-1.jpg), [Fisch](hud-pc-fisch-1.jpg), [BGSI](hud-pc-bgsi-1.jpg), and [our desktop](../v3/hud-desktop.png).

| Reference does | v3 shows | Concrete transfer to test |
|---|---|---|
| RIVALS separates match status at top, health at bottom-left and tool state at bottom-right. | A large instruction heading plus two left counters and a generic hotbar. | Distinguish persistent currency, current action progress and held-tool state by position and scale. |
| Fisch brings a narrow progress bar into the current fishing action. | Instruction text with no depicted action-progress state. | Show a compact target/steal progress state close to the current interaction. |
| BGSI currency capsules carry icons and visibly bounded numeric fields. | Mostly floating icon/number pairs. | Give long balances a consistent bounded container and alignment. |
| RIVALS uses small secondary key labels under the tool group. | Slot numbers do most of the control explanation. | Keep the hotbar compact, but include one small action/key cue for the selected tool. |
| RIVALS uses bold primary numbers with quieter secondary text. | Similar heavy outlined treatment on most prominent labels. | Reserve thick outlined type for the current action and use lighter secondary labels. |

BGSI's full late-game HUD is a **clutter counterexample**: do not copy its number of icons, ads or boost counters. Borrow capsule construction and grouping only.

### Phone HUD — best reference: RIVALS touch controls; contextual alternative: Adopt Me portrait segment

Compare [explicit touch icons](hud-phone-rivals-1.jpg), [mobile gameplay](hud-phone-rivals-2.jpg), [portrait segment](hud-phone-adopt-me-1.jpg), and [our phone](../v3/hud-phone.png).

| Reference does | v3 shows | Concrete transfer to test |
|---|---|---|
| RIVALS has solid white action silhouettes on black circles. | Thin scythe art plus a word inside the context circle. | Test a thicker, simpler scythe/hand glyph at phone size. |
| RIVALS places joystick and tool/health information in distinct corner regions. | A compact but tightly adjacent counter/joystick stack. | Give the joystick more separation from text and persistent counters. |
| Adopt Me places the hand interaction on the selected coffin. | The persistent SMASH/STEAL action is spatially detached from the target. | Echo the active target with a small anchored hand/ring cue; retain the single action button. |
| The portrait segment fits menus into a collapsible bottom row. | Two permanently boxed hotbar tiles. | Test flatter selected-item treatment and reserve box depth for the current item. |
| The portrait reward text sits low in the world view while the target remains visible. | Floating reward icons compete with the avatar and tool. | Use a short, consistent low-screen reward line and keep the avatar clear. |

Do not copy RIVALS' many action buttons: Pumpkin's one-context-action constraint wins. Device model, physical tap size and successful thumb reach are UNKNOWN; these frames are layout references, not a phone usability test.

### Shop panel — best reference: DOORS Pre-Run Shop

Compare [DOORS](shop-panel-doors-1.jpg), [BGSI](shop-panel-bgsi-1.jpg), and [our shop](../v3/panels-shop-index.png).

| Reference does | v3 shows | Concrete transfer to test |
|---|---|---|
| DOORS gives each item a plain functional sentence beside its price. | Tool name, rarity and cost, with power separated into a side card. | Put a one-line benefit beside each offer. |
| DOORS shows the selected item state and total on the confirm area. | All three buy cards have nearly the same visual emphasis. | Depict selected, owned and unavailable states, so the next choice reads immediately. |
| BGSI uses compact upgrade rows with visible level/tier chips. | Tall product cards and a generic bonus strip. | Test denser rows for repeated upgrade tiers; keep hero tools as illustrated cards. |
| BGSI differentiates available green costs from unavailable red costs. | Mostly uniform green buy buttons. | Make affordability/lock state visually explicit rather than relying only on numbers. |
| DOORS' restrained brown backdrop and thin separators let icons and prices lead. | Saturated purple edges, stars, cards and glow all compete. | Reduce background saturation and outline weight behind the main offer. |

This is a visual state study; it does not propose adding a cart, changing prices or adding products.

### Index panel — best reference: BGSI seasonal book; alternate: Adopt Me Journal

Compare [BGSI book](index-panel-bgsi-1.jpg), [Adopt Me Journal](index-panel-adopt-me-1.jpg), [search/tooltip](index-panel-adopt-me-2.jpg), and [our index](../v3/panels-index.png).

| Reference does | v3 shows | Concrete transfer to test |
|---|---|---|
| BGSI's open-book silhouette belongs to the collection theme. | Another generic purple rectangle. | Give Pumpkin's index a distinct scrapbook/book silhouette. |
| BGSI separates Normal/Shiny state from collection-category tabs. | Pets/Pumpkins tabs plus one flat rarity grid. | Show the selected collection variant/category as separate, readable states. |
| Adopt Me offers a visible text search. | No depicted search/filter control. | Include a compact search field in the concept, especially for large collections. |
| Adopt Me lists rarity groups and exposes item rarity/age in a tooltip. | Tile silhouettes and a small income preview. | Make discovered-item details a stable readable preview, rather than tiny text on every tile. |
| BGSI gives the season a heading and visibly completed/claimed state. | Mainly a total collected count. | Show season/category completion distinctly from the overall count. |

### Hatch/reveal — best reference: Adopt Me companion acquisition; light/VFX alternate: BGSI chest

Compare [Adopt Me emergence](hatch-reveal-adopt-me-1.jpg), [BGSI opening chest](hatch-reveal-bgsi-1.jpg), [Fisch catch](hatch-reveal-fisch-1.jpg), and [our reveal](../v3/hatch-reveal.png).

| Reference does | v3 shows | Concrete transfer to test |
|---|---|---|
| Adopt Me's acquisition sits inside a webbed, candle-lit enclosure. | Flat lawn and fence behind the reward card. | Stage the nest with a recognisable enclosing prop and a local light source. |
| BGSI chest light spills across a solid wooden/metal object. | Burst colours surround a largely uniform pumpkin shell. | Make the shell's lip, interior and nearby floor respond to the burst. |
| Adopt Me keeps the emerged pet physically present with its name/state nearby. | A card covers much of the newly revealed object. | Let the pet silhouette remain the hero; place the information beside it. |
| Fisch's catch name, bestiary update and best-weight message describe why this result matters. | Chance percentage and a generic “burst open” title dominate. | Prioritise NEW, pet name, rarity and useful result information over static odds. |
| The chest and companion moments use different spark/puff shapes for different reward sources. | Similar broad confetti/glow treatment across reveal variants. | Give crack dust, rarity rays and reward sparkles separate shape vocabularies. |

**Limit:** These are real reward-reveal moments, not captured egg hatching. Animation beat lengths and a true mass-hatch layout remain UNKNOWN. The v3 mass-hatch card needs a later motion-specific reference; no animation timing is inferred from a still.

### Pets lineup — best reference: BGSI varied giant companions; restrained alternative: Adopt Me

Compare [BGSI group](pets-lineup-bgsi-1.jpg), [Adopt Me pair](pets-lineup-adopt-me-1.jpg), [BGSI giant](pets-lineup-bgsi-2.jpg), and [our pets](../v3/pets.png).

| Reference does | v3 shows | Concrete transfer to test |
|---|---|---|
| BGSI crowns, swept horns and broad wings create very different outer contours. | Several species share similarly blocky head/body proportions. | Give each Pumpkin pet one unique outer silhouette feature. |
| BGSI mixes pale sculpted surfaces, dark recesses and emissive accents. | Pixel/stud detail plus broad aura colour changes. | Add material contrast inside the model, not only a coloured surrounding aura. |
| The BGSI group visibly overlaps at different heights and distances. | A largely evenly spaced presentation around the player. | Compose one foreground hero with smaller companions behind and to its sides. |
| Adopt Me's neon pet uses bounded glowing regions and readable facial features. | Large area glows compete across most of the lineup. | Keep the eye/mouth/unique accessory readable and restrict glow coverage. |
| BGSI's oversized companion has a visibly different body/wing scale. | Rare variants lean heavily on aura and labels. | Test rarity through body silhouette and one added material detail before adding more VFX. |

The giant BGSI frame also warns that huge pets can obscure the route. Borrow form variety; do not copy unlimited size or screen-filling glow.

### Tool held — best material reference: DOORS canisters; silhouette alternate: RIVALS scythe

Compare [DOORS](tool-held-doors-1.jpg), [RIVALS](tool-held-rivals-1.jpg), [Fisch](tool-held-fisch-1.jpg), and [our scythes](../v3/scythes.png).

| Reference does | v3 shows | Concrete transfer to test |
|---|---|---|
| DOORS' nearby metal object and room display bevels, facets and repeating material detail. | Largely smooth/pixel-styled tool surfaces. | Add bevel highlights and distinct shaft/head material treatments. |
| RIVALS' purple hook remains recognisable in a small viewport-corner silhouette. | Similar scythe profiles mainly distinguished by colour/aura. | Test each tool as a black silhouette at phone size. |
| Fisch's held object and line clearly indicate the action direction. | Tool aura gives little directional information. | Add a deliberate head orientation and a short directional trail at use. |
| DOORS orange light changes the visible colour of the held object and nearby metal. | The tool's glow is mostly isolated from the environment. | Depict nearby surface response to the tool's emission. |
| RIVALS associates a selected tool with a quieter small icon/name region. | Seven equally prominent demonstration slots. | In the gameplay concept, give the held tool one selected-state cue rather than seven competing hero slots. |

Held canisters are a material/grip analogue, not a scythe. A first-person reference does not imply changing Pumpkin's third-person camera.

### Boss fight — best reference: Deepwoken actual boss; combat-feedback alternate: RIVALS

Compare [boss staging](boss-fight-deepwoken-1.jpg), [ground impact](boss-fight-deepwoken-2.jpg), [attack arc](boss-fight-rivals-1.jpg), and [our fight](../v3/guards-and-king-fight.png).

| Reference does | v3 shows | Concrete transfer to test |
|---|---|---|
| Deepwoken puts the boss's feet, huge weapon and nearby players in the same combat plane. | A distant king/throne scene with limited attack contact. | Draw one close attack moment with players clearly inside its reach. |
| Deepwoken's ground swirl follows the boss's foot-level impact. | Broad aura/title emphasis with little floor-level impact evidence. | Put the attack ring/debris at the contact point. |
| Deepwoken's circular floor has planks, rings and a stone rim. | A mostly flat purple/green arena and stud repeat. | Give the arena an authored surface pattern that communicates bounds. |
| RIVALS uses a white arc for outgoing action and a red wedge for incoming damage. | A large breach headline competes with the actual fight. | Separate attack direction and received-hit cues with shape as well as colour. |
| Deepwoken keeps the boss name/health narrow at the top while the weapon occupies the scene. | Large duplicated boss portraits/health and title treatment. | Use one health treatment and let pose/weapon communicate the threat. |

Deepwoken's editorial “General Strategy” heading is source-video text, not game HUD. RIVALS is PvP, not a literal boss. Neither frame proves that Pumpkin combat feels good or is fun.

### First minutes — best opening interaction: DOORS; spatial target reference: Adopt Me

Compare [DOORS opening run](first-minutes-doors-1.jpg), [Adopt Me contextual action](first-minutes-adopt-me-1.jpg), [BGSI opening choice](first-minutes-bgsi-1.jpg), and [our first-five-minutes sheet](../v3/first-5-min.png).

| Reference does | v3 shows | Concrete transfer to test |
|---|---|---|
| Adopt Me attaches the interaction prompt to a particular coffin. | The headline instructs an action while several targets look similar. | Make the very first pumpkin/nest visually distinct and attach the prompt there. |
| The same crypt action produces a short candy reward line in the current view. | Rewards and the next action are separated into storyboard panels. | Draw one complete action-to-result frame with target and reward together. |
| DOORS immediately shows a held object after the purchase choice. | The tool and goal are mostly explained by icons and heading. | Put the usable starter tool visibly in hand before the first action. |
| BGSI's opening choice uses device icons, short labels and one clear visual state. | No depicted opening/menu state; the sheet begins directly in gameplay. | When an opening choice is needed, give it one simple two-card state rather than a dense generic panel. |
| The crypt frames connect path, target, reward and destination window through the environment. | Wide empty meadow with separate chest, target and home destinations. | Compose the first route so the next destination is visible immediately beyond the active target. |

The BGSI quality choice is observed UI, not a recommendation to introduce an unnecessary settings step. First-ever-player onboarding and reward timing are UNKNOWN; no “first 30 seconds” claim is made from veteran accounts.

## One review comparison, then owner check

[One hub comparison](_hub-comparison.jpg) places the current v3 hub beside BGSI and Adopt Me, with the reference JPEGs preserved separately. [All accepted frames overview](_overview.jpg).

The comparison is not a blanket claim that their whole screens beat ours: v3 already has clear destination signs, a readable central route and a coherent friendly palette. Preserve those strengths. The useful differences are layered canopies, local light contrast and less repetitive edge composition; BGSI's busy HUD and giant auras are things to simplify, not copy.

For the next art revision, make **one hub frame** first. Test three changes together: authored ground materials, clustered edge props and warm/cool local lighting. Have Zion judge that single comparison before multiplying it into all screens. This research does not generate or approve a new concept batch.

## Lessons

- When a reference title promises a hatch or mobile session, verify the visible event and controls, because titles often describe off-camera history or contain desktop footage.
- When exporting contact-sheet selections, inspect the exact final seek frame, because two-second sampler labels can land before an effect or panel has appeared.
- When v3 feels empty, add surface contrast and layered prop groups before more glow, because geometry and material hierarchy supply depth without covering the action.

## Verification and remaining unknowns

- 31 full-frame JPEGs, 11 screen groups; each has 2–3 frames across at least two different selected games. All six selected games are represented. The overview and single comparison are supplementary, not counted as full-frame references.
- Dates come from saved yt-dlp metadata, not search snippets. The final set uses eight source videos; one extra exploratory download was discarded as stated above.
- Visually checked the final overview and key full frames; checked extracted dimensions and ledger/file coverage. No fabricated frames, Roblox runtime captures from our game, claimed revenue or owner approval.
- Egg-hatch motion, a second literal boss game, first-ever FTUE, intrinsic resolution of embedded phone segments, actual device usability and our runtime graphics remain UNKNOWN.
- All downloaded videos were deleted with `study.sh clean`; recursive verification found zero MP4/WebM/MKV/part files. The zip, yt-dlp and ffprobe binaries were removed. The temporary `_tools/ffmpeg.exe` remains: normal removal returned Access Denied, and automatic approval review rejected forced removal as blocked by policy. No security settings were changed. Small reproduction helpers and chart/date/frame ledgers remain. No game-code edits; no commit.
