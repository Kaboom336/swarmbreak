# TARGET provenance

Built-in image_gen, precise-object-edit; inputs are `before-arrival.png` and
`before-outgoing.png`, both inspected before generation. Copied tool result to
TARGET.png. Generated art is a target only, never shipped geometry/evidence.

Exact prompt:

> Use case: precise-object-edit. Create a two-panel Crystal Cave C1 arrival art target from these two actual Roblox player-camera renders, first image top panel, second bottom panel. Preserve each camera perspective, existing level geometry, tan open walking apron, giant foreground timber sign, carts, rails, every background crystal landmark, stairs, buildings and sky exactly. Change ONLY the arrival apron outer shoulders: add two restrained connected clusters of large irregular faceted grey-blue/slate boulders at the extreme left and right foreground sides, safely outside the tan walking floor, keeping broad open middle and existing paths unblocked. Chunky Quaternius-style low poly natural boulder silhouettes, 3-4 large forms each, darker purple seams. One tiny warm lantern on a solid rocky shoulder on each side, no tall poles, no new crystals, no grass, no explosions, no new signs. Keep the camera view and framing identical to the inputs. This is a scoped environment concept target, not a full redesign. Labels only 'C1 ARRIVAL — TARGET' and 'C1 OUTGOING — TARGET'. Keep existing unrelated clutter unchanged.

Observed drift: generator widened/reframed the camera and put large masses on
the apron. Those details do not override the actual map/corridor constraints.
Built-in original:
`C:/Users/zerha/.codex/generated_images/01a148dd-7fe3-7d13-b921-fab0ed2b2087/exec-137a90cc-4b5d-4ee0-9b82-e7a356f8e5bf.png`.
