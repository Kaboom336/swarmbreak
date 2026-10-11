# B5/B6/B7 review (diff 857f612..HEAD, pumpkin/giant/src)

This was a read-only review. I did not run anything in Studio. Line numbers are HEAD lines: S = `ServerScriptService/Patch.server.luau`, C = `StarterPlayerScripts/Patch.client.luau`, K = `ReplicatedStorage/PatchConfig.luau`.

**Verdict:** I found no confirmed blocker in the code. Two high items should be fixed before launch: H1 (you can only carry 1 pet) and H2 (a startup assert can kill the whole server). Also check H3.

## High

| # | Where | Scenario | Fix |
|---|---|---|---|
| H1 | C:3315 (PetPrompt `set(...)` adds `and not carrying`) | The owner picks up 1 pet. The prompt on every other pet is then hidden, so carry never goes past 1/3 and the Witch stack sale is dead. A thief who is already carrying cannot steal either, but the server would allow it up to capacity. Before this change, pick-up was only blocked while carrying with a full pen. | Hide the prompt only when `Carry >= capacity`, or when the pen is full and the Place/Swap prompt owns the interaction (the old rule). |
| H2 | S:30-35 (`assert` PumpkinPup), S:90-93 (`assert` ThroneKing) | If the published place lacks `ServerStorage.PetModels.PumpkinPup` or a model named `ThroneKing`, Patch.server dies at startup. Nothing works: no remotes and no saves. | Replace both with `warn` and a graceful fallback. Before publishing, check that the place has both by name. |
| H3 | S:2601 (`error(...)` in becomeAlive) | `Looks.attach` returns false when a pet model has a bounding box under 0.01 high, or a bad clone. becomeAlive runs from `Bases.put`, which `Bases.restore` calls during player load and the hatch path calls too. The error aborts that player's load mid-way, or kills the calling loop. | Use `warn`, then fall back to the PumpkinPup look, or keep the plain pumpkin. Never `error` on a live path. |

## Medium

| # | Where | Scenario | Fix |
|---|---|---|---|
| M1 | C:1040 (pop lanes at `-lane*0.30` of Stats), C:898 / C:1166 | **Phone:** the Stats frame is at y 0.365-0.565 and the left buttons at y 0.12-0.357. Candy pop lanes 1-3 rise to about y 0.185, so they draw over Shop/Index/Daily. They do not block clicks (TextLabels), but they are hard to read. | Put the lanes to the right of the counter on touch, or shrink them to 0.15 steps and limit them to 2 lanes on touch. |
| M2 | C:200, C:1196 (pill `mobile()`), C:4029, C:5834, C:7353 (`and not KeyboardEnabled` removed) | Touchscreen laptops and tablets with keyboards get the phone layout: icon-only buttons, panels at 0.92 width, and the dash button shown. | Restore `TouchEnabled and not KeyboardEnabled`, or use `LastInputType == Touch`. |
| M3 | C:6988-7000 (pet RenderStepped) | Every frame, every placed pet in the server (8 pens x up to 16, about 128) does about 5 attribute reads plus `Config.roamPoint`. This happens before the 80-stud cull, so far pets still cost CPU. | Move the distance cull into the 0.5 s list-builder loop (C:6970), so RenderStepped only walks nearby pets. |
| M4 | C:7057 (`garden.Zones` direct index) | If `Zones` is missing or not yet streamed, `garden.Zones` throws. This happens only when a `HoardPumpkin` is in range. The aura and nest-glow thread dies for the session. | `local zones = garden:FindFirstChild("Zones")`, and nil-check it. |
| M5 | S:2030 (`Looks.clear` in stackPumpkin), S:2793 (`Bases.extraOf` has no HatchSize) | A picked-up or stolen pet becomes a plain pumpkin (B17 asks for this). When it is placed again, it hatches without `HatchSize`, so it comes back smaller than the first hatch (the B15 ≥0.8x rule is lost). | Add `hatchSize = p:GetAttribute("HatchSize")` to extraOf and restore it in `Bases.put`. |

