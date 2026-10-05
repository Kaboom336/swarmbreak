# Codex H1: why hit feedback doesn't show, then one HitFeedback path (2026-10-05)

Base: integrate/wave13 (latest). Diagnosis plus a fix only. No new features.

testcmd: cd game && stylua --check src tests && selene src && lune run tests/run.luau && lune run ../tools/lint_runtime_apis.luau && rojo build default.project.json -o out.rbxl

## Evidence
Play played 5f826a4 as a brand-new player (default profile, Starter Pistol, auto-fire and auto-aim, stage 1). Notes are in research/r6-handson-swarmbreak-baseline.md on the research/r6 branch. Across 3 runs, Play saw:
- **no damage numbers**;
- **no camera shake or punch** on hit or kill (FOV fixed at 70, distance 12.3-13.7);
- **no hit-freeze**;
- only a thin tracer and a small spark.

The code for all of these exists:
- HitMarkers.client.luau draws the numbers from the HitMarker remote.
- ClientFX.shake and Feel.shakeFor handle shake.
- ClientFX sets WeaponHitstopUntil for hit-stop.
- U1 ScreenEffects and AnimeEffects, and FX1 hitSpark, DeathBurst and impact frames.

So something stops them reaching the screen for a normal player.

## 1. Diagnose (write the cause in the commit message)
Check at least:
- Is the HitMarker remote fired for **auto-fire and auto-aim** hits, or only for manual or scythe hits? Check Combat.server and Shooting.client.
- The default shake setting: is a new profile "Off"? The default must be "Full", and settings keep the off switch.
- Budget or quality gating (PoolSize, the NumberScale budget) zeroing things out at the default quality level.
- Hit-stop: is WeaponHitstopUntil only set on scythe hits? Is it read only by WeaponFeel for the Reaper?
- Kill feedback: does DeathBurst run for every kill, or only when a particular event or remote fires?
- Anything parented to a folder that isn't rendered, or destroyed in the same frame.

## 2. Fix: one HitFeedback path
- Add a client module `HitFeedback.luau`. `HitFeedback.hit(info)` and `HitFeedback.kill(info)` are the only entry points from every weapon (pistol, auto-fire, shotgun, scythe, abilities, ultimates).
- In the same frame, each hit fires:
  - an enemy white flash (a Highlight fill pulse, 0.06 s);
  - a damage number;
  - a hit spark;
  - a hit marker;
  - a camera nudge (a small FovStack kick or a shake of 0.15-0.3);
  - a hit sound, layered with pitch variation;
  - hit-stop of 0.03 s for normal hits and 0.06 s for crits and the scythe, applied to the local weapon pose.
- Each kill adds:
  - a DeathBurst;
  - a bigger shake;
  - a kill sound;
  - the impact frame on elites and bosses only (as FX1 did).
- Auto-fire hits get the full feedback, scaled to 0.7 so constant fire doesn't overwhelm the screen.
- Keep every budget from FX1: at most 60 live VFX, low quality halved, centre clear within 0.3 s, FOV only through ClientFX or FovStack.

## 3. Specs
- Every weapon's hit path calls HitFeedback.hit. A source scan covers Shooting.client, ScytheCombat, the ability and ultimate paths, and whatever else fires the hit remotes.
- The server fires the HitMarker remote (or its equivalent) for auto-fire hits. Test the server function directly or by source scan.
- A default new profile has shake "Full".
- HitFeedback.hit produces a damage number, a spark, a nudge and a sound request when given a pure-mock info table. Keep the logic pure and testable, with Roblox calls behind a thin adapter.

## Done when
- The gate is green.
- The commit message names the root cause or causes.
- Play can confirm, by playing like a real player, that numbers, shake and hit-stop show on wave 1 with the Starter Pistol.
