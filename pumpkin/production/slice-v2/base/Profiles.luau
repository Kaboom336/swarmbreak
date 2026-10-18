-- Small DataStore adapter, not the third-party ProfileStore package.
-- UpdateAsync lease prevents two servers loading the same key; errors never become a fresh save.
return function(C,D, backend, token, clock)
	local store={}
	function store:StartSessionAsync(key, now)
		local ok, record=pcall(function()
			return backend:UpdateAsync(key,function(old)
				if old and old.lease and old.lease.token~=token and old.lease.expires>clock() then return nil end
				local data=old and old.data or D.default(now)
				if not D.validate(data) then return nil end
				return {data=data,lease={token=token,expires=clock()+C.LeaseSeconds}}
			end)
		end)
		if not ok or not record or record.lease.token~=token then return nil end
		local p={Data=D.copy(record.data),active=true,expires=record.lease.expires}
		function p:IsActive() return self.active and clock()<self.expires end
		function p:write(ending)
			if not self:IsActive() or not D.validate(self.Data) then return false end
			local snapshot=D.copy(self.Data)
			local success,result=pcall(function()
				return backend:UpdateAsync(key,function(old)
					if not old or not old.lease or old.lease.token~=token or old.lease.expires<=clock() then return nil end
					local lease=nil
					if not ending then lease={token=token,expires=clock()+C.LeaseSeconds} end
					return {data=snapshot,lease=lease}
				end)
			end)
			if not success or not result then return false end
			if ending then self.active=false else self.expires=result.lease.expires end
			return true
		end
		function p:Save() return self:write(false) end
		function p:EndSession() return self:write(true) end
		return p
	end
	return store
end
