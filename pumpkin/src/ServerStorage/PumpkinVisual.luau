--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Grow = require(Shared:WaitForChild("Grow"))

local PumpkinVisual = {}

local function characterHeight(character: Model, pumpkin: BasePart): number
	local bottom = math.huge
	local top = -math.huge
	for _, descendant in character:GetDescendants() do
		if
			descendant:IsA("BasePart")
			and descendant ~= pumpkin
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
	end
end

return PumpkinVisual
