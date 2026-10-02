--!strict
-- Pure configuration for enemy types that use Roblox R15 humanoid rigs.
local Theme = require(script.Parent.Theme)

export type Definition = {
	Description: { [string]: number },
	BodyColor: { number },
	Height: number,
}

local function definition(
	name: string,
	height: number,
	description: { [string]: number }
): Definition
	return {
		Description = description,
		BodyColor = Theme.Enemy[name].Body,
		Height = height,
	}
end

local HumanoidEnemies = {
	Animations = {
		Walk = "rbxassetid://507777826",
		Run = "rbxassetid://507767714",
	},
	Defs = {
		Walker = definition("Walker", 10, {
			BodyTypeScale = 0.15,
			DepthScale = 1.1,
			HeadScale = 1.05,
			HeightScale = 1,
			ProportionScale = 0.15,
			WidthScale = 1.05,
		}),
		Runner = definition("Runner", 8, {
			BodyTypeScale = 0.35,
			DepthScale = 0.8,
			HeadScale = 0.9,
			HeightScale = 1.05,
			ProportionScale = 0.8,
			WidthScale = 0.75,
		}),
		Spitter = definition("Spitter", 9, {
			BodyTypeScale = 0.2,
			DepthScale = 1.15,
			HeadScale = 1.2,
			HeightScale = 0.95,
			ProportionScale = 0.25,
			WidthScale = 1,
		}),
		Brute = definition("Brute", 18, {
			BodyTypeScale = 0.1,
			DepthScale = 1.25,
			HeadScale = 0.95,
			HeightScale = 0.9,
			ProportionScale = 0,
			WidthScale = 1.25,
		}),
	},
}

return HumanoidEnemies
