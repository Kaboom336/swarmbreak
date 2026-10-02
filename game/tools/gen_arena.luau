--!strict
-- Regenerates the checked-in edit-mode arena from the shared Wave 6 layout data.
local fs = require("@lune/fs")
local serde = require("@lune/serde")

local ArenaLayout = require("../src/ReplicatedStorage/Shared/ArenaLayout")
local ArenaModelGenerator = require("../src/ReplicatedStorage/Shared/ArenaModelGenerator")
local Theme = require("../src/ReplicatedStorage/Shared/Theme")

local OUTPUT_DIRECTORY = "src/Workspace/Arena"

for _, output in ArenaModelGenerator.build(ArenaLayout, Theme) do
	local json = serde.encode("json", output.Contents, true)
	fs.writeFile(OUTPUT_DIRECTORY .. "/" .. output.Name, json .. "\n")
end
