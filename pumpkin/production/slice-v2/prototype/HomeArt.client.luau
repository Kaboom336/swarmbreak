-- HOME-only presentation. Never creates LootId, consumes cargo, or delays input.
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local AssetService = game:GetService("AssetService")
local Data = require(RS:WaitForChild("HomeArtGeometry"))
local CoreConfig = require(RS:WaitForChild("TreasureCore").Config)
local world = workspace:WaitForChild("GREYBOX")
local templates, retained, pending, active = {}, {}, {}, {}
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
	local gui = Instance.new("BillboardGui")
	gui.Name, gui.Adornee = "HomePetCaption", root
	gui.Size, gui.StudsOffsetWorldSpace = UDim2.fromOffset(200, 84), Vector3.new(0, 14, 0)
	gui.MaxDistance, gui.AlwaysOnTop, gui.Parent = 650, false, model
	local text = Instance.new("TextLabel")
	text.Size, text.BackgroundTransparency = UDim2.fromScale(1, 1), 1
	text.Font, text.TextSize = Enum.Font.GothamBold, 20
	text.RichText = true
	text.TextColor3, text.TextStrokeTransparency = Color3.new(1, 1, 1), 0.15
	local tier = root:GetAttribute("PetTier")
	if tier then
		local rarity = CoreConfig.Rarities[tier]
		text.Text = (root:GetAttribute("PetName") or kind)
			.. "\n"
			.. rarity.name
			.. "\n+"
			.. tostring(root:GetAttribute("PetRate") or 0)
			.. " Coins/s"
		text.TextColor3 = Color3.fromRGB(table.unpack(rarity.color))
		local _, bounds = model:GetBoundingBox()
		gui.StudsOffsetWorldSpace = Vector3.new(0, bounds.Y + 0.5, 0)
		gui.MaxDistance = 90
		if tier > 1 then
			local outline = Instance.new("Highlight")
			outline.FillColor, outline.OutlineColor = text.TextColor3, text.TextColor3
			outline.FillTransparency, outline.OutlineTransparency = 0.92, 0.15
			outline.DepthMode, outline.Adornee, outline.Parent =
				Enum.HighlightDepthMode.Occluded, model, model
			local socket = Instance.new("Attachment")
			socket.Parent = root
			socket.Name = "CoreRaritySparkles"
			local particles = Instance.new("ParticleEmitter")
			particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			particles.Rate, particles.Lifetime, particles.Speed =
				3, NumberRange.new(0.7, 1.2), NumberRange.new(1, 2)
			particles.Size = NumberSequence.new(0.2)
			particles.Color, particles.LightEmission = ColorSequence.new(text.TextColor3), 0.5
			particles.Parent = socket
			local light = Instance.new("PointLight")
			light.Color, light.Brightness, light.Range, light.Parent =
				text.TextColor3, 0.35, 6, socket
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
	-- Serialize template creation, since mesh API calls yield.
	while pending[name] do
		task.wait()
	end
	if templates[name] then
		return templates[name]
	end
	pending[name] = true
	local model = Instance.new("Model")
	model.Name = "HomeArt_" .. name
	local meshes = {}
	local ok, err = pcall(function()
		for _, section in ipairs(Data[name]) do
			local mesh =
				assert(AssetService:CreateEditableMesh(), "EditableMesh memory unavailable")
			table.insert(meshes, mesh)
			local lo, hi =
				Vector3.new(math.huge, math.huge, math.huge),
				Vector3.new(-math.huge, -math.huge, -math.huge)
			for _, vertex in ipairs(section.vertices) do
				local v = Vector3.new(table.unpack(vertex))
				lo, hi = lo:Min(v), hi:Max(v)
			end
			local centre, ids = (lo + hi) / 2, {}
			for i, vertex in ipairs(section.vertices) do
				ids[i] = mesh:AddVertex(Vector3.new(table.unpack(vertex)) - centre)
			end
			for _, tri in ipairs(section.triangles) do
				mesh:AddTriangle(ids[tri[1] + 1], ids[tri[2] + 1], ids[tri[3] + 1])
			end
			local part = AssetService:CreateMeshPartAsync(Content.fromObject(mesh))
			part.Name, part.Color = section.name, Color3.fromRGB(table.unpack(section.color))
			local neon = section.name == "PortalLight"
				or section.name == "PortalGreen"
				or section.name == "Cyan"
				or section.name == "LampLight"
				or section.name == "Lava"
			part.Material = neon and Enum.Material.Neon or Enum.Material.SmoothPlastic
			part.Anchored, part.CanCollide, part.CanQuery, part.CanTouch = true, false, false, false
			part.CFrame, part.Parent = CFrame.new(centre), model
		end
		model.WorldPivot = CFrame.identity -- JSON origin is the feet, not bounding centre.
	end)
	pending[name] = nil
	if not ok then
		model:Destroy()
		for _, mesh in ipairs(meshes) do
			mesh:Destroy()
		end
		error(err)
	end
	templates[name], retained[name] = model, meshes
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
	sound.SoundId = RS.HomeArtGeometry:GetAttribute("RevealSoundId")
		or "rbxasset://sounds/electronicpingshort.wav"
	sound.Parent = socket
	if sound.SoundId ~= "" then
		sound:Play()
	end
	task.delay(2, function()
		socket:Destroy()
	end)
	return socket
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
		root.LocalTransparencyModifier = 0
		for _, gui in ipairs(root:GetDescendants()) do
			if gui:IsA("BillboardGui") then
				gui.Enabled = true
			end
		end
		local state = root:GetAttribute("LootState")
		if state ~= "Secured" and state ~= "Placed" then
			return
		end
		local isCore = root:GetAttribute("CoreState") ~= nil
		local isPet = isCore and root:GetAttribute("CoreState") == "Pet"
			or not isCore and state == "Placed"
		local kind = isPet
				and (root:GetAttribute("PetModel") or species(root:GetAttribute("LootId")))
			or "Acorn"
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
			or not isCore
				and state == "Secured"
				and entry.previous ~= nil
				and entry.previous ~= "Secured"
		entry.isPet = isPet
		entry.previous = state
		task.spawn(function()
			local ok, model = pcall(clone, reveal and "OpenAcorn" or kind)
			if not ok then
				warn("[HomeArt] mesh loader failed: " .. tostring(model))
				return
			end
			if
				active[root] ~= entry
				or generation ~= entry.generation
				or not root:IsDescendantOf(workspace)
			then
				model:Destroy()
				return
			end
			entry.model, entry.started = model, reveal and os.clock() or nil
			entry.fragments = {}
			if reveal then
				for _, piece in model:GetChildren() do
					if
						piece:IsA("BasePart")
						and (piece.Name == "CapBrown" or piece.Name == "StemBrown")
					then
						entry.fragments[piece] = model:GetPivot():ToObjectSpace(piece.CFrame)
					end
				end
			end
			if isPet and not reveal then
				model:ScaleTo(PET_SCALE)
				local pad = Instance.new("Part")
				pad.Name, pad.Size, pad.Position =
					"CosmeticPetPad", Vector3.new(5, 0.2, 5), Vector3.new(0, -0.1, 0)
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
				if
					child:IsA("BasePart")
					and (child.Name == "AcornCap" or child.Name == "AcornStem")
				then
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
		anchor.Anchored, anchor.CanCollide, anchor.CanQuery, anchor.CanTouch =
			true, false, false, false
		anchor.Position, anchor.Parent = Vector3.new(-66 + (i - 1) * 44, 36, -145), decor
		local gui = Instance.new("BillboardGui")
		gui.Size, gui.Adornee, gui.MaxDistance, gui.Parent =
			UDim2.fromOffset(145, 26), anchor, 700, anchor
		local text = Instance.new("TextLabel")
		text.Size, text.BackgroundTransparency = UDim2.fromScale(1, 1), 1
		text.Text, text.Font, text.TextSize = name, Enum.Font.GothamBold, 16
		text.TextColor3, text.TextStrokeTransparency, text.Parent = Color3.new(1, 1, 1), 0, gui
	end
end)
RunService.RenderStepped:Connect(function()
	for root, entry in pairs(active) do
		if not root:IsDescendantOf(workspace) then
			destroy(entry)
			active[root] = nil
		elseif entry.model then
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
