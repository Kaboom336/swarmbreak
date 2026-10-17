local fs,rb=require('@lune/fs'),require('@lune/roblox')
local p=rb.deserializePlace(fs.readFile('prototype/cave-v2.pre-c8.rbxl'))
print('PRE-C8 MAP ATTRIBUTES',p.Workspace.CaveV2:GetAttributes(),'KIT FOLDER EXISTS',p.Workspace.CaveV2:FindFirstChild('CaveKitDressing')~=nil)
for _,n in p.Workspace:GetDescendants() do
 if n:IsA('BasePart') and (n.Name=='FloatingRock' or n.Name=='R3DistantIsland' or n.Name=='UndersideCrystalTip') then print(n:GetFullName(),n.CFrame.Position,n.Size,n.CanCollide,n.CanQuery,n:GetAttributes()) end
end
