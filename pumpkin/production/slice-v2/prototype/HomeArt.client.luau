-- HOME-only presentation. Never creates LootId, consumes cargo, or delays input.
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Blocks = require(RS:WaitForChild("NativeBlocks"))
local Data = require(RS:WaitForChild("HomeArtGeometry"))
local CoreConfig = require(RS:WaitForChild("TreasureCore").Config)
local Style = require(RS:WaitForChild("UIStyle"))
local world = workspace:WaitForChild("GREYBOX")
local templates, pending, active = {}, {}, {}
local PET_SCALE = 1.6 -- >=4-stud pet height, inside the existing placement footprint.
local replacedHome = {
	CentralStonePath = true,
	CyanPortalDisc = true,
	LockedPortalDisc = true,
	PortalFoot = true,
	LockedPortalTerrace = true,
	TerraceLanding = true,
	LanternPost = true,
	LanternCap = true,
	LanternLight = true,
}
local function replaced(name)
	return replacedHome[name] or name:match("^PortalArchStone") or name:match("^TerraceStep")
end
local function petCaption(root, model, kind)
	local text, gui = Style.billboard(root, "HomePetCaption", UDim2.new(6, 36, 2.8, 18), 90, false)
	gui.Parent = model
	local _, bounds = model:GetBoundingBox()
	gui.StudsOffsetWorldSpace = Vector3.new(0, bounds.Y + 1, 0)
	text.RichText = true
	local tier = root:GetAttribute("PetTier")
	if tier then
		local rarity = CoreConfig.Rarities[tier]
		local color = Style.rarity(rarity)
		text.Text = (root:GetAttribute("PetName") or kind)
			.. '\n<font color="#' .. color:ToHex() .. '">* ' .. rarity.name .. '</font>'
			.. '\n<font color="#FFCF41">$ +'
			.. tostring(root:GetAttribute("PetRate") or 0)
			.. ' /s</font>'
		if tier > 1 then
			local outline = Instance.new("Highlight")
			outline.FillColor, outline.OutlineColor = color, color
			outline.FillTransparency, outline.OutlineTransparency = 0.92, 0.15
			outline.DepthMode, outline.Adornee, outline.Parent = Enum.HighlightDepthMode.Occluded, model, model
			local socket = Instance.new("Attachment")
			socket.Parent = root
			socket.Name = "CoreRaritySparkles"
			local particles = Instance.new("ParticleEmitter")
			particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			particles.Rate, particles.Lifetime, particles.Speed = 3, NumberRange.new(0.7, 1.2), NumberRange.new(1, 2)
			particles.Size = NumberSequence.new(0.2)
			particles.Color, particles.LightEmission = ColorSequence.new(color), 0.5
			particles.Parent = socket
			local light = Instance.new("PointLight")
			light.Color, light.Brightness, light.Range, light.Parent = color, 0.35, 6, socket
		end
		return
	end
	text.Text = kind
		.. '\n<font color="'
		.. (kind == "Crow" and "#42E9FF" or "#A5FF67")
		.. '">'
		.. (kind == "Crow" and "Rare" or "Common")
		.. "</font>\n+? coins/s"
	text.Parent = gui
end
local function destroy(entry)
	if entry.model then
		entry.model:Destroy()
	end
	if entry.burst then
		entry.burst:Destroy()
	end
