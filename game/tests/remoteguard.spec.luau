--!strict
local RemoteGuard = load("RemoteGuard")

local function newGuard()
	local now = 0
	local guard = RemoteGuard.new(function()
		return now
	end)
	return guard, function(value)
		now = value
	end
end

test("a burst is limited by the action capacity", function()
	local guard = RemoteGuard.new(function()
		return 10
	end)
	local player = {}
	for _ = 1, RemoteGuard.Policies.shop.Capacity do
		local allowed = guard:allow(player, RemoteGuard.Actions.Shop, "upgrade")
		eq(allowed, true, "request inside burst")
	end
	local allowed, retryAfter = guard:allow(player, RemoteGuard.Actions.Shop, "upgrade")
	eq(allowed, false, "request beyond burst")
	eq(retryAfter, 1, "retry time")
end)

test("refill accepts exactly on the token boundary", function()
	local guard, setNow = newGuard()
	local player = {}
	for _ = 1, RemoteGuard.Policies.code.Capacity do
		guard:allow(player, RemoteGuard.Actions.Code, "WELCOME")
	end

	setNow(1.999)
	local early, retryAfter = guard:allow(player, RemoteGuard.Actions.Code, "WELCOME")
	eq(early, false, "before boundary")
	eq(retryAfter > 0, true, "positive deterministic retry")

	setNow(2)
	local boundary = guard:allow(player, RemoteGuard.Actions.Code, "WELCOME")
	eq(boundary, true, "at boundary")
end)

test("actions have isolated buckets", function()
	local guard = RemoteGuard.new(function()
		return 0
	end)
	local player = {}
	for _ = 1, RemoteGuard.Policies.shop.Capacity do
		guard:allow(player, RemoteGuard.Actions.Shop, "upgrade")
	end
	local shopAllowed = guard:allow(player, RemoteGuard.Actions.Shop, "upgrade")
	local equipAllowed = guard:allow(player, RemoteGuard.Actions.Equip, "weapon")
	eq(shopAllowed, false, "shop exhausted")
	eq(equipAllowed, true, "equip remains available")
end)

test("malformed and oversized payloads are rejected without spending tokens", function()
	local guard = RemoteGuard.new(function()
		return 0
	end)
	local player = {}
	local longString = string.rep("x", RemoteGuard.Limits.MaxStringBytes + 1)
	local tooLarge = {}
	for index = 1, RemoteGuard.Limits.MaxTableEntries + 1 do
		tooLarge[index] = true
	end
	local cyclic = {}
	cyclic.self = cyclic

	eq(guard:allow(player, RemoteGuard.Actions.Settings, longString), false, "long string")
	eq(guard:allow(player, RemoteGuard.Actions.Settings, tooLarge), false, "large table")
	eq(guard:allow(player, RemoteGuard.Actions.Settings, cyclic), false, "cyclic table")
	eq(guard:allow(player, RemoteGuard.Actions.Settings, function() end), false, "bad type")

	for _ = 1, RemoteGuard.Policies.settings.Capacity do
		local allowed = guard:allow(player, RemoteGuard.Actions.Settings, { Music = true })
		eq(allowed, true, "invalid requests did not drain bucket")
	end
end)

test("clearing a player removes all of their buckets", function()
	local guard = RemoteGuard.new(function()
		return 0
	end)
	local player = {}
	for _ = 1, RemoteGuard.Policies.code.Capacity do
		guard:allow(player, RemoteGuard.Actions.Code, "WELCOME")
	end
	eq(guard:allow(player, RemoteGuard.Actions.Code, "WELCOME"), false, "bucket exhausted")
	guard:clear(player)
	eq(guard:allow(player, RemoteGuard.Actions.Code, "WELCOME"), true, "fresh after cleanup")
end)
