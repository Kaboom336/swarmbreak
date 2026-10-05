--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Grow = require(Shared:WaitForChild("Grow"))
local VisualRules = require(Shared:WaitForChild("VisualRules"))

local PumpkinVisual = {}

local function configureArtPart(part: Part)
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Massless = true
end

local function addWeldedArt(
	pumpkin: BasePart,
	art: Model,
	name: string,
	color: Color3,
	material: Enum.Material,
	shape: Enum.PartType?
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Color = color
	part.Material = material
	part.Shape = shape or Enum.PartType.Block
	configureArtPart(part)
	part.Parent = art
	local weld = Instance.new("Weld")
	weld.Name = name .. "Weld"
	weld.Part0 = pumpkin
	weld.Part1 = part
	weld.Parent = part
	return part
end

local function ensureHeroArt(pumpkin: BasePart): Model
	local existing = pumpkin:FindFirstChild("PumpkinHeroArt")
	if existing and existing:IsA("Model") then
		return existing
	end
	local art = Instance.new("Model")
	art.Name = "PumpkinHeroArt"
	art:SetAttribute("ValueBandCount", VisualRules.REQUIRED_VALUE_BANDS)
	art.Parent = pumpkin
	for index = 1, 5 do
		addWeldedArt(
			pumpkin,
			art,
			"Rib_" .. index,
			Color3.fromRGB(128, 45, 12),
			Enum.Material.SmoothPlastic,
			Enum.PartType.Ball
		)
	end
	addWeldedArt(pumpkin, art, "Stem", Color3.fromRGB(73, 113, 42), Enum.Material.Wood)
	for index = 1, 2 do
		addWeldedArt(
			pumpkin,
			art,
			"EmissiveEye_" .. index,
			Color3.fromRGB(255, 212, 0),
			Enum.Material.Neon
		)
	end
	addWeldedArt(pumpkin, art, "EmissiveMouth", Color3.fromRGB(255, 212, 0), Enum.Material.Neon)
	return art
end

local function positionArt(pumpkin: BasePart, diameter: number)
	local art = ensureHeroArt(pumpkin)
	for index = 1, 5 do
		local rib = art:FindFirstChild("Rib_" .. index) :: Part?
		local weld = if rib then rib:FindFirstChild("Rib_" .. index .. "Weld") :: Weld? else nil
		if rib and weld then
			local alpha = (index - 3) / 2
			rib.Size = Vector3.new(diameter * 0.075, diameter * 0.67, diameter * 0.07)
			weld.C0 = CFrame.new(alpha * diameter * 0.27, -diameter * 0.01, -diameter * 0.48)
				* CFrame.Angles(0, 0, alpha * math.rad(14))
		end
	end
	local stem = art:FindFirstChild("Stem") :: Part?
	local stemWeld = if stem then stem:FindFirstChild("StemWeld") :: Weld? else nil
	if stem and stemWeld then
		stem.Size = Vector3.new(diameter * 0.14, diameter * 0.31, diameter * 0.14)
		stemWeld.C0 = CFrame.new(0, diameter * 0.51, 0) * CFrame.Angles(0, 0, math.rad(-13))
	end
	for index, x in { -0.16, 0.16 } do
		local eye = art:FindFirstChild("EmissiveEye_" .. index) :: Part?
		local weld = if eye
			then eye:FindFirstChild("EmissiveEye_" .. index .. "Weld") :: Weld?
			else nil
		if eye and weld then
			eye.Size = Vector3.new(diameter * 0.16, diameter * 0.13, diameter * 0.035)
			weld.C0 = CFrame.new(x * diameter, diameter * 0.09, -diameter * 0.5)
				* CFrame.Angles(0, 0, math.rad(if index == 1 then -12 else 12))
		end
	end
	local mouth = art:FindFirstChild("EmissiveMouth") :: Part?
	local mouthWeld = if mouth then mouth:FindFirstChild("EmissiveMouthWeld") :: Weld? else nil
	if mouth and mouthWeld then
		mouth.Size = Vector3.new(diameter * 0.36, diameter * 0.075, diameter * 0.035)
		mouthWeld.C0 = CFrame.new(0, -diameter * 0.15, -diameter * 0.5)
	end
end

local function characterHeight(character: Model, pumpkin: BasePart): number
	local bottom = math.huge
	local top = -math.huge
	for _, descendant in character:GetDescendants() do
		if
			descendant:IsA("BasePart")
			and descendant ~= pumpkin
			and not descendant:IsDescendantOf(pumpkin)
			and descendant:FindFirstAncestorOfClass("Accessory") == nil
		then
			bottom = math.min(bottom, descendant.Position.Y - descendant.Size.Y * 0.5)
			top = math.max(top, descendant.Position.Y + descendant.Size.Y * 0.5)
		end
	end
	return if top > bottom then top - bottom else 5
end

local function applySize(character: Model, pumpkin: BasePart, size: number)
	local mesh = pumpkin:FindFirstChild("PumpkinMesh") :: SpecialMesh?
	local weld = pumpkin:FindFirstChild("PumpkinWeld") :: Weld?
	if not mesh or not weld then
		return
	end
	local diameter = Grow.pumpkinVisualDiameter(size, characterHeight(character, pumpkin))
	pumpkin:SetAttribute("VisualDiameter", diameter)
	mesh.Scale = Vector3.new(diameter, diameter * 0.82, diameter) * Config.PumpkinMeshScale
	weld.C0 = CFrame.new(0, 1.25 + diameter * 0.42, 0)
	positionArt(pumpkin, diameter)
	local light = pumpkin:FindFirstChild("PumpkinGlow")
	if light and light:IsA("PointLight") then
		local brightness, range = VisualRules.cappedPumpkinLight(diameter)
		light.Brightness = brightness
		light.Range = range
	end
end

local function playGrowReaction(pumpkin: BasePart)
	local light = pumpkin:FindFirstChild("PumpkinGlow")
	if not light or not light:IsA("PointLight") then
		return
	end
	local resting = light.Brightness
	local pulse = TweenService:Create(
		light,
		TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true),
		{ Brightness = math.min(1.5, resting + 0.3) }
	)
	pulse:Play()
	local art = pumpkin:FindFirstChild("PumpkinHeroArt")
	if art then
		for _, descendant in art:GetChildren() do
			if descendant:IsA("BasePart") and string.find(descendant.Name, "Emissive", 1, true) then
				TweenService:Create(
					descendant,
					TweenInfo.new(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true),
					{ Color = Color3.new(1, 1, 1) }
				):Play()
			end
		end
		local stem = art:FindFirstChild("Stem")
		local stemWeld = if stem then stem:FindFirstChild("StemWeld") else nil
		if stemWeld and stemWeld:IsA("Weld") then
			TweenService:Create(
				stemWeld,
				TweenInfo.new(0.09, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, true),
				{ C0 = stemWeld.C0 * CFrame.Angles(0, 0, math.rad(12)) }
			):Play()
		end
	end
