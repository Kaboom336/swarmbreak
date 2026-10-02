# R4 genre feel: first 60 seconds and moment-to-moment feel (2026-10-02)

## Evidence caveat (read first)
WebSearch returned only titles + URLs here, with NO text snippets, and WebFetch was banned. So nothing below is
page-verified. Each game's lines are labelled:
- [TITLE] = supported by what the result title/URL shows exists (e.g. a wiki page called "Rush").
- [VIDEO] = from our own VIDEO-NOTES-2026-10-02.md frames (Duels clip), which we did see.
- [PRIOR] = my background knowledge of the game, unverified this run. Treat as hypothesis to confirm by playing or reading.
No numbers are quoted. Estimates are marked (est).

## Per-game cards (visual identity / juice / HUD)
### Rivals (Nosniy Games) - https://roblox.fandom.com/wiki/Nosniy_Games/RIVALS ; https://rivals-guide.wiki/
- Look [PRIOR]: clean, bright, competitive-FPS styling; readable maps, weapon-skin focus.
- Juice [PRIOR]: hitmarkers, headshot sounds, kill feed, per-weapon recoil. [TITLE] crosshair-customization pages exist
  (rocodes.gg/decals/game/rivals-crosshairs; pixeltwelve.com best-settings) = players care about the aim reticle enough to tune it.
