local HumanoidEnemies = load("HumanoidEnemies")
local Theme = load("Theme")

local TARGET_HEIGHTS = {
	Walker = 10,
	Runner = 8,
	Spitter = 9,
	Brute = 18,
}

local function channel(value: number): number
	local normalized = value / 255
	if normalized <= 0.04045 then
		return normalized / 12.92
	end
	return ((normalized + 0.055) / 1.055) ^ 2.4
end

local function luminance(color: { number }): number
	return 0.2126 * channel(color[1]) + 0.7152 * channel(color[2]) + 0.0722 * channel(color[3])
end

local function contrast(a: { number }, b: { number }): number
	local lighter = math.max(luminance(a), luminance(b))
	local darker = math.min(luminance(a), luminance(b))
	return (lighter + 0.05) / (darker + 0.05)
end

test("humanoid enemy types have descriptions, readable colors, and G1 heights", function()
	for name, targetHeight in TARGET_HEIGHTS do
		local def = HumanoidEnemies.Defs[name]
		assert(def, name .. " must use a humanoid rig")
		assert(next(def.Description) ~= nil, name .. " needs a humanoid description")
		eq(def.BodyColor, Theme.Enemy[name].Body, name .. " body color comes from Theme")
		assert(contrast(def.BodyColor, Theme.Floor) >= 3, name .. " body color contrast")
		eq(def.Height, targetHeight, name .. " G1 target height")
	end
end)

test("creature enemy types do not use humanoid rigs", function()
	for _, name in { "Flyer", "Tank", "Queen", "Warden" } do
		eq(HumanoidEnemies.Defs[name], nil, name .. " remains a creature rig")
	end
end)

test("humanoid enemies use Roblox default R15 locomotion", function()
	eq(HumanoidEnemies.Animations.Walk, "rbxassetid://507777826", "default R15 walk")
	eq(HumanoidEnemies.Animations.Run, "rbxassetid://507767714", "default R15 run")
end)
