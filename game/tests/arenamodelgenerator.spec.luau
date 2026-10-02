local ArenaLayout = load("ArenaLayout")
local ArenaModelGenerator = load("ArenaModelGenerator")
local Theme = load("Theme")

local function assertSame(left, right, path)
	assert(type(left) == type(right), path .. " type differs")
	if type(left) ~= "table" then
		eq(left, right, path)
		return
	end
	for key, value in left do
		assert(right[key] ~= nil, path .. " missing " .. tostring(key))
		assertSame(value, right[key], path .. "." .. tostring(key))
	end
	for key in right do
		assert(left[key] ~= nil, path .. " gained " .. tostring(key))
	end
end

local function inspectCFrames(value, path, found)
	if type(value) ~= "table" then
		return
	end
	for key, child in value do
		local childPath = path .. "." .. tostring(key)
		if key == "CFrame" then
			found.count += 1
			assert(type(child) == "table", childPath .. " must be a table")
			assert(type(child.CFrame) == "table", childPath .. " must use the explicit form")
			eq(#child.CFrame.position, 3, childPath .. " position length")
			eq(#child.CFrame.orientation, 3, childPath .. " orientation row count")
			for row, values in child.CFrame.orientation do
				eq(#values, 3, childPath .. " orientation row " .. row)
			end
		else
			inspectCFrames(child, childPath, found)
		end
	end
end

test("arena model generation is deterministic", function()
	local first = ArenaModelGenerator.build(ArenaLayout, Theme)
	local second = ArenaModelGenerator.build(ArenaLayout, Theme)
	assertSame(first, second, "output")
end)

test("every generated part uses an explicit CFrame", function()
	local outputs = ArenaModelGenerator.build(ArenaLayout, Theme)
	local found = { count = 0 }
	inspectCFrames(outputs, "output", found)
	eq(found.count, 49, "generated CFrame count")
end)
