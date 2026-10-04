--!strict
local fs = require("@lune/fs")

local function read(path: string): string
	return fs.readFile(path)
end

test("server only accepts the equipped Reaper loadout (K1 review)", function()
	local source = read("src/ServerScriptService/Combat.server.luau")
	assert(source:find("table.find(loadout.Abilities, abilityId)", 1, true), "loadout gate missing")
end)

test("attack clicks over GUI pass through (K1 review)", function()
	local source = read("src/StarterPlayer/StarterPlayerScripts/ScytheCombat.client.luau")
	assert(source:find("GetGuiObjectsAtPosition", 1, true), "GUI check missing")
	assert(source:find("ContextActionResult.Pass", 1, true), "GUI clicks must pass")
end)

test("ClientFX is the only FieldOfView writer (K1 review)", function()
	local writers = 0
	for _, path in
		{
			"src/StarterPlayer/StarterPlayerScripts/Camera.client.luau",
			"src/StarterPlayer/StarterPlayerScripts/ClientFX.luau",
			"src/StarterPlayer/StarterPlayerScripts/ScytheCombat.client.luau",
			"src/StarterPlayer/StarterPlayerScripts/WeaponFeel.client.luau",
			"src/StarterPlayer/StarterPlayerScripts/BossIntro.client.luau",
		}
	do
		local source = read(path)
		local _, n = source:gsub("FieldOfView%s*=", "")
		writers += n
		if n > 0 then
			assert(path:find("ClientFX", 1, true), path .. " writes FieldOfView")
		end
	end
	assert(writers == 1, "expected one FieldOfView writer, got " .. writers)
end)

test("ability pose ends on animation time (K1 review)", function()
	local source = read("src/StarterPlayer/StarterPlayerScripts/WeaponFeel.client.luau")
	assert(
		source:find("abilityAnimTime >= abilityDuration", 1, true),
		"ability must end on animation time"
	)
end)
