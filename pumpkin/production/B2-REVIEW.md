# B2 review: commit d69323f (economy + first session)

Read-only review against `b2-task.md`, LAUNCH-PLAN §2/§3/SEG3, AUDIT-GAMEPLAY §5.
Line numbers are the files at d69323f. SRV = `pumpkin/giant/src/ServerScriptService/Patch.server.luau`,
CLI = `.../StarterPlayerScripts/Patch.client.luau`, CFG = `.../ReplicatedStorage/PatchConfig.luau`.

Re-ran here: compile-check OK (all 3), `selene src` 0 errors, `lune run scene/econ-sim.luau` prints OK.
Arrivals Z2-Z7: 2.98 / 9.57 / 15.93 / 27.88 / 47.17 / 71.90 min. First hatch (modelled) 21 s.
Farm share: 19% (min 2), 54% (min 4), then 25-47%. Scythe cost / earnings: 12-29 s.

## High

**H1. 4x3 slot re-layout leaves padlocks and rims behind.** SRV 8022-8049, 2223-2250, 9321.
At server start, `slotLook(patch, 8)` builds anchored `SlotLock` padlocks on plots 9-10 at the old
2x5 positions. The first owner's `Progress.arrive` then moves the Plot parts (`SlotGeometry`). The
anchored padlock parts are not welded, and they are not rebuilt because the plot is still locked,
so they float over the wrong spots. The 10 `DiscRim` parts (Lobby.luau:143) never move either, so
every owned pen shows 10 orphan rims plus displaced discs. Unowned pens keep the old layout until
someone claims them.
Fix: run the re-layout once per patch at startup, before the first `slotLook` (do-block ~9319).
Move each rim with its plot (match the nearest rim before moving), or destroy the rims. Destroy any
existing `SlotLock` after moving so `slotLook` rebuilds it.

**H2. Top-level local headroom (client).** Counted declared names: SRV 160/175 (matches the
report), CLI **163/175** (only 12 left). Batches 3, 5, 6 and 7 are mostly client UI. One careless
batch will break Studio compile.
Fix: before batch 3, pack client top-level locals into tables (for example, fold the forward
declarations and UI handles into `HUD`/`ZoneView`-style tables). Add a count assert to
compile-check that fails above about 165.

## Medium

**M1. Carry is now permanently 2, while a nest holds 3.** CFG 635 (`Stack ... max = 1, cut = true`),
SRV 272, SRV 5960 (buy rejects `cut`). AUDIT intent: "Carry 3 = one nest", so Stack lvl 1 stays
reachable. With `cut`, new players stay at `BaseCarry 2`, while old saves with Up_Stack >= 1 keep 3.
Fix: set `BaseCarry = 3` and leave Stack cut and hidden (and clamp `carryCapacity` to 3), or drop
`cut` and keep only the hidden card.

**M2. Zone 1 first-touch farming takes 8 hits.** CFG ~1124/1140: `zoneTools[1] = 2` makes
Zone1 hp = 15 x 2.5 = 37.5. The new tutorial forces "Smash 50 candy" (step 3) with the Rusty 5-dmg
scythe before Iron: 8 swings per pumpkin, about 30 s of swinging. The old hp was 10, so 2 hits.
The hp is also fractional (37.5 / 22.5 shows in the bar).
Fix: `zoneTools[1] = 1` (hp 12.5 -> Rusty 3 hits, Iron 1 hit, a clear upgrade), and
`math.ceil` every hp. Re-run the sim.

**M3. Auto-replace can downgrade.** SRV 3086-3106. The swap replaces the weakest pet even when the
carried pumpkin earns less. The commit also removed the `income > weakest` guard from the sim.
Scenario: a full pen of Rares, the player delivers a nest Orange, and a Rare is gone for its 300 s
value.
Fix: if `incomeOf(top) <= incomeOf(weakest)`, keep the pen and hint "Sell it at the Witch".
The payout itself is correct (see OK list).

**M4. A laggy hold-E can fail silently.** SRV 4330-4353. The client hold is 0.6 s, but the server
needs 0.55 s between the HoldBegan and Triggered arrivals. Jitter (a delayed HoldBegan) gives
< 0.55 s, so the prompt completes and nothing happens, with no hint. The `holds[player]` entry
also leaks for players who leave mid-hold.
Fix: set the threshold to about 0.3 s (the price is the real gate), add a hint on reject, and
clear `holds` on PlayerRemoving.

**M5. Stale copy that contradicts the cut rules.**
- CLI 783: the toast "Midnight in 5s... / ALL PUMPKINS RESET!" fires every 2.5 min.
- CLI 3207-3217: the banner "ALL PUMPKINS RESET!" reads as loss. Ruling B13: a
  "Nests restocked!" toast.
- CLI 3224: "Nests restocked!" fires when Midnight ends, although the refill happens when it
  starts. It is gated on `PlayerSteal`, so new players never see it.
- CLI 1821: "New upgrade in the Shop: Lucky Swing!" still fires at 1800 s, but Lucky is cut.
- CLI 1822 / 3948 / 6533: "Blood Moon" / "King Night" vs "King Fight" (A11).
- CFG 828: the GhostBounty skill text "x2 ghost candy" (Zone 7 only, low).

