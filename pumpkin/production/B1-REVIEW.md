# B1 Launch Blockers: Code Review

Target: the uncommitted diff in `C:\dev\codex-lab\b1-blockers\repo`, checked against `b1-task.md` and the LAUNCH-PLAN rulings (§2, batch 1, SEG3 addendum).
Paths are relative to `pumpkin/giant/`. Line numbers are from the current working tree.
Tool checks were rerun: compile-check OK for all 4 files, selene 0 errors / 0 warnings, econ-sim OK.

Severity: **HIGH** = data loss, exploit or broken blocker. **MED** = wrong behaviour players will hit. **LOW** = polish, dead code or a risk to verify.

---

## HIGH

### H1. A guard catch drops every carried item, then sends it to the nest (other players' pets and your own pets are lost)
- **Where:** `src/ServerScriptService/Patch.server.luau:4889-4911` (`bonk`)
- **Scenario:** A thief carries a Hoard pumpkin plus either a pet stolen from player B or their own pet picked up to sell. The guard catches them. `bonk` removes **every** stack item and clears `Purge.transit[p]`, so the stolen pet no longer returns to its owner. It then stamps `HoardZone = g.zone` on items that never came from a nest. After 20 s, `Hoards.giveBack` destroys each item and turns it into a nest pumpkin, so B's pet (or the thief's own pet) is gone for good. Before that, a third player can take B's pet freely.
  The stamp also lasts if the item is grabbed again. Carrying it re-wakes the guard. On death, `Bases.dropStolen` (3273) sends it to the nest, not back to its owner. The old code only took back `HoardZone` pumpkins.
