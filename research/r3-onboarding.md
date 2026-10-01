# R3: first five minutes (2026-10-01)

Builds on COMPARISON.md "Research round 2" (#8 telemetry, release step 1 "fights in 3 s") and r2-critique missing item 1 (FTUE). Not repeated: codes, feel, map. Claims carry URLs; "est." = our judgement.

## 1. Evidence
| Topic | Finding | URL |
|---|---|---|
| Roblox FTUE | "Avoid a long tutorial"; keep onboarding "ideally in 5 minutes or less after entering"; find and fix big drop-offs by completion rate per core-loop step. The doc gives no numeric D1 or bounce targets. | https://create.roblox.com/docs/production/analytics/retention |
| Hint style | Contextual just-in-time hints triggered by play, visuals over text, world-integrated cues (signs, particles, trails) over UI overlays; dim/spotlight only when a popup is needed. | https://create.roblox.com/docs/production/game-design/onboarding-techniques |
| Hint timing | Playtest the median completion time, then show the hint just after it (doc example: players press the button within 10 s, add highlight at 11 s); A/B 5 s vs 10 s. Surface overlooked features in the first two sessions. | same |
| Vampire Survivors | "Almost no friction": pick character and stage, already moving; first level-up within a minute or two; menu to meaningful choice in under a minute. Power growth is taught by the screen filling up. | https://www.kokutech.com/blog/gamedev/design-patterns/power-fantasy/vampire-survivors |
| Survive The Swarm | Tutorial first, then third-person run with auto-attack; level-up shows a holographic card screen; "your first death is just currency" (first run framed as learning). | https://survivetheswarm.wiki/progression/survive-the-swarm-beginner-guide |
| Lobby vs action | Final Swarm and STS use a lobby first with big servers (RESEARCH.md, GAME-PLAN.md 2026-09-30). Not independently measured: no public time-to-first-fun numbers found (est. gap). | GAME-PLAN.md |

## 2. Audit of our code
**Shared/Tutorial.luau** (6 ordered steps Move, Shoot, Dash, Pick, Upgrade, Crate; flags `Tut_*`; `Tutorial.next` returns the first unfinished step).
- Strictly ordered: if a player never presses Shift, the hint stays "Press Shift to dash" and Pick, Upgrade, Crate hints never show. Dash is not needed to survive wave 1, so this can block the card hint (the key learning moment). Fix: `next(flags, context)` picks by context (in arena vs shop vs summary).
- No timing: hints show instantly and forever. Roblox advice is to show after the median time. No per-step timestamps exist.
- Hint strings are desktop only ("WASD", "Click", "Shift"). Mobile text is missing (r2-critique item 2, still unverified).
- Completion is only recorded in Flags; no telemetry per step, so we cannot find the drop-off Roblox tells us to find.
- Tutorial.server.luau: Move completes after 10 studs of horizontal travel from character spawn, checked every 0.25 s. Fine. Dash fires from client remote; Shoot is in Combat.server.luau:186; Pick/Upgrade/Crate in PlayerData.luau (293, 440, 517).
- Hud.client.luau:412-425 and 1225: one bottom-centre pill (300x38, 17 pt) is the only hint: a popup, not diegetic. No arrow, ring or world marker.

**Lobby flow** (GAME-PLAN.md "Still to do: lobby place"; Shared/Places.luau ids are 0). The lobby does not exist yet, so today a new player lands straight in the arena. Keep that for session 1 (est.: matches VS "already moving" and the 3 s exit criterion). WaveManager.runWave gives 3 s WaveStartDelay (Config.luau:7) then wave 1; first card arrives only after wave 1 clears, so first choice time is not measured (est. 60-90 s; needs telemetry).

**Run summary** (Hud.client.luau:871+, PlayerData.RunSummary, Config.RestartDelay = 15). Has Won, Wave, Kills, Gems, BestWave, NewBest, Goal and perk buttons. Good: next-goal bar and buy-here perks. Gaps: no "first death is currency" framing on run 1, no explicit play-again button wording check, auto-restart in 15 s may cut off a new player still reading (est.), no onboarding step for "spend your Gems" (Upgrade step only completes on purchase, but is hidden behind Dash).

## 3. Recommended first-five-minutes flow (est. targets, to verify by playtest)
- 0-3 s: spawn in arena, no menu. 0-10 s: wave 1 is 2-3 slow Walkers near the player.
- Move/Shoot: world cue (floor chevrons or glowing ring on first enemy) instead of text; the pill appears at median+1 s only if not done.
- First card at the wave-1 clear: dim background + pulse on card 1, text "Pick one" (spotlight pattern from the Roblox doc).
- First death or win: summary shows "Run 1 done: Gems added, buy your first perk" with one pulsing button, then lobby later.
- Anything for Dash / Crate waits until session 2 (doc: progressive disclosure, first two sessions).

## 4. Changes
1. **Context-aware hint picker.** Replace first-unfinished with `Tutorial.pick(flags, ctx)` where ctx is "arena" | "cards" | "shop" | "summary"; Dash becomes optional and never blocks Pick. Add tests in tests/ (new tutorial.spec). Evidence: https://create.roblox.com/docs/production/game-design/onboarding-techniques. S. Codex.
2. **Delayed hints with per-step timers.** Add `Tutorial.shouldShow(step, secondsSinceContext, medianSeconds)` with defaults Move 8 s, Shoot 6 s, Pick 5 s (est.; tune from telemetry), Hud shows the pill only after the delay. Evidence: same doc (hint just after the median). S. Codex.
3. **FTUE telemetry.** Fire AnalyticsService custom events for each Tut_ completion with seconds-since-join, plus FTUE_RunEnd wave and quit time; extends COMPARISON #8. Builder `Telemetry.ftueStep(stepId, seconds)` pure and tested. Evidence: https://create.roblox.com/docs/production/analytics/retention (find drop-offs per step). S. Codex.
4. **Platform-aware hint text.** `Tutorial.hintFor(step, platform)` returning touch text ("Drag to move", "Tap to shoot") vs keyboard; Hud picks via UserInputService.TouchEnabled. Evidence: onboarding-techniques (visual-first) plus r2-critique item 2 (mobile unverified). S. Codex.
5. **Diegetic cue for Move/Shoot.** Neon floor chevrons from spawn to the first enemy and a pulse ring on it, fading after Move+Shoot complete; card spotlight dim on first Pick. Evidence: onboarding-techniques (world-integrated cues, spotlighting). M. Claude.
6. **Run-1 summary framing and no auto-close for new players.** If `Flags.Tut_Upgrade` is not set, show "Your first run pays Gems: buy a perk" with pulsing perk button and extend RestartDelay to 30 s; pure `Config.restartDelay(flags)`. Evidence: https://survivetheswarm.wiki/progression/survive-the-swarm-beginner-guide ("first death is just currency"), Roblox retention doc. S. Codex.
7. **Easy wave 1 for new profiles.** WaveTable multiplier 0.6 on wave 1-2 counts when `Tut_Pick` unset, so the first card arrives within about 60 s (est.). Evidence: kokutech VS analysis (first level-up in 1-2 min) https://www.kokutech.com/blog/gamedev/design-patterns/power-fantasy/vampire-survivors. S. Codex.
8. **Playtest the median times.** 5 kids, silent watch, record seconds to Move/Shoot/Pick and where they quit; feeds changes 2 and 7. Evidence: onboarding-techniques playtest-then-trigger guidance. S. Claude.
