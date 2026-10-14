# Independent offline look review

Final scene SHA256: `7b8fffdcb0ab7b90f20ba1f3024a63d2297726eb4f43c65cf3e86a0dacd2d286`.
34,552 manifest parts. The read-only critic verified the matching render metadata,
inspected the actual before/after hill and 3/4 images, and reviewed lighting code.

**Final: offline visual PASS; Studio UNKNOWN.** The continuous hill turf,
attached vegetation/flowers/boulders, clear skylights and rock variation pass
the offline review. The final clipped boundary removes the previously exposed
right-side grass tabs. Local dark cave/rock joins remain visible without the
former thin-panel overhangs. No source blocker remains after client override
guard and effect instance reuse were reviewed.

The first candidates failed on perimeter tabs and the hill toe slit. A projection
diagnostic traced low grass cells beyond the actual island footprint. Visible
skin was clipped at those unsupported cells; collision geometry stayed identical.
Perimeter banks and embedded rock/grass rolls give the remaining edge thickness.
The critic accepted the final scene after inspecting regenerated images.

GardenWarm/Grow a Garden remains the named style bar; private game lighting
settings and live gameplay/reference fidelity were not inspected. Offline Cycles
images prove geometry/colour comparisons, not Roblox effects. Runtime lighting,
replication, FPS and solo/PvP/trap results remain UNKNOWN / NOT RUN.

Lessons: When a hill boundary looks like a panel, project the offending cells
back to the map because zero collision counters cannot detect unsupported
cosmetic silhouettes. When A/B lighting replicates, reuse saved effect instances
because server/client reconstruction can race.
