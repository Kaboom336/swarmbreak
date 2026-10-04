# Art-final2 fight captures: integrate/wave13 @ 5dd4367 (2026-10-04)

Built from 5dd4367 and opened in Studio. Pad terrain pasted back from LandingPad.rbxm.

**Capture harness (scratch place only, not committed):** the default profile in ProfileSchema was patched so the run starts with:
- Reaper owned and equipped;
- `StageClear_Outpost9_Normal_4` set, so stage 5 can be picked.

This was needed because execute_luau runs in its own Luau VM: calling PlayerData or GameState from it changes a separate copy of the module, not the game's.

Selection: stage via the player's `SelectedStage` attribute; ultimate by firing the WeaponAbility remote `ReaperArc` from the client.

## Shots and scores
| # | Shot | vs Hunty | Bright, sharp anime action? |
|---|---|---|---|
| 01 | midfight: stage 1 wave 2, scythe swing (gold slash ring), mites in frame, cyan kill-burst streaks, HUD on | **worse** | Partly. The slash ring and bursts are thin streaks. The frame is cluttered because the camera sits in a corner. Hunty's hits fill the screen. |
| 02 | stage1-finale: wave 3 swarm of mites plus a Tank, HUD on | **close** | Bright, saturated and readable. The enemies pop against the warm pad. No VFX in this instant. |
| 03 | boss-big-brute: stage 5 wave 4, BIG BRUTE boss bar showing (313/1016) | **worse** | No. There's a bug (below). The Brute renders as a huge cyan mass above the north art gate. |
| 04 | reaper-ultimate: mid-cinematic | **close** | Yes. Bold yellow "REAPER ARC" title, purple and gold diamond lattice, orbit camera. It reads as anime. (It was cast between waves, so there are no enemies in the shot.) |
| 05 | side-by-side: fight and finale, ours next to Hunty | **worse** overall | The environment and enemy colours are close. Hit and kill VFX size and impact are still well behind Hunty's full-screen purple and orange effects. |

Extra frames:
- x-kill-burst-wave-clear: the orange radial kill burst.
- x-wave1-pack-behind-cover.
- x-cards-open-midfight.
- x-boss-closeup-camera-inside.

## Bugs found
1. **The boss is stuck on the north gate.**
   - On stage 5 wave 4 the Brute's bounding box was 100x56x94, centred about 72 studs up at (-6, -70), above the north art gate.
   - Its HP stayed at 313/1016 for more than 20 seconds. The player couldn't reach it, and the camera filled with a cyan wash when it got close.
   - In the earlier stage 5 run the boss wave finished quickly. So it doesn't happen every time.
2. **Waves are cleared in a second or two with the scythe.** Mid-fight frames are hard to catch. The finale's 20-second minimum is the only wave that lasts.

## Card panel check
- With RewardCards hidden on the client for 3 full runs, nothing stalled.
- `CardPicked` logs every ~8 s (for example 18 s, 26 s, 34 s), and waves advanced normally. The 8 s auto-pick fixes the old stall.

## FPS
Client RenderStepped, Studio in the foreground, 1920x1080.

| Run | Wave | Average | Worst frame |
|---|---|---|---|
| Stage 1 | 1 | 60 | 28–46 ms |
| Stage 1 | 2 | 60 | 30–38 ms |
| Stage 1 | 3 (finale) | 60 | 54 ms |
| Stage 5 | 1 | 60 | 37 ms |
| Stage 5 | 2 | 60 | 31 ms |
| Stage 5 | 3 | 60 | 36 ms |
| Stage 5 | 4 (boss) | 59.7 | **272 ms** (one spike around the boss spawn); 39 ms in the stuck-boss run |
