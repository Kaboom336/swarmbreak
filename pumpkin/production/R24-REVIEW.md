# R24 review: commit 8219f6f (Codex: stale-goal sweep, big pumpkins + roaming pets, Boots, teleport, dash, walking King, guard speed by zone)

Scope: `git diff HEAD~1 HEAD -- pumpkin/giant/src/`. This was a read-only review. Line numbers refer to 8219f6f. selene (giant/selene.toml) reports 0 errors and 0 warnings on all three files.

## Checked and clean (no finding)

- **Remotes.**
  - `Teleport` and `Dash` are RemoteFunctions and `Sprint` is a RemoteEvent. Names match between `server:108-111` and the client `WaitForChild` calls.
  - Teleport accepts only the three target strings. Dash takes no arguments.
  - All positions come from the server. There is a 0.1 s attempt limit and a per-action cooldown, and the cooldown is stamped only on success.
- **Teleport blocks.**
  - Teleport is refused in each of these cases:
    - while `FightActive` is set
    - while a guard targets you (`Hoards.targets`, cleared in `giveUp`)
    - while you carry any `HoardZone` (nest) or `StolenFrom` (stolen) pumpkin
    - while you are stunned (multiplier 0)
  - A thief cannot teleport away from a bonk, and a nest runner cannot teleport away from a guard.
- **Dash blocks.**
  - Dash requires `bestTool().order >= 2` (Iron Scythe). The client uses `Tool ~= StartTool`, which is the same test.
  - Dash is refused while carrying a nest or stolen pumpkin, in a fight, or during `PurgeEnds`.
  - Distance is clamped by both a blockcast and a raycast. The client's look vector only chooses the direction.
- **Speed.**
  - The server Heartbeat (`server:8916-8938`) owns `WalkSpeed`: `16 + 2*Boots`, capped at 26, x1.25 while sprinting, minus the carry penalty, times the guard-twist multiplier, and 0 in a fight.
  - The only client input is the `Sprinting` boolean, so a legitimate client cannot go above 32.5.
- **Boots.**
  - Saved through the generic `Config.Upgrades` loop (`server:1147`), and clamped to 0..max on load (`:996-1000`).
  - Not touched by `Progress.rebirth`. Reset only by the admin reset.
  - Prices were retuned against the updated econ sim (allowed by plan section 1).
- **Pick up / steal reach.** These use the server-authored waypoint (`Config.roamPoint`), never a client CFrame.
- **Steal prompts.**
  - They move to `PetPromptAnchor` on hatch and back to the plot in `Bases.take`.
  - Every removal path (pickUp, steal, sell-weakest, clear, fuse) goes through `take`. A stash ghost keeps the pumpkin parented to the plot. So no plot loses its prompts.
- **Income.** The server never moves the pet part, so income is unaffected.
- **Leaks.** The client roam loop holds no per-pet connections.
- **King banner.**
  - King orders are no longer dealt unless `KingActive` is set and HP > 0.
  - The client also refuses to show "Hit the Pumpkin King!" without `KingActive`.
  - Zone quest checkboxes moved to the toggle panel.
- **King phases.**
  - Phase 1 stays planted. The King attacks only when `not moving and not attackBusy`.
  - `endBloodMoon` restores pose, size and collision. Rewards and defeat paths are unchanged.
- **R23 findings.** None got worse.
  - #2 (income tag) got slightly better: kg is shown again, but the shield is still missing.
  - #6 (hoard glow) is unchanged: `Looks.attach` at `:2524` still passes no glow.
  - The rest are untouched.

## Findings (ranked)

### 1. [Medium] The stale-goal sweep wipes the active order whenever its live condition blinks off, including while the player is doing it
- **Where:**
  - `server:8534-8541`, the 5 s loop that redeals when `not Progress.orderLive(player, o.list[1])`
  - `server:816-826`, the same test on load
  - the `orderLive` rules at `:479-547`
- **Problem:** `RotatingCount = 1`, so `list[1]` is the player's only order. `orderLive` tests transient world state:
  - **bonkGhost** is live only while any ghost exists. "Bonk 8 ghosts" is dealt at Midnight; the player pops the last ghost at 5/8, and within 5 s the order is replaced and the progress is lost.
  - **placeType:Ghost** (target `place`) is live only while the shared Zone1 nest (3 pumpkins, refilled at Midnight) still has a pumpkin. Taking the last nest pumpkin to do the order kills the order while the player carries it home. Another player emptying the nest does the same.
  - **steal** turns false whenever the only victim locks their base or is inside `RobbedUntil`.
  - **On login,** any of these that is not live at that moment marks the saved list stale and redeals it.
