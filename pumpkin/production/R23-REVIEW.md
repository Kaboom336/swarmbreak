# R23 review: commit e282ed8 (Codex UI rework, admin panel, plot domes/timers/locked discs)

Scope: `git diff e282ed8~1 e282ed8 -- pumpkin/giant/src/`. Read-only review. selene reports 0 errors and 0 warnings on all three files.
Line numbers refer to e282ed8.

## Checked and clean (no finding)
- **Admin security.**
  - `IsAdmin` is set only on the server (`Patch.server.luau:8060`). A client-side SetAttribute on the Player does not replicate.
  - The `Admin` RemoteFunction re-checks three things on the server (`:8392-8397`): `UserId == 405476801 or RunService:IsStudio()`, the server-side `IsAdmin` attribute, and `isLoaded`.
  - The Studio check runs on the server. The 1 s rate limit and a busy guard are in place.
  - `candy` amounts are validated: NaN and inf are rejected, and the value is clamped to 1..1e9.
  - `Bases.debugAction` is not reachable from any remote other than the four allow-listed actions.
  - The client gear is cosmetic only.
- **Admin reset.**
  - Ordering: cancel the fight, then `Bases.clear` (which runs while PenSlots is still the old value, so plots 7-10 are emptied), then `dropStolen` returns stolen and Hoard pumpkins, then the carry is cleared and progress resets.
  - `applyData({purchases=receiptsOf})` keeps the receipt ledger, so no product is re-granted. Game passes are untouched.
  - The reset is then saved and the character respawned.
  - No path leaves a carried or placed pumpkin duplicated. The only products are consumable candy, so a reset cannot lose anything that was bought.
- **Plot gating (Index > PenSlots).**
  - `place` (`:2621`), `plotsOf`, `firstEmptyPlot`/`Bases.empty`, `fillPens`, `restore` and every `Bases.put` caller go through PenSlots.
  - Client prompts use the same test (`Patch.client.luau:2819`).
  - All discs now get a `plotState` and prompts at boot (`:3112`). That fixes the old case where discs 7-10 on a 10-disc map had no state.
- **Leaks.**
  - Padlocks are created once and destroyed on unlock.
  - The puff emitter is destroyed after 1 s.
  - `PenUpgrade` and `OwnerPortrait` are made once per patch.
  - `HatchDome` and `HatchSparkles` are children of the pumpkin and are removed in `carve` and `Bases.take`. Every clear, steal or ghost path goes through `take` or `Destroy`.
- **Daily.** `ClaimDaily` is idempotent per UTC day and has no yield, so double-invokes cannot double-pay.
- **Fight bar.** start, fill, win, lose and cancel all still work. `Hoards.cancelFight` mirrors the PlayerRemoving cleanup.

## Findings (ranked)

### 1. [Medium] Admin gear sits under the Roblox top-bar menu button
- **Where:** `Patch.client.luau:1259`.
- **Problem:** the HUD ScreenGui has `IgnoreGuiInset = true` (`:335`), and the gear is at scale (0.012, 0.02) with size 0.045 x 0.07. At 1280x720 that is roughly x 15..73, y 14..64, exactly where the CoreGui Roblox menu and chat buttons draw. CoreGui renders above the gear and takes the click, on mobile too.
- **Effect:** the admin panel is hard or impossible to open.
- **Fix:** move the gear below the top-bar inset: `UDim2.new(0.012, 0, 0, GuiService:GetGuiInset().Y + 8)`, or use `GuiService.TopbarInset`. Simpler still, put it in the left column under the pills, e.g. y 0.66.

### 2. [Medium] Hatched-pet income tag no longer shows the shield, GOLD/SHINY or weight
- **Where:** `Patch.server.luau:2124-2133`.
- **Problem:** for any seed with a pet (every valid seed), `text` is overwritten with `rarity display \n $X/s`. That drops the `🛡` that marks the protected (unstealable) best pet, which was its only visual cue. The client just hides the Steal prompt on that plot (`client:2845`), so thieves get no explanation. The Gold/Shiny prefix and the kg value are lost too.
- **Fix:** build the pet text with the prefixes, e.g. `(protected and "🛡 " or "") .. (gold and "GOLD " or shiny and "SHINY " or "") .. pet.rarity .. " " .. pet.display .. "\n$" .. rate .. "/s"`.

### 3. [Medium] King Night countdown and shield status are gone from the HUD
- **Where:** `Patch.client.luau:731-733` and `:5540`.
- **Problem, timer chip:**
  - The old chip showed `KING NIGHT in mm:ss` from `KingWakesAt` outside Blood Moon. The new chip only shows the Day/Midnight `PhaseEnds` timer, and nothing else in the client reads `KingWakesAt`.
  - King Night runs on its own :00/:20/:40 schedule (`server:5212`), so players lose any countdown to the main event.
  - During Blood Moon the chip reads "☀ in <KingSeconds>", which is mislabelled.
- **Problem, King bar:** it always reads `PUMPKIN KING hp/max`. The `KingShield` state ("Bonk N lanterns" / "SHIELD x/y") and "WEAK SPOT x2" were removed from both the chip and the bar. Players see a bar that will not drop and no instruction; only the world-space bubble remains.
- **Fix:**
  - Outside Blood Moon, add a second line or the boost row with `"👑 King in " .. clockText(KingWakesAt - now)`.
  - During Blood Moon, show `"KING NIGHT " .. clockText(left)`.
  - In `refreshHpBar`, keep the size and colour from the spec but switch `wideText` to `"SHIELD: bonk %d lanterns"` while `KingShield` is set, and to "WEAK SPOT x2" while `KingStunned`.

