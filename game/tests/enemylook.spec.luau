local Enemies = load("Enemies")
local Theme = load("Theme")

test("enemy body colors contrast with the floor", function()
	for name in Enemies.Defs do
		local palette = Theme.Enemy[name]
		assert(palette, name .. " needs an enemy palette")
		assert(
			Theme.luminanceContrast(Theme.Floor, palette.Body) >= 0.35,
			name .. " body is hard to read"
		)
	end
end)

test("every enemy has a readable relative height", function()
	for name, def in Enemies.Defs do
		if def.Boss then
			assert(def.Scale >= 4.68 and def.Scale <= 5.28, name .. " boss scale")
		elseif name == "Tank" then
			eq(def.Scale, 3.38, "Tank elite scale")
		else
			assert(def.Scale >= 1.2 and def.Scale <= 2, name .. " enemy scale")
		end
	end
	eq(Enemies.Defs.Walker.Scale, 2, "Walker height relative to player")
end)