- **Fix:**
  - Use `orderLive` only when *dealing* (`nextOrders`).
  - In the loop and in `loadOrders`, swap out only orders whose target can never come back this session, i.e. `target == "king"` while `KingActive` is false (the plan's actual ask), plus `gate` with no locked zone left.
  - Alternatively, keep `(o.list[1].have or 0) > 0` orders and only hide the banner goal.

### 2. [Medium] The walking King floats at plinth height and moves in 2-stud jumps
- **Where:** `server:6884` (`faceBase = eventBase + (kingGround - groundHome)`), `:7048-7050`, `:7085-7087`.
- **Problem, height:**
  - `eventBase` is the plinth pose. Lobby.luau builds the plinth top at y=6 and lifts KingFace by 6.
  - Only the horizontal delta is added, so at every pad (±40, ±25 from centre, all off the 34-wide plinth) the 28-stud King hangs about 6 studs above the plaza.
  - Meanwhile the slam and volley telegraphs are drawn at `kingGround`, on the floor.
- **Problem, motion:** `walkKing` runs only from the event loop, which ticks every 0.2 s. An anchored server CFrame is not interpolated on clients, so the King visibly teleports 2 studs five times a second.
- **Fix:**
  - When `king.pad > 0`, set Y so the King's feet sit on the ground: `CFrame.new(kingGround + Vector3.yAxis * (kingFace.Size.Y/2 - 1)) * homeBase.Rotation`. Tween the first step down off the plinth.
  - Drive the walk from a Heartbeat (or `TweenService` per leg, which replicates every frame) instead of the 0.2 s loop.
- **Verify in Studio:** the King's bottom height against the Lobby plinth.

### 3. [Medium-Low] Pet anchors are written every server frame, which floods replication
- **Where:** `server:3279-3286`.
- **Problem:**
  - `anchor.WorldPosition` is set on every Heartbeat for every placed pet: up to 8 pens x 10 plots = 80 attachments x 60 Hz of `Attachment.Position` replication to every client.
  - The client then overwrites it locally anyway (`client:6702`, `anchor.Position = Vector3.zero`), so the traffic is pure waste.
- **Fix:**
  - Update the server anchors at 5 Hz or less (a prompt's server range check tolerates that), or only on waypoint change plus every 0.25 s while moving.
  - `Bases.petReach` already validates against `roamPoint`.

### 4. [Medium-Low] Plot discs grow to the giant pumpkin's width and never shrink back
- **Where:** `server:2462-2466` and `:2507-2511`. No code restores `plot.Size`: `Bases.take`, `Bases.clear`, release and `slotLook` all leave it.
- **Problem:**
  - A Mythic mystery pumpkin (40 tall, wider than tall) turns its disc into about 40-48 studs.
  - After it hatches into a 3-15 stud pet, or after the pen is released to the next owner, the disc stays that size.
  - In a 36x30 pen with 10 discs, they overlap each other and the fence and z-fight, and the damage builds up over a server's lifetime.
- **Fix:**
  - Store the original size once (`plot:SetAttribute("BaseSize", plot.Size)` in `setupPlot`).
  - In `Bases.take` and in `carve`/`becomeAlive`, restore it, e.g. `plot.Size = plot:GetAttribute("BaseSize")`.
  - Better still, scale a separate visual ring instead of the plot part that owns the prompts.

### 5. [Medium-Low] Unhatched Legendary and Mythic pumpkins cannot be picked up or stolen
- **Where:** `server:2587-2594` (`(root.Position - at).Magnitude <= 11`, a 3D distance to the pumpkin's centre), with heights from `:2456-2466`.
- **Problem:**
  - A full-grown Legendary (33) has its centre about 16.6 studs above the disc and a Mythic (40) about 20; the player's root is about 3 above. The vertical gap alone (13.6 or 17) exceeds 11, so `petReach` is always false for the rest of the hatch timer (8-20 s). Heavy Epics fail unless the player stands inside them.
  - The prompt still shows (it is 9 studs from the disc), the hold completes, and nothing happens and no hint is shown.
- **Fix:** measure flat distance plus a vertical band, e.g. `Vector3.new(d.X,0,d.Z).Magnitude <= 11 and d.Y > -p.Size.Y/2 - 6`, or measure to `at - Vector3.yAxis*(p.Size.Y/2)` (the pumpkin's base).

### 6. [Low-Medium] Guard chase speed no longer looks at real velocity, so speed exploits and launch pads always escape
- **Where:** `server:5144-5159`.
- **Problem:**
  - The old code chased at `share x max(walk, seen velocity)`. The new code uses `GuardSpeed[zone] x (Boots walk x (Sprinting attr and 1.25)) - carry`.
  - Both inputs come from the server or a client boolean, so a client that raises its own `WalkSpeed` (client-owned physics) faces a guard at 0.7-0.95 of the *legal* speed and can never be caught. The same applies to jump pads (`PadForward = 70`).
  - The `Sprinting` attribute is also whatever the client last sent.
- **Fix:**
  - Keep the plan's fractions, but base them on `math.max(legalTop, math.min(observedFlatSpeed, legalTop*1.25 + 6))` as before.
  - Optionally add a server check that flags `observedFlatSpeed > legalTop*1.3` sustained over 1 s outside pads and dash.

### 7. [Low] Dash is blocked at every zone gate the player has already unlocked
- **Where:** `server:8893-8908`, with gate walls set to `CanCollide = true` on the server for all zones at `:3988`. Clients only open their own unlocked gates locally.
- **Problem:** the server blockcast with `RespectCanCollide` hits the server-solid wall, so a dash through an open gate returns "Wall ahead" or stops short.
- **Fix:** add `zones[id].GateWall` to the filter for each `id` where `hasZone(player, id)`.

### 8. [Low] The dash sweep box clips the floor, so short avatars and gentle slopes get "Wall ahead"
- **Where:** `server:8897-8899` (`Blockcast(root.CFrame, Vector3.new(4,5,3), ...)`).
- **Problem:**
  - The box is centred on the root, so its bottom is at root - 2.5. For a default R15 (root about 3 above the floor) that leaves only 0.5 studs of clearance.
  - For smaller avatars (HipHeight about 1.3) the box starts inside the floor. Blockcast ignores the part it starts in, but hits the edge of the next floor tile or path strip (Lobby paths are 0.16 thick) or any rise over 0.5 within 16 studs, so the dash is clamped to about 0.
- **Fix:** sweep a shorter box raised above the feet, e.g. `root.CFrame + Vector3.yAxis * 1`, size (4, 3.5, 3). Optionally raycast down at the destination to confirm there is ground.

### 9. [Low] Mobile players lost the RUN button
- **Where:** `client:5148`, where `BindAction("Sprint", ..., false, LeftShift)` was changed from `true` to `false`.
- **Problem:**
  - Touch players can only sprint through "Toggle sprint" inside the Teleport menu. Most will never find it.
  - The plan says sprint stays x1.25. Guards scale with the `Sprinting` attribute, so this does not cause catches, but mobile players move 20% slower than PC players everywhere.
- **Fix:** either keep the touch button (it is not one of the "3 buttons" in plan 7, which counts Dash on mobile), or auto-sprint on mobile (`setSprint(true)` when `TouchEnabled and not KeyboardEnabled`).

### 10. [Low] Ghost raids fly to the pet's home spot, not to where the pet is shown
- **Where:** `server:6180` (`goal = target.Position + ...`).
- **Problem:**
  - The server pet part never leaves its home CFrame, but clients draw it up to a pen-width away.
  - The ghost dives at empty soil and the pet snaps across the pen when grabbed. On rescue it snaps back to home (`:6103`).
- **Fix:** use `Config.roamPoint(target, now())` for the ghost goal. When grabbing, also set `ghost.savedCF`/`RoamTo` from that point, so the rescue resumes where the player saw it.

## Notes (not bugs, worth knowing)
- **Telegraph timing.** Plan section 7's 1.2 s windup now applies to Volley too (`VolleyWarn` is no longer used).
- **Phase 3.** The extra Phase-3 slam ring was removed. That matches "double-ring after launch".
- **Teleport landing (Zone Gate).** The landing point is 8 studs on the -Z side of the furthest unlocked zone's GateWall, i.e. at the end of the *previous* zone. If "Zone Gate" was meant to be inside the newly unlocked zone, use `+standOff`.
- **Teleport landing (My Pen, Shop).** These targets exclude the target part from the ray and cast from 60 studs up. Any collidable part overhead (stall awning, pennant at y 22) becomes the landing spot. Check the Shop landing in Studio.
- **`attack()` busy flag.** `attack()` returns without clearing `attackBusy` when the event token changes during the windup (`:6911-6913`). This is harmless today, because `startBloodMoon` and `endBloodMoon` reset it.
- **Stun tween.** After a stun, the 0.4 s tween back to `faceBase` (`:7006-7008`) overlaps `walkKing` resuming. Expect a brief stutter.
- **Mystery pumpkin height formula.** The code uses `heights[rarity] + 3.6*(kg^0.25 - median^0.25)` rather than the plan's `0.6 x kg^(1/4) x ch`. It stays within 15-40 and scales with rarity and weight, so it is acceptable. Sizes of 15-40 studs in a 36x30 pen with 10 discs will overlap heavily, which is plan-level and worth a look in Studio.
