-- Lune overlay of the current canonical place, never plain Rojo regeneration.
local fs, rb, luau, serde =
	require("@lune/fs"), require("@lune/roblox"), require("@lune/luau"), require("@lune/serde")
local path = "slice-v2/prototype/guardian-greybox.rbxl"
local backup = "slice-v2/prototype/guardian-greybox.pre-raid1.rbxl"
assert(fs.isFile(backup), "pre-raid backup required")
local before = fs.readFile(path)
local p = rb.deserializePlace(before)
local original = rb.deserializePlace(fs.readFile(backup))
local changes = {}
local mounts = {
	{ p.ReplicatedStorage.MeadowV4, "ModuleScript", "RaidSlice", "prototype/meadow-v4/RaidSlice.luau" },
	{ p.ReplicatedStorage.MeadowV4, "ModuleScript", "Builder", "prototype/meadow-v4/MeadowV4.luau" },
	{ p.ServerScriptService, "ModuleScript", "GreyboxArena", "slice-v2/prototype/Arena.luau" },
	{ p.ServerScriptService, "Script", "Greybox", "slice-v2/prototype/Greybox.server.luau" },
	{ p.ServerScriptService, "ModuleScript", "StudioPass", "slice-v2/prototype/StudioPass.luau" },
	{ p.ReplicatedStorage, "ModuleScript", "GreyboxTraps", "slice-v2/prototype/Traps.luau" },
	{ p.ServerScriptService, "ModuleScript", "RaidSliceTestRunner", "slice-v2/prototype/RaidSliceTest.luau" },
	{
		p.StarterPlayer.StarterPlayerScripts,
		"LocalScript",
		"RaidSliceClient",
		"prototype/meadow-v4/RaidSlice.client.luau",
	},
}
for _, m in mounts do
	local n = m[1]:FindFirstChild(m[3])
	local prior = n and n.Source
	if not n then
		n = rb.Instance.new(m[2])
		n.Name, n.Parent = m[3], m[1]
	end
	table.insert(changes, { node = n, prior = prior })
	n.Source = fs.readFile(m[4])
end
local compiled = 0
for _, n in p:GetDescendants() do
	if n:IsA("LuaSourceContainer") then
		for o = 0, 2 do
			luau.compile(n.Source, { optimizationLevel = o })
		end
		compiled += 1
	end
end
local bytes = rb.serializePlace(p)
for _, c in changes do
	if c.prior then
		c.node.Source = c.prior
	else
		c.node:Destroy()
	end
end
assert(
	rb.serializePlace(p) == rb.serializePlace(rb.deserializePlace(before)),
	"unrelated saved state changed"
)
local result = rb.deserializePlace(bytes)
assert(
	rb.serializeModel({ result.Workspace }) == rb.serializeModel({ original.Workspace }),
	"serialized Workspace changed"
)
-- Original nine suite bodies remain byte exact; coordinator is deliberately extended.
for _, name in
	{
		"DropSampleTestRunner",
		"GreyboxLoopTestRunner",
		"GreyboxTrapTestRunner",
		"CoreLoopTestRunner",
		"OutsmartTestRunner",
	}
do
	assert(
		result.ServerScriptService[name].Source == original.ServerScriptService[name].Source,
		"existing suite changed " .. name
	)
end
fs.writeFile(path, bytes)
fs.writeFile(
	"treasure/RAID-BUILD.json",
	serde.encode(
		"json",
		{
			status = "PASS",
			compiled_O0_O1_O2 = compiled,
			place = path,
			backup = backup,
			place_sha256 = serde.hash("sha256", bytes),
			backup_sha256 = serde.hash("sha256", fs.readFile(backup)),
			undo_exact = true,
			workspace_exact = true,
			existing_suite_bodies_exact = true,
			Studio = "NOT RUN",
		},
		true
	)
)
print(
	"PASS raid Lune overlay; " .. compiled .. " scripts O0/O1/O2; exact undo and existing suite preservation"
)