Ghost, raid and Purge texts are otherwise gone or unreachable. The Purge announces at SRV 9202
and 9291 sit behind `Purge.start`/`tick` early returns.

**M6. JOIN RAID removed with no replacement.** CLI 6463-6480. The comment says "entry is the
throne ring", but no ring exists (grep). The `KingJoin` remote is still live (SRV 8657). This was
out of scope for B2. Players deep in zones lose the quick route to the King.
Fix: restore the button gated by `unlocked("King")`, or build the ring. Correct the comment.

**M7. Robux candy packs rescaled about 8x without a ruling.** SRV 400 / 7800: `orderBase` is now
total pen income x 60 (it was best-type income x 60). So CandySmall = 30 min and CandyBig = 3.3 h
of full income.
Fix: confirm this is intended, or keep `productCandy` on the old base.

## Low

- **L1** SRV 846-861: v3 order saves skip their old v3->v4 map `{1,3,3,2,5}` and go straight
  through the v4->v5 map, so they land on the wrong step. Only test saves are affected. Fix: chain
  the maps when `v == 3` (and for older saves).
- **L2** SRV 805-812: the reward is recomputed at completion, so the paid value differs from the
  dealt/displayed one. `def` is unguarded: if `RotatingOrders` shrinks, `def.b` errors inside
  `track`. Fix: `if def then`.
- **L3** CLI 6396-6407: the gate bar's Heartbeat calls `ZoneView.gateCost`, which JSON-decodes
  `ZoneProgress` every frame. The teleport/dash Heartbeat does the same through `ZoneView.has`.
  Fix: throttle to 0.25 s or cache on attribute change.
- **L4** SRV 3860: the initial wild HP label is `short(seed.hp)` (Orange = 20), not the zone hp.
  This is pre-existing, but now very wrong (Zone 7 = 5500).
- **L5** CLI ~4783: the tutorial hard-codes "150 candy". Use `Config.Tools[2].cost`.
- **L6** econ-sim: the sim pays `DailyCandy` at t = 1, but `claimDaily` is blocked until the
  tutorial is done (SRV 7551), and that now means after gate 1. This is +100 of 2,500, small.
- **L7** SRV 287-299: the badge attribute is set before `AwardBadge`. A non-throwing `false`
  return never retries this session. This is harmless, since BadgeService dedupes.
- **L8** CFG 1140: Zones 6 and 7 both have hp 5500 (`zoneTools` 7,7), so no scythe tier exists
  for Zone 7. Acceptable, noted.

## Checked OK

- **AUDIT §5 values:** the candy ladder 8...150000, gateCosts {2500,...,540000000},
  arrivalMinutes, farmSeconds 1800, rarityWeights {0,70,27,3}, pity 5, Raid.grace 1e9,
  CarveNewSeconds 2, Stack.max 1, Lucky.cut, Dash.tier 3 and Unlocks.King 600 are all applied.
  DayLength 150, SpookyLength 90 and `Purge.minutes = {}` follow the rulings. There is no
  `baseCandy`.
- **Purge off at every entry:** `nextSlot` returns nil, and `start` and `tick` return early.
  The admin "purge" returns a reason instead of crashing.
- **Raids off:** `raidCheck` returns 0, and ghost/rescue orders are filtered. The "Go home" /
  "Lock your Base" texts are removed, and the sign-post LOCK prompt only shows during a Purge.
- **Swap payout:** it pays only the replaced pet's own `WitchSellSeconds` value (Bought = 30 s),
  times the Index row bonus and sellMult, the same as the stall. No value comes from the carried
  pumpkin, and the hatch reveal plays through `ForceReveal`. The SEG3 exploit is closed.
- **Badges:** they are ID-0 guarded, run in pcall inside task.spawn, are deduped per session, and
  BadgeService dedupes across sessions. There is no double reward.
- **Gate bypass:** this is the only `unlockZone` caller. The commit added a server check that the
  previous zone is owned, and price/discount are computed on the server. No touch path exists.
- **Server-gated features:** teleport needs Zone2, dash checks `bestTool.order`, fuse needs Zone3,
  and buyUpgrade rejects `cut`. DoubleCandy doubles smash candy on the server.
- **Removed names:** BigStack, `BigStackCarry`, `Pass_BigStack` and `bestUnlocked` have no
  references left in src or scene.
- **Save compatibility:** `slots` is clamped to 8..12, so old 6-slot saves become 8. `placed` is
  keyed by plot Index, so old pets at 1-6 (or 1-8 / 1-10) land in valid slots. `arrive` runs
  before `restore`. No saved field was renamed, and `KingCrates` comes from the existing `crates`.
- **Geometry fit:** soil 36x30 with a 4x3 grid at an 8-stud step and 6.6 discs spans X ±15.3 and
  Z ±11.3, so the grid fits.
- **King pity:** the label `pity - crates % pity` matches the server rule `crates % pity == 0`.
  `KingCrates` is refreshed every second through `publish`, and the weight-0 tier is skipped
  correctly.
