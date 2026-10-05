--!strict
-- Pooled, screen-space anime accents shared by combat and movement.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Rules = require(ReplicatedStorage.Shared.ScreenEffects)
local Theme = require(ReplicatedStorage.Shared.Theme)

local AnimeEffects = {}
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local gui = Instance.new("ScreenGui")
gui.Name = "AnimeEffects"
gui.DisplayOrder = 40
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.Parent = playerGui

local impactFrame = Instance.new("Frame")
impactFrame.Name = "KillImpactFrame"
impactFrame.Size = UDim2.fromScale(1, 1)
impactFrame.BackgroundColor3 = Color3.new(1, 1, 1)
impactFrame.BorderSizePixel = 0
impactFrame.Visible = false
impactFrame.ZIndex = 100
impactFrame.Parent = gui
local impactToken = 0
local impactTween: Tween? = nil

local function color(values: { number }): Color3
	return Color3.fromRGB(values[1], values[2], values[3])
end

local marker = Instance.new("Frame")
marker.Name = "HitMarker"
marker.AnchorPoint = Vector2.new(0.5, 0.5)
marker.Position = UDim2.fromScale(0.5, 0.5)
marker.Size = UDim2.fromOffset(34, 34)
marker.BackgroundTransparency = 1
marker.Visible = false
marker.Parent = gui
local markerScale = Instance.new("UIScale")
markerScale.Parent = marker
for index, rotation in { 45, -45 } do
	local shadow = Instance.new("Frame")
	shadow.Name = "Ink" .. index
	shadow.AnchorPoint = Vector2.new(0.5, 0.5)
	shadow.Position = UDim2.fromScale(0.5, 0.5)
	shadow.Size = UDim2.fromOffset(34, 8)
	shadow.Rotation = rotation
	shadow.BackgroundColor3 = color(Theme.ChitinDark)
	shadow.BorderSizePixel = 0
	shadow.Parent = marker
	local slash = Instance.new("Frame")
	slash.Name = "Slash"
	slash.Position = UDim2.fromOffset(3, 2)
	slash.Size = UDim2.new(1, -6, 1, -4)
	slash.BackgroundColor3 = Color3.new(1, 1, 1)
	slash.BorderSizePixel = 0
	slash.Parent = shadow
end

local markerToken = 0
local markerTween: Tween? = nil
function AnimeEffects.hitMarker(critical: boolean?)
	markerToken += 1
	local token = markerToken
	if markerTween then
		markerTween:Cancel()
	end
	markerScale.Scale = if critical then 1.35 else 1.1
	marker.Rotation = if critical then 12 else 0
	marker.Visible = true
	markerTween = TweenService:Create(
		markerScale,
		TweenInfo.new(Rules.HitMarkerSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Scale = 0.8 }
	)
	markerTween:Play()
	task.delay(Rules.HitMarkerSeconds, function()
		if markerToken == token then
			marker.Visible = false
		end
	end)
end

function AnimeEffects.impactFrame(accent: Color3, duration: number)
	impactToken += 1
	local token = impactToken
	if impactTween then
		impactTween:Cancel()
	end
	impactFrame.BackgroundColor3 = Color3.new(1, 1, 1)
	impactFrame.BackgroundTransparency = 0
	impactFrame.Visible = true
	impactTween = TweenService:Create(impactFrame, TweenInfo.new(duration), {
		BackgroundColor3 = accent,
		BackgroundTransparency = 1,
	})
	impactTween:Play()
	task.delay(duration, function()
		if impactToken == token then
			impactFrame.Visible = false
		end
	end)
end

type SpeedLine = {
	Image: ImageLabel,
	Fallback: Frame,
	Token: number,
	ImageTween: Tween?,
	FallbackTween: Tween?,
}

local speedLines: { SpeedLine } = {}
for index = 1, 12 do
	local onLeft = index <= 6
	local row = (index - 1) % 6
	local image = Instance.new("ImageLabel")
	image.Name = "SpeedLine" .. index
	image.AnchorPoint = Vector2.new(if onLeft then 0 else 1, 0.5)
	image.Position = UDim2.fromScale(if onLeft then 0 else 1, 0.12 + row * 0.15)
	image.Size = UDim2.new(0.22, 0, 0, 3)
	image.BackgroundTransparency = 1
	image.Image = if Rules.TextureIds.SpeedLines == 0
		then ""
		else "rbxassetid://" .. tostring(Rules.TextureIds.SpeedLines)
	image.ImageColor3 = color(Theme.Goo)
	image.Visible = false
	image.Parent = gui
	local fallback = Instance.new("Frame")
	fallback.Name = "Fallback"
	fallback.Size = UDim2.fromScale(1, 1)
	fallback.BackgroundColor3 = color(Theme.Goo)
	fallback.BorderSizePixel = 0
	fallback.Visible = Rules.TextureIds.SpeedLines == 0
	fallback.Parent = image
	table.insert(speedLines, {
		Image = image,
		Fallback = fallback,
		Token = 0,
		ImageTween = nil,
		FallbackTween = nil,
	})
end

function AnimeEffects.speedLines(kind: string?)
	local tint = if kind == "Ultimate" then color(Theme.Loot) else color(Theme.Goo)
	for index, entry in speedLines do
		entry.Token += 1
		local token = entry.Token
		if entry.ImageTween then
			entry.ImageTween:Cancel()
		end
		if entry.FallbackTween then
			entry.FallbackTween:Cancel()
		end
		entry.Image.ImageColor3 = tint
		entry.Fallback.BackgroundColor3 = tint
		entry.Image.ImageTransparency = 0.1
		entry.Fallback.BackgroundTransparency = 0.08
		entry.Image.Size = UDim2.new(0.12 + (index % 3) * 0.04, 0, 0, 3)
		entry.Image.Visible = true
		entry.ImageTween = TweenService:Create(
			entry.Image,
			TweenInfo.new(Rules.SpeedLineSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ ImageTransparency = 1, Size = UDim2.new(0.26, 0, 0, 1) }
		)
		entry.FallbackTween = TweenService:Create(
			entry.Fallback,
			TweenInfo.new(Rules.SpeedLineSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ BackgroundTransparency = 1 }
		)
		entry.ImageTween:Play()
		entry.FallbackTween:Play()
		task.delay(Rules.SpeedLineSeconds, function()
			if entry.Token == token then
				entry.Image.Visible = false
			end
		end)
	end
end

function AnimeEffects.slam(label: TextLabel)
	local scale = label:FindFirstChild("SlamScale") :: UIScale?
	if not scale then
		scale = Instance.new("UIScale")
		scale.Name = "SlamScale"
		scale.Parent = label
	end
	scale.Scale = 1.35
	label.Rotation = -2
	TweenService:Create(
		scale,
		TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Scale = 1 }
	):Play()
	TweenService:Create(label, TweenInfo.new(0.12, Enum.EasingStyle.Quad), { Rotation = 0 }):Play()
end

return AnimeEffects
