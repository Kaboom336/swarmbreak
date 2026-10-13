local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local PromptService = game:GetService("ProximityPromptService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local remote = RS:WaitForChild("GreyboxAction")
local world = workspace:WaitForChild("GREYBOX")
local Config = require(RS:WaitForChild("GreyboxConfig"))
local Placement = require(RS:WaitForChild("GreyboxPlacement"))
local Scene = require(RS:WaitForChild("GreyboxScene"))
local lighting = game:GetService("Lighting")
local pollenVolume, pollenEmitter = Scene.pollen(workspace)
local function environment()
	local meadow = player:GetAttribute("GreyboxPhase") == "Run"
	Scene.environment(lighting, meadow)
	pollenEmitter.Enabled = false
	if not meadow then
		pollenEmitter:Clear()
	end
end
player:GetAttributeChangedSignal("GreyboxPhase"):Connect(environment)
environment()
local weatherElapsed = 0
RunService.RenderStepped:Connect(function(dt)
	weatherElapsed += dt
	if weatherElapsed < 0.25 then
		return
	end
	weatherElapsed = 0
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local enabled = player:GetAttribute("GreyboxPhase") == "Run" and root ~= nil
	if enabled then
		pollenVolume.Position = root.Position + Vector3.new(0, 8, 0)
	end
	pollenEmitter.Enabled = enabled
end)
local controls = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetControls()
local function testControls()
	if player:GetAttribute("GreyboxLoopTesting") then
		controls:Disable()
	else
		controls:Enable()
	end
end
player:GetAttributeChangedSignal("GreyboxLoopTesting"):Connect(testControls)
testControls()
PromptService.Enabled, PromptService.MaxPromptsVisible = true, 8
local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn = "GreyboxGoal", false
gui.Parent = player:WaitForChild("PlayerGui")
local goal = Instance.new("TextLabel")
goal.AnchorPoint, goal.Position = Vector2.new(0.5, 1), UDim2.fromScale(0.5, 0.96)
goal.Size, goal.BackgroundTransparency = UDim2.fromScale(0.9, 0.1), 0.2
goal.BackgroundColor3, goal.TextColor3 = Color3.fromRGB(30, 35, 40), Color3.new(1, 1, 1)
goal.TextSize, goal.TextWrapped = 20, true
goal.Parent = gui
local button = Instance.new("TextButton")
button.Name = "ActionButton"
button.AnchorPoint, button.Position = Vector2.new(0.5, 1), UDim2.fromScale(0.5, 0.82)
button.Size = UDim2.new(0.6, 0, 0, 72)
button.BackgroundColor3, button.TextColor3 = Color3.fromRGB(255, 170, 40), Color3.fromRGB(25, 30, 35)
button.TextSize, button.TextWrapped, button.Visible = 26, true, false
button.Parent = gui
local function refresh()
	goal.Text = (player:GetAttribute("GreyboxCarry") and "Carry 1/1 | " or "")
		.. (player:GetAttribute("GreyboxGoal") or "Enter the central portal.")
end
player:GetAttributeChangedSignal("GreyboxGoal"):Connect(refresh)
player:GetAttributeChangedSignal("GreyboxCarry"):Connect(refresh)
refresh()
local rotation, snap, candidate, placementActive = 0, false, nil, false
local ghost = Instance.new("Part")
ghost.Name, ghost.Size, ghost.Anchored = "PlacementGhost", Vector3.new(4, 0.15, 4), true
ghost.CanCollide, ghost.CanQuery, ghost.CanTouch = false, false, false
ghost.Material, ghost.Transparency = Enum.Material.Neon, 1
ghost.Parent = workspace
local function placementButton(name, x, width)
	local b = Instance.new("TextButton")
	b.Name, b.Text = name, name
	b.Position, b.Size = UDim2.fromScale(x, 0.7), UDim2.new(width, 0, 0, 48)
	b.BackgroundColor3, b.TextColor3 = Color3.fromRGB(40, 55, 65), Color3.new(1, 1, 1)
	b.TextSize, b.Visible, b.Parent = 18, false, gui
	return b
end
local placeButton = placementButton("Place [E / X]", 0.15, 0.3)
local rotateButton = placementButton("Rotate [R / Y]", 0.46, 0.2)
local snapButton = placementButton("Snap OFF [G / B]", 0.67, 0.2)
local function rotate()
	rotation = (rotation + 15) % 360
end
local function toggleSnap()
	snap = not snap
	snapButton.Text = "Snap " .. (snap and "ON" or "OFF") .. " [G / B]"
end
local function confirmPlacement()
	if placementActive and candidate then
		remote:FireServer("Place", candidate, rotation)
	end
end
placeButton.Activated:Connect(confirmPlacement)
rotateButton.Activated:Connect(rotate)
snapButton.Activated:Connect(toggleSnap)
UserInputService.InputBegan:Connect(function(input, processed)
	if processed or not placementActive then
		return
	end
	if input.KeyCode == Enum.KeyCode.R or input.KeyCode == Enum.KeyCode.ButtonY then
		rotate()
	elseif input.KeyCode == Enum.KeyCode.G or input.KeyCode == Enum.KeyCode.ButtonB then
		toggleSnap()
	elseif input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.ButtonX then
		confirmPlacement()
	end
end)
RunService.RenderStepped:Connect(function()
	placementActive = player:GetAttribute("GreyboxPhase") == "Home"
		and player:GetAttribute("GreyboxCarry") == true
		and not player:GetAttribute("GreyboxLoopTesting")
	placeButton.Visible, rotateButton.Visible, snapButton.Visible = placementActive, placementActive, placementActive
	ghost.Transparency, candidate = 1, nil
	local camera, slot = workspace.CurrentCamera, player:GetAttribute("GreyboxPen")
	local character = player.Character
	local r = character and character:FindFirstChild("HumanoidRootPart")
	if not placementActive or not camera or not slot or not r then
		return
	end
	local mouse = UserInputService:GetMouseLocation()
	local ray = camera:ScreenPointToRay(mouse.X, mouse.Y)
	if UserInputService.TouchEnabled or UserInputService:GetLastInputType() == Enum.UserInputType.Gamepad1 then
		ray = camera:ViewportPointToRay(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
	end
	if ray.Direction.Y >= -0.001 then
		return
	end
	local point = ray.Origin + ray.Direction * ((0.2 - ray.Origin.Y) / ray.Direction.Y)
	local x, z = point.X, point.Z
	if snap then
		x, z = math.round(x), math.round(z)
	end
	local occupied = {}
	for _, p in world:GetChildren() do
		if p:IsA("BasePart") and p:GetAttribute("PenSlot") == slot and p:GetAttribute("PlacementX") then
			table.insert(occupied, {
				x = p:GetAttribute("PlacementX"),
				z = p:GetAttribute("PlacementZ"),
				extent = p:GetAttribute("PlacementExtent"),
			})
		end
	end
	local valid = Placement.validate(Config, slot, x, z, rotation, occupied)
	point = Vector3.new(x, 0.2, z)
	valid = valid and (r.Position - point).Magnitude <= 24
	ghost.CFrame = CFrame.new(x, 0.3, z) * CFrame.Angles(0, math.rad(rotation), 0)
	ghost.Transparency = 0.45
	ghost.Color = valid and Color3.fromRGB(80, 240, 150) or Color3.fromRGB(255, 70, 70)
	placeButton.Text = valid and "Place [E / X]" or "Choose a free plot spot"
	if valid then
		candidate = point
	end
end)
local countdown = Instance.new("TextLabel")
countdown.Name = "EscapeCountdown"
countdown.AnchorPoint, countdown.Position = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.36)
countdown.Size, countdown.BackgroundTransparency = UDim2.fromOffset(300, 84), 1
countdown.Font, countdown.TextStrokeTransparency = Enum.Font.GothamBold, 0.2
countdown.Visible, countdown.Parent = false, gui
RunService.RenderStepped:Connect(function()
	local deadline = world:GetAttribute("EscapeDeadline")
	local remaining = deadline and math.max(0, deadline - workspace:GetServerTimeNow())
	countdown.Visible = player:GetAttribute("GreyboxPhase") == "Run" and remaining ~= nil
	if remaining then
		countdown.Text =
			string.format("Escape · %d:%02d", math.floor(math.ceil(remaining) / 60), math.ceil(remaining) % 60)
		countdown.TextSize = remaining <= 5 and 56 or 44
		countdown.TextColor3 = remaining <= 5 and Color3.fromRGB(255, 70, 70)
			or remaining <= 15 and Color3.fromRGB(255, 185, 50)
			or Color3.new(1, 1, 1)
	end
end)
local highlight = Instance.new("Highlight")
highlight.Name, highlight.FillTransparency, highlight.OutlineColor = "OwnPen", 1, Color3.fromRGB(255, 220, 80)
highlight.Parent = gui

local prompts, shown = {}, {}
local function configurePen(q)
	local slot = q:GetAttribute("PenSlot")
	-- The ONLY client Enabled mutation is for an explicitly tagged pen action.
	if q:GetAttribute("GreyboxAction") == "Place" and slot ~= nil then
		local enabled = slot == player:GetAttribute("GreyboxPen")
		if q.Enabled ~= enabled then
			q.Enabled = enabled
		end
	end
end
local function register(q)
	if q:IsA("ProximityPrompt") and q:GetAttribute("GreyboxAction") then
		prompts[q] = true
		configurePen(q)
		local function selfBump()
			if
				q:GetAttribute("GreyboxAction") == "Bump"
				and q:GetAttribute("CarrierUserId") == player.UserId
				and q.Enabled
			then
				q.Enabled = false
			end
		end
		selfBump()
		q:GetAttributeChangedSignal("CarrierUserId"):Connect(selfBump)
		q:GetPropertyChangedSignal("Enabled"):Connect(selfBump)
		q:GetAttributeChangedSignal("PenSlot"):Connect(function()
			configurePen(q)
		end)
	end
end
workspace.DescendantAdded:Connect(register)
workspace.DescendantRemoving:Connect(function(q)
	prompts[q], shown[q] = nil, nil
end)
for _, q in workspace:GetDescendants() do
	register(q)
end
player:GetAttributeChangedSignal("GreyboxPen"):Connect(function()
	for q in prompts do
		configurePen(q)
	end
end)
PromptService.PromptShown:Connect(function(q)
	if prompts[q] then
		shown[q] = true
		player:SetAttribute("GreyboxPromptShownCount", (player:GetAttribute("GreyboxPromptShownCount") or 0) + 1)
		print("[GreyboxPrompt] SHOWN " .. q:GetFullName())
	end
end)
PromptService.PromptHidden:Connect(function(q)
	shown[q] = nil
end)
print(
	"[GreyboxPrompt] client ready; service Enabled="
		.. tostring(PromptService.Enabled)
		.. " MaxPromptsVisible="
		.. PromptService.MaxPromptsVisible
)
player:SetAttribute("GreyboxClientReady", true)

local selected, holding, heldInput
local sentFinish = false
local began = 0
local function cancelHold()
	if holding and not sentFinish then
		remote:FireServer(holding:GetAttribute("GreyboxAction"), "cancel")
	end
	holding, heldInput, sentFinish = nil, nil, false
end
local function beginHold(input)
	if not selected or not Config.HoldSeconds[selected:GetAttribute("GreyboxAction")] or holding then
		return
	end
	holding, heldInput, began, sentFinish = selected, input, os.clock(), false
	remote:FireServer(selected:GetAttribute("GreyboxAction"), "begin")
end
button.Activated:Connect(function()
	if selected and not Config.HoldSeconds[selected:GetAttribute("GreyboxAction")] then
		remote:FireServer(selected:GetAttribute("GreyboxAction"))
	end
end)
button.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		beginHold(input)
	end
end)
UserInputService.InputBegan:Connect(function(input, processed)
	if processed or not selected or shown[selected] then
		return -- native E/X owns input while its prompt is visible
	end
	if input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.ButtonX then
		if Config.HoldSeconds[selected:GetAttribute("GreyboxAction")] ~= nil then
			beginHold(input)
		else
			remote:FireServer(selected:GetAttribute("GreyboxAction"))
		end
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if
		input == heldInput
		or (
			heldInput
			and input.UserInputType ~= Enum.UserInputType.Touch
			and input.UserInputType == heldInput.UserInputType
			and input.KeyCode == heldInput.KeyCode
		)
	then
		cancelHold()
	end
end)
UserInputService.WindowFocusReleased:Connect(cancelHold)
remote.OnClientEvent:Connect(function(ok, reason)
	if not ok then
		goal.Text = "Action refused: " .. tostring(reason)
	end
end)

