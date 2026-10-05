--!strict
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

-- Unpublished places throw on store lookup; leaderboards then stay off so the game still runs
local winsOk, winsStore =
	pcall(DataStoreService.GetOrderedDataStore, DataStoreService, "Pumpkin_GlobalWins_v1")
local sizeOk, sizeStore =
	pcall(DataStoreService.GetOrderedDataStore, DataStoreService, "Pumpkin_GlobalSize_v1")
local enabled = winsOk and sizeOk
if not enabled then
	warn("Leaderboards disabled: DataStores unavailable (publish the place to enable)")
end

local Leaderboards = {}

local function formatValue(value: number): string
	if value >= 1e9 then
		return string.format("%.1fB", value / 1e9)
	elseif value >= 1e6 then
		return string.format("%.1fM", value / 1e6)
	elseif value >= 1e3 then
		return string.format("%.1fK", value / 1e3)
	end
	return tostring(math.floor(value))
end

local function render(boardName: string, title: string, store: any)
	local board = workspace:FindFirstChild(boardName, true)
	if not board or not board:IsA("BasePart") then
		return
	end
	local ok, pages = pcall(store.GetSortedAsync, store, false, 10)
	if not ok then
		return
	end

	local lines = { title }
	for rank, entry in pages:GetCurrentPage() do
		local userId = tonumber(entry.key)
		local name = if userId then "Player " .. tostring(userId) else tostring(entry.key)
		if userId then
			local nameOk, result = pcall(Players.GetNameFromUserIdAsync, Players, userId)
			if nameOk then
				name = result
			end
		end
		table.insert(lines, string.format("#%d  %s  %s", rank, name, formatValue(entry.value)))
	end

	local surface = board:FindFirstChild("GlobalLeaderboard") :: SurfaceGui?
	if not surface then
		surface = Instance.new("SurfaceGui")
		surface.Name = "GlobalLeaderboard"
		surface.Face = Enum.NormalId.Front
		surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		surface.PixelsPerStud = 45
		surface.Parent = board
	end
	local label = surface:FindFirstChild("Entries") :: TextLabel?
	if not label then
		label = Instance.new("TextLabel")
		label.Name = "Entries"
		label.BackgroundColor3 = Color3.fromRGB(13, 53, 63)
		label.BackgroundTransparency = 0.08
		label.Font = Enum.Font.GothamBlack
		label.Size = UDim2.fromScale(1, 1)
		label.TextColor3 = Color3.fromRGB(255, 250, 218)
		label.TextScaled = true
		label.TextStrokeTransparency = 0
		label.TextWrapped = true
		label.Parent = surface
	end
	label.Text = table.concat(lines, "\n")
end

function Leaderboards.record(player: Player, profile: any)
	if not enabled then
		return
	end
	task.spawn(function()
		pcall(winsStore.SetAsync, winsStore, tostring(player.UserId), math.floor(profile.Wins))
		pcall(
			sizeStore.SetAsync,
			sizeStore,
			tostring(player.UserId),
			math.floor(profile.BiggestPumpkin)
		)
	end)
end

function Leaderboards.refresh()
	if not enabled then
		return
	end
	render("Leaderboard_Wins", "★ GLOBAL WINS ★", winsStore)
	render("Leaderboard_Size", "🎃 BIGGEST PUMPKIN 🎃", sizeStore)
end

return Leaderboards
