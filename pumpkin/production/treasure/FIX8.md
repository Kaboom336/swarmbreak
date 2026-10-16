# Fix8 — wall bait floor dip

Owner-reported LIVE after fix7: Outsmart wall bait stops with `DashStopReason="floor height"` after its endpoint-only level check passes. Studio is owned by Claude; no connected Studio tool was available here. Live acceptance remains UNKNOWN.

Inspected and reproduced offline: the authored route at local x=-73 ends near z=99. Exposed SolidMountainStone is two studs lower until z=104; start z=88 and bait z=104 are level enough to pass the old check. The geometry-driven mock reproduces a floor-height stop with the new slab removed, without injecting a collision result.

Changed:
- Outsmart builds one six-stud-wide slab, top y=0.12, z=87..109.5, meeting the existing broad cover face at z=108.92. Existing terrain, cover position, S1 props and kit skins remain. The slab is an authored lane floor with lane ID outsmart_bait. The R5BoulderFoot at (-73,4.305,113) receives the OutsmartBaitCover tag/attribute.
- Dense level validation uses the committed center lane at half-stud intervals, includes the final point 0.01 studs before the actual raycast wall face, and uses the same floor-query height as the dash. It rejects a missing tagged cover, missing floor or height variation of 0.3 studs. This runs in live OutsmartTest before the dash.
- When a floor probe would stop a dash, a second cover sweep extends only the existing 1.5-stud step tolerance. It can recognize only the tagged bait cover with a vertical contact and footing within that vertical tolerance. Safe-zone/leash stops cannot grant a stun. The normal production cover collision path, 1.55-second stun cap, one FX request and corner memory remain.

Backup: `slice-v2/prototype/guardian-greybox.pre-fix8.rbxl`, byte-verified before the first fix8 Rojo build. Rebuilt `guardian-greybox.rbxl` by mounting only Outsmart, Attacks and OutsmartTestRunner onto that backup; 71 scripts compile at O0/O1/O2, 68 unrelated sources and serialized Workspace preserved. The floor is built at runtime. No commit, publish, live sync or Studio edits.

Checks: `treasure/fix8-check.luau` uses rebuilt production parts, OBB ray casts, wedge slope clipping and swept-body bounds rather than a hardcoded wall hit. Runs actual Outsmart level validation, Arena.floor and Keeper dash at zero and (0,76,-360) origins. Covers full body-lane floor samples, original dip reproduction, a half-stud lip beyond the bait endpoint, tagged-only tolerance, exact intended cover impact, one stun/star request, repeat refusal, safe-zone and leash refusal. This is offline policy/geometry evidence, not Roblox engine collision or live suite acceptance. Cast approximations do not certify mesh collision or Humanoid movement. Evidence: FIX8-BUILD.json and FIX8-CHECK.json.

Also passed: fix7-check.luau policy (existing wall stun/FX and recovery diagnostics), and the full slice-v2/prototype/check.luau legacy suite from its required working directory, including built-source parity. All remain offline checks.

Claude: reopen the updated guardian-greybox.rbxl or sync the three source changes into the existing session, restart play so the new runtime slab is built, then rerun OutsmartTest and StudioPassAll. Capture OutsmartTestFailureJSON if red. Check that the six-stud bait lane is visually flush and the existing rock skin remains aligned.

Lesson: When validating a committed dash, sample through to the actual wall face because level endpoints can hide an intervening floor dip. When mocking casts, retain wedge geometry and world bounds because an inflated rotated box can report a false rock hit.
