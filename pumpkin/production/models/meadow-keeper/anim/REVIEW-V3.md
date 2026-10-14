# V3 independent blind review and polish

CHECKED: actual approved-mesh rendered strips and ordered motion samples. Two independent critics: one blind motion critic and one gameplay code critic. No owner acceptance, no current best-in-class reference playback, no Studio test. The motion critic was shown neutral IDs and the five takeaways, without recipe mapping; picks were recorded before revealing it. This is a blind preference judgment, not a statistical experiment.

| Motion | Blind pair / winner | Initial score | Post-polish score |
|---|---|---:|---:|
| idle | Q / M → Q (recipe 0) | 7 | 7 |
| chase | V / J → J (recipe 1) | 7 | 7 |
| lob | D / X → X (recipe 1) | 6 | 7 |
| fan | H / B → B (recipe 1) | 7 | 7 |
| slam | N / S → S (recipe 1) | 6 | 8 |

Scores /10 are subjective offline judgments. `variants-v3.json` preserves both recipes; `preview/variants-v3/_pairs.jpg` preserves blind evidence. `author-v3.py --final 0,1,1,1,1` emits winners plus polish for apply_patch; it does not write source files. Sources were synchronized with apply_patch. JSON/Luau clip parity is checked by verify.luau.

Polish: lob release moves farther outward; fan releases low across the waist with an outward rigid-arm accent; chase has deeper alternating contact compression; slam has a distinct -1.15-stud landing compression at 0.800s, delayed opposing hat tilt and slower recovery. Live bounded head yaw follows the target. No mesh deformation or literal smear mesh: translated fast rigid poses provide the smear surrogate. Fists are articulated mittens, not finger animation.

Final critic inspected `_motion-v3.jpg`, attack strips and `_sheet-v3.jpg`: calm idle, clear opposing chase limbs, improved lob anticipation/clearance, broad low fan sweep, stronger slam jump/landing/recovery. Remaining weaknesses: chase contact weight, subtle idle, visually busy fan props. It did **not** play GIFs; smoothness, perceived velocity, foot skating and secondary timing in playback remain unverified. Ordered stills and exact key strips are evidence, not live gameplay footage. The geometry tests are implementer-run, not independently reproduced by the motion critic.

Gameplay critic: initial 7/10; final 8/10 static judgment after fixing landing cover classification and deriving lanes from the same release socket. Human balance UNKNOWN. The close-jump selection suggestion was applied: FanHeight only overrides fan selection, not close slam. Predicted fan landings over higher terrain are rejected, preserving the checked flight envelope.

CHECKED geometry: 201 pose samples per new clip with -0.45/0/+0.45rad live head yaw; conservative glove spheres and held spheres outside posed Head/Hat section AABBs. Lob flight tested at distances 12/24/56/72 and landing elevations -8/0/8/16; fan flight at 12/24/32/50 and -1.5/0/1.5, each fan direction and acorn cap included. Smallest conservative fan flight margin ~0.068 studs; **Studio clearance and camera projections still require inspection**. These sampled conservative bounds do not prove unsampled motion or gameplay physics.

GIFs are generated from ordered render samples at 16 fps, with exact count limits to exclude stale prior frames. Offline renders show the same clip sampler/hierarchy and tuned new flight curves toward an illustrative stationary 24-stud target. Gameplay red/amber tells are illustrated in `ATTACK-storyboard.jpg`; that storyboard is a schematic, not a Studio screenshot. Legacy throw remains only for compatibility/offline historic comparisons; production Keeper selects lob/fan/slam.

Lessons:
- When flight begins at an animated hand, check the whole arc and secondary props because a clear release frame alone can still cross the hat later.
- When a landing collision is near the aim point, require a floor surface and upward normal because nearby cover must still stop the attack.
- When landing compression has its own strong pose, impact reads clearly even in a still sequence.
