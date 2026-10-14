local fs, rb = require("@lune/fs"), require("@lune/roblox")
local path = "prototype/guardian-greybox.pre-core.rbxl"
assert(not fs.isFile(path), "Refusing to overwrite pre-core backup")
local bytes = fs.readFile("prototype/guardian-greybox.rbxl")
rb.deserializePlace(bytes)
fs.writeFile(path, bytes)
assert(fs.readFile(path) == bytes, "Backup differs")
print("PASS byte-identical pre-core backup")
