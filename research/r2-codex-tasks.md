# Codex wave 2 (Swarm Break, from Research round 2, 2026-10-01)

Same rules as research/codex-wave1.md: repo https://github.com/Kaboom336/swarmbreak, one branch per task (codex/<task>), push, do not merge. Run commands inside game/. Pure modules in game/src/ReplicatedStorage/Shared/ (no Roblox globals; server passes os.time() and positions as plain {x, z} tables); tests in game/tests/<name>.spec.luau using `load`, `test`, `eq` (style of tests/daily.spec.luau). --!strict Luau, plain English names, placeholder numbers marked `-- placeholder`. Read game/PITFALLS-LUAU.md first if it exists. Backlog numbers refer to COMPARISON.md "Research round 2" b.

## Task 1: Redeem codes with requirements (backlog #1)
Goal: codes that pay Gems / shards / a Gem crate, can require a best wave, expire, and redeem once per player.
Files: new Shared/Codes.luau (`Codes.Defs` keyed by upper-case code: { Reward = { Gems?, Shard?, Crate? }, MinWave?, ExpiresDay? }, `Codes.check(code, profile, today) -> (ok, reasonText)`, `Codes.redeem(profile, code, today) -> (profile, reward?)`, case-insensitive, trims spaces); ProfileSchema.luau adds `Redeemed: {[string]: boolean}` with sanitize; Shop.server.luau gets a `RedeemCode` remote calling Codes.redeem (rate limit 1 per 2 s).
Tests (tests/codes.spec.luau): unknown code refused; lower-case and padded input accepted; MinWave blocks until best wave reached; expired code refused; second redeem refused; reward copied, not shared; sanitize drops non-boolean Redeemed entries.
testcmd: stylua --check src tests && selene src && lune run tests/run.luau

## Task 2: "Boss in N waves" HUD chip (backlog #2)
Goal: the HUD always says when the next boss comes.
Files: WaveTable.luau (or Enemies.luau, wherever bossForWave lives) adds `wavesUntilBoss(wave) -> number` (0 on a boss wave, uses Config.BossEvery) and `bossChipText(wave) -> string` ("BOSS WAVE", "Boss next wave", "Boss in 3 waves"); Hud.client.luau shows the text in a small label under waveLabel.
Tests (tests/bosschip.spec.luau): waves 1..15 with BossEvery 5 give 4,3,2,1,0 pattern; texts for 0, 1, n; infinite waves past NormalWaves keep the pattern; changing Config.BossEvery in a copy changes the result.
testcmd: stylua --check src tests && selene src && lune run tests/run.luau

## Task 3: Spawn picker with player exclusion (backlog #3)
Goal: no enemy appears within 30 studs of any player; spawns stay spread.
Files: new Shared/SpawnPicker.luau (`SpawnPicker.ExcludeRadius = 30`, `pick(portals: {{x,z}}, players: {{x,z}}, roll01) -> index`: choose uniformly among portals farther than ExcludeRadius from every player; if none, return the portal with the largest min distance; deterministic for a given roll); WaveManager.server.luau randomSpawnCFrame passes portal and player positions. Also export `SpawnPicker.ChargeSeconds = 2` for the client telegraph (FX itself is not in scope).
Tests (tests/spawnpicker.spec.luau): no players -> any portal by roll; a player on a portal excludes it; all portals blocked -> farthest returned; roll 0 and 0.999 stay in range; empty portal list errors clearly.
testcmd: stylua --check src tests && selene src && lune run tests/run.luau

## Task 4: Arena layout as data, with spacing rules (backlog #4, #14)
Goal: Outpost 9 v2 positions live in one table that tests can check, so agents stop guessing placement.
Files: new Shared/ArenaLayout.luau with `Floor = 160`, `Spawns` (corner spawns at (+-58,+-58), edges at (0,-72),(72,0),(0,72),(-72,0)), `Bunkers` 20x6x20 at (+-66,+-66), `Ring` {OuterDiameter = 44, Height = 5, Thickness = 3, Gap = 10}, `Props` (24 clusters, sizes <= 5 tall), `Beacons`, and `playArea(players) -> number` (120 under 4 players, 160 at 4+); ArenaBuilder.server.luau reads the table (keep existing model.json parts working if the table is absent).
Tests (tests/arenalayout.spec.luau): every position on the 4-stud grid; props >= 18 apart and none within 25 of the ring edge; every prop height <= 5; spawns >= 10 studs from bunkers and inside the walls; spawns inside playArea(1) exist for the solo case; playArea(1)=120, playArea(4)=160.
testcmd: stylua --check src tests && selene src && lune run tests/run.luau

## Task 5: Feel budget (backlog #7)
Goal: one table that sizes hit stop, shake and damage numbers by event size, and caps numbers per second.
Files: new Shared/Feel.luau (`Feel.Events = { Hit, Crit, Kill, BossHit, BossKill }` each { FreezeMs, Shake, NumberScale }, FreezeMs 0 for Hit/Kill and 40-80 only for BossHit/Crit/BossKill; `Feel.NumberCapPerSecond = 20 -- placeholder`; `Feel.allowNumber(state, now) -> (state, boolean)` sliding 1 s window; `Feel.shakeFor(event, setting)` with setting "Off"|"Low"|"Full"); HitMarkers.client.luau and ClientFX.luau read it.
Tests (tests/feel.spec.luau): FreezeMs within 0..80 and 0 for Hit; Off setting gives 0 shake; Low < Full; cap allows exactly N in one second and resumes after the window; state not mutated in place.
testcmd: stylua --check src tests && selene src && lune run tests/run.luau

## Task 6: Telemetry events (backlog #8)
Goal: the funnel events we read after soft launch, defined in one place.
Files: new Shared/Telemetry.luau (`Telemetry.Events` names: RunStart, WaveReached, CardPicked, RunEnd, QuitMidRun, CrateOpened, CodeRedeemed, PurchasePrompted; `Telemetry.build(name, fields) -> {name, fields}` that rejects unknown names and unknown or non-number/string fields, rounds seconds to whole numbers); server calls via AnalyticsService (pcall) in WaveManager.server.luau and PlayerData.luau.
Tests (tests/telemetry.spec.luau): every event has a field list; unknown event errors; extra field rejected; seconds rounded; build output does not alias input.
testcmd: stylua --check src tests && selene src && lune run tests/run.luau

## Task 7: Co-play bonus and convenience passes (backlog #6, #11)
Goal: reward playing with friends and add the convenience-only product lineup.
Files: new Shared/CoPlay.luau (`coinMult(friendsInArena) -> number`, +10% per friend capped at +30% -- placeholder); Economy coin calculation multiplies by it; Monetization.luau adds QuickCrate, LuckyCrate, VIP, StarterPack, DoubleRunRewards entries with id 0 (Not for sale yet) and placeholder prices; nothing sells damage or health.
Tests (tests/coplay.spec.luau and additions to monetization.spec.luau): 0 friends = 1.0, cap holds at 5 friends, negative input treated as 0; every new product has id 0 and a label; no product entry carries a DamageMult or MaxHealth field.
testcmd: stylua --check src tests && selene src && lune run tests/run.luau
