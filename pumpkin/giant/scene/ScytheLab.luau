-- Paste this entire script into Studio's command bar in EDIT mode after syncing PatchConfig.
-- No downloaded rigs/assets. The game builder/styles/pose keys are required directly.
assert(not game:GetService("RunService"):IsRunning(), "ScytheLab requires Edit mode")
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("PatchConfig"))
assert(Config.buildScythe and Config.ScythePose, "Sync the S2 PatchConfig before building the lab")
local previous = workspace:FindFirstChild("ScytheLab")
if previous then
	previous:Destroy()
end

local origin = Vector3.new(1500, 3, -200)
local bounds = Vector3.new(100, 24, 60)
local empty = false
-- Include CanQuery=false decoration: query bounds alone would miss it.
local function occupied(center)
	for _, part in workspace:GetDescendants() do
		if part:IsA("BasePart") and not part:IsA("Terrain") then
			local cf, half = part.CFrame, part.Size / 2
			local extent = Vector3.new(
				math.abs(cf.RightVector.X) * half.X
					+ math.abs(cf.UpVector.X) * half.Y
					+ math.abs(cf.LookVector.X) * half.Z,
				math.abs(cf.RightVector.Y) * half.X
					+ math.abs(cf.UpVector.Y) * half.Y
					+ math.abs(cf.LookVector.Y) * half.Z,
				math.abs(cf.RightVector.Z) * half.X
					+ math.abs(cf.UpVector.Z) * half.Y
					+ math.abs(cf.LookVector.Z) * half.Z
			)
			local d = part.Position - center
			if
				math.abs(d.X) < bounds.X / 2 + extent.X
				and math.abs(d.Y) < bounds.Y / 2 + extent.Y
				and math.abs(d.Z) < bounds.Z / 2 + extent.Z
			then
				return true
			end
		end
	end
	-- Terrain occupies cells independently of BaseParts.
	local region = Region3.new(center - bounds / 2, center + bounds / 2):ExpandToGrid(4)
	local _, occupancy = workspace.Terrain:ReadVoxels(region, 4)
	for _, plane in ipairs(occupancy) do
		for _, row in ipairs(plane) do
			for _, density in row do
				if density > 0 then
					return true
				end
			end
		end
	end
	return false
end
for attempt = 0, 30 do
	origin = Vector3.new(1500 + attempt * 140, 3 + (attempt > 15 and 100 or 0), -200)
	if not occupied(origin + Vector3.new(0, 10, 0)) then
		empty = true
		break
	end
end
assert(empty, "No empty ScytheLab site found; nothing built")
print("ScytheLab empty site:", origin)
local folder = Instance.new("Folder")
folder.Name, folder.Parent = "ScytheLab", workspace

local function part(parent, name, size, cf)
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame = name, size, cf
	p.Anchored, p.CanCollide = true, false
	p.Color, p.Material = Color3.fromRGB(160, 170, 190), Enum.Material.SmoothPlastic
	p.Parent = parent
	return p
end
local function label(subject, text)
	local gui = Instance.new("BillboardGui")
	gui.Size, gui.StudsOffset, gui.AlwaysOnTop =
		UDim2.fromOffset(220, 40), Vector3.new(0, 5, 0), true
	gui.Adornee, gui.Parent = subject, subject
	local caption = Instance.new("TextLabel")
	caption.Size, caption.BackgroundTransparency = UDim2.fromScale(1, 1), 1
	caption.Text, caption.TextColor3, caption.TextStrokeTransparency = text, Color3.new(1, 1, 1), 0
	caption.TextSize, caption.Font, caption.Parent = 20, Enum.Font.GothamBold, gui
end
local function placeTool(tool, cf, parent)
	local delta = cf * tool.Handle.CFrame:Inverse()
	for _, p in tool:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored = true
			p.CFrame = delta * p.CFrame
		elseif p:IsA("ParticleEmitter") then
			p.Enabled = false
		end
	end
	tool.Parent = parent
end
for i, def in Config.Tools do
	local tool = Config.buildScythe(def)
	tool.Name = def.id
	placeTool(tool, CFrame.new(origin + Vector3.new((i - 4) * 12, 4, 0)), folder)
	label(tool.Handle, string.format("%d: %s", i, def.name))
end

local function sample(step, time)
	if not step then
		return table.clone(Config.ScythePose.idle)
	end
	local previousPose, at = Config.ScythePose.idle, 0
	for _, key in Config.ScythePose.swings[step] do
		if time <= key[1] then
			local f = math.clamp((time - at) / (key[1] - at), 0, 1)
			if key[2] == "outCubic" then
				f = 1 - (1 - f) ^ 3
			elseif key[2] == "outQuart" then
				f = 1 - (1 - f) ^ 4
			end
			local result = {}
			for i = 1, #previousPose do
				result[i] = previousPose[i] + (key[i + 2] - previousPose[i]) * f
			end
			return result
		end
		previousPose, at = {}, key[1]
		for i = 1, #Config.ScythePose.idle do
			previousPose[i] = key[i + 2]
		end
	end
	return table.clone(Config.ScythePose.idle)
