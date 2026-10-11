local fs = require("@lune/fs")
local luau = require("@lune/luau")
local function fixture(unavailable: boolean?)
	local config = table.clone(load("Config"))
	config.DataRetries = 2
	config.FirstRetryDelay = 0
	local store = { record = nil, fail = false, hook = nil }
	local clock = { now = 1000 }
	local serial = 0
	function store:UpdateAsync(_, callback)
		if self.fail then
			error("simulated datastore outage")
		end
		if self.hook then
			local hook = self.hook
			self.hook = nil
			hook()
		end
		local result = callback(self.record)
		if result ~= nil then
			self.record = result
		end
		return result
	end
	local shared = {}
	function shared:WaitForChild(name)
		return name
	end
	local services = {
		HttpService = {
			GenerateGUID = function()
				serial += 1
				return "fixture-incarnation-" .. serial
			end,
		},
		DataStoreService = {
			GetDataStore = function()
				if unavailable then
					error("simulated live store unavailable")
				end
				return store
			end,
		},
		RunService = {
			IsStudio = function()
				return false
			end,
		},
		ReplicatedStorage = {
			WaitForChild = function()
				return shared
			end,
		},
	}
	local gameMock = {
		JobId = "garden-unit-session",
		GetService = function(_, name)
			return services[name]
		end,
	}
	local env = setmetatable({
		os = setmetatable({
			time = function()
				return clock.now
			end,
		}, { __index = os }),
		game = gameMock,
		task = { wait = function() end },
		warn = function() end,
		require = function(name)
			return if name == "Config" then config else load(name)
		end,
	}, { __index = _G })
	local data = luau.load(
		fs.readFile("src/ServerStorage/Data.luau"),
		{ environment = env, debugName = "Data.integration" }
	)()
	return data, store, { UserId = 42, Name = "Tester" }, clock
end
test("data fences stale writer even when foreign session expired or unowned", function()
	for _, foreign in { { SessionId = "foreign", SessionExpiresAt = 0 }, {} } do
		local data, store, p = fixture()
		local profile = data.load(p)
		profile.Gold = 999
		foreign.Data = { Gold = 77 }
		store.record = foreign
		eq(data.save(p), false)
		eq(store.record, foreign)
		eq(store.record.Data.Gold, 77)
		eq(data.get(p), nil)
		eq(data.release(p), false)
		eq(store.record.Data.Gold, 77)
	end
end)
test("data final save failure retains dirty profile and later recovery releases", function()
	local data, store, p = fixture()
	local profile = data.load(p)
	profile.Gold = 123
	data.markDirty(p)
	store.fail = true
	eq(data.release(p), false)
	eq(data.get(p), profile)
	eq(data.get(p).Gold, 123)
	store.fail = false
	eq(data.release(p), true)
	eq(store.record.Data.Gold, 123)
	eq(store.record.SessionId, nil)
	eq(data.get(p), nil)
end)
test("data save snapshots once before yielded operation mutates live profile", function()
	local data, store, p = fixture()
	local profile = data.load(p)
	profile.Gold = 25
	store.hook = function()
		profile.Gold = 30
		data.markDirty(p)
	end
	eq(data.save(p), true)
	eq(store.record.Data.Gold, 25)
	eq(data.get(p).Gold, 30)
	eq(data.save(p), true)
	eq(store.record.Data.Gold, 30)
end)
test("data cannot create blank live profiles when store opening fails", function()
	local data, _, p = fixture(true)
	local profile, message = data.load(p)
	eq(profile, nil)
	eq(type(message), "string")
	eq(data.get(p), nil)
end)
test(
	"data replacement incarnation cannot claim pending unexpired orphan and old retry cannot overwrite takeover",
	function()
		local data, store, old, clock = fixture()
		local profile = data.load(old)
		profile.Gold = 999
		local oldToken = store.record.SessionId
		store.fail = true
		eq(data.release(old), false)
		store.fail = false
		local replacement = { UserId = old.UserId, Name = "Replacement" }
		eq(data.load(replacement), nil)
		eq(store.record.SessionId, oldToken)
		clock.now += 181
		eq(data.get(old), nil)
		local fresh = data.load(replacement)
		eq(type(fresh), "table")
		eq(store.record.SessionId ~= oldToken, true)
		fresh.Gold = 700
		eq(data.save(replacement), true)
		local newToken = store.record.SessionId
		eq(data.release(old), false)
		eq(store.record.SessionId, newToken)
		eq(store.record.Data.Gold, 700)
		eq(data.get(replacement).Gold, 700)
	end
)
test(
	"data expires confirmed lease during outage and safely renews only exact existing owner",
	function()
		local data, store, p, clock = fixture()
		local profile = data.load(p)
		profile.Gold = 81
		store.fail = true
		eq(data.save(p), false)
		clock.now += 179
		eq(data.get(p), profile)
		clock.now += 1
		eq(data.get(p), nil)
		eq(data.load(p), nil)
		store.fail = false
		eq(data.save(p), true)
		eq(data.get(p), profile)
		eq(store.record.Data.Gold, 81)
	end
)
test("data yielding old save cannot write or release a newer same-server incarnation", function()
	local data, store, old, clock = fixture()
	local profile = data.load(old)
	profile.Gold = 999
	local replacement = { UserId = old.UserId, Name = "Replacement" }
	store.hook = function()
		clock.now += 181
		eq(data.get(old), nil)
		local fresh = data.load(replacement)
		fresh.Gold = 321
		eq(data.save(replacement), true)
	end
	eq(data.save(old), false)
	eq(store.record.Data.Gold, 321)
	local token = store.record.SessionId
	eq(data.release(old), false)
	eq(store.record.SessionId, token)
	eq(data.get(replacement).Gold, 321)
end)
