--!strict
-- Double jump + dash with charges. Dash on Shift / Q / gamepad B / on-screen button.
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local ClientFX = require(script.Parent.ClientFX)

local player = Players.LocalPlayer
local Dash = (ReplicatedStorage:WaitForChild("Remotes") :: Folder):WaitForChild(
		"Dash"
	) :: RemoteEvent

local function bind(char: Model)
	local hum = char:WaitForChild("Humanoid") :: Humanoid
	local root = char:WaitForChild("HumanoidRootPart") :: BasePart
	local canDouble = false
	local charges = (player:GetAttribute("DashCharges") :: number?) or Config.Dash.Charges
	local maxCharges = charges

	local chargesConn = player:GetAttributeChangedSignal("DashCharges"):Connect(function()
		maxCharges = (player:GetAttribute("DashCharges") :: number?) or Config.Dash.Charges
		charges = math.min(charges + 1, maxCharges)
	end)

	hum.StateChanged:Connect(function(_, new)
		if new == Enum.HumanoidStateType.Landed then
			canDouble = false
		elseif new == Enum.HumanoidStateType.Freefall then
			task.delay(0.15, function()
				if hum:GetState() == Enum.HumanoidStateType.Freefall then
					canDouble = true
				end
			end)
		end
	end)

	local function dash()
		if charges <= 0 or hum.Health <= 0 then
			return
		end
		charges -= 1
		Dash:FireServer()
		player:SetAttribute("DashReady", charges)
		ClientFX.sound("Dash")
		ClientFX.fovKick(10, 0.35)
		ClientFX.burst(root.Position, Color3.fromRGB(40, 220, 210), 10, 0.5, 6, 0.3, false)
		local dir = hum.MoveDirection
		if dir.Magnitude < 0.1 then
			dir = root.CFrame.LookVector
		end
		dir = Vector3.new(dir.X, 0, dir.Z).Unit
		local att = Instance.new("Attachment")
		att.Parent = root
		local lv = Instance.new("LinearVelocity")
		lv.Attachment0 = att
		lv.MaxForce = math.huge
		lv.VectorVelocity = dir * Config.Dash.Speed
		lv.RelativeTo = Enum.ActuatorRelativeTo.World
		lv.Parent = root
		task.delay(Config.Dash.Duration, function()
			lv:Destroy()
			att:Destroy()
		end)
		-- the Fast Dash reward card shortens the cooldown (PlayerData sets the attribute)
		local cooldownMult = (player:GetAttribute("DashCooldownMult") :: number?) or 1
		task.delay(Config.Dash.Cooldown * cooldownMult, function()
			charges = math.min(charges + 1, maxCharges)
			player:SetAttribute("DashReady", charges)
		end)
	end

	UserInputService.JumpRequest:Connect(function()
		if canDouble and hum:GetState() == Enum.HumanoidStateType.Freefall then
			canDouble = false
			hum:ChangeState(Enum.HumanoidStateType.Jumping)
			ClientFX.sound("Jump", nil, 0.2)
			ClientFX.ring(
				root.Position - Vector3.new(0, 2.5, 0),
				Color3.fromRGB(40, 220, 210),
				5,
				0.3
			)
			local v = root.AssemblyLinearVelocity
			root.AssemblyLinearVelocity = Vector3.new(v.X, Config.DoubleJump.Power, v.Z)
		end
	end)

	ContextActionService:BindAction("Dash", function(_, state)
		if state == Enum.UserInputState.Begin then
			dash()
		end
		return Enum.ContextActionResult.Pass
	end, true, Enum.KeyCode.LeftShift, Enum.KeyCode.Q, Enum.KeyCode.ButtonB)
	ContextActionService:SetTitle("Dash", "DASH")
	ContextActionService:SetPosition("Dash", UDim2.new(0.72, 0, 0.2, 0))

	hum.Died:Connect(function()
		ContextActionService:UnbindAction("Dash")
		chargesConn:Disconnect()
	end)
	player:SetAttribute("DashReady", charges)
end

if player.Character then
	bind(player.Character)
end
player.CharacterAdded:Connect(bind)
