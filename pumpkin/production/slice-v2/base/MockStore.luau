-- Local adaptation of prototype/core/MockStore's ProfileStore-style session contract.
-- No vendor package is imported. Faults occur before a write; live adapter also fails closed.
return function(D)
	local store={records={},active={},failWrites=false}
	function store:StartSessionAsync(key, now)
		if self.active[key] then return nil end
		local p={Data=D.copy(self.records[key] or D.default(now)),active=true}
		self.active[key]=p
		function p:IsActive() return self.active end
		function p:Save()
			if not self.active or store.failWrites or not D.validate(self.Data) then return false end
			store.records[key]=D.copy(self.Data)
			return true
		end
		function p:EndSession()
			if not self:Save() then return false end
			self.active=false; store.active[key]=nil
			return true
		end
		return p
	end
	return store
end
