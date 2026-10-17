# Sound kit (picked by Claude 2026-10-11; all load in Studio via ContentProvider; re-check in the published place in batch 8)
| Cue | Asset id | Length | Notes |
|---|---|---|---|
| HitA (swing 1) | 71589018126132 | 0.40 | "Smash a Pumpkin sfx2_hit2" |
| HitB (swing 2) | 120939342937662 | 0.40 | "sfx2_hit1" |
| HitC (overhead slam) | 85745022889572 | 0.40 | "sfx2_hit4" |
| Break (pumpkin breaks) | 85841544161801 | 0.80 | "sfx2_crack_open" |
| Whoosh (swing, every swing) | 9120972321 | 0.56 | ProSoundEffects wood whoosh |
| CandyTick (candy collected) | 4612374807 | 0.70 | coin_pickup_1; pitch ladder 1.0 -> 1.5 |
| Pop (pet pop-out, UI pop) | 109359226723492 | 1.49 | cartoon bubble pop |
| Growl (guard wakes) | 9113980319 | 3.12 | ProSoundEffects creature growl; play 1.2 s then fade |
| Reveal (hatch / rare) | 1840076509 | 2.25 | APM "Through the Roof" sting |
| Buy (purchase / gate) | 134810204798705 | 2.09 | Cash register |
| Click (UI) | 127036696152728 | 0.11 | UI ping |
SoundGroups: SFX (0.6), UI (0.5), Music (0.35), Ambience (0.3). Pools: Growl/Reveal max one; other cues max six, with Explosion deduplicated per source.

## Roadmap 16 — shared Meadow / Cave audio, 2026-10-17

Claude-selected IDs and free/APM/PSE licensing are owner-reported. Codex has not
verified current asset permissions, loading, loop seams or the mix in Roblox.
The heading's older live-load claim applies to the original kit only.

Update, owner-reported Claude live check 2026-10-17: all 13 tested asset IDs
returned ContentProvider Success; Meadow music and ambience played. Growl
stacked two to four copies during one run. This does not verify the post-fix mix.

| Cue | Asset id | Source / use |
|---|---|---|
| Meadow music | 1842172723 | APM, Disguise, reported 106 s; loop |
| Alternate (unmounted) | 1839908728 | APM, Strange But True; live-check fallback |
| Cave music | 1840777445 | APM, Worlds Of Darkness; loop |
| Meadow ambience | 9112835068 | PSE, Neighborhood Birds 2, reported 64 s; sound volume .22 |
| Cave ambience | 9119386571 | PSE, Spacecraft Engine Idle Mild Roar; sound volume .10 |
| CartRolling | 9113385140 | PSE, Bedrock Traffic; volume .35, moving grounded carts only |
| Explosion | 78012301000651 | cartoon_explosion; TNT payoff, support breaks, cart Flight |
| Escape | 1839881844 | APM, Spinning Around (b), reported 2 s; ESCAPED! |
| Steal / pet reveal | 1840076509 | Existing Reveal; carry rising edge / confirmed reveal |
| Keeper alert | 9113980319 | Existing Growl; gameplay alert edge, per-Keeper 6 s cooldown, one voice, 1.2 s + .15 s fade |

`prototype/core/Audio.luau` and `Audio.client.luau` serve both places. Music and
ambience fade out across biome changes over 1.2 s; new ambience fades in over
1.2 s and music eases to its target over .45 s. Music eases to 40% during an active
TreasureCutscenes GUI or Reveal/Escape/Growl sting, then restores over .45 s;
overlapping stings retain the latest expiry. Carry uses the requested +10% music
volume fallback without pitch/tempo changes. Ambience volume above is multiplied
by its .3 group. Explosion uses InverseTapered RollOff 8–100 studs; cart 8–65.
Carts sample actual part displacement at 10 Hz, stop at rest/in flight, and cap
at six rolling voices. Growl and Reveal use one voice each; other one-shot pools
cap each named cue at six. Explosion drops overlapping requests from the same
source part. Pools reuse stopped voices and guard delayed cleanup by generation.

Motion settings adds Music and SFX buttons (Activated, touch/gamepad selectable).
MusicMuted controls Music; SFXMuted controls SFX, UI and Ambience. These are
session-local preferences. Stock character footsteps are untouched. Existing
DecoyRattle and HomeRevealPop join SFX locally; their original groups restore on
audio teardown. Click follows existing UI Activated, Pop follows confirmed
TreasureCore Collect, Buy follows a replicated Coins decrease, and Reveal follows
TreasureCore Reveal or CaveOpenResult=Opened. No speculative purchase success.
The original hit/whoosh/candy kit remains documented above; no new combat hooks.

Steal/escape cues follow the replicated outcome even when the camera beat is
skipped or has already played this session. Meadow success handles either order
of escape-count and Home replication. Empty return/death does not fanfare.
TNT follows PayoffPreview; support blast follows BreakableSpan's collision edge;
cart Flight sounds at the cart PrimaryPart. Audio never sends a remote, writes
gameplay attributes, changes physics, controls, character or server state.

