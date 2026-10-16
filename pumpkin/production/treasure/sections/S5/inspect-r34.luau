local fs,rb,serde=require('@lune/fs'),require('@lune/roblox'),require('@lune/serde')
local p=rb.deserializePlace(fs.readFile('slice-v2/prototype/guardian-greybox.rbxl'))
fs.writeFile('treasure/sections/S5/mounted-KitSwap.luau',p.ServerScriptService.KitSwap.Source)
fs.writeFile('treasure/sections/S5/mounted-KitLibrary.luau',p.ServerScriptService.KitLibrary.Source)
local d=serde.decode('json',fs.readFile('treasure/sections/S5/r2.json'))
for _,q in d.parts do local v=q.position
 if v[1]>87 and v[1]<145 and v[3]>-8 and v[3]<45 and (q.name:find('Shelf') or (q.size[2]<.4 and v[2]>4)) then
 print(q.name,serde.encode('json',{v,q.size,q.collidable,q.lane})) end
end
