-- Camera/particles only; stock input, character animation and server physics own movement.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local VR = game:GetService("VRService")
local Run = game:GetService("RunService")
local player = Players.LocalPlayer
local core = RS:WaitForChild("TreasureCore")
local Move = require(core:WaitForChild("CinematicMove"))
local Trove = require(core.Packages.Trove)
local trove = Trove.new()
local characterTrove = trove:Extend()
local boundHum, boundRoot, dust, attachment
local age, phase, distance, landing = 0, 0, 0, 0
local wasAir = false
local camera, originalFov, baseFrame
local boundCharacter
local function debugState(blend, reason, intent, speed, hum)
	if Run:IsStudio() and player:GetAttribute("StudioDebug") == true then
		player:SetAttribute("CineBlend", blend)
		player:SetAttribute("CineGate", reason)
		player:SetAttribute("CineIntent", intent or 0)
		player:SetAttribute("CineSpeed", speed or 0)
		player:SetAttribute("CineHum", hum and hum:GetFullName() or "")
	end
end
local function carrying()
	return player:GetAttribute("GreyboxCarry") == true or player:GetAttribute("CaveItemID") ~= nil
end
local function restoreFrame()
	if camera and baseFrame then
		camera.CFrame = baseFrame
	end
	baseFrame = nil
end
local function releaseCamera()
	restoreFrame()
	if camera and originalFov then
		camera.FieldOfView = originalFov
	end
	camera, originalFov = nil, nil
end
local function reset()
	age, phase, distance, landing, wasAir = 0, 0, 0, 0, false
	if dust then
		dust:Clear()
	end
	releaseCamera()
	debugState(0, "reset")
end
local function bindCharacter(character, hum, root)
	reset()
	characterTrove:Clean()
	boundHum, boundRoot, dust, attachment = hum, root, nil, nil
	boundCharacter = character
end
trove:Connect(player.CharacterAdded, function(character)
	bindCharacter(character)
end)
trove:Connect(player.CharacterRemoving, function()
	reset()
	characterTrove:Clean()
	boundHum, boundRoot, dust, attachment = nil, nil, nil, nil
	boundCharacter = nil
end)
if player.Character then
	bindCharacter(player.Character)
end

-- Session preferences: Activated handles mouse, touch and selected gamepad activation.
local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn, gui.DisplayOrder = "MovementSettings", false, 5
gui.Parent = player:WaitForChild("PlayerGui")
trove:Add(gui)
local function button(name, text, y)
	local b = Instance.new("TextButton")
	b.Name, b.Text = name, text
	b.AnchorPoint, b.Position, b.Size = Vector2.new(1, 0), UDim2.new(1, -12, 0, y), UDim2.fromOffset(200, 48)
	b.BackgroundColor3, b.TextColor3 = Color3.fromRGB(31, 42, 58), Color3.fromRGB(255, 245, 218)
	b.Font, b.TextSize, b.Selectable, b.Parent = Enum.Font.GothamBold, 15, true, gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = b
	return b
end
local settings = button("Settings", "Motion settings", 112)
local reduced = button("ReducedMotion", "", 164)
local shake = button("CameraShake", "", 216)
reduced.Visible, shake.Visible = false, false
settings.NextSelectionDown, reduced.NextSelectionUp = reduced, settings
reduced.NextSelectionDown, shake.NextSelectionUp = shake, reduced
local function refresh()
	reduced.Text = "Reduced motion: " .. (player:GetAttribute("ReducedMotion") and "ON" or "OFF")
	shake.Text = "Camera shake: " .. (player:GetAttribute("CameraShakeEnabled") == true and "ON" or "OFF")
	-- Notifications update labels only. Effective suppression is sampled below;
	-- repeated replicated carry/preference notifications must not erase run age.
end
trove:Connect(settings.Activated, function()
	reduced.Visible = not reduced.Visible
	shake.Visible = reduced.Visible
	if not reduced.Visible then
		local selection = game:GetService("GuiService")
		if selection.SelectedObject == reduced or selection.SelectedObject == shake then
			selection.SelectedObject = settings
		end
	end
end)
trove:Connect(reduced.Activated, function()
	player:SetAttribute("ReducedMotion", not player:GetAttribute("ReducedMotion"))
end)
trove:Connect(shake.Activated, function()
	player:SetAttribute("CameraShakeEnabled", player:GetAttribute("CameraShakeEnabled") ~= true)
end)
for _, name in { "ReducedMotion", "CameraShakeEnabled", "GreyboxCarry", "CaveItemID" } do
	trove:Connect(player:GetAttributeChangedSignal(name), refresh)
end
refresh()

