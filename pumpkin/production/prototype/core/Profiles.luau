-- Injectable UpdateAsync adapter. Same snapshot/revision is retried after an unknown write.
local Profiles = {}
Profiles.__index = Profiles
function Profiles.new(store, config, domain, token, now, wait)
	return setmetatable({
		store = store,
		config = config,
		domain = domain,
		token = token,
		now = now,
		wait = wait,
		sessions = {},
	}, Profiles)
end
function Profiles:retry(operation)
	local err
	for i = 1, self.config.Retries do
		local ok, result = pcall(operation)
		if ok then
			return true, result
		end
		err = result
		if i < self.config.Retries then
			self.wait(0.5 * 2 ^ (i - 1))
		end
	end
	return false, tostring(err)
end
function Profiles:load(key)
	if self.sessions[key] then
		return self.sessions[key].data
	end
	local ok, record = self:retry(function()
		return self.store:UpdateAsync(key, function(old)
			if old and old.token and old.token ~= self.token and old.expires > self.now() then
				return nil
			end
			local data = old and old.data or self.domain.default()
			local valid, why = self.domain.validate(data, self.config)
			assert(valid, why) -- Never silently replace damaged/future data.
			return {
				data = self.domain.copy(data),
				token = self.token,
				expires = self.now() + self.config.Lease,
				revision = old and old.revision or 0,
			}
		end)
	end)
	if not ok or not record or record.token ~= self.token then
		return nil, "load failed/session locked: " .. tostring(record)
	end
	self.sessions[key] = {
		data = self.domain.copy(record.data),
		revision = record.revision,
		expires = record.expires,
	}
	return self.sessions[key].data
end
function Profiles:commit(key, nextData, release)
	local session = self.sessions[key]
	local revision = session.revision + 1
	local snapshot = self.domain.copy(nextData)
	local ok, record = self:retry(function()
		return self.store:UpdateAsync(key, function(old)
			if not old then
				return nil
			end
			-- A response may be lost AFTER commit (including release). Reconcile that revision.
			if old.revision == revision and old.operation == self.token .. ":" .. revision then
				return old
			end
			if
				old.token ~= self.token
				or old.expires <= self.now()
				or old.revision ~= session.revision
			then
				return nil
			end
			return {
				data = self.domain.copy(snapshot),
				token = not release and self.token or nil,
				expires = not release and self.now() + self.config.Lease or 0,
				revision = revision,
				operation = self.token .. ":" .. revision,
			}
		end)
	end)
	if not ok or not record or record.operation ~= self.token .. ":" .. revision then
		return false, "save unacknowledged/session fenced: " .. tostring(record)
	end
	session.data, session.revision, session.expires =
		self.domain.copy(record.data), revision, record.expires
	-- Ordinary yielding saves must not erase online ticks accrued during the write.
	session.data.bank += session.deferredBank or 0
	session.deferredBank = 0
	return true
end
function Profiles:transaction(key, mutate)
	local session = self.sessions[key]
	if
		not session
		or session.busy
		or session.closing
		or session.uncertain
		or session.expires <= self.now()
	then
		return false, "profile busy/unavailable"
	end
	session.busy = true
	local nextData = self.domain.copy(session.data)
	local ran, ok, result = pcall(mutate, nextData)
	if not ran or not ok then
		session.busy = false
		return false, result or ok
	end
	local valid, why = self.domain.validate(nextData, self.config)
	if not valid then
		session.busy = false
		return false, why
	end
	local saved, errorMessage = self:commit(key, nextData, false)
	if not saved then
		-- Keep the exact pending snapshot; prohibit actions/income until reconciliation.
		session.uncertain = nextData
	else
		session.uncertain = nil
	end
	session.busy = false
	return saved, saved and result or errorMessage
end
function Profiles:save(key, release)
	local session = self.sessions[key]
	if not session or session.busy then
		return false, "profile busy"
	end
	session.busy = true
	local ok, why = self:commit(key, session.uncertain or session.data, release)
	if ok then
		session.uncertain = nil
	end
	session.busy = false
	return ok, why
end
function Profiles:available(key)
	local s = self.sessions[key]
	return s and not s.busy and not s.closing and not s.uncertain and s.expires > self.now()
end
return Profiles
