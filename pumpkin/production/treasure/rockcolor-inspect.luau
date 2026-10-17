local fs,rb=require('@lune/fs'),require('@lune/roblox')
local p=rb.deserializePlace(fs.readFile('slice-v2/prototype/guardian-greybox.rbxl'))
fs.writeDir('treasure/rockcolor')
for _,name in {'Builder','Section6'} do fs.writeFile('treasure/rockcolor/mounted-'..name..'.luau',p.ReplicatedStorage.MeadowV4[name].Source) end
fs.writeFile('treasure/rockcolor/mounted-KitLibrary.luau',p.ServerScriptService.KitLibrary.Source)
for _,n in p.ServerScriptService.KitLibrary:GetChildren() do print(n.Name,n.ClassName,#n:GetDescendants()) end
