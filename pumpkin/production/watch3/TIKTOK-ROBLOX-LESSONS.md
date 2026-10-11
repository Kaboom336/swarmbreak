# TikTok / creator lessons for Roblox games (research 2026-10-11)

Method and honesty note: TikTok video pages expose only captions (no transcripts; yt-dlp subs = NA; no whisper installed). So TikTok evidence below is caption/title level (what the creator says the video teaches). The spoken substance comes from YouTube transcripts of the same creator genre (YT = pulled with yt-dlp auto-subs) plus the common Roblox-dev consensus. Where a rule is my inference, it is marked (inf). TikTok base: https://www.tiktok.com/

## (a) Owner favourites log (@kabbom336, Favorites tab, 5815 saved, scanned newest ~206)
Favorites are overwhelmingly NOT game dev (fitness, Drake, bikes, homelab, Claude/agents, height). Only the newest ~35 are Roblox/dev; they cluster on "Roblox + Claude/Opus + Blender VFX + UI + SFX".

| creator | link | tip / what it teaches |
|---|---|---|
| @solodev_t | tiktok.com/@solodev_t/video/7695102365577252128 | Blender + Claude built power VFX; "first preview, not final look" - ship ability VFX early, iterate |
| @solodev_t | tiktok.com/@solodev_t/video/7694345827648654624 | Out of Claude credits, so polishing flaws by hand: budget AI usage, polish pass is human |
| @yag0iz | tiktok.com/@yag0iz/video/7695254311571393823 | 2-player lantern tycoon; creator himself says UI "looks shit" - UI is the commonly weakest part of AI/solo builds |
| @sailent.sfx | tiktok.com/@sailent.sfx/video/7679740203690413326 (+7681643165253717261, 7680492931366554910) | Roblox SFX design reels: ability sounds sold as commissions - sound is a differentiator |
| @cloudsfx4 | tiktok.com/@cloudsfx4/video/7682798727530106132 | Sound-design showreel for Roblox |
| @turiptoroblox | tiktok.com/@turiptoroblox/video/7693317161586036000 | "Opus 5.5 is crazy" Roblox + Claude; also "clean Roblox UI with Claude" and "Tools to make Roblox games" (search results) |
| @cuhfilme | tiktok.com/@cuhfilme/video/7692972841637055774 | #robloxdev #claude #chatgpt AI-assisted dev reel |
| @006_xoxoa | tiktok.com/@006_xoxoa/video/7693371046598053134 | Roblox RTX / #codex story build |
| @ludc45 | tiktok.com/@ludc45/video/7693346958177504542 | "day 1 of vfx slop" - daily VFX practice log |
| @frostbladegames | tiktok.com/@frostbladegames/video/7681462339568192782 and 7681849596540243214 | Pixel Blade RPG: "Animation vs Release" (before/after of polish) and a boss-fight showcase: animation polish is the visible gap |
| @xedimzz | tiktok.com/@xedimzz/video/7676338989548211486 | Gate of Babylon VFX/build in Studio: spectacle moments sell |
| @playwallball | tiktok.com/@playwallball/video/7692525624761666829 | Wall Ball, a game sold on nostalgia ("based on YOUR childhood") - one-sentence hook |
| @rikdeveloper | tiktok.com/@rikdeveloper/video/7693601999597653281 | Roblox dev milestone post |
| @outretroed | tiktok.com/@outretroed/video/7693393673521777934 | Roblox dev vent |
| (cover text) | favorites grid | "My 6 month journey as a solo Roblox developer" (1.3M views), "Week 3 of making abilities for my Roblox game, Opus 4.5 / Blender / VFX Studio" (40K), "Claude building inconsistencies..." (64K) |

