local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local Run = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local player = Players.LocalPlayer
local remote = RS:WaitForChild("RaidSliceEvent")
local R = require(RS:WaitForChild("MeadowV4"):WaitForChild("RaidSlice"))
local seen, voices = {}, {}
-- JumpRequest is the existing keyboard / touch Jump / controller Jump action.
UIS.JumpRequest:Connect(function()
	local char = player.Character
	local h = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not h or not root or player:GetAttribute("GreyboxPhase") ~= "Run" then
		return
	end
	local origin = Vector3.new(0, 76, -360) -- Match canonical config, never infer a wall from arbitrary parts.
	local config = require(RS.GreyboxConfig)
	origin = Vector3.new(config.MeadowX, config.MeadowHeight, config.MeadowZ)
	local e=R.encounterAt(root.Position-origin)
	if e and (root.Position - origin - e.wall).Magnitude < 8 then
		remote:FireServer("Jump", h.MoveDirection)
	end
end)
local elapsed = 0
Run.Heartbeat:Connect(function(dt)
	elapsed += dt
	if elapsed < 0.1 then
		return
	end
	elapsed = 0
	local world = workspace:FindFirstChild("GREYBOX")
	local island = world and world:FindFirstChild("SharedIsland")
	local squad = island and island:FindFirstChild("RaidSquad")
	local map = island and island:FindFirstChild("MeadowV4")
	local junction = map and map:FindFirstChild(squad and squad:GetAttribute('Encounter') or 'RaidJunction')
	if not squad or not junction then
		for _, sound in voices do
			sound:Destroy()
		end
		table.clear(voices)
		table.clear(seen)
		return
	end
	local serial, lane = squad:GetAttribute("TellSerial"), squad:GetAttribute("TellLane")
	if not serial or not lane or seen[serial] then
		return
	end
	local arrow = junction:FindFirstChild("Arrow" .. lane)
	if not arrow or arrow.Transparency > 0.1 or not squad:FindFirstChild("SproutRunner" .. lane) then
		return
	end
	local sound = voices[serial]
	if not sound then
		sound = Instance.new("Sound")
		sound.Name = "RaidCommand"
		sound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
		sound.Volume = 0.55
		sound.PlaybackSpeed = 0.8
		sound.RollOffMaxDistance = 65
		sound.SoundGroup = SoundService:FindFirstChild("SFX", true)
		sound.Parent = junction:FindFirstChild("Lane" .. lane)
		voices[serial] = sound
	end
	-- An unloaded cue grants no damage eligibility. Late joins get a fresh full warning.
	if sound.IsLoaded then
		if not player:GetAttribute("SFXMuted") then
			sound:Play()
		end
		seen[serial] = true
		remote:FireServer("Ready", serial)
	end
end)