end
local function template(name)
	if templates[name] then
		return templates[name]
	end
	-- Cache one native template per asset; every instance clones it.
	while pending[name] do
		task.wait()
	end
	if templates[name] then
		return templates[name]
	end
	pending[name] = true
	local model = Instance.new("Model")
	model.Name = "HomeArt_" .. name
	local ok, err = pcall(function()
		local count = 0
		for _, section in ipairs(Data[name]) do
			local neon = section.name == "PortalLight"
				or section.name == "PortalGreen"
				or section.name == "Cyan"
				or section.name == "LampLight"
				or section.name == "Lava"
			-- S8: this decorative home-vista seam reads as a stray orange pole
			-- from below Meadow. Retain geometry; mute only its cosmetic finish.
			if name == "Decor" and section.name == "Lava" then
				section = table.clone(section)
				section.color = { 143, 105, 69 }
				neon = false
			end
			local material = Enum.Material.SmoothPlastic
			if name == "Decor" then
				local id = section.name:lower()
				material = (id:find("wood") or id:find("brown")) and Enum.Material.WoodPlanks
					or (id:find("grass") or id:find("leaf") or id:find("green")) and Enum.Material.Grass
					or id:find("path") and Enum.Material.Cobblestone
					or Enum.Material.Slate
			end
			count += Blocks.section(section, model, CFrame.identity, neon and Enum.Material.Neon or material)
		end
		model.WorldPivot = CFrame.identity -- JSON origin is the feet, not bounding centre.
		Blocks.log("HomeArt " .. name, count)
	end)
	pending[name] = nil
	if not ok then
		model:Destroy()
		warn("[HomeArt] " .. name .. " geometry failed: " .. tostring(err) .. "; using emergency block build")
		model = Instance.new("Model")
		model.Name = "HomeArt_" .. name
		for _, section in ipairs(Data[name] or {}) do
			Blocks.section(
				{ name = section.name, color = section.color, vertices = section.vertices, triangles = {} },
				model,
				CFrame.identity,
				Enum.Material.Slate
			)
		end
		model.WorldPivot = CFrame.identity
	end
	templates[name] = model
	return model
end
local function clone(name)
	return template(name):Clone()
end
-- Local-only reusable mesh source for the Index's real pet silhouettes.
local preview = Instance.new("BindableFunction")
preview.Name, preview.Parent = "CorePetPreview", RS
preview.OnInvoke = clone
local function species(id)
	local sum = 0
	for i = 1, #id do
		sum += string.byte(id, i)
	end
	return sum % 2 == 0 and "Pup" or "Crow" -- Visual variation only; no rarity/economy claim.
end
local function burst(root)
	local socket = Instance.new("Attachment")
	socket.Name, socket.Parent = "HomeAcornReveal", root
	local sparkle = Instance.new("ParticleEmitter")
	sparkle.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparkle.Enabled, sparkle.Rate = false, 0
	sparkle.Lifetime, sparkle.Speed = NumberRange.new(0.45, 0.8), NumberRange.new(3, 7)
	sparkle.SpreadAngle, sparkle.LightEmission = Vector2.new(180, 180), 1
	sparkle.Color = ColorSequence.new(Color3.fromRGB(255, 222, 105))
	sparkle.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(1, 0),
	})
	sparkle.Parent = socket
	sparkle:Emit(24)
	local sound = Instance.new("Sound")
	sound.Name, sound.Volume, sound.RollOffMaxDistance = "HomeRevealPop", 0.45, 48
	-- Owner can set a cleared sound ID on HomeArtGeometry in Studio; no upload needed.
	sound.SoundId = RS.HomeArtGeometry:GetAttribute("RevealSoundId") or "rbxasset://sounds/electronicpingshort.wav"
	sound.Parent = socket
	if sound.SoundId ~= "" then
		sound:Play()
	end
	task.delay(2, function()
		socket:Destroy()
	end)
	return socket
