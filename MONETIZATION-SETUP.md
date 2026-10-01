# Monetization setup (Zion creates, Claude pastes IDs)

Where: https://create.roblox.com/dashboard/creations > Swarm Break > Monetization.
Roblox keeps 30% of every Robux sale (SOURCE: Roblox Creator Docs, Marketplace fee).
Prices below are ESTIMATES; typical for small survival games. Change any of them.

## Game passes (Monetization > Passes > Create)
| Name | Price (Robux) | What it does in the game |
|---|---|---|
| 2x Coins | 199 | Doubles coins from every kill |
| Extra Dash | 149 | Two dash charges instead of one |
| Starter Pack | 249 | Shotgun unlocked + 300 coins at the start of every run |

## Developer products (Monetization > Developer Products > Create)
| Name | Price (Robux) | What it does |
|---|---|---|
| 500 Coins | 49 | +500 coins now |
| 1,500 Coins | 129 | +1,500 coins now |
| Revive | 25 | Come back mid-wave (only charged if you are dead during a wave) |
| Weapon Crate | 99 | Random weapon. Odds shown in the shop: Common 65%, Rare 25%, Epic 8.5%, Legendary 1.5%. Legendary guaranteed by the 40th Robux crate. Duplicates give Gems: Common 30, Rare 80, Epic 200, Legendary 500. |
| Epic Crate | 299 (placeholder) | Odds: Rare 55%, Epic 35%, Legendary 10%. Legendary guaranteed by the 40th Robux crate. Duplicates give Gems as above. |

The Gem crate (150 Gems, odds Common 70%, Rare 25%, Epic 5%, never Legendary) is free: it is paid in Gems earned by playing, so it needs no product. The first boss a player beats also pays one free Gem crate.

## After creating
Each item shows an ID number on its page. Paste them in the thread like this:
```
DoubleCoins=123456789
ExtraDash=...
StarterPack=...
Coins500=...
Coins1500=...
Revive=...
WeaponCrate=...
EpicCrate=...
```
Claude writes them into `game/src/ReplicatedStorage/Shared/Monetization.luau`. Until then every ID is 0 and the shop says "Not for sale yet."

## Rules already handled in code
- Crate odds are displayed in the shop, with the pity rule in words (Roblox requires this for paid random items). Both Robux crates share one pity counter: the 40th Robux crate since the last Legendary is a Legendary.
- Receipts are only granted after the coins / weapon / revive is actually given.
- Revive is refused (no charge) when the player is alive or between waves.
