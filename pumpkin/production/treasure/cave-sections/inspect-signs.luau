local fs,rb=require('@lune/fs'),require('@lune/roblox')
local p=rb.deserializePlace(fs.readFile('prototype/cave-v2.rbxl'))
for _,n in p.Workspace.CaveV2:GetDescendants()do
 if n:IsA('BasePart')and(n.Name:lower():find('sign')or n.Name:lower():find('board'))then
  print(n.Name,n.CFrame.Position,n.Size,n.CanCollide,n.CFrame.LookVector)
  for _,d in n:GetDescendants()do if d:IsA('TextLabel')then print('TEXT',d.Text,d.Parent.Face)end end
 end
end
