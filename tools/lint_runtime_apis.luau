--!strict
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")

local sourceRoot: string
local corePath: string
local allowlistPath: string
if fs.isDir("game/src") then
	sourceRoot = "game/src"
	corePath = "tools/lint_runtime_apis_core.luau"
	allowlistPath = "tools/runtime_api_allow.txt"
elseif fs.isDir("src") then
	sourceRoot = "src"
	corePath = "../tools/lint_runtime_apis_core.luau"
	allowlistPath = "../tools/runtime_api_allow.txt"
else
	error("run from the repository root or game directory")
end

local RuntimeApis = luau.load(fs.readFile(corePath), {
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

local allowlist = {}
for line in (fs.readFile(allowlistPath) .. "\n"):gmatch("(.-)\n") do
	line = line:gsub("\r$", "")
	if line:match("%S") and not line:match("^%s*#") then
		local path, lineNumber, reason = line:match("^([^:]+):(%d+)%s+(.+)$")
		if not path or not lineNumber or not reason or not reason:match("%S") then
			error("invalid runtime API allowlist entry: " .. line)
		end
		allowlist[path .. ":" .. lineNumber] = true
	end
end

local failures = 0
local files = walk(sourceRoot, {})
table.sort(files)
for _, path in files do
	local displayPath = if sourceRoot == "src" then "game/" .. path else path
	for _, hit in RuntimeApis.scanSource(fs.readFile(path), displayPath) do
		local location = displayPath .. ":" .. hit.line
		if not allowlist[location] then
			failures += 1
			if hit.message then
				print(string.format("%s: %s", location, hit.message))
			else
				print(string.format("%s: %s is plugin-only", location, hit.api))
			end
		end
	end
end

if failures > 0 then
	process.exit(1)
end
