local fs,rb,serde=require('@lune/fs'),require('@lune/roblox'),require('@lune/serde')
local H='treasure/cave-sections/C7/'
local path='prototype/cave-v2.pre-c7.rbxl'
assert(not fs.isFile(path),'backup exists; do not overwrite')
local bytes=fs.readFile('prototype/cave-v2.rbxl');fs.writeFile(path,bytes);assert(fs.readFile(path)==bytes)
fs.writeFile(H..'BACKUP.json',serde.encode('json',{byte_verified=true,sha256=serde.hash('sha256',bytes)},true))
local p=rb.deserializePlace(bytes)
fs.writeFile(H..'ROUTES.txt',p.ReplicatedStorage.CaveRouteData.Source)
print(p.ReplicatedStorage.CaveRouteData.Source)
