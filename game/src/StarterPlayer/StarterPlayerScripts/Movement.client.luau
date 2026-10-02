--!strict
-- Fast movement shared by keyboard, gamepad, and the on-screen touch controls.
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local MovementTuning = require(ReplicatedStorage.Shared.MovementTuning)
local ClientFX = require(script.Parent:WaitForChild("ClientFX"))

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local DashRemote = (ReplicatedStorage:WaitForChild("Remotes") :: Folder):WaitForChild(
		"Dash"
	) :: RemoteEvent

local RENDER_STEP_NAME = "SwarmMovementCamera"

local function bind(character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local root = character:WaitForChild("HumanoidRootPart") :: BasePart
	local baseWalkSpeed = humanoid.WalkSpeed
	local mobileSprint = MovementTuning.defaultSprint(UserInputService.TouchEnabled)
	local sprintHeld = false
	local sliding = false
	local slideStartedAt = 0
	local slideVelocity: LinearVelocity? = nil
	local slideAttachment: Attachment? = nil
	local cameraTilt = 0
	local dashStartedAt = -math.huge
	local lastGroundedAt = os.clock()
	local lastJumpRequestAt = -math.huge
	local canDoubleJump = false
	local wasGrounded = true
	local charges = (player:GetAttribute("DashCharges") :: number?) or Config.Dash.Charges
	local maxCharges = charges
	local connections: { RBXScriptConnection } = {}

	local function isSprinting(): boolean
		return mobileSprint or sprintHeld
	end

	local function setWalkSpeed()
		humanoid.WalkSpeed = if isSprinting()
			then baseWalkSpeed * MovementTuning.Sprint.SpeedMultiplier
			else baseWalkSpeed
	end

	local function finishSlide()
		if not sliding then
			return
		end
		sliding = false
		if slideVelocity then
			slideVelocity:Destroy()
			slideVelocity = nil
		end
		if slideAttachment then
			slideAttachment:Destroy()
			slideAttachment = nil
		end
		setWalkSpeed()
	end

	local function beginSlide()
		if sliding or not isSprinting() or humanoid.Health <= 0 then
			return
		end
		local direction = humanoid.MoveDirection
		if direction.Magnitude < 0.1 then
			return
		end
		direction = Vector3.new(direction.X, 0, direction.Z).Unit
		sliding = true
		slideStartedAt = os.clock()
		slideAttachment = Instance.new("Attachment")
		slideAttachment.Parent = root
		slideVelocity = Instance.new("LinearVelocity")
		slideVelocity.Attachment0 = slideAttachment
		slideVelocity.MaxForce = math.huge
		slideVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
		slideVelocity.VectorVelocity = direction * MovementTuning.Slide.StartSpeed
		slideVelocity.Parent = root
	end

	local function dash()
		if charges <= 0 or humanoid.Health <= 0 then
			return
		end
		finishSlide()
		charges -= 1
		dashStartedAt = os.clock()
		DashRemote:FireServer()
		player:SetAttribute("DashReady", charges)
		ClientFX.sound("Dash")
		ClientFX.burst(root.Position, Color3.fromRGB(40, 220, 210), 10, 0.5, 6, 0.3, false)

		local direction = humanoid.MoveDirection
		if direction.Magnitude < 0.1 then
			direction = root.CFrame.LookVector
		end
		direction = Vector3.new(direction.X, 0, direction.Z).Unit
		local attachment = Instance.new("Attachment")
		attachment.Parent = root
		local velocity = Instance.new("LinearVelocity")
		velocity.Attachment0 = attachment
		velocity.MaxForce = math.huge
		velocity.VectorVelocity = direction * MovementTuning.Dash.Speed
		velocity.RelativeTo = Enum.ActuatorRelativeTo.World
		velocity.Parent = root
		task.delay(MovementTuning.Dash.Duration, function()
			velocity:Destroy()
			attachment:Destroy()
		end)

		local cooldownMultiplier = (player:GetAttribute("DashCooldownMult") :: number?) or 1
		task.delay(MovementTuning.Dash.Cooldown * cooldownMultiplier, function()
			if humanoid.Health > 0 then
				charges = math.min(charges + 1, maxCharges)
				player:SetAttribute("DashReady", charges)
			end
		end)
	end

	table.insert(
		connections,
		player:GetAttributeChangedSignal("DashCharges"):Connect(function()
			local newMaximum = player:GetAttribute("DashCharges") :: number? or Config.Dash.Charges
			charges = math.min(charges + math.max(0, newMaximum - maxCharges), newMaximum)
			maxCharges = newMaximum
			player:SetAttribute("DashReady", charges)
		end)
	)

	table.insert(
		connections,
		UserInputService.JumpRequest:Connect(function()
			local now = os.clock()
			lastJumpRequestAt = now
			if humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
				return
			end
			if now - lastGroundedAt <= MovementTuning.Jump.CoyoteTime then
				lastGroundedAt = -math.huge
				lastJumpRequestAt = -math.huge
				humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			elseif canDoubleJump then
				canDoubleJump = false
				lastJumpRequestAt = -math.huge
				humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
				ClientFX.sound("Jump", nil, 0.2)
				ClientFX.ring(
					root.Position - Vector3.new(0, 2.5, 0),
					Color3.fromRGB(40, 220, 210),
					5,
					0.3
				)
				local currentVelocity = root.AssemblyLinearVelocity
				root.AssemblyLinearVelocity =
					Vector3.new(currentVelocity.X, Config.DoubleJump.Power, currentVelocity.Z)
			end
		end)
	)

	ContextActionService:BindAction("Sprint", function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			sprintHeld = true
			setWalkSpeed()
		elseif
			inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel
		then
			sprintHeld = false
			setWalkSpeed()
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonL2)

	ContextActionService:BindAction("Slide", function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			beginSlide()
		end
		return Enum.ContextActionResult.Sink
	end, true, Enum.KeyCode.LeftControl, Enum.KeyCode.C, Enum.KeyCode.ButtonL3)
	ContextActionService:SetTitle("Slide", "SLIDE")
	ContextActionService:SetPosition("Slide", UDim2.fromScale(0.65, 0.72))

	ContextActionService:BindAction("Dash", function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			dash()
		end
		return Enum.ContextActionResult.Sink
	end, true, Enum.KeyCode.Q, Enum.KeyCode.ButtonB)
	ContextActionService:SetTitle("Dash", "DASH")
	ContextActionService:SetPosition("Dash", UDim2.fromScale(0.78, 0.72))

	table.insert(
		connections,
		RunService.Heartbeat:Connect(function()
			local now = os.clock()
			local grounded = humanoid.FloorMaterial ~= Enum.Material.Air
			if grounded then
				lastGroundedAt = now
				canDoubleJump = false
				if
					not wasGrounded
					and now - lastJumpRequestAt <= MovementTuning.Jump.BufferTime
				then
					lastJumpRequestAt = -math.huge
					humanoid.Jump = true
				end
			elseif wasGrounded then
				task.delay(0.15, function()
					if humanoid:GetState() == Enum.HumanoidStateType.Freefall then
						canDoubleJump = true
					end
				end)
			end
			wasGrounded = grounded

			if sliding then
				local elapsed = now - slideStartedAt
				if elapsed >= MovementTuning.Slide.Duration or humanoid.Health <= 0 then
					finishSlide()
				elseif slideVelocity then
					local direction = slideVelocity.VectorVelocity.Unit
					local speed = MovementTuning.slideSpeed(elapsed)
						* (baseWalkSpeed / MovementTuning.WalkSpeed)
					slideVelocity.VectorVelocity = direction * speed
				end
			end
		end)
	)

	RunService:BindToRenderStep(RENDER_STEP_NAME, Enum.RenderPriority.Camera.Value + 2, function(dt)
		local moving = humanoid.MoveDirection.Magnitude > 0.1
		local targetTilt = if sliding then MovementTuning.Slide.CameraTiltDegrees else 0
		cameraTilt += (targetTilt - cameraTilt) * math.min(1, dt * 12)
		if camera.CameraType ~= Enum.CameraType.Scriptable then
			camera.CFrame *= CFrame.Angles(0, 0, math.rad(cameraTilt))
		end

		local sprintKick = if isSprinting()
				and moving
				and not sliding
			then MovementTuning.Fov.SprintKick
			else 0
		local dashFov = MovementTuning.fovAt(
			os.clock() - dashStartedAt,
			MovementTuning.Fov.DashKick
		) - MovementTuning.Fov.Base
		local targetFov = MovementTuning.Fov.Base + sprintKick + dashFov
		camera.FieldOfView += (targetFov - camera.FieldOfView) * math.min(1, dt * 12)
	end)

	table.insert(
		connections,
		humanoid.Died:Connect(function()
			finishSlide()
			ContextActionService:UnbindAction("Sprint")
			ContextActionService:UnbindAction("Slide")
			ContextActionService:UnbindAction("Dash")
			RunService:UnbindFromRenderStep(RENDER_STEP_NAME)
			for _, connection in connections do
				connection:Disconnect()
			end
			camera.FieldOfView = MovementTuning.Fov.Base
		end)
	)

	setWalkSpeed()
	player:SetAttribute("DashReady", charges)
end

if player.Character then
	bind(player.Character)
end
player.CharacterAdded:Connect(bind)
