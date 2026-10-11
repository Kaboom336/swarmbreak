# AUDIT: VFX + SFX + game feel (ASPECT=VFX-SFX)

Auditor pass on 2026-10-10. Evidence comes from `giant/src/StarterPlayerScripts/Patch.client.luau` (line numbers given as `C:nnnn`), `Patch.server.luau` (`S:nnnn`) and `PatchConfig.luau` (`Cfg:nnn`). It also uses a live read-only Studio client query during the owner's playtest, frames from `rec/play_000.mp4` (0:30 and 2:14) and `seg0/sheets/play_000_sheet02/08.jpg`. The references are `refs/aspects/vfx/REFERENCES.md`, `HOWTO.md`, `BIBLE-STEAL-AN-EGG.md §9` and `BIBLE-PET-SIM-99.md §9`. The recordings have **no audio track**, so the sound findings come from code plus the live SoundService state.

## 0. Inventory: what exists today

| System | What exists | Where |
|---|---|---|
| SFX palette | **5 sounds total**: Pick 9113730784, Bonk 9116488438 (2.2 s long), Brew 99963459517796, Coin 1169806635, Whoosh 9120972321. "Roar" is the Bonk sound pitched down. The Purge "siren" is Bonk alternating between pitch 0.65 and 1.3. | Cfg:899-911 |
| Music | 3 tracks (Day "CandyMenu" is a **71 s loop**, Midnight, Boss). All 3 play at once and are crossfaded by volume. Spooky Hour speeds up the day loop. Mute button. | C:1706-1750; live: all 3 `playing=true`, two at vol 0 |
| SFX routing | `play()` creates a new Sound in SoundService each time. There are **no SoundGroups**, so music and SFX cannot be mixed separately and there is no voice cap. The live query showed 5 copies of Bonk playing at once (their 2.2 s tails pile up). | C:60-73 |
| UI click | Every chunky button plays Pick at pitch 2.2, volume 0.35, and gets a hover/press scale (1.08/0.9). Good. | C:505-520 |
| Smash hit | White Highlight flash 0.08 s, squash 1.08/0.9 over 0.07 s, 6 sparkles, damage number (34 to 56 px, PS99-style), Bonk with the pitch rising per combo, "xN COMBO!" from 3 hits, HP bar only on your target. | C:3530-3590, 181, 3498 |
| Smash pop | 2 bursts (26 sparkles + 14 smoke), 6-10 neon candy bits that pop out and magnet in over 0.55 s, Coin on the first arrival, "+N 🍬" float, counter punch, shake(0.4). | C:3592-3662 |
| Swing | Scythe swing pose, `SwingTrail` (the **only Trail in the game**), Whoosh with random pitch. | C:3381-3455, S:6593 |
| Carry | Head-stack pop "+1 🎃" (Back 0.18 s). Stolen or hoard carry adds a RUN!! pill pulsing 1.07x, a red Drop pill, and a **4-edge red vignette 18% (top/bottom) and 13% (sides) thick, BackgroundTransparency 0.1 to 0.5 at 6 rad/s**. | C:238-288, 4934-5030 |
| Steal grab | Hint text, Coin pitch 1.4, shake(0.5). No flash, no halo burst, no alarm sting. Victim: 2 red flashes plus Bonk pitch 0.5, and the thief gets a red AlwaysOnTop Highlight. | C:5027-5050, 5064-5090 |
| Hatch | Rock for 1.6 s (10 accelerating cycles, white glow builds), white Highlight flash, 24 sparkles, 6-10 physics shell slabs lying 2.5 s, Bonk pitch 1.5. Owner gets a white-to-pink screen flash, shake, FOV punch 70→85→70 (Back), then the reveal card. | C:6090-6330 |
| Rarity reveal | White card with a rarity-coloured 6 px stroke, 8 static rays, a spinning ViewportFrame pet, RARITY / name / +X/s, blur 18, 45% dim, confetti for Rare and up, Brew at pitch 1.2/1.5. | C:2430-2700 |
| Events | Phase lighting tweens (Spooky orange-purple, Purge pink, King Night red) with 20 client bats in Spooky Hour, a banner for Purge and Ghost/King, "siren" from the pitched Bonk, toast for everything else, plus Brew at pitch 0.7 on every announce. King: stomp rings, neon lane telegraph, damage numbers, kill burst of 120 sparkles + shake(2) + FOV 90→70. | C:2404-2428, 3060-3360, 3820-3930 |
| Purchases | Scythe, upgrade and pass purchases get a **toast + Coin, nothing else**. Only Daily gets confetti. | C:1544, 1592, 2200-2212, 5272 |
| Post-processing | **4 ColorCorrectionEffects stacked**: MapCC sat +0.15, BaseGrade +0.22, ColorCorrection +0.12, PhaseTint +0.10, for a total **saturation of +0.59** and contrast of +0.22. Bloom threshold is 1.6 (almost nothing blooms). DOF is off. SunRays is on. | live Lighting query |
| Camera shake | `shake()` adds a random positional offset to `camera.CFrame` inside a `task.wait(0.02)` loop. | C:290-297 |
| Counts (live) | 36 ParticleEmitters, 1 Trail, 0 Beams in the workspace. | live query |

