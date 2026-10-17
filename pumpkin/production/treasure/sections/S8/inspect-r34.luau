local fs,rb=require('@lune/fs'),require('@lune/roblox')
local p=rb.deserializePlace(fs.readFile('slice-v2/prototype/guardian-greybox.pre-s8r3.rbxl'))
for _,n in p:GetDescendants() do
 if n:IsA('LuaSourceContainer') and (n.Source:find('LavaFall',1,true) or n.Name:find('Scene')) then print(n:GetFullName(),#n.Source) end
end
