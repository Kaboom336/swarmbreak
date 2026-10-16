# Two blind player-camera reviews

Round 2 widened-scope work is recorded separately in [CRITIC-R2.md](CRITIC-R2.md), with two additional blind reviews, corrections and explicit remaining gaps. The record below belongs to round 1.

Independent image-only agent; no implementation, spec, progress or numeric scores supplied. Compared the two player views with local REFS and TARGET. This is visual criticism, not live acceptance.

`REFS-review.jpg` preserves the board actually supplied to both critics. Final `REFS.jpg` tightens its crops and substitutes a clearer Grow a Garden fruit-tree image from the same local reference set. Critic outcomes were not revised after that board cleanup.

Round 1: `iteration0-walk.png`, `iteration0-mouth.png`. Worst gap: pale blocks and a dark void dominate instead of the timber destination. Secondary: low crossing beam, bright crystals, thin vines, dim sign. Asked for a coherent warm frame, paired lights, route visibility and less projecting stone.

Correction 1: moved timber presentation onto exposed stone faces, connected it with wall brackets, made grouped ivy, moved lanterns forward and added their actual light metadata to the offline renderer. Contact iterations rejected a south-face placement inside the hill; retained face-mounted placement in `review1.json`, `review1-walk.png`, `review1-mouth.png`. These review images precede a header-depth-only contact fix. Contact defects were not waived.

Round 2: `review1-walk.png`, `review1-mouth.png`. Worst gap: the route still disappears into darkness, with pale walls/crystals stronger than the entrance. Timber remains cropped/obscured; old low crossbeam cuts the passage. Asked for an illuminated threshold, clear route/endpoint and better framing.

Correction 2: lowered the new header/sign and lanterns into the locked player frames, shifted the left support along the exposed wall into both frustums, increased actual runtime entrance light range/brightness, and removed explicitly named superseded nonphysical S1 mine trim located inside S2. The frame remains wall-mounted above the protected bait approach. Gameplay solids, lane/floor geometry and S3 remain unchanged. No cosmetic path laid over lanes and no wall solids moved. Final `after-*` evidence shows this correction.

Correction 2 refinement: the low-frame candidate in `review2a-*` still hid its posts. A camera-ray probe identified the left pale arch blocks as nonphysical `TunnelExitArchShoulderVoxel*`, rather than the retained hill solids. Removed only the nine S2-owned left mouth voxels, widened the facing timbers, added knee braces, and placed the header at Y17.5. Right S1 seam voxels and S3 interior decoration remain. Final contact audit stayed at zero failures. This further addresses the second critique; no third independent approval is claimed.

The critic's desired route/interior changes exceed this section's allowed scope. Final coverage metrics and remaining visual gaps belong in RESULT.md; neither critic issued approval. Exact owner-reported `RECOVERY -> CYAN` text was absent from inspected mounted sources and saved TextLabels. The current source-created `OutsmartExit` floating cyan cue at (-53,5,108) was removed as the corresponding mouth label, with unrelated cues preserved.
