--!strict
-- Global top-10 best wave board in the Base. Refreshes every 60 s.
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local WeeklyBoard = require(ReplicatedStorage.Shared.WeeklyBoard)
local UiTheme = require(ReplicatedStorage.Shared.UiTheme)
local PlayerData = require(ServerStorage.PlayerData)

-- Keep a separate OrderedDataStore for each Monday-based UTC week. The all-time board below
-- continues to use PlayerData's existing store and display.
local state = ReplicatedStorage:WaitForChild("State")
local phase = state:WaitForChild("Phase") :: StringValue
local wave = state:WaitForChild("Wave") :: IntValue
local runStartedAt: number? = nil

phase:GetPropertyChangedSignal("Value"):Connect(function()
	if phase.Value == "starting" and wave.Value == 1 then
		runStartedAt = os.time()
	elseif phase.Value == "over" and runStartedAt then
		local finishedAt = os.time()
		local runScore = WeeklyBoard.score(wave.Value, math.max(0, finishedAt - runStartedAt))
		runStartedAt = nil
		for _, plr in Players:GetPlayers() do
			task.spawn(function()
				pcall(function()
					local weeklyStore =
						DataStoreService:GetOrderedDataStore(WeeklyBoard.key(finishedAt))
					weeklyStore:UpdateAsync(tostring(plr.UserId), function(old)
						return math.max(old or 0, runScore)
					end)
				end)
			end)
		end
	end
end)

local base = workspace:WaitForChild("Base")
local board = base:WaitForChild("LeaderboardWall") :: BasePart

local gui = Instance.new("SurfaceGui")
gui.Face = Enum.NormalId.Front
gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
gui.PixelsPerStud = 40
gui.Parent = board

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0.15, 0)
title.BackgroundTransparency = 1
title.Text = "TOP SURVIVORS"
title.Font = if UiTheme.Font.Title == "FredokaOne"
	then Enum.Font.FredokaOne
	else Enum.Font.GothamBold
title.TextScaled = true
title.TextColor3 =
	Color3.fromRGB(UiTheme.Colors.Accent[1], UiTheme.Colors.Accent[2], UiTheme.Colors.Accent[3])
title.Parent = gui

local list = Instance.new("TextLabel")
list.Position = UDim2.new(0.05, 0, 0.17, 0)
list.Size = UDim2.new(0.9, 0, 0.8, 0)
list.BackgroundTransparency = 1
list.Text = "Loading..."
list.Font = if UiTheme.Font.Body == "GothamBold" then Enum.Font.GothamBold else Enum.Font.FredokaOne
list.TextScaled = true
list.TextXAlignment = Enum.TextXAlignment.Left
list.TextYAlignment = Enum.TextYAlignment.Top
list.TextColor3 =
	Color3.fromRGB(UiTheme.Colors.Text[1], UiTheme.Colors.Text[2], UiTheme.Colors.Text[3])
list.Parent = gui

while true do
	local rows = PlayerData.topWaves(10)
	if #rows == 0 then
		list.Text = "No runs yet. Be the first!"
	else
		local lines = {}
		for i, row in rows do
			table.insert(lines, string.format("%2d. %-20s wave %d", i, row.Name, row.Wave))
		end
		list.Text = table.concat(lines, "\n")
	end
	task.wait(60)
end
