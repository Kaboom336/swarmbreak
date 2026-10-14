local fs, luau = require("@lune/fs"), require("@lune/luau")
local r = require("@lune/roblox")
local Placement = require("./Placement")
local old = r.deserializePlace(fs.readFile("guardian-greybox.pre-home-round3.rbxl"))
local new = r.deserializePlace(fs.readFile("guardian-greybox.rbxl"))
local function mount(path)
	local node = new
	for _, name in ipairs(path) do
		node = assert(node:FindFirstChild(name), name)
	end
	return node
end
for _, entry in ipairs({
	{ { "ReplicatedStorage", "GreyboxPlacement" }, "Placement.luau" },
	{ { "ReplicatedStorage", "GreyboxScene" }, "Scene.luau" },
	{ { "ServerScriptService", "Greybox" }, "Greybox.server.luau" },
	{ { "ServerScriptService", "GreyboxLoopTestRunner" }, "LoopTest.luau" },
	{ { "StarterPlayer", "StarterPlayerScripts", "Greybox" }, "Greybox.client.luau" },
}) do
	assert(mount(entry[1]).Source == fs.readFile(entry[2]), "round 3 source mount mismatch")
end
assert(new.Lighting.Technology == r.Enum.Technology.Future and new.Lighting.GlobalShadows, "Future/shadows missing")
assert(new.Lighting.ClockTime == 14 and new.Lighting.Brightness == 2.5, "warm HOME lighting missing")
local protected =
	{ "GreyboxArena", "GreyboxTrapTestRunner", "GreyboxConfig", "GreyboxLayout", "GreyboxLootRules", "GreyboxTraps" }
for _, name in ipairs(protected) do
	local a = old:FindFirstChild(name, true)
	local b = new:FindFirstChild(name, true)
	assert(a.Source == b.Source, "protected module changed " .. name)
end
local source = fs.readFile("Greybox.server.luau")
local first = assert(source:find("for i = 1, 8 do\n\tlocal x, z = Placement.center(i)", 1, true))
local last = assert(source:find("local function assemble()", first, true))
local world = r.Instance.new("Folder")
local pens = {}
local function part(parent, name, size, position, color)
	local p = r.Instance.new("Part")
	p.Name, p.Size, p.CFrame, p.Color, p.Parent = name, size, r.CFrame.new(position), color, parent
	return p
end
-- Lune has no Model:GetPivot/PivotTo. Mock only its documented translation.
local construction = source:sub(first, last - 1)
local pivot = "plot:PivotTo(plot:GetPivot() + Vector3.new(0, Placement.height(i), 0))"
local start = assert(construction:find(pivot, 1, true))
construction = construction:sub(1, start - 1)
	.. "translate(plot, Vector3.new(0, Placement.height(i), 0))"
	.. construction:sub(start + #pivot)
luau.load(construction, {
	environment = {
		Placement = Placement,
		Instance = r.Instance,
		Vector3 = r.Vector3,
		CFrame = r.CFrame,
		Color3 = r.Color3,
		world = world,
		pens = pens,
		part = part,
		label = function()
			return {}
		end,
		orange = r.Color3.new(1, 0.5, 0),
		Scene = { pen = function() end },
		translate = function(model, offset)
			for _, p in ipairs(model:GetDescendants()) do
				if p:IsA("BasePart") then
					p.CFrame += offset
				end
			end
		end,
	},
})()
for slot = 1, 8 do
	local x, z = Placement.center(slot)
	local y = Placement.height(slot)
	assert(y == ((slot - 1) % 4) * 3.5, "terrace spacing")
	assert(
		(pens[slot].base.CFrame.Position - r.Vector3.new(x, y + 0.1, z)).Magnitude < 0.00001,
		"whole plot floor transform"
	)
	assert((pens[slot].base.Size - r.Vector3.new(64, 0.2, 48)).Magnitude < 0.00001, "plot footprint changed")
	assert(math.abs(pens[slot].marker.CFrame.Position.Y - (y + 1.5)) < 0.00001, "marker did not move with plot")
	assert(math.abs(pens[slot].gate.Z - z) == 8, "return spawn intersects stairs")
end
local steps = 0
for _, p in ipairs(world:GetChildren()) do
	if p.Name == "HomePlotStep" then
		steps += 1
		assert(p.Size.Y <= 10.5 and p.Size.Z == 12 and p:GetAttribute("SurfaceRole") == "Floor", "stair contract")
	end
end
assert(steps == 84, "all terrace stairs missing")
print(
	"PASS server construction (Model pivot translation mocked): eight whole plot roots; heights 0/3.5/7/10.5; unchanged 64x48/XZ; raised markers; 84 collision steps; safe return spawn"
)
print("PASS source mount parity, protected gameplay identity, binary Future/warm sun/shadows")
