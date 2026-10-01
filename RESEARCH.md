# Research: what the popular games do, and what Swarm Break should match

Date: 2026-09-30. Source-backed where a link is given; "estimate" where it is my read. Player counts move daily.

## 1. The big picture (Roblox charts, 2026)

| Game | Live players (sourced) | Genre | Why it holds people |
|---|---|---|---|
| Brookhaven RP | ~400k-510k | social roleplay | friends, freedom |
| Grow a Garden (1 and 2) | ~250k-500k | cozy sim + stealing | short loops, collection, friends steal from you |
| Blox Fruits | ~200k-350k | anime action RPG | progression, bosses, constant updates |
| 99 Nights in the Forest | ~290k | survival horror co-op | scaling nights, rescue your friends |
| RIVALS | ~130k-190k | FPS | unlockable weapons and cosmetics |
| Steal a Brainrot | ~150k | collection + PvP theft | passive income vs risk |
| Build and Kill Zombies | ~27k | **wave survival** | build a car, survive rounds (top of the zombie niche) |

Sources: [ejaw charts](https://ejaw.net/roblox-charts/), [MaxLevel 2026 list](https://www.maxlevelgg.com/news/ten-most-popular-roblox-games-in-twenty-twenty-six-based-on-concurrent-players/), [rblxdb zombie chart](https://rblxdb.com/best-roblox-games/zombie).

What they share: **friends first** (servers big enough to bring a group), **one loop you can explain in a sentence**, **something you own that grows** (pets, fruits, cars, weapons), **weekly updates**, and a **bright readable look** (stylized, not realistic).

## 2. Our niche: swarm / wave survival on Roblox

| Game | What it is (sourced) | Take for Swarm Break |
|---|---|---|
| **Final Swarm** (the Notion inspiration) | "Fight against hundreds of enemies at once... survive waves and defeat the Final Swarm." Action RPG, **20-player servers**, 2M+ visits. Currency **Keys** from waves and quests, spent on weapon upgrades, unlocks and **chests** (Wooden / Rare / Epic). Weapons split into DPS vs AoE roles; loadout slots; multiple **worlds** (Starter, Jungle). Limited cosmetic sets, group rewards. | Keys = our Gems. Chest tiers = our crate odds. Worlds = our later maps. Big servers = our lobby (30) and 8-player arenas. |
| **Survive The Swarm** | "Fight hundreds of enemies... Survive The Swarm and Defeat The Final Boss." **Six classes** (Warrior, Rogue, Mage, Ranger, Engineer, Healer). Weapons auto-attack; you move and **kite**; collect crystals to level up and **pick an upgrade each level**; "Evolution Index" forges gear; **lobby with character customization**; Infinite Dungeons endless mode; weekly updates; console support. Enemies are literally "cube insects". | Level-up choices mid-run (we have coin upgrades; add a pick-1-of-3 on wave clear). Evolution = our weapon evolution. Classes = a later "kits" feature. |
| **Bullet Heaven** (Vampire Survivors style) | "Survive endless hordes, build insane combos, level up, **evolve weapons**." Kits, multiple worlds, solo or co-op. In beta. | Same evolution idea; we do it with 4 elements so it stays simple. |
| **Build and Kill Zombies** | Wave survival where you roll parts and build a car to survive the horde. 27k live players. | Proof the wave loop works on Roblox when there is a **thing you build between waves**. Our "thing" = the weapon you evolve and the perks in the Base. |

Sources: [Final Swarm on Roblox](https://www.roblox.com/games/99521272836282/Final-Swarm), [final-swarm.wiki](https://final-swarm.wiki/), [finalswarmhub.wiki](https://finalswarmhub.wiki/), [Survive The Swarm on Roblox](https://www.roblox.com/games/100227226022278/Survive-The-Swarm), [survive-the-swarm.wiki](https://survive-the-swarm.wiki/), [Bullet Heaven on Roblox](https://www.roblox.com/games/87852743066035/Bullet-Heaven), [Build and Kill Zombies](https://www.roblox.com/games/105011592530400/Build-and-Kill-Zombies).

Note on videos: this cloud machine cannot open YouTube or TikTok (blocked), so I could not watch gameplay. The wikis and store pages above are text. The **best next step is on the laptop**: open Final Swarm, Survive The Swarm and Bullet Heaven in the Roblox app for 10 minutes each and screenshot the lobby, the shop and one boss. I can then compare frame by frame.

## 3. How the good-looking ones look (and what we are doing about it)

What players call "good looking" on Roblox is not realism. It is: chunky readable shapes, strong silhouettes, two-tone bodies with one glowing accent color, big particle effects, a dark arena with bright lights, and a UI that fits the theme. (Pocket Gamer's best-looking list is mostly lighting and effects, not polygon counts: [source](https://www.pocketgamer.com/roblox/best-looking-games/).)

Before (what you saw in the preview): boxes and cylinders welded together in code. Correct rigs, terrible look. Agreed.

Now: **real meshes made in Blender**, by script, in the cloud:

- 8 enemies, each split into rig parts (Torso, Head, Legs, Wings, Jaw) so the existing animation and Motor6D rig keep working. Dark chitin bodies, metal plates, glowing eyes, cores and sacs in each enemy's color.
- 15 weapons, chunky sci-fi, rarity-colored glow parts, separate orb models for the three orbital weapons.
- An arena kit: floor tiles, grates over the Nest glow, walls, pillars, crates, barrels, gate, boss gate, spawn holes with tendrils, railings, lamps, nest roots.
- Everything exports as FBX + GLB with vertex colors (Roblox imports both; no textures to upload). Renders are in `assets/renders/` and contact sheets in `assets/renders/*-sheet.png`.
- Triangle counts are under 5k per part (Roblox limit is 10k per MeshPart).

Still missing for the "cinematic" bar, in order: skinned animations (walk cycles made in Blender, imported as FBX animations), particle textures (a few PNGs: soft dot, spark, smoke ring), post effects (bloom, color grade, sun rays in Lighting), and one distinctive music track.

## 4. Design changes taken from the research

1. **Lobby first, then arenas** (Zion's call, and how Final Swarm and Survive The Swarm do it): Base with themed zones, 30 players; arenas of 8.
2. **Pick 1 of 3 on wave clear** (Survive The Swarm's level-up choice): built as wave reward cards (game/src/ReplicatedStorage/Shared/WaveRewards.luau: 12 cards, tap or keys 1-3 during the shop timer, auto-pick when it runs out). Keeps every run different.
3. **Chest tiers with visible odds** (Final Swarm): our crate already shows odds; add Rare and Epic crates later at higher prices.
4. **Classes / kits** (Survive The Swarm, Bullet Heaven): later, after retention data.
5. **Weekly updates**: both niche leaders promise it. Plan one small content drop per week after launch (a weapon, an enemy, or a map piece).
