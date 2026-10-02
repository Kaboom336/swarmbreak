--!strict
-- Pure level-up cadence, card rarity, and end-of-run chest rules.
local Evolutions = require(script.Parent.Evolutions)
local WaveRewards = require(script.Parent.WaveRewards)
local Weapons = require(script.Parent.Weapons)

export type EvolutionPreview = {
	Element: string,
	Tier: number,
	Label: string,
}

export type OfferCard = {
	Id: string,
	Rarity: string,
	Element: string?,
	Color: { number }?,
	OnHitEffect: string?,
	EvolutionPreview: EvolutionPreview?,
}

local LevelUp = {}

LevelUp.WaveOneKillRate = 0.2 -- one Walker kill every 5 seconds in the opening wave
-- XP needed for each level. Early picks are frequent; from wave 4 onward the
-- curve settles at 40 seconds per pick at the baseline kill rate below.
LevelUp.XpCurve = { 30, 35, 40, 80 }
LevelUp.KillXp = {
	Walker = 10,
	Runner = 10,
	Flyer = 12,
	Tank = 20,
	Spitter = 14,
	Brute = 50,
	Queen = 70,
	Warden = 90,
}
LevelUp.RarityOrder = { "Common", "Rare", "Epic", "Legendary" }
LevelUp.RarityOdds = {
	Common = 0.60,
	Rare = 0.27,
	Epic = 0.10,
	Legendary = 0.03,
}
LevelUp.ChestCrate = "Gem"
LevelUp.ChestRevealSeconds = 2.25
LevelUp.CardFlipSeconds = 0.12

function LevelUp.requiredXp(level: number): number
	local curveIndex = math.clamp(math.floor(level), 1, #LevelUp.XpCurve)
	return LevelUp.XpCurve[curveIndex]
end

function LevelUp.secondsAtWaveOneRate(level: number): number
	return LevelUp.requiredXp(level) / (LevelUp.KillXp.Walker * LevelUp.WaveOneKillRate)
end

function LevelUp.xpForKill(enemyType: string): number
	return LevelUp.KillXp[enemyType] or LevelUp.KillXp.Walker
end

function LevelUp.advance(level: number, xp: number, gainedXp: number): (number, number, number)
	local nextLevel = math.max(0, level)
	local remaining = math.max(0, xp) + math.max(0, gainedXp)
	local levelsGained = 0
	while remaining >= LevelUp.requiredXp(nextLevel + 1) do
		remaining -= LevelUp.requiredXp(nextLevel + 1)
		nextLevel += 1
		levelsGained += 1
	end
	return nextLevel, remaining, levelsGained
end

function LevelUp.rollRarity(roll01: number): string
	local remaining = math.clamp(roll01, 0, 1) -- 1 deliberately falls back to Legendary
	for _, rarity in LevelUp.RarityOrder do
		remaining -= LevelUp.RarityOdds[rarity]
		if remaining < 0 then
			return rarity
		end
	end
	return LevelUp.RarityOrder[#LevelUp.RarityOrder]
end

local function rolledElement(roll01: number): string
	local index = math.clamp(
		math.floor(math.clamp(roll01, 0, 0.999999) * #Evolutions.Order) + 1,
		1,
		#Evolutions.Order
	)
	return Evolutions.Order[index]
end

function LevelUp.offer(
	level: number,
	stacks: { [string]: number },
	equippedKind: string,
	cardRolls: { number },
	rarityRolls: { number }
): { OfferCard }
	local ids = WaveRewards.offer(level, stacks, equippedKind, cardRolls)
	local cards = {}
	for i, id in ids do
		table.insert(cards, {
			Id = id,
			Rarity = LevelUp.rollRarity(rarityRolls[i] or 0),
		})
	end
	if #cards > 0 and (level == 2 or level == 4) then
		local elementName = rolledElement(cardRolls[1] or 0)
		local element = Evolutions.Elements[elementName]
		if level == 2 then
			cards[1].Element = elementName
			cards[1].Color = element.Color
			cards[1].OnHitEffect = element.Tiers[2].Effect
		else
			cards[1].EvolutionPreview = {
				Element = elementName,
				Tier = 1,
				Label = element.Tiers[1].Label,
			}
		end
	end
	return cards
end

-- Run chests use the existing Gem crate odds, then the shared crate pity rule.
function LevelUp.chestRarity(roll01: number, cratesSinceLegendary: number): string
	local crate = Weapons.Crates[LevelUp.ChestCrate]
	local rolled = Weapons.rollRarity(roll01, crate.Odds)
	return Weapons.applyPity(rolled, cratesSinceLegendary)
end

return LevelUp