trove:BindToRenderStep("TreasureCinematicRestore", Enum.RenderPriority.Camera.Value - 2, restoreFrame)
trove:BindToRenderStep("TreasureCinematicMovement", Enum.RenderPriority.Camera.Value + 2, function(dt)
	dt = math.min(dt, 0.1)
	local character = player.Character
	-- These frame-local reads are the only movement inputs. Cached identities
	-- only decide when to retire effects; they never supply a Humanoid or root.
	local hum = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if hum and not hum:IsDescendantOf(character) then
		hum = nil
	end
	if root and not root:IsDescendantOf(character) then
		root = nil
	end
	if character ~= boundCharacter or hum ~= boundHum or root ~= boundRoot then
		bindCharacter(character, hum, root)
	end
	local intent = hum and hum.MoveDirection.Magnitude or 0
	local velocity = root and root.AssemblyLinearVelocity or Vector3.zero
	local speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
	local current = workspace.CurrentCamera
	if
		not hum
		or not root
		or not current
		or current.CameraType ~= Enum.CameraType.Custom
		or current.CameraSubject ~= hum
		or VR.VREnabled
		or player:GetAttribute("ReducedMotion")
	then
		reset()
		debugState(0, not hum and "humanoid" or not root and "root" or not current and "camera"
			or current.CameraType ~= Enum.CameraType.Custom and "camera-type"
			or current.CameraSubject ~= hum and "camera-subject" or VR.VREnabled and "vr" or "reduced", intent, speed, hum)
		return
	end
	if current ~= camera then
		releaseCamera()
		camera, originalFov = current, current.FieldOfView
	end
	local state = hum:GetState()
	local grounded = hum.FloorMaterial ~= Enum.Material.Air and state == Enum.HumanoidStateType.Running
	local carry = carrying()
	local blocked = hum.Sit or hum:GetAttribute("CaveCartRiding") == true
	local blend, running
	age, blend, running = Move.step(age, dt, {
		carry = carry,
		reduced = false,
		blocked = blocked,
		walkSpeed = hum.WalkSpeed,
		grounded = grounded,
		alive = hum.Health > 0,
		intent = intent,
		speed = speed,
	})
	debugState(blend, running and "running" or carry and "carry" or blocked and "blocked"
		or hum.Health <= 0 and "dead" or hum.WalkSpeed < 16 and "slow"
		or not grounded and "air" or "idle", intent, speed, hum)
	local eligible = not carry and not blocked and hum.WalkSpeed >= 16 and hum.Health > 0
	local air = state == Enum.HumanoidStateType.Freefall
	if wasAir and grounded and eligible and player:GetAttribute("CameraShakeEnabled") == true then
		landing = 0.16
	end
	-- Landed can occupy a render frame between Freefall and Running.
	-- Keep the fall latch through that intermediate state, then consume it once.
	if air then
		wasAir = true
	elseif state ~= Enum.HumanoidStateType.Landed then
		wasAir = false
	end
	if not eligible then
		landing = 0
		distance = 0
		if dust then
			dust:Clear()
		end
	end
	landing = math.max(0, landing - dt)
	camera.FieldOfView = 70 + blend * 10
	phase += dt * math.min(speed, hum.WalkSpeed) * 0.85
	local bob = running and blend or 0
	local impact = math.sin(landing * 85) * landing * 0.15
	baseFrame = camera.CFrame
	camera.CFrame = baseFrame
		* CFrame.new(math.sin(phase) * 0.025 * bob, math.cos(phase * 2) * 0.035 * bob + impact, 0)
		* CFrame.Angles(0, 0, math.sin(phase) * 0.0015 * bob)
	if running and blend > 0.25 then
		if not dust then
			attachment = Instance.new("Attachment")
			attachment.Name, attachment.Parent = "CinematicFootDust", root
			characterTrove:Add(attachment)
			dust = Instance.new("ParticleEmitter")
			dust.Name, dust.Texture = "FootDust", "rbxasset://textures/particles/smoke_main.dds"
			dust.Rate, dust.Lifetime, dust.Speed = 0, NumberRange.new(0.18, 0.3), NumberRange.new(0.5, 1)
			dust.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.18), NumberSequenceKeypoint.new(1, 0.65) })
			dust.Transparency =
				NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.78), NumberSequenceKeypoint.new(1, 1) })
			dust.Color, dust.SpreadAngle = ColorSequence.new(Color3.fromRGB(167, 153, 133)), Vector2.new(25, 25)
			dust.Parent = attachment
		end
		-- R6 HipHeight excludes its leg height; R15 HipHeight includes the legs.
		local leg = character:FindFirstChild("Left Leg")
		local legHeight = leg and leg.Size.Y or 0
		attachment.Position = Vector3.new(0, -hum.HipHeight - legHeight - root.Size.Y * 0.5 + 0.12, 0)
		distance += math.min(speed, hum.WalkSpeed) * dt
		if distance >= 3.5 then
			distance %= 3.5
			dust:Emit(2)
		end
	else
		distance = 0
	end
end)
script.Destroying:Connect(function()
	reset()
	trove:Destroy()
end)
