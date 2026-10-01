--!strict
-- Floating damage numbers where your shots land.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local HitMarker = ReplicatedStorage:WaitForChild("Remotes").HitMarker :: RemoteEvent

HitMarker.OnClientEvent:Connect(function(pos: Vector3, damage: number, killed: boolean)
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
	t.TextSize = if killed then 26 else 18
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
