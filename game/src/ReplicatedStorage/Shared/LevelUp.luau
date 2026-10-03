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
	Evolution: string?,
}

export type ActionState = {
	RerollsUsed: number,
	BanishesUsed: number,
	Banished: { [string]: boolean },
}

local LevelUp = {}

LevelUp.WaveOneKillRate = 0.2 -- one Walker kill every 5 seconds in the opening wave
-- XP needed for each level. Early picks are frequent, then the requirement grows
-- steadily so rising weapon damage does not make late-run picks accelerate.
LevelUp.XpCurve = { 30, 45, 55, 80, 80, 80, 80 }
LevelUp.XpGrowthPerLevel = 10
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
LevelUp.CardDamageMultiplier = 0.5
LevelUp.CardProtectionSeconds = 6
LevelUp.FreeRerolls = 1
LevelUp.RerollLevelInterval = 5
LevelUp.BanishesPerRun = 2
LevelUp.SkipXpFraction = 0.10

function LevelUp.incomingDamage(
	damage: number,
	offerOpenedAt: number,
	now: number,
	cardsOpen: boolean
): number
	if cardsOpen and now - offerOpenedAt <= LevelUp.CardProtectionSeconds then
		return damage * LevelUp.CardDamageMultiplier
	end
	return damage
end

function LevelUp.requiredXp(level: number): number
	local wholeLevel = math.max(1, math.floor(level))
	if wholeLevel <= #LevelUp.XpCurve then
		return LevelUp.XpCurve[wholeLevel]
	end
	return LevelUp.XpCurve[#LevelUp.XpCurve]
		+ (wholeLevel - #LevelUp.XpCurve) * LevelUp.XpGrowthPerLevel
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
	rarityRolls: { number },
	banished: { [string]: boolean }?,
	excluded: { [string]: boolean }?,
	evolvedRecipe: string?
): { OfferCard }
	local ids = WaveRewards.offer(level, stacks, equippedKind, cardRolls, banished, excluded)
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
	local recipe = Evolutions.readyRecipe(stacks, equippedKind, evolvedRecipe)
	if recipe then
		table.insert(cards, 1, {
			Id = Evolutions.CardId,
			Rarity = "Legendary",
			Evolution = recipe.Id,
		})
		if #cards > WaveRewards.OfferSize then
			table.remove(cards)
		end
	end
	return cards
end

function LevelUp.newActionState(): ActionState
	return {
		RerollsUsed = 0,
		BanishesUsed = 0,
		Banished = {},
	}
end

function LevelUp.rerollsLeft(state: ActionState, level: number): number
	local earned = LevelUp.FreeRerolls
		+ math.floor(math.max(0, level) / LevelUp.RerollLevelInterval)
	return math.max(0, earned - state.RerollsUsed)
end

function LevelUp.useReroll(state: ActionState, level: number): boolean
	if LevelUp.rerollsLeft(state, level) <= 0 then
		return false
	end
	state.RerollsUsed += 1
	return true
end

function LevelUp.banishesLeft(state: ActionState): number
	return math.max(0, LevelUp.BanishesPerRun - state.BanishesUsed)
end

function LevelUp.banish(state: ActionState, id: string): boolean
	if state.Banished[id] or LevelUp.banishesLeft(state) <= 0 then
		return false
	end
	state.Banished[id] = true
	state.BanishesUsed += 1
	return true
end

function LevelUp.skipXp(level: number): number
	return math.floor(LevelUp.requiredXp(level + 1) * LevelUp.SkipXpFraction + 0.5)
end

-- Run chests use the existing Gem crate odds, then the shared crate pity rule.
function LevelUp.chestRarity(roll01: number, cratesSinceLegendary: number): string
	local crate = Weapons.Crates[LevelUp.ChestCrate]
	local rolled = Weapons.rollRarity(roll01, crate.Odds)
	return Weapons.applyPity(rolled, cratesSinceLegendary)
end

return LevelUp