The team clearly knows the vocabulary: the hatch, reveal and smash beats copy the reference timing well. The game falls short on **sound identity, mix, Halloween-specific VFX and a few broken or overcooked effects**.

## 1. Scores (1-10, our game against each reference)

| Checklist line | vs Steal an Egg | vs Pet Sim 99 | Note |
|---|---|---|---|
| Hit feedback (flash, squash, number, sound) | 7 | 6 | The beat structure matches PS99. The sparkle burst is generic and the shake does not show (see F2). |
| Collect / pickup (magnet, counter punch) | 7 | 6 | Candy magnet is good. "+N" overlaps the counter (W2: "67 +4" garbled; frame 0:30 "29.8k+314"). |
| Number pops (damage, income, float) | 6 | 6 | Damage numbers are fine. Too many pop types stack: "+132" over "MVP", "x5 COMBO" over "+19" (frame 2:14). |
| Hatch sequence | 7 | 7 | Rock, slabs, flash and FOV punch all follow REFERENCES §3.1. There is no hatch-specific sound (it uses the Bonk sound). |
| Rarity reveal | 5 | 5 | It is a static white card with 8 non-rotating rays. Every rarity gets the same flash and sound. A Legendary feels the same as a Common, apart from confetti. |
| Steal grab | 4 | n/a | SAE has a white flash, a prismatic halo sphere, a ground beam trail and the "You stole an EGG!" toast. We have a hint, a coin sound and a shake that does not show. |
| Carry state / vignette | 3 | n/a | Too thick and too opaque. It also stays on in the hub and Safe Zone, and it fires for a **Hoard** carry with nobody chasing (live: `CarryHoard=1`, `CarryStolen=0`). Sheet 0:24-0:34 shows the whole frame tinted red. |
| Chase / danger audio | 2 | n/a | No heartbeat, alarm or chase layer. The guardian roar is the pitched Bonk sound. |
| Fight (King / ghosts) | 6 | 6 | Telegraph rings and lanes are good. Stomps use Bonk pitch 0.45, which reads as a "toy bonk", not a boss. |
| Purchase / upgrade feedback | 3 | 2 | PS99 and SAE flash the bought object, burst sparkles and use confetti. We show a toast only. |
| Event announcements (Spooky / Purge / King) | 5 | 5 | The lighting shifts are good. The banner sound is generic Brew, the "siren" is Bonk, and there is no stinger per event. |
| Screen grade / tint | 3 | 3 | +0.59 stacked saturation is the root of the "garish lime" note in W1/W2. The Purge tint plus vignette turns the screen pink-red. |
| Camera shake | 2 | 4 | Effectively invisible (F2). |
| Sound palette / identity | 2 | 3 | 5 sounds reused for about 70 cues. Nothing sounds like Halloween (no bells, organ, cackles or creaks). |
| Music | 6 | 6 | Licensed tracks with phase switching. The 71 s day loop will grate within 10 minutes. |
| UI clicks / hover | 7 | 6 | Click sound and scale are present. Panel open/close has no sound or whoosh. |
| Ambient world VFX | 4 | 4 | Bats only during Spooky Hour. Pumpkins and jack faces barely bloom (threshold 1.6). No fog wisps or fireflies at the base. |

