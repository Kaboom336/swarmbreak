--!strict
-- Reusable Roblox constructors backed by the engine-free UiTheme tokens.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local UiTheme = require(ReplicatedStorage.Shared.UiTheme)

local UiKit = {}

local fontsByToken = {
	FredokaOne = Enum.Font.FredokaOne,
	GothamBold = Enum.Font.GothamBold,
	LuckiestGuy = Enum.Font.LuckiestGuy,
}
UiKit.Fonts = {
	Body = fontsByToken[UiTheme.Font.Body],
	Title = fontsByToken[UiTheme.Font.Title],
	Number = fontsByToken[UiTheme.Font.Number],
	Banner = fontsByToken[UiTheme.Font.Banner],
}

local function color(value: { number }): Color3
	return Color3.fromRGB(value[1], value[2], value[3])
end

local function corner(parent: Instance, radius: number)
	local item = Instance.new("UICorner")
	item.CornerRadius = UDim.new(0, radius)
	item.Parent = parent
end

local function stroke(parent: Instance)
	local item = Instance.new("UIStroke")
	item.Name = "Outline"
	item.Color = color(UiTheme.Stroke.Color)
	item.Thickness = UiTheme.Stroke.Thickness
	item.Transparency = UiTheme.Stroke.Transparency
	item.Parent = parent
end

local function shadowFor(panel: GuiObject)
	local shadow = Instance.new("Frame")
	shadow.Name = panel.Name .. "Shadow"
	shadow.BackgroundColor3 = color(UiTheme.Shadow.Color)
	shadow.BackgroundTransparency = UiTheme.Shadow.Transparency
	shadow.BorderSizePixel = 0
	shadow.AnchorPoint = panel.AnchorPoint
	shadow.Position = panel.Position
		+ UDim2.fromOffset(UiTheme.Shadow.Offset, UiTheme.Shadow.Offset)
	shadow.Rotation = panel.Rotation
	shadow.Size = panel.Size
	shadow.ZIndex = panel.ZIndex
	shadow.Parent = panel.Parent
	corner(shadow, UiTheme.Corner.Panel)

	panel:GetPropertyChangedSignal("Position"):Connect(function()
		shadow.Position = panel.Position
			+ UDim2.fromOffset(UiTheme.Shadow.Offset, UiTheme.Shadow.Offset)
	end)
	panel:GetPropertyChangedSignal("Size"):Connect(function()
		shadow.Size = panel.Size
	end)
	panel:GetPropertyChangedSignal("AnchorPoint"):Connect(function()
		shadow.AnchorPoint = panel.AnchorPoint
	end)
	panel:GetPropertyChangedSignal("Rotation"):Connect(function()
		shadow.Rotation = panel.Rotation
	end)
	panel:GetPropertyChangedSignal("Visible"):Connect(function()
		shadow.Visible = panel.Visible
	end)
	panel.AncestryChanged:Connect(function()
		if panel.Parent == nil then
			shadow:Destroy()
		else
			shadow.Parent = panel.Parent
		end
	end)
end

function UiKit.ScreenScale(screen: ScreenGui): UIScale
	local scale = Instance.new("UIScale")
	scale.Name = "ScreenScale"
	scale.Parent = screen

	local viewportConnection: RBXScriptConnection? = nil
	local function update()
		local camera = workspace.CurrentCamera
		local viewport = if camera then camera.ViewportSize else Vector2.new(1920, 1080)
		scale.Scale = UiTheme.scaleFor(viewport.X, viewport.Y)
	end
	local function watchCamera()
		if viewportConnection then
			viewportConnection:Disconnect()
		end
		local camera = workspace.CurrentCamera
		if camera then
			viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(update)
		end
		update()
	end
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)
	watchCamera()
	return scale
end

local function gradient(parent: Instance, definition: any)
	local item = Instance.new("UIGradient")
	item.Rotation = definition.Rotation
	item.Color = ColorSequence.new(color(definition.Colors[1]), color(definition.Colors[2]))
	item.Parent = parent
end

function UiKit.Label(
	parent: Instance,
	name: string,
	position: UDim2,
	size: UDim2,
	content: string,
	textSize: number
): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Position = position
	label.Size = size
	label.BackgroundTransparency = 1
	label.Font = UiKit.Fonts.Body
	label.TextColor3 = color(UiTheme.Colors.Text)
	label.TextStrokeColor3 = color(UiTheme.Stroke.Color)
	label.TextStrokeTransparency = UiTheme.Stroke.Transparency
	label.TextSize = textSize
	label.Text = content
	label.Parent = parent
	return label
end

function UiKit.Panel(parent: Instance, name: string): Frame
	local panel = Instance.new("Frame")
	panel.Name = name
	panel.BackgroundColor3 = color(UiTheme.Colors.Panel)
	panel.BackgroundTransparency = 0.08
	panel.BorderSizePixel = 0
	panel.Parent = parent
	shadowFor(panel)
	corner(panel, UiTheme.Corner.Panel)
	stroke(panel)
	gradient(panel, UiTheme.Gradients.Panel)
	return panel
end

local function tweenScale(scale: UIScale, target: number)
	TweenService:Create(
		scale,
		TweenInfo.new(UiTheme.Motion.Button.Seconds, Enum.EasingStyle.Quad),
		{ Scale = target }
	):Play()
end

