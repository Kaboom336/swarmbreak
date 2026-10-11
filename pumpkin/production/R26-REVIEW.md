# R26 review: The Purge, owned pen names, Gotham fonts

Scope: `git diff HEAD~1 HEAD -- pumpkin/giant/src/` (commit 8d0d7b3), checked against R24-PLAN.md section 2.
Line numbers are for the files at HEAD. Every item below was traced through the code; nothing was run in Studio.

**Fonts: no breakage found.** Nothing on the server reads `Config.Fonts`, and nothing in `pumpkin/giant/src` calls `Enum.Font[...]` on a Config.Fonts value except `fontFace()` (Patch.client.luau:16-33), which now handles both table and string specs. `shout` is still a string and still goes through the enum path. Every other caller uses `fontFace(role, ...)`, including `textLabel(..., font)` at :413, which only receives role names. One side effect is intended: a table spec's weight overrides the caller's, so `fontFace("number", "Regular", ...)` at :840 renders as Heavy. The server's own billboards (LockWall timer at server:3194, King loot sign at :8450) still hard-code `Enum.Font.FredokaOne`. That is a look mismatch, not a bug.

## Ranked findings

### 1. (High) Standing still for 45 s gives a full-Purge lock and a guaranteed free Survivor pet
- **Where:** server:72-76 (`Purge.immune`), :2040-2044 (`Bases.isLocked` returns true for immune owners), :8879-8895 (Survivor loop in `finish`), :8829-8832 / :8851-8855 (participants include every loaded player).
- **Scenario:** A player stops moving 15 s before the 30 s warning, or just goes AFK. After 45 s they count as immune, which has three effects: `isLocked` is true for the whole Purge, thieves get "locked", and ghost raids skip them (`raidEligible` calls `isLocked`). They can never be added to `losses`, so `finish` gives them a Hoard-size mystery pet from their best zone every Purge (twice an hour). The same applies to players under 15 minutes of playtime, a player with an empty pen, and alts left idle. The one-lock-per-Purge limit also stops mattering, because standing still is an unlimited lock.
- **Fix:** Give the Survivor reward only to players who were robbable for most of the Purge. For example, record per player how many seconds they were not immune and not locked, and require at least 90 of the 120 s plus at least 1 unprotected pet in the pen. Exclude players under `Purge.grace` from `participants`.

### 2. (High) Steal-and-bonk with a friend or alt mints candy every Purge
- **Where:** server:3066-3068 (`StealOwnerShare` paid when the steal happens), :3127 (`Purge.reward(owner)` on bonk).
- **Scenario:** An alt or friend steals the main's pet. The main gets 25 % of the pet's sell value right away, bonks the thief within 10 s, gets the pet back, and earns 250 x zone-tier candy. A returned pet is not a loss, so the main also still qualifies for Survivor. Two friends can do this to each other every Purge with no risk.
- **Fix:** Pay the owner share in `Purge.settle` (the steal is final), not in `steal()`. Pay `Purge.reward` only when the theft is reversed, and never pay the share for that theft. Optionally cap defence rewards to 1 per owner per Purge, and pay nothing when the thief stole from no one else.

### 3. (Medium) The "Steal a pumpkin" order is dealt when no Purge is running
- **Where:** server:503 `Progress.orderLive`, steal branch :527-560 (checks `LockedUntil`/`RobbedUntil` only). Server-side, steals are now Purge-only (:3002-3011).
- **Scenario:** Outside a Purge, `orderLive` says a steal target exists, so the order is dealt. It cannot be completed for up to 40 min, and `orderExpired` (:498) does not retire it. `stopThief` has the same problem to a lesser degree. The check also ignores `Purge.immune(other)`.
- **Fix:** In the `steal` branch, return false unless `Purge.active()`, and skip `other` when `Purge.immune(other)` is true. Alternatively, retire steal orders in `orderExpired` when no Purge is active or warned.

### 4. (Medium) `Purge.tick()` runs without a pcall in the main 1 s loop
- **Where:** server:8701.
- **Scenario:** Every other subsystem in that loop (Bases.tick, guardZones, Hoards.tick, Spooky.tick) is wrapped in a pcall. `Purge.tick` calls `Purge.start`, which calls `spawnGhost`, `stealTargets` and `raidEligible`, and it also calls `finish`. Any error in that chain kills the whole loop for the rest of the server's life: PlayTime, unlocks, the idle shield, daily rewards and order refresh all stop.
- **Fix:** `local ok, err = pcall(Purge.tick) if not ok then warn("[Patch] Purge tick failed:", err) end`.