## Public search coverage (6 queries, ~70 videos' captions read)
Key hits: jakeinatx "If your Roblox game has one of these, REMOVE IT" (7671398345696431373), "Your roblox game will fail" (...8-9), "This Roblox stat is SO IMPORTANT" (...8-8); shadarchives/duomillionz "5 things before you publish" (7687094359082192141); zohab.dev "why YOUR games are flopping" + plugin tip (7669139339267345686); KH Studios "Roblox lighting 100X better" (35.6K likes); FlayoDev "UI scale for mobile in 1 click" (16.1K), "best UI tip"; phoxik "rebuilt button in Figma, one word in layer name makes it bounce with sounds"; fishmopf "UI Tutorial Part 3 - visual effects for better UI" (20K likes); MysticDev "lighting for your simulator" (17.6K); pr0_devv Bezier VFX; Dev Mind "Roblox devs need to see this" (30.5K) + "Don't be the 90%"; Jay "cash grabs won't save you" / "if you're a new Roblox dev listen up"; timrobloxgames "making vfx for my game" (7.3K).

## (b) 25 actionable rules
Sources: YT1 = youtube.com/watch?v=Y93DRfB-Deo (Here's Why Roblox Games Blow Up), YT2 = Le4QhC3dDGk (How To Make A Popular Roblox Game), YT3 = f63stwpsaXw (5 Dev Mistakes), YT4 = fqb9MfRqK9I (20 Game Dev Tips). TT = TikTok links above.

### Core loop & retention
1. The game must be explainable in one sentence and playable within seconds; if it needs a tutorial the design is failing. Guide with big buttons, arrows, animation, sound, not text. (YT1)
2. Core loop must be satisfying every single repetition and still fun for a rich late-game player and a broke new player. (YT2)
3. Do not make a game that is "done in 10 minutes": add replayability (leaderboards, daily challenges, modes, a different experience each join). (YT2, Tower of Hell example)
4. Build FOMO stakes: timed events, rare spawns, offline-catch-up ("what if a rare drops while I'm gone"), leaderboard pressure. Retention = the "pulled back" feeling, not a daily-reward popup alone. (YT1)
5. Roblox ranks on session length, retention and non-pay-to-win monetization; design to those three numbers. (YT1, YT2; TT jakeinatx "This Roblox stat is SO IMPORTANT")
6. Make it social: trading, gifting, co-op, things worth doing with friends; friends bring friends. (YT2)
7. Scope tiny: one mechanic, whole game revolves around it; ship small, add features from feedback; 10 small games beat 1 huge. (YT3, YT4, tip 2)

### UI / HUD
8. Immediate feedback on every action ("click something, get an explosion"), rewards on interaction, not after 10 minutes of grinding. (YT1)
9. Keep first screen uncluttered; players must know what to do without reading. Use consistent button styles, one icon+label pattern. (YT1, TT FlayoDev best UI tip)
10. Scale UI for mobile (UIScale / anchor+scale, test on phone emulator); most players are on phone. (TT FlayoDev 16.1K "scale UI for mobile in 1 click")
11. Buttons must animate: hover grow, press squish, sound on click (TT phoxik: button bounce + sounds from a layer-name convention). Animate panel open/close and counters with tweens (TT fishmopf).
12. Design UI in Figma/with a token system (colour, stroke, radius, font) before building; AI-generated UI is the usual weak spot (TT yag0iz self-critique; TT turiptoroblox "clean UI with Claude").

### Visuals / colour / art direction
13. Lighting is the cheapest big upgrade: Future lighting, tuned Atmosphere, ColorCorrection, Bloom, SunRays, correct time-of-day. (TT KH Studios, MysticDev simulator lighting)
14. Pick one palette and mood per game (Halloween = deep purple/orange/black with glowing accents) and keep it everywhere; saturated but not neon-everywhere. (inf; YT3 "bright colors" for thumbnail)
15. Stylised, consistent decor beats realism; keep part counts low, use materials/textures sparingly. (TT casaulIy "stylized decor")

### Game feel (animation / VFX / SFX)
16. Ship VFX/ability moments early and show a before/after: unanimated release looks cheap ("Animation vs Release"). (TT frostbladegames)
17. Hit juice stack: camera shake, hitstop (a few frames), squash/pop on the target, particles, damage/loot numbers, sound. (inf; TT sailent.sfx/pr0_devv)
18. SFX: layered, pitch-randomised on repeat actions, rising pitch on combos; dedicated sound per reward tier. (TT sailent.sfx, cloudsfx4)
19. Use Bezier/tweened paths for coins and loot flying to the HUD counter so collection feels earned. (TT pr0_devv Bezier VFX)

### Monetization
20. Sell convenience and cosmetics, not power: teleport pass, auto-collect, timed boosts, trails/skins; make the purchase moment feel good. (YT2)
21. Value must be visible: owned items and boosts show on the HUD and on the character, which also acts as ads for other players. (inf from YT2 "make purchases feel good")

### Discovery / thumbnails
22. Thumbnail + title are the first impression: bright colours, a clear character render, minimal text; title says exactly what the game is (Hide or Die vs Prop Hunt). (YT3)
23. Marketing early: Discord/group, post sneak peeks before launch; a cheap TikTok/Shorts creator clip can seed the algorithm better than big Robux ads; ads cannot fix a weak loop. (YT3, YT2, TT dev tips)

### Dev workflow
24. Playtest with real people early and often; keep a feedback board; fix what several people say. (YT3)
25. Pre-publish checklist: mobile test, thumbnail/icon, rejoin/data test, private -> public. (TT shadarchives "5 things before you publish"). Use AI for code/VFX drafts but budget credits and do a human polish pass. (TT solodev_t)

## (c) 10 rules "Steal a Pumpkin" most violates
Evidence: FINISH-PLAN.md and shots u2-hud.jpg, u2-shop.jpg, hub-v4-studs.jpg (pumpkin/production/shots/).
1. Rule 14 palette/mood: screenshots are lime-green grass, bright blue sky, white tiles; Halloween only appears in the purple wall and the King. It reads as Easter-day, not Halloween. Fix: dusk/Halloween sky, dark-purple/orange palette, ColorCorrection+fog.
2. Rule 13 lighting: flat bright daylight, no Atmosphere depth, no bloom on glowing jack-o-lantern/lamps. Night look is on the cut list, which is the opposite of the theme.
3. Rule 1/8 first-seconds clarity: spawn plaza is huge and nearly empty (hub-v4); nothing says "swing scythe, smash pumpkins". Needs an arrow, glowing target pumpkin and a prompt in the first 5 seconds.
4. Rule 8/17 game feel: no visible hit VFX/shake/numbers/loot fly in any screenshot; the 3-swing scythe is the identity hook but only seen as a static held prop (scythe-s1-hold).
5. Rule 9 HUD clutter and hierarchy: small unlabeled counters (0/3, 0) bottom-left, two timer pills bottom-right (King / Nests) competing, clipped "SHOP / SELL" world text at screen edges; no prominent currency counter.
6. Rule 12 UI system: shop panel is a plain dark card with tabs cut off by a cramped scroll; item cards show only price numbers; mixed icon/label styles (Pets/Quests/Daily labels outside buttons, Shop/Index inside).
7. Rule 11 button animation/sound: nothing in plan or shots about squish/hover/click sounds or panel tweens.
8. Rule 18 audio: plan (FINISH-PLAN) has zero SFX or music tasks; every hook (swing, hatch, King) depends on sound.
9. Rules 4/5 retention: Offline income and the night look are cut; there are timers (King, Nests) but no rare-drop FOMO, leaderboard or daily-streak stakes beyond a "Daily" button.
10. Rules 22/23 discovery: thumbnail and marketing sit only in the "Identity pass" hour (12:30); no TikTok/Discord seeding or clip-worthy moment plan; also Rule 25 playtest happens late (14:30 Zion) and rejoin/mobile UI scaling (Rule 10) is not scheduled.