end
local function acornGlow(model, summit)
	local anchor = Instance.new("Part")
	anchor.Name, anchor.Size, anchor.Transparency = "AcornGlowAnchor", Vector3.one, 1
	anchor.Anchored, anchor.CanCollide, anchor.CanQuery, anchor.CanTouch = true, false, false, false
	anchor.CFrame, anchor.Parent = CFrame.new(0, 2, 0), model
	local light = Instance.new("PointLight")
	light.Color, light.Brightness, light.Range = Color3.fromRGB(255,218,103), summit and 1.2 or 0.55, summit and 18 or 8
	light.Shadows = false
	light.Parent = anchor
	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparkles.Rate, sparkles.Lifetime, sparkles.Speed = summit and 9 or 3, NumberRange.new(0.8,1.6), NumberRange.new(0.5,1.5)
	sparkles.SpreadAngle, sparkles.LightEmission = Vector2.new(180,180), 0.7
	sparkles.Color, sparkles.Size = ColorSequence.new(light.Color), NumberSequence.new(0.22)
	sparkles.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(0.2,0.15),NumberSequenceKeypoint.new(1,1)})
	sparkles.Parent = anchor
	if summit then
		local a, b = Instance.new("Attachment"), Instance.new("Attachment")
		a.Position, b.Position = Vector3.new(0,4.8,0), Vector3.new(0,66,0)
		a.Parent, b.Parent = anchor, anchor
		local beam = Instance.new("Beam")
		beam.Name, beam.Attachment0, beam.Attachment1 = "SummitBeacon", a, b
		beam.FaceCamera, beam.Width0, beam.Width1 = true, 1.8, 3
		beam.Color, beam.LightEmission = ColorSequence.new(light.Color), 1
		beam.LightInfluence, beam.Brightness = 0.4, 0.45
		beam.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(0.15,0.92),NumberSequenceKeypoint.new(0.75,0.97),NumberSequenceKeypoint.new(1,1)})
		beam.Parent = anchor
	end
end
local function observe(root)
	if not root:IsA("BasePart") or not root:GetAttribute("LootId") or active[root] then
		return
	end
	local entry = { generation = 0 }
	active[root] = entry
	local function change()
		entry.generation += 1
		local generation = entry.generation
		destroy(entry)
		local oldFx = root:FindFirstChild("CoreRaritySparkles")
		if oldFx then
			oldFx:Destroy()
		end
		entry.model, entry.burst, entry.started, entry.kind = nil, nil, nil, nil
		entry.hidden = nil
		root.LocalTransparencyModifier = 0
		for _, gui in ipairs(root:GetDescendants()) do
			if gui:IsA("BillboardGui") then
				gui.Enabled = true
			end
		end
		local state = root:GetAttribute("LootState")
		local meadowAcorn = state == "Nest" or state == "Carried" or state == "Dropped"
		if state ~= "Secured" and state ~= "Placed" and not meadowAcorn then
			return
		end
		local isCore = root:GetAttribute("CoreState") ~= nil
		local isPet = isCore and root:GetAttribute("CoreState") == "Pet" or not isCore and state == "Placed"
		local kind = isPet and (root:GetAttribute("PetModel") or species(root:GetAttribute("LootId"))) or "Acorn"
		entry.kind = kind
		for _, caption in ipairs(root:GetDescendants()) do
			if caption:IsA("TextLabel") then
				caption.Text = kind == "Acorn" and "Golden Acorn" or kind
			end
		end
		-- Late join shows the current acorn without replaying an old celebration.
		local reveal = isCore
				and isPet
				and root:GetAttribute("RevealAt")
				and workspace:GetServerTimeNow() - root:GetAttribute("RevealAt") < 1
			or not isCore and state == "Secured" and entry.previous ~= nil and entry.previous ~= "Secured"
		entry.isPet = isPet
		entry.previous = state
		task.spawn(function()
			local ok, model = pcall(function()
				if meadowAcorn then return require(RS.MeadowV4.SummitAcorn).build() end
				return clone(reveal and "OpenAcorn" or kind)
			end)
			if not ok then
				warn("[HomeArt] mesh loader failed: " .. tostring(model))
				return
			end
			if active[root] ~= entry or generation ~= entry.generation or not root:IsDescendantOf(workspace) then
				model:Destroy()
				return
			end
			entry.model, entry.started = model, reveal and os.clock() or nil
			if meadowAcorn then
				-- Existing Style caption stays outside the shaft and follows carried loot.
				for _, gui in root:GetDescendants() do
					if gui:IsA('BillboardGui') then
						gui.StudsOffsetWorldSpace=Vector3.new(0,6.8,0)
						gui.AlwaysOnTop=true
						for _, text in gui:GetDescendants() do
							if text:IsA('TextLabel') then
								text.TextColor3=Style.Colors.Cream
								text.BackgroundColor3=Color3.fromRGB(34,39,46)
								text.BackgroundTransparency=.15
							end
						end
					end
				end
				acornGlow(model, state == "Nest")
				model:ScaleTo(state == "Nest" and 1.8 or 1.2)
				entry.beacon = model:FindFirstChild("SummitBeacon", true)
			end
			entry.fragments = {}
			if reveal then
				for _, piece in model:GetChildren() do
					if piece:IsA("BasePart") and (piece.Name == "CapBrown" or piece.Name == "StemBrown") then
						entry.fragments[piece] = model:GetPivot():ToObjectSpace(piece.CFrame)
					end
				end
			end
			if isPet and not reveal then
				model:ScaleTo(PET_SCALE)
				local pad = Instance.new("Part")
				pad.Name, pad.Size, pad.Position = "CosmeticPetPad", Vector3.new(5, 0.2, 5), Vector3.new(0, -0.1, 0)
				pad.Color, pad.Material = Color3.fromRGB(103, 119, 130), Enum.Material.Slate
				pad.Anchored, pad.CanCollide, pad.CanQuery, pad.CanTouch = true, false, false, false
				if not isCore then
					pad.Parent = model
				else
					pad:Destroy()
				end
				petCaption(root, model, kind)
				for _, gui in ipairs(root:GetDescendants()) do
					if gui:IsA("BillboardGui") then
						gui.Enabled = false
					end
				end
			end
			model:PivotTo(root.CFrame * CFrame.new(0, isPet and -1.25 or -1.5, 0))
			model.Parent = world
			root.LocalTransparencyModifier = 1
			for _, child in root:GetDescendants() do
				if child:IsA("BasePart") and (child.Name == "AcornCap" or child.Name == "AcornStem") then
					child.LocalTransparencyModifier = 1
				end
			end
			if reveal then
				entry.burst = burst(root)
			end
		end)
	end
	root:GetAttributeChangedSignal("LootState"):Connect(function()
		local previous = entry.previous
		change()
		entry.previous = root:GetAttribute("LootState") or previous
	end)
	for _, name in { "CoreState", "PetModel", "PetRate" } do
		root:GetAttributeChangedSignal(name):Connect(change)
	end
	change()
	entry.previous = root:GetAttribute("LootState")
