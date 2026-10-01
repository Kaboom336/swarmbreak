local Monetization = load("Monetization")

test("id 0 never resolves to a product", function()
	eq(Monetization.productKeyForId(0), nil, "zero")
	eq(Monetization.productKeyForId(123456), nil, "unknown")
end)

test("every pass and product has a name", function()
	for key, p in Monetization.GamePasses do
		assert(type(p.Name) == "string" and #p.Name > 0, key)
		assert(type(p.Id) == "number", key .. " id")
	end
	for key, p in Monetization.DeveloperProducts do
		assert(type(p.Name) == "string" and #p.Name > 0, key)
		assert(type(p.Id) == "number", key .. " id")
	end
	assert(Monetization.DeveloperProducts.Coins500.Coins == 500, "coin pack amount")
end)

local Weapons = load("Weapons")

test("the Epic crate is a product and every Robux crate names a real product", function()
	local epic = Monetization.DeveloperProducts.EpicCrate
	assert(epic and type(epic.Name) == "string" and #epic.Name > 0, "EpicCrate")
	for key, crate in Weapons.Crates do
		if crate.Product then
			assert(Monetization.DeveloperProducts[crate.Product], key .. " names a missing product")
		end
	end
end)
