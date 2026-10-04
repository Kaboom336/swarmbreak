--!strict
-- Procedural held-weapon pose, recoil, muzzle flash, and melee swing.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Publish the local event before loading helpers so Shooting never misses its runtime producer.
local event = Instance.new("BindableEvent")
event.Name = "WeaponFeelEvent"
event.Parent = script.Parent

local Feel = require(ReplicatedStorage.Shared.Feel)
local AnimCurves = require(ReplicatedStorage.Shared.AnimCurves)
local VfxDefs = require(ReplicatedStorage.Shared.VfxDefs)
local ClientFX = require(script.Parent:WaitForChild("ClientFX"))

local player = Players.LocalPlayer

local recoilStartedAt: number? = nil
local swingStartedAt: number? = nil
local swingStage = 1
local abilityStartedAt: number? = nil
local abilityAnimTime = 0 -- animation-time seconds, scaled by LocalAnimationSpeed
local lastFeelAt = os.clock()
local abilityKind = ""
local aimDirection: Vector3? = nil
local aimExpiresAt = 0
local activeCharacter: Model? = nil
local shoulder: Motor6D? = nil
local elbow: Motor6D? = nil
local grip: Motor6D? = nil

local function motorIn(char: Model, name: string): Motor6D?
	local found = char:FindFirstChild(name, true)
	return if found and found:IsA("Motor6D") then found else nil
end

local function bindCharacter(char: Model?)
	if activeCharacter == char then
		return
	end
	if shoulder then
		shoulder.Transform = CFrame.identity
	end
	if elbow then
		elbow.Transform = CFrame.identity
	end
	if grip then
		grip.Transform = CFrame.identity
	end
	activeCharacter = char
	shoulder = if char then motorIn(char, "RightShoulder") else nil
	elbow = if char then motorIn(char, "RightElbow") else nil
	grip = if char then motorIn(char, "GripMotor") else nil
end

local function weaponIn(char: Model): Model?
	local weapon = char:FindFirstChild("Weapon")
	return if weapon and weapon:IsA("Model") then weapon else nil
end

local function largestWeaponPart(weapon: Model): BasePart?
	local largest: BasePart? = nil
	local largestAxis = 0
	for _, descendant in weapon:GetDescendants() do
		if descendant:IsA("BasePart") and descendant.Name ~= "Grip" then
			local size = descendant.Size
			local axis = math.max(size.X, size.Y, size.Z)
			if axis > largestAxis then
				largest = descendant
				largestAxis = axis
			end
		end
	end
	return largest
end

local function trailFor(char: Model)
	local weapon = weaponIn(char)
	local blade = weapon and largestWeaponPart(weapon)
	if not blade then
		return
	end
	local trail = blade:FindFirstChild("CombatTrail") :: Trail?
	if not trail then
		local size = blade.Size
		local axis = if size.X >= size.Y and size.X >= size.Z
			then Vector3.new(size.X / 2, 0, 0)
			elseif size.Y >= size.Z then Vector3.new(0, size.Y / 2, 0)
			else Vector3.new(0, 0, size.Z / 2)
		local first = Instance.new("Attachment")
		first.Name = "CombatTrailTip"
		first.Position = axis
		first.Parent = blade
		local second = Instance.new("Attachment")
		second.Name = "CombatTrailBase"
		second.Position = -axis
		second.Parent = blade
		trail = Instance.new("Trail")
		trail.Name = "CombatTrail"
		trail.Attachment0 = first
		trail.Attachment1 = second
		trail.LightEmission = 1
		trail.FaceCamera = true
		trail.Parent = blade
	end
	trail.Color = ColorSequence.new(blade.Color)
	trail.Lifetime = VfxDefs.TrailSeconds
	trail.Enabled = true
	local token = ((trail:GetAttribute("EnableToken") :: number?) or 0) + 1
	trail:SetAttribute("EnableToken", token)
	task.delay(AnimCurves.ComboDuration, function()
		if trail and trail.Parent and trail:GetAttribute("EnableToken") == token then
			trail.Enabled = false
		end
	end)
end

local function muzzleFlash(char: Model)
	local weapon = weaponIn(char)
	local found = weapon and weapon:FindFirstChild("Muzzle", true)
	local muzzle = if found and found:IsA("Attachment") then found else nil
	local primary = weapon and weapon.PrimaryPart
	local parent = muzzle and muzzle.Parent
	local muzzlePart = if parent and parent:IsA("BasePart") then parent else nil
	local flashCFrame: CFrame
	local flashColor: Color3
	if muzzle and muzzlePart then
		flashCFrame = muzzle.WorldCFrame
		flashColor = muzzlePart.Color
	elseif primary then
		flashCFrame = primary.CFrame * CFrame.new(0, 0, -primary.Size.Z / 2)
		flashColor = primary.Color
	else
		return
	end
	ClientFX.muzzleStar(flashCFrame.Position, flashColor, flashCFrame.LookVector)
	ClientFX.flash(flashCFrame.Position, flashColor, 8, Feel.WeaponMuzzleFlashSeconds)
