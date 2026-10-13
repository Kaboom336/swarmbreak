-- Authoritative, non-yielding item transitions. Adapters provide live range/sight/floor checks.
local Rules = {}
function Rules.new(config)
	return { config = config, actors = {}, items = {}, serial = 0, active = nil }
end
function Rules.actor(r, actor)
	local s = {
		phase = "Home",
		mercy = 0,
		shield = 0,
		shieldUsed = false,
		firstHitUsed = false,
		completed = 0,
		cooldown = 0,
	}
	r.actors[actor] = s
	return s
end
function Rules.spawn(r, position)
	assert(not r.active, "unresolved provisional item")
	r.serial += 1
	local item = { id = "arena1:" .. r.serial, state = "Nest", position = position, version = 0 }
	r.items[item.id], r.active = item, item
	return item
end
function Rules.audit(r)
	local active = 0
	for id, item in r.items do
		assert(id == item.id, "identity corruption")
		local carriers = 0
		for actor, s in r.actors do
			if s.item == item then
				carriers += 1
				assert(
					item.holder == actor and (item.state == "Carried" or item.state == "Secured"),
					"duplication/illegal holder"
				)
			end
		end
		if item.state == "Carried" or item.state == "Secured" then
			assert(carriers == 1 and item.holder ~= nil, "LOOT lost/duplicated")
		else
			assert(carriers == 0 and item.holder == nil, "orphan carrier")
			assert(
				item.state == "Nest" or item.state == "Dropped" or item.state == "Placed" or item.state == "Retired",
				"lost state"
			)
		end
		if item.state == "Nest" or item.state == "Carried" or item.state == "Dropped" then
			active += 1
			assert(r.active == item, "provisional item lost")
		end
	end
	assert(active == (r.active and 1 or 0), "duplicated arena LOOT")
	return true
end
-- Deadline belongs to the original item through every drop and handoff.
function Rules.expire(r, now)
	local item = r.active
	if not item or not item.escapeDeadline or now < item.escapeDeadline then
		return false
	end
	if item.state ~= "Carried" and item.state ~= "Dropped" then
		return false
	end
	for _, s in r.actors do
		if s.item == item then
			s.item = nil
		end
		if s.hold and s.hold.item == item then
			s.hold = nil
		end
	end
	item.state, item.holder, item.position, item.settle = "Retired", nil, nil, nil
	item.version += 1
	r.active, r.respawnAt = nil, now + r.config.RespawnSeconds
	return true, item
end
function Rules.eligible(r, actor, action, target, now, check)
	local s, item = r.actors[actor], r.active
	if not s or s.phase ~= "Run" or s.item or not item then
		return false, "hands/arena/Taken"
	end
	if item.escapeDeadline and now >= item.escapeDeadline then
		return false, "escape expired"
	end
	if action == "Steal" then
		if item.state ~= "Nest" then
			return false, "Taken"
		end
	elseif action == "Grab" then
		if item.state ~= "Dropped" or now < item.settle then
			return false, "Taken/settling"
		end
	elseif action == "Bump" then
		local victim = r.actors[target]
		if not victim or victim.item ~= item or item.state ~= "Carried" or target == actor then
			return false, "carrier/Taken"
		end
		if now < s.shield or now < victim.shield or now < victim.mercy then
			return false, "FIRST RUN/mercy"
		end
	else
		return false, "unknown hold"
	end
	return check(actor, action, target, item)
end
function Rules.begin(r, actor, action, target, now, check)
	local s = r.actors[actor]
	if not s then
		return false, "unknown actor"
	end
	if action == "Bump" then
		if now < s.cooldown then
			return false, "Bump cooldown"
		end
		s.cooldown = now + r.config.BumpCooldown -- Includes refused/cancelled attempts.
	end
	local ok, reason = Rules.eligible(r, actor, action, target, now, check)
	if not ok or s.hold then
		return false, reason or "hold active"
	end
	s.hold = {
		action = action,
		target = target,
		began = now,
		item = r.active,
		version = r.active.version,
	}
	return true
end
function Rules.drop(r, actor, now, position)
	local s = r.actors[actor]
	local item = s and s.item
	if not item or item.state ~= "Carried" or not position then
		return false, "no valid floor/item"
	end
	s.item, s.hold = nil, nil
	item.state, item.holder, item.position, item.settle = "Dropped", nil, position, now + r.config.SettleSeconds
	item.version += 1
	return true, item
end
function Rules.hit(r, actor, source, now, position)
	local s = r.actors[actor]
	if not s or s.phase ~= "Run" or now < s.mercy or (source == "Pvp" and now < s.shield) then
		return false, "mercy"
	end
	local retain = r.config.GuardianFirstHitRetains
		and source == "Guardian"
		and s.item ~= nil
		and s.completed == 0
		and not s.firstHitUsed
	if s.item and not retain then
		local ok, why = Rules.drop(r, actor, now, position)
		if not ok then
			return false, why
		end
	end
	if source == "Guardian" and retain then
		s.firstHitUsed = true
	end
	s.mercy, s.slowUntil = now + r.config.MercySeconds, now + r.config.SlowSeconds
	s.hold = nil
	return true, retain
end
function Rules.finish(r, actor, action, now, check, dropPosition)
	local s = r.actors[actor]
	local hold = s and s.hold
	if not hold or hold.action ~= action or now - hold.began < r.config.HoldSeconds[action] then
		return false, "missing/short hold"
	end
	s.hold = nil
	if hold.item ~= r.active or hold.version ~= hold.item.version then
		return false, "Taken"
	end
	local ok, why = Rules.eligible(r, actor, action, hold.target, now, check)
	if not ok then
		return false, why
	end
	if action == "Bump" then
		return Rules.hit(r, hold.target, "Pvp", now, dropPosition(hold.target))
	end
	local item = hold.item
	if not item.firstPickup then
		item.firstPickup = now
		item.escapeDeadline = now + r.config.EscapeSeconds
	end -- Frozen through every handoff.
	item.state, item.holder, item.position = "Carried", actor, nil
	item.version += 1
	s.item, s.mercy, s.idleAt = item, now + r.config.MercySeconds, now
	if action == "Steal" and not s.shieldUsed then
		s.shieldUsed, s.shield = true, now + r.config.ShieldSeconds
	end
	return true, item
end
function Rules.secure(r, actor, now)
	local s = r.actors[actor]
	if not s or s.phase ~= "Run" then
		return false, "not in arena"
	end
	if s.item then
		local item = s.item
		if now >= item.escapeDeadline then
			return false, "escape expired"
		end
		assert(item == r.active and item.holder == actor and item.state == "Carried", "secure identity")
		item.state, item.securedAt, item.firstPup = "Secured", now, s.completed == 0
		item.version += 1
		r.active = nil
		r.respawnAt = now + r.config.RespawnSeconds
		s.completed += 1
	end
	s.phase, s.hold, s.shield = "Home", nil, 0
	return true
end
function Rules.place(r, actor)
	local s = r.actors[actor]
	local item = s and s.item
	if not s or s.phase ~= "Home" or not item or item.state ~= "Secured" then
		return false, "not secured"
	end
	s.item = nil
	item.state, item.holder = "Placed", nil
	item.version += 1
	return true, item
end
function Rules.retire(r)
	if r.active then
		local item = r.active
		if item.holder then
			r.actors[item.holder].item = nil
		end
		item.state, item.holder = "Retired", nil
		r.active = nil
	end
end
return Rules
