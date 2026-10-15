-- ProfileStore owns locking, retries, autosave and shutdown. Keep domain snapshots
-- separate while a save yields; acknowledge economy operations only after persistence.
local Profiles = {}
Profiles.__index = Profiles
function Profiles.new(store, config, domain, token, now, wait)
	return setmetatable({store=store, config=config, domain=domain, token=token,
		now=now, wait=wait, sessions={}}, Profiles)
end
function Profiles:load(key)
	if self.sessions[key] then return self.sessions[key].data end
	local ok, profile = pcall(function()
		return self.store:StartSessionAsync(key, {Cancel=function() return self.store.cancel and self.store.cancel(key) end})
	end)
	if not ok or not profile then return nil, "load failed/session locked" end
	local envelope = profile.Data
	if envelope.data == nil then
		if next(envelope) ~= nil then profile:EndSession(); return nil, "invalid save envelope" end
		local migrated, data = pcall(function()
			return self.store.legacy and self.store.legacy(key) or self.domain.default()
		end)
		if not migrated then profile:EndSession(); return nil, tostring(data) end
		envelope = {data=self.domain.copy(data), revision=0}
	end
	local valid, why = self.domain.validate(envelope.data, self.config)
	if not valid or not self.domain.finite(envelope.revision)
		or envelope.revision < 0 or envelope.revision % 1 ~= 0 then
		profile:EndSession()
		return nil, why or "invalid save revision"
	end
	profile.Data = self.domain.copy(envelope)
	local session = {profile=profile, data=self.domain.copy(envelope.data),
		revision=envelope.revision, expires=math.huge}
	self.sessions[key] = session
	profile.Data.data = session.data -- Restored pet ticks must be visible to native autosave.
	session.ended = profile.OnSessionEnd:Connect(function()
		session.expires = 0
		if self.store.lost then self.store.lost(key) end
	end)
	return session.data
end
function Profiles:commit(key, nextData, release)
	local s = self.sessions[key]
	if not s.profile:IsActive() then return false, "session ended" end
	local pending = s.pending or {data=self.domain.copy(nextData), revision=s.revision+1,
		operation=self.token .. ":" .. (s.revision+1)}
	s.pending = pending
	local acknowledged = false
	local function check(saved)
		if saved and saved.operation == pending.operation and saved.revision == pending.revision then
			acknowledged = true
		end
	end
	local connection = s.profile.OnAfterSave:Connect(check)
	check(s.profile.LastSavedData)
	s.profile.Data = self.domain.copy(pending)
	for _ = 1, self.config.Retries do
		if acknowledged or not s.profile:IsActive() then break end
		s.profile:Save()
		-- Save queues asynchronously; OnAfterSave is the acknowledgement, not Save's return.
		for _ = 1, 100 do
			if acknowledged or not s.profile:IsActive() then break end
			self.wait(0.05)
		end
	end
	connection:Disconnect()
	if not acknowledged or not s.profile:IsActive() then
		return false, "save unacknowledged/session ended"
	end
	s.data = self.domain.copy(pending.data)
	s.data.bank += s.deferredBank or 0
	s.deferredBank, s.pending, s.uncertain = 0, nil, nil
	s.revision = pending.revision
	-- Autosave must see ticks accrued during the acknowledged write too.
	s.profile.Data.data = s.data
	if release then
		s.ended:Disconnect()
		s.profile:EndSession()
		s.expires = 0
	end
	return true
end
function Profiles:transaction(key, mutate)
	local s = self.sessions[key]
	if not self:available(key) then return false, "profile busy/unavailable" end
	s.busy = true
	local nextData = self.domain.copy(s.data)
	local ran, ok, result = pcall(mutate, nextData)
	if not ran or not ok then s.busy=false; return false, result or ok end
	local valid, why = self.domain.validate(nextData, self.config)
	if not valid then s.busy=false; return false, why end
	local saved, err = self:commit(key, nextData, false)
	if not saved then s.uncertain=nextData end
	s.busy=false
	return saved, saved and result or err
end
function Profiles:save(key, release)
	local s = self.sessions[key]
	if not s or s.busy then return false, "profile busy" end
	s.busy=true
	local ok, why = self:commit(key, s.uncertain or s.data, release)
	if not ok then s.uncertain=s.uncertain or self.domain.copy(s.data) end
	s.busy=false
	return ok, why
end
function Profiles:available(key)
	local s = self.sessions[key]
	return s and s.profile:IsActive() and not s.busy and not s.closing
		and not s.uncertain and s.expires > self.now()
end
return Profiles
