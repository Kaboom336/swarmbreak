# 28929ca captures (Swarm Queen + enemy pool)

I drove the run with Studio MCP: auto-fire, standing still in Landing, Normal difficulty, with a heal hook that tops HP back up below 50%. The desktop recording stopped after about 3 minutes when the screen locked, so these are stills only.

## BLOCKER: the wave 15 Queen never spawns, and the run soft-locks
Server log at wave 15 (696 s):
```
ServerStorage.EnemyPool:40: no enemy pool factory for Queen
  EnemyPoolLogic:67 take <- EnemyPool:51 take <- EnemyRigBuilder:233 build
  <- EnemyBuilder:686 build <- EnemyAI:395 spawn <- WaveManager:308 spawnEnemy
  <- WaveManager:586 runWave <- WaveManager:763 gameLoop
```
- The error kills `gameLoop`. The HUD sits on "WAVE 15, 0 LEFT" with the timer running (02-wave15-no-queen.png).
- BossName stays empty. There is no intro, no input lock, no phase 2 and no kill, so none of the Queen checks could be done.
- The boss path (WaveManager:586, `spawnEnemy(bossName, bossAt, false)`) goes through EnemyRigBuilder → EnemyPool.take, and the pool has no factory registered for "Queen".
- Note: Enemies.bossForWave(15) returns "Warden", but WaveManager uses currentMap.BossKey (Queen) for wave 15. That's fine, just inconsistent.

## Pool run (waves 1–15)
- WaveReached: w1 0s, w2 24s, w3 49s, w4 77s, w5 108s, w6 141s, w7 207s, w8 272s, w9 349s, w10 420s, w11 491s, w12 542s, w13 594s, w14 646s, w15 696s.
- **No stalls before 15.** The 40-second no-change watcher logged nothing.
- Frame times (client RenderStepped, per wave): average 60 fps in every wave.
  - Worst frame was 22–25 ms in every wave **except wave 5: 276 ms**.
  - Waves 8–10 worst: 23 / 22 / 23 ms. The old 275 ms hitch is gone from the bursts. It now shows only at wave 5, probably the Brute boss spawn (non-pooled) or the end-of-run-5 crate.
- The only server errors were the Queen pool error above. There were no rig errors.
- Pooled enemies walk in and die normally as waves clear. I did not get a still of a goo burst.
