# FARM PLAN (merged, launch build)

Judged blind: X = Proposal A, Y = Proposal B.

| Criterion | X | Y |
|---|---|---|
| Satisfaction / feel | 8 | 6 (no swing variants) |
| Simplicity for tomorrow | 6 | 4 (28 skins, Ripe, Rainbow, pity, fountain) |
| Performance safety | 8 | 7 |
| Economy sanity | 5 | 3 |
| Zion's request coverage | 8 | 6 |
| **Overall** | **7.0** | **5.2** |

Taken from X: the 3-swing chain, hit-stop, the sound ladder, pooled chunks. Taken from Y: per-zone variety, crack stages, a bigger candy ladder (only from Zone 2 up), the chime on golden pumpkins.

## Code facts this plan is built on (checked)
- `Patch.server.luau` `Wild.spawnOne` (about line 3741) only ever spawns `"Orange"` or `"Golden"`. Each zone already has a `weights` table of pumpkin types (`Zones.ZoneN.weights`), and `makePumpkin(id)` has a model for every one of them. So we get variety for free.
- `Wild.hit` (about line 3888): it hits the nearest pumpkin in front within `BonkRange` 11. Tool order 3 and up also hits `Farm.arcTargets` 3 within `Farm.arcRange` 6 (dot >= 0.5). Crit is 10% x3. `pop` pays `CandyReward` = zone candy x big (25%, x6) x golden (1/40, x20).
- `BonkCooldown` 0.55 is read in four places: the client gate, the server gate, `Progress.bossCandy`, and the econ sim. **We do not change it.**
- Client `Patch.client.luau`: a single swing (`KEYS`, 0.42s), Whoosh at a random pitch, Bonk pitched `1.1 + 0.03*min(combo,10)`. There is already a 2s client `combo` counter (`countHit`).
- Performance debt: `play()` makes a new Sound on every call, `burst()` makes a new Attachment and ParticleEmitter on every call, `juice()` makes a new Highlight on every hit, and `candyBurst` makes 6-10 new Parts on every pop. All of this also runs for **every other player's** hits, because the server uses `FireAllClients`.
- Econ sim (I ran it against a scratch copy, without touching game code). Zone 2 arrives at 4.00 min against a target of 5, and the floor is 3.75 (tolerance 25%). **Any raise to Zone 1 candy fails**: x1.5 gives 3.52, and candy 2 with hp 15 gives 3.57. Zones 2-7 at x3 **pass**, and the arrivals barely move because pen income drives the gates.