local portalInRange = false
RunService.RenderStepped:Connect(function()
	local character = player.Character
	local r = character and character:FindFirstChild("HumanoidRootPart")
	local slot = player:GetAttribute("GreyboxPen")
	highlight.Adornee = slot and world:FindFirstChild("PenMarker" .. slot) or nil
	local nearest, distance = nil, math.huge
	local phase, carrying = player:GetAttribute("GreyboxPhase"), player:GetAttribute("GreyboxCarry")
	if r then
		for q in prompts do
			local action, parent = q:GetAttribute("GreyboxAction"), q.Parent
			local owner = q:GetAttribute("OwnerUserId")
			local legal = (action == "Enter" and phase == "Home" and not carrying)
				or (action == "Return" and phase == "Run")
				or (action == "Steal" and phase == "Run" and not carrying)
				or (action == "Grab" and phase == "Run" and not carrying)
				or (action == "Bump" and phase == "Run" and not carrying and q:GetAttribute("CarrierUserId") ~= player.UserId)
				or (action == "Place" and phase == "Home" and carrying and q:GetAttribute("PenSlot") == slot)
			if
				legal
				and q.Enabled
				and parent
				and parent:IsA("Attachment")
				and (not owner or owner == player.UserId)
			then
				local d = (r.Position - parent.WorldPosition).Magnitude
				local clear = true
				if action == "Bump" or action == "Grab" then
					local params = RaycastParams.new()
					params.FilterType, params.FilterDescendantsInstances =
						Enum.RaycastFilterType.Include, { world:FindFirstChild("SharedIsland") }
					clear = workspace:Raycast(r.Position, parent.WorldPosition - r.Position, params) == nil
				end
				if d <= q.MaxActivationDistance and d < distance and clear then
					nearest, distance = q, d
				end
			end
		end
	end
	selected = nearest
	if holding and holding ~= selected then
		cancelHold()
	end
	button.Visible = selected ~= nil and not player:GetAttribute("GreyboxLoopTesting")
	if selected then
		local action = selected:GetAttribute("GreyboxAction")
		button.Text = Config.HoldSeconds[action] and ("Hold to " .. action .. " [E / X]") or action .. " [E / X]"
		if holding then
			local elapsed = os.clock() - began
			button.Text =
				string.format("Hold %d%%", math.min(100, math.floor(elapsed / Config.HoldSeconds[action] * 100)))
			if elapsed >= Config.HoldSeconds[action] and not sentFinish then
				sentFinish = true
				remote:FireServer(selected:GetAttribute("GreyboxAction"), "finish")
			end
		end
	end
	local portal = world:FindFirstChild("HomePortal", true)
	local inRange = r and portal and (r.Position - portal.Position).Magnitude <= 9
	if inRange and not portalInRange then
		local q = portal:FindFirstChild("ActionPoint"):FindFirstChildOfClass("ProximityPrompt")
		local localPos, half = portal.CFrame:PointToObjectSpace(r.Position), portal.Size / 2
		local surface = Vector3.new(
			math.max(0, math.abs(localPos.X) - half.X),
			math.max(0, math.abs(localPos.Y) - half.Y),
			math.max(0, math.abs(localPos.Z) - half.Z)
		).Magnitude
		local centre = (r.Position - portal.Position).Magnitude
		local camera = workspace.CurrentCamera
		local cameraDistance = camera and (camera.CFrame.Position - portal.Position).Magnitude or -1
		player:SetAttribute("GreyboxPortalCentreDistance", centre)
		player:SetAttribute("GreyboxPortalSurfaceDistance", surface)
		print(
			string.format(
				"[GreyboxPrompt] portal range centre=%.3f surface=%.3f camera=%.3f enabled=%s service=%s maxVisible=%d style=%s shown=%s",
				centre,
				surface,
				cameraDistance,
				tostring(q.Enabled),
				tostring(PromptService.Enabled),
				PromptService.MaxPromptsVisible,
				q.Style.Name,
				tostring(shown[q] == true)
			)
		)
		if not PromptService.Enabled or PromptService.MaxPromptsVisible == 0 then
			warn("[GreyboxPrompt] global prompt service suppresses native UI; fallback remains available")
		end
	end
	portalInRange = inRange == true
end)
