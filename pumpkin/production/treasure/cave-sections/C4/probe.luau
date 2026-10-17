local fs,rb,serde=require('@lune/fs'),require('@lune/roblox'),require('@lune/serde')
local target,backup='prototype/cave-v2.rbxl','prototype/cave-v2.pre-c4.rbxl'
local bytes=fs.readFile(target)
assert(not fs.isFile(backup),'backup already exists; inspect before reusing')
fs.writeFile(backup,bytes);assert(fs.readFile(backup)==bytes)
fs.writeFile('treasure/cave-sections/C4/BACKUP.json',serde.encode('json',{byte_verified=true,sha256=serde.hash('sha256',bytes)},true))
local p=rb.deserializePlace(bytes)
print(p.ReplicatedStorage.CaveRouteData.Source)
for _,n in p.Workspace.CaveV2:GetDescendants()do
 if n:IsA('BasePart')and(n.Name:lower():find('sign')or n.Name:lower():find('landing')or n.Name:lower():find('support')or n.Name:lower():find('blast'))then
  print(n:GetFullName(),n.CFrame.Position,n.Size,n.CanCollide,n.CanQuery)
  for _,g in n:GetDescendants()do if g:IsA('TextLabel')then print('TEXT',g.Text)end end
 end
end
