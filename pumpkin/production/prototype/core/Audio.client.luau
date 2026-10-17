-- Read replicated presentation signals only. No gameplay writes or remote sends.
local RS = game:GetService("ReplicatedStorage")
local player = game:GetService("Players").LocalPlayer
local core = RS:WaitForChild("TreasureCore", 15)
local module = core and core:WaitForChild("Audio", 15)
local gui = player:WaitForChild("PlayerGui", 15)
if not module or not gui then
	warn("[TreasureAudio] Missing dependency; audio disabled")
	return
end
local Audio = require(module)
local Tween = game:GetService("TweenService")
local mixer = Audio.new({
	service = game:GetService("SoundService"),
	new = Instance.new,
	clock = os.clock,
	after = task.delay,
	rolloff = Enum.RollOffMode.InverseTapered,
	tween = function(node, seconds, goal)
		return Tween:Create(node, TweenInfo.new(seconds), goal)
	end,
})
local connections, observed, cartSamples, legacySounds = {}, {}, {}, {}
local function connect(signal, callback)
	local connection = signal:Connect(callback)
	table.insert(connections, connection)
end
local function carry()
	return player:GetAttribute("GreyboxCarry") == true or player:GetAttribute("CaveItemID") ~= nil
end
local wasCarry = carry()
local escapes = player:GetAttribute("GreyboxMeadowEscapes") or 0
local secured = player:GetAttribute("CaveSecured")
local pendingEscape = false
local coins = player:GetAttribute("Coins")
connect(player:GetAttributeChangedSignal("Coins"), function()
	local current = player:GetAttribute("Coins")
	if type(current) == "number" and type(coins) == "number" and current < coins then
		mixer:play("Buy")
	end
	coins = current
end)
local function attributes()
	local carrying = carry()
	if carrying and not wasCarry then
		mixer:play("Reveal")
	end
	wasCarry = carrying
	local count = player:GetAttribute("GreyboxMeadowEscapes") or 0
	local id = player:GetAttribute("CaveSecured")
	if count > escapes then
		pendingEscape = true
	end
	if (pendingEscape and player:GetAttribute("GreyboxPhase") == "Home") or (id ~= nil and id ~= secured) then
		pendingEscape = false
		mixer:play("Escape")
	end
	escapes, secured = count, id
end
for _, name in { "GreyboxCarry", "CaveItemID", "GreyboxMeadowEscapes", "GreyboxPhase", "CaveSecured" } do
	connect(player:GetAttributeChangedSignal(name), attributes)
end
connect(player:GetAttributeChangedSignal("CaveOpenResult"), function()
	if player:GetAttribute("CaveOpenResult") == "Opened" then
		mixer:play("Reveal")
	end
end)
local function observe(node)
	if observed[node] then
		return
	end
	-- Weak keys avoid retaining streamed-out map parts. Connections are retired on Destroying.
	local localConnections = {}
	local function listen(signal, fn)
		table.insert(localConnections, signal:Connect(fn))
	end
	if node:IsA("GuiButton") then
		listen(node.Activated, function()
			mixer:play("Click")
		end)
	elseif node:IsA("RemoteEvent") and node.Name == "TreasureCoreEvent" then
		listen(node.OnClientEvent, function(kind)
			if kind == "Reveal" then
				mixer:play("Reveal")
			elseif kind == "Collect" then
				mixer:play("Pop")
			end
		end)
	elseif node:IsA("BasePart") and (node.Name == "TNTHook" or node.Name == "DynamiteGuardianHook") then
		listen(node:GetAttributeChangedSignal("PayoffPreview"), function()
			if node:GetAttribute("PayoffPreview") then
				mixer:play("Explosion", node)
			end
		end)
	elseif node:IsA("BasePart") and node.Name == "BreakableSpan" then
		local solid = node.CanCollide
		listen(node:GetPropertyChangedSignal("CanCollide"), function()
			if solid and not node.CanCollide then
				mixer:play("Explosion", node)
			end
			solid = node.CanCollide
		end)
	elseif node:IsA("Model") and node.Name:match("^RideableCart") then
		local previous = node:GetAttribute("State")
		listen(node:GetAttributeChangedSignal("State"), function()
			local state = node:GetAttribute("State")
			if state == "Flight" and previous ~= "Flight" and node.PrimaryPart then
				mixer:play("Explosion", node.PrimaryPart)
			end
			previous = state
		end)
	elseif node:IsA("Sound") and (node.Name == "DecoyRattle" or node.Name == "HomeRevealPop") then
		legacySounds[node] = { group = node.SoundGroup }
		node.SoundGroup = mixer.groups.SFX
		listen(node.Destroying, function()
			legacySounds[node] = nil
		end)
	elseif node.Name == "Guardian" then
		local function alert()
			local mode = node:GetAttribute("KeeperMode")
			return mode == "Warn" or mode == "Chase" or mode == "DecoyTell"
		end
		local previous, nextAlert = alert(), 0
		listen(node:GetAttributeChangedSignal("KeeperMode"), function()
			local active = alert()
			if active and not previous and os.clock() >= nextAlert then
				nextAlert = os.clock() + 6
				mixer:play("Growl")
			end
			-- Suppressed edges are consumed, never replayed by a detection tick.
			previous = active
		end)
	end
	if #localConnections == 0 then
		return
	end
	observed[node] = localConnections
	listen(node.Destroying, function()
		for _, connection in localConnections do
			connection:Disconnect()
		end
		observed[node] = nil
	end)
end
setmetatable(observed, { __mode = "k" })
for _, root in { workspace, gui, RS } do
	connect(root.DescendantAdded, observe)
	for _, node in root:GetDescendants() do
		observe(node)
	end
end
local elapsed = 0
connect(game:GetService("RunService").Heartbeat, function(dt)
	local cutscene = gui:FindFirstChild("TreasureCutscenes")
	mixer:setBiome(workspace:FindFirstChild("CaveV2") and "cave" or "meadow")
	mixer:update(
		carry(),
		cutscene and cutscene.Enabled == true,
		player:GetAttribute("MusicMuted") == true,
		player:GetAttribute("SFXMuted") == true
	)
	elapsed += dt
	if elapsed < 0.1 then
		return
	end
	local sampleTime = elapsed
	elapsed = 0
	local cave = workspace:FindFirstChild("CaveV2")
	local seen = {}
	if cave then
		for _, cart in cave:GetChildren() do
			if cart.Name:match("^RideableCart") and cart:IsA("Model") then
				local part = cart.PrimaryPart
				if part then
					seen[part] = true
					local previous = cartSamples[part]
					local position = part.Position
					local state = cart:GetAttribute("State")
					local moving = previous
						and (position - previous).Magnitude / sampleTime > 0.5
						and state ~= "Dock"
						and state ~= "Flight"
						and state ~= "Fall"
					-- Cart samples are separate from signal subscriptions.
					cartSamples[part] = position
					mixer:cart(part, moving == true)
				end
			end
		end
	end
	for part in mixer.carts or {} do
		if not seen[part] then
			mixer:cart(part, false)
		end
	end
	for part in cartSamples do
		if not seen[part] then
			cartSamples[part] = nil
		end
	end
end)
script.Destroying:Connect(function()
	for _, connection in connections do
		connection:Disconnect()
	end
	for _, list in observed do
		for _, connection in list do
			connection:Disconnect()
		end
	end
	for node, prior in legacySounds do
		if node.Parent then
			node.SoundGroup = prior.group
		end
	end
	mixer:Destroy()
end)
