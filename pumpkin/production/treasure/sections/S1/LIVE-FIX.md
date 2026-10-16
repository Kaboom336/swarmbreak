S1 live support fix

Root cause: Arena passes Config's Meadow origin (0,76,-360) through Loader to Builder. Builder previously translated floors immediately, while Section1.build and ground() used local x/z and required top Y in [-3,1]. Thus the first BedSoil footprint had no eligible live floors. The old S1 audit built only at Vector3.zero, hiding this mismatch. Names, tags and the 0.15-stud level tolerance were not changed.

Builder now dresses in island-local coordinates, translates all parts once, records MeadowOrigin, then parents the model. Late Section1 kit support samples normalize floor frames using that origin and kit spawns translate back to world space. Existing Section1 pcall/warn protection now covers Outsmart, Section<number> modules and modules marked MeadowDressing. KitSwap's late S1 call also has a guard.

Index uses a horizontal UIListLayout with a 34-pixel icon slot, 8-pixel gap and separate 68-pixel caption, inside 10-pixel horizontal padding. The slot contains the rotated 24-pixel gem's full visual bounds.

Artifact: slice-v2/prototype/guardian-greybox.rbxl. Backup: guardian-greybox.pre-s1live.rbxl in the same directory, byte-verified before Rojo. Only Builder, Section1, KitSwap and TreasureCoreHud sources are mounted; saved Workspace and unrelated sources (including existing tests) are preserved. No commit.

Regression command: lune run treasure/sections/S1/live-fix.luau (requires the backup and live-fix-rojo.rbxl). Replays the saved pre-fix failure at the real origin; builds from the actual mounted Data/Fix1Art/Fix2Routes/Polish sources at zero and live origins; checks full-footprint S1 support, late kit frames, translated part parity, physical geometry/tags and injected cosmetic failures. Kit mesh loading uses a placement stub. All saved scripts compile at O0/O1/O2. See LIVE-FIX-AUDIT.json. Studio play, UI visual layout and actual kit loading remain UNKNOWN.

Lessons: When auditing local placement, run the actual builder at the production origin because zero-origin proofs hide coordinate bugs. When adding optional dressing, use the guarded section contract because a cosmetic error must leave the island available.

Process scope: reused inspected project code and existing Lune/Rojo tooling; no new dependency or asset. The exact Keystone Roblox Process Playbook was not found in the available local files. This is a targeted regression repair, with no art-direction change or browser work.
