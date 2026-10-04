# eca9fb2 captures (Outpost 9 map, new lighting/effects, old enemy models)

The laptop screen was locked the whole time, so desktop recording failed (gdigrab error 5). Every frame here comes from Studio MCP screen_capture during a playtest (about 1450x840, scaled to 1080p). There is no video.

| Shot | File | Status |
|---|---|---|
| 01 lobby wide | 01-lobby-wide.png | ok. The new Difficulty Select board and the Outpost 9 field are visible past the lobby. |
| 03 arena start | 03-arena-start.png | ok. "Survive 5 waves. Beat the Big Brute." banner with countdown 2. Bright, readable midday light. |
| 05 crowd | 05-wave3-attempt.png | partial. Wave 3 had 13 alive, but only one pack was in view when the frame landed. Each capture takes many seconds, so timing shots miss. |
| 06 hit | none | **not captured.** Damage numbers and flashes are too brief for the capture latency. Needs an unlocked screen and a recorded run. |
| 09 element | none | **not captured** (same reason). The card panel was force-hidden during the crowd attempt, so no element was picked. |
| Clip B (kill burst) | none | **not captured.** Video needs an unlocked screen. |

Capture-only changes during this session (none are in the build):
- A server hook healed the player below 50% HP.
- Later, the card panel was hidden by script so auto-fire kept running.
- One enemy stuck on a LowWall was killed by script after 6 s (see bug 2).

## Bugs found (live checks with Studio MCP)

1. **Auto-fire stops whenever a level-up card is open** (Shooting.client.luau line 288: `autoFireEnabled() and player:GetAttribute("CardPanelOpen") ~= true`). Cards arrive faster than they get picked, so enemies walk up to the player and the camera ends up inside them (x-cards-open-camera-in-enemy.png). This is the "wave won't end / can't see" feeling.
2. **Enemies get stuck on top of `Workspace.Arena.LowWall` on Outpost 9.** Wave 1 sat at "1 LEFT" for over 4 minutes. A Walker was at (-51,10,62), running/freefalling on a LowWall, 97 studs from the player and out of auto-fire range. Wave 2 hung the same way at "1 LEFT" (x-wave2-stuck-1-left.png), with a Walker at (-52,20,63) in Freefall on LowWall, moving about 3 studs per 2 s without getting anywhere. The spawn portal near (-52, y, 63) seems to drop enemies onto that wall. It's the same class of bug as the old floating BossGate.
