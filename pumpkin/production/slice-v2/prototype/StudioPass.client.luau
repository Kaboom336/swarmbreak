-- Local, non-collidable debug geometry and camera capture; never enabled in live servers.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Run = game:GetService("RunService")
if not Run:IsStudio() then
	return
end
local player = Players.LocalPlayer
local control = RS:WaitForChild("StudioPassControl")
local routes = require(RS:WaitForChild("MeadowV4"):WaitForChild("RouteData"))
local origin = Vector3.new(0, 76, -360)
local function point(p)
	return origin + Vector3.new(p.x, p.y, -p.z)
end
local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn, gui.Parent = "StudioPassDebug", false, player:WaitForChild("PlayerGui")
local text = Instance.new("TextLabel")
text.Size, text.Position = UDim2.fromOffset(580, 82), UDim2.new(0, 12, 1, -96)
text.BackgroundTransparency, text.TextColor3, text.TextSize = 0.25, Color3.new(1, 1, 1), 16
text.TextXAlignment, text.Parent = Enum.TextXAlignment.Left, gui
local folder, timers, last = nil, {}, "No completed route"
local function toggle()
	if folder then
		folder:Destroy()
		folder = nil
	end
	timers, last = {}, "No completed route"
	gui.Enabled = control:GetAttribute("ShowDebug") == true
	if not gui.Enabled then
		return
	end
	folder = Instance.new("Folder")
	folder.Name, folder.Parent = "StudioPassRouteLines", workspace
	local keys = {}
	for name in routes do
		table.insert(keys, name)
	end
	table.sort(keys)
	for index, name in keys do
		local route = routes[name]
		for i = 2, #route do
			local a, b = point(route[i - 1]) + Vector3.new(0, 0.4, 0), point(route[i]) + Vector3.new(0, 0.4, 0)
			if (b - a).Magnitude < 0.01 then
				continue
			end
			local line = Instance.new("Part")
			line.Name, line.Size, line.CFrame =
				name, Vector3.new(0.13, 0.13, (b - a).Magnitude), CFrame.lookAt((a + b) / 2, b)
			line.Anchored, line.CanCollide, line.CanQuery, line.CanTouch = true, false, false, false
			line.Material, line.Color, line.Parent = Enum.Material.Neon, Color3.fromHSV(index / #keys, 0.8, 1), folder
		end
	end
end
control:GetAttributeChangedSignal("ShowDebug"):Connect(toggle)
toggle()
local tickAt = 0
Run.RenderStepped:Connect(function()
	if not gui.Enabled or os.clock() < tickAt then
		return
	end
	tickAt = os.clock() + 0.1
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local current = {}
	for name, route in routes do
		-- Endpoint gates: elapsed includes turns, combat and pauses; this is not a centerline proof.
		local a, b =
			(root.Position - point(route[1])).Magnitude < 6, (root.Position - point(route[#route])).Magnitude < 6
		local timer = timers[name]
		if not timer and (a or b) then
			timers[name] =
				{ began = os.clock(), reverse = b and not a, left = false, carry = player:GetAttribute("GreyboxCarry") }
		elseif timer then
			if not a and not b then
				timer.left = true
			end
			if timer.left and (timer.reverse and a or not timer.reverse and b) then
				last = string.format(
					"%s %s %s %.2fs",
					name,
					timer.reverse and "reverse" or "forward",
					timer.carry and "carry" or "empty",
					os.clock() - timer.began
				)
				player:SetAttribute("StudioPassWalkTime", last)
				print("[StudioPassWalkTime] " .. last)
				timers[name] = nil
			else
				table.insert(current, string.format("%s %.1fs", name, os.clock() - timer.began))
			end
		end
	end
	table.sort(current)
	local handle = workspace:FindFirstChild("GREYBOX")
	handle = handle and handle:FindFirstChild("Guardian", true)
	text.Text = "Keeper: "
		.. tostring(control:GetAttribute("KeeperState"))
		.. "/"
		.. tostring(handle and handle:GetAttribute("KeeperClip"))
		.. " | exit "
		.. tostring(workspace:GetAttribute("TunnelGuardedExit"))
		.. " | guarding "
		.. tostring(workspace:GetAttribute("TunnelGuardWaiting"))
		.. "\n"
		.. last
		.. "\n"
		.. table.concat(current, " | ")
end)
local generation = 0
local function capture()
	generation += 1
	local token = generation
	task.spawn(function()
		local camera = workspace.CurrentCamera
		if not camera then
			return
		end
		local cutscenes = player.PlayerGui:FindFirstChild("TreasureCutscenes")
		local release = cutscenes and cutscenes:FindFirstChild("ReleaseCamera")
		if release then release:Invoke() end -- Local presentation only; save the released camera.
		local saved = { camera.CameraType, camera.CFrame, camera.FieldOfView, camera.CameraSubject }
		local shots = {
			{ "portal", Vector3.new(0, 5.5, 130), Vector3.new(0, 53, -96), 70 },
			{ "summit", Vector3.new(0, 53.5, -96), Vector3.new(-76, 5.5, -27), 70 },
			{ "bridge", Vector3.new(0, 9, 0), Vector3.new(40, 0, 24), 70 },
			{ "tunnel mouth", Vector3.new(-76, 5.5, -35), Vector3.new(-76, 5.5, 5), 70 },
			{ "tunnel inside", Vector3.new(-76, 5.5, 0), Vector3.new(-76, 5.5, 35), 70 },
			{ "east ridge", Vector3.new(148, 25.5, 24), Vector3.new(148, 27.5, 56), 70 },
			{ "home island", Vector3.new(0, 150, 260) - origin, Vector3.new(0, 4, 0) - origin, 40 },
		}
		local pet
		for _, node in workspace:WaitForChild("GREYBOX"):GetDescendants() do
			if
				node:IsA("BasePart")
				and node:GetAttribute("CoreState") == "Pet"
				and node:GetAttribute("PenSlot") == player:GetAttribute("GreyboxPen")
			then
				pet = node
				break
			end
		end
		local target = pet and pet.Position
			or (player.Character and player.Character:GetPivot().Position or Vector3.new(0, 4, 0))
		table.insert(shots, { "pet reveal", target - origin + Vector3.new(8, 5, 10), target - origin, 50 })
		local selected
		Run:BindToRenderStep("StudioPassCapture", Enum.RenderPriority.Camera.Value + 1, function()
			if selected then
				camera.CameraType = Enum.CameraType.Scriptable
				camera.CFrame, camera.FieldOfView =
					CFrame.lookAt(origin + selected[2], origin + selected[3]), selected[4]
			end
		end)
		local ok, why = pcall(function()
			for _, shot in shots do
				if token ~= generation then
					break
				end
				selected = shot
				player:SetAttribute("StudioPassShot", shot[1])
				print(
					"[CaptureShots] "
						.. shot[1]
						.. (shot[1] == "pet reveal" and not pet and " MISSING PET: complete manual Open first" or "")
				)
				task.wait(2)
			end
		end)
		Run:UnbindFromRenderStep("StudioPassCapture")
		camera.CameraType, camera.CFrame, camera.FieldOfView, camera.CameraSubject =
			saved[1], saved[2], saved[3], saved[4]
		player:SetAttribute(
			"StudioPassShot",
			ok and (pet and "DONE" or "FAIL: pet reveal missing") or "FAIL: " .. tostring(why)
		)
	end)
end
local capturing = false
control:GetAttributeChangedSignal("CaptureShots"):Connect(function()
	if capturing then
		return
	end
	capturing = true
	capture()
	task.delay(17, function()
		capturing = false
	end)
end)
