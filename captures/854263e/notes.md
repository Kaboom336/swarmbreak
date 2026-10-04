# 854263e captures (rig sizes, zone stall fix, Refinery floors)

The screen was locked, so these come from Studio MCP screen_capture. There's no video (c3 not done), and 06 hit was not captured.

## Rig sizes (07-roster-with-avatar.png)
The spawned heights come from EnemyBuilder.build with the live defs. The avatar is Zion's character clone, 6.8 studs including hair and accessories.

| Role (enemy type) | Height | Bounds |
|---|---|---|
| Mite (Walker) | 4.5 | 5.3 x 4.5 x 5.9 |
| Runner | 5.5 | 8.4 x 5.5 x 7.8 |
| Shooter (Spitter) | 6.5 | 6.0 x 6.5 x 10.2 |
| Tank | 10.0 | 11.1 x 10.0 x 9.6 |
| Flyer | 6.0 | 8.9 x 6.0 x 7.2 |

All heights match the role bands exactly. All 5 are the new rigs (each has a Body part).

## Refinery gate floors
A raycast down from each gate (+2 studs) hits a floor at y=1.0:
- RefineryGateNorth (200,2,-68): Outpost9.Zones.Refinery.Floor
- RefineryGateSouth (200,2,68): Outpost9.Zones.Refinery.Floor
- RefineryGateEast (268,2,0): Outpost9.Zones.Refinery.Floor

The Landing and Hive gates also have floor under them.

## Full run, player standing still in Landing (auto-fire, heal hook at 50% HP)
WaveReached times: w1 0s, w2 24s, w3 49s, w4 77s, w5 109s, w6 156s, w7 212s, w8 274s, w9 349s, w10 419s, w11 490s, w12 531s, w13 573s.
- **No stalls.** The 40-second no-change watcher logged nothing.
- Waves 11 and 12 (Hive Core spawns) cleared in about 41 s each.
- Waves 7–10 are the slowest, at 60–75 s each, as Refinery enemies walk in.

## FPS
- Waves 3–9 (264 s sample): **average 59.9 fps**, worst single frame 275 ms. Max alive was 27.
- Earlier light-load sample (e38b458): 60 fps, worst 27 ms.
- The 275 ms hitch happened once, probably a wave spawn or rig clone burst. Worth a MicroProfiler look in an interactive session.
