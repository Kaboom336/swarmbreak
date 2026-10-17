-- Shared presentation only: no currency, ownership, input or persistence rules.
local Style = {}
Style.Font = Enum.Font.FredokaOne
Style.BodyFont = Enum.Font.BuilderSansBold
Style.Colors = {

	Ink = Color3.fromRGB(31, 27, 47),
	Panel = Color3.fromRGB(49, 60, 84),
	Gold = Color3.fromRGB(255, 207, 65),
	Cyan = Color3.fromRGB(63, 215, 235),
	Danger = Color3.fromRGB(255, 87, 93),
	Cream = Color3.fromRGB(255, 245, 218),
}
local function child(parent, class, name)
	local old = parent:FindFirstChild(name)
	if old then
		old:Destroy()
	end
	local node = Instance.new(class)
	node.Name, node.Parent = name, parent
	return node
end
function Style.rarity(rarity)
	return Color3.fromRGB(table.unpack(rarity.color)) -- Single source: Core.Config.
end
function Style.lettering(t, maximum, minimum)
	t.Font, t.TextColor3 = Style.Font, Style.Colors.Cream
	t.TextScaled, t.TextWrapped, t.BorderSizePixel = true, true, 0
	t.TextStrokeTransparency = 1
	local stroke = child(t, "UIStroke", "LetterOutline")
	stroke.ApplyStrokeMode, stroke.Color, stroke.Thickness = Enum.ApplyStrokeMode.Contextual, Style.Colors.Ink, 2
	local limit = child(t, "UITextSizeConstraint", "TypeBounds")
	limit.MinTextSize, limit.MaxTextSize = minimum or 12, maximum or 26
	return t
end
function Style.panel(t, accent, maximum)
	Style.lettering(t, maximum)
	t.BackgroundColor3, t.BackgroundTransparency = accent or Style.Colors.Panel, 0
	local corner = child(t, "UICorner", "PanelCorner")
	corner.CornerRadius = UDim.new(0, 14)
	local edge = child(t, "UIStroke", "PanelEdge")
	edge.ApplyStrokeMode, edge.Color, edge.Thickness = Enum.ApplyStrokeMode.Border, Style.Colors.Ink, 3
	local shadow = child(t, "UIStroke", "PanelShadow")
	shadow.ApplyStrokeMode, shadow.Color, shadow.Thickness, shadow.Transparency =
		Enum.ApplyStrokeMode.Border, Color3.new(), 6, 0.65
	local gradient = child(t, "UIGradient", "PanelGradient")
	gradient.Rotation = 90
	gradient.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(185, 196, 215))
	local padding = child(t, "UIPadding", "PanelPadding")
	padding.PaddingLeft, padding.PaddingRight = UDim.new(0, 12), UDim.new(0, 12)
	padding.PaddingTop, padding.PaddingBottom = UDim.new(0, 5), UDim.new(0, 5)
	return t
end
-- Code-native icons; no external image uploads, IDs, fonts or licences needed.
function Style.icon(parent, kind, color)
	local icon = child(parent, "Frame", "StyleIcon")
	icon.Size, icon.Position, icon.AnchorPoint = UDim2.fromOffset(24, 24), UDim2.new(0, 8, 0.5, 0), Vector2.new(0, 0.5)
	icon.BackgroundColor3, icon.BorderSizePixel = color or Style.Colors.Gold, 0
	local c = Instance.new("UICorner")
	c.CornerRadius, c.Parent = UDim.new(kind == "coin" and 1 or 0, kind == "coin" and 0 or 4), icon
	icon.Rotation = kind == "gem" and 45 or 0
	local mark = Instance.new("TextLabel")
	mark.Size, mark.BackgroundTransparency, mark.Text =
		UDim2.fromScale(1, 1), 1, kind == "coin" and "$" or kind == "route" and ">" or "!"
	mark.Font, mark.TextScaled, mark.TextColor3, mark.Parent = Style.Font, true, Style.Colors.Ink, icon
	local padding = parent:FindFirstChild("PanelPadding")
	if padding then
		padding.PaddingLeft = UDim.new(0, 44)
	end
	return icon
end
function Style.gear(parent)
	local gear = child(parent, "Frame", "GearIcon")
	gear.Size, gear.Position, gear.AnchorPoint =
		UDim2.fromOffset(24, 24), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5)
	gear.BackgroundTransparency = 1
	for i = 0, 7 do
		local tooth = Instance.new("Frame")
		local a = i * math.pi / 4
		tooth.Size, tooth.AnchorPoint = UDim2.fromOffset(7, 8), Vector2.new(0.5, 0.5)
		tooth.Position, tooth.Rotation =
			UDim2.fromScale(0.5 + math.cos(a) * 0.36, 0.5 + math.sin(a) * 0.36), i * 45 + 90
		tooth.BackgroundColor3, tooth.BorderSizePixel, tooth.Parent = Style.Colors.Cream, 0, gear
	end
	for i, size in { 18, 7 } do
		local disc = Instance.new("Frame")
		disc.Size, disc.Position, disc.AnchorPoint =
			UDim2.fromOffset(size, size), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5)
		disc.BackgroundColor3, disc.BorderSizePixel, disc.Parent =
			i == 1 and Style.Colors.Cream or Style.Colors.Ink, 0, gear
		local corner = Instance.new("UICorner")
		corner.CornerRadius, corner.Parent = UDim.new(1, 0), disc
	end
	return gear
end
function Style.billboard(root, name, size, distance, onTop)
	local gui = Instance.new("BillboardGui")
	gui.Name, gui.Adornee, gui.Size = name, root, size
	gui.MaxDistance, gui.AlwaysOnTop, gui.LightInfluence = distance, onTop == true, 0
	gui.StudsOffsetWorldSpace = Vector3.new(0, root.Size.Y / 2 + 2, 0)
	gui.Parent = root
	local text = Instance.new("TextLabel")
	text.Name, text.Size, text.BackgroundTransparency = "Caption", UDim2.fromScale(1, 1), 1
	Style.lettering(text, 36, 1) -- World labels must be free to shrink with distance.
	text.Parent = gui
	return text, gui
end
function Style.sign(board, caption)
	board.Material, board.Color = Enum.Material.Wood, Color3.fromRGB(133, 82, 43)
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local gui = Instance.new("SurfaceGui")
		gui.Name, gui.Face, gui.SizingMode, gui.PixelsPerStud =
			"RouteLettering", face, Enum.SurfaceGuiSizingMode.PixelsPerStud, 48
		gui.LightInfluence, gui.AlwaysOnTop, gui.MaxDistance, gui.Parent = 0, false, 120, board
		local text = Instance.new("TextLabel")
		text.Size, text.BackgroundTransparency, text.Text = UDim2.fromScale(1, 1), 1, ">  " .. caption
		Style.lettering(text, 64, 1)
		text.Parent = gui
	end
end
return Style
