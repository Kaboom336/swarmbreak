-- Test runner for Lune (no Roblox needed). Loads the pure Shared modules with a fake
-- `script`/`require` so `require(script.Parent.Config)` resolves to files.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")

local ROOT = "src/ReplicatedStorage/Shared/"
local cache = {}

local function loadModule(name: string)
	if cache[name] then
		return cache[name]
	end
	local path = ROOT .. name .. ".luau"
	local src = fs.readFile(path)
	local parent = setmetatable({}, {
		__index = function(_, key)
			return "MODULE:" .. key
		end,
	})
	local env = setmetatable({
		script = { Parent = parent, Name = name },
		require = function(target)
			if type(target) == "string" and target:sub(1, 7) == "MODULE:" then
				return loadModule(target:sub(8))
			end
			return require(target)
		end,
	}, { __index = _G })
	local fn = luau.load(src, { debugName = path, environment = env })
	local result = fn()
	cache[name] = result
	return result
end

-- 1. Syntax check every .luau file under src (compile only).
local function walk(dir: string, out: { string })
	for _, entry in fs.readDir(dir) do
		local p = dir .. "/" .. entry
		if fs.isDir(p) then
			walk(p, out)
		elseif entry:match("%.luau$") then
			table.insert(out, p)
		end
	end
	return out
end
local files = walk("src", {})
local syntaxErrors = 0
for _, f in files do
	local ok, err = pcall(luau.compile, fs.readFile(f))
	if not ok then
		syntaxErrors += 1
		print("SYNTAX ERROR", f, err)
	end
end
print(string.format("Syntax: %d files checked, %d errors", #files, syntaxErrors))

-- 2. Unit tests.
local passed, failed = 0, 0
local function test(name: string, fn: () -> ())
	local ok, err = pcall(fn)
	if ok then
		passed += 1
	else
		failed += 1
		print("FAIL", name, err)
	end
end
local function eq(a, b, msg)
	if a ~= b then
		error(string.format("%s: expected %s, got %s", msg or "", tostring(b), tostring(a)), 2)
	end
end

for _, spec in fs.readDir("tests") do
	if spec:match("%.spec%.luau$") then
		local fn = luau.load(fs.readFile("tests/" .. spec), {
			debugName = spec,
			environment = setmetatable(
				{ test = test, eq = eq, load = loadModule },
				{ __index = _G }
			),
		})
		fn()
	end
end
print(string.format("Tests: %d passed, %d failed", passed, failed))
if failed > 0 or syntaxErrors > 0 then
	process.exit(1)
end
