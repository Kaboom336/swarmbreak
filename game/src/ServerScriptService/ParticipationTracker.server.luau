--!strict
-- Owns ephemeral participation state. Inputs arrive only from server-validated systems;
-- movement is sampled from the character state observed by the server.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Participation = require(ReplicatedStorage.Shared.Participation)
local signals = ServerStorage:WaitForChild("ParticipationSignals")
local Reset = signals:WaitForChild("Reset") :: BindableEvent
local Record = signals:WaitForChild("Record") :: BindableEvent
local Eligible = signals:WaitForChild("Eligible") :: BindableFunction

local states: { [Player]: Participation.State } = {}
local lastPositions: { [Player]: Vector3 } = {}
local elapsed = 0

local function reset(plr: Player, joinedLate: boolean)
	states[plr] = Participation.new(os.clock(), joinedLate)
	lastPositions[plr] = nil
end

Reset.Event:Connect(function(plr: Player, joinedLate: boolean?)
	reset(plr, joinedLate == true)
end)

Record.Event:Connect(function(plr: Player, kind: Participation.Kind, amount: number?)
	local state = states[plr]
	if state and plr.Parent == Players then
		Participation.record(state, kind, amount or 1, os.clock())
	end
end)

Eligible.OnInvoke = function(plr: Player): boolean
	local state = states[plr]
	return state ~= nil and Participation.isEligible(state, os.clock())
end

RunService.Heartbeat:Connect(function(dt)
	elapsed += dt
	if elapsed < 1 then
		return
	end
	elapsed = 0
	for plr, state in states do
		local char = plr.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if hum and hum.Health > 0 and root and not plr:GetAttribute("WaitingForIntermission") then
			local previous = lastPositions[plr]
			if previous then
				-- Ignore vertical knockback and cap one sample so teleports cannot qualify a player.
				local delta = (root.Position - previous) * Vector3.new(1, 0, 1)
				Participation.record(state, "Movement", math.min(delta.Magnitude, 32), os.clock())
			end
			lastPositions[plr] = root.Position
		else
			lastPositions[plr] = nil
		end
	end
end)

local function onPlayerAdded(plr: Player)
	reset(plr, false)
end
Players.PlayerAdded:Connect(onPlayerAdded)
for _, plr in Players:GetPlayers() do
	onPlayerAdded(plr)
end

Players.PlayerRemoving:Connect(function(plr)
	states[plr] = nil
	lastPositions[plr] = nil
end)
