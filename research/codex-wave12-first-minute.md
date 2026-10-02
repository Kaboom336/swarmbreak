# Codex wave 12: "First minute is fun" (TOP PRIORITY, supersedes overlapping wave 9-11 tasks)
Why: Zion's Play video 2026-10-02 03:04 (/mnt/project-files/20261002-0304-34.7624998.mp4), verdict "terrible". Observed in the frames:
1. Arena is pitch black: Floor colour 40,42,50 Slate under night lighting reads as a void; only teal grid lines and giant cyan fan discs / magenta beams show.
2. Enemies are invisible: dark bodies on a black floor; only their red health bars float. Player character is a tiny dark blob.
3. Combat does not land: 1 minute of play, Kills 0, died in wave 1 twice. No visible tracers, hits or feedback.
4. HUD clutter: Quests panel always open on the left, Shop bar mid-right, stat text rows at the bottom, "TOP SURVIVORS" billboard in the arena, and a run-summary panel covering the centre with auto "Restarting in 9".
Bar: Hunty Zombie (bright, readable, big juice), Deep Rock Galactic (readable enemies), Final Swarm (first kill in seconds, first level-up fast).

Base: integrate/wave8 e95bb4f. Merge in any finished wave 9 branch first if it touches the same files.
Rules: failing spec first, listed files plus one spec, no blood (goo teal/green), prices 0, run 3 at a time.
testcmd: cd game && stylua --check src tests && selene src && lune run tests/run.luau && rojo build default.project.json -o out.rbxl

## F1 Bright arena now
Station lighting: ClockTime 15.5, Brightness 2.5, blue sky, warm sun, Bloom Threshold 0.9, ColorCorrection Contrast 0.1 (also baked in default.project.json). Floor colour ~ (170,175,185) Concrete/SmoothPlastic with a subtle darker grid; walls mid-grey with teal/amber neon trim only as thin strips. Shrink the cyan fan discs to small floor decals and remove the tall magenta beams (spawn pads become small glowing rings). Move the TOP SURVIVORS board to the Base only.
Spec tests/arenalook.spec.luau: floor relative luminance >= 0.45; no Neon part with any size axis > 12 studs in the arena; ClockTime 14-17; project.json Lighting equals the preset.

## F2 Readable enemies
Every enemy gets a Highlight (OutlineColor warm orange, FillTransparency 1, OutlineTransparency 0.2; cap 30 live, nearest first), body colours lifted so contrast vs floor >= 3:1, scale via Fit so a Walker is about 1.2x player height. Health bar shows only after first damage, sits above the head.
Spec tests/enemylook.spec.luau: Theme enemy colours meet contrast vs floor; every enemy type has a scale entry in range 1.0-1.6 (bosses 2.5-4).

## F3 Third-person camera like Hunty Zombie
Over-the-shoulder camera, distance 12 studs, offset right 2, mouse lock on PC by default (toggle in Settings), centred crosshair; touch keeps current auto-aim. Character faces aim direction.
Spec: Shared/CameraConfig.luau values in range; crosshair hidden on touch.

## F4 Combat that lands every click
PC soft aim assist: snap to nearest enemy within a 6 degree cone and weapon range (reuse AimAssist). Every shot shows tracer + muzzle flash; every hit shows a white flash 0.06 s, hit spark, damage number, hit sound, small knockback; kills show a goo burst + coin pop. Make all non-button HUD frames Active=false so clicks over panels still fire.
Spec: AimAssist cone pick test; static scan that HUD Frames default Active=false; Feel timings in range.

## F5 First 60 seconds tuning
Spawn: 3 s countdown with "Survive 5 waves" goal line. Wave 1 = 8 Walkers from one side, slow, die in 2 starter hits; player HP 150; 2 s spawn protection. First kill within 5 s, first level-up card about 15 s in (wave 9 T8 if merged, else a minimal 3-card pick from existing perks).
Spec tests/firstminute.spec.luau (pure, from WaveTable + weapon stats): wave-1 time-to-kill <= 1.0 s per Walker; Walker reaches player no sooner than 4 s after spawn; first level XP <= 3 Walker kills.

## F6 Clean HUD
During play only: wave + timer top centre, HP bar bottom-left, XP bar bottom full width, ammo bottom-right, small icon column left (Quests, Shop, Settings) that opens panels on click. Remove the bottom stat text rows (move to Stats panel). Max 3 panels visible during play.
Spec tests/hudlayout.spec.luau: no overlaps at 1920x1080 and 1334x750; play-state visible panel count <= 3.

## F7 Death and restart flow
On death: 3 s spectate with "Respawn next wave" or, if all dead, a compact summary card (wave, kills, gems) with one big Play again button; no full-screen panel during play; no auto-restart countdown over a living player.
Spec: state machine pure test (alive -> dead -> spectate -> respawn / summary).

## F8 Auto-capture for review
game/tools/capture.luau (wave 9 T5 if done): 6 fixed cameras incl. gameplay camera at wave 1 with 8 enemies, saves screenshots, so Claude can judge without a video. No unit test; selene/stylua clean.

## Order and what changes in waves 9-11
Run F1, F2, F4 first, then F5, F3, F6, F7, F8.
Wave 9: T1 superseded by F1 (keep its presets file if done), T6 superseded by F6, T3/T2 feed F4 (merge if done). Keep T8 and T7. T4 UI kit after F6.
Wave 10: keep A3 (boss poster) and A5 (juice); hold A1, A2, A4, A6 until the first-minute playtest passes.
Wave 11: keep B12 (save safety), B9 (enemy tells), B1 (difficulty); hold the rest until the playtest passes.
