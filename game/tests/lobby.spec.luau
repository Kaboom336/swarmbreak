local Lobby = load("Lobby")

test("start pad requires three full seconds", function()
	eq(Lobby.StartPadSeconds, 3, "pad duration")
	assert(not Lobby.isPadReady(10, 12.99), "pad should still be charging")
	assert(Lobby.isPadReady(10, 13), "pad should start at three seconds")
end)

test("players are grouped into parties without exceeding the party size", function()
	local groups = Lobby.groupParties({ 8, 3, 5, 1, 2 })
	eq(#groups, 2, "party count")
	eq(#groups[1], Lobby.PartySize, "first party is full")
	eq(#groups[2], 1, "last party contains the remainder")

	local seen = {}
	for _, group in groups do
		assert(#group <= Lobby.PartySize, "party exceeds the configured size")
		for _, userId in group do
			assert(not seen[userId], "player grouped more than once")
			seen[userId] = true
		end
	end
	for _, userId in { 8, 3, 5, 1, 2 } do
		assert(seen[userId], "player missing from parties")
	end
end)

test("every lobby shop price is zero", function()
	assert(#Lobby.ShopItems > 0, "shop board needs at least one item")
	for _, item in Lobby.ShopItems do
		eq(item.Price, 0, item.Name .. " price")
	end
end)
