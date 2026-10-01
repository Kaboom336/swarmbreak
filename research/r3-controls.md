## Research round 3: mobile and console controls (2026-10-01)

Method note: WebSearch returned titles and URLs only (no body snippets); claims below rest on titles or on our own code. Anything needing the page body is in "Must-read later". Estimates are marked "est.".

### a. Platform share
- Roblox is mostly phones: "80% of Roblox users are on mobile, contributing 46% of Robux revenue" (title only, year not visible): https://www.pocketgamer.biz/80-of-roblox-users-are-on-mobile-contributing-46-of-robux-revenue/
- PlayStation 5 client released 2026-04-14, PS4 2023-10-10 (Wikipedia, fetched): https://en.wikipedia.org/wiki/Roblox. That page gives no platform split.
- Takeaway (est.): design phone-first; a desktop-only test pass misses most of the audience. Console is a smaller but real, growing slice, so gamepad must work, not just not crash.

### b. Conventions (what the sources say)
- Survivor-likes on phones are move-only: one virtual stick, weapons auto-fire and auto-target (Brotato Android port, Vampire Survivors phone control pages): https://www.androidpolice.com/brotato-brilliantly-fun-vampire-survivors-clone-out-now-android/ , https://serafimgaming.com/controller/vampire-survivors/ . Body text not read; convention is from the genre (est.).
- Shooter-style Roblox games on touch use a left move stick plus a right-side aim/fire area; devs report conflicts between the default thumbstick and a fire touch (threads, titles only): https://devforum.roblox.com/t/how-to-ignore-movement-joystick-for-mobile-when-shooting/4048462 , https://devforum.roblox.com/t/how-should-i-make-shooter-mobile-controls/3674650 , https://devforum.roblox.com/t/how-do-i-allow-player-to-aim-with-2-fingers-on-mobile/4220085
- Twin-stick convention (move stick + aim stick) is the console default: https://en.wikipedia.org/wiki/Twin-stick_shooter
- ContextActionService: BindAction(createTouchButton=true) makes a touch button; SetTitle/SetPosition style it; devs report SetPosition/SetTitle bugs and quirks with it: https://create.roblox.com/docs/reference/engine/classes/ContextActionService , https://devforum.roblox.com/t/bug-report-contextactionservice-failing-to-settitle-or-setposition-engine-bug/2314894 , https://devforum.roblox.com/t/positioning-contextactionservice-mobile-buttons/2165713
- Safe area: ScreenGui.ScreenInsets enum (None, DeviceSafeInsets, CoreUISafeInsets, TopbarSafeInsets) and notched-screen support exist: https://create.roblox.com/docs/reference/engine/enums/ScreenInsets , https://devforum.roblox.com/t/notched-screen-support-full-release/2074324
- Scaling UI across phone/console/PC (Scale over Offset, UIScale, UISizeConstraint, 10-foot console TV distance): https://simplified.media/guides/roblox-ui-systems , https://kitsblox.com/blog/fix-roblox-ui-scaling-mobile

### c. Audit of game/src/StarterPlayer/StarterPlayerScripts (code read, not run)
Shooting.client.luau (97 lines)
- M1. No auto-aim or auto-fire on touch. Fire needs a held finger that is also the aim point (touchPos); the finger covers the target and the player cannot move and aim with two thumbs reliably. Survivor-likes avoid this (section b).
- M2. InputEnded stops `firing` for ANY touch ending, including a second finger; `touchPos` is overwritten by whichever touch begins last. Two-finger play (stick + fire) will cut or redirect fire.
- M3. Gamepad: only ButtonR2 sets firing; the aim point still comes from GetMouseLocation (stale or centre on a pad), so a controller player fires at an arbitrary point. No right-stick aim, no auto-aim assist.
- M4. Orbital weapons return early (fine), but there is no "target nearest enemy" helper to share with aim assist; `Shoot:FireServer(origin, dir)` is already direction-based so server needs no change.
Movement.client.luau (109 lines)
- M5. Dash is bound through CAS with a touch button (good), but SetPosition(UDim2.new(0.72,0,0.2,0)) is a fixed screen fraction: on a phone it sits mid-right near the top, likely on top of the fire zone and away from the thumb arc (est.). Button size is the CAS default. No cooldown/charge state on the button (charges are only in the Hud).
- M6. Double jump rides JumpRequest, so touch gets it free via the default jump button; no on-screen hint that a second press works.
- M7. Gamepad: ButtonB dash is bound (good); jump is the default ButtonA. Nothing tells the player the pad bindings.
Hud.client.luau (1409 lines)
- M8. No touch/gamepad/safe-area handling at all (grep: no UIScale, ScreenInsets, GuiService, Selectable, GamepadEnabled). ScreenGui "Hud" is created with defaults, so it sits under the notch/top-bar inset rules by default (est.), and no `ScreenInsets` choice was made.
- M9. Layout is pixel offsets anchored to the right edge: questPanel x=-272, settingsPanel x=-544 (y=50), shop x=-372, hotbar x=-432 (y=-72), settings button x=-404, shop button x=-122. On a ~640x360 phone viewport these overlap each other and eat over half the width (est.); text sizes are 10-16 px, below a comfortable touch/TV size.
- M10. Buttons are 34 px tall (settingsToggle 120x34): under the usual ~44-48 px touch target (est., no cited source; check in Must-read).
- M11. Gamepad cannot operate the card pick, shop, or settings: no SelectionImageObject, NextSelection or GuiService.SelectedObject set (grep empty), so on console the pick-1-of-3 reward screen may be unreachable. This is the highest-risk console bug.
- M12. Settings only has Music/Sfx volume (Shared/Settings.luau); no "auto aim", "aim assist", "button size" or "left-handed" option.

