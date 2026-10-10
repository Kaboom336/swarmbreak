# Guard twists plan (arena r22, merged; PB base + PA details)

Rule: every guard keeps the chase, plus ONE signature twist. Same visual language for all: red circle or red lane on the ground (reuse the King `Telegraph` remote + `landAttack`, Patch.server.luau ~5885-5947; hook into the Guardian chase loop ~4300), guard freezes in a pose + one unique sound during the warning. Twists never BONK directly (only slow / root / push / pull / teleport); being caught still starts the FIGHT bar. First twist 3 s after wake; 1 s mercy after a hit (no twist on you); slows capped at 2 s; nothing in the hub safe zone; one active effect per guard. Slowed/rooted players get a head icon. Add a server-side WalkSpeed multiplier attribute if no slow path exists.

| Zone | Guard | Twist | Cooldown / warn | Effect | Counter |
|---|---|---|---|---|---|
| 1 Meadow | Scarecrow | Crow dive: shadow circle r6 on your spot | 8 s / 1.5 s | slow to 60% for 1.5 s | keep walking out of the shadow |
| 2 Graveyard | Skeleton | Bone throw: red lane 40 x 3 at you | 7 s / 1.3 s | push 12 studs + slow 1 s | sidestep |
| 3 Haunted Woods | Tree Ent | Root ring r8 under you | 8 s / 1.4 s | rooted 1.5 s | leave the circle |
| 4 Witch Swamp | Frog | Leap to where you'll be (circle r7, 1 s ahead) | 8 s / 1.2 s | tongue pulls you 10 studs toward the nest | change direction |
| 5 Vampire Castle | Vampire | Bat hop: purple ring + ghost silhouette 18 studs ahead; guard teleports there (particle bat swirl) | 9 s / 1.5 s | blocks your path | turn aside |
| 6 Candy Land | Candy Bear | 2 sticky puddles r6 in your path, last 6 s (pink glow, gloop) | 8 s / 1.2 s | slow to 40% inside | walk around |
| 7 Throne | Pumpkin King | 3 boulders in a fan (red lanes w6), speed 50 | 7 s / 1.5 s | push 14 + 1 s dizzy | leave the lanes |

All numbers live in one Config table (Config.GuardTwists[zone]) for tuning. Cut: separate crow AI, multi-bone volleys, real bat models, minions.
Build ~3.5 h: twist scheduler + config 45 min; circle twists (1,3,4,6) 60; lane twists (2,7) 45; vampire teleport 30; client lane telegraph, slow/root/pull, head icon, sounds 45; tuning 15.
