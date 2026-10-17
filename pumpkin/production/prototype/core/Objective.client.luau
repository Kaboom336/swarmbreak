-- Read replicated display signals only; never writes gameplay state or sends input.
local RS = game:GetService("ReplicatedStorage")
local Run = game:GetService("RunService")
local Tween = game:GetService("TweenService")
local player = game:GetService("Players").LocalPlayer
local Style = require(RS:WaitForChild("UIStyle"))
local UI = require(RS:WaitForChild("TreasureCore"):WaitForChild("UIPresentation"))
local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn, gui.DisplayOrder = "TreasureObjective", false, 21
gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
gui.Parent = player:WaitForChild("PlayerGui")
local banner = Instance.new("TextLabel")
banner.Name, banner.Text = "ObjectiveBanner", ""
Style.panel(banner, Style.Colors.Panel, 22)
banner.AnchorPoint, banner.Parent = Vector2.new(0.5, 0), gui
local icon = Style.icon(banner, "route", Style.Colors.Cyan)
banner.PanelPadding.PaddingLeft = UDim.new(0, 48)
icon.Position = UDim2.new(0, -36, 0.5, 0)
local timer = Instance.new("TextLabel")
timer.Name, timer.Text = "CarryTimer", ""
Style.panel(timer, Style.Colors.Panel, 16)
timer.AnchorPoint, timer.Parent = Vector2.new(0.5, 0), gui
local track = Instance.new("Frame")
track.Name, track.Size, track.Position = "Track", UDim2.new(0.52, 0, 0, 6), UDim2.new(0, 0, 1, -6)
track.BorderSizePixel, track.BackgroundColor3, track.Parent = 0, Style.Colors.Ink, timer
local fill = Instance.new("Frame")
fill.Name, fill.Size, fill.BorderSizePixel, fill.BackgroundColor3, fill.Parent =
	"Fill", UDim2.fromScale(1, 1), 0, Style.Colors.Cyan, track
local captionPad = timer.PanelPadding
captionPad.PaddingLeft, captionPad.PaddingRight = UDim.new(), UDim.new()
captionPad.PaddingTop, captionPad.PaddingBottom = UDim.new(), UDim.new()
timer.BackgroundTransparency = 1
for _, name in { "PanelEdge", "PanelShadow", "PanelGradient" } do
	timer[name]:Destroy()
end
track.Size, track.Position = UDim2.fromScale(1, 1), UDim2.fromScale(0, 0)
local slide = Instance.new("UIScale")
slide.Parent = banner
local activeTween, previous, full, timerIdentity = nil, nil, nil, nil
local function fit()
	local v = gui.AbsoluteSize
	local y = 8
	local width = UI.bannerWidth(v.X)
	banner.Position, banner.Size = UDim2.new(0.5, 0, 0, y), UDim2.fromOffset(width, 44)
	timer.Position, timer.Size = UDim2.new(0.5, 0, 0, y + 38), UDim2.fromOffset(width - 24, 4)
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
fit()
local nextUpdate = 0
local connection = Run.RenderStepped:Connect(function()
	if os.clock() < nextUpdate then
		return
	end
	nextUpdate = os.clock() + 0.05
	local world, cave = workspace:FindFirstChild("GREYBOX"), workspace:FindFirstChild("CaveV2")
	local character = player.Character
	local hum = character and character:FindFirstChildOfClass("Humanoid")
	local alive = hum ~= nil and hum.Health > 0
	local carrying = player:GetAttribute("GreyboxCarry") == true or player:GetAttribute("CaveItemID") ~= nil
	-- Cave keeps the cargo id on a dropped item; its existing recovery prompt exposes that state.
	if cave then
		local geode = cave:FindFirstChild("Geode")
		if geode then
			for _, p in geode:GetChildren() do
				if p:IsA("ProximityPrompt") and p.ActionText == "Recover geode" and p.Enabled then
					carrying = false
				end
			end
		end
	end
	carrying = alive and carrying
	local goal = UI.objective({
		carry = carrying,
		cave = cave ~= nil,
		secured = player:GetAttribute("CaveSecured"),
		phase = player:GetAttribute("GreyboxPhase"),
		goal = player:GetAttribute("GreyboxGoal"),
	})
	-- Preserve existing local refusal feedback without adding an input path.
	local legacyGui = player.PlayerGui:FindFirstChild("GreyboxGoal")
	local legacy = legacyGui and legacyGui:FindFirstChild("Objective")
	if legacy and legacy.Text:find("Action refused:", 1, true) == 1 then
		goal = legacy.Text
	end
	if goal ~= previous then
		previous, banner.Text = goal, goal
		if activeTween then
			activeTween:Cancel()
			activeTween:Destroy()
			activeTween = nil
		end
		slide.Scale = 1
		if not player:GetAttribute("ReducedMotion") then
			slide.Scale = 0.94
			activeTween = Tween:Create(slide, TweenInfo.new(0.22, Enum.EasingStyle.Back), { Scale = 1 })
			activeTween:Play()
		end
	end
	local phase = player:GetAttribute("GreyboxPhase")
	local deadline = world and world:GetAttribute("EscapeDeadline")
	local identity = cave and player:GetAttribute("CaveItemID") or (phase == "Run" and deadline or nil)
	if identity ~= timerIdentity then
		full, timerIdentity = nil, identity
	end
	local remaining = UI.timer(
		carrying and (cave ~= nil or phase == "Run"),
		deadline,
		workspace:GetServerTimeNow(),
		player:GetAttribute("CaveSecondsLeft")
	)
	timer.Visible = remaining ~= nil
	banner.PanelPadding.PaddingBottom = UDim.new(0, remaining and 10 or 5)
	banner.Text = goal .. (remaining and (" · " .. tostring(math.ceil(remaining)) .. "s") or "")
	if remaining then
		full = math.max(full or remaining, remaining, 1)
		fill.Size = UDim2.fromScale(math.clamp(remaining / full, 0, 1), 1)
		fill.BackgroundColor3 = remaining <= 5 and Style.Colors.Danger or Style.Colors.Cyan
		timer.TextColor3 = fill.BackgroundColor3
		timer.Text = ""
	end
end)
player:GetAttributeChangedSignal("ReducedMotion"):Connect(function()
	if player:GetAttribute("ReducedMotion") then
		if activeTween then
			activeTween:Cancel()
		end
		slide.Scale = 1
	end
end)
script.Destroying:Connect(function()
	connection:Disconnect()
	if activeTween then
		activeTween:Cancel()
		activeTween:Destroy()
	end
	gui:Destroy()
end)
