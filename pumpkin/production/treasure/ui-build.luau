local fs, rb, luau, serde = require("@lune/fs"), require("@lune/roblox"), require("@lune/luau"), require("@lune/serde")
local main = "slice-v2/prototype/guardian-greybox.rbxl"
local backup = "slice-v2/prototype/guardian-greybox.pre-ui.rbxl"
if require("@lune/process").args[1] == "backup" then
	assert(fs.isFile("treasure/sections/S1/RESULT.md"), "section pilot must finish first")
	assert(not fs.isFile(backup), "preserve existing pre-ui backup")
	local bytes = fs.readFile(main)
	local place = rb.deserializePlace(bytes)
	assert(place.ReplicatedStorage.MeadowV4:FindFirstChild("Section1"), "S1 not mounted")
	fs.writeFile(backup, bytes)
	assert(fs.readFile(backup) == bytes)
	print("PASS byte-verified post-S1 pre-ui backup")
	return
end
assert(fs.isFile(backup), "backup required before Rojo")
local old = rb.deserializePlace(fs.readFile(backup))
local place = rb.deserializePlace(fs.readFile(backup))
local built = rb.deserializePlace(fs.readFile("treasure/ui-rojo.rbxl"))
local paths = {
	{"ReplicatedStorage", "UIStyle"},
	{"StarterPlayer", "StarterPlayerScripts", "TreasureUIWorld"},
	{"StarterPlayer", "StarterPlayerScripts", "TreasureCoreHud"},
	{"StarterPlayer", "StarterPlayerScripts", "HomeArt"},
	{"StarterPlayer", "StarterPlayerScripts", "Greybox"},
	{"ServerScriptService", "Greybox"},
}
local function at(root, path, count)
	for i = 1, count or #path do root = assert(root:FindFirstChild(path[i]), path[i]) end
	return root
end
local allowed = {}
for _, path in paths do
	local parent = at(place, path, #path - 1)
	local existing = parent:FindFirstChild(path[#path])
	if existing then existing:Destroy() end
	at(built, path):Clone().Parent = parent
	allowed[table.concat(path, ".")] = true
end
assert(rb.serializeModel({old.Workspace}) == rb.serializeModel({place.Workspace}), "world changed")
local compiled, preserved = 0, 0
for _, node in place:GetDescendants() do
	if node:IsA("LuaSourceContainer") then
		for level = 0, 2 do luau.compile(node.Source, {optimizationLevel = level}) end
		compiled += 1
		if not allowed[node:GetFullName()] then
			assert(at(old, string.split(node:GetFullName(), ".")).Source == node.Source, "unrelated source changed: " .. node:GetFullName())
			preserved += 1
		end
	end
end
-- UI constructor checks against real serialized Roblox instances (no engine rendering).
local env = {}
for _, name in {"Enum", "Instance", "Color3", "Vector2", "Vector3", "UDim", "UDim2", "ColorSequence"} do env[name] = rb[name] end
local style = luau.load(place.ReplicatedStorage.UIStyle.Source, {environment = env})()
local panel = rb.Instance.new("TextButton")
style.panel(panel, style.Colors.Gold, 26)
style.icon(panel, "coin")
assert(panel.Font == rb.Enum.Font.FredokaOne and panel.TypeBounds.MaxTextSize == 26)
assert(panel.LetterOutline.ApplyStrokeMode == rb.Enum.ApplyStrokeMode.Contextual)
assert(panel.PanelEdge.ApplyStrokeMode == rb.Enum.ApplyStrokeMode.Border)
assert(panel.PanelCorner and panel.PanelGradient and panel.PanelShadow and panel.StyleIcon)
local root = rb.Instance.new("Part")
local caption, billboard = style.billboard(root, "TestPet", rb.UDim2.new(6, 36, 2.8, 18), 90, false)
assert(caption.Parent == billboard and billboard.Size.X.Scale == 6 and billboard.MaxDistance == 90)
assert(not billboard.AlwaysOnTop and caption.TypeBounds.MinTextSize == 1)
style.sign(root, "CAMP")
assert(root.Material == rb.Enum.Material.Wood)
local surfaces = 0
for _, node in root:GetChildren() do if node:IsA("SurfaceGui") then surfaces += 1; assert(not node.AlwaysOnTop) end end
assert(surfaces == 2)
-- Execute the actual pet-caption function with a tiered pet; catches its former unparented-text return.
local source = place.StarterPlayer.StarterPlayerScripts.HomeArt.Source
local start = assert(source:find("local function petCaption", 1, true))
local finish = assert(source:find("local function destroy", start, true))
local config = luau.load(place.ReplicatedStorage.TreasureCore.Config.Source)()
local model = rb.Instance.new("Model")
root.Parent = model
root:SetAttribute("PetTier", 1); root:SetAttribute("PetName", "Pup"); root:SetAttribute("PetRate", 1)
local e = table.clone(env)
e.Style, e.CoreConfig = style, config
-- Model:GetBoundingBox is an engine method: supply measured fixture bounds, retain real GUI instances.
local modelProxy = {GetBoundingBox = function() return rb.CFrame.identity, rb.Vector3.new(4, 4, 4) end}
local proxyStyle = table.clone(style)
proxyStyle.billboard = function(...)
	local text, gui = style.billboard(...)
	return text, setmetatable({}, {__index = function(_, key) return gui[key] end, __newindex = function(_, key, value) gui[key] = key == "Parent" and model or value end})
end
e.Style = proxyStyle
luau.load(source:sub(start, finish - 1) .. "\nreturn petCaption", {environment = e})()(root, modelProxy, "Pup")
local petGui = assert(model:FindFirstChild("HomePetCaption"))
assert(petGui.Caption.Parent == petGui and petGui.Caption.Text:find("Common", 1, true))
assert(petGui.Caption.Text:find("#A5FF67", 1, true), "rarity mismatch")
local bytes = rb.serializePlace(place)
rb.deserializePlace(bytes)
fs.writeFile(main, bytes)
fs.writeFile("treasure/UI-CHECKS.json", serde.encode("json", {
	status = "PASS", compiled_O0_O1_O2 = compiled, unrelated_sources_preserved = preserved,
	workspace_byte_equal = true, post_S1_backup = backup, constructors_and_tiered_pet = "PASS",
	StudioPassAll = "UNKNOWN; rerun after UI", phone_touch_gamepad_rendering = "UNKNOWN; offline mockups only",
}, true))
print("PASS", compiled, "scripts O0/O1/O2;", preserved, "unrelated sources preserved; UI constructors, tiered pet, Workspace parity")
