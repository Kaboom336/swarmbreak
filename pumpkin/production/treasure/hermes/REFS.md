# Steal a Treasure — Reference Brief

Status: research brief, 2026-10-14. Every non-observed design recommendation is labelled INFERRED. Source quality is noted where useful; community wikis and creator videos are supporting evidence, not primary documentation.

Best-in-class comparison: Steal An Egg is the closest current category reference: its stated loop is stealing eggs from pets, hatching them, and collecting rare pets. Pet Simulator 99 is the stronger reference for repeated hatch-to-pet-to-coin economy presentation. Sources: [Steal An Egg wiki](https://roblox.fandom.com/wiki/And_Collect_Rare_Pets/Steal_An_Egg), [PS99 eggs wiki](https://pet-simulator.fandom.com/wiki/List_of_Eggs_(Pet_Simulator_99)).

## 1. Bright, readable lighting and colour

### What is actually sourced

| Reference | Observed / published evidence | Values published? | Design takeaway |
|---|---|---:|---|
| Grow a Garden | Public gameplay references show a bright, daytime, saturated low-poly garden presentation; no trustworthy public Lighting hierarchy/settings were found. [Gameplay reference](https://www.youtube.com/watch?v=tf2os_On0Xw) | No | INFERRED: use broad daylight, large colour blocks, and readable silhouettes; avoid realism, murky fog, or a dark skybox. |
| Steal An Egg | The closest loop reference has guardian eggs, hatching, and rare-pet collecting. Its community page lists camera animation among experience categories, but does not publish lighting configuration. [Wiki](https://roblox.fandom.com/wiki/And_Collect_Rare_Pets/Steal_An_Egg) | No | INFERRED: make the floating island bright enough that the guardian, treasure, route, and portal read in one glance. |
| Pet Simulator 99 | Eggs are a core loop; pets follow the player and collect coins. No official public Lighting object values found. [PS99 eggs wiki](https://pet-simulator.fandom.com/wiki/List_of_Eggs_(Pet_Simulator_99)) | No | INFERRED: use the same high-value simulator readability: bright world, saturated interactables, clear reward contrast. |
| Adopt Me | Egg-hatching/reveal videos provide visual references, but no verified public Lighting setup was located. [Hatch-animation video search result](https://www.youtube.com/watch?v=WjehLwJ577I) | No | INFERRED: use warm, cheerful daylight and distinctive local colour for the hatch/home space. |
| Roblox DevForum lighting reference | A Roblox creator recommends Future technology; bright-midday Brightness 2.3; ColorCorrection contrast/saturation +0.1; Bloom intensity 0.1, size 0.4, threshold 0.8; SunRays intensity 0.2/spread 0.7; Atmosphere glare 10/haze 1.55. This is one creator’s setup, not a top-game leak. [DevForum post](https://devforum.roblox.com/t/hyper-realistic-lighting-settings/915802) | Yes, but not game-specific | Use as a starting test range only, then test on mobile and low graphics. |
| Roblox DevForum simulator guidance | A separate discussion explicitly says simulators should be bright but not overbearing and suggests Brightness 4–5 plus ColorCorrection contrast/saturation +0.1–0.2 for a sunny look. [DevForum discussion](https://devforum.roblox.com/t/tips-on-realistic-lighting/1261456) | Yes, community advice | Conflicts with the prior creator values; do not present either as a top-game setting. Test for legibility instead. |

### Recommended island lighting test preset

INFERRED, based on the published DevForum ranges above, not copied from any named game:

- Lighting Technology: Future. Keep ShadowMap as the fallback test if Future harms mobile frame rate.
- Daylight: ClockTime around midday; Brightness test at 2.3 first, then compare against 4.0 only if shadows feel too heavy.
- Atmosphere: low density/haze on the play route; reserve denser coloured atmosphere for the far void so it does not obscure the 60-second escape path.
- ColorCorrection: start Saturation +0.10 and Contrast +0.10. Use a warm yellow sunlight / cool-blue shadow split only if it preserves treasure and portal contrast.
- Bloom: begin at Intensity 0.10, Size 0.40, Threshold 0.80. Restrict very bright emissives to the portal, rarity reveal, and guardian wind-up; do not bloom every surface.
- Colour map: grass/stone as low-saturation support colours; treasure as gold/high yellow; escape portal as a single non-treasure accent such as cyan-violet; guardian attacks as red-orange. Do not reuse portal and danger colours.

Acceptance test — INFERRED: from spawn, a player should identify guardian, carried treasure, portal direction, and damage zone without reading UI. Test at phone-sized resolution and the lowest supported graphics setting.

## 2. Container opening, pet reveal, index, and coins

### Evidence

- PS99 eggs are bought with coins; each contains pets that follow the player and collect coins. The first egg has explicit per-pet probability display in the wiki’s egg table. [PS99 egg list](https://pet-simulator.fandom.com/wiki/List_of_Eggs_(Pet_Simulator_99))
- A DevForum thread describing observed PS99 hatching says the pet initially stands beside the player for several seconds, then animatedly approaches the camera. Contributors identify a camera-relative / client-side presentation rather than a basic static UI card. [Thread and embedded source clip](https://devforum.roblox.com/t/how-does-pet-simulator-do-it/2779392)
- Steal An Egg’s listed badges distinguish Eternal, Secret, and Divine hatches; the page labels Divine as the highest tier. This supports explicit tier naming and milestone outcomes, not specific colours or timing. [Steal An Egg wiki](https://roblox.fandom.com/wiki/And_Collect_Rare_Pets/Steal_An_Egg)
- Foltyn’s Steal An Egg video explicitly chapters “Hatching and upgrading” at 1:36, a usable visual reference for category pacing. [YouTube, 1:36](https://www.youtube.com/watch?v=GVTeMVqFJzI&t=96s)
- Adopt Me hatch-animation videos are a visual reference, but no authoritative timing/rarity-colour specification was found. [YouTube reference](https://www.youtube.com/watch?v=WjehLwJ577I)

### Apply to Steal a Treasure

| Moment | Recommended presentation | Evidence status |
|---|---|---|
| Treasure reaches portal | Freeze the countdown only after portal collision; immediately move to a focused reveal scene so success is unambiguous. | INFERRED |
| Opening beat | Put the treasure centre screen; use a short anticipation motion, escalating particles/light, then a single decisive open. Never make common results feel slower than the return-to-play loop can tolerate. | INFERRED; category basis: PS99 camera-relative pet approach and Steal An Egg hatch loop. |
| Pet reveal | Spawn the pet near the player/home, hold it briefly, then move it toward camera or into a camera-relative showcase slot. This mirrors the observed PS99 “stands beside player, then approaches camera” sequence. | Sourced pattern; exact duration INFERRED. |
| Rarity | Use text + icon + colour + audio together. Reserve the strongest screen flash, bass hit, and extended hold for rare outcomes. Avoid communicating rarity by colour alone. | INFERRED; tiered hatch outcomes sourced from Steal An Egg badges. |
| Rarity palette | Suggested: common neutral/gray; uncommon green; rare blue; epic purple; legendary gold; divine/secret white-gold or iridescent. Validate for colour-blind accessibility with labels/icons. | INFERRED; no source found proving these named games use this exact palette. |
| Sound | Three layers: container shake ticks, reveal impact/chime, rarity stinger. Rare stingers should be recognizably different, not merely louder. | INFERRED |
| Pet index | Grid of pet silhouettes; owned state with portrait; undiscovered state with silhouette/question mark; tier filter; source treasure/island label; duplicate count. Show completion at category level, not only a giant total. | INFERRED. PS99’s long egg list and visible hatch odds support clear collection/source mapping. |
| Home earnings | Pets visibly travel to assigned coin targets, strike or interact, create coin pops, then return/retarget. Keep earnings readable at a glance and aggregate spam when many pets act at once. | INFERRED; PS99 confirms pets follow players and collect coins. |
| Coin pop/collect | Make the coin number pop at the target, arc toward a persistent wallet counter, play a brief pickup sound, and update the counter only once per small burst. Retain a compact feed for major earnings. | INFERRED |

Do not claim a specific hatch duration, exact camera FOV, sound ID, rarity colour, or coin animation is copied from PS99/Adopt Me: the cited public material does not establish those specifics.

## 3. Guardian NPC: telegraphs and animation feel

### Evidence

- A telegraph is an intentionally lengthened/accented enemy animation that signals the upcoming attack and gives time to respond. [PlayStation glossary definition](https://www.playstation.com/en-us/editorial/playstation-ultimate-gaming-glossary/)
- Deepwoken’s combat documentation explicitly has a “Telegraphed Attacks” section and links combat video evidence, demonstrating that readable signals are a known Roblox-combat expectation. [Deepwoken combat mechanics wiki](https://deepwoken.fandom.com/wiki/Combat_Mechanics)
- Roblox development material for boss systems lists stun as a defined boss immunity/status dimension; this supports treating stun as a legible state, not a surprise interruption. [Boss-system DevForum post](https://devforum.roblox.com/t/5-attacks-boss-fight-system-control-bosses-from-1-script-easy-customization-free-premade-abilities-and-more/4039013)
- A Roblox boss-fight tutorial is a build reference for parry, dodge, stun, and rage systems, not proof that any commercial game uses specific timings. [YouTube tutorial](https://www.youtube.com/watch?v=ycqx8DUniW4)

No reliable public video timestamp was found for a named popular Roblox guardian showing ring warning, wind-up, and stun in a single verifiable sequence. Do not fabricate timestamps.

### Guardian package for this game

INFERRED, designed for a 60-second steal-and-escape loop:

1. Notice: guardian turns head/body toward intruder; eye/light colour changes; short alert sound.
2. Commit: clearly readable wind-up. Freeze or slow the body’s translation while a limb/weapon pulls back. Use a unique pre-attack sound.
3. Ground attack: show a floor decal/ring that grows or pulses before impact. It must remain visible over grass, treasure, and other players.
4. Impact: one strong hit frame, local camera bump only for the affected player, particle burst, then a recovery window.
5. Stun: distinct star/spark or broken-shield visual, changed idle pose, reduced movement. Give the player a clear steal/escape opportunity rather than stacking another attack immediately.
6. Escalation: while carrying treasure, guardian attacks should make route choices tense, not remove control. Prefer dodgeable area denial over unavoidable tracking damage.

Timing values are intentionally omitted: no trustworthy source here supports exact seconds, and the right values require playtest data. Use the same warning language consistently: red/orange ground = damage; blue/white burst = stun/loot interaction; portal colour never equals danger colour.

## 4. Movement feel

### Identified game

The likely game is **Escape Huss Valley**, not “Hush Valley.” Roblox’s experience page calls it “Escape Huss Valley,” describes it as an escape/survival experience, and lists Sprint: LeftShift and ShiftLock: LeftCTRL. It had 6.0M+ visits at the time retrieved. [Official Roblox page](https://www.roblox.com/games/125215626986308/Escape-Huss-Valley)

Search results also surface a guide describing Huss Valley as a tag-style game with sprinting, vaulting, and sliding. Treat that as secondary evidence, not official documentation. [Guide](https://www.aprasi.com/blogs/trending-topics/huss-valley-roblox-guide)

### Movement reference conclusions

| Reference | What is sourced | Adaptation |
|---|---|---|
| Escape Huss Valley | Dedicated sprint control; escape/survival context; community guide reports sprint/vault/slide. [Official page](https://www.roblox.com/games/125215626986308/Escape-Huss-Valley), [secondary guide](https://www.aprasi.com/blogs/trending-topics/huss-valley-roblox-guide) | INFERRED: use a gradual run-up, not instant maximum speed, to sell a desperate getaway and create a decision when the guardian wakes. |
| Roblox Parkour | Public tutorials cover jump, landing, vaulting, and ledges, making it a useful movement-language reference. [Tutorial](https://www.youtube.com/watch?v=LIy5Plr8qYY) | INFERRED: borrow landing anticipation and vault readability, not a high-skill control burden. |
| AOT Venture | Creator material presents ODM gear as a dedicated movement system. [Movement guide channel](https://www.youtube.com/@Garo) | INFERRED: use it only as a cinematic-motion reference; do not add grapples/air mobility to the first steal loop. |

### Recommended movement curve

INFERRED:

- Walk into run with visible torso lean and cadence change; sprint ramps smoothly so it feels earned.
- Treasure carry should preserve enough speed and jump control to make escape exciting, but make turning/acceleration slightly heavier than empty-handed movement.
- Add camera follow/lean and footstep cadence as cosmetic feedback, not aggressive motion blur. Keep camera changes optional/reduced for comfort.
- One action vocabulary for first session: run, sprint, jump, optional low vault. No slide or stamina unless playtesting proves the guardian cannot create a fair chase without it.
- Portal run should have readable wide routes plus one higher-risk shortcut. This creates clips without making basic completion require parkour mastery.

## 5. TikTok / short-form clip plan for a “Steal a …” game

### Evidence

- TikTok says lead with a hook, value/body, and close; it reports that 90% of ad-recall impact is captured in the first six seconds. [TikTok Creative Codes](https://ads.tiktok.com/business/en/blog/creative-best-practices-top-performing-ads)
- TikTok’s small-business video guide says show the value in the first three seconds; for ads, it recommends 21–34 seconds and jump cuts/zooms/text animation to sustain energy. [TikTok guide](https://ads.tiktok.com/business/en/guides/video-advertising-guide)
- TikTok’s gaming conversion article reports stronger conversion for gaming ads with five or more scenes and an advantage for on-screen text within the first seven seconds. These are paid-ad findings, not a guarantee for organic virality. [TikTok gaming creative guidance](https://ads.tiktok.com/business/en-US/blog/creative-that-drives-conversions)
- TikTok’s game creative page recommends a hook in the first 3–6 seconds, immediate gameplay after it, and a clear CTA; it specifically suggests suspense, humor, twists, collaboration, and relatable situations. [TikTok game creative tips](https://ads.tiktok.com/business/creativecenter/quicktok/online/creative-tips-for-strategic-games/pc/en)
- In the comparable category, a Steal a Brainrot TikTok result advertises “How to Take the New Brainrot,” a concrete how-to / new-item hook; another result is framed around the game reaching a major milestone. [How-to example](https://www.tiktok.com/@chy.tt/video/7548233970421337374), [news/milestone example](https://www.tiktok.com/@dakreekcraft/video/7607853770894085406)
- Steal An Egg content has clear “starting the egg hunt” and “hatching and upgrading” chapters, supporting the steal → reveal → progression structure. [YouTube video](https://www.youtube.com/watch?v=GVTeMVqFJzI)

### Formats to make

All clip prescriptions below are INFERRED applications of the sourced TikTok guidance.

| Format | Hook in first 1–3 seconds | Middle | Payoff / close | Suggested edit length |
|---|---|---|---|---:|
| One HP escape | “I stole the guardian’s [rare treasure] with 1 second left.” Show danger first, not title card. | Guardian wind-up, route cut, portal almost missed. | Portal hit → pet reveal. | 15–25 s |
| Friend betrayal | “He said he would distract the guardian.” Show the guardian turning toward the player. | Failed teamwork / chase cuts. | One player escapes, reaction caption. | 15–30 s |
| Rare treasure challenge | “Can a starter pet escape with the divine treasure?” | One attempt, bad dodge, recovery. | Reveal tier and coin earn at home. | 20–34 s |
| Route secret | “The safe path is slower — this shortcut is insane.” | Before/after route comparison. | Timer comparison; ask viewers which route to take. | 15–25 s |
| Guardian pattern | “Wait for THIS attack, then steal.” | One readable ring/wind-up, stun, grab. | Successful escape. | 12–20 s |
| Pet outcome | “I risked 60 seconds for this pet.” Show the final pet silhouette or reaction first. | Theft and portal clips in fast cuts. | Full pet reveal + first coin pop. | 15–25 s |

Production rules:

- Use vertical gameplay, readable captions from the first frame, and native/creator-like delivery rather than polished logo-first trailers. This follows TikTok’s “TikTok first” and early-text guidance.
- Show the real core action immediately: stealing, guardian danger, countdown, or rare reveal. Do not lead with a cinematic island flyover.
- Cut around state changes: spotted, ring appears, treasure grabbed, timer reaches danger, portal reached, pet revealed, coin earned.
- Use a question or challenge that viewers can answer in comments: “safe route or shortcut?”, “would you risk the rare treasure?”, “which guardian is worst?” This is INFERRED; it is not a TikTok-published causal claim.
- Treat 21–34 seconds as an ad benchmark, not an organic requirement. Test shorter clips for a single clutch moment and longer clips only when the story earns it.

## Source gaps and risks

- No named top game in the request publicly exposes a verified Lighting hierarchy with its actual Technology, Atmosphere, ColorCorrection, and Bloom values. All named-game lighting descriptions here are marked INFERRED.
- No trustworthy source found establishes exact Adopt Me/PS99 hatch timings, exact rarity colours, sound design values, or coin-pickup timings. Recommendations are marked INFERRED.
- No single verified popular-Roblox guardian video yielded the requested attack-telegraph timestamps. The guardian section therefore cites general/source-backed combat concepts and explicitly avoids invented timestamps.
- “Huss Valley” is confirmed as the likely intended name; the official page confirms sprint, but not gradual acceleration characteristics. The gradual run-up recommendation is INFERRED.

## Build priority

1. Build the 60-second core loop first: alert → telegraphed guardian → steal → sprint route → portal → pet reveal → first home coin. INFERRED prioritization.
2. Compare that single loop side-by-side with Steal An Egg (category loop) and PS99 (reward readability) before expanding pet/index content. Evidence basis: cited category and economy references.
3. Instrument and playtest completion rate, damage source, abandonment during opening, and whether players recognize portal/danger without UI. Exact success thresholds are UNKNOWN until a playable build exists.

## Lessons

1. When a named game’s internal settings are not public, describe the observed look and label the implementation recommendation INFERRED, because guessed values are not evidence.
2. When the product has a 60-second theft loop, make the guardian warning, portal direction, and reward reveal readable before adding movement complexity, because those are the make-or-break state changes.
3. When making short clips, start with the theft danger or rare reward in the first seconds, because TikTok’s own guidance prioritizes early hooks and immediate gameplay.
