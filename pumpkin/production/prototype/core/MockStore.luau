-- Offline ProfileStore contract fixture. Studio also tests the real .Mock store.
local MockStore = {}
function MockStore.new(domain)
	local store={records={}, active={}, failBefore=0, failAfter=0}
	local function signal()
		local listeners={}
		return {
			Connect=function(_, fn)
				listeners[fn]=true
				return {Disconnect=function() listeners[fn]=nil end}
			end,
			Fire=function(_, ...)
				for fn in listeners do fn(...) end
			end,
		}
	end
	function store:StartSessionAsync(key)
		if self.active[key] then return nil end
		local profile={Data=domain.copy(self.records[key] or {}), LastSavedData=domain.copy(self.records[key] or {}),
			OnAfterSave=signal(), OnSessionEnd=signal()}
		self.active[key]=profile
		function profile:IsActive() return store.active[key]==self end
		function profile:Save()
			if not self:IsActive() then return end
			if store.onWrite then store.onWrite() end
			if store.failBefore>0 then store.failBefore-=1; return end
			store.records[key]=domain.copy(self.Data)
			if store.failAfter>0 then store.failAfter-=1; return end
			self.LastSavedData=domain.copy(self.Data)
			self.OnAfterSave:Fire(self.LastSavedData)
		end
		function profile:EndSession()
			if self:IsActive() then self:Save(); store.active[key]=nil; self.OnSessionEnd:Fire() end
		end
		return profile
	end
	return store
end
return MockStore
