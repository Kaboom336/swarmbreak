# Raid review and second encounter

CHECKED: mounted RaidSlice, client, server vault interpolation, RaidSliceTest,
RAID-ARENA, RAID-SLICE-1 and game-theory checklist. Source/offline evidence;
live balance, device input, audio and fun remain UNKNOWN. No Studio play.

| Question | Finding | Decision |
|---|---|---|
| Clear tell? | Guardian command, ground arrows and loaded chirp; hit eligibility waits 1.2s after that client's Ready. | Keep 1.5s tell and 1.2s complete warning. Choose the junction from the active encounter on the client. |
| Fair? | One squad reserves Guardian attacks, two sequential locked charges, shared mercy, no retarget and no spawn within seven studs of entrants/cargo. | Keep every condition, 0.45s charge, 1s recovery and 0.3s gap. Do not shorten tells to manufacture difficulty. |
| Harder? | A second optional route decision broadens coverage; actual success-rate change is UNKNOWN. | Add S5 only after one successful escape, reusing the existing per-player meadowEscapes value. One deployment total per cargo remains the cap. |
| Pacifist Outsmart? | Players choose lanes, bait or Jump; no minion HP, attack or kill reward. | Preserve Guardian knock/drop and exact cargo ID/deadline. Preserve walking bypass and immediate portal use. |
| New-player load? | Checklist O3 / bible law 4: teach one system at a time. | S2 is available immediately; S5 requires meadowEscapes >= 1. A failed first attempt cannot unlock it. |
| Counterplay? | Checklist S2 / C4: readable, recoverable loss; arena Evade movement bar. | Both forks retain ordinary walking and a marked low vault. No sprint button, wave wait or new control. |

S5 east ridge wins over S6 spiral: the offline native floor probe found a broad
20.12-stud landing across X102–118/Z38–50. S6's sloped shelves and summit sight
lines would add avoidable placement and warning complexity. S5 supplies another
escape-route choice without changing a floor, blocker or cover. The surface
near Z52 has a pre-existing 0.35-stud finish: lanes/bypass tolerate the existing
floor variation; vault landings stay at X106 where the floor remains 20.12.

Second fork: lanes (116,20,43)→(106,20,43) and
(116,20,53)→(106,20,53), wall (106,21.12,48), walking switch via X112.
The full convex standing-body check rejected the first Z41 placement near the
climb wedge despite clear vertical rays. The entire fork moved two studs north
on the existing landing; no original geometry was changed to make it fit.
All coordinates island-local XYZ. One new 2.8×2×1 wall is an explicit raid
addition, excluded from the cosmetic conservation delta. Original colliders
remain exact. No existing lane is rebuilt or narrowed across its full width.

Encounter definitions share build, lifecycle, hit, cleanup, cue and vault code.
The server's per-step vault exclusion now selects that vault's wall rather than
hardcoding S2; other walls stay blockers. Existing once-per-cargo lifetime,
serial readiness, tunnel cancellation and Guardian coordinator are unchanged.

The final matched camera exposed another issue: S5's cosmetic paving is above
the collision floor. Its 20 nonphysical fork/arrow pieces are lifted 0.44 studs
to remain visible. No floor, wall, trigger, hit lane or vault datum moves.
The final native manifest proves these are the only constructed-scene deltas
from the frozen full DropSample input. The complete saved places match after
neutralizing only that exact cue-height Source change; all queried/collidable
parts, kit inputs and production resolver code stay exact. The full original
N8 lattice reports 31,824 samples across 20 routes with zero failures.

Reference comparison: Steal an Egg (owner-reported wake/run) sets cue clarity;
Evade sets the movement bar; this pass adds one familiar decision rather than
combat. These are the arena's existing reference judgments, not newly watched
footage. Independent Claude live critique remains pending under the owner rule.