Reference: DOORS is the existing best-in-class threat-audio target from
treasure/CUTSCENES.md. Side by side design intent: its readable threat pacing vs
our quieter biome bed, short Keeper alert and distinct steal/escape payoffs.
This is inferred design intent; no listening comparison or parity claim. One
shared slice is ready for Claude's listening review before more variants.
The exact Keystone Roblox Process Playbook remains unavailable in exposed tools
and the local active-work filenames; its contents are UNKNOWN.

Backups: `treasure/sound-backup-20261017/` (pre-edit sources and complete places),
plus immutable `guardian-greybox.pre-sound.rbxl` and `cave-v2.pre-sound.rbxl`.
Build with Lune `treasure/sound-meadow-build.luau` and
`prototype/cave-v2/build.luau sound`; these patch complete canonical files, verify
UIStyle in both, compile all scripts at O0/O1/O2, and undo the overlay in memory
to prove exact saved-state preservation. Reports: `treasure/SOUND-BUILD-*.json`.

Offline checks: `treasure/sound-check.luau` executes the real audio client/mixer
for both biomes with deterministic services and guarded player writes, checks
full serialized preservation and prohibits gameplay writes/remote sends.
`treasure/sound-existing-checks.luau movement` adds real Activated mute checks to
the existing movement fixture body; `cutscenes` retains its 48 fixture groups.
The old full-place assumptions are replaced by SOUND-CONTRACT's current overlay
proof; existing assertions are not weakened. Core, Meadow behavior/reset and
Cave cart drive/boarding checks also pass. Selene: zero errors/warnings/parse
errors on audio and settings sources. Evidence: `SOUND-CONTRACT.json`,
`SOUND-MOVEMENT.json`, `SOUND-CUTSCENES.json`; all in treasure. Run
`treasure/sound-seal.luau` to hash final sources, places, backups and these reports
into `treasure/SOUND-FINAL.json`.

Claude handoff: reopen each canonical place fresh. Run the CLIENT command-bar
contents of `treasure/sound-live-check.luau` to record ContentProvider statuses
for all 19 IDs (including the alternate and original kit); a successful preload
is not a listening pass. Listen to both loops/seams, birds/rumble balance, steal,
Keeper, reveal, confirmed spending, escape/empty return, TNT/support/cart blast,
moving/stopped/airborne carts, cutscene skip/duck restoration, mute on phone/pad,
respawn and rapid repeated cues. Check that default footsteps remain. Post-fix
listening quality and Claude acceptance remain UNKNOWN. Codex did not
launch Studio Play, publish or commit.

Lessons: when success fields replicate separately, test both orders because
fanfare must follow a confirmed escape; when sounds attach to transient parts,
replace destroyed pooled voices because streamed parts can destroy their audio.

## Keeper stacking fix, 2026-10-17

Inspected Arena's mode and clip mapping: attacks can return to the chase clip
while gameplay remains in Chase. Animation changes are not alert transitions.
Arena now replicates `KeeperMode` for presentation at build, tick mode changes
and reset; it does not change detection, movement, attacks or physics.
The client treats Warn/Chase/DecoyTell as one alert state. Only entry from a
non-alert state can request Growl, at most once per six seconds per Keeper.
Warn-to-Chase and attack clip changes stay silent. Suppressed edges are consumed;
cooldown expiry cannot trigger a deferred alert. Already-alert streamed Keepers
do not bark on observation. Growl has one voice across all Keepers: an allowed
replacement fades the old voice over .15 s and reuses it after .16 s, with stale
callbacks guarded by generation. The normal 1.2 s duration remains.

Reveal had multiple signal paths (carry, open result and reveal event); requests
while its one voice is occupied now drop. Explosion retains distinct positional
sources, up to six voices, but drops repeated requests from the same source
until its current cue finishes. Cart audit: one loop per PrimaryPart already
exists; repeated movement samples do not call Play again, and rest/airborne/
removed carts retire the loop. No extra cart behavior change was needed.

Backed up complete current places and edited sources before changes in
`treasure/sound-stack-backup-20261017/`. Mounted through the existing Meadow
sound wrapper and Cave `build.luau sound` pipeline. Meadow also mounts GreyboxArena
for the mode signal. Both pipeline reports prove exact undo preservation of
unrelated serialized state. The contract compares against these immediate
backups, allowing only the audio sources and Meadow Arena presentation source.
All 96 Meadow and 50 Cave scripts compile at O0/O1/O2.

Offline regressions execute the shipped client in both biomes: repeated attack
clips, Warn-to-Chase, rapid reacquisition, cooldown expiry without a new edge,
fresh entry after six seconds, two Keepers replacing one voice, stale cleanup,
duplicate Reveal paths, duplicate source blasts and repeated cart loop requests.
Audio contract, real Keeper behavior/reset, movement/settings and 48 cutscene
fixture groups pass. Audio Selene: zero errors, warnings or parse errors. Arena:
zero errors/parse errors; one pre-existing multiple_statements warning at line
227 (also present in the backup). Reports remain `SOUND-*.json`; final hashes
are in `SOUND-FINAL.json`. Post-fix live listening is UNKNOWN. No Studio Play,
publish or commit was run.

Lesson: when attack clips return to chase, use gameplay state for alert audio,
because animation edges can repeat during one uninterrupted encounter.