### 5. (Medium) The ghost-raid warning still says "Lock base", but locks now only work during a Purge
- **Where:** server:8078 (raid announcement); :3214 `Bases.lock` returns early unless `Purge.active()`; client LockPrompt and HUD pill are hidden outside a Purge.
- **Scenario:** A normal raid tells players to lock their base. Neither the LOCK prompt nor the remote does anything, so the only defence is going home. The debug `lock` action (:9050) is also a no-op outside a Purge.
- **Fix:** Change the text to "Ghosts coming! Go home to protect your pen". If raid locks are meant to stay, keep the old cooldown lock path when no Purge is active.

### 6. (Low) After the 10 s window, a dropped stolen pet can be picked up by anyone
- **Where:** server:1998-2001 (pickup restricted while `Purge.transit[p]` exists); Heartbeat settle (:8936-8944) runs on `t >= untilAt` even when `p.Parent == loose`.
- **Scenario:** The thief uses Drop with the stolen pet. Ten seconds later the Heartbeat settles it: `Owner` becomes the thief and the transit entry is cleared, so the restriction disappears. The pet now lies loose, and any passer-by can take it. The victim is also marked as a loss.
- **Fix:** In the Heartbeat, do not settle a pet with `p.Parent == loose`. Either give it back to the owner when the window expires (the thief never got it home), or keep the pickup restricted to the thief.

### 7. (Low) A victim who leaves mid-theft can lose the pet for good
- **Where:** server:8619-8631 calls `Bases.giveBack`; giveBack falls back to `dropLoose` at :2716-2718.
- **Scenario:** The victim places another pet in the emptied slot, so no plot is free, and their hands are full or their character is already gone. When they leave, the returned pet is dropped loose after their carry has been collected for the save, so it is never saved for anyone.
- **Fix:** In PlayerRemoving, when no plot is free, append the pet's entry straight to `Progress.pending[player]` (the `collectCarry` format) and destroy it, instead of calling giveBack.

### 8. (Low) The Steal prompt shows in cases the server refuses
- **Where:** client:2905-2945 compared with server:3018-3040.
- **Scenario:** The client shows Steal when the thief's own base is locked (the server refuses with a hint) and on stashed pets (the server returns silently, with no feedback). The server's "was robbed a moment ago. Try again later." hint (:3042) is also wrong now: the rule is one steal per victim per Purge.
- **Fix:** Hide the prompt when `myPatch()`'s `LockedUntil > now` or the pumpkin has `Stashed`. Change the hint to "already robbed this Purge".

### 9. (Low) The Spooky Hour end toast promises the wrong time
- **Where:** client:3333 `clockText(Config.SpookyEvery or 600)`.
- **Scenario:** Spooky is now pinned to :30 by `nextSpooky`, so the next one is about 58:30 away, but the toast always says 1:00:00. It would be wrong after any debug or late start too.
- **Fix:** Use `state:GetAttribute("SpookyNext") - workspace:GetServerTimeNow()`.

## Checked and found OK
- **Stealing outside the Purge:** `steal()` requires `Purge.active()`, a server-recorded hold of at least 2 s on the same plot, and the current `Purge.id`.
- **Best pet:** `Protected` is still checked first. Stashed pets now count when choosing the best pet. That only matters when a ghost holds the best pet, and that pet is unstealable anyway.
- **Multiple steals per victim:** `Purge.victims[ownerId]` is per Purge and survives rejoining.
- **Lock limit:** one lock per Purge, enforced on the server by UserId.
- **Delivery bypass:** place, hoard place, swap, pen-sell and market sell all go through `Purge.deliveryReady`.
- **Thief death or leave:** stolen pets go back through giveBack, which clears the transit entry. `collectCarry` skips `StolenFrom` pets while the victim is online.
- **Schedule:** King :00/:20/:40 and Purge :10/:50 do not overlap. `kingClock`, `raidCheck` and `Spooky.start` all yield to the Purge and its warning, and Purge yields to King, LocksOff and Spooky. One design note, not a bug: Spooky dropped from every 10 min to once an hour, at :30.
