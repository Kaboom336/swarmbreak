local Runtime = {}
function Runtime.create(config, domain, profiles, service, hooks)
	local RS = game:GetService("RunService")
	local SSS = game:GetService("ServerScriptService")
	local Players = game:GetService("Players")
	local ProfileStore = require(script.Parent.Packages.ProfileStore)
	local mock = RS:IsStudio() and not SSS:GetAttribute("CoreUseDataStore")
	-- Legacy custom envelopes cannot be passed directly to ProfileStore.
	local native = ProfileStore.New(config.Store .. "_ProfileStore", {})
	if mock then native=native.Mock end
	local legacy = not mock and game:GetService("DataStoreService"):GetDataStore(config.Store)
	local store = {volatile=mock}
	function store:StartSessionAsync(key, options)
		if not mock then
			while ProfileStore.DataStoreState=="NotReady" do task.wait(.1) end
			assert(ProfileStore.DataStoreState=="Access", "QA DataStore inaccessible; refusing volatile fallback")
		end
		return native:StartSessionAsync(key, options)
	end
	store.cancel = function(key)
		return not Players:GetPlayerByUserId(tonumber(key:match("%d+$")))
	end
	store.lost = function(key)
		local player=Players:GetPlayerByUserId(tonumber(key:match("%d+$")))
		if player then player:Kick("Save session ended. Please rejoin.") end
	end
	store.legacy = function(key)
		if not legacy then return domain.default() end
		local old=legacy:GetAsync(key)
		if old == nil then return domain.default() end
		assert(type(old)=="table" and type(old.data)=="table", "invalid legacy record")
		assert(not old.token or (type(old.expires)=="number" and old.expires<=os.time()),
			"legacy session still active; retire old servers before migration")
		local valid, why=domain.validate(old.data, config)
		assert(valid, why)
		return old.data
	end
	local token=game:GetService("HttpService"):GenerateGUID(false)
	return service.new(config, domain, profiles.new(store, config, domain, token, os.time, task.wait), hooks), token
end
return Runtime
