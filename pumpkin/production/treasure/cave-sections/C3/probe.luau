local fs,rb,serde=require('@lune/fs'),require('@lune/roblox'),require('@lune/serde')
local bytes=fs.readFile('prototype/cave-v2.rbxl')
local backup='prototype/cave-v2.pre-c3.rbxl'
if not fs.isFile(backup)then fs.writeFile(backup,bytes);assert(fs.readFile(backup)==bytes)end
local p=rb.deserializePlace(fs.readFile(backup))
print(p.ReplicatedStorage.CaveRouteData.Source)
for _,n in p.Workspace:GetDescendants()do
 if n:IsA('BasePart')and(n:IsA('Seat')or n.Name:find('Dock')or n.Name:find('Cart'))then print(n:GetFullName(),n.CFrame.Position,n.Size)end
end
fs.writeFile('treasure/cave-sections/C3/BACKUP.json',serde.encode('json',{sha256=serde.hash('sha256',fs.readFile(backup)),byte_verified=true},true))