- **Fix:** Drop only pumpkins whose `HoardZone` is already set (all zones, or just `g.zone`). Never write `HoardZone` in `bonk`. Leave stolen pets on the old path (`giveBack(owner, …)` / transit), and keep the thief's own pets on their stack.
- **Severity:** HIGH (data loss of other players' pets)

---

## MED

### M1. An old destroy timer deletes a pumpkin that was grabbed again and dropped again
- **Where:** `Patch.server.luau:2117-2121` (`dropLoose` timer) together with `bonk` 4897-4906
- **Scenario:**
  1. t=0: the player is caught. `dropLoose(p, …, 21)` starts a destroy timer for 21 s, and `bonk` starts a giveBack timer for 20 s.
  2. t=5: the player grabs it again. `wakeLoose` re-wakes the guard.
  3. t≈10: caught again. New timers are set for 30 s and 31 s.
  4. t=21: the **first** destroy timer fires. `p.Parent == loose` is true, so it runs `p:Destroy()`. The pumpkin vanishes 9 s early, and no `giveBack` runs.

  The `GuardDropUntil` token protects the giveBack timer, but not dropLoose's own timer. This is a loss, not a duplicate.
- **Fix:** Give dropLoose a drop token, e.g. `local token = {}; pumpkin:SetAttribute("LooseToken", …)` or a weak table, and check it in the delay. For guard drops, you can also skip dropLoose's own timer and let the giveBack timer own the lifetime.
- **Severity:** MED

### M2. Changing a guard's target leaves `GuardChasing` stuck on the old thief
- **Where:** `Patch.server.luau:4786-4806` (`wake`)
- **Scenario:** The guard is chasing A, and A's `GuardChasing` is true. A places the pumpkin, so A no longer carries from this zone, but the next Heartbeat has not called `giveUp` yet. In that window B grabs from the same nest. `wake` passes its early-return check because `carriesFrom(A)` is false, then overwrites `g.target = B` without calling `giveUp`. A keeps `GuardChasing = true` until some later giveUp happens to touch A. On A's client the vignette and RUN!! stay on, and Daily stays hidden.
  `debugFight` (4915-4922) has a related bug. It sets `h.guard.debugTarget = true` even when `wake` returned early, so another player's real chase ignores `carriesFrom`.
- **Fix:** At the top of `wake`, if `g.target` is set and is not `player`, call `giveUp(g, false)` (or clear the old target's attribute) before taking the new target. In `debugFight`, set `debugTarget` only when `g.target == player` after the wake.
- **Severity:** MED

### M3. The new overlap check blocks King JOIN when another player is standing there, and may break pen and shop teleports
- **Where:** `Patch.server.luau:2009-2046` (`Bases.safeLanding`), used at 8332 (King join) and 9254 (teleport)
- **Scenario:**
  - The overlap box excludes only floors. Every player who presses JOIN lands at the same single point, `Plaza + (28,0,0)`. The second player's box overlaps the first player's character (HRP and limbs can collide), so it returns `nil` and the press **silently does nothing**. There is no hint.
  - The old teleport had no overlap check. "My Pen" lands at the centre of the soil and "Shop" at the stall `PromptPart`. A colliding plot, pet, sign or counter there now returns "No safe landing", which is a regression in teleports that worked before.
  - `kingSide = 28` on +X is a guess. Nothing confirms it is clear of the statue or plinth. Ruling A8 asks for "JOIN 20 times with no death".
- **Fix:** Add every `Players` character to the overlap exclude list, or ignore parts whose ancestor has a Humanoid. Try a ring of candidate offsets (e.g. 8 angles at radius `kingSide`, then a bigger radius) and use the first clear one. Fire a hint when nothing is found. In Studio, test JOIN 20× with 2+ players, plus My Pen and Shop teleports.
- **Severity:** MED

### M4. The Drop button now shows for any carried item, so one tap can give your own pet away
- **Where:** `src/StarterPlayerScripts/Patch.client.luau:4904`
- **Scenario:** Before, Drop showed only when `CarryStolen` or `CarryHoard` was above 0. Now it shows whenever `Carry > 0`. A player carrying their own pet to the Witch taps it by accident. The server `dropEvent` (Patch.server 5692) runs `dropLoose` on it, and anyone can pick it up for 30 s before it is destroyed. This goes against the A23 rule "never lose pets by accident".
- **Fix:** Keep the old visibility (`CarryStolen > 0 or CarryHoard > 0`), or make the server drop only stolen and Hoard items.
- **Severity:** MED

### M5. A full-pen "Place" prompt swaps the weakest pet in one hold, with no label or confirm, and hatches the new one instantly
- **Where:** client `Patch.client.luau:2950-2960` (PlacePrompt is enabled on filled plots), server `Patch.server.luau:2925-2928` and `3051` (`carve(placed, true)`)
- **Scenario:** With a full pen, every occupied plot shows a "Your plot" Place prompt. Holding E on any of them destroys the pen's weakest pet, not the pet on that plot, and pays candy. A18 does allow the auto-replace, but the prompt never says it replaces anything, which is how A23 happened.
  The swapped-in pumpkin is also `carve`d at once, which skips `CarveSeconds`. A18 asked for "the normal hatch reveal instead of a toast", not an instant hatch. SEG3 lists swap + hatch as an exploit, so this is an economy change outside batch 1.
  For a stolen player pet (no `Hoard` or `Jack`), `fullChoice` returns silently. The prompt shows and nothing happens.
- **Fix:** Put the swap on the prompt text: ActionText "Replace weakest", ObjectText `<weakest pet name>`. Enable it only when the top item is Hoard or Jack. Let the new pumpkin hatch on its normal timer, and send `forceReveal` when it hatches.
- **Severity:** MED

### M6. The part renaming only takes effect after VoxelModels is rebuilt and copied into the place
- **Where:** `scene/VoxelModels.luau:102-106`. It outputs to `ServerStorage.VoxelOut`, which is not where the game reads from.
- **Scenario:** The server reads `ServerStorage.PetModels` and `ServerStorage.GuardModels`. The models already in the place still name every part "V". Until someone reruns VoxelModels in the command bar and copies `VoxelOut/Pets` and `VoxelOut/Guards` over those folders, guard eyes never glow (A9) and Gold pets still lose their faces (A20). The code passes lune but changes nothing in game. The copy would also overwrite any hand edits made to those models in Studio (e.g. B16 Scarecrow face).
  `scene/VoxelKit.luau:101` still names parts "V". Nothing in `src/` or `scene/` searches for "V", so no existing code breaks.
- **Fix:** Add the rebuild and copy step to the Studio test list. Add a server startup warning when a voxel model has no `FacePart` attribute. Diff the place's current models before overwriting them.
- **Severity:** MED (the blocker is not fixed in game until this is done)

### M7. Gold Crow stays black, and Gold Toad keeps a green hat (wrong palette keys marked as face)
- **Where:** `scene/VoxelModels.luau:104-105`, `Patch.server.luau:1936-1946`
- **Scenario:** `FacePart` treats every `k`, `e` and `f` as a face part. On Crow, `k` is the whole body, head and tail (lines 436-444), so a Gold Crow keeps a black body with gold wings only. On Toad, `f` is the leaf hat (734-736). On Kinglet, `k` is also the ermine spots, which is fine. The server's name fallback `{"Eye","Face","k","e","f"}` repeats the same mistake.
  Guard eyes have similar problems: the PumpkinKing `f` includes the vine-arm leaves (1156-1157), so the leaves glow red, and the CandyGolem `k` includes its nose.
- **Fix:** Give each model a face-key list (e.g. a `faceKeys` field in `add()`), for example Crow `{e}`, Toad `{k}`, Kinglet `{f}`. Set `FacePart` only when it is true. Drop the name fallback on the server, or use the same per-model list there.
- **Severity:** MED (visual, but Gold is the top rarity finish)

### M8. The guard twist attacks were removed without a ruling
- **Where:** the old `twist()` was deleted at about `Patch.server.luau:5080`, along with the Heartbeat call
- **Scenario:** The task asked only to cut the TAP quick-time fight. The diff also removes every zone twist (Bone, Boulder, Bat, Sticky, Tongue), and no LAUNCH-PLAN ruling cuts them. Left behind are the `Config.GuardTwists` config, `g.twist` / `g.nextTwist` / `warnUntil` (4806-4807, 5150, now dead), the client `Telegraph` "Guard:*" handlers (client 5404-5450) and the slow/stagger pieces of `Progress.slow`. Chases in Zones 2-7 now differ only in speed.
- **Fix:** Get an explicit ruling. If twists stay, restore `twist()` and keep it from firing during `minChase` or cosmetic chases. If they go, delete the dead config, fields and client handlers in the same batch.
- **Severity:** MED (scope creep and a design regression)

---

## LOW

### L1. During a guard drop the nest can briefly hold one extra pumpkin
`Patch.server.luau:4889-4911`, together with `Hoards.tick` 5050. A dropped pumpkin does not count toward `h.pending`, so during its 20 s `tick` can refill that slot. For up to 20 s there is one more grabbable pumpkin than `HoardCount`. When the giveBack runs later it finds no free slot and is discarded, so nothing is duplicated permanently.
**Fix:** `h.pending += 1` at the drop, and `-= 1` on re-grab or giveBack.

### L2. The first-ever (cosmetic) chase is faster than a real Zone1 chase
`Patch.server.luau:4800`: `GuardianFirstShare` is 0.8, but `GuardSpeed.Zone1` is 0.70. The first-ever chase never catches, which is correct. The flaw is that a brand-new player sees the fastest Zone1 guard of their career.
**Fix:** Use `math.min(Config.GuardianFirstShare, Config.GuardSpeed[g.zone])`, or keep 0.8 and accept it.

### L3. Shake is probably too weak to see
`Patch.client.luau:292-319`. Strength is `strength*0.025` rad, capped at 0.05, then multiplied by `math.noise`, which stays around ±0.5. The hatch call `shake(0.5,8)` comes out at about 0.36° for 0.16 s, which may fail the acceptance check "Shake is visible on a hatch".
The binding order itself is correct: restore at `Camera-1`, apply at `Camera+1`, the call API is unchanged, and every caller already uses `task.spawn`.
**Fix:** Multiply by about 3, or normalise the noise (`*2`). Check it on a hatch in Studio.

### L4. The vignette and Daily use a DisplayOrder tie and two different safe lines
`Patch.client.luau:4861`: `alarmGui` = HUD (1) - 1 = 0, which ties with `dimGui.DisplayOrder = 0` (1170). It is still below the HUD, so the requirement is met, but the order against the dim layer is undefined. The vignette's safe-zone check uses `state.SafeLineZ`, while Daily (5139, 6668-6680) uses `Config.SafeLineZ`.
The vignette also hides whenever `Center.busy` is true, i.e. during any banner.
**Fix:** Use an explicit 0 / -1 ordering and one safe-line helper.

### L5. The Daily panel is force-closed every Heartbeat
`Patch.client.luau:5142`, 5180. After a claim, `DailyClaimable` turns false, so the panel closes at once and the "Day N: +X candy!" text in it is never seen. Two `rootPart()` calls per frame are a minor cost.
**Fix:** Close the panel only when the hub or carry condition changes, not when it is no longer claimable.

### L6. Stale text from the cut features
`Patch.server.luau:8244` still says "Pens full: Swap or Sell", referring to the soil prompts that were removed. The objective also lost the "JOIN KING NIGHT!" and quest/order pointers. That is acceptable under A19, but check that King Night is announced somewhere else.

### L7. The steal() early return leaves `PurgeStealing` set
`Patch.server.luau:3122-3134`. The new hatching / `PickupReadyAt` return runs before `Purge.holds[thief] = nil` and before `PurgeStealing` is cleared, so the client stays in its "stealing" state. Purge is off at launch per A28, so the impact is low.
**Fix:** Move the new check after those two lines.

### L8. Dead code left behind
- `FightActive` is now never set, but the client still reads it (3446, 5230, 6650) and so does the server (4957, 8331, 9178, 9337).
- `Config.UI.fightY` and `Center.interrupt` (client 360) are no longer used.
- The `GuardTwists` fields are covered in M8.
- The debug log prints on every state change **in every Studio session** (5103), because it is gated on `IsStudio()`. It should be gated only on `PatchDebug`.

### L9. The econ sim no longer matches the swap payout
The swap now pays `SellPerIncome` (30 s, server 3042). `scene/econ-sim.luau:128` still models a swap as `FullPenSellSeconds` (300 s). This is a batch-2 change made early, and the sim passes against the old rule.
**Fix:** Update the sim, or move the payout change to batch 2.

---

## Verified OK
- **Re-grab duplication:** the giveBack timer is guarded by `GuardDropUntil`, which `stackPumpkin` clears. The prompt checks `Parent ~= loose`, and there is a new server distance check of 11 studs. No item can be duplicated, only lost (H1, M1). The pen pickup has its own guards: `PickupReadyAt` / `CarveAt` in `pickUp`, `steal` and the swap's weakest-pet choice.
- **First-ever chase:** `g.cosmetic` blocks `bonk`. `FirstHoardDone` is saved, so a rejoin does not give a second free chase.
- **"You got away!"** fires only when `g.chasedAt` is set, i.e. the guard reached `chase` (4831).
- **Minimum chase:** both catch and give-up are gated on `minChase` = 3 s. Catching is also blocked in the safe zone and in the thief's own base. With `HoardLeashPad` at 80 the chase no longer ends at once.
- **Vignette:** edge only (8 % bands, opacity 25-35 %), shown only when chased or carrying a stolen pet, hidden in the hub and when a panel is open, and drawn below the HUD.
- **Shake** is bound after `Camera`, with a restore step before it so the camera module never reads a shaken CFrame.
- **Removed names:** `fightEvent` / "Fight", `Hoards.fight`, `twist`, `PatchStealBeat` / FightBar, `nearestCauldron`, `otherBase`, `nearestGhost`, `Config.Fight`, `FightUsed`, `StunnedUntil` and `GuardMercyUntil` (set) have no remaining references in `src/` or `scene/`. Only `gateCost` was renamed (to `ZoneView.gateCost`), and both callers are updated. The soil prompts are also destroyed at runtime.
- **Smashing while carrying** is blocked on both the server (6630) and the client (3443). TAP is gone, so TAP and RUN can never show together.
- **Saves:** no DataStore keys or saved fields changed (`firstHoard`, `wakes` and the others are intact).
- **Tool checks:** compile-check OK, selene clean, econ-sim OK.

## Studio test additions
1. Carry a Hoard pumpkin plus your own pet, or a stolen pet, and get caught. Neither pet may end up in the nest (H1).
2. Get caught, re-grab, get caught again within 10 s, and watch the pumpkin for 30 s (M1).
3. Two players press JOIN at the same time, 20 times each, then use the My Pen and Shop teleports (M3).
4. Rerun VoxelModels, copy the output into PetModels and GuardModels, then check red eyes on wake and the Gold Crow, Toad and Kinglet (M6, M7).
5. With a full pen, hold E on a plot: check the prompt text, which pet is replaced, and the hatch timing (M5).
