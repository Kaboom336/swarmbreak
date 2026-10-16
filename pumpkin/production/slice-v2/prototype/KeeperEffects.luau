-- Client presentation only. Native particles/trails, bounded lifetime and distance.
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local FX = {}
local dustColor = Color3.fromRGB(187, 155, 99)
local gold = Color3.fromRGB(255, 205, 57)
local groups, shakes = {}, {}
FX.SoundNames = {
	"lobWindup",
	"lobRelease",
	"lobImpact",
	"LogBlocked",
	"fanWindup",
	"fanRelease",
	"AcornPop",
	"slamWindup",
	"slamRelease",
	"dashWindup",
	"dashRelease",
	"WallStun",
	"Warn",
	"PlayerHit",
	"Chase",
	"Return",
	"Celebrate",
	"Stun",
}
local library = Instance.new("Folder")
library.Name, library.Parent = "KeeperSounds_TODO", Players.LocalPlayer:WaitForChild("PlayerScripts")
for _, name in ipairs(FX.SoundNames) do
	local s = Instance.new("Sound")
	s.Name, s.SoundId, s.Volume, s.RollOffMaxDistance = name, "", 0.6, 75
	if name == "dashWindup" or name == "WallStun" then
		s.SoundId = "rbxasset://sounds/electronicpingshort.wav"
		s.PlaybackSpeed = name == "dashWindup" and 0.7 or 0.5
	end
	s:SetAttribute("TODO", "Assign verified Roblox free audio ID; blank is intentionally silent")
	s.Parent = library
end
local function host(guard, position, life)
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame = "KeeperFX", Vector3.one * 0.1, CFrame.new(position)
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery, p.Transparency = true, false, false, false, 1
	p.Parent = workspace
	groups[guard] = groups[guard] or {}
	groups[guard][p] = true
	p.Destroying:Once(function()
		if groups[guard] then
			groups[guard][p] = nil
		end
	end)
	Debris:AddItem(p, life or 2)
	return p
end
local function sound(p, name)
	local original = library:FindFirstChild(name)
	if original then
		local s = original:Clone()
		s.Parent = p
		if s.SoundId ~= "" then
			s:Play()
		end
	end
end
local function particles(p, count, stars, scale)
	local a = Instance.new("Attachment")
	a.Name = "BurstSocket"
	a.Parent = p
	local e = Instance.new("ParticleEmitter")
	e.Name = stars and "HitSparks" or "MeadowDust"
	e.Texture = stars and "rbxasset://textures/particles/sparkles_main.dds"
		or "rbxasset://textures/particles/smoke_main.dds"
	e.Color = ColorSequence.new(stars and gold or dustColor)
	e.Lifetime = NumberRange.new(0.3, 0.75)
	e.Speed = NumberRange.new(stars and 10 or 3, stars and 19 or 9)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Rate = 0
	e.Enabled = false
	e.Rotation = NumberRange.new(0, 360)
	e.RotSpeed = NumberRange.new(-90, 90)
	e.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.25),
		NumberSequenceKeypoint.new(0.2, scale or 2),
		NumberSequenceKeypoint.new(1, 0),
	})
	e.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.08, 0.12),
		NumberSequenceKeypoint.new(1, 1),
	})
	e.LightEmission = stars and 0.8 or 0.1
	e.Acceleration = Vector3.new(0, stars and -18 or 2, 0)
	e.Parent = a
	e:Emit(count)
end
local function flash(p)
	local light = Instance.new("PointLight")
	light.Color = gold
	light.Range = 18
	light.Brightness = 4
	light.Parent = p
	TweenService:Create(light, TweenInfo.new(0.22), { Brightness = 0 }):Play()
end
local function shake(guard, position, strength)
	local r = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not r then
		return
	end
	local falloff = 1 - math.clamp((r.Position - position).Magnitude / 65, 0, 1)
	if falloff > 0 then
		table.insert(shakes, { guard = guard, at = os.clock(), power = strength * falloff })
	end