end
local function dummy(name, position, pose)
	local rig = Instance.new("Model")
	rig.Name, rig.Parent = name, folder
	local humanoid = Instance.new("Humanoid")
	humanoid.RigType, humanoid.DisplayDistanceType =
		Enum.HumanoidRigType.R15, Enum.HumanoidDisplayDistanceType.None
	humanoid.Parent = rig
	local root = part(
		rig,
		"HumanoidRootPart",
		Vector3.new(2, 2, 1),
		CFrame.new(position + Vector3.new(0, 3, 0))
	)
	root.Transparency, rig.PrimaryPart = 1, root
	-- Standard segmented R15 mannequin. All joints are Motor6Ds; bake the same
	-- Transform into CFrames because Edit mode does not run the animation/physics batch.
	local function joint(name, parent, childName, size, c0, c1, index)
		local child = part(rig, childName, size, CFrame.identity)
		local motor = Instance.new("Motor6D")
		motor.Name, motor.Part0, motor.Part1, motor.C0, motor.C1 = name, parent, child, c0, c1
		local rotation = CFrame.identity
		if index then
			local pitch, yaw, roll = pose[index], 0, 0
			if index ~= 4 and index ~= 8 then
				yaw, roll = pose[index + 1], pose[index + 2]
			end
			rotation = CFrame.fromEulerAnglesYXZ(math.rad(pitch), math.rad(yaw), math.rad(roll))
		end
		motor.Transform = c0.Rotation:Inverse() * rotation * c0.Rotation
		child.CFrame = parent.CFrame * c0 * motor.Transform * c1:Inverse()
		motor.Parent = parent
		return child
	end
	local lower =
		joint("Root", root, "LowerTorso", Vector3.new(2, 0.6, 1), CFrame.identity, CFrame.identity)
	local upper = joint(
		"Waist",
		lower,
		"UpperTorso",
		Vector3.new(2, 1.6, 1),
		CFrame.new(0, 0.3, 0),
		CFrame.new(0, -0.8, 0),
		9
	)
	joint(
		"Neck",
		upper,
		"Head",
		Vector3.new(2, 1, 1),
		CFrame.new(0, 0.8, 0),
		CFrame.new(0, -0.5, 0)
	)
	local rightHand
	for _, side in { "Right", "Left" } do
		local sign, index = side == "Right" and 1 or -1, side == "Right" and 1 or 5
		local arm = joint(
			side .. "Shoulder",
			upper,
			side .. "UpperArm",
			Vector3.new(1, 1.2, 1),
			CFrame.new(sign, 0.6, 0),
			CFrame.new(-sign * 0.5, 0.4, 0),
			index
		)
		local forearm = joint(
			side .. "Elbow",
			arm,
			side .. "LowerArm",
			Vector3.new(1, 1.2, 1),
			CFrame.new(0, -0.6, 0),
			CFrame.new(0, 0.6, 0),
			index + 3
		)
		local hand = joint(
			side .. "Wrist",
			forearm,
			side .. "Hand",
			Vector3.new(1, 0.3, 1),
			CFrame.new(0, -0.6, 0),
			CFrame.new(0, 0.15, 0)
		)
		if side == "Right" then
			rightHand = hand
		end
		local thigh = joint(
			side .. "Hip",
			lower,
			side .. "UpperLeg",
			Vector3.new(1, 1.2, 1),
			CFrame.new(sign * 0.5, -0.3, 0),
			CFrame.new(0, 0.6, 0)
		)
		local shin = joint(
			side .. "Knee",
			thigh,
			side .. "LowerLeg",
			Vector3.new(1, 1.2, 1),
			CFrame.new(0, -0.6, 0),
			CFrame.new(0, 0.6, 0)
		)
		joint(
			side .. "Ankle",
			shin,
			side .. "Foot",
			Vector3.new(1, 0.3, 1.4),
			CFrame.new(0, -0.6, 0),
			CFrame.new(0, 0.15, 0.2)
		)
	end
	local tool = Config.buildScythe(Config.Tools[4])
	local handRotation = CFrame.Angles(math.rad(-90), 0, 0)
	local grip = tool.Grip
		* handRotation:Inverse()
		* CFrame.Angles(math.rad(pose[12]), math.rad(pose[14]), math.rad(pose[13])):Inverse()
		* handRotation
	tool.Grip = grip
	local c0 = CFrame.new(0, -0.15, 0) * handRotation
	placeTool(tool, rightHand.CFrame * c0 * grip:Inverse(), rig)
	local motor = Instance.new("Motor6D")
	motor.Name, motor.Part0, motor.Part1, motor.C0, motor.C1, motor.Parent =
		"RightGrip", rightHand, tool.Handle, c0, grip, rightHand
	label(root, name)
end
for i, entry in
	{
		{ "IDLE" },
		{ "REAP mid-swing", 1, 0.15 },
		{ "RETURN mid-swing", 2, 0.15 },
		{ "HARVEST slam", 3, 0.24 },
	}
do
	dummy(entry[1], origin + Vector3.new((i - 2.5) * 18, 0, 17), sample(entry[2], entry[3]))
end
local front = origin + Vector3.new(0, 12, -42)
local back = origin + Vector3.new(0, 12, 55)
return string.format(
	"ScytheLab origin %s; front camera %s; back camera %s; look at %s",
	tostring(origin),
	tostring(front),
	tostring(back),
	tostring(origin + Vector3.new(0, 4, 8))
)
