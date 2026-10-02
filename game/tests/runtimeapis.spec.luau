local fs = require("@lune/fs")
local luau = require("@lune/luau")

local RuntimeApis = luau.load(fs.readFile("../tools/lint_runtime_apis_core.luau"), {
	debugName = "lint_runtime_apis_core.luau",
})()

local function walk(dir: string, out: { string }): { string }
	for _, entry in fs.readDir(dir) do
		local path = dir .. "/" .. entry
		if fs.isDir(path) then
			walk(path, out)
		elseif entry:match("%.luau$") then
			table.insert(out, path)
		end
	end
	return out
end

test("plugin-only runtime APIs are flagged", function()
	local samples = {
		"settings().Rendering.QualityLevel = 1",
		"Lighting.Technology = Enum.Technology.Future",
		'game:GetService("StudioService")',
		'game:GetService("PluginGuiService")',
		'game:GetService("ChangeHistoryService")',
		'game:GetService("Selection")',
		'plugin:CreateToolbar("Build")',
		"plugin.Name",
		"game:TakeScreenshot()",
		'game:GetService("CoreGui").RobloxGui.Enabled = false',
	}

	for _, sample in samples do
		assert(#RuntimeApis.matchLine(sample) > 0, "expected a hit for: " .. sample)
	end
end)

test("comment lines are ignored", function()
	eq(#RuntimeApis.matchLine("  -- Lighting.Technology = Enum.Technology.Future"), 0)
	eq(#RuntimeApis.matchLine("-- settings()"), 0)
end)

test("UserSettings is runtime-safe", function()
	eq(#RuntimeApis.matchLine('UserSettings():GetService("UserGameSettings")'), 0)
end)

test("game source contains no plugin-only APIs", function()
	local hits = {}
	for _, path in walk("src", {}) do
		for _, hit in RuntimeApis.scanSource(fs.readFile(path)) do
			table.insert(hits, string.format("%s:%d: %s", path, hit.line, hit.api))
		end
	end
	assert(#hits == 0, table.concat(hits, "\n"))
end)
