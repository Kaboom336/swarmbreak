--!strict
-- Hold mouse / touch to fire toward the cursor. Server validates the actual hit.
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Weapons = require(ReplicatedStorage.Shared.Weapons)
local Upgrades = require(ReplicatedStorage.Shared.Upgrades)
local Evolutions = require(ReplicatedStorage.Shared.Evolutions)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Shoot = Remotes.Shoot :: RemoteEvent
local StatsChanged = Remotes.StatsChanged :: RemoteEvent

local firing = false
local last = 0
local equipped = "Starter"
local fireRateMult = 1
local touchPos: Vector2? = nil

StatsChanged.OnClientEvent:Connect(function(stats)
	equipped = stats.Equipped or "Starter"
	-- The same rate the server checks shots against (PlayerData.fireRateMultiplier): run
	-- upgrades x the equipped weapon's evolution tier x this run's Trigger cards. This throttle
	-- is what sets the real cadence (the server only guards), so every part is folded in here.
	local _, evoRate = Evolutions.multipliers((stats.Evolutions or {})[equipped])
	fireRateMult = Upgrades.valueAt("FireRate", (stats.Levels and stats.Levels.FireRate) or 0)
		* evoRate
		* (1 + ((stats.Boosts and stats.Boosts.FireRateMult) or 0))
end)

local function tryShoot()
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not root or not hum or hum.Health <= 0 then
		return
	end
	local weapon = Weapons.Defs[equipped] or Weapons.Defs.Starter
	if weapon.Kind == "Orbital" then
		return -- passive weapon: nothing to send
	end
	local now = os.clock()
	if now - last < 1 / (weapon.FireRate * fireRateMult) then
		return
	end
	last = now
	-- Mouse: GetMouseLocation and ViewportPointToRay share the same raw space.
	-- Touch: InputObject.Position is inset-adjusted, so use ScreenPointToRay.
	local ray: Ray
	if touchPos then
		ray = camera:ScreenPointToRay(touchPos.X, touchPos.Y)
	else
		local m = UserInputService:GetMouseLocation()
		ray = camera:ViewportPointToRay(m.X, m.Y)
	end
	local origin = root.Position + Vector3.new(0, 1, 0)
	local aimPoint = ray.Origin + ray.Direction * 500
	Shoot:FireServer(origin, (aimPoint - origin).Unit)
end

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then
		return
	end
	if input.UserInputType == Enum.UserInputType.Touch then
		touchPos = Vector2.new(input.Position.X, input.Position.Y)
		firing = true
	elseif
		input.UserInputType == Enum.UserInputType.MouseButton1
		or input.KeyCode == Enum.KeyCode.ButtonR2
	then
		firing = true
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch and touchPos then
		touchPos = Vector2.new(input.Position.X, input.Position.Y)
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if
		input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
		or input.KeyCode == Enum.KeyCode.ButtonR2
	then
		firing = false
		touchPos = nil
	end
end)
RunService.RenderStepped:Connect(function()
	if firing then
		tryShoot()
	end
end)