end
local function stars(p)
	-- Literal five-point stars, distinct from sparkle-texture particles.
	for i = 1, 6 do
		local gui = Instance.new("BillboardGui")
		gui.Size = UDim2.fromOffset(52, 52)
		gui.AlwaysOnTop = false
		gui.Parent = p
		gui.StudsOffsetWorldSpace = Vector3.new(math.cos(i * math.pi / 3) * 2, 1 + math.sin(i * math.pi / 3), 0)
		local t = Instance.new("TextLabel")
		t.Size = UDim2.fromScale(1, 1)
		t.BackgroundTransparency = 1
		t.Text = "★"
		t.TextScaled = true
		t.TextColor3 = gold
		t.TextStrokeTransparency = 0.2
		t.Rotation = i * 40
		t.Parent = gui
		TweenService
			:Create(
				gui,
				TweenInfo.new(0.65),
				{ StudsOffsetWorldSpace = gui.StudsOffsetWorldSpace + Vector3.new(0, 2, 0) }
			)
			:Play()
		TweenService
			:Create(
				t,
				TweenInfo.new(0.65),
				{ TextTransparency = 1, TextStrokeTransparency = 1, Rotation = i * 40 + 100 }
			)
			:Play()
	end
end
local function chunks(guard, position)
	for i = 1, 10 do
		local a = i * math.pi / 5
		local p = host(guard, position, 0.85)
		p.Transparency = 0
		p.Size = Vector3.one * (0.35 + (i % 3) * 0.2)
		p.Color, p.Material = dustColor, Enum.Material.Ground
		local apex = position + Vector3.new(math.cos(a) * 4, 2 + (i % 3), math.sin(a) * 4)
		TweenService:Create(
			p,
			TweenInfo.new(0.23, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Position = apex, Orientation = Vector3.new(i * 30, i * 50, 35) }
		):Play()
		task.delay(0.23, function()
			if p.Parent then
				TweenService:Create(
					p,
					TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
					{ Position = apex - Vector3.new(0, 4, 0), Transparency = 1 }
				):Play()
			end
		end)
	end
end
function FX.trail(p, kind)
	local a, b = Instance.new("Attachment"), Instance.new("Attachment")
	a.Position, b.Position = Vector3.new(0, -0.5, 0), Vector3.new(0, 0.5, 0)
	a.Parent, b.Parent = p, p
	local trail = Instance.new("Trail")
	trail.Name = "KeeperWhoosh_" .. kind
	trail.Attachment0, trail.Attachment1 = a, b
	trail.Color = ColorSequence.new(kind == "fan" and Color3.fromRGB(156, 190, 75) or dustColor)
	trail.Lifetime = 0.22
	trail.MinLength = 0.05
	trail.FaceCamera = true
	trail.Transparency = NumberSequence.new(0, 1)
	trail.WidthScale = NumberSequence.new(1, 0)
	trail.Parent = p
	return trail
end
function FX.reset(guard)
	for p in pairs(groups[guard] or {}) do
		p:Destroy()
	end
	groups[guard] = nil
	for i = #shakes, 1, -1 do
		if shakes[i].guard == guard then
			table.remove(shakes, i)
		end
	end
