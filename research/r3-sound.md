## R3 Sound and music (2026-10-01)

Evidence limits: devforum/youtube blocked; create.roblox.com/docs/audio and /audio/assets loaded; SoundGroup reference fetch was denied. No data on how Final Swarm / Survive the Swarm mix their audio was found; layering advice below is generic game-feel guidance, marked est. where it is our judgement.

### a. Audit of game/src (what exists)
- `Shared/Sounds.luau`: 27 entries, all `rbxasset://sounds/...` client built-ins reused with Pitch tricks (e.g. ShotPistol, ShotSmg and Orb all use electronicpingshort.wav; Swing/Dash share swoosh.wav; WaveStart is bass.wav; BossRoar is HalloweenGhost.wav). `Music.Id = ""`: the game ships with no music. No distinct boss music, no wave-clear vs victory stinger, no low-health loop.
- `Shared/SfxMap.luau`: only 4 events (enemy kill, wave clear, quest done, kit equip). Nothing for wave start, boss spawn, level-up/card pick, crate open, pickup, low HP, evolution. Combat code still names Sounds keys directly (Combat.server.luau lines 74/129/159 via `Sounds.ForWeapon`).
- `StarterPlayerScripts/ClientFX.luau` `ClientFX.sound`: creates a new Sound (plus an anchored Part when positional) per call, Debris 4 s, parent SoundService or workspace. No SoundGroup, no concurrency cap, no per-name cooldown, pitch jitter default only +-5% and not chained. Volume = def.Volume * sfxVolume; music one `Sound` in SoundService, no ducking.
- `Shared/Settings.luau`: DefaultVolume 0.5 for both music and SFX; sliders exist in Hud.client.luau (lines ~331-386). No mute toggle, no "reduce screen effects" link.
- Risk: a 15-weapon SMG-style fire rate x 8 players x kill splats can create hundreds of Sound instances per second with nothing capping them (est.).

### b. Findings
1. Roblox's own test: 1-400 Sound instances run normally, 401-500 shows desync, 501+ cuts audio after 2-4 s; tested on a desktop i5, "results vary by device", so mobile headroom is lower (est.). Source: https://devforum.roblox.com/t/total-sound-instance-limit/3736250 (via fetch). Our rule (est.): cap at about 24 live one-shots per client, 6 per name.
2. Layering: good feedback stacks sound, burst, hit-stop, flash, knockback, shake and number, scaled to event size, kept transient (https://atskills.one/gamedev-skills/game-feel). Our Hit(0.3)/Kill(0.5) are one layer each; kill should be 2 layers (thud + short high tick) and chained kills should rise in pitch (COMPARISON c2).
3. Audio privacy: since 22 March 2022 all user-uploaded audio became private; only audio from Roblox's licensing team can be public (https://progameguides.com/roblox/roblox-to-private-millions-of-user-created-sounds-within-its-audio-database/). Now your own uploads work in your experiences and you can grant permission to specific experiences/friends (https://create.roblox.com/docs/audio/assets).
4. Allowed supply: Creator Store has 100,000+ free professionally produced SFX and music (https://create.roblox.com/docs/audio). Uploads: ID-verified 2,000 free audio per 30 days, unverified 100; mp3/ogg/wav/flac, <20 MB, <7 min, <=48 kHz (https://create.roblox.com/docs/audio/assets). Zion's account should be ID verified before the sound pass.
5. Cheap SFX: Kenney Impact Sounds is 130 files, CC0, no attribution (https://kenney.nl/assets/impact-sounds); Kenney Interface Sounds also listed (https://kenney.nl/assets/interface-sounds, license not fetched, Kenney packs are normally CC0, verify). sfxr-style generators (jsfxr) make retro pings/zaps in seconds (not verified on a fetched page; confirm licence of output on the tool page). Uploaded CC0 audio still goes through Roblox moderation (est. delay minutes to days).
6. Bundled rbxasset sounds are fine for a prototype but they are the "default Roblox" sounds every player knows; no loudness consistency between them (est.).
7. Volume defaults: we mix everything at 0.5 master. Keep music at about 0.25 * slider (already) and SFX at 0.5; mobile speakers favour mid frequencies (est.).

### c. Recommended design (all est. except where cited)
- Buses: SoundGroups `Music`, `Sfx`, `Ui` under SoundService; slider drives group Volume instead of per-sound multiplication.
- Priority tiers: P0 boss/wave stingers and player hurt never dropped; P1 player weapon; P2 kills/hits (rate-limited 1 per 60 ms per name); P3 enemy spawn/ambience (dropped first).
- Ducking: when a P0 stinger plays, tween Music group to 40% for 1.2 s; or CompressorSoundEffect sidechain (not verified in docs fetch).
- Stingers: WaveStart (rising 0.8 s), WaveClear (bright 1.2 s), BossIntro (low hit + roar), Victory, Defeat. Music: calm lobby loop, combat loop, boss loop; crossfade 1 s on state change.
- Kill chain: pitch = base * 2^(min(chain,12)/12) resets after 1.5 s idle; shotgun/hammer hits get an extra heavy layer.

### d. Concrete changes
1. **Sound budget module.** `Shared/SoundBudget.luau` pure: `allow(name, nowSec, state)` enforces global cap (24), per-name cap and min interval, priority drop; ClientFX.sound calls it before Instance.new. Test in Lune with fake clock. Evidence https://devforum.roblox.com/t/total-sound-instance-limit/3736250. Effort S. Codex.
2. **Chain pitch + layered kill.** `Shared/KillChain.luau` pure (`pitchFor(chain)`, reset window); SfxMap gets "enemy kill heavy"; HitMarkers.client uses it. Evidence https://atskills.one/gamedev-skills/game-feel (layer, scale to event). Effort S. Codex.
3. **Expand SfxMap events** (wave start, boss spawn, card pick, crate open, pickup, level up, low HP, victory, defeat) and route Combat/Hud calls through it; add test that every mapped name exists in Sounds. Evidence: audit above. Effort S. Codex.
4. **SoundGroups + music ducking + mute.** `Shared/Mix.luau` pure ducking envelope (target gain by time since stinger); ClientFX creates groups and applies it; Settings adds Mute. Evidence https://create.roblox.com/docs/audio (SoundGroup page not fetched; verify API on laptop). Effort M. Codex.
5. **Replace placeholder SFX with CC0 set.** Pick about 40 files from Kenney Impact + Interface, plus 6 jsfxr zaps; trim, normalise to similar loudness, verify ID, upload under the ID-verified account, swap Ids in Sounds.luau (keep rbxasset as fallback). Evidence https://kenney.nl/assets/impact-sounds, https://create.roblox.com/docs/audio/assets. Effort M. Claude (judgment, upload).
6. **Music tracks.** Choose 3 loops (lobby, combat, boss) from Creator Store free audio; set Sounds.Music per state; crossfade in ClientFX. Evidence https://create.roblox.com/docs/audio. Effort M. Claude (taste) then Codex (state switch).
7. **Mobile mix check.** On a phone: confirm no clipping at 8 players, stinger readable over fire; log live Sound count with `#SoundService:GetDescendants()` in a dev overlay. Evidence https://devforum.roblox.com/t/total-sound-instance-limit/3736250. Effort S. Claude.
