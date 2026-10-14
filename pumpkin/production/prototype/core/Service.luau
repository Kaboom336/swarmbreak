local Service = {}
Service.__index = Service
function Service.new(config, domain, profiles, hooks)
	return setmetatable({
		config = config,
		domain = domain,
		profiles = profiles,
		hooks = hooks,
		keys = {},
		openers = {},
		taps = {},
		roots = {},
		holds = {},
		accumulated = 0,
	}, Service)
end
function Service:data(actor)
	local key = self.keys[actor]
	local session = key and self.profiles.sessions[key]
	return session and session.data
end
function Service:publish(actor)
	local data = self:data(actor)
	if not data then
		return
	end
	actor:SetAttribute("Coins", data.coins)
	actor:SetAttribute("PlotCoins", data.bank)
	actor:SetAttribute("CoinsPerSecond", self.domain.rate(data, self.config))
	actor:SetAttribute("CoreOpenReady", data.pending and data.pending.placed == true or false)
	actor:SetAttribute(
		"CoreSaveStatus",
		self.profiles.store.volatile and "STUDIO: UNSAVED"
			or (
				self.profiles:available(self.keys[actor]) and "Saving active" or "Saving / retrying"
			)
	)
	local names = {}
	for name in data.discovered do
		table.insert(names, name)
	end
	table.sort(names)
	actor:SetAttribute("PetDiscoveries", table.concat(names, "|"))
end
function Service:load(actor, state)
	local key = "player_" .. actor.UserId
	local data, why = self.profiles:load(key)
	if not data then
		return false, why
	end
	self.keys[actor] = key
	state.completed, state.meadowEscapes = data.escapes, data.escapes
	state.shieldUsed, state.firstHitUsed = data.shieldUsed, data.firstHitUsed
	for _, pet in data.pets do
		self.hooks.restore(actor, pet, true)
	end
	if data.pending then
		self.hooks.restore(actor, data.pending, false)
	end
	self:publish(actor)
	return true
end
function Service:canEnter(actor)
	local data = self:data(actor)
	return data
		and self.profiles:available(self.keys[actor])
		and not data.pending
		and #data.pets < self.config.MaxPets
end
function Service:secure(actor, item, state)
	return self.profiles:transaction(self.keys[actor], function(data)
		return self.domain.secure(data, self.config, item.id, item.rollTier, state)
	end)
end
function Service:place(actor, item, position, rotation, slot)
	local x, z = self.hooks.center(slot)
	local ok, why = self.profiles:transaction(self.keys[actor], function(data)
		return self.domain.place(data, item.id, position.X - x, position.Z - z, rotation)
	end)
	local session = self.profiles.sessions[self.keys[actor]]
	while not ok and session and session.uncertain and actor.Parent do
		task.wait(2)
		ok = self:save(actor, false)
	end
	return ok, why
end
function Service:decorate(actor, item, opened)
	local root = item.visual
	if not root then
		return
	end
	local data = self:data(actor)
	local pet = not opened and data.pending or nil
	if opened then
		for _, entry in data.pets do
			if entry.id == item.id then
				pet = entry
				break
			end
		end
	end
	if not pet then
		return
	end
	local rarity = self.config.Rarities[pet.tier]
	root:SetAttribute("CoreOwner", actor.UserId)
	root:SetAttribute("PetModel", rarity.model)
	root:SetAttribute("PetName", rarity.pet)
	root:SetAttribute("PetRarity", rarity.name)
	root:SetAttribute("PetTier", pet.tier)
	local rate = rarity.rate
	if opened and data.feed and data.pets[1].id == pet.id then
		rate += 1
	end
	root:SetAttribute("PetRate", rate)
	root:SetAttribute("CoreState", opened and "Pet" or "Acorn")
	root:SetAttribute("CorePlaced", pet.placed)
	if pet.placed and not root:FindFirstChild("CorePetPad") then
		local pad = Instance.new("Part")
		pad.Name, pad.Size, pad.CFrame =
			"CorePetPad", Vector3.new(4, 0.12, 4), root.CFrame * CFrame.new(0, -1.45, 0)
		pad.Anchored, pad.CanCollide, pad.CanQuery, pad.CanTouch = true, false, false, false
		pad.Color, pad.Material, pad.Parent =
			Color3.fromRGB(103, 119, 130), Enum.Material.Slate, root
	end
	self.roots[item.id] = root
	if not opened and pet.placed and not root:FindFirstChild("CoreOpenPoint") then
		local point = Instance.new("Attachment")
		point.Name, point.Parent = "CoreOpenPoint", root
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name, prompt.ActionText, prompt.ObjectText = "CoreOpen", "Open", "Golden Acorn"
		prompt:SetAttribute("CoreOwner", actor.UserId)
		prompt.KeyboardKeyCode, prompt.GamepadKeyCode = Enum.KeyCode.E, Enum.KeyCode.ButtonX
		prompt.HoldDuration, prompt.MaxActivationDistance, prompt.RequiresLineOfSight =
			self.config.OpenHold, 9, true
		prompt.ClickablePrompt, prompt.Parent = true, point
		local function begin(player)
			if player == actor and (self.hooks.openNear or self.hooks.near)(player, root) then
				self.holds[player] = { at = os.clock(), root = root }
			end
		end
		prompt.PromptButtonHoldBegan:Connect(begin)
		prompt.PromptButtonHoldEnded:Connect(function(player)
			local held = self.holds[player]
			task.delay(0.15, function()
				if self.holds[player] == held then
					self.holds[player] = nil
				end
			end)
		end)
		local function finish(player)
			local held = self.holds[player]
			self.holds[player] = nil
			if
				player ~= actor
				or not held
				or held.root ~= root
				or os.clock() - held.at < self.config.OpenHold - 0.05
				or not (self.hooks.openNear or self.hooks.near)(player, root)
			then
				return
			end
			local ok = self.profiles:transaction(self.keys[player], function(nextData)
				return self.domain.open(nextData, self.config, item.id)
			end)
			local session = self.profiles.sessions[self.keys[player]]
			while not ok and session and session.uncertain and player.Parent do
				task.wait(2)
				ok = self:save(player, false)
			end
			if ok and root.Parent then
				prompt:Destroy()
				root:SetAttribute("RevealAt", workspace:GetServerTimeNow())
				self:decorate(player, item, true)
				self.hooks.event:FireClient(
					player,
					"Reveal",
					rarity.pet,
					rarity.name,
					rate,
					item.id
				)
				self.hooks.goal(player, "Pet earns Coins / collect at your plot gate")
			end
			self:publish(player)
		end
		prompt.Triggered:Connect(finish)
		self.openers[item.id] = { begin = begin, finish = finish }
	end
