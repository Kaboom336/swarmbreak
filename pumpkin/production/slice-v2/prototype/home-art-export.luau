-- Export actual Scene.home/pen Parts and fixed reference-camera transform.
local fs, luau, serde = require("@lune/fs"), require("@lune/luau"), require("@lune/serde")
local r = require("@lune/roblox")
local Scene = luau.load(fs.readFile("Scene.luau"), {
	environment = {
		game = {
			GetService = function()
				return {
					WaitForChild = function()
						return "Layout"
					end,
				}
			end,
		},
		require = function()
			return {}
		end,
		Instance = r.Instance,
		Vector3 = r.Vector3,
		Vector2 = r.Vector2,
		CFrame = r.CFrame,
		Color3 = r.Color3,
		Enum = r.Enum,
	},
})()
local home = r.Instance.new("Model")
local function make(parent, name, size, position, color)
	local p = r.Instance.new("Part")
	p.Name, p.Size, p.Position, p.Color, p.Parent = name, size, position, color, parent
	p.CFrame = r.CFrame.new(position) -- Lune does not synchronize Position into CFrame.
	p.Anchored = true
	return p
end
Scene.home(home, make, function() end)
for slot = 1, 8 do
	local x, z = require("./Placement").center(slot)
	local height = require("./Placement").height(slot)
	local function raised(parent, name, size, position, color)
		return make(parent, name, size, position + r.Vector3.new(0, height, 0), color)
	end
	raised(home, "Pen" .. slot, r.Vector3.new(64, 0.2, 48), r.Vector3.new(x, 0.1, z), r.Color3.fromRGB(100, 115, 100))
	Scene.pen(home, x, z, raised)
	for step = 1, math.ceil(height / 0.5) do
		local h = math.min(step * 0.5, height)
		make(
			home,
			"HomePlotStep",
			r.Vector3.new(0.9, h, 12),
			r.Vector3.new((x < 0 and -1 or 1) * (1.4 + step * 0.9), h / 2, z),
			r.Color3.fromRGB(180, 173, 157)
		)
	end
end
local parts = {}
for _, p in ipairs(home:GetDescendants()) do
	if p:IsA("BasePart") and p.Transparency < 1 and p.Name ~= "TreeTrunk" and not p.Name:find("BlockCanopy") then
		table.insert(parts, {
			name = p.Name,
			size = { p.Size.X, p.Size.Y, p.Size.Z },
			cf = { p.CFrame:GetComponents() },
			color = { p.Color.R, p.Color.G, p.Color.B },
			shape = p.Shape.Name,
			neon = p.Material == r.Enum.Material.Neon,
		})
	end
end
fs.writeFile("../home-art/native-home.json", serde.encode("json", parts))
print("EXPORTED actual HOME native parts", #parts)
