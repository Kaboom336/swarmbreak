-- Canonical Lune source-only mount; full serialized equality outside Section5.Source.
local fs,rb,luau=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau')
local src=fs.readFile('treasure/sections/S4/build.luau'):gsub('S4','S5'):gsub('Section4','Section5'):gsub('pre%-s4','pre-s5r3')
src=src:gsub("local s=rb.Instance.new%('ModuleScript'%);s.Name='Section5';", "local s=place.ReplicatedStorage.MeadowV4.Section5;")
src=src:gsub(' and not oldWarning','')
src=src:gsub('kind=p.ClassName,position',"kind=p.ClassName,shadows=p.Shadows,position")
src=src:gsub("table.insert%(physical,serde.encode%('json',q%)%)", function() return [[
local copy=serde.decode('json',serde.encode('json',q))
local v=copy.position
if (copy.name=='SolidMountainStone' and v[1]>=80 and v[1]<=144 and v[3]>=-12 and v[3]<=64) or copy.name:match('^OptionalJumpLanding%d+$') then copy.color=nil;copy.material=nil end
table.insert(physical,serde.encode('json',copy))]] end)
src=src:gsub("export%(old,'before'%)", "export(old,'r3-start')")
src=src:gsub('signatures.before',"signatures['r3-start']")
src=src:gsub("local kits=serde.decode",[[
local section=load(root.ReplicatedStorage.MeadowV4.Section5);local s5kits={}
for i,g in section.kits or {} do table.insert(s5kits,{id=g.id,name=g.name,x=g.x,y=g.y,z=g.z,size={g.size.X,g.size.Y,g.size.Z},color=g.color}) end
fs.writeFile(H..tag..'-kits.json',serde.encode('json',s5kits))
local kits=serde.decode]])
src=src:gsub("if mode=='deliver' then", "if mode=='r3' or mode=='r4' then")
local first=assert(src:find(' local rojo=',1,true));local last=assert(src:find(' fs.writeFile(main,bytes)',first,true))
src=src:sub(1,first-1)..src:sub(last)
src=src:gsub('local bytes=rb.serializePlace%(place%)',[[
local neutral=rb.deserializePlace(rb.serializePlace(place))
neutral.ReplicatedStorage.MeadowV4.Section5.Source=old.ReplicatedStorage.MeadowV4.Section5.Source
assert(rb.serializePlace(neutral)==rb.serializePlace(old),'unrelated serialized state changed')
local bytes=rb.serializePlace(place)]])
src=src:gsub(' fs.writeFile%(main,bytes%)'," fs.writeFile(H..string.upper(mode)..'-review.rbxl',bytes);fs.writeFile(main,bytes)")
luau.load(src,{environment=getfenv(),injectGlobals=true})()
