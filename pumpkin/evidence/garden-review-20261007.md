# Magic garden independent review

## Submission 1

Build: `garden-integrated-20261007.json`, raw checks `garden-integrated-20261007-raw.txt`. SHA-256 `437FC52BBCAFEF02D18A62F805D6A11EE1CBA07F5ACDF70BA23AD0F7213FD4CB`. 120 tests, 49 syntax files, format/lint/Rojo build pass. No Studio captures.

Fresh `magic_integration_critic` and separate fresh `magic_authority_critic`, both given only criteria/artifact pointers, returned **FAIL**. Actionable findings: unvalidated character displacement can sweep ghosts for rewards; deceased/reset burst owners remain chain contributors; gamepad labels advertise keyboard controls; Data saves use permissive acquisition ownership; failed final save discards local data; character setup can duplicate death listeners.

One initial integration finding claimed ProfileSchema syntax corruption. Exact numbered readback disproved it; the critic retracted it. No repair was made for that unsupported claim.

The gameplay implementer has been assigned repairs, nearest-ready-crop selection and distinct staged spell/burst feedback. A fresh critic must review the revised submission. All runtime, multiplayer, visual, audio, mobile and fun gates remain pending.

## Repair 1

Build: `garden-repair1-integrated-20261007.json`; SHA-256 `0AD7A04CB1F213EAC719E5B6A6BBAA5BB35E2943C92AF5F001005F4EEC775BF0`. 127 tests, 50 syntax files, format/lint/Rojo pass. `garden-build-audit2-raw.txt` checks packaged gameplay/Data source against disk. `garden-repair1-source-manifest.json` identifies all source/test/build-input hashes.

Fresh `magic_fresh_authority_critic` returned **PENDING**: no actionable G4–G6 source defect, static G9 pass, runtime absent. It independently verified all 85 source manifest entries and the build hash. Fresh `magic_fresh_integration_critic` returned **FAIL G7**: the 56-pixel action buttons overlap by two pixels, their stack overlaps the HUD in a 280-pixel-high safe viewport, and session fencing stops actions without updating or terminating the client's stale active UI.

Repair 2 is limited to responsive action placement and explicit termination of an invalid live data session. Fresh review and rebuilt artifact are required. No runtime quality gate has been accepted.

## Repair 2

Build: `garden-repair2-integrated-20261007.json`; SHA-256 `6E6AC046DB3011E39B4F41517AE935BC58868D5A3E383E5211A6B5435D36C6E9`. 129 tests, 51 syntax files, lint/format/build pass. Source manifest and packaged-source audit match disk. Responsive rectangle tests cover 320×280, 568×280, 360×640, desktop and an unusually short 320×220 view; actual touch rendering remains pending.

Fresh authority critic `magic_final_authority_critic` returned **FAIL G6**: server-wide session identity allows an old Player incarnation's failed departure retry to overwrite a same-server rejoin; local reward eligibility also does not expire after failed lease renewal. The next repair is confined to unique per-load ownership and confirmed lease validity, with actual Data-module mocked race/outage tests. Runtime gates remain pending.

Fresh integration critic `magic_final_integration_critic` returned **PENDING** with no additional source defect; G7 rectangle checks passed, actual device/rendering checks remained pending. Its general persistence inspection did not establish the race found by the independent authority reviewer; the authority finding took precedence.

## Repair 3 — current playable submission

Build: `garden-repair3-integrated-20261007.json`; SHA-256 `CFF69D58158BC6BD4E947014EEC623743CF0330FBA9528B32FAEFD0B81901487`. 132 tests, 51 syntax files, format/lint/build pass. `garden-build-audit4-raw.txt` checks packaged gameplay, layout and saving modules against disk; `garden-repair3-source-manifest.json` identifies the tested inputs. `garden-desktop-20261007.json` records the matching Desktop copy.

Fresh `magic_release_authority_critic` returned **PENDING overall**, with PASS for G4–G6 source review and G9 static evidence, no actionable source defect. It independently verified every source-manifest entry and the build hash. Tests now cover unique player-incarnation ownership, old-save/new-owner races, expiry during outages, exact-owner recovery and immutable snapshots.

Fresh final integration critic `magic_package_integration_critic` returned **PENDING overall**, with static integration passing and no concrete blocking source defect. It independently verified all source hashes, the build hash, and reran the packaged-source audit. G1/G4/G6/G9 pass for static scope; G2/G3/G5/G7/G8 require direct Studio/device/presentation evidence. Separate fresh authority and integration reviews cover this same final artifact.

This submission is `implemented` and `static-pass`, with `runtime-pending` and `user-review-pending`. It is not fully accepted for gameplay/fun or release. Next action is the terminal-free [playtest route](../production/GARDEN-PLAYTEST.md), followed by harsh clip/screenshot review and fixes to the weakest observed area. No commit/publication.
