--!strict
-- Server-owned completion for movement and the client's successful dash action.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local PlayerData = require(ServerStorage.PlayerData)
local RemoteGuard = require(ReplicatedStorage.Shared.RemoteGuard)
local Dash = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Dash") :: RemoteEvent

local moveStarts: { [Player]: Vector3 } = {}
local remoteGuard = RemoteGuard.new()

local function watchCharacter(plr: Player, char: Model)
	local root = char:WaitForChild("HumanoidRootPart") :: BasePart
	moveStarts[plr] = root.Position
end

local function watchPlayer(plr: Player)
	plr.CharacterAdded:Connect(function(char)
		watchCharacter(plr, char)
	end)
	if plr.Character then
		task.spawn(watchCharacter, plr, plr.Character)
	end
end

Players.PlayerAdded:Connect(watchPlayer)
for _, plr in Players:GetPlayers() do
	watchPlayer(plr)
end

local elapsed = 0
RunService.Heartbeat:Connect(function(dt)
	elapsed += dt
	if elapsed < 0.25 then
		return
	end
	elapsed = 0
	for plr, start in moveStarts do
		local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root then
			local delta = root.Position - start
			if Vector3.new(delta.X, 0, delta.Z).Magnitude > 10 then
				moveStarts[plr] = nil
				PlayerData.completeTutorial(plr, "Move")
			end
		end
	end
end)

Dash.OnServerEvent:Connect(function(plr)
	local allowed = remoteGuard:allow(plr, RemoteGuard.Actions.Tutorial, nil)
	if not allowed then
		return
	end
	local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
	if hum and hum.Health > 0 then
		PlayerData.completeTutorial(plr, "Dash")
	end
end)

Players.PlayerRemoving:Connect(function(plr)
	moveStarts[plr] = nil
	remoteGuard:clear(plr)
end)