function UiKit.Button(parent: Instance, content: string, size: UDim2): TextButton
	local button = Instance.new("TextButton")
	button.Size = size
	button.Text = content
	button.Font = UiKit.Fonts.Body
	button.TextSize = UiTheme.Sizes.Text.Body
	button.TextColor3 = color(UiTheme.Colors.Text)
	button.TextStrokeColor3 = color(UiTheme.Stroke.Color)
	button.TextStrokeTransparency = UiTheme.Stroke.Transparency
	button.BackgroundColor3 = color(UiTheme.Colors.Button)
	button.AutoButtonColor = false
	button.BorderSizePixel = 0
	button.Parent = parent
	corner(button, UiTheme.Corner.Small)
	stroke(button)
	gradient(button, UiTheme.Gradients.Button)
	local lip = Instance.new("Frame")
	lip.Name = "Lip"
	lip.AnchorPoint = Vector2.new(0, 1)
	lip.Position = UDim2.fromScale(0, 1)
	lip.Size = UDim2.new(1, 0, 0, 4)
	lip.BackgroundColor3 = color(UiTheme.Colors.ButtonLip)
	lip.BorderSizePixel = 0
	lip.Parent = button
	corner(lip, UiTheme.Corner.Small)

	local scale = Instance.new("UIScale")
	scale.Parent = button
	button.MouseEnter:Connect(function()
		tweenScale(scale, UiTheme.Motion.Button.HoverScale)
	end)
	button.MouseLeave:Connect(function()
		tweenScale(scale, 1)
	end)
	button.MouseButton1Down:Connect(function()
		tweenScale(scale, UiTheme.Motion.Button.PressScale)
	end)
	button.MouseButton1Up:Connect(function()
		tweenScale(
			scale,
			if button.GuiState == Enum.GuiState.Hover then UiTheme.Motion.Button.HoverScale else 1
		)
	end)
	return button
end

function UiKit.Badge(parent: Instance, name: string, glyph: string, diameter: number): Frame
	local badge = Instance.new("Frame")
	badge.Name = name
	badge.Size = UDim2.fromOffset(diameter, diameter)
	badge.BackgroundColor3 = color(UiTheme.Colors.Button)
	badge.BorderSizePixel = 0
	badge.Parent = parent
	corner(badge, UiTheme.Corner.Round)
	stroke(badge)
	local label =
		UiKit.Label(badge, "Glyph", UDim2.new(), UDim2.fromScale(1, 1), glyph, diameter * 0.5)
	label.Font = UiKit.Fonts.Title
	return badge
end

export type Bar = {
	Frame: Frame,
	Fill: Frame,
	Label: TextLabel,
}

function UiKit.Bar(parent: Instance, name: string, size: UDim2, fillColor: { number }?): Bar
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = size
	frame.BackgroundColor3 = color(UiTheme.Colors.BarTrack)
	frame.BorderSizePixel = 0
	frame.ClipsDescendants = true
	frame.Parent = parent
	corner(frame, UiTheme.Corner.Round)
	stroke(frame)
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = color(fillColor or UiTheme.Colors.Success)
	fill.BorderSizePixel = 0
	fill.Parent = frame
	corner(fill, UiTheme.Corner.Round)
	local label = UiKit.Label(frame, "Value", UDim2.new(), UDim2.fromScale(1, 1), "", 14)
	label.ZIndex = fill.ZIndex + 1
	return { Frame = frame, Fill = fill, Label = label }
end

export type Counter = {
	Label: TextLabel,
	Set: (self: Counter, value: number, duration: number?) -> (),
}

function UiKit.Counter(parent: Instance, name: string, initialValue: number): Counter
	local label = UiKit.Label(
		parent,
		name,
		UDim2.new(),
		UDim2.fromOffset(
			UiTheme.Sizes.TouchTargets.Counter.Width,
			UiTheme.Sizes.TouchTargets.Counter.Height
		),
		tostring(initialValue),
		UiTheme.Sizes.Text.Body
	)
	local shown = initialValue
	local token = 0
	local counter = {} :: any
	counter.Label = label
	function counter:Set(value: number, duration: number?)
		token += 1
		local ownToken = token
		local start = shown
		local seconds = duration or UiTheme.Motion.CounterSeconds
		if seconds <= 0 then
			shown = value
			label.Text = tostring(math.round(value))
			return
		end
		task.spawn(function()
			local startedAt = os.clock()
			while ownToken == token do
				local alpha = math.min((os.clock() - startedAt) / seconds, 1)
				shown = start + (value - start) * alpha
				label.Text = tostring(math.round(shown))
				if alpha >= 1 then
					break
				end
				task.wait()
			end
		end)
	end
	return counter :: Counter
end

function UiKit.Banner(parent: Instance, name: string, content: string): TextLabel
	local label = UiKit.Label(
		parent,
		name,
		UDim2.new(0.5, -300, 0.22, 0),
		UDim2.new(0, 600, 0, 80),
		content,
		UiTheme.Sizes.Text.Banner
	)
	label.Font = UiKit.Fonts.Banner
	gradient(label, UiTheme.Gradients.Banner)
	return label
end

function UiKit.Portrait(parent: Instance, name: string, image: string, caption: string): Frame
	local frame = UiKit.Panel(parent, name)
	frame.Size = UDim2.fromOffset(
		UiTheme.Sizes.TouchTargets.Portrait.Width,
		UiTheme.Sizes.TouchTargets.Portrait.Height
	)
	frame.ClipsDescendants = true

	local picture = Instance.new("ImageLabel")
	picture.Name = "Image"
	picture.Size = UDim2.fromScale(1, 1)
	picture.BackgroundTransparency = 1
	picture.Image = image
	picture.Parent = frame

	local label =
		UiKit.Label(frame, "Caption", UDim2.new(0, 2, 1, -20), UDim2.new(1, -4, 0, 18), caption, 14)
	label.ZIndex = picture.ZIndex + 1
	return frame
end

return UiKit