end
function FX.emit(guard, name, position, radius)
	if name == "Reset" then
		FX.reset(guard)
		return
	end
	local camera = workspace.CurrentCamera
	if not camera or (camera.CFrame.Position - position).Magnitude > 140 then
		return
	end
	local p = host(guard, position, name == "WallStun" and 1.55 or 2)
	sound(p, name)
	if name == "Warn" then
		local gui = Instance.new("BillboardGui")
		gui.Size = UDim2.fromOffset(100, 100)
		gui.StudsOffsetWorldSpace = Vector3.new(0, 8, 0)
		gui.Parent = p
		local text = Instance.new("TextLabel")
		text.Size = UDim2.fromScale(1, 1)
		text.BackgroundTransparency = 1
		text.Text = "!"
		text.Font = Enum.Font.GothamBlack
		text.TextScaled = true
		text.TextColor3 = gold
		text.TextStrokeTransparency = 0.2
		text.Parent = gui
		local scale = Instance.new("UIScale")
		scale.Scale = 0.1
		scale.Parent = text
		TweenService:Create(scale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1.2 })
			:Play()
		task.delay(0.32, function()
			if scale.Parent then
				TweenService:Create(scale, TweenInfo.new(0.25), { Scale = 1 }):Play()
			end
		end)
	elseif name == "lobImpact" or name == "slamRelease" then
		particles(p, 45, false, 4)
		flash(p)
		chunks(guard, position)
		shake(guard, position, name == "lobImpact" and 0.45 or 0.65)
		local crater = host(guard, position + Vector3.new(0, 0.05, 0), 1.5)
		crater.Transparency = 0.98
		crater.Size = Vector3.new(name == "lobImpact" and 8 or 12, 0.05, name == "lobImpact" and 8 or 12)
		local decal = Instance.new("Decal")
		decal.Name = "DustCrater"
		decal.Face = Enum.NormalId.Top
		decal.Texture = "rbxasset://textures/particles/smoke_main.dds"
		decal.Color3 = Color3.fromRGB(77, 56, 34)
		decal.Transparency = 0.2
		decal.Parent = crater
		TweenService:Create(decal, TweenInfo.new(1.3), { Transparency = 1 }):Play()
		-- Ring surface built as actual wedge meshes; same radius/time as damaging rim.
		if name == "slamRelease" then
			for i = 0, 39 do
				local a = i * math.pi / 20
				local segment = host(guard, position, 1.15)
				segment.Transparency = 0.08
				segment.Color = gold
				segment.Material = Enum.Material.Neon
				local mesh = Instance.new("SpecialMesh")
				mesh.MeshType = Enum.MeshType.Wedge
				mesh.Parent = segment
				if i % 5 == 0 then
					local attachment = Instance.new("Attachment")
					attachment.Parent = segment
					local dust = Instance.new("ParticleEmitter")
					dust.Name = "ShockwaveDust"
					dust.Texture = "rbxasset://textures/particles/smoke_main.dds"
					dust.Color = ColorSequence.new(dustColor)
					dust.Rate = 6
					dust.Lifetime = NumberRange.new(0.25, 0.45)
					dust.Speed = NumberRange.new(1, 3)
					dust.Size = NumberSequence.new(0.8, 0)
					dust.Transparency = NumberSequence.new(0.4, 1)
					dust.Parent = attachment
				end
				segment.CFrame = CFrame.new(position + Vector3.new(0, 0.18, 0)) * CFrame.Angles(0, -a - math.pi / 2, 0)
				segment.Size = Vector3.new(0.1, 0.2, 2.4)
				local endCF = CFrame.new(
					position + Vector3.new(math.cos(a) * (radius or 22), 0.18, math.sin(a) * (radius or 22))
				) * CFrame.Angles(0, -a - math.pi / 2, 0)
				TweenService:Create(segment, TweenInfo.new((radius or 22) / 24, Enum.EasingStyle.Linear), {
					CFrame = endCF,
					Size = Vector3.new((radius or 22) * math.pi / 20 + 0.1, 0.2, 2.4),
					Transparency = 1,
				}):Play()
			end
		end
	elseif name == "PlayerHit" or name == "WallStun" or name == "Stun" then
		particles(p, 18, true, 1)
		stars(p)
		flash(p)
		if name == "WallStun" then
			shake(guard, position, 0.22)
		end
	elseif name == "AcornPop" or name == "LogBlocked" then
		particles(p, 12, true, 0.75)
	elseif name == "dashRelease" then
		FX.trail(p, "dash")
		local connection
		local at = os.clock()
		connection = RunService.Heartbeat:Connect(function()
			if not p.Parent or not guard.Parent or os.clock() - at > 0.55 then
				connection:Disconnect()
				return
			end
			p.CFrame = guard.CFrame * CFrame.new(0, -5, 1)
			particles(p, 2, false, 0.8)
		end)
		-- Stretched white speed lines around lowered shoulders.
		for i = 1, 5 do
			local line = host(guard, position, 0.45)
			line.Material = Enum.Material.Neon
			line.Color = Color3.fromRGB(244, 232, 186)
			line.Transparency = 0.2
			line.Size = Vector3.new(0.08, 0.08, 6)
			line.CFrame = guard.CFrame * CFrame.new((i - 3) * 1.6, (i % 2) - 2, 4)
			TweenService
				:Create(line, TweenInfo.new(0.35), { CFrame = line.CFrame * CFrame.new(0, 0, 5), Transparency = 1 })
				:Play()
		end
	else
		particles(p, name == "slamWindup" and 20 or 8, false, 1.5)
	end
end
RunService:BindToRenderStep("KeeperImpactShake", Enum.RenderPriority.Camera.Value + 1, function()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local power = 0
	local now = os.clock()
	for i = #shakes, 1, -1 do
		local s = shakes[i]
		local age = now - s.at
		if age > 0.38 then
			table.remove(shakes, i)
		else
			power += s.power * (1 - age / 0.38)
		end
	end
	if power > 0 then
		camera.CFrame *= CFrame.new(math.sin(now * 91) * power, math.cos(now * 113) * power * 0.65, 0)
	end
end)
return FX