end

function PumpkinVisual.attach(character: Model, size: number): BasePart?
	local head = character:WaitForChild("Head", 10) :: BasePart?
	if not head then
		return nil
	end

	local existing = character:FindFirstChild("Pumpkin")
	if existing and existing:IsA("BasePart") then
		applySize(character, existing, size)
		return existing
	end

	local pumpkin = Instance.new("Part")
	pumpkin.Name = "Pumpkin"
	pumpkin.Size = Vector3.one
	pumpkin.Color = Color3.fromRGB(255, 106, 18)
	pumpkin.Material = Enum.Material.SmoothPlastic
	pumpkin.CanCollide = false
	pumpkin.CanQuery = false
	pumpkin.CanTouch = false
	pumpkin.Massless = true
	pumpkin.CastShadow = true
	pumpkin.Parent = character

	local mesh = Instance.new("SpecialMesh")
	mesh.Name = "PumpkinMesh"
	mesh.MeshType = Enum.MeshType.FileMesh
	mesh.MeshId = Config.PumpkinMeshId
	mesh.TextureId = Config.PumpkinTextureId
	mesh.Parent = pumpkin

	local weld = Instance.new("Weld")
	weld.Name = "PumpkinWeld"
	weld.Part0 = head
	weld.Part1 = pumpkin
	weld.Parent = pumpkin

	-- Avatar loading swaps in a new Head after CharacterAdded, which would leave the pumpkin unwelded to fall away.
	character.ChildAdded:Connect(function(child)
		if child.Name == "Head" and child:IsA("BasePart") then
			weld.Part0 = child
		end
	end)

	local light = Instance.new("PointLight")
	light.Name = "PumpkinGlow"
	light.Color = Color3.fromRGB(255, 113, 22)
	light.Brightness = 0.7
	light.Range = 8
	light.Parent = pumpkin

	local outline = Instance.new("Highlight")
	outline.Name = "HeroSeparation"
	outline.Adornee = pumpkin
	outline.DepthMode = Enum.HighlightDepthMode.Occluded
	outline.FillTransparency = 1
	outline.OutlineColor = Color3.fromRGB(23, 18, 37)
	outline.OutlineTransparency = 0.08
	outline.Parent = pumpkin

	applySize(character, pumpkin, size)
	return pumpkin
end

function PumpkinVisual.update(character: Model?, size: number)
	if not character then
		return
	end
	local pumpkin = character:FindFirstChild("Pumpkin")
	if pumpkin and pumpkin:IsA("BasePart") then
		applySize(character, pumpkin, size)
		playGrowReaction(pumpkin)
	end
end

return PumpkinVisual