end
function Service:tapOpen(actor)
	local data, state = self:data(actor), self.hooks.state(actor)
	if
		not data
		or not state
		or state.phase ~= "Home"
		or not data.pending
		or not data.pending.placed
		or not self.profiles:available(self.keys[actor])
	then
		return
	end
	local now = os.clock()
	if now - (self.taps[actor] or -math.huge) < 1 then
		return
	end
	self.taps[actor] = now
	local opener = self.openers[data.pending.id]
	if not opener then
		return
	end
	opener.begin(actor)
	-- One touch intent; the server checks the full 0.6-second dwell/range/sight.
	task.delay(self.config.OpenHold + 0.05, function()
		opener.finish(actor)
	end)
end
function Service:collect(actor, marker)
	local state = self.hooks.state(actor)
	if not state or state.phase ~= "Home" or not self.hooks.near(actor, marker) then
		return
	end
	local data = self:data(actor)
	if not data or data.bank <= 0 then
		return
	end
	local ok, amount = self.profiles:transaction(self.keys[actor], self.domain.collect)
	if ok and amount > 0 then
		self.hooks.event:FireClient(actor, "Collect", amount)
	end
	self:publish(actor)
end
function Service:tick(dt)
	-- Holds are checked each server frame, not just on Triggered/whole-second income ticks.
	for actor, held in self.holds do
		if not (self.hooks.openNear or self.hooks.near)(actor, held.root) then
			self.holds[actor] = nil
		end
	end
	self.accumulated += dt
	if self.accumulated < 1 then
		return
	end
	local seconds = math.floor(self.accumulated)
	self.accumulated -= seconds
	for actor, key in self.keys do
		local session = self.profiles.sessions[key]
		if self.profiles:available(key) then
			local data, state = self:data(actor), self.hooks.state(actor)
			if state then
				data.shieldUsed, data.firstHitUsed = state.shieldUsed, state.firstHitUsed
			end
			self.domain.tick(data, self.config, seconds)
		elseif
			session.busy
			and not session.uncertain
			and not session.closing
			and session.expires > self.profiles.now()
		then
			session.deferredBank = (session.deferredBank or 0)
				+ self.domain.rate(session.data, self.config) * seconds
		end
		self:publish(actor)
	end
end
function Service:save(actor, release)
	local key = self.keys[actor]
	if not key then
		return true
	end
	local session = self.profiles.sessions[key]
	if release then
		session.closing = true
	end
	local deadline = os.clock() + 20
	while session.busy and os.clock() < deadline do
		task.wait(0.05)
	end
	if not session.uncertain then
		local state = self.hooks.state(actor)
		if state then
			session.data.shieldUsed, session.data.firstHitUsed =
				state.shieldUsed, state.firstHitUsed
		end
	end
	local ok, why = self.profiles:save(key, release)
	if not ok then
		warn("[Core] " .. tostring(why))
	end
	if release and ok then
		self.keys[actor] = nil
		self.profiles.sessions[key] = nil
	end
	return ok
end
return Service
