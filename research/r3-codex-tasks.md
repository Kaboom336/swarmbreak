# Codex wave 3 (Swarm Break, from Research round 3, 2026-10-01)

Same rules as research/codex-wave1.md and r2-codex-tasks.md: repo https://github.com/Kaboom336/swarmbreak, one branch per task (codex/<task>), push, do not merge. Pure modules in game/src/ReplicatedStorage/Shared/ (no Roblox globals; pass time and positions as plain numbers / {x, z} tables); tests in game/tests/<name>.spec.luau using `load`, `test`, `eq` (style of tests/daily.spec.luau; run.luau picks up every *.spec.luau). --!strict Luau, plain English names, every tunable number marked `-- placeholder` (none of them are sourced). Read game/PITFALLS-LUAU.md first if it exists. Backlog numbers refer to COMPARISON.md "Research round 3".

## Task 1: Touch auto-aim and touch tracking (backlog #1)
Goal: on a phone the player only moves; weapons aim at a sensible enemy, and a second finger never cuts or redirects fire.
Files: new Shared/AimAssist.luau (`pickTarget(origin: {x,z}, facing: {x,z}, enemies: {{x,z}}, maxRange, maxAngleDeg) -> index?`: nearest enemy inside the facing cone within range, else nearest within range, else nil; ties by lower index); new Shared/TouchTracker.luau (pure state: `began(state, id, onGui) -> state`, `ended(state, id) -> state`, `isFiring(state) -> boolean`, `fireTouch(state) -> id?`; touches that began on GUI/thumbstick never become the fire touch; only the end of the fire touch stops firing); StarterPlayerScripts/Shooting.client.luau uses both (auto-aim + auto-fire when UserInputService.TouchEnabled and no mouse); Shoot:FireServer(origin, dir) stays unchanged.
Tests (tests/aimassist.spec.luau, tests/touchtracker.spec.luau): empty list -> nil; enemy in cone beats a nearer one behind; nothing in cone -> nearest; out of range ignored; tie deterministic; two-finger sequence (stick down, fire down, stick up) keeps firing; fire up stops; GUI touch never fires; state not mutated in place.
testcmd: cd game && stylua --check src tests && selene src && lune run tests/run.luau

## Task 2: Context-aware, delayed, platform-aware tutorial (backlog #3)
Goal: an unused Dash never blocks the card hint; hints show only after a delay; phone players see touch wording.
Files: Shared/Tutorial.luau: keep `next` for compatibility; add `Steps[i].Context` ("arena" | "cards" | "shop"), `Optional` for Dash and Crate; `pick(flags, ctx) -> Step?` (first unfinished non-optional step for that context, then optional ones); `Tutorial.DelaySeconds = { Move = 8, Shoot = 6, Pick = 5 } -- placeholder`; `shouldShow(stepId, secondsInContext) -> boolean`; `hintFor(stepId, platform: "keyboard" | "touch" | "gamepad") -> string` (e.g. "Drag to move", "Tap to shoot"). Hud.client.luau (around lines 412-425 and 1225) calls pick/shouldShow/hintFor.
Tests (extend tests/tutorial.spec.luau): with Move+Shoot done and Dash not done, ctx "cards" returns Pick; ctx "shop" returns Upgrade; all done -> nil; shouldShow false before the delay, true after; unknown step uses a default delay; every step has text for all three platforms; existing next/complete tests still pass.
testcmd: cd game && stylua --check src tests && selene src && lune run tests/run.luau

## Task 3: Sound budget and wider SfxMap (backlog #5)
Goal: the client never piles up hundreds of Sound instances, and every key game event has a mapped sound.
Files: new Shared/SoundBudget.luau (`SoundBudget.GlobalCap = 24`, `PerNameCap = 6`, `MinIntervalSec = 0.06` all `-- placeholder`; priority tiers P0 stingers/player hurt (never dropped), P1 player weapon, P2 hits/kills, P3 ambience; `new() -> state`, `allow(state, name, priority, now) -> (state, boolean)`, `release(state, name, now) -> state`); StarterPlayerScripts/ClientFX.luau calls allow before Instance.new and release when the sound ends; Shared/SfxMap.luau adds "wave start", "boss spawn", "card pick", "crate open", "pickup", "level up", "low hp", "victory", "defeat" (map to existing Sounds keys for now).
Tests (new tests/soundbudget.spec.luau; update tests/sfxmap.spec.luau, which currently asserts "wave start" is unmapped): global cap reached -> P2/P3 refused, P0 still allowed; per-name cap; same name inside MinIntervalSec refused, allowed after; release frees a slot; every SfxMap event names an existing Sounds entry; unknown event -> nil.
testcmd: cd game && stylua --check src tests && selene src && lune run tests/run.luau

## Task 4: Responsive HUD layout (backlog #4)
Goal: HUD panels never overlap on a phone and touch targets are large enough.
Files: new Shared/HudLayout.luau (`scaleFor(viewportX, viewportY, platform) -> number` clamped to a range `-- placeholder` (r3-controls suggests clamp(viewportY/720, 0.6, 1.4), est.); `rects(viewportX, viewportY, platform) -> { [panelName]: {x, y, w, h} }` for quest, settings, shop, hotbar, wave, health; `MinButtonHeight = 44 -- placeholder`); Hud.client.luau applies one UIScale from scaleFor and sets ScreenGui.ScreenInsets explicitly (DeviceSafeInsets for gameplay HUD).
Tests (tests/hudlayout.spec.luau): at 640x360, 844x390, 1280x720, 1920x1080 all panel rects are pairwise disjoint and inside the viewport; every button height * scale >= MinButtonHeight on touch; scale is monotonic in viewport height and stays in range.
testcmd: cd game && stylua --check src tests && selene src && lune run tests/run.luau

## Task 5: Enemy animation culling (backlog #6, code part)
Goal: far or off-screen enemies cost little on the client.
Files: new Shared/AnimCull.luau (`AnimCull.FullDistance = 80`, `FarEvery = 3` `-- placeholder`; `shouldUpdate(distance, onScreen, enemyIndex, frame) -> boolean`: always when near and on screen, every FarEvery frames (staggered by enemyIndex) when far, never when off screen beyond FullDistance); StarterPlayerScripts/EnemyAnimator.client.luau lines 52-90 calls it and hoists the per-enemy `set` closure out of the loop. Do not touch EnemyBuilder.luau emitters/lights (Claude does that with a look check).
Tests (tests/animcull.spec.luau): near on-screen always true; far enemy true exactly once per FarEvery frames; two far enemies with different indices update on different frames; off-screen far never; boundary at exactly FullDistance defined and tested.
testcmd: cd game && stylua --check src tests && selene src && lune run tests/run.luau

## Task 6: Invite prompt rules (backlog #7)
Goal: an alone player is offered a friend invite at the moments it makes sense, not spammed.
Files: new Shared/Invite.luau (`Invite.CooldownSec = 300 -- placeholder`; `shouldShow(playersInServer, moment: "summary" | "death", lastShownAt?, now) -> boolean`: only when playersInServer == 1, only for those moments, respects cooldown); Hud.client.luau adds an "Invite a friend" button to the summary panel (~line 871) and death screen that calls SocialService:PromptGameInvite after a pcall'd CanSendGameInviteAsync; hide the button if the check fails.
Tests (tests/invite.spec.luau): 2+ players -> false; first show allowed; inside cooldown false, after true; unknown moment false; nil lastShownAt treated as never shown.
testcmd: cd game && stylua --check src tests && selene src && lune run tests/run.luau
