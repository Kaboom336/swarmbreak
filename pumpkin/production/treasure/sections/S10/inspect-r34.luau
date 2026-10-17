local fs,rb,serde=require('@lune/fs'),require('@lune/roblox'),require('@lune/serde')
local path='slice-v2/prototype/guardian-greybox.rbxl'
local bytes=fs.readFile(path)
local backup='slice-v2/prototype/guardian-greybox.pre-s10r3.rbxl'
if not fs.isFile(backup)then fs.writeFile(backup,bytes)end
assert(fs.readFile(backup)==bytes,'backup does not match initial canonical')
local p=rb.deserializePlace(bytes)
for _,node in {p.ReplicatedStorage.MeadowV4.Builder,p.ReplicatedStorage.MeadowV4.Section9,p.ServerScriptService.Greybox,p.ReplicatedStorage.HomeArtGeometry}do
 fs.writeFile('treasure/sections/S10/inspect-'..node.Name..'.txt',node.Source)
end
fs.writeFile('treasure/sections/S10/BACKUP-R34.json',serde.encode('json',{path=backup,sha256=serde.hash('sha256',bytes),byte_exact=true},true))
print('backup verified',serde.hash('sha256',bytes))