### d. Recommendations (4-8)
1. **Auto-aim + auto-fire on touch (and optional on pad).** Pure `Shared/AimAssist.luau`: `pickTarget(origin, enemies, facing, maxRange, maxAngle) -> position?` (nearest in cone, falls back to nearest). Shooting.client.luau uses it when on touch/pad or when the setting is on; held fire then needs no aim finger. Evidence: survivor-like phone convention https://www.androidpolice.com/brotato-brilliantly-fun-vampire-survivors-clone-out-now-android/ ; Roblox shooter-touch conflicts https://devforum.roblox.com/t/how-should-i-make-shooter-mobile-controls/3674650 . Effort M. Codex.
2. **Fix touch bookkeeping (M2).** Track the fire touch by InputObject identity; ignore touches that began on the thumbstick/GUI; stop firing only when THAT touch ends. Extract `Shared/TouchTracker.luau` (state machine, Lune tests for two-finger sequences). Evidence: two-finger thread https://devforum.roblox.com/t/how-do-i-allow-player-to-aim-with-2-fingers-on-mobile/4220085 . Effort S. Codex.
3. **Gamepad aim and menu navigation (M3, M11).** Right stick aim via `Shared/PadAim.luau` (deadzone, last-direction hold), R2 fire, plus GuiService.SelectedObject on card/shop/summary panels, selection highlight, B to close. Evidence: twin-stick convention https://en.wikipedia.org/wiki/Twin-stick_shooter ; UI for console https://simplified.media/guides/roblox-ui-systems . Effort M (pure PadAim: Codex; panel selection: Claude, needs a console or Studio emulator check).
4. **Responsive HUD layout (M8-M10).** Pure `Shared/HudLayout.luau`: given viewport size and platform returns UIScale factor (e.g. clamp(viewportY/720, 0.6, 1.4), est. numbers), panel anchors that never overlap (test: rects disjoint at 640x360, 844x390, 1920x1080), min button height 44. Hud applies a UIScale and sets ScreenInsets deliberately. Evidence: https://create.roblox.com/docs/reference/engine/enums/ScreenInsets , https://kitsblox.com/blog/fix-roblox-ui-scaling-mobile . Effort M. Codex (layout maths + tests) then Claude (visual pass).
5. **Dash button placement and state (M5).** Move to bottom-right thumb arc (est. Position about (0.82,0,0.62) after a phone screenshot check), larger size via `ContextActionService:GetButton("Dash")` and show charges as the title ("DASH 2"); keep fire zone clear of it. Evidence: CAS docs and SetPosition quirks https://create.roblox.com/docs/reference/engine/classes/ContextActionService , https://devforum.roblox.com/t/positioning-contextactionservice-mobile-buttons/2165713 . Effort S. Claude (needs on-device judgement).
6. **Controls settings (M12).** Extend Shared/Settings.luau and ProfileSchema with `AutoAim` (default true on touch), `AimAssist` strength, `UiScale` (0.8-1.3), `LeftHanded`; clamp/apply with tests in the existing Settings pattern. Evidence: same genre convention as #1; Settings.luau already has the clamp/apply pattern. Effort S. Codex.
7. **Platform test matrix.** Add a checklist to PLAYBOOK.md and release step d: Studio device emulator (phone landscape, tablet), gamepad emulator, one real phone from the 5-kid test. Use `UserInputService.TouchEnabled/GamepadEnabled` to set a `Platform` attribute and log it in Telemetry (#8) so D1 is cut by platform. Evidence: 80% mobile https://www.pocketgamer.biz/80-of-roblox-users-are-on-mobile-contributing-46-of-robux-revenue/ . Effort S. Claude (process) + Codex (Platform telemetry field).

### e. Must-read later
- https://create.roblox.com/docs/production/game-design/mobile-design (blocked earlier; touch target size, thumb zones)
- https://create.roblox.com/docs/ui/safe-area (confirm exact ScreenInsets behaviour; exact path unverified)
- https://ir.roblox.com/news/news-details/2025/Roblox-Reports-Second-Quarter-2025-Financial-Results/default.aspx (official DAU by platform)
- https://www.pocketgamer.biz/80-of-roblox-users-are-on-mobile-contributing-46-of-robux-revenue/ (year and source of the 80%)
- https://www.androidpolice.com/brotato-brilliantly-fun-vampire-survivors-clone-out-now-android/ (confirm auto-aim claim)
- https://devforum.roblox.com/t/how-should-i-make-shooter-mobile-controls/3674650 (blocked domain; find a quoting article)