## 1. Three swing variants, side to side (client only) [S]
`Patch.client.luau`, Scythe block: replace the single `KEYS` with `SWINGS = { FORE, BACK, SLAM }`. `swingTool(tool, step)` picks one.
- FORE (left to right, the existing keys): `{0,0,0},{0.08,38,-32},{0.18,-112,34},{0.27,-88,20},{0.42,0,0}`. Hit frame 0.16s. Trail on 0.07-0.30s.
- BACK (right to left, mirror the roll): `{0,0,0},{0.08,38,32},{0.18,-112,-34},{0.27,-88,-20},{0.42,0,0}`. Hit frame 0.16s.
- SLAM (overhead): `{0,0,0},{0.12,-150,0},{0.22,20,0},{0.30,10,0},{0.50,0,0}`. Hit frame 0.22s. Trail width x1.6 while it plays.
- Chain: if the next swing comes within `Config.Farm.chainWindow = 0.9`s of the last one, step = step % 3 + 1. Otherwise step = 1. Holding the mouse or a finger auto-repeats at the cooldown, using the existing `Activated` handler plus a held-input loop (`InputBegan`/`InputEnded`; mobile through the tool's `Activated` repeat).
- **The server is unchanged.** Every variant does the same damage at the same 0.55s cadence, so the economy stays neutral. CUT from X: the server combo step, 1.6x slam damage, 360-degree slam, cooldown 0.40, and area hits for every tier (all of these shifted DPS and King damage).

## 2. Impact stack (client) [S/M]
Predict the impact locally. At the variant's hit frame, call the existing `currentTarget(root)`. If it finds a target, play the impact there at once, then let `WildHit` add the damage number. Skip the Bonk in the `WildHit` handler when `hitAt[part]` was predicted less than 0.3s earlier.

| Layer | Normal | Crit | Break | SLAM hit | Golden break |
|---|---|---|---|---|---|
| Hit-stop (hold the swing clock, visuals only) | 40ms | 70ms | 90ms | 110ms | 140ms |
| Squash (existing `juice`) | 0.90 Y | 0.82 Y | burst | 0.85 Y | burst |
| Camera | none | `shake(0.3,4)` | `shake(0.4,5)` (exists) | `shake(0.6,6)` + FOV +4 for 120ms | FOV +6, gold screen flash 0.12s |
| Number | white | orange "CRIT" x1.3 size | "+N 🍬" (exists) | "x3 COMBO" (exists) | gold, big |

- Hit-stop: pause by adding the duration to `started` inside the swing's RenderStepped. Never yield, and never touch the server or Humanoid.
- Mobile (`TouchEnabled and not KeyboardEnabled`): shake and FOV at 60%, particle counts halved.

## 3. Sounds (client) [S]
New `Config.Sounds` keys: `Crunch` (a wet pumpkin crunch/squish) and `Chime` (a golden sparkle). Use free Roblox library audio only. If the id is 0, fall back to `Pick` at 1.3 and `Coin` at 1.5.
- Whoosh pitch by variant: FORE 1.0, BACK 1.08, SLAM 0.85, volume 0.5.
- Hit (Bonk): `1.0 + 0.05*min(combo,12)` (climbs to 1.6, then holds), volume `0.5 + 0.03*min(combo,12)`. Uses the existing 2s `combo`.
- Break: `Crunch` at `0.95 + 0.03*min(combo,12)`, plus `Coin` at 1.2 and volume 0.4. SLAM hits add `Bonk` at 0.55 (thud layer). Golden adds `Chime`.
- At most 2 sounds per event. **Sound pool**: rewrite `play()` to round-robin 8 preloaded Sound objects. Stop, set the id and pitch, then Play. No more `Instance.new` per sound.

## 4. Things to break: variety and crack stages [S]
- Server `Wild.spawnOne`: `id = golden and "Golden" or rollWeights(zoneDef.weights)`, skipping the `"Golden"` entry so only the bonus golden looks gold. hp and candy stay **zone based** (the skin is cosmetic). The burst colour already follows `seedColor(seed)`, and the name over the bar shows for order >= 3. Before shipping, grep that nothing treats a Wild part's `Seed` attribute as ownership; `pop` only pays candy.
- Crack stages without new art (client `juice`), from hp % (bar attribute `Hp`/`MaxHp`): at 66% and below, the colour darkens 15% and a 2-stud wobble is added. At 33% and below, it darkens 30%, jitters each hit, and sheds 2 chunks. Restore on respawn.
- Break: 6 shards from a **pool of 24 Parts** (seed colour, 0.5s arc), plus the existing burst and candy.
- CUT: crack decal art, 28 skins, chest skin, unique meshes.

## 5. Farming pays more [S, sim gated]
- PatchConfig `Zones`: candy for Zones 2-7 goes x3, hp unchanged: Z2 3→9, Z3 9→27, Z4 27→81, Z5 80→240, Z6 240→720, Z7 720→2160. **Zone 1 stays 1.** The first gate is locked at 1000 and any Zone 1 raise fails the sim. The Z1 pop already feels bigger through pitch, crunch and shards.
- Before tripling, save `z.baseCandy = z.candy` in a loop. In `Progress.bossCandy`, use `zone.baseCandy or zone.candy` so King Night payouts do not triple.
- Golden (1/40 x20): add the gold flash, the `Chime` and the 140ms hit-stop. Odds unchanged.
- CUT: server streak or combo candy multipliers (X's +40%, Y's up to x2), Ripe, Rainbow 1/400, pity, and the big/crit retune. Any of them would push Zone 1 past the sim floor.
- **Validate**: from `pumpkin\giant`, run `lune run scene/econ-sim.luau`. It must print `OK: ...` with Zone 2 at 4.00 min. If `lune` complains about the manifest, use `~/.rokit/tool-storage/lune-org/lune/0.10.5/lune.exe`.

## 6. Performance [M]
- Pool `burst()`: 8 Attachments under Terrain, each holding one emitter. Set Color, Size and Texture, then `Emit`. Round-robin, no Destroy.
- Pool `juice()` Highlights (4, reused). Roblox caps Highlights at 31.
- Pool `candyBurst` CandyBits (60 max live; overflow merges).
- For other players' `WildHit`/`WildPopped` events: skip juice, shards and sound when more than 60 studs from the camera. Particles at half.

## Effort and order
1. Swing variants + chain + hold-to-swing (S)
2. Sound pool + pitch ladder + Crunch/Chime (S)
3. Predicted impact + hit-stop + camera table (S)
4. Zone weights skins + candy x3 Z2-7 + baseCandy + sim (S)
5. Crack tint/wobble + pooled shards + burst/Highlight/candy pools (M)

## Acceptance tests (Studio, 2 players)
1. Clicking 3 times quickly gives left-to-right, right-to-left, then the overhead slam. A pause over 0.9s restarts at left-to-right. Holding the button swings on its own every 0.55s.
2. Each hit lands with a short freeze on the scythe. The slam shakes harder and thuds deeper.
3. A chain of 12 hits climbs audibly in pitch, then holds. A break plays a crunch plus a coin tick.
4. Zone 1 shows Orange, Sunny, Ghost and Moon pumpkins. Zone 3 shows Ghost, Moon and CandyCorn, and nothing gold except the sparkling 1/40 golden, which chimes and flashes.
5. A pumpkin darkens and wobbles at about 2/3 hp, and jitters and sheds chunks at about 1/3. On breaking it throws 6 shards.
6. A normal Zone 2 pop shows "+9 🍬". Zone 1 still shows "+1". The King Night payout is unchanged.
7. Farming 2 minutes with two players: the Workspace/SoundService instance count stays flat (no growth from Sounds, Attachments or Highlights), and frame time holds on the mobile emulator.
8. `lune run scene/econ-sim.luau` prints OK.
