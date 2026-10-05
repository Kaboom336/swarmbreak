# R5 wide research: combat feel, controls, retention, first minute, AI-made games, playtesting, launch bar (2026-10-05)

## Evidence caveat (read first, same limit as R4)
WebSearch returned ONLY page titles + URLs this run (no snippets); WebFetch is banned. So:
- [TITLE] = the cited page exists and its title says this. Content NOT read.
- [PRIOR] = background knowledge of the module/game, unverified this run. Treat as hypothesis; confirm by playing or reading.
- [INFERRED] = my reasoning from the above.
- No player counts, revenue or D1/D7 numbers are quoted. Public D1/D7 benchmarks for Roblox were NOT found. The only metric
  definitions are in Roblox's own analytics docs (title-level): https://create.roblox.com/docs/production/analytics/retention
Earlier research (r2-ai-made, r4-ai-build, r4-genre-feel, BEST-OF) already covers: Studio going agentic / built-in MCP / Playtesting Agent
(https://about.roblox.com/newsroom/2026/04/roblox-studio-going-agentic), Cube, OpenGameEval, Mining Tycoon case, 10 feel rules. Not repeated; this goes into HOW.

Honest bottom line: we cannot verify "why Hunty feels good" from text search. The most reliable output is a build list of well-known, cheap feel
techniques (named modules below) plus a test method that forces us to FEEL the game with real input. The owner's diagnosis (environment ok, feel/effects/pacing behind) matches a gap that is
fixable with a fixed, small set of techniques applied to EVERY hit, not new content.

---------------------------------------------------------------------------------------------------
## 1. Combat feel: what makes hits good in Roblox action games

### What we should copy (buildable list)
1. **One `HitFeedback.play(hitInfo)` function that every weapon calls**, firing 8 channels in the SAME frame: (a) enemy white flash 0.06 s (Highlight FillTransparency or
   color-tween on parts), (b) hit sound (layered, below), (c) 6-12 spark/chip particles at hit point, (d) damage number (tween up, size by damage, crit = bigger+yellow), (e) 1-3 frame
   hit-stop on attacker animation, (f) enemy knockback/stagger, (g) camera nudge, (h) crosshair/hitmarker tick. Missing channels are the likeliest cause of "feels floaty" [INFERRED].
2. **Hit-stop by AnimationTrack:AdjustSpeed(0) for 0.04-0.08 s, then restore** (small hit 0.04, kill 0.08, boss slam 0.12). Roblox has no engine hit-stop; devs do it with AdjustSpeed
   on the attacker's track and often the victim's [PRIOR]. Pitfall: AdjustSpeed has threads of "working inconsistently" / "not adjusting speed"
   (https://devforum.roblox.com/t/adjustspeed-working-inconsistently/2643111 , https://devforum.roblox.com/t/anim-adjust-speed-not-working/2399494 [TITLE]) so test it on a track that is
   already playing and set it after the track has started (last-write-wins race) [INFERRED]. Never freeze the camera or the player's movement; only the attack track.
3. **Hitboxes: swept, not touched.** Use a swept cast along the weapon arc each Heartbeat for melee. Named modules: RaycastHitbox (TeamSwordphin, "V.4" thread
   https://devforum.roblox.com/t/374482 [TITLE]), `WorldRoot:Shapecast/Blockcast` (https://devforum.roblox.com/t/introducing-shapecasts/2320655 [TITLE]; note a thread "Shapecast hitbox inaccurate",
   https://devforum.roblox.com/t/shapecast-hitbox-inaccurate/2997929 [TITLE] - test at high speeds), "Hitbox Module by Salvatore" (https://devforum.roblox.com/t/hitbox-module-by-salvatore/3913281 [TITLE]),
   "HitboxClass v2.0 OOP-based" (https://devforum.roblox.com/t/hitboxclass-v20-a-powerful-oop-based-hitbox-module/3929512 [TITLE]). For a scythe: a 120-180 degree arc sector query
   (GetPartBoundsInRadius + angle check) fired at the animation's swing keyframe marker, hitting ALL enemies in the arc, is the swarm-friendly choice [INFERRED]. Make it generous: widen hit radius 15-25% on mobile [INFERRED].
4. **Server owns damage, client owns feedback.** Client plays flash/sound/shake the instant the player swings or sees the hit (predicted); server validates and applies HP. Else lag makes every hit feel late
   [PRIOR; standard Roblox practice].
5. **Knockback with LinearVelocity (not BodyVelocity, deprecated) for 0.12-0.2 s, ImpulseMagnitude scaled by enemy weight.** Known pain: lag/teleporting when the server owns the part (threads: "Laggy knockback (linear velocity)"
   https://devforum.roblox.com/t/laggy-knockback-linear-velocity/2950780 , "How to make proper knockback for a combat system?" https://devforum.roblox.com/t/how-to-make-proper-knockback-for-a-combat-system/3936670 [TITLE]).
   Fix pattern [PRIOR]: for NPC enemies the server sets network ownership to server (`SetNetworkOwner(nil)`), applies the velocity, and the client interpolates. Swarm enemies: short stagger (0.15 s) +
   0.5-1.5 stud shove; big enemies: no knockback, just a flinch + sound; boss: armored (no stagger) except on a "break" phase.
6. **Death = ragdoll-lite, not full ragdoll.** For 100+ swarm enemies skip Motor6D ragdoll; instead: pop, spin 90-180 degrees, launch 3-6 studs, fade over 0.4 s with a particle puff and coin/XP burst. Full ragdoll is for
   humanoid bosses/kill-cams only (cost and physics instability) [INFERRED].
7. **Animation: put a swing/impact marker in each attack animation (AnimationEvent / keyframe marker `Hit`) and fire hitbox + VFX + sound ON that marker, not on a timer.** This is how animation and effect stay in sync [PRIOR].
8. **Attack timeline = anticipation (windup 0.08-0.12 s) - strike (1-3 frames) - overshoot - recovery cancelable by dash/next hit.** Cancel windows are what make Roblox combo games feel snappy [PRIOR; INFERRED for scythe].
9. **Sound layering (3 layers per hit): transient click/crack (<50 ms) + body thump (low) + material tail (squelch/glass/metal) with ±8% PlaybackSpeed random and 3+ variants, plus a pitch-up on crit/combo.** Keep a
   per-sound cooldown (e.g. max 6 hits sounds/0.1 s) so swarms do not become noise [INFERRED; r3-sound.md has more].
10. **Camera shake with a trauma model**: add trauma on events (hit 0.08, kill 0.15, boss slam 0.5), shake = trauma^2 * noise, decays ~1.5/s. Named modules: EZ Camera Shake port
    (https://devforum.roblox.com/t/ez-camera-shake-ported-to-roblox/98482 [TITLE]) and a newer "GG Camera Shake - Screenshake that doesn't suck" (https://devforum.roblox.com/t/gg-camera-shake-screenshake-that-doesnt-suck/4731267 [TITLE]).
    Rule: hits on single weak enemies shake ~0; only kills, crits, big hits, own damage taken. Add an option to disable (motion-sickness).
11. **VFX recipe, in order of value per hour**: (1) flash+sparks at hit point, (2) slash arc mesh/trail on the scythe (Trail or a Beam/transparent mesh with scrolling-UV or a quick scale-in+fade), (3) ground ring/shockwave on
    big events (neon cylinder scaling 0->radius in 0.25 s with transparency fade), (4) dust puff on enemy landing. Use Beams for lightning/links, ParticleEmitter flipbooks (Texture sheet, `FlipbookLayout` Grid4x4/8x8,
    `FlipbookMode`) for smoke/explosion/slash frames [PRIOR; Roblox docs], and a bright additive (`LightEmission`=1) look. "How to create VFX?" https://devforum.roblox.com/t/how-to-create-vfx/4029502 [TITLE];
    Roblox VFX curriculum "Next steps" https://create.roblox.com/docs/tutorials/curriculums/artist/next-steps [TITLE].
12. **Buy, don't hand-make, the first VFX set.** Marketplace sources exist: "RPG & Combat Effects Pack" https://builtbybit.com/resources/rpg-combat-effects-pack.110092/ , "100+ Combat VFX Asset Pack"
    https://builtbybit.com/resources/100-combat-vfx-asset-pack.115026/ , and a "8,000+ effects" library https://builtbybit.com/resources/8000-massive-vfx-library-anime-aura.105063/ [TITLE only; vendor claims, check licence
    and that effects are Roblox-native before buying]. Also Fiverr Roblox VFX/anime-effect sellers (https://de.fiverr.com/emmyjovfx/create-roblox-vfx-combat-abilities-anime-effects-and-animation [TITLE]).
    Owner decision needed (cost).

### Where animation comes from (what top games do)
- **Moon Animator** (plugin) is the standard community tool for keyframing rigs/VFX and exporting to Animation; guides exist (https://www.exitlag.com/blog/moon-animator-roblox/ [TITLE, low-quality SEO pages]) [PRIOR: R15/custom rigs, camera and VFX keyframing].
- Roblox's own Animation Editor + **free animation uploading/mocap from video** (Animation Capture, "Animation from video") [PRIOR; verify in docs] - useful for a creature swarm? No: for 20+ enemy types, hand-keying 4 loops (idle/walk/attack/die) per archetype and re-using across skins is realistic [INFERRED].
- Top anime/fighting games (Type Soul, Jujutsu Shenanigans, TSB) are known to use custom per-move animations plus per-move VFX, stun/hit-stop/ragdoll frameworks and ~4-hit M1 strings with a finisher knockback [PRIOR; unverified].
  The Strongest Battlegrounds is widely discussed for its combat mechanics (games.gg combat guide, title: https://games.gg/ur/roblox/guides/the-strongest-battlegrounds-combat-guide/ [TITLE]).
- Blox Fruits: skill-based combos with per-style moves (wiki combo pages for each fruit/style exist, e.g. https://blox-fruits.fandom.com/wiki/Koko/Combos [TITLE]) [PRIOR: big coloured numbers and ability circles, from BEST-OF].
- For us (Codex coder): do NOT chase fighter-style hand-animated combos for 100 enemies. Copy the *swarm* approach: one great 3-hit scythe string + 2 abilities, each with the 8-channel feedback, and procedural (tween-based) enemy hit-reactions.

### Specific feel numbers to start from (all [INFERRED] tuning defaults, tune by playing)
| Event | Hit-stop | Shake trauma | Knockback | Sound layers |
|---|---|---|---|---|
| scythe hit, small enemy | 0.03 s | 0 | 1 stud, 0.12 s | 3 |
| scythe finisher (3rd hit) | 0.07 s | 0.12 | 3 studs, 0.2 s | 4 + whoosh |
| kill | 0 | 0.05 (0.15 if elite) | launch 4 studs + spin | pop + coin |
| gun hit | 0 | 0 | 0.3 stud | tick + hitmarker |
| player damaged | 0 | 0.25 | 2 studs | grunt + red vignette 0.2 s |
| boss slam | 0.1 | 0.5 | none (ring pushes players) | sub-bass + crack |

---------------------------------------------------------------------------------------------------
## 2. Camera and controls, mobile first

### What we should copy
1. **Default to a fixed-offset over-the-shoulder / slightly-top-down camera that follows the character, with right-thumb free drag to orbit.** Do not require shift-lock on mobile (shift-lock is a toggle that many
   mobile players do not find; a guide titled "how to enable shift lock on roblox mobile" exists, https://www.findingdulcinea.com/how-to-enable-shift-lock-on-roblox-mobile/ [TITLE]). Provide a custom toggle button for shift-lock-like facing instead [INFERRED].
2. **Auto-target on attack, not lock-on.** One big ATTACK button (right thumb, bottom-right, ≥ 80 px at 1080p-equivalent). On press: character snaps/turns to the nearest enemy within a 70-90 degree cone in front of the move direction
   (soft aim assist, lerp the facing 0.08 s) and attacks. Hold = auto-repeat. This is the standard mobile action-RPG fix [INFERRED; lock-on camera systems exist in many genres - generic lock-on feedback threads e.g. https://community.monsterhunternow.com/t/improved-lock-on-suggestion-dropdown-ver/5459 [TITLE]].
3. **Button layout (right thumb arc):** big ATTACK at bottom-right corner; ability 1/2/3 and DASH on an arc above/left of it; reload/swap weapon small, far from attack. Bottom-left is the thumbstick (Roblox dynamic thumbstick).
   Use ContextActionService `CreateButton`/`SetPosition` or custom ScreenGui; Roblox mobile input doc: https://create.roblox.com/docs/input/mobile [TITLE]. Keep every button at least 48 dp and safe-area aware.
4. **Dash/dodge is a first-class button** (short i-frames 0.2 s, cooldown 1.5 s). It is the skill expression in swarm games (kiting, see Final Swarm kiting guide in r4).
5. **Gun fire = auto-aim assist toward nearest enemy in cone, no manual aiming on mobile**; on PC/console aim with mouse/right stick. Keep range-limited and visibly telegraphed with a tracer so players trust it.
6. **Controller/PC parity**: bind the same actions through ContextActionService (E/Q/F/LeftShift/Space, Mouse1) so PC testers can drive an AI/bot with real inputs too (see Q6).
7. **Camera FOV kick + tilt on dash/hit (BEST-OF Rivals idea) at 3-6 degrees, 0.1 s**, and FOV +8 on boss intro.
8. **Mobile readability**: damage numbers and telegraph rings at 1.5x size of desktop; HUD scale via `GuiService`/screen size; cap particles (r3-performance.md).

### Not verified
Exact button layouts of Hunty Zombie, Dead Rails, Anime Vanguards could not be confirmed from text; the owner's screenshots / a phone screen recording of each are the authority. Action: record a 60 s phone capture of Hunty and Dead Rails and label button positions (task for the owner).

---------------------------------------------------------------------------------------------------
## 3. Progression and why players come back

### What we should copy
1. **Three timescales in the HUD at all times**: this-minute (kill streak / XP bar fills in seconds), this-session (wave/stage and a chest at the end), this-week (Daily Tasks + weekly board). BEST-OF already
   lists Rivals daily tasks and Grow a Garden "UPDATE IN" timers.
2. **A short daily-reward calendar (7 days, last day = guaranteed named unit/weapon crate) with login streak.** Ready-made systems exist as products (https://builtbybit.com/resources/daily-rewards-login-streak-system.105963/ [TITLE]) -
   indicates the pattern is common; we should build our own (DataStore + os.time UTC day) [INFERRED].
3. **Codes**: every top game in this genre publishes codes tied to updates/milestones (Anime Vanguards code lists are heavily SEO'd, e.g. https://www.creation.dev/codes/anime-vanguards-codes [TITLE]). A code redemption box + a
   "Like + Favorite + Join group" reward (PSU headline: "the cheap trick roblox devs use to keep dead games alive", https://www.psu.com/news/the-cheap-trick-roblox-devs-use-to-keep-dead-games-alive/ [TITLE; content unread]) is table stakes.
   Build: `Codes` table server-side with expiry, one-time per user, announced with each update.
4. **Unit/weapon collection with rarity reveal** (Anime Vanguards / Defenders model [PRIOR]): banner/summon with visible odds and pity counter. In our setting: "Weapon Crate" and Kits; evolve weapons by element (already in plan). Guides on banners exist (https://www.droidgamers.com/guides/anime-defenders-banners-guide/ [TITLE]).
   Note: Roblox requires odds disclosure for paid random items (Roblox policy; [PRIOR]; verify in Creator docs before launch).
5. **Quests that point at the next unlock** (always-visible quest panel, Hunty look in BEST-OF), 1 main + 3 daily + 1 weekly, each pays currency AND progress to a named goal.
6. **Co-op social hooks**: shared reactor/base goal, "co-play bonus" (+XP when playing with friends), party invite button on spawn, emote/ping wheel. Group join reward. Leaderboards: weekly boss damage, fastest clear (reset weekly so new players can place).
7. **Trading is optional and risky for a small team** (scam/moderation load) - skip at launch [INFERRED].
8. **Update cadence**: top games post frequent updates and announce countdowns ("Dead Rails Update Countdown" sites exist, https://techwiser.com/countdowns/dead-rails/ [TITLE]); a typical pattern is small weekly content/events with a bigger monthly update [PRIOR; unverified here].
   For us: weekly rotating "Mutation of the week", monthly new Core (15 stages).
9. **Retention metrics to watch** are defined in Roblox's analytics docs: https://create.roblox.com/docs/production/analytics/retention [TITLE] - set our own targets after the first 100 testers rather than citing others' unverified numbers.

### Observed platform facts
- Roblox's June 2026 newsroom post on discovery ("Optimizing Discovery: how great games reach millions of players", https://about.roblox.com/newsroom/2026/06/optimizing-discovery-great-games-reach-millions-players-roblox [TITLE]) and
  press coverage that an algorithm shift toward long-term retention hit Roblox bookings/guidance (e.g. https://www.nasdaq.com/articles/roblox-guided-bookings-down-much-18-and-withdrew-its-full-year-outlook-algorithm-change ,
  https://massivelyop.com/2026/08/06/roblox-stonks-plummeted-as-its-shift-toward-long-term-retention-sees-kids-spending-less-money/ [TITLEs]). Implication [INFERRED]: discovery now rewards games that keep players across days more than quick spikes, so
  retention loops (daily/weekly) are not optional.

---------------------------------------------------------------------------------------------------
## 4. First minute / first session

### What we should copy
1. **Target timeline (our targets, not benchmarks) [INFERRED from r4-genre-feel rule 10]**: 0-5 s in-world with a weapon in hand and the move/attack buttons visible; 5-15 s first enemy within 8 studs; ~20 s first kill with full 8-channel feedback;
   30-45 s first level-up/pick-a-card; 60 s a mini-boss telegraph or a chest, plus the first quest ticked. 90-120 s first "wave cleared" banner with rewards.
2. **Teach by doing, never by text wall**: a single bottom-centre prompt line ("Hold ATTACK"), arrow/ring to the first target, hand-pointer on the first button. Roblox's own onboarding guidance: https://create.roblox.com/docs/production/game-design/onboarding [TITLE]; a community framework "OnBoard" exists
   (https://devforum.roblox.com/t/release-onboard-modern-lightweight-onboarding-tutorial-framework/4751478 [TITLE]) - evaluate before writing our own.
3. **Skip the lobby for new players**: first-ever join goes straight to a guided wave-1 arena (solo, forced win), THEN drops them in the Base with the first reward (Hunty-style quests panel). Returning players get the Base.
4. **First win must be guaranteed and spectacular**: scripted wave 1 makes the player look strong (enemies die in 1-2 hits, big VFX, a coin shower). Difficulty ramps only after the first level-up.
5. **No purchase prompts, no code box, no daily-reward pop-up in the first 3 minutes.** Show the daily reward after the first win.
6. **Instrument the funnel** (Roblox Analytics custom events / AnalyticsService:LogFunnelStepEvent [PRIOR; verify]): join -> moved -> first attack -> first kill -> first level-up -> wave 1 clear -> wave 3 -> session 5 min -> second session. Look for step drop-offs (Q6).
7. **Mobile**: first screen must not hide gameplay under tutorial UI; test at iPhone SE-class resolution.
Retention benchmarks: not found in public search results; do NOT quote any. Use Roblox Creator Analytics retention charts (D1/D7/D30 definitions in the docs link above).

---------------------------------------------------------------------------------------------------
## 5. How creators get results with AI-made Roblox games

### What we should copy
1. **Bounded tasks with a test**: precise scope + observable failure + how to verify scored far better in Roblox's OpenGameEval analysis (already in r2). Make every Codex task "one script, one acceptance test".
2. **Plan first, then build**: Mining Tycoon case used a design doc and implementation plan before building (r2). Keep game-bible-v3 + per-wave task files.
3. **Humans do the look; AI does the logic.** Repeated across sources: logic/server scripts are "absurdly good", visual feedback / UI layout / placement needs a human eye (Mining Tycoon, r2). Our feel gap is exactly the part AI is worst at, so build a *feel kit* once (Q1 items) and reuse.
4. **Pitfall manual**: the Obby comparison used a shared manual of 28 known pitfalls (r2, note.com). Maintain `PITFALLS.md` of our own Roblox gotchas (network ownership, AdjustSpeed, particle caps) and feed it into every task.
5. **Studio MCP + Claude Code/Codex** is the dominant tooling (r4 lists weppy, boshyxd, official MCP). New title-level finds this round:
   - AI tooling roundups: https://ropilot.ai/blog/best-ai-tools-for-roblox , https://www.creation.dev/learn/which-ai-makes-best-roblox-game-chatgpt-claude-gemini-comparison , https://opper.ai/ai-roundtable/questions/which-ai-assistant-is-the-best-for-autonomous-roblox-game-f4e4c111 [TITLEs; vendor/aggregator pages, claims unverified].
   - Browser-native/"studio bridge" paths: https://sorceress.games/blog/how-to-make-a-roblox-game-with-ai-studio-bridge-2026 [TITLE].
   - A transcript titled "gpt6 astra vs fable viral roblox game" (https://sozai.app/transcript/gpt6-astra-vs-fable-viral-roblox-game/ [TITLE]) suggests creator-video comparisons of models building a game; contents unread.
   - "Roblox game earnings lessons" transcript (https://sozai.app/transcript/roblox-game-earnings-lessons/ [TITLE]; mentions $28,910/mo in its title - this is a creator's claim in a title, unverified).
6. **What creator videos show (inferred from titles only)**: short TikTok/YouTube clips show the result (a flashy trailer-style montage), not the days of hand-tuning. We could not read any creator's workflow, time spent, or hand-vs-AI split.
   I cannot honestly report "how long it takes" for AI-made Roblox hits. The one documented timing: ~11 h to an MVP of a mining tycoon with heavy limits (r2 case study), and a Roblox mobile demo of 10-15 min to a basic farm (r2).
   Must-do (owner/human): watch 5 top "AI made Roblox game" videos and fill a table: tools, hours, hand-made assets, what the game looks like. Search queries to run on YouTube: "I made a Roblox game with Claude", "AI made Roblox game 24 hours", "Claude Code Roblox Studio MCP devlog".
7. **Use AI for asset pipelines only with a human quality gate**: Roblox Mesh Generation / Cube (r2), Meshy/Tripo imports (r4) are fine for props; characters/enemies need a style pass. Keep the art bible rule: chunky, bright, readable silhouette.
8. **Overnight PR loop** (Solo Hunters creator quote, r2): community bug reports -> AI PRs -> human review each morning. Adopt only after launch.

---------------------------------------------------------------------------------------------------
## 6. Playtesting like a real player; automated/AI driving without cheating

### What we should copy
1. **Human playtests first**: 5-10 friends on phones, screen-recorded, silent observation, 15 min. Record: time to first kill, where thumbs hesitate, deaths and cause, quit moment. Repeat after each wave of changes. Small studios use a Roblox group/Discord "playtest" role and a private/test place [PRIOR].
2. **Use a test place + published "Playtest" experience (private, friends only)** so analytics and mobile devices work (Studio emulator is not feel-representative) [INFERRED].
3. **Analytics funnel** (Q4 item 6) using Roblox's analytics (docs: https://create.roblox.com/docs/production/analytics [TITLE]). Review weekly.
4. **Bot driver rules (non-cheating)** so tests are representative:
   - Drive the game ONLY through input: Humanoid:Move via a virtual thumbstick vector and VirtualInputManager (SendKeyEvent / SendMouseButtonEvent / touch) - title-level docs: https://create.roblox.com/docs/en-us/reference/engine/classes/VirtualInput.md ,
     https://robloxapi.github.io/ref-temp/class/VirtualInputManager.html ; Roblox's own new testing APIs: https://devforum.roblox.com/t/new-studio-testing-apis-and-assistant-improvements/4657854 [TITLE];
     Playtest agent beta: https://devforum.roblox.com/t/studio-beta-studio-assistant-mcp-playtest-agent/4566767 [TITLE]; third-party bot/AI test docs: https://docs.rbxsync.dev/bot-testing , https://docs.rbxsync.dev/ai-testing [TITLE].
   - Bot may NOT: teleport, set Health/Position, spawn/remove enemies, call server remotes directly, read enemy positions the player could not see. It MAY read screen-space info a player sees (enemy positions within camera view, HUD values).
   - Bot uses human limits: 150-250 ms reaction delay, movement via the thumbstick vector only, attack via the ATTACK button hit area, ≤ 6 inputs/s, and deliberately imperfect aim.
   - Bot reports *feel metrics*: time to first kill, kills per minute, damage taken per wave, frames with FPS < 30, particle count peak, number of sound instances, clearing time vs target (60-90 s per wave).
   - Pass/fail: a 15-minute "naive kiter" bot (moves away from nearest enemy and attacks) should clear stage 1 with 40-70% HP left (win but not trivially), and a "stands still" bot should die by wave 3 [INFERRED targets].
5. **Frame-capture QA**: record 10 s clips of each scythe swing, kill, boss slam at 60 fps; a human reviews a contact sheet for: flash frame visible, VFX arrives on the strike frame, no clipped trail, number readable. Use the same checklist each build.
6. **Do not accept "no errors" as success**: AI-run Studio playtests catch script errors, not dullness (Mining Tycoon "zero visual feedback" lesson, r2).

---------------------------------------------------------------------------------------------------
## 7. "Good enough to launch" in 2025-2026

### What we should copy
1. **Understand the ranking signal**: Roblox says (June 2026 newsroom, title-level) it is optimizing discovery around what keeps players engaged; coverage ties the change to long-term retention rather than short spikes
   (links in Q3). Third-party explainers (unverified, SEO): https://rolearn.dev/insights/roblox-game-discovery-algorithm-2026 , https://rowatcher.com/news/what-the-roblox-algorithm-actually-rewards-in-2026-not-ccu . Official docs: https://create.roblox.com/docs/en-us/discovery.md [TITLE].
   Treat: session length, day-1/day-7 return, qualified play-through rate (qPTR on thumbnails, see r2) are the levers [INFERRED].
2. **Sponsored ads caution**: a DevForum thread argues "sponsored ads traffic degrades the engagement metrics used for discovery" (https://devforum.roblox.com/t/sponsored-ads-traffic-degrades-the-engagement-metrics-used-for-discovery-causing-paid-acquisition-to-harm-organic-ranking/4838351 [TITLE]; a creator's claim, unverified).
   Practical rule [INFERRED]: do not buy ads until D1 return and session length are acceptable; first ad test with a small budget. Official: https://create.roblox.com/docs/production/promotion/ads-manager ; break-even math explainer: https://rowatcher.com/news/roblox-ads-in-2026-the-break-even-math-small-devs-ignore [TITLEs].
3. **Thumbnail/icon**: official thumbnail docs (https://create.roblox.com/docs/production/publishing/thumbnails , promotional thumbnails https://create.roblox.com/docs/production/promotion/promotional-thumbnails [TITLEs]); thumbnail personalization up to 5 variants (r2).
   Build 5 variants: (1) hero mid-swing with huge swarm behind, bright rim light; (2) boss reveal; (3) co-op team of 4; (4) loot/chest reveal; (5) ability explosion. ONE focal subject, 3 colours max, high contrast, readable at 150 px; no text beyond 2-3 words. Article "The Roblox Thumbnail Is a Conversion Ad" (https://rowatcher.com/news/the-roblox-thumbnail-is-a-conversion-ad-stop-designing-it-like-art [TITLE]).
4. **Launch checklist (our bar) [INFERRED]**: (a) 60 s first-minute passes the 5 playtesters test, (b) 8-channel feedback on every hit, (c) 60 FPS desktop/30+ FPS low-end phone with 80 enemies, (d) stage 1-5 content (5 of 15) polished rather than 15 rough, (e) save data safe, (f) daily reward + codes + quests live, (g) 5 thumbnails + icon + 3-4 trailer GIFs, (h) analytics funnel working, (i) a 4-week update roadmap posted.
5. **Update cadence**: launch with a visible "next update in X days" timer; ship weekly small updates the first 8 weeks (new mutation, event, bug fixes) and a stage pack every ~2-4 weeks [INFERRED; Dead Rails/Anime Vanguards sites show frequent update coverage].
6. **Soft launch** to a small group + limited visibility, watch D1, then public. Then check Creator Analytics weekly.

---------------------------------------------------------------------------------------------------
## Top 10 changes for Swarm Break, ranked by impact on how good it feels to play
1. **Build the single HitFeedback pipeline (8 channels) and route every weapon/ability through it.** Flash + spark + sound + number + hit-stop + knockback + shake + hitmarker on the same frame. (Q1.1)
2. **Fire hits on animation markers with a swept arc hitbox (hit-stop via AdjustSpeed 0.03-0.08 s).** (Q1.2, 1.3, 1.7)
3. **Kill payoff: pop + spin-launch + coin/XP burst + per-kill sound with a swarm cooldown; no full ragdolls for swarms.** (Q1.6, 1.9)
4. **Mobile control rebuild: one big ATTACK button with auto-target cone, DASH button, ability arc, no shift-lock requirement.** (Q2)
5. **Scythe slash arc + ground ring + dust VFX set (buy or commission a pack; flipbook + additive + Beam), plus a boss-slam shockwave.** (Q1.11-1.12)
6. **First minute rewrite: straight into a scripted wave 1, first kill by ~20 s, first level-up by ~45 s, reward after first win, no popups.** (Q4)
7. **Pacing: 60-90 s waves with a calm beat and event banner every 3rd wave, mini-boss telegraph, AoE rings, chest at end.** (Q4.1, r4 rules 7)
8. **Camera trauma shake (event-scaled) + FOV kick on dash/boss intro, with an off switch.** (Q1.10, 2.7)
9. **Retention layer: daily reward calendar, codes box, always-visible quest panel, weekly board, "next update" timer.** (Q3)
10. **Real-input bot + phone playtests + funnel analytics before every release; 5 thumbnail variants prepared for launch.** (Q6, Q7)

## Open items needing a human (cannot be answered by text search)
- Watch Hunty Zombie, Dead Rails, Anime Vanguards on a phone: label button layout, first-minute timeline, hit effects frame by frame.
- Watch 5 "AI made Roblox game" videos and note tools/hours/hand-vs-AI.
- Decide VFX budget (buy pack vs commission vs build).
- Verify Roblox policy on paid random item odds disclosure before adding crates.
