# Blind mobile-performance critic

**Winner: Y. Ranking: Y > Z > X.** Simulated AI persona judgment, based only on BLIND-PACK.md and visual inspection of BLIND.jpg.

| Candidate | Score | Reason |
| --- | --- | --- |
| X | 6/10 | Angular route edges read clearly, but pine layers and cliff facets add silhouette clutter. Its proposed ceiling is highest: 700 cosmetic BaseParts, 64 mesh instances, 55k placed mesh triangles, 8 local lights; estimated 26–40 hours. |
| Y | 8/10 | Broad slabs and cube trees give the clearest construction plan and smallest proposed budget: 450 cosmetic BaseParts, 24 mesh instances, 18k placed mesh triangles, 6 local lights; estimated 18–26 hours. Warm lanes remain distinct at small scale, although the repeated studs/checker pattern distracts. |
| Z | 7/10 | Smooth paths and large masses give the cleanest phone-scale visual surface. Proposed 600 cosmetic BaseParts, 48 mesh instances, 40k placed mesh triangles, 8 local lights and estimated 24–36 hours put it between the others; rounded edge fitting adds work and can imply unsupported walkable ground. |

**Required cut/fix:** For Y, delete the pictured tiny edge blocks and use a plain path with no repeating stud relief. Fit the visible terrace edges to the retained collider footprints; do not square off walkable floor boundaries merely to match the concept.

**Shared cost and uncertainty:** All retain roughly 8,413 protected records/parts per historical documentation; cosmetic simplification does not remove that physical/query cost. Each permits two shadow-casting local lights. Proposed caps and effort are estimates, not achieved counts. Hero/VFX and S9/S10 are excluded. These unmatched 2D concepts cannot establish FPS, draw calls, memory, collision cost or real mesh complexity; actual phone results remain UNKNOWN until a built scene is tested.

**Lesson:** When retained gameplay geometry dominates the floor, choose the simplest cosmetic proposal and verify its collider fit before expanding it, because a prettier concept alone cannot demonstrate runtime savings.
