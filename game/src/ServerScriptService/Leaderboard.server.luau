--!strict
-- Global top-10 best wave board on the arena wall. Refreshes every 60 s.
local ServerStorage = game:GetService("ServerStorage")
local PlayerData = require(ServerStorage.PlayerData)

local arena = workspace:WaitForChild("Arena")
local board = arena:WaitForChild("LeaderboardWall") :: BasePart

local gui = Instance.new("SurfaceGui")
gui.Face = Enum.NormalId.Front
gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
gui.PixelsPerStud = 40
gui.Parent = board

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0.15, 0)
title.BackgroundTransparency = 1
title.Text = "TOP SURVIVORS"
title.Font = Enum.Font.GothamBlack
title.TextScaled = true
title.TextColor3 = Color3.fromRGB(255, 200, 60)
title.Parent = gui

local list = Instance.new("TextLabel")
list.Position = UDim2.new(0.05, 0, 0.17, 0)
list.Size = UDim2.new(0.9, 0, 0.8, 0)
list.BackgroundTransparency = 1
list.Text = "Loading..."
list.Font = Enum.Font.Gotham
list.TextScaled = true
list.TextXAlignment = Enum.TextXAlignment.Left
list.TextYAlignment = Enum.TextYAlignment.Top
list.TextColor3 = Color3.new(1, 1, 1)
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