- HUD [PRIOR]: crosshair, ammo, health, round score, kill feed. Minimal.
### Tower Defense Simulator - https://tds.fandom.com/wiki/How_to_Play
- Look [PRIOR]: cartoon top-down, towers are the characters, enemies readable by silhouette/colour.
- Juice [PRIOR]: tower attack projectiles/flashes, money pop on kill, upgrade level-up effects.
- HUD [TITLE+PRIOR]: wiki "How to Play" covers wave, cash, tower placement and upgrades; HUD = wave counter, cash, base HP, tower bar.
### Doors - https://doorsgame.wiki/wiki/Rush ; https://doors-game.fandom.com/wiki/Seek
- Look [PRIOR]: dim hotel corridors, one hero light, entity silhouettes.
- Juice [TITLE+PRIOR]: per-entity wiki pages (Rush, Seek) and a guide titled "All 14 Hostile Entities and the Tell for Each"
  (https://bloxguidesgg.com/games/doors) show each threat has a distinct TELL (audio/light) before it hits. Light flicker + sound is the warning.
- HUD [PRIOR]: almost none; items bottom, a few prompts. Atmosphere over UI.
### Blox Fruits - https://blox-fruits.fandom.com/wiki/Stats ; https://bloxfruitswiki.org/wiki/quests/
- Look [PRIOR]: anime-ish, big colourful ability VFX, many islands.
- Juice [PRIOR]: large skill VFX, damage numbers, level-up. [TITLE] "Stats" and "Quests" pages and a damage calculator exist = numbers/progression are the core hook.
- HUD [PRIOR]: health/energy bars, level, ability hotbar with cooldowns, quest tracker.
### Grow a Garden - https://roblox.fandom.com/wiki/The_Garden_Game/Grow_a_Garden ; https://growagarden.fandom.com/wiki/Grow_a_Garden_Wiki
- Look [PRIOR]: soft, cute, saturated; calm.
- Juice [PRIOR]: coin chime on sell, plant pop on harvest, timed weather events that change the whole garden.
- HUD [PRIOR]: money counter, seed shop timer, event banner. Low-effort, high-frequency rewards.
### Dead Rails - https://roblox.fandom.com/wiki/RCM_Games/Dead_Rails ; https://deadrails.fandom.com/wiki/Gameplays_and_Strategy
- Look [PRIOR]: dusty wild-west, low-poly, dark nights.
- Juice [TITLE+PRIOR]: GameRant headline "Roblox Zombie Game is Blowing Up" (https://gamerant.com/roblox-zombie-game-dead-rails-popularity/);
  loop is a moving train you protect while scavenging; night pressure.
- HUD [PRIOR]: distance travelled, bonds/currency, weapon slots, train status.
### Jailbreak - https://roblox.fandom.com/wiki/Badimo/Jailbreak ; https://jailbreak.fandom.com/wiki/Cash
- Look [PRIOR]: readable city, vehicles, two clearly coloured teams.
- Juice [PRIOR]: robbery alert/timers, cash on screen, sirens.
- HUD [TITLE+PRIOR]: wiki has Cash and robbery pages; HUD = cash, objective/heist timer, minimap.
### Final Swarm (direct competitor) - https://final-swarm-rblx.fandom.com/wiki/Worlds_%26_Gameplay_Loop ; https://final-swarm.wiki/how-to-survive-waves/
- [TITLE] has a "Worlds & Gameplay Loop" page and a "Kiting Tips" wave-survival guide: kiting (moving while shooting) is the core skill; worlds are progression tiers.
- Look/HUD: not verified. Must read (see list).
### Duels clip (our own notes) [VIDEO] - /mnt/project-files/roblox/VIDEO-NOTES-2026-10-02.md
- Floating damage numbers, kill feed with distance, death burst effect, round timer top-centre with squad portraits, chunky UI.

## 10 transferable feel rules for Swarm Break (hypotheses; rules 1-3 best supported)
1. Every hit confirms itself in 3 channels at once: hitmarker + hit sound + damage number (Duels clip [VIDEO]; Rivals/Blox Fruits [PRIOR]). Different tick for headshot/crit.
2. Every kill pays out visibly in under 0.3s (est): death burst + coin/XP pop flying to the counter. (Duels kill effect [VIDEO]; Grow a Garden coin chime [PRIOR].)
3. Each enemy type gets a TELL: distinct sound + silhouette/light before its attack (Doors per-entity tells [TITLE]). Brute vs runner vs spitter must be recognisable with the HUD off.
4. HUD minimal: wave number, timer, health, ammo, currency, squad portraits. Nothing else on screen mid-fight (Duels, Rivals, Doors).
5. Support kiting: movement stays fast and shots keep landing while moving; no stop-to-shoot (Final Swarm kiting guide [TITLE]).
6. Make the ONE hero light/colour read: players and pickups in warm saturated colours, enemies in a contrasting cool or dark palette, so the screen parses in a glance (Doors lighting [PRIOR]; Duels saturation [VIDEO]).
7. Rhythm of waves: build a calm beat (shop/prep) then pressure, with an event banner announcing each change (Grow a Garden weather events, Dead Rails night [PRIOR]).
8. Cooldown/ability hotbar always shows readiness (glow or ping when ready) (Blox Fruits [PRIOR]).
9. Spawn-in and build-in animations for turrets/gates (parts assemble with glow/dust): cheap juice, great on camera (Video B notes [VIDEO]).
10. First 60 seconds: in a fight within ~10s (est), first kill within ~20s (est), first upgrade/level-up pop by 60s (est). No long menus before shooting. (Pattern across all above [PRIOR]; verify by timing Final Swarm and Dead Rails on video.)

## What this does NOT answer
- Real HUD layouts and exact timings; all need video or in-game observation.
- Why our render gallery was judged poor; that is a modeling/lighting question for r4-build-craft.md.

## Must-read later (unread; do NOT WebFetch, owner/other agent or watch video)
- https://final-swarm-rblx.fandom.com/wiki/Worlds_%26_Gameplay_Loop (closest competitor loop)
- https://final-swarm.wiki/how-to-survive-waves/ (kiting)
- https://final-swarm-9mm.pages.dev/guides/beginner-guide/ (first waves)
- https://bloxguidesgg.com/games/doors (all entity tells)
- https://tds.fandom.com/wiki/How_to_Play (HUD/loop)
- https://deadrails.fandom.com/wiki/Gameplays_and_Strategy and https://www.bluestacks.com/blog/game-guides/roblox/rl-dead-rails-beginners-guide-en.html
- https://www.robloxtutorial.com/games/rivals/how-to-play-rivals-roblox-fps-beginner-guide/
- https://jailbreakgame.wiki/guides/getting-started/ (first minutes)
- https://noping.com/blog/grow-a-garden-gameplay-guide
- YouTube "first 60 seconds" footage of each game (search by title; not done).