### 4. [Medium-Low] Toasts overlap the RUN!! and Drop buttons
- **Where:** `Patch.client.luau:607`, with `Config.UI.toastY = 0.80` and `actionY = 0.70`.
- **Problem:** the toast holder is bottom-anchored at y 0.80 with height 0.12, and each toast is 0.28 of the holder (about 0.034 of the screen) plus padding. Two toasts reach y of about 0.73; three reach 0.68.
  - RUN!! spans x 0.39-0.49 and Drop spans x 0.51-0.61, both at y 0.70-0.755, so they sit inside the holder's x range of 0.28-0.72.
- **When it shows:** carrying or stealing is exactly when hints fire, so the text draws over the buttons.
- **Fix:** move the toasts under the action row, e.g. anchor (0.5, 0) at y 0.765 with height 0.12 so they grow downward, or set `toastY` to about 0.88. Keep x < 0.72 so the mobile jump area stays clear.

### 5. [Medium-Low] The new "my pen" house marker probably never renders
- **Where:** `Patch.client.luau:6677`.
- **Problem:** a BillboardGui is parented to `gui`, which is a ScreenGui. A LayerCollector nested inside another LayerCollector is not rendered; every other client billboard in this file is parented to PlayerGui or to a part (`:181`, `:235`, `:4298`).
- **Fix:** set `bb.Parent = player.PlayerGui`, or put it in a dedicated ScreenGui-free folder. Keep `Adornee = soil`.
- **Note:** this marker also duplicates the existing "⬇ YOUR BASE ⬇" billboard (`:2922-2947`). Consider replacing that one instead.
- **Note:** `utf8.char(8962)` "⌂" may not exist in FredokaOne; use an ImageLabel icon.
- **Verify in Studio.**

### 6. [Low] Hoard pumpkins lose their orange glow while they hatch
- **Where:** `Patch.server.luau:2371` then `:2384-2397`.
- **Problem:**
  - `Hoards.look` attaches the MysteryPumpkin look with a `LookGlow` PointLight.
  - Right after, `Bases.put` calls `Looks.attach(..., Config.MysteryModel, h)` with no glow arg, which destroys the old PetLook and its light.
  - `Looks.refit` then finds no `LookGlow` to carry forward.
- **Fix:** pass the glow, `extra and extra.hoard and C(255,170,70) or nil`, to that `Looks.attach`. Alternatively skip the second attach when `PetLook` already exists, and only rescale it.

### 7. [Low] Carry line shows the raw tool id: "RustySickle Scythe", "PumpkinKingCleaver Scythe"
- **Where:** `Patch.client.luau:993-998`.
- **Problem:** the `Tool` attribute is an id (`PatchConfig` `StartTool = "RustySickle"`, `WoodenScythe`, ...), so the line reads e.g. "WoodenScythe Scythe".
- **Fix:** look up `Config.Tools` by id and use `tool.name`, which is already "Rusty Scythe" and so on: `string.format("%s   Carry %d/%d", name, n, cap)`.

### 8. [Low] Padlocks reappear and an "unlock" puff fires on every login of an upgraded player
- **Where:** `Patch.server.luau:2009` and `:8299`.
- **Problem:**
  - On release, the Owner->0 watcher calls `slotLook(patch, baseSlots)`, which locks discs 7-10.
  - The next owner's `Progress.arrive` then calls `slotLook(10)`, so every login plays the 20-particle unlock puff on each upgraded disc. Players see "unlocked" again for things they already own.
- **Fix:** only puff when the owner's slot count actually grows during the session, e.g. pass a flag from `Progress.arrive` when `d.slots` increased compared with the pre-call `PenSlots` of the same owner. Do not use the `SlotLocked` history.

### 9. [Low] Locked-disc and "Upgrade" prices show "$25000" in raw dollars
- **Where:** `Patch.server.luau:2004` and `:2049`.
- **Problem:** the currency is candy, and every other price uses `short()` with 🍬 (e.g. the gate prompt at `:3787`). "$" reads as Robux or real money, and the value is not shortened.
- **Fix:** `"🔒 " .. short(cost) .. " 🍬"` and `"Upgrade " .. short(cost) .. " 🍬"`. `short` is already defined above `Bases`.

### 10. [Low] textLabel's AbsoluteSize hook overwrites callers' stroke thickness
- **Where:** `Patch.client.luau:403-405`.
- **Problem:** every `textLabel` now resets its UIStroke to 2 or 3 whenever AbsoluteSize changes. That happens after the caller's own setting, on the first layout and on every viewport or UIScale change.
- **Affected:** toasts (2.5, `:621`), the objective title (3), panel and reveal strokes, etc. These silently revert, so spec'd heavier strokes, such as the money counter at 3 px, can drop to 2 px on small screens.
- **Fix:** only apply the auto rule while the stroke still has the default thickness. For example, set an attribute `AutoStroke=true` in `textLabel` and clear it when a caller changes `Thickness`. Or apply the 2/3 rule once at creation and let callers override it.

## Notes (not bugs, worth knowing)
- `Progress.shiftStash` (`server:6489`) is now dead code since the slot re-layout block was removed.
- On the old 6-disc PatchMap, `Progress.arrive` still clones discs 7-10 at `plots[1] + RightVector * 8..32` with no re-layout. They can land outside the soil and fence. This is fine only if the live place uses the 10-disc Lobby build (`scene/Lobby.luau`).
- Each hatching pumpkin spawns 48 transparent Glass parts. A server with 8 full pens hatching can hold several thousand transparent parts; consider one mesh or SpecialMesh dome.
- Daily is no longer auto-granted on join. A player who never taps the Daily pill breaks their streak. The pill also stays hidden until the tutorial is done. This matches the spec but is a behaviour change.
