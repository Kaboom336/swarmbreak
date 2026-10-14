-- Runtime dependencies are separate from the testable store/economy code.
local Runtime = {}
function Runtime.create(config, domain, profiles, service, hooks)
	local RunService = game:GetService("RunService")
	local SSS = game:GetService("ServerScriptService")
	local store
	-- Studio uses an isolated volatile store unless explicitly testing real QA saving.
	if not RunService:IsStudio() or SSS:GetAttribute("CoreUseDataStore") then
		local ok, result = pcall(function()
			return game:GetService("DataStoreService"):GetDataStore(config.Store)
		end)
		if ok then
			store = result
		end
	end
	if not store and RunService:IsStudio() and not SSS:GetAttribute("CoreUseDataStore") then
		store = { volatile = true, records = {} }
		function store:UpdateAsync(key, callback)
			local result = callback(domain.copy(self.records[key]))
			if result then
				self.records[key] = domain.copy(result)
			end
			return domain.copy(result)
		end
	end
	if not store then
		store = {}
		function store:UpdateAsync()
			error("DataStore unavailable; no default live profile")
		end
	end
	local token = game:GetService("HttpService"):GenerateGUID(false)
	return service.new(
		config,
		domain,
		profiles.new(store, config, domain, token, os.time, task.wait),
		hooks
	),
		token
end
return Runtime
