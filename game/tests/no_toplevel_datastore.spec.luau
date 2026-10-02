--!strict
local fs = require("@lune/fs")

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

local function leadingTabs(line: string): number
	local tabs = line:match("^(\t*)") or ""
	return #tabs
end

test("DataStore acquisition is protected at module top level", function()
	for _, path in walk("src", {}) do
		local functionIndents: { number } = {}
		for line in fs.readFile(path):gmatch("[^\r\n]+") do
			local trimmed = line:match("^%s*(.-)%s*$") or ""
			local code = trimmed:gsub("%-%-.*$", "")
			local indent = leadingTabs(line)
			if
				#functionIndents > 0
				and indent == functionIndents[#functionIndents]
				and code:match("^end[%s%),]*$")
			then
				table.remove(functionIndents)
			end

			local getsStore = code:find(":GetDataStore%(") or code:find(":GetOrderedDataStore%(")
			local insideFunction = #functionIndents > 0 or code:match("%f[%a]function%f[%A]")
			if getsStore and not insideFunction then
				error(path .. " has unprotected top-level DataStore acquisition: " .. trimmed)
			end

			if code:match("%f[%a]function%f[%A]") and not code:match("%f[%a]end%f[%A]") then
				table.insert(functionIndents, indent)
			end
		end
	end
end)
