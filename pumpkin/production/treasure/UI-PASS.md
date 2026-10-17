# Roadmap 17 — UI pass

Design recorded before implementation, 2026-10-17. Scope: both saved places, client presentation only; no Studio play, commit or publish. Claude owns the one live screenshot review.

## Evidence and reuse

Read UI-AUDIT.md, UI-SBS.jpg, the PS99, Grow a Garden and Steal a Brainrot originals in refs-topgames, UIStyle, TreasureCoreHud source, cutscene title cards and CinematicMovement's Motion panel. Owner-reported: bottom action/goal stack blocks the view; former goal clipping; coin and Index panels are good. Checked code confirms a separate centre countdown and plain settings controls. The local repo PLAYBOOK.md was read; the separately named Keystone playbook is unavailable through this session's tools.

Reuse UIStyle's FredokaOne, cream/ink outline, rounded panels, Config rarity colours, Feel/Trove and native prompt forwarding. No external kit or dependency adopted; no new licence obligation. Existing project package licences remain unchanged.

## Side-by-side design

Open [the comparison board](UI-PASS-SBS.png) or [the HTML mockup](UI-PASS-MOCKUP.html). Left: actual official promotional thumbnails. Right: explicitly labelled proposed UI, not a Studio capture. Thumbnails prove visual hierarchy/contrast only; their live HUD, motion and input behaviour are UNKNOWN. The board uses a labelled Comic Sans Bold local font proxy; runtime uses FredokaOne. Reproduce with `powershell -NoProfile -File treasure/ui-pass-proof.ps1`.

| Reference / best use | Our one representative design |
|---|---|
| Pet Simulator 99: one large reward, saturated rarity and sparkles | Rarity-coloured reveal card, pet name above rarity/income, sparse decorative stars, existing skip/lifetime |
| Grow a Garden: outlined short headline over bright scenery | Single top-centre route icon + short objective; no bottom goal or central countdown |
| Steal a Brainrot: name/tier/income hierarchy | Keeper nameplate and local/nearby occupied plot plates; suppress vacant/debug state strings |

## Layout and behaviour

- Banner: top safe-area row at y=8 on all sizes, max 460px and 44px tall; countdown seconds append to the caption and a 4px bar sits inside its lower edge. This leaves the existing coin/Index row at y=56 and the gear at y=112 clear, including phone landscape. Objectives derive from existing phase/goal/cargo attributes; Home carry directs placement, Run carry directs escape. Refused-action feedback remains available. Animate only on changed goal, cancel prior tween; reduced motion stays still.
- Carry bar: below the caption within the banner. Meadow reads GREYBOX.EscapeDeadline against GetServerTimeNow only during Run. Cave reads existing CaveSecondsLeft (no replicated deadline exists there). Last five seconds red; no invented deadline and no gameplay timing changes. Hide on drop/respawn/return; retain bar denominator across a drop/recover of the same cargo. Never reset remaining time locally.
- Action: keep the existing input/hold/revalidation path; compact 48px target at the lower edge, separate from the top objective. Native prompts retain their existing selection/LOS/range/hold behavior; style existing custom prompt cards only.
- Coins: observe positive Coins deltas; no initial-load reward and no duplicate Collect-event pop. At most six visible +N tokens travel to the existing panel; bounce on arrival. Reduced motion uses a stationary brief amount. No economy writes.
- Reveal: existing Reveal event only; name, rarity and income retain server data. Decorative stars, card tint from Config, existing skip/generation guard. No new reward or cave gameplay event.
- Settings: one 48px gear launcher below Index; centred fitted panel with four 48px rows and Close. Existing ReducedMotion, CameraShakeEnabled, MusicMuted and SFXMuted handlers remain unchanged. Explicit gamepad selection links and close return focus.
- World: do not rewrite replicated caption Text. Hide original Keeper/pen captions locally and render a styled mirror; only nearby occupied plots/home phase and Keeper during a nearby run. Preserve emergency !/? warnings. No changes to prompt Enabled, key codes, hold duration or trigger callbacks.

CoreUISafeInsets is used for interactive HUDs, following [Roblox ScreenGui docs](https://create.roblox.com/docs/reference/engine/classes/ScreenGui). Existing custom prompt forwarding follows [Roblox ProximityPrompt docs](https://create.roblox.com/docs/reference/engine/classes/ProximityPrompt).

## Acceptance / contract

Back up source and both places first. Mount current source through a Lune overlay preserving complete unrelated serialization; Cave build gets a ui-pass entrypoint and UIStyle. Compile all mounted scripts O0/O1/O2. Compare server trees and Workspace exactly against backups. UI-only modules may not send remotes or write player/world attributes; legacy client changes must preserve existing gameplay/input sections and preference handlers exactly. Preferences remain local existing settings. Record static checks separately from live proof.

Claude review: desktop and 390x844 / 844x390 safe areas; enter → steal → carry final five seconds → drop/return; positive coin delta; reveal/skip twice; occupied/vacant pens; Keeper warning; gear/toggles/close with mouse, touch and gamepad. Verify no overlapping bars, clipped text, stuck focus, changed prompt holds or altered gameplay. Runtime visual acceptance is pending until these screenshots exist.

## Build and review evidence

- Backups: `treasure/ui-pass-backup-20261017/` contains byte-verified originals of both places and changed existing sources; place hashes are in `UI-PASS-BUILD-meadow.json` and `UI-PASS-BUILD-cave.json`.
- Meadow: `lune run treasure/ui-pass-meadow-build.luau`; Cave: `lune run prototype/cave-v2/build.luau ui-pass`. These overlay current complete places. Historical map generators are not run.
- Offline: 98 Meadow and 54 Cave scripts compile at O0/O1/O2. Server trees and serialized Workspace match backups exactly. Full source-overlay undo serialization is exact. `ui-pass-check.luau` records presentation/contract assertions and mounted source parity in `UI-PASS-CHECKS.json`. Selene reports zero errors/warnings for all seven affected runtime sources.
- Two independent source reviews checked layout/input and gameplay authority. Fixed Home-carry escape messaging, suppressed tactical Keeper warnings, portrait gear overlap and gamepad access to the Index scroller. No independent runtime/visual acceptance is claimed.
- Cave limitation, CHECKED CODE: its current server has no Coins replication, economy HUD or TreasureCoreEvent Reveal emission. Shared HUD/reveal listeners are mounted and nonblocking there; absent Coins is hidden, and no pet/currency outcome is fabricated. Native Cave prompts now use shared presentation and their unchanged engine hold path. A real Cave reveal needs a separately authorized gameplay integration.
- No Studio play, commit, publish, account action or messages to other people. Claude's one live screenshot/input review remains pending. No claim of top-game parity.

## Lessons

- When cargo survives a return home, gate escape UI by phase, because carrying alone also describes placement.
- When replacing debug captions, preserve tactical instructions, because Keeper warning strings share the same label as idle state.
- When fitting a short viewport, scroll settings/Index content rather than shrinking it, because touch targets must stay 48px and gamepad needs a selectable scroll target.
