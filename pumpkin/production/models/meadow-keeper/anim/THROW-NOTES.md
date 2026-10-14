# Throw reference and judging contract

2026-10-13 update: [CC0 library retarget review](mocap/REVIEW.md) supersedes the old lob socket/pose recipe below.
Lob now lifts the cylindrical log fully overhead through a constrained two-hand hybrid. Release remains .620.
Fan retains the blind-selected hand-keyed animation. No dedicated throw exists in the Standard pack.

Owner-reported: lob, fan and other throws look unnatural. CHECKED: existing rig, clips, renderer and authoritative release code. Reuse: project-owned approved mesh and local tools; no third-party code/art imported and no new licence dependency.

Reference bar: coordinated baseball throwing mechanics, rather than an arm-only game animation. Real-world motion knowledge is the basis for the six pose sketches; these are original schematic drawings, not traced footage. Read reference: [Pitching mechanics, revisited](https://pmc.ncbi.nlm.nih.gov/articles/PMC3811736/) describes lower-body initiation and a pelvis-first stride. No video was watched or frame-by-frame motion capture measured. Heavy two-hand overhead and low sidearm adaptations below are authored inference, not baseball technique claims. Shot-put is a one-hand push; it is not the two-hand lob reference.

## Six key poses, right-handed throw, target forward

1. **Load / rear support:** settle mass onto right/rear foot; bend knees; left hand indicates target, right hand gathers. Eyes stay on target. Heavy version gathers in both hands after the indication.
2. **Stride / separation:** left foot steps toward target and braces. Pelvis begins opening while chest and throwing hand remain wound back. The support arm starts folding inward.
3. **Drive / elbow lead:** rear foot pushes, hips lead chest, shoulder carries the bent elbow forward while the hand trails. Heavy version extends both knees and lifts both hands above shoulder level in front of the hat.
4. **Release / whip:** chest catches hips; elbow extends and mitten wrist snaps on the exact projectile spawn frame. Heavy version hops forward and drives both hands overhead together; fan uses one low sidearm sweep. Head counter-turns independently.
5. **Decelerate / across:** throwing arm crosses the front of the body; torso folds forward over the lead leg. Rear heel lifts and foot drags toward recovery. Heavy version drops both arms forward. Hat and relaxed arm lag 1–2 frames.
6. **Recover / balance:** ease out into a braced stance, bring rear foot under mass, restore neutral shoulders and settle the hat. Return to the existing idle pose rather than a new rest position.

## Timing and safeguards

Release stays at 0.620 seconds for lob, fan and legacy throw. Clips use 1.10 seconds: load/stride to 0.495 (~45%), drive/release to 0.620 (~11%), deceleration/recovery to 1.10 (~44%). Heavy lob moves through a deeper slower gather within the same authoritative windup; extending the server attack warning is outside this animation fix. Gameplay's existing flight/impact deadlines stay unchanged. Offline render samples include an exact 0.620 pose in addition to regular 30 fps GIF frames.

Use a separate pelvis, elbows, wrists, knees and ankles; no translated shoulder detachment. Neutral geometry must remain unchanged. Head counter-rotation cancels pelvis/chest turn and tilt. Heavy heave stays on committed forward aim to keep the broad hat out of the raised mittens. Generated reference sketches show pose relationships, not anatomical measurements. The boulder appears at .20 after the gathering motion, has a 5.4-stud visual diameter, and retains the existing server collision envelope.

## Blind judge rubric

Four anonymized candidates, recipe mapping withheld from independent critics. Judge six criteria, each /10: rear-to-lead weight transfer; hip/chest/shoulder/elbow/hand ordering; attack-specific silhouette; release/follow-through; head/hat overlap; recovery/contact. Report their mean as a subjective visual score. Judge strips and animated frame contact sheets; offline poses cannot prove Studio contact, runtime performance or owner acceptance. Keep the winner per attack and replace legacy throw with the winning one-hand mechanics.

## Lessons

- When a rigid rig cannot bend at the elbow, add a real joint before polishing timing, because shoulder rotation alone cannot show a throwing chain.
- When a large prop shares a release deadline, author the body and both hand supports around that deadline, because cosmetic timing changes can desynchronize gameplay.
