-- Greybox steal / carry / escape slice. Shared economy domain is referenced,
-- saving deliberately stays absent from this separate prototype place.
local core = game.ReplicatedStorage.TreasureCore
local Domain, Config = require(core.Domain), require(core.Config)
local map = workspace.CaveV2
local Drops = require(script.Parent.CaveDrops)
local Policy = require(script.Parent.CavePolicy)
local states = {}
local previewActions = {}
local carrier = nil
local cargo = nil
local started = 0
local dropped = false
local pickupAfter = 0
local steal = Instance.new("ProximityPrompt")
steal.ActionText = "Steal geode"
steal.HoldDuration = 2
steal.MaxActivationDistance = 10
steal.Parent = map.Geode
local function take(player)
	if cargo then
		return false
	end
	carrier = player
	started = os.clock()
	cargo = { id = game.HttpService:GenerateGUID(false), tier = Domain.roll(Config, math.random()) }
	player:SetAttribute("CaveItemID", cargo.id)
	steal.Enabled = false
	return cargo.id
end
steal.Triggered:Connect(take)
game.Players.PlayerAdded:Connect(function(player)
	states[player] = Domain.default()
	player:SetAttribute("CavePrototype", "Volatile; no saving")
end)
local function resetCargo()
	if carrier then
		carrier:SetAttribute("CaveItemID", nil)
		carrier:SetAttribute("CaveSecondsLeft", nil)
	end
	carrier = nil
	cargo = nil
	dropped = false
	steal.Enabled = true
	map.Geode.CFrame = CFrame.new(160, 51, -120)
end
local grab = Instance.new("ProximityPrompt")
grab.ActionText = "Recover geode"
grab.Enabled = false
grab.MaxActivationDistance = 7
grab.Parent = map.Geode
local function drop(player, target)
	if player ~= carrier or dropped then
		return false
	end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local floor = root and Drops.floor(root.Position)
	if not floor then
		return false
	end
	local socket, why = Drops.socket(target or root.Position, floor, root.Position)
	local landing = socket and Drops.solidRay(socket + Vector3.new(0, 8.25, 0), Vector3.new(0, -10.45, 0))
	local diagnostic = {
		itemId = cargo.id,
		carrierPos = { root.Position.X, root.Position.Y, root.Position.Z },
		carrierFloorY = floor.Y,
		laneId = landing and landing.Instance:GetAttribute("LaneId") or "UNKNOWN",
		landingInstance = landing and landing.Instance:GetFullName() or "NONE",
		landingY = landing and landing.Position.Y or "UNKNOWN",
		recoverPath = "pending physical recovery",
		reason = why,
		lootPos = socket and { socket.X, socket.Y + 1.5, socket.Z } or "NONE",
	}
	script.Parent:SetAttribute("LoopTestLastDrop", game.HttpService:JSONEncode(diagnostic))
	if not socket then
		return false
	end
	dropped = true
	pickupAfter = os.clock() + 0.6
	map.Geode.CFrame = CFrame.new(socket + Vector3.new(0, 1.5, 0))
	grab.Enabled = true
	return true
end
local function recover(player)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if
		not dropped
		or os.clock() < pickupAfter
		or not root
		or not Drops.reachable(root.Position, map.Geode.Position)
	then
		return false
	end
	if carrier then
		carrier:SetAttribute("CaveItemID", nil)
	end
	carrier = player
	player:SetAttribute("CaveItemID", cargo.id)
	dropped = false
	grab.Enabled = false
	return cargo.id