## 2. Issue table

| id | What is wrong (specific) | What refs do | Our distinct-style fix (Halloween identity) | Sev | Effort | Simplify/cut? |
|---|---|---|---|---|---|---|
| F1 | The carry vignette is a 4-edge frame 18%/13% thick at 0.1 transparency, so it fills the whole screen. It fires on a **Hoard carry** and stays on in the **Safe Zone/hub** (C:5005-5025; W1/W3; sheet 0:24-0:34). | SAE: a thin red ring on the outer 8-12% of the screen at about 60% alpha, a slight pulse, only while being chased. | Use one radial ImageLabel vignette in **deep orange-to-blood (#FF3A1A to #7A0010)**, edges only 10%, transparency 0.45-0.7. Show it only while `CarryStolen>0` or a guardian is awake, and fade it out in the Safe Zone. Add a "candle smoke" edge texture flicker for our own look. | blocker | S | Cut the 4-frame build and replace it with 1 ImageLabel |
| F2 | `shake()` offsets `camera.CFrame` from a `task.wait` loop. The CameraModule rewrites position every RenderStepped, so the shake is at most a 1-frame jitter and uses random (not noise) offsets (C:290). About 15 call sites (hatch, steal, King kill) lose their punch. | HOWTO §9: rotational `math.noise` shake bound to RenderStepped after the camera, 0.02-0.05 rad for 0.2-0.4 s. | Use `RunService:BindToRenderStep("Shake", Enum.RenderPriority.Camera.Value + 1, ...)` and apply `CFrame.Angles(noise*k...)` with k decaying. Keep the same `shake(strength, steps)` signature mapped to intensity and duration so call sites do not change. | bad | S | no |
| F3 | Saturation is +0.59 from 4 stacked ColorCorrectionEffects (MapCC, BaseGrade, ColorCorrection, PhaseTint). This makes the lime ground and purple paths garish (W1/W2), and every event tint stacks on top. | SAE/PS99: bright but natural daylight, with the saturation in the props and not a global grade. | Keep **one** base grade (sat +0.1, contrast +0.05, faint warm tint #FFF4E8) plus PhaseTint for events. Delete MapCC and ColorCorrection, or zero them. Lower Bloom threshold to 0.95 with intensity 0.6 so only Neon (jack faces, candy) glows: a lantern-lit look, not a highlighter look. | bad | S | Cut 2 effects |
| F4 | Only 5 SFX for about 70 cues. Roar, siren, King stomp, hatch crack and ghost bonk are all the same Bonk at different pitches. Bonk is 2.2 s long, so tails pile up (5 copies playing at once, live). | PS99: every action has its own short sound (pop, coin tick, hatch whoosh+chime, rarity sting). SAE events have alarm stingers. | Build a **16-sound Halloween kit** (§4) and route it through SoundGroups (Music / SFX / UI) with a per-sound cooldown (max 3 concurrent of one id). | blocker | M | no |
| F5 | The steal grab has no visual beat: hint + Coin + invisible shake (C:5027). | SAE: white flash on the egg, egg lifts above the head in a prismatic halo, ground-beam trail, "RUN!!", then the delivery toast. | **"Soul grab"**: a green-white ghost-fire flash on the pumpkin (Highlight 0→1 over 0.25 s), 20 green wisp particles spiralling up, and a ground **Beam trail in ectoplasm green to purple** behind the thief while carrying. Delivery plays the "YOU STOLE A PUMPKIN!" banner, an orange confetti burst and a bell sting. | bad | M | Reuse the existing burst() and confetti() |
| F6 | The rarity reveal is the same for every tier: the same flash, Brew at pitch 1.2 or 1.5, and static rays (C:2566-2640). | SAE: purple lightning for Secret, a fire burst for Phoenix, rainbow halo rings. PS99: a white radial flash, then the pet flies to the player. | Per-tier escalation using the existing card: rays **rotate** (360° per 6 s); Epic+ gets a rarity-coloured screen tint flash; Legendary+ gets lightning-arc ImageLabels and a deeper sting; Mythic+ gets a 0.4 s hitstop (FOV 70→60 hold) and an organ chord. One table of 6 rows in Config. | bad | M | no |
| F7 | Purchases (scythe, upgrade, pass) get a toast + Coin only (C:1544, 1592, 2209). | SAE: full-screen confetti 4-6 s plus a gold flash on the upgraded object. PS99: an item card plus sparkles. | Buying a scythe gets a gold flash on the held tool, 30 orange/purple sparkles, a "cha-ching + bell" sound and confetti. A pen upgrade gets a ring pulse on the pen floor (reuse the stomp ring code with an orange colour). | bad | S | Reuse confetti(), the stomp ring and burst |
| F8 | Number-pop clutter: "+N" overlaps the HUD candy counter (W2 "67 +4", frame 0:30 "29.8k+314"). The combo float, damage number and +candy float all spawn at about the same spot (frame 2:14 "x5 COMBO" over "+19"). | PS99: one number per hit above the pile and a separate coin tick by the counter. SAE: green "+$" only. | Cap world pops at 1 per type per 0.15 s with a vertical stack offset. Move the counter "+N" **above** the counter (not on its line). Show combo as a single screen-space chip under the crosshair area that scales with the count, not a new float per hit. | bad | S | Cut the per-hit combo floats |
| F9 | Event announcements share the generic Brew sound. The Purge siren is pitched Bonk. Spooky Hour has no sting (C:2404-2428, 3321). | SAE: a central announcement with an alarm, a giant countdown and a white wash on reset. | Give each event its own **3-part signature**: (a) a sting (Spooky: church bell plus bat flutter; Purge: air-raid siren rise; King Night: low gong plus thunder), (b) a 0.3 s screen colour wash in the event colour, (c) a big centre title that scale-pops 0→1.15→1. | bad | S | no |
| F10 | No chase or danger audio. The guardian "Roar" is Bonk at pitch 0.6 (Cfg:905, S:4603). | SAE: the guard wakes with a red "!" and chases with distinct audio cues (implied). | Add a low heartbeat loop at 0.4 vol while a guardian is awake within 60 studs (playback speed rising as it closes in), a proper monster growl on wake, and a "!" pop with a stinger. | bad | S | no |
| F11 | Hatch and reveal sounds are reused (Bonk 1.5 for the crack, Brew for the card). Nothing builds up during the 1.6 s rock. | PS99/SAE: a rising whoosh, then a pop, then a chime. | Use a rising "magic swell" during the rock (start it with `CarveAt-1.6`), a squelchy pumpkin-crack on burst, and a chime pitched by rarity on the card. | polish | S | no |
| F12 | Pickup ("+1 🎃") and candy collect both use Pick/Coin at random pitches. There is no ascending pitch for a streak of collects. | PS99: the coin-collect pitch rises with rapid pickups. | Track a collect streak within 1.5 s and raise PlaybackSpeed by 1.0 + 0.05·n (cap 1.6). This is the cheapest "addictive" sound trick. | polish | S | no |
| F13 | Bloom threshold is 1.6, so neon jack faces and candy barely glow. No ambient VFX at bases. Bats appear only in Spooky Hour. | SAE: constant sparkle fields on ready eggs and auras on rare pets. | Add an ambient kit: jack-face flicker (HOWTO §8), low purple fog wisps in the zone lanes (Rate 4), green fireflies around your own pen (Rate 2, Lifetime 3-5), and a rarity aura on Epic+ pets (HOWTO §7). | polish | M | Limit to own pen plus nearby (the perf note has 23.8k instances) |
| F14 | The music day loop is 71 s and repeats endlessly. All 3 tracks play simultaneously with 2 muted (wasted decode). | Top games: 2-4 min loops or playlists. | Add a second day track and alternate between them. Stop muted tracks with `:Pause()` and resume them on phase change. | polish | S | no |
| F15 | Panel open/close has no sound or motion cue beyond the button press. The reveal card, toasts and banners arrive silently except for Brew. | PS99: whoosh-pop on menus and a ding on toasts. | Use a soft paper whoosh on panel open, a reversed whoosh on close, and a tiny bell "ding" on toasts. | polish | S | no |

## 3. Minimal juice kit (what to build, with exact settings)

### 3.1 Sound kit (16 sounds, free Roblox/ProSoundEffects library audio only, chosen by description; no scripted Creator Store items)
Search the Creator Store Audio tab and filter by Roblox/ProSoundEffects uploads. Listen to each and keep anything under about 1.2 s unless noted.

| Key | Description to search | Use | Vol / pitch |
|---|---|---|---|
| Hit | "pumpkin squash" / "cartoon punch thud" (short, wet, 0.2-0.4 s). **Replaces Bonk on smash.** | wild hit | 0.5, 0.95-1.15 random + combo·0.03 |
| Pop | "cartoon pop" / "bubble pop" | pumpkin breaks, candy burst | 0.7, 1.0-1.2 |
| Candy | "coin collect" / "pickup chime" (bright and short) | candy arrival | 0.4, streak pitch 1.0→1.6 |
| Swing | keep Whoosh 9120972321 | scythe | as now |
| Grab | "magic whoosh up" / "ghost swoosh" | steal grab, pickup | 0.8 |
| Steal | "church bell single hit" / "hand bell" | stole + delivered | 0.7 |
| Alarm | "alarm siren rise" | robbed, Purge start | 0.6 |
| Heart | "heartbeat loop" | guardian chase (looped) | 0.4, speed 1→1.5 |
| Growl | "monster growl" / "creature roar short" | guardian wake, King stomp layer | 0.9 |
| Gong | "gong hit" / "deep impact boom" | King Night start, King stomp | 0.8 |
| Bell | "bell toll" / "clock chime" | Spooky Hour start | 0.6 |
| Cackle | "witch laugh" / "evil laugh short" | Purge or Spooky title (rarely, max once per event) | 0.5 |
| Swell | "magic charge rise" / "riser" (about 1.5 s) | hatch rock build | 0.6 |
| Crack | "egg crack" / "wood break short" | hatch burst | 0.8 |
| Reveal | "success chime" / "level up fanfare short" | reveal card; pitch by tier (Common 1.0 … Mythic 0.8 + organ layer) | 0.8 |
| Buy | "cash register" / "purchase ding" | scythe, upgrade, pass | 0.8 |
| UI | "soft click" / "button tap" (replaces Pick 2.2) and "paper whoosh" for panels | all UI | 0.35 |

**Routing.** Add 3 SoundGroups (Music 0.3, SFX 0.8, UI 0.5) and parent each `play()` sound to its group. Keep a `lastPlayed[id]` with a 0.05 s cooldown and a maximum of 3 concurrent copies per id.

### 3.2 Particle presets (one shared `Fx` module so all 70 call sites stay one-liners)
All presets use `LightInfluence = 0`, `Rate = 0` and `:Emit(n)`.
- **CandyPop** (replaces the generic orange smash burst): default sparkle texture, Emit 18, Speed 14-22, SpreadAngle (180, 180), Acceleration (0, -35, 0), Drag 2, Lifetime 0.4-0.7, Size 0.6→0, LightEmission 1, Color candy palette with hard keypoints (pink #FF5AAA, yellow #FFD23C, cyan #78E6FF, lime #96FF6E, orange #FF8C28). Add a **pumpkin-gut chunk** emitter: smoke texture, orange #FF7A1A, Emit 8, Speed 10-16, Acceleration (0, -50, 0), Size 0.8→0.2, LightEmission 0.
- **Shockring** (smash pop, purchase, pen upgrade): reuse the stomp-ring cylinder (C:3836) with colour = seed or rarity colour, 0.35 s, size to 3× the pumpkin, Transparency 0.2→1.
- **SoulGrab** (steal): Attachment at the pumpkin, Emit 20, Texture smoke, Color #8CFFB4→#9B5CFF, Speed 4-8, EmissionDirection Top, Acceleration (0, 6, 0), RotSpeed ±180, Size 1→0, Transparency 0.2→1, LightEmission 1, Lifetime 0.8-1.2.
- **EctoTrail** (carry, replaces the full-screen tint as the "I'm a thief" signal): a Beam between 2 foot attachments, 0.35 studs wide, FaceCamera false (flat on the ground), Texture none, Color #8CFFB4→#9B5CFF, LightEmission 1, Transparency 0.2→1 over 0.5 s Lifetime (use a Trail with the same settings if a Beam is awkward).
- **RarityAura** (Epic+ pets): HOWTO §7, Rate 12, cylinder surface, rarity colour.
- **GhostFire** (King and hoard guardians): Rate 20, Lifetime 0.4-0.8, Speed 2-4 up, Size 1.2→0, Color #9BFF6E→#2BA84A, LightEmission 1.

### 3.3 Screen kit
- **Vignette**: one ImageLabel with a radial gradient (white, UIGradient Radial, Transparency keypoints 0→1, 0.75→1, 1→0.35), ImageColor3 #C0141E, pulse 0.45↔0.7 at 2 Hz. On only while chased (see F1).
- **Wash**: a full-screen Frame, event colour, BackgroundTransparency 0.4→1 over 0.35 s (Spooky #FF8A2A, Purge #E040C0, King #C01020).
- **Shake**: rotational noise, priority Camera+1. Presets: Hit 0.006 rad/0.1 s, Pop 0.012/0.18, Steal 0.02/0.25, Hatch 0.025/0.3, King kill 0.05/0.5.
- **Hitstop** (Mythic+ reveal, King kill only): freeze the card/pet spin and drop FOV 70→62 for 0.12 s, then Back-ease out.

## 4. The 5 changes that most raise "premium" for the least effort
1. **Fix the carry vignette (F1).** Make it thin, show it only while chased, and turn it off in the Safe Zone and for Hoard carries. This is the most-noticed bad effect in the playtest (S).
2. **Collapse to one colour grade and lower the Bloom threshold (F3).** Total saturation drops from +0.59 to about +0.1 and neon starts to glow. The whole game stops looking "default Roblox highlighter" in one edit (S).
3. **Replace the 5-sound palette with the 16-sound Halloween kit plus SoundGroups and voice caps (F4/F9/F10/F11).** Sound is half of "premium", and the current one-Bonk-for-everything is the biggest gap against PS99 (M, but mostly config).
4. **Make camera shake actually work (F2).** One function rewrite, and about 15 existing call sites (hatch, steal, King, smash) instantly gain impact (S).
5. **Juice the reward moments: steal grab, purchases and rarity tiers (F5/F6/F7).** Use the SoulGrab burst, EctoTrail, confetti and a shockring on buys, plus per-tier reveal escalation. Everything reuses existing burst(), confetti() and the ring code (M).

Also cheap: F8 (number-pop de-clutter) and F12 (streak pitch on candy pickups).
