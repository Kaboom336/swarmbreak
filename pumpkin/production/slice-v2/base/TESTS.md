# Test handoff

Status: offline assertions and serialized structure checks are recorded in OFFLINE-RESULT.txt and BUILD-RESULT.txt. Every Studio, visual, device, multiplayer and live persistence test below is **NOT RUN** by Codex. Do not infer runtime success from compilation.

## Offline (from production)

```powershell
lune run slice-v2/base/check.luau
lune run slice-v2/base/build.luau
```

If the Rokit shim says `home directory not found`, use the installed binary:

```powershell
& 'C:/Users/zerha/.rokit/tool-storage/lune-org/lune/0.10.5/lune.exe' run slice-v2/base/check.luau
& 'C:/Users/zerha/.rokit/tool-storage/lune-org/lune/0.10.5/lune.exe' run slice-v2/base/build.luau
```

The build compiles every local Luau source, creates a fresh DataModel, serializes/deserializes it, then runs BaseTest against the deserialized place with Lune Roblox types. No other slice is imported. `check` writes actual pass counts and a deterministic 10min simulation; the simulation uses fractional steps, active walking/collecting, seed 20261018 and plot 1. It also sweeps all eight plots with independent seeds. These are modeled timings, not a prediction for every human or random spawn sequence.

## Claude: Studio EDIT only

Open `steal-a-treasure-base.rbxl` in EDIT mode. Through Studio MCP `execute_luau` run:

```lua
assert(not game:GetService("RunService"):IsRunning(), "EDIT mode required")
return require(game.ServerScriptService.BaseTest)()
```

Checks actual Config/Rules loads, central spawn, eight plots, eighty anchored pedestals, four open per base, pads, entry positions, initial earner, Buy/Steal/Lock prompts, anchored server authority markers and remotes. Anchored earners have no client physics owner; ProximityPrompts themselves have no Roblox network-owner property. Attribute markers document the contract, and the server script implements validation. This module does not prove the running controller, touch events, HUD or network behavior. Claude never starts Play or plays.

## Zion: two-player local server, ten minutes

Use Studio Test → Start Server with **two players** yourself. Default Studio save backend is in-memory; it persists only while that server stays running. Keep live API access off for this test. Record actual times, cash and console errors.

1. Join A and B: distinct plots, $600 each, four open pedestals, two HUD buttons, no join popup. Start stopwatch. Follow the arrow; buy the $600 Compass. Record purchase, placement, first income and first collection; compare <30s reward and <120s placement. Step away and back onto Collect and then the $100 Unlock pad. Record first unlock; target ≤180s. Check cash at 2/5/10min against the modeled report, allowing different actions/rolls.
2. Watch carpet for 30s: spawns about every 3s, travels straight, despawns at far end. Read name, coloured rarity, price and $/s. Compete for the same Buy prompt: exactly one buyer pays and receives it. An unaffordable buy, distant buy or full-base buy must change nothing. Purchase multiple rapidly: different first-free pedestals must be reserved. Delivery through a locked barrier must work.
3. With fewer than three purchases: stealing against or by that player fails; lock and slap unavailable. Reach three purchases naturally for both players. Check exactly one unlock toast and Slap tool. No test-only cash grant is built in; a server-console grant may be used by Zion only if separately recorded as test setup.
4. A holds E on B's placed treasure for <2s, releases or moves >12 studs: fails. Hold for 2s while nearby: one carry, slow speed 10, RUN!! and Drop appear, B receives a toast. A walks home: treasure takes A's first free slot, B loses that slot's treasure, Index discovers it, normal speed returns. Two thieves must not carry the same treasure.
5. Repeat the theft; use Drop, reset, damage the carrier from the server console, disconnect carrier, or disconnect owner in separate cases. Each returns the item to its original slot, clears the reservation and restores speed. B equips Slap, approaches within 7 studs and clicks: only B's own stolen item is returned, at most once per 1.2s. Distant/unequipped activation does nothing.
6. B locks: A cannot enter from front, sides or back; B can enter and leave. A already inside is ejected. Trying to steal while locked fails. At 60s barrier opens; lock remains unavailable for another 60s. At 120s lock works again. Repeated presses never extend it.
7. Step on speed pad: costs $100, then $250, then $625; speed becomes 18, 20, 22; insufficient funds and max-level attempts change nothing. Step on unlock pad: only next slot unlocks; see updated price. Check no accidental multiple charge from one character's limbs.
8. Index shows exactly 25 entries, owned discoveries named, others ???; close works. Shop only toasts its placeholder. During carry the arrow points home. Death/rejoin does not duplicate HUD or tools. Watch the five-minute guaranteed Legendary and its reset.
9. On SERVER console, invoke the internal damage hook with `player.Character.Humanoid:TakeDamage(1)` and verify a carry drops. On a CLIENT console, send malformed, unknown, oversized, repeated or distant intents to `ReplicatedStorage.TreasureBase.Action`: no money/item/lock changes and no server errors. Try Steal without a real server-observed hold. Test teleporting during carry: it must return the item rather than completing delivery.
10. While server remains running, rejoin A: cash, slots, upgrades, discoveries, tutorial and owned pedestal records recover. Stopping the local server resets the mock by design. Do live save/offline tests only in a separately authorized private test universe with an isolated DataStore namespace. Never enable live data against production profiles for this plan.

## Persistence fault checks before any public release

Offline tests cover mock isolation, failed writes, exclusive sessions, live-adapter UpdateAsync failure, expired leases, takeover, stale token rejection, corrupt-save rejection and JSON roundtrip. Real API budgets, network retries and shutdown deadlines remain NOT RUN. Offline 1h cap is tested at 0/60/3600/36000s and future timestamps. Live reconnection/offline grants need a private-universe test.

Known launch blocker: theft changes two profiles; saves are individually leased but not a durable cross-profile transaction. A server crash or one failed save during theft can roll back one side. Prove a transfer journal/reconciliation scheme before using this greybox with valuable live inventories.
