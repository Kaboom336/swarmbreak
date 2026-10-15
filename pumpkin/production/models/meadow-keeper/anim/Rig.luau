-- Approved JSON's pivots, not MeshPart bounding-box centres, drive all joints.
local Blocks = require(game:GetService("ReplicatedStorage"):WaitForChild("NativeBlocks"))
local Data = require(script.Parent.Geometry)
local Skeleton = require(script.Parent.Skeleton)
local Kinematics = require(script.Parent.Kinematics)
local Rig = {}
local order = Skeleton.jointOrder
local parents = Skeleton.parents

local function invisible(name, cf, model)
	local part = Instance.new("Part")
	part.Name, part.Size, part.Transparency = name, Vector3.new(0.2, 0.2, 0.2), 1
	part.CFrame, part.CanCollide, part.CanTouch, part.CanQuery = cf, false, false, false
	part.Massless = true
	part.Parent = model
	return part
end

local function skeleton(model, placement, pivots)
	local rig = { model = model, carriers = {}, motors = {}, rest = {}, meshes = {} }
	local root = invisible("KeeperRoot", placement, model)
	root.Anchored = true
	rig.root, rig.carriers.Root = root, root
	model.PrimaryPart = root
	for _, name in ipairs(order) do
		local cf = placement * CFrame.new(table.unpack(pivots[name]))
		local carrier = invisible("Pivot_" .. name, cf, model)
		rig.carriers[name] = carrier
		local motor = Instance.new("Motor6D")
		motor.Name, motor.Part0, motor.Part1 = "Keeper_" .. name, rig.carriers[parents[name]], carrier
		motor.C0 = motor.Part0.CFrame:ToObjectSpace(cf)
		motor.C1 = CFrame.identity
		motor.Parent = motor.Part0
		rig.motors[name], rig.rest[name] = motor, motor.C0
	end
	-- Actual hand centre in Arm.R pivot coordinates. Front is +Z.
	local hand = Instance.new("Attachment")
	hand.Name, hand.Position = "ReleaseSocket", Vector3.new(table.unpack(Skeleton.hand))
	hand.Parent = rig.carriers["Wrist.R"]
	rig.release = hand
	function rig:ReleaseCFrame(pose, clip)
		-- Forward kinematics is immediate; Attachment.WorldCFrame can lag until physics.
		return Kinematics.socket(pose, self.root.CFrame, clip)
	end
	return rig
end

local function weld(part, carrier)
	part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery, part.Massless = false, false, false, false, true
	local joint = Instance.new("WeldConstraint")
	joint.Part0, joint.Part1, joint.Parent = carrier, part, carrier
end

function Rig.build(placement)
	local model = Instance.new("Model")
	model.Name = "MeadowKeeperAnimationDemo"
	local pivots = Skeleton.pivots
	local rig = skeleton(model, placement or CFrame.identity, pivots)
	local ok, err = pcall(function()
		local count = 0
		for _, section in ipairs(Data) do
			count += Blocks.section(section, model, rig.root.CFrame, Enum.Material.SmoothPlastic, function(part)
				weld(part, assert(rig.carriers[section.rig_part], section.rig_part))
			end)
		end
		model:SetAttribute("KeeperGeometry", "NativeBlocks")
		Blocks.log("MeadowKeeper", count)
	end)
	if not ok then
		warn("[MeadowKeeper] geometry creation failed: " .. tostring(err) .. "; using emergency coloured block rig")
		for _, child in model:GetChildren() do
			if child:IsA("BasePart") and child.Name ~= "KeeperRoot" and not child.Name:match("^Pivot_") then
				child:Destroy()
			end
		end
		for _, section in ipairs(Data) do
			Blocks.section(
				{ name = section.name, color = section.color, vertices = section.vertices, triangles = {} },
				model,
				rig.root.CFrame,
				Enum.Material.SmoothPlastic,
				function(part)
					weld(part, rig.carriers[section.rig_part])
				end
			)
		end
	end
	return rig
end

-- Alternative: articulated neutral meshes, aligned to the JSON's Y-up +Z basis.
-- Call before animation begins. Captures existing visual transforms, avoiding mesh-centre assumptions.
function Rig.bind(model, placement)
	assert(not model:FindFirstChild("KeeperRoot"), "Keeper is already rigged")
	assert(
		model:FindFirstChild("Elbow.R", true),
		"Seven-part FBX cannot throw with elbows; use Rig.build or articulated named meshes"
	)
	local pivots, parts = Skeleton.pivots, {}
	for _, name in ipairs(order) do
		if name == "Pelvis" then
			continue
		end -- virtual pelvis has no imported visual mesh
		local part = model:FindFirstChild(name, true)
		assert(part and part:IsA("BasePart"), "Missing imported part: " .. name)
		parts[name] = part
	end
	local rig = skeleton(model, placement or CFrame.identity, pivots)
	for name, part in pairs(parts) do
		weld(part, rig.carriers[name])
	end
	return rig
end

function Rig.destroy(rig)
	rig.model:Destroy()
	for _, mesh in ipairs(rig.meshes) do
		mesh:Destroy()
	end
end

return Rig
