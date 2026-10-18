# Blind engineer critic — difficulty revision

2026-10-18. Independent simulated engineering lens. Read only DIFFICULTY-BLIND-PACK.md and current source named below; no other critics or recommendation. All design judgments and scores INFERRED. Source observations CHECKED by reading; no tests, Studio Play, place edits or code mutations.

| Anonymous design | Overall /10 | Difficulty quality /10 |
|---|---:|---:|
| X | 8 | 8 |
| Y | 6 | 6 |
| Z | 6 | 7 |

**Winner X (INFERRED).** Its long visible lane makes committed threats, returning cargo and home direction easiest to reason about. A maximum of three demands per encounter plus serial waves can create hard decisions without unreadable overlap. Y adds hidden corners and travel cost before adding skill. Z can concentrate interesting timing, but spokes, shared exits and short retreat introduce more scheduling and safe-boundary exploits. These scores rate a specification, not measured fun or success rates.

## CHECKED reuse and gaps

- `slice-v2/prototype/LootRules.luau:4,20,62` holds one active provisional item and asserts singleton conservation. Fifteen nests require a deliberate multi-zone coordinator with globally unique IDs and per-player single-cargo enforcement, not fifteen independent copies sharing actor state.
- `LootRules.luau:68,84,195,212` already represents deadline expiry, refill, first-steal deadline and secure tie checks. Keep the original cargo identity/deadline through recovery, handoff and guardian transitions. `Greybox.server.luau:553` has a securePending phase; do not refill the nest before durable award resolution.
- `prototype/core/Domain.luau:101,107,128,139` has one pending award, cap checks, and rarity-based income rather than zone-valued income. A full pen blocks the next award; transactional replacement and zone/rarity migration are critical before claiming 15-zone progression works. `prototype/core/Config.luau:9` sets MaxPets=8.
- `prototype/core/Profiles.luau:41-80` waits for matching revision/operation persistence acknowledgment; `Profiles.luau:82-94` copies and validates mutation data. Reuse this transaction boundary for permits, boots, replacement and durable bank progression. Do not mark a zone banked at physical safe-line crossing alone.
- `slice-v2/prototype/GreyboxConfig.luau:20-21` fixes empty/carry speeds at 16/13.5. Gear scaling and all movement validation/cinematics must use one server-owned movement profile. A 41.5 carry speed and dash are design proposals, not verified motion tuning.
- `slice-v2/prototype/KeeperAttacks.luau:13,27` uses 0.5 DashTell and 0.80 SlamLand; `KeeperAttacks.luau:98` describes a committed straight charge without homing. Raise the actual full tell to the promised minimum, including each collateral victim; a comment or UI flash does not establish fair warning.
- `prototype/meadow-v4/RaidSlice.luau:5,182,187,202,233` has a 1.5-second tell, arena-level raid state and item association. The global four-runner budget, serial waves, per-carrier reservation and guardian handoff are new coordination work.
- `slice-v2/prototype/Greybox.server.luau:46-48,964` already disables player-player collisions. But `Greybox.server.luau:975-978` still creates a Bump prompt, and `LootRules.luau:103,189` accepts Bump. Pacifist requires removing server eligibility and all player-forced-drop paths, not merely hiding the prompt.
- `GreyboxConfig.luau:58` has ShieldSeconds=12; `LootRules.luau:200-201` gives a first-steal shield. That existing protection differs from the proposed one guardian-drop block. Resolve the policy explicitly before tuning new-player success.

## Strongest objection and concrete correction (INFERRED)

The global raid cap can erase the very encounter used to make a zone hard: eight carriers compete for two squad pairs, and saturated deployments are skipped. Collision-free rivals do not replace that difficulty. Do not queue unseen late waves or expand budgets silently. Make every zone's mandatory decision work with its Keeper/terrain alone, reserve scarce raid episodes before telegraphing, and treat a skipped raid as a recorded easier variant. Measure success separately for full versus reduced-threat variants and solo versus eight-player sessions. The 10% zone-15 target cannot be promised from the table.

Other implementation blockers before first playable:

1. Specify permit policy on both initial Steal and loose-cargo Grab. Otherwise an ineligible friend can recover a deep-zone drop and farm the higher income without its intended access gate. Choose and document whether this is allowed; if prohibited, server-check eligible zone at Grab completion and show the reason before holding.
2. Make retry authoritative: clear cargo/holds/commitments, then restore only empty-handed to a safe staging pad. Falling, reset, disconnect and handoff must never teleport loot, refresh shield, regenerate a decoy or reset a deadline. No safe-pad interception of a dropped item.
3. Require a visible, timed decision on the walking bypass at maximum legal speed and with each allowed gear combination. A wider route that bypasses all new mechanics turns zone8+ into travel. Conversely, do not make starter-speed deadline expiry the only reason it is difficult.
4. Guardian handoff must transfer pursuit ownership only after previous commitments/recovery clear; threats from unrelated cargo must not hit another carrier without that carrier's full cue and decision window. Global caps alone do not provide fairness.
5. Separate technical/queue failures from learning failures. A failed save, absent item, missed device input or hidden cue must never be counted toward the proposed novice failure targets.

## Minimum evidence gate (INFERRED)

Build X zones1–3 only, then attempt a zone8 encounter in isolation before producing the rest. Future checks should cover duplicate/expired IDs; permit and Grab policy; double purchases; full pen replacement; secure-ack failure/retry; reset with cargo; dash through safe boundary; eight carriers competing for raid reservations; and mobile cue visibility. Existing tests were read selectively as source search context but were not run and establish no current result here.

Lesson: when difficulty depends on a shared actor budget, validate the busy-server variant because scarcity can remove the challenge. When increasing zone rewards, migrate identity and capacity transactions first because source income currently depends on rarity alone.