## Low

| # | Where | Scenario | Fix |
|---|---|---|---|
| L1 | S:6060 (`addCandy(player, total, true)`) | `addCandy` still adds `candyFraction`, so a sale can pay 1 more than the shown `CarryValue` (A3 exactness). | Pass a flag that skips the fraction for sells, or fold the fraction into the quote. |
| L2 | C:3357 | The Sell prompt says "Sell for $X". The currency is candy. | Use "Sell: X candy". |
| L3 | S:2366 | `ObjectText = title .. " ? +2 slots"`: the "?" is a mojibake separator. | Use " - +2 slots". |
| L4 | S:52-70 | PetPreviews copies every child of PetModels, including the 168-part `MysteryPumpkin`. It is replicated to every client and never rendered. | Copy only the names in `Config.Pets`. |
| L5 | K:1336-1340 `Config.indexReward` | `min(max(200, x), income*cap)`: the cap wins, so the 200 minimum is never honored (an early pet pays about 21). This is safe for econ, but the reward looks tiny. | Use `max(minimum, min(x, income*cap))` if a 200 floor is wanted. Re-run econ-sim. |
| L6 | C:5952 | The Daily "Come back in hh:mm" only updates on `refresh()`, so the time goes stale while the panel is open. | Re-run `refresh()` each second while the frame is visible. |
| L7 | C:461 | `ScreenInsets = CoreUISafeInsets` replaces `IgnoreGuiInset`. Full-screen flashes and vignettes in PatchHud no longer cover the top bar. | Put full-screen overlays in a separate ScreenGui with IgnoreGuiInset. |
| L8 | C:6875 | The pop-in tweens server-replicated `LookWeld.C0`. If the server refits the look during the 0.35 s tween, the tween just ends on a destroyed weld. This is harmless, noted only. | None needed. |

## Checked and OK

- **Index claims (S:9937-9987):** The server validates discovery from `indexOf`. Claims are keyed per pet, and the flag is set before payout with no yields, so claiming is idempotent. The amount is computed on the server from the server-set `Income`. The claim is saved with the candy (`IndexClaims`/`IndexMilestones` at S:1389). Old saves default to `{}` (S:509). Admin reset clears the claims (S:9714) and `Title` (S:9735). `cleanupPlayer` clears the tables. The client key "Milestone:25" matches the server.
- **Owner cannot steal:** PetPrompt.Triggered routes the owner to `pickUp` (S:3705, S:3731). The Purge hold excludes the owner (S:3776). `steal()` still checks `ownerId == thief.UserId`.
- **Sell quote:** `Helpers.sellQuote` is shared by `CarryValue` and the sale (S:1738, S:6020). It is refreshed every second (S:3595). Apart from L1, the shown amount equals the paid amount.
- **Upgrade prompt:** The server checks distance, owner, slots, the previous zone and the cost (through `unlockZone`).
- **Removed names:** There are no live references to PickupPrompt, old StealPrompt (the remaining hits are Hoard nest prompts), dressJack, OwnerPortrait (only the cleanup), indexCells, refreshIndex, travelIcon, MAX_QUEUE or `button(`.
- **Leaks:** PetPrompt is one per plot and goes back to the plot on every `Bases.take`, which is the only removal path. Index tiles are built once, lazily, and nothing rotates. Candy-icon ViewportFrames die with their parent. Aura and glow effects are destroyed when out of range or gone.
- **Reveal queue:** It is pcall-guarded, so `revealBusy` cannot stick. Only the data-only Reveal remote shows the card, so there is no double card.
- **Daily and Teleport share slot 3:** They are mutually exclusive (Daily hides on Zone2; Teleport shows on Zone2).
- **Phone zones:** The event chip (y ≤ 0.59) and the left bar and stats stay out of the jump and thumbstick zones. Panels open at 0.92 x 0.85 on touch. Index tiles are at least 70 px.
