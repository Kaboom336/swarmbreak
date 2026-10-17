local fs,rb,luau,serde=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau'),require('@lune/serde')
local p=rb.deserializePlace(fs.readFile('prototype/cave-v2.rbxl'))
print('ROUTES',p.ReplicatedStorage.CaveRouteData.Source)
for _,n in p.Workspace:GetChildren()do print('ROOT',n.Name,n.ClassName)end
for _,n in p.Workspace.CaveV2:GetChildren()do
 if n:IsA('BasePart')and (n.Name=='SafetyApron'or n.Name=='PortalSpawn'or n.Name:lower():find('portal')or n.Name:lower():find('sign'))then print(n.Name,n.CFrame.Position,n.Size,n.CanCollide,n.CanQuery)end
end
print('SOURCES')
for _,n in p:GetDescendants()do if n:IsA('LuaSourceContainer')then print(n:GetFullName())end end
