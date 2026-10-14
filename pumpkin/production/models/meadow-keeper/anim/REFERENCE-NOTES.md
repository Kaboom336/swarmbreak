# Motion reference notes — v3

Evidence: web search reached Roblox DevForum listings; full pages hit bot verification and direct MP4 download failed with network restriction. **No reference video or frame-by-frame footage was watched.** Do not turn listing snippets into visual evidence. Exact Keystone Roblox Process Playbook still unavailable; repository PLAYBOOK.md inspected, and approved rig/renderer reused without third-party imports.

Named comparison bar: Tower Defense Simulator boss attack readability (aspirational, current footage UNVIEWED), owner-approved Keeper silhouette, and stylised blocky pose timing. These are reference choices, not a claim of matching the best animation on Roblox. Public research leads: [Jespone's animation guide](https://devforum.roblox.com/t/jespones-guide-to-animations/225752), [blocky animation tutorial](https://devforum.roblox.com/t/how-to-make-low-fps-blocky-style-animation/2800541), [Mega Boss Battles showcase/system](https://devforum.roblox.com/t/4039013). No assets/code copied; showcase permission/licence not established.

Fallback: established pose-to-pose animation principles; evaluate our actual rendered frames and continuous GIFs:

1. **Silhouette before detail:** hold each attack's distinct loaded pose for at least 0.12s; keep fists outside head/hat silhouettes. Lob loads out to the right, fan coils low across the waist, slam spreads both fists outward before jumping.
2. **Anticipation vs strike:** spend most windup time loading, then travel through a fast 0.05–0.09s release accent. Use an outward translated rigid arm pose as a smear surrogate; this rig cannot deform meshes.
3. **Weight begins at the feet:** use a wide planted attack base, push torso up at takeoff, drop it into compression at slam landing, then recover slowly. Chase has alternating contact compression and lifted passing boots; actual floor contact/IK remains Studio-only.
4. **Secondary motion follows the main mass:** hat tips opposite torso acceleration and settles one key later; arms counterbalance chase and recoil after release. Secondary motion must not obscure the red/amber gameplay tell.
5. **Eyes and mechanics agree:** counter-turn head toward the committed target, add bounded live head yaw in the client, and sample projectile socket at exactly the 0.620s release pose. Slam impact shares the 0.800s landing key. No prop visible after release and no interpolated release origin.

Blind judging rubric (each /10): silhouette, anticipation/timing, weight/contact, secondary motion, gameplay synchronization. Two variants per idle/chase/lob/fan/slam. An independent critic receives anonymized paired image strips with no recipe mapping, chooses each winner, then sees continuous final evidence. The critic is blind to mapping, not to which motion category is visible. Scores are subjective offline evidence, not owner approval or playtest results.
