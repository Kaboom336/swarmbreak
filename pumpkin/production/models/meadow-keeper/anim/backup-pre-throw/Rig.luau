-- Approved JSON's pivots, not MeshPart bounding-box centres, drive all joints.
local AssetService = game:GetService("AssetService")
local Data = require(script.Parent.Geometry)
local Rig = {}
local order = {"Torso", "Leg.L", "Leg.R", "Arm.L", "Arm.R", "Head", "Hat"}
local parents = {Torso="Root", ["Leg.L"]="Torso", ["Leg.R"]="Torso",
	["Arm.L"]="Torso", ["Arm.R"]="Torso", Head="Torso", Hat="Head"}

local function invisible(name,cf,model)
	local part = Instance.new("Part")
	part.Name, part.Size, part.Transparency = name, Vector3.new(.2,.2,.2), 1
	part.CFrame, part.CanCollide, part.CanTouch, part.CanQuery = cf, false, false, false
	part.Massless = true
	part.Parent = model
	return part
end

local function skeleton(model, placement, pivots)
	local rig = {model=model, carriers={}, motors={}, rest={}, meshes={}}
	local root = invisible("KeeperRoot",placement,model)
	root.Anchored = true
	rig.root, rig.carriers.Root = root, root
	model.PrimaryPart = root
	for _, name in ipairs(order) do
		local cf = placement * CFrame.new(table.unpack(pivots[name]))
		local carrier = invisible("Pivot_"..name,cf,model)
		rig.carriers[name] = carrier
		local motor = Instance.new("Motor6D")
		motor.Name, motor.Part0, motor.Part1 = "Keeper_"..name, rig.carriers[parents[name]], carrier
		motor.C0 = motor.Part0.CFrame:ToObjectSpace(cf)
		motor.C1 = CFrame.identity
		motor.Parent = motor.Part0
		rig.motors[name], rig.rest[name] = motor, motor.C0
	end
	-- Actual hand centre in Arm.R pivot coordinates. Front is +Z.
	local hand = Instance.new("Attachment")
	hand.Name, hand.Position = "ReleaseSocket", Vector3.new(.89,-3.55,1.5)
	hand.Parent = rig.carriers["Arm.R"]
	rig.release = hand
	function rig:ReleaseCFrame(pose)
		-- Forward kinematics is immediate; Attachment.WorldCFrame can lag until physics.
		return self.root.CFrame * self.rest.Torso * pose.Torso
			* self.rest["Arm.R"] * pose["Arm.R"] * hand.CFrame
	end
	return rig
end

local function weld(part,carrier)
	part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery, part.Massless = false,false,false,false,true
	local joint = Instance.new("WeldConstraint")
	joint.Part0, joint.Part1, joint.Parent = carrier,part,carrier
end

function Rig.build(placement)
	local model = Instance.new("Model")
	model.Name = "MeadowKeeperAnimationDemo"
	local pivots = {}
	for _, section in ipairs(Data) do pivots[section.rig_part] = section.pivot end
	local rig = skeleton(model,placement or CFrame.identity,pivots)
	local ok, err = pcall(function()
		for _, section in ipairs(Data) do
			local editable = assert(AssetService:CreateEditableMesh(), "EditableMesh memory unavailable")
			table.insert(rig.meshes,editable) -- Retain references for the rig's lifetime.
			local ids = {}
			local minV, maxV = Vector3.new(math.huge,math.huge,math.huge), Vector3.new(-math.huge,-math.huge,-math.huge)
			for _, v in ipairs(section.vertices) do
				local p = Vector3.new(table.unpack(v))
				minV, maxV = minV:Min(p), maxV:Max(p)
			end
			local centre = (minV+maxV)/2
			for i,v in ipairs(section.vertices) do ids[i] = editable:AddVertex(Vector3.new(table.unpack(v))-centre) end
			for _, tri in ipairs(section.triangles) do editable:AddTriangle(ids[tri[1]+1],ids[tri[2]+1],ids[tri[3]+1]) end
			local part = AssetService:CreateMeshPartAsync(Content.fromObject(editable))
			part.Name, part.Color, part.Material = section.name, Color3.fromRGB(table.unpack(section.color)), Enum.Material.SmoothPlastic
			part.CFrame = rig.root.CFrame * CFrame.new(centre)
			part.Parent = model
			weld(part,rig.carriers[section.rig_part])
		end
	end)
	if not ok then Rig.destroy(rig); error("Keeper geometry creation failed; no settings were changed: "..tostring(err)) end
	return rig
end

-- Alternative: neutral imported FBX, exact seven names, aligned to JSON's Y-up +Z basis.
-- Call before animation begins. Captures existing visual transforms, avoiding mesh-centre assumptions.
function Rig.bind(model, placement)
	assert(not model:FindFirstChild("KeeperRoot"),"Keeper is already rigged")
	local pivots, parts = {}, {}
	for _, section in ipairs(Data) do pivots[section.rig_part] = section.pivot end
	for _, name in ipairs(order) do
		local part = model:FindFirstChild(name,true)
		assert(part and part:IsA("BasePart"),"Missing imported part: "..name)
		parts[name] = part
	end
	local rig = skeleton(model,placement or CFrame.identity,pivots)
	for name,part in pairs(parts) do weld(part,rig.carriers[name]) end
	return rig
end

function Rig.destroy(rig)
	rig.model:Destroy()
	for _, mesh in ipairs(rig.meshes) do mesh:Destroy() end
end

return Rig