end

event.Event:Connect(function(kind: string, direction: Vector3?, detail: any)
	if kind == "aim" then
		aimDirection = direction
		aimExpiresAt = if direction then os.clock() + 0.1 else 0
		return
	end
	local char = player.Character
	if not char or not direction then
		return
	end
	aimDirection = direction
	aimExpiresAt = os.clock() + 0.5
	if kind == "swing" then
		swingStartedAt = os.clock()
		swingStage = detail or 1
		trailFor(char)
		ClientFX.shake(Feel.WeaponCameraKick)
	elseif kind == "ability" then
		abilityStartedAt = os.clock()
		abilityAnimTime = 0
		abilityKind = tostring(detail)
		trailFor(char)
	else
		-- No camera shake per shot: with auto-fire it shook every few frames and read as jank
		-- (Zion 10/03). Hits, kills and bosses keep their own shake in Feel.Events.
		recoilStartedAt = os.clock()
		muzzleFlash(char)
	end
end)

local function mouseDirection(root: BasePart): Vector3
	local camera = workspace.CurrentCamera
	if not camera then
		return root.CFrame.LookVector
	end
	local mouse = player:GetMouse()
	local ray = camera:ViewportPointToRay(mouse.X, mouse.Y)
	return ray.Direction
end

RunService:BindToRenderStep("WeaponFeel", Enum.RenderPriority.Character.Value + 1, function()
	local char = player.Character
	bindCharacter(char)
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local weapon = char and weaponIn(char)
	if not char or not root or not root:IsA("BasePart") or not weapon then
		return
	end
	if not shoulder or not shoulder.Parent then
		shoulder = motorIn(char, "RightShoulder")
	end
	if not elbow or not elbow.Parent then
		elbow = motorIn(char, "RightElbow")
	end
	if not grip or not grip.Parent then
		grip = motorIn(char, "GripMotor")
	end

	local now = os.clock()
	if abilityStartedAt then
		abilityAnimTime += (now - lastFeelAt) * ((player:GetAttribute("LocalAnimationSpeed") :: number?) or 1)
	end
	lastFeelAt = now
	if (player:GetAttribute("WeaponHitstopUntil") or 0) > now then
		return
	end
	local direction = if aimDirection and now <= aimExpiresAt
		then aimDirection
		else mouseDirection(root)
	local localDirection = root.CFrame:VectorToObjectSpace(direction.Unit)
	local yaw =
		math.clamp(-math.atan2(localDirection.X, -localDirection.Z), math.rad(-60), math.rad(60))
	local pitch = math.clamp(math.asin(localDirection.Y), math.rad(-45), math.rad(45))
	local swing = if swingStartedAt
		then AnimCurves.comboSwingAt(swingStage, now - swingStartedAt)
		else { PitchDegrees = 0, RollDegrees = 0 }
	local ability = if abilityStartedAt
		then AnimCurves.scytheAbilityAt(abilityKind, abilityAnimTime)
		elseif weapon:GetAttribute("WeaponId") == "Reaper" then AnimCurves.scytheIdleAt(now)
		else AnimCurves.scytheAbilityAt("", 0)
	if shoulder then
		shoulder.Transform = CFrame.Angles(
			math.rad(-75 + swing.PitchDegrees + ability.ArmSweepDegrees * 0.25) - pitch,
			yaw * 0.7,
			math.rad(10 + swing.RollDegrees + ability.SpinDegrees)
		)
	end
	if elbow then
		elbow.Transform = CFrame.Angles(math.rad(-25), yaw * 0.3, 0)
	end
	if grip then
		local recoil = if recoilStartedAt
			then AnimCurves.fireLoopAt(now - recoilStartedAt)
			else { BackStuds = 0, UpDegrees = 0 }
		grip.Transform = CFrame.new(0, 0, recoil.BackStuds)
			* CFrame.Angles(math.rad(-recoil.UpDegrees), 0, 0)
	end
	if recoilStartedAt and now - recoilStartedAt >= AnimCurves.FireLoopDuration then
		recoilStartedAt = nil
	end
	if swingStartedAt and now - swingStartedAt >= AnimCurves.ComboDuration then
		swingStartedAt = nil
	end
	local abilityDuration = (AnimCurves.ScytheAbilityDurations :: any)[abilityKind]
	if
		abilityStartedAt
		and type(abilityDuration) == "number"
		and abilityAnimTime >= abilityDuration
	then
		abilityStartedAt = nil
		abilityKind = ""
	end
end)
