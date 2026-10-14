# Animation acceptance record

## Reviewer-directed exaggeration follow-up / 2026-10-13

Owner-supplied verdict: THROW too compact, CHASE stiff, WARN too restrained, RETURN close to idle. Reused the approved model, renderer, driver and local tools; no new dependencies or assets. Supplied compare.jpg v2 meadow throw and title-card lunge are the directly inspected pose benchmark. No new independent reviewer or top-game parity claim.

Throw now loads the arm high behind the shoulder, twists into a separated stance, lunges through the unchanged 0.620s release, overshoots into a low follow-through and settles. Chase uses a deep forward lean, opposing broad arm pumps, longer boot arcs, torso counter-rotation and a small two-beat bob. Warn has a forward lean and larger separated fist accents. Return is a slumped annoyed trudge with heavier sway, hanging arms and downward head tilt.

Evidence: old/new same-camera throw/chase comparison beside the supplied references, regenerated full sheet, sampled-motion GIFs, real-driver keyframe/loop/release tests and package source checks. Studio and actual travel/foot contact remain UNKNOWN. Historical critic verdicts below describe earlier passes, not this revision.

Lessons: When a high arm still overlaps the brim, move its arc outward and inspect intermediate frames because a keyframe alone misses crossings. When a chase torso leans deeply, counter-rotate the legs because inherited rotation otherwise hides the stride. When a return walk resembles idle, give it a persistent slumped posture because timing alone cannot establish its mood.

Checked GDD guardian/throw contract, HANDOFF rules, approved JSON/Blender build/export code, seven rig pivots, supplied compare.jpg, current Roblox API references and local PLAYBOOK. Model approval is owner-reported. No current Pet Simulator / Grow a Garden gameplay video was watched; those are the owner-stated quality bar, not claimed verified benchmarks.

Two independent agents saw only blind A-H strips and supplied compare.jpg. They did not read animation names, code, or labelled sheets. Both inferred all eight actions, with ambiguity between the two walks. Still strips do not establish continuous playback quality. No numerical quality scores were invented.

| Blind ID / actual clip | What read | Critic gaps |
|---|---|---|
| A / idle | Calm look-around; stable silhouette | Small changes; appropriate idle restraint |
| B / patrol | Alternating walk feet | More arm/torso counter-motion would add weight |
| C / warn | Alert, fist gesture | First pass fist foreshortened near chest/face; narrow stance |
| D / chase | Forward arm, lifted boot, urgent gait | Stronger forward torso lean could add urgency |
| E / throw | Prop and loading imply throw | Both critics: hand crowded face, follow-through crossed hat, unclear direction |
| F / stun | Head tilt, dip and asymmetry read impact | No continuous timing verdict possible |
| G / celebrate | Airborne hop and landing clearest full action | Raised hands overlap hat at peak |
| H / return | Slower walk | Close to idle; weaker swing/weight shift; distinction from patrol uncertain |

Critic 1 ranked E/H weakest. Critic 2 ranked E/C weakest. Root resolved the tie to E/C because the attack and warning reference poses are explicit acceptance targets. The return walk's subtlety remains a gap, not an unrecorded pass.

## Single correction pass

- Throw: widened stance, raised loading hand beyond the shoulder, increased wind-up diagonal, moved release outward, and lowered cross-body follow-through with rear-heel lift. Release timing unchanged at 0.620s.
- Warn: opened raised fist diagonally, widened stance, added torso counter-lean, kept a separate forward point before two high fist accents.
- All eight strips re-rendered from synchronized keyframes. First-pass strips remain in preview/before. Final sheet: preview/_sheet.jpg. Direct supplied-reference comparison: preview/_reference-compare.jpg.

Independent recheck: **both improved**. Warn now approaches the supplied diagonal, but fist still touches the brim silhouette and the intermediate point is less clear. Throw now reads as a throw instead of salute, but release remains compact near shoulder and has less forward reach/weight commitment than the reference. No claim of top-game parity or owner acceptance.

## Verification

Offline Lune executed the actual Animator module using Lune CFrames and service/signal stubs: all authored keyframes, loop seams, release crossing a long frame, exactly-once release/completion, speed changes, cancellation, loop repetition and reentrant transitions. Five Luau sources compile. A floating-point residual loop hang was found and fixed with a bounded epsilon. XML package deserialization and source freshness are checked separately.

Blender rendered the actual approved geometry, using the same hierarchy, XYZ rotation order, quaternion interpolation and easing. Selected seven poses per clip are inspected. This is visual pose proof, not Studio capture or live physics proof. BindableEvent mocks are synchronous; production release consumers receive an immutable forward-kinematic CFrame snapshot to handle deferred Roblox signals.

**UNKNOWN / pending:** Studio Play, exact rendered-hand/socket correspondence in the live engine, mesh creation permissions/memory, real-device readability, actual movement/feet on hills, animation feel and owner acceptance. No foot IK, literal mesh deformation, fingers/elbows, audio or gameplay hooks. The pose language compresses/extends the rigid rig; it does not stretch vertices. No changes to map files, guardian-greybox or approved Blender sources; no commit/upload/publication.

## Lessons

- When a blocky arm cannot bend, separate the hand from the face/hat because silhouette carries intent at gameplay scale.
- When release events can be deferred, send an immutable forward-kinematic socket snapshot because drawn-part transforms can lag until physics.
- When looping a floating-point timeline, discard tiny residual time because a remainder can be too small to advance the current timestamp.