end
-- Carried parts are parented to Characters, so observe all workspace descendants.
local function watch(root)
	observe(root)
	-- Attribute replication can follow DescendantAdded on a newly created loot root.
	if
		root:IsA("BasePart")
		and (root.Name == "LOOT" or root.Name == "Golden Acorn" or root.Name:match("^Placed_"))
		and not active[root]
	then
		root:GetAttributeChangedSignal("LootId"):Connect(function()
			observe(root)
		end)
	end
end
workspace.DescendantAdded:Connect(watch)
for _, root in ipairs(workspace:GetDescendants()) do
	watch(root)
end
task.spawn(function()
	local ok, decor = pcall(clone, "Decor")
	if not ok then
		warn("[HomeArt] decor loader failed: " .. tostring(decor))
		return
	end
	decor.Name, decor.Parent = "HomeArtDecor", world
	-- S9 decor finish only; pet/loot presentation and authoritative state are unchanged.
	local finishOK, finishError = pcall(function() require(RS.MeadowV4.Section9).finishDecor(decor) end)
	if not finishOK then warn("[HomeArt] S9 decor finish skipped: " .. tostring(finishError)) end
	for _, p in ipairs(world:GetDescendants()) do
		if
			p:IsA("BasePart")
			and p.Name:match("^Pen")
			and (p.Name:find("Rail") or p.Name == "PenPost" or p.Name == "PenAccessPath")
		then
			p.LocalTransparencyModifier = 1
		end
	end
	local home = world:WaitForChild("HomeFloatingIsland")
	for _, p in ipairs(home:GetDescendants()) do
		if p:IsA("BasePart") and (p.Name == "TreeTrunk" or p.Name:find("BlockCanopy")) then
			p.LocalTransparencyModifier = 1
		end
		if p:IsA("BasePart") and replaced(p.Name) then
			p.LocalTransparencyModifier = 1
			for _, gui in ipairs(p:GetDescendants()) do
				if gui:IsA("BillboardGui") then
					gui.Enabled = false
				end
			end
		end
	end
	for i, name in ipairs({ "Crystal Cave", "Frost Peak", "Volcano", "Ocean" }) do
		local anchor = Instance.new("Part")
		anchor.Name, anchor.Size, anchor.Transparency = "HomePortalName", Vector3.one, 1
		anchor.Anchored, anchor.CanCollide, anchor.CanQuery, anchor.CanTouch = true, false, false, false
		anchor.Position, anchor.Parent = Vector3.new(-66 + (i - 1) * 44, 36, -145), decor
		local text = Style.billboard(anchor, "DestinationCaption", UDim2.new(8, 24, 1.4, 8), 180, false)
		text.Text, text.TextColor3 = "> " .. name, Style.Colors.Cyan
	end
end)
RunService.RenderStepped:Connect(function()
	for root, entry in pairs(active) do
		if not root:IsDescendantOf(workspace) then
			destroy(entry)
			active[root] = nil
		elseif entry.model then
			if entry.beacon and entry.beacon.Parent then
				-- Five-second breath; widths include the approved 1.8x nest scale.
				local pulse = 1 + 0.07 * math.sin(os.clock() * math.pi * 2 / 5)
				entry.beacon.Width0, entry.beacon.Width1 = 1.8 * 1.8 * pulse, 3 * 1.8 * pulse
			end
			-- Recovery temporarily hides the authoritative loot; hide its cosmetics too.
			local hidden = root.Transparency >= 1
			if hidden ~= entry.hidden then
				entry.hidden = hidden
				for _, node in entry.model:GetDescendants() do
					if node:IsA("BasePart") then node.LocalTransparencyModifier = hidden and 1 or 0
					elseif node:IsA("Beam") or node:IsA("ParticleEmitter") or node:IsA("PointLight") then
						node.Enabled = not hidden
					end
				end
			end
			local t = entry.started and os.clock() - entry.started
			local scale = t and (1 + 0.22 * math.sin(math.min(t / 0.35, 1) * math.pi)) or 1
			if t then
				entry.model:ScaleTo(scale)
			end
			entry.model:PivotTo(
				root.CFrame
					* CFrame.new(
						0,
						(entry.kind ~= "Acorn" and -1.25 or -1.5)
							+ (t and 0.5 * math.sin(math.min(t, 1) * math.pi) or 0),
						0
					)
			)
			if t then
				local pop = math.clamp(t / 0.65, 0, 1) * 1.6
				for piece, localFrame in entry.fragments do
					piece.CFrame = entry.model:GetPivot()
						* CFrame.new(localFrame.Position * scale + Vector3.new(0, pop, 0))
						* localFrame.Rotation
				end
			end
			if t and t > 1 then
				entry.started = nil
				local generation = entry.generation
				task.spawn(function()
					local ok, model = pcall(clone, entry.isPet and entry.kind or "Acorn")
					if not ok then
						warn("[HomeArt] acorn loader failed: " .. tostring(model))
						return
					end
					if active[root] ~= entry or generation ~= entry.generation then
						model:Destroy()
						return
					end
					entry.model:Destroy()
					entry.model = model
					if entry.isPet then
						model:ScaleTo(PET_SCALE)
						petCaption(root, model, entry.kind)
						for _, gui in root:GetDescendants() do
							if gui:IsA("BillboardGui") then
								gui.Enabled = false
							end
						end
					end
					model.Parent = world
				end)
			end
		end
	end
end)
