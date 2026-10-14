# Meadow A/B/C geometry study — incomplete Studio evidence

## Evidence

CHECKED: MAP-V3.md, GDD.md, HANDOFF-NOW.md, v2 Meadow image, existing Scene/Layout/Arena sources.
Reused the inspected native tree, lantern, portal and background-island helpers from Scene.luau.
No external model kit or licence dependency was introduced. The golden acorn and Keeper are native
stand-ins; the owner's approved Blender acorn mesh is not imported in these places.
Exact Keystone Roblox Process Playbook remains unavailable through this session's tools/local intake;
the supplied real-art/greybox/reference rules were applied. No claim the Keystone note was read.

Rojo 7.4.4 built `prototype/meadow-study-seed.rbxl`; installed Lune 0.10.5 authored and round-tripped
three separate binary places. Existing sources and `slice-v2/prototype/guardian-greybox.rbxl` were not edited.
No commit, publishing, imported script kit, purchase, account action or external message.
Authoring edits used apply_patch; place serialization/rendering produced binary artifacts.
Library API checked against [official Lune documentation](https://lune-org.github.io/docs/api-reference/roblox/).

## Independent critic and one bounded correction

Critic first examined source geometry without using the previous judge pick as a ranking.
They found portal jump obstructions, a buried spiral start, and a half-buried C camp ramp.
Those large overlaps were corrected; jumps now sit outside the safety entries.
They then inspected all six explicitly OFFLINE geometry renders beside the v2 reference.
This is NOT the requested blind in-game-shot critique: Studio control was rejected before access.

| Layout | Critic's biggest visible geometry gap | Correction |
|---|---|---|
| A | Square camp plinth; bare edges | Broken noncolliding camp rock faces and grass rim |
| B | Smooth tall spiral skirt resembling a drum | Noncolliding outer rock facets and grass tufts |
| C | Missing west hill / incorrect east hill position | Both hills at specified (-60,+24,+8) and (+60,+24,+10), renewed collision audit; rim dressing |

The final exported geometry is rendered separately in `../offline-preview/`.
Lighting, grass/slate/cobblestone textures, fog and relative scene brightness in these proxies
must not be judged as actual Studio output. V2's rich foliage, final acorn mesh and expressive Keeper
remain larger art gaps. Rough greyboxes are not final art approval.

Named supplied comparison bar: **Steal an Egg** for objective-to-exit clarity; the v2 image for Meadow art.
A has the lowest direct route; B has the strongest terrace silhouette; C presents three crossings.
These are inferred topology observations, not playtested fun or an owner choice.

## Construction adaptations and honest gaps

Camp / portal positions, island envelopes, hill heights, C bridge 12x32/+6, shallow floors,
minimum authored lane widths and <=25-degree ramp angles were checked in the serialized builds.
The marked path lengths are A140.0, B107.3, C238.6 studs; only distance/speed estimates were made.

Some construction details depart from nominal blueprint positions to fit walkable surfaces:
A's south route dog-legs and its west inner link routes around the camp ramp. Its optional shallow
jump practice sits north rather than on the direct south descent. B's +6 shelf / I3 is lateral at
(-22,-31,+6); its I2 is on the east switchback. C's I1/I3 courts are laterally offset to keep them clear
of bridge ramp feet; its west north-bank link climbs through camp instead of crossing under hills.
The C west summit is twelve studs wide; its east summit twenty-four. These are study adaptations,
not a claim of exact blueprint fidelity. If Zion picks one, reconcile its route graph before gameplay integration.

Static sampled body / hat audit retained A4/B5/C1 small intersections at ramp/recovery joins.
No sampled centre-line intersection remained in the main routes. Sampling is discrete, body width4,
hat width11 at one height; it cannot prove real character, cargo, hat or NPC traversal.
Every retained flag is in collision-audit.json. Actual walks, optional jumps and two-way NPC paths are UNKNOWN.
One continuous land model per study; no dedicated hide spots or mandatory bridge. Keeper is cosmetic.

## Lessons

1. When ramps meet solid terraces, sweep the route volume because nominal width and slope can still hide a blocked lane.
2. When pictures are required, keep offline proxies explicitly labelled because a render cannot substitute for Studio evidence.
3. When a bridge is the dramatic route, preserve walkable flanks because forced convergence removes the escape choice.