end
grab.Triggered:Connect(recover)
local dropPrompt = Instance.new("ProximityPrompt")
dropPrompt.ActionText = "Drop carried geode"
dropPrompt.MaxActivationDistance = 7
dropPrompt.Parent = map.Geode
dropPrompt.Triggered:Connect(function(player)
	drop(player)
end)
game.Players.PlayerRemoving:Connect(function(player)
	states[player] = nil
	if carrier == player then
		resetCargo()
	end
end)
game:GetService("RunService").Heartbeat:Connect(function()
	grab.Enabled = dropped
	dropPrompt.Enabled = carrier ~= nil and not dropped
	if not carrier then
		return
	end
	if os.clock() - started >= 60 then
		resetCargo()
		return
	end
	local root = carrier.Character and carrier.Character:FindFirstChild("HumanoidRootPart")
	local humanoid = carrier.Character and carrier.Character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then
		resetCargo()
		return
	end
	if root and not dropped then
		carrier:SetAttribute("CaveSecondsLeft", math.max(0, 60 - (os.clock() - started)))
		map.Geode.CFrame = root.CFrame * CFrame.new(0, 1, 3)
		if math.abs(root.Position.X + 150) < 24 and math.abs(root.Position.Z - 120) < 20 and root.Position.Y < 15 then
			local profile = states[carrier] or Domain.default()
			local ok, why =
				Domain.secure(profile, Config, cargo.id, cargo.tier, { shieldUsed = false, firstHitUsed = false })
			if ok then
				states[carrier] = profile
				carrier:SetAttribute("CaveSecured", cargo.id)
				resetCargo()
			else
				carrier:SetAttribute("CaveSecureRefusal", why)
			end
		end
	end
	if carrier and os.clock() - started >= 60 then
		resetCargo()
	end
end)
-- Core prototype progression uses the existing pure domain operations. Clear
-- secured pending cargo via place/open before another steal can be rewarded.
local open = Instance.new("ProximityPrompt")
open.ActionText = "Place / open secured geode (prototype)"
open.HoldDuration = 0.6
open.Parent = map.PortalBeacon
local function openCargo(player)
	local profile = states[player]
	local pending = profile and profile.pending
	if pending then
		if not pending.placed then
			Domain.place(profile, pending.id, 0, 0, 0)
		end
		local ok, why = Domain.open(profile, Config, pending.id)
		player:SetAttribute("CaveOpenResult", ok and "Opened" or why)
		return ok
	end
end
open.Triggered:Connect(openCargo)
-- Studio-only adapter calls the same actions as prompts; no remote test bypass.
if game:GetService("RunService"):IsStudio() then
	local api = Instance.new("BindableFunction")
	api.Name = "CaveLoopActions"
	api.Parent = script.Parent
	api.OnInvoke = function(action, player, arg)
		if action == "take" then
			return take(player)
		elseif action == "drop" then
			return drop(player, arg)
		elseif action == "recover" then
			return recover(player)
		elseif action == "open" then
			return openCargo(player)
		elseif action == "status" then
			return cargo and cargo.id, dropped, started
		elseif action == "pristine" then
			local profile = states[player]
			return not cargo and (not profile or (profile.escapes == 0 and not profile.pending and #profile.pets == 0))
		elseif action == "preview" and previewActions[arg] then
			task.spawn(previewActions[arg])
			return true
		elseif action == "reset" then
			resetCargo()
			if player then
				states[player] = Domain.default()
			end
			return true
		end
	end
end
-- Other feature hooks expose faithful timed, non-damaging telegraphs. Guardian
-- locomotion, blast force, mercy and pickup priority require a future combat pass.
for name, definition in Policy.previews do
	local entry = { name, definition.stages, definition.cooldown }
	local hook = map[entry[1]]
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Preview " .. entry[1]
	prompt.HoldDuration = 0.4
	prompt.Parent = hook
	local function preview()
		if not prompt.Enabled then
			return
		end
		prompt.Enabled = false
		if entry[1] == "ShatterCavernHook" then
			-- Each cluster receives its own >=1s tell and bursts at 1/1.8/2.6s.
			for index = 1, 3 do
				task.delay((index - 1) * 0.8, function()
					hook:SetAttribute("Cluster" .. index .. "Cracking", true)
					hook.Color = Color3.fromRGB(255, 255, 255)
					task.wait(1)
					hook:SetAttribute("Cluster" .. index .. "Cracking", false)
					hook:SetAttribute("Cluster" .. index .. "Burst", true)
					hook.Color = Color3.fromRGB(170, 80, 255)
					task.wait(0.15)
					hook:SetAttribute("Cluster" .. index .. "Burst", false)
				end)
			end
			task.wait(2.75 + entry[3])
			hook.Color = Color3.fromRGB(226, 123, 58)
			prompt.Enabled = true
			return
		end
		for stage, seconds in entry[2] do
			hook:SetAttribute("TelegraphStage", stage)
			hook.Color = Color3.fromRGB(255, 210, 110)
			task.wait(seconds)
		end
		hook:SetAttribute("TelegraphStage", 0)
		hook:SetAttribute("PayoffPreview", true)
		hook.Color = Color3.fromRGB(170, 80, 255)
		task.wait(0.3)
		hook:SetAttribute("PayoffPreview", false)
		task.wait(entry[3])
		hook.Color = Color3.fromRGB(226, 123, 58)
		prompt.Enabled = true
	end
	prompt.Triggered:Connect(preview)
	previewActions[name] = preview
end
