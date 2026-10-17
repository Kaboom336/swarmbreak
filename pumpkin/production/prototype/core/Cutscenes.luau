-- Presentation policy/lifecycle. Ports own only local UI, camera and scheduling.
local Cutscenes = {}
Cutscenes.Beats = {
	meadowArrival = { title = "MEADOW", duration = 3.2, path = "vista", priority = 1 },
	caveArrival = { title = "CRYSTAL CAVE", duration = 3.2, path = "vista", priority = 1 },
	keeper = { title = "THE KEEPER IS WATCHING", duration = 2, path = "warn", priority = 2 },
	acorn = { title = "STOLEN!", duration = 2, path = "orbit", payoff = true, priority = 3 },
	geode = { title = "STOLEN!", duration = 2, path = "orbit", payoff = true, priority = 3 },
	escape = { title = "ESCAPED!", duration = 2.4, path = "pull", payoff = true, priority = 5 },
	blast = { title = "BLAST OFF!", duration = 2.4, path = "blast", payoff = true, priority = 4 },
}
Cutscenes.Watchdog = 4.5

function Cutscenes.new(ports)
	local controller = { seen = {}, active = nil, previous = nil, destroyed = false }
	function controller:finish(reason, expected)
		local active = self.active
		if not active or (expected and active ~= expected) then
			return
		end
		self.active = nil -- Retire before cleanup, including callbacks from cancelled tweens.
		ports.finish(active, reason)
	end
	function controller:request(id, state)
		local beat = assert(Cutscenes.Beats[id], "unknown cutscene")
		local arrival = id == "meadowArrival" or id == "caveArrival"
		if self.destroyed or not state.alive or state.capture then
			return false
		end
		if not beat.payoff and (state.carry or state.danger) then
			return false
		end
		if self.seen[id] and not arrival then
			return false
		end
		if self.active and self.active.beat.priority >= beat.priority then
			return false
		end
		self:finish("superseded")
		local active = {
			id = id,
			beat = beat,
			duration = arrival and self.seen[id] and 2 or beat.duration,
			titleOnly = state.reduced or state.vr or state.otherCamera or state.moving,
			character = state.character,
			camera = state.camera,
			humanoid = state.humanoid,
		}
		self.active, self.seen[id] = active, true
		-- Arm recovery before presentation; failure to create a tween cannot strand a camera.
		ports.after(Cutscenes.Watchdog, function()
			self:finish("watchdog", active)
		end)
		ports.after(active.duration, function()
			self:finish("complete", active)
		end)
		local ok, why = pcall(ports.begin, active, state)
		if not ok then
			self:finish("error", active)
			if ports.warn then
				ports.warn(why)
			end
		end
		return ok
	end
	function controller:update(state)
		if self.destroyed then
			return
		end
		local active = self.active
		if active then
			if
				not state.alive
				or state.capture
				or active.character ~= state.character
				or active.camera ~= state.camera
				or active.humanoid ~= state.humanoid
			then
				self:finish("binding")
			elseif
				not active.beat.payoff
				and (state.carry or state.danger or (active.id == "meadowArrival" and state.phase ~= "Run"))
			then
				self:finish("unsafe")
			elseif (state.reduced or state.vr) and not active.titleOnly then
				active.titleOnly = true
				ports.titleOnly(active)
			end
		end
		local old = self.previous
		local arrival
		if state.biome == "meadow" then
			if state.phase == "Run" and (not old or old.phase ~= "Run" or not old.alive) then
				arrival = "meadowArrival"
			end
		elseif state.entry and (not old or not old.entry or not old.alive) then
			arrival = "caveArrival"
		end
		if arrival and state.alive then
			-- Spawn/portal replication can precede the first grounded frame. Allow only
			-- a short entry-local settling window, never a cinematic later in the run.
			local pending = { id = arrival, character = state.character }
			self.pendingArrival = pending
			ports.after(0.9, function()
				if self.pendingArrival == pending then
					self.pendingArrival = nil
				end
			end)
		end
		local pending = self.pendingArrival
		if pending then
			local inEntry = pending.id == "meadowArrival" and state.phase == "Run"
				or pending.id == "caveArrival" and state.entry
			if not inEntry or state.character ~= pending.character or state.carry or not state.alive then
				self.pendingArrival = nil
			elseif not state.danger then
				self.pendingArrival = nil
				self:request(pending.id, state)
			end
		end
		-- First snapshot never manufactures a steal/secure from late replicated state.
		if state.alive then
			if state.biome == "meadow" then
				if old and state.phase == "Run" and state.carry and not old.carry then
					self:request("acorn", state)
				end
				-- Count is published separately from phase. Remember it until Home arrives.
				if old and state.escapes > old.escapes then
					self.pendingEscape = true
				end
				if self.pendingEscape and state.phase == "Home" then
					self:request("escape", state)
					self.pendingEscape = nil
				end
				if state.phase == "Run" and state.spotted then
					self:request("keeper", state)
				end
			else
				if old and state.item and not old.item then
					self:request("geode", state)
				end
				if old and state.secured and state.secured ~= old.secured then
					self:request("escape", state)
				end
				if state.flight and (not old or not old.flight) then
					self:request("blast", state)
				end
			end
		end
		self.previous = state
	end
	function controller:Destroy()
		self.destroyed = true
		self:finish("destroyed")
	end
	return controller
end
return Cutscenes
