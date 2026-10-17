-- Client presentation only. Ports permit offline execution of the shipped mixer.
local Audio = {}
Audio.Cues = {
	Reveal = { 1840076509, "SFX", 0.65, 2.25 },
	Growl = { 9113980319, "SFX", 0.6, 1.2 },
	Escape = { 1839881844, "SFX", 0.8, 2 },
	Explosion = { 78012301000651, "SFX", 0.85, 3 },
	Click = { 127036696152728, "UI", 0.65, 0.2 },
	Pop = { 109359226723492, "UI", 0.55, 1.49 },
	Buy = { 134810204798705, "UI", 0.65, 2.09 },
}
Audio.Biomes = {
	meadow = { 1842172723, 9112835068, 0.22 },
	cave = { 1840777445, 9119386571, 0.1 },
}
function Audio.new(ports)
	local mixer = { groups = {}, pools = {}, loops = {}, owned = {}, tweens = {}, dead = false, duckUntil = 0 }
	local function own(class, parent, name)
		local node = ports.new(class)
		node.Name, node.Parent = name, parent
		table.insert(mixer.owned, node)
		return node
	end
	for name, volume in { Music = 0.35, SFX = 0.6, UI = 0.5, Ambience = 0.3 } do
		local group = own("SoundGroup", ports.service, name)
		group.Volume = volume
		mixer.groups[name] = group
	end
	local function fade(node, volume, duration)
		if mixer.tweens[node] then
			mixer.tweens[node]:Cancel()
		end
		mixer.tweens[node] = ports.tween(node, duration, { Volume = volume })
		mixer.tweens[node]:Play()
	end
	local function sound(id, group, volume, parent, looped, name)
		local s = own("Sound", parent or ports.service, name)
		s.SoundId, s.SoundGroup, s.Volume, s.Looped = "rbxassetid://" .. id, mixer.groups[group], volume, looped == true
		s.RollOffMinDistance, s.RollOffMaxDistance = 8, 100
		s.RollOffMode = ports.rolloff
		return s
	end
	function mixer:duck(seconds)
		self.duckUntil = math.max(self.duckUntil, ports.clock() + seconds)
	end
	function mixer:play(name, parent)
		if self.dead then
			return
		end
		local cue = assert(Audio.Cues[name], name)
		local pool = self.pools[name] or {}
		self.pools[name] = pool
		local slot
		for _, item in pool do
			-- Duplicate blast signals from one source are one audible event.
			if name == "Explosion" and item.sound.Parent == (parent or ports.service) and item.untilTime > ports.clock() then
				return
			end
			if not slot and item.untilTime <= ports.clock() then
				slot = item
			end
		end
		local limit = (name == "Growl" or name == "Reveal") and 1 or 6
		if name == "Growl" and not slot then
			slot = pool[1]
		end
		if not slot and #pool < limit then
			slot = { sound = sound(cue[1], cue[2], cue[3], parent, false, name), generation = 0 }
			table.insert(pool, slot)
		end
		if not slot then
			return
		end -- Drop excess voices, never interrupt gameplay.
		local s = slot.sound
		if not s.Parent then
			self.tweens[s] = nil
			for i, node in self.owned do
				if node == s then
					table.remove(self.owned, i)
					break
				end
			end
			s = sound(cue[1], cue[2], cue[3], parent, false, name)
			slot.sound = s
		end
		if self.tweens[s] then
			self.tweens[s]:Cancel()
		end
		local replacing = name == "Growl" and slot.untilTime and slot.untilTime > ports.clock()
		slot.generation += 1
		local generation = slot.generation
		slot.untilTime = ports.clock() + cue[4] + 0.2 + (replacing and 0.16 or 0)
		local function start()
			if self.dead or slot.generation ~= generation or not s.Parent then
				return
			end
			s:Stop()
			s.Parent, s.Volume = parent or ports.service, cue[3]
			s:Play()
			if name == "Reveal" or name == "Escape" or name == "Growl" then
				self:duck(cue[4])
			end
			ports.after(cue[4], function()
				if self.dead or slot.generation ~= generation or not s.Parent then
					return
				end
				fade(s, 0, 0.15)
				ports.after(0.16, function()
					if not self.dead and slot.generation == generation and s.Parent then
						s:Stop()
						s.Parent = ports.service
					end
				end)
			end)
		end
		if replacing then
			-- Fade, stop and reuse the same voice; never overlap two Growls.
			fade(s, 0, 0.15)
			ports.after(0.16, start)
		else
			start()
		end
		return s
	end
	function mixer:setBiome(biome)
		if self.dead or self.biome == biome then
			return
		end
		self.biome = biome
		for _, entry in self.loops do
			fade(entry.music, 0, 1.2)
			fade(entry.ambience, 0, 1.2)
		end
		local entry = self.loops[biome]
		if not entry then
			local data = assert(Audio.Biomes[biome], "unknown audio biome")
			entry = {
				music = sound(data[1], "Music", 0, nil, true, biome .. "Music"),
				ambience = sound(data[2], "Ambience", 0, nil, true, biome .. "Ambience"),
			}
			self.loops[biome] = entry
			entry.music:Play()
			entry.ambience:Play()
		end
		self.lastMusic = nil
		fade(entry.ambience, Audio.Biomes[biome][3], 1.2)
	end
	function mixer:update(carry, cutscene, musicMuted, sfxMuted)
		if self.dead then
			return
		end
		self.groups.Music.Volume = musicMuted and 0 or 0.35
		self.groups.SFX.Volume = sfxMuted and 0 or 0.6
		self.groups.UI.Volume = sfxMuted and 0 or 0.5
		self.groups.Ambience.Volume = sfxMuted and 0 or 0.3
		local volume = (carry and 1.1 or 1) * ((cutscene or ports.clock() < self.duckUntil) and 0.4 or 1)
		if self.biome and volume ~= self.lastMusic then
			self.lastMusic = volume
			fade(self.loops[self.biome].music, volume, 0.45)
		end
	end
	function mixer:cart(part, moving)
		if self.dead then
			return
		end
		self.carts = self.carts or {}
		local s = self.carts[part]
		if moving and not s then
			local count = 0
			for _ in self.carts do
				count += 1
			end
			if count >= 6 then
				return
			end
			s = sound(9113385140, "SFX", 0.35, part, true, "CartRolling")
			s.RollOffMaxDistance = 65
			self.carts[part] = s
			s:Play()
		elseif s and not moving then
			s:Stop()
			self.carts[part] = nil
			-- Keep the ownership list bounded when carts respawn.
			for i, node in self.owned do
				if node == s then
					table.remove(self.owned, i)
					break
				end
			end
			s:Destroy()
		end
	end
	function mixer:Destroy()
		self.dead = true
		for _, tween in self.tweens do
			tween:Cancel()
		end
		for i = #self.owned, 1, -1 do
			self.owned[i]:Destroy()
		end
		table.clear(self.owned)
		table.clear(self.pools)
	end
	return mixer
end
return Audio
