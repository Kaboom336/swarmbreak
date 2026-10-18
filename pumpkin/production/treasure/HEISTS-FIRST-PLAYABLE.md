# Heists first playable — Zion's test route

**Open:** [steal-a-treasure-heists.rbxl](../slice-v2/heists/steal-a-treasure-heists.rbxl).
This is a separate place. The old guardian place is unchanged by this lane.
Greybox art is intentional; lane 2 supplies the visual rebuild.

## Play

Zion starts and stops Studio testing. Codex never starts Studio Play.
1. Walk to the gold **HEIST BOARD** and use **Break in** (E / mobile prompt).
2. Walk beside your gold ball to push it in your movement direction. Standard
   WASD / stick / touch movement. Stop near it to brake. Jump works normally.
3. Roll over gold cubes. Coins grow the ball; larger balls collect goblets, chairs,
   safes, crowns and Baron Bumble's hat. Names are pickup feedback; cubes are art placeholders.
4. Face a direction and **Q / controller X / SHOVE touch button** to shove your ball.
   Run alongside it to regain steering. Friends in the room can push any nearby ball.
5. Approach the baron with loot. His red floor lane locks before a charge. Bait a
   charge into a grey block, turn away, collect his hat once big enough, or chase
   your spilled loot. Guardian bumps spill up to three attachments, never your bank.
6. Roll your ball to the teal **GETAWAY** at the southeast edge. Stay close enough
   to escort it. It freezes during saving, then shows the real **+$haul BANKED**.
   You return to your hideout; bank, best haul, server best-haul board and your
   personal gold trophy heap update.
7. Break in again. When nobody is running, the room resets. While others run,
   the same contested loot stays in the room. A run ends after four minutes;
   unbanked loot spills and you can retry immediately. Banking early is allowed.

## What to judge

- **Solo:** Is sweeping up coins enjoyable before payout? Can you turn, brake,
  shove and recover without fighting the controls? Try a different greedy route
  on run two. Intended run length is 2–4 minutes, not a measured result.
- **With a friend:** Start one run each. Help push a ball, then ram balls with a
  shove. Three loose attachments can be taken by either ball after a short settle.
  Steal yours back. Is it funny and reversible? Both players must have agency.
- **Guardian:** Can you read the red lane before impact? Can you make him hit cover?
  Does losing a few pieces create a recovery decision instead of a restart chore?
- **Getaway:** A capped ball must fit the 22-stud breach or the 30-stud east bypass.
  No geometry should require shrinking the haul. Check a big ball on both routes.
- **Brag:** Is the stolen heap/value clear at phone size? Is the goal visible with
  sound muted? Compare to Steal an Egg's visible steal/chase, Katamari's rolling
  toy, and Grow a Garden's conspicuous owned jackpot. Reference observations come
  from the supplied studies, not new playtests.

## HeistTest live suite (Zion only)

Start from the hideout before a run. In Studio's **server** command bar:

```lua
task.spawn(function()
  require(game.ServerScriptService.HeistTest).run(game.Players:GetPlayers()[1])
end)
```

Then play the route normally, including approaching the baron, observing a charge,
growing the ball and banking. It has six minutes to observe a complete run. It
does not teleport, award test money or disable collision/guardian rules. Check
`ServerScriptService.HeistTestResult` and `HeistTestSuccess`, plus Output. A failure
to observe a charge is an incomplete test, not a reason to claim the guardian passed.
The suite runs isolated save-failure contracts and observes actual physical ball
movement, welds, growth, tell timing, release and the player's saved bank delta.
It does not certify phone feel, two-human rivalry or fun. Those need Zion's verdict.

## Saves and rejoin

Studio defaults to the existing **ProfileStore.Mock**: survives character respawn
and the live suite within this server, but **not Stop/Play**. The HUD bank is only
awarded after ProfileStore's save acknowledgement. Failed saves hold the extracted
ball and retry the same operation; pickup/bumps cannot change a pending haul.

An authorized published-server test uses the separate `StealTreasure_Heists_v1`
DataStore automatically. No old treasure saves are changed. With API services
already authorized/enabled by Zion, `ServerScriptService.HeistUseDataStore = true`
before his Studio session enables real persistence there. This task did not enable
API access, publish, enter credentials, or test a real DataStore. Rejoin persistence
against Roblox services remains **UNKNOWN** until Zion runs it. Do not treat a
mock roundtrip as proof that a real rejoin passed.

## Offline rebuild

From `pumpkin/production`, use installed Lune 0.10.5:

```powershell
lune run slice-v2/heists/check.luau
lune run slice-v2/heists/build.luau
```

If the Rokit shim reports `home directory not found`, invoke the installed binary
at `C:/Users/zerha/.rokit/tool-storage/lune-org/lune/0.10.5/lune.exe` with those same
arguments. No environment or security change is needed.

`OFFLINE-RESULT.txt` records contract results. `BUILD-REPORT.json` records source
mounts and binary roundtrip results. The builder creates a new DataModel with static
greybox geometry; it compiles scripts without running them. Shared Profiles,
MockStore, UIStyle and vendored ProfileStore are mounted directly from
`prototype/core`, with the Apache-2.0 licence embedded. Source changes use apply_patch;
the rbxl and reports are generated outputs. No commit.

Known limits: physics/control/visual quality, actual run timing, mobile/controller
layout and two-human fun are untested. Server-authoritative rolling favors honest
pickup ownership; latency feel needs Zion's test. There is one heist, no Bed build,
no gadgets, no progression shop, no global leaderboard and no final art/audio.
Files stay in this requested repo; this sandbox cannot write to Desktop.

Input integration was checked against Roblox's [Humanoid.MoveDirection reference](https://create.roblox.com/docs/reference/engine/classes/Humanoid/MoveDirection),
which marks that property as not replicated. The client sends movement intent at
10 Hz; server rules reject invalid/oversized vectors and excess packets, expire
stale input, and apply physical forces only near the ball. Ball physics stay on
the server, following the [network ownership API](https://create.roblox.com/docs/physics/network-ownership).

Lessons: when the ball grows, budget the escape aperture around its maximum diameter
because a funny big haul must remain escapable. When saving can yield, freeze the
haul before persistence because bumps and retries must not change the banked value.
