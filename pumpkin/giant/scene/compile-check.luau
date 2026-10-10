local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
-- Studio compiles with debugLevel 2, which keeps constant locals in registers; check every level.
for _, path in process.args do
	local src = fs.readFile(path)
	local bad = nil
	for _, o in { 0, 1, 2 } do
		local ok, err = pcall(luau.compile, src, { optimizationLevel = o, debugLevel = 2 })
		if not ok then
			bad = "O" .. o .. ": " .. tostring(err):match("^[^\n]*")
			break
		end
	end
	print(path, bad or "OK")
end
