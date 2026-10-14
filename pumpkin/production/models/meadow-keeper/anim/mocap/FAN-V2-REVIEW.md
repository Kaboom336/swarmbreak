# Fan blend attempt — 2026-10-13

Decision: retain current hand-keyed fan. Two independent blind critics scored Punch_Cross + Walk_Loop **6.2 / 5** (mean **5.6**) and Sword_Attack + Walk_Loop **5.7 / 6** (mean **5.85**). Neither exceeds the user's **6/10** incumbent gate. Their fresh baseline scores were **5 / 4** (mean **4.5**); candidates beat this fresh comparison but fail the requested absolute gate. Scores are subjective, not measurements. Critics disagreed on which blend won; no consensus winner claimed.

## What was checked

- Read existing retargeting, geometry, render, clip and runtime spawn code. Standard GLB is animation data only; no vendor code executed or modified. Inspected existing CC0 licence. Capture method UNKNOWN; this is a keyframed library blend, not verified optical mocap.
- Source clips contain forward arm extension and gait mechanics: Punch_Cross extension phase .44; Sword_Attack .28; Walk_Loop provides hips/legs. Directions sampled from shoulders to hands and thighs to feet collapse articulated source motion onto seven rigid visual parts. Existing 16-joint schema is retained with elbow, wrist, knee, ankle and pelvis rotations zero in both new variants. Rig, geometry and maps were not edited.
- Blend keeps 35% captured arm direction after stylised hand-path compression, gait leg rotations, captured chest motion plus larger loaded twist, a .52–.62 acceleration, .62–.84 cross-body finish and bounded recovery. These are authored adaptations, not a nonexistent Standard throw clip.
- Existing Release marker stays .620s. Runtime KeeperAttacks code spawns three acorns in one release branch at -16 / 0 / +16 degrees. Matched proofs show three simultaneous spawns from the .620 sampled right-hand socket. Preview trajectories are illustrative; gameplay was not modified.
- Both variants have 97+ baked frames plus exact marker/action keys. Dense 120Hz runtime-style quaternion interpolation passes floor checks: M minimum sole Y .01135, Q .01172 studs. Neither is collision certified: sampled forearm/hand-body contact pairs M **138**, Q **97**, baseline **241**. Attachment/cap contact and penetration depth are not separated by this test. Inspect fan-v2-check.json for timestamps.
- All 24fps proof frames and nine-pose strips inspected. Two fresh critics received only anonymous M/Q/T images, with no code, mapping, prior scores or other critic output. They independently inspected all six pose/motion sheets. Still sheets support pose judging; exact perceived speed remains uncertain. All three GIFs decode with ffmpeg. Studio, device playback, terrain and owner acceptance UNKNOWN.
- Production clips.json, Clips.luau and isolated Studio package remain untouched. Candidate data and proof images are diagnostic artifacts only. No source installation, map edits, commit, publish or accounts. Hashes are in fan-v2-result.json.

## Blind findings

Critic 1: M is the most coherent load/sweep/finish but has passive feet and insufficient acceleration/braking separation. Q has strongest anticipation but folds too deeply and hides the action under the hat. T reads as dispensing rather than throwing.

Critic 2: Q has the clearest windup and transfer but reads as a stumble/bow. M reads as a low push. T generates the least force. None holds a strong across-body finish.

Comparison bar: the actual current hand-keyed Keeper fan is the inspected reference and requested 6/10 gate. Earlier notes name Vesteria Ethera / World // Zero as aspirational references; their current footage was not inspected, so no parity claim. Local Pumpkin PLAYBOOK.md was read; exact Keystone Roblox Process Playbook was not available locally or in exposed tools.

## Files

preview/mocap/fan-v2.gif shows the retained hand-keyed fan with the corrected three-acorn proof. fan-v2-comparison.jpg labels baseline and both rejected blends. Anonymous sheets/GIFs and fan-v2-candidates.json preserve evidence; they are not active animations.

## Lessons

1. When blending sword motion onto a short rigid rig, bound chest rotation, because source follow-through can hide the arm under the hat.
2. When judging a throw, carry the mitten visibly past the opposite hip and hold the finish, because a small forward push reads as dispensing.
3. When a task supplies an incumbent score, keep that gate separate from a fresh blind score, because judge calibration can shift.
