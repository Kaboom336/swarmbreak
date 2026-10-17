local fs,rb,serde=require('@lune/fs'),require('@lune/roblox'),require('@lune/serde')
local path='prototype/cave-v2.pre-c5.rbxl'
assert(not fs.isFile(path),'backup exists; do not overwrite')
local bytes=fs.readFile('prototype/cave-v2.rbxl');fs.writeFile(path,bytes);assert(fs.readFile(path)==bytes)
fs.writeFile('treasure/cave-sections/C5/BACKUP.json',serde.encode('json',{byte_verified=true,sha256=serde.hash('sha256',bytes)},true))
local p=rb.deserializePlace(bytes)
print(p.ReplicatedStorage.CaveRouteData.Source)
for _,n in p.Workspace.CaveV2:GetDescendants()do
 if n:IsA('BasePart')and(n.Name:lower():find('shatter')or n.Name:lower():find('cave')or n.Name:lower():find('crystal'))then
  print(n.Name,n.CFrame.Position,n.Size,n.CanCollide,n.Material.Name)
 end
end
