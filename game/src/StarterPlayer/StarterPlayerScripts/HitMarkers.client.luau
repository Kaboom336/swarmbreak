--!strict
-- Floating damage numbers where your shots land.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Feel = require(ReplicatedStorage.Shared.Feel)
local SfxMap = require(ReplicatedStorage.Shared.SfxMap)
local ClientFX = require(script.Parent.ClientFX)
local HitMarker = ReplicatedStorage:WaitForChild("Remotes").HitMarker :: RemoteEvent
local numberState: Feel.NumberState = {}

HitMarker.OnClientEvent:Connect(function(pos: Vector3, damage: number, killed: boolean)
	local event: Feel.EventName = if killed then "Kill" else "Hit"
	if killed then
		local soundName = SfxMap.forEvent("enemy kill")
		if soundName then
			ClientFX.sound(soundName)
		end
	end
	ClientFX.shakeFor(event, "Full")
	local allowed: boolean
	numberState, allowed = Feel.allowNumber(numberState, os.clock())
	if not allowed then
		return
	end
	local budget = Feel.Events[event]
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(0.1, 0.1, 0.1)
	anchor.Position = pos
	anchor.Parent = workspace
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(80, 30)
	bb.AlwaysOnTop = true
	bb.Parent = anchor
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.GothamBlack
	t.TextSize = math.round(18 * budget.NumberScale)
	t.TextColor3 = if killed then Color3.fromRGB(255, 80, 80) else Color3.fromRGB(255, 240, 150)
	t.TextStrokeTransparency = 0.3
	t.Text = tostring(damage)
	t.Parent = bb
	TweenService:Create(bb, TweenInfo.new(0.6, Enum.EasingStyle.Quad), {
		StudsOffset = Vector3.new(0, 3, 0),
	}):Play()
	TweenService:Create(t, TweenInfo.new(0.6), { TextTransparency = 1, TextStrokeTransparency = 1 })
		:Play()
	Debris:AddItem(anchor, 0.7)
end)
