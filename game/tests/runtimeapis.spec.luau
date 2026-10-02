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

test("StarterPlayerScripts requires script siblings with WaitForChild", function()
	local path = "game/src/StarterPlayer/StarterPlayerScripts/Client.client.luau"
	local samples = {
		"local Module = require(script.Parent.X)",
		'local Module = require(script.Parent["X"])',
	}

	for _, sample in samples do
		local hits = RuntimeApis.scanSource(sample, path)
		eq(#hits, 1)
		eq(hits[1].api, "require(script.Parent.X)")
		eq(hits[1].message, "require(script.Parent.X) must use WaitForChild")
	end
end)

test("StarterPlayerScripts WaitForChild requires are allowed", function()
	local path = "game/src/StarterPlayer/StarterPlayerScripts/Client.client.luau"
	local source = 'local Module = require(script.Parent:WaitForChild("X"))'
	eq(#RuntimeApis.scanSource(source, path), 0)
end)

test("script sibling requires outside StarterPlayerScripts are allowed", function()
	local path = "game/src/ServerScriptService/Server.server.luau"
	eq(#RuntimeApis.scanSource("local Module = require(script.Parent.X)", path), 0)
end)

test("game source contains no plugin-only APIs", function()
	local hits = {}
	for _, path in walk("src", {}) do
		for _, hit in RuntimeApis.scanSource(fs.readFile(path), path) do
			table.insert(hits, string.format("%s:%d: %s", path, hit.line, hit.api))
		end
	end
	assert(#hits == 0, table.concat(hits, "\n"))
end)
