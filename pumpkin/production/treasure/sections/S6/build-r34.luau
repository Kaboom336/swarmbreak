-- Reuse the inspected source-only mount; Section6.Source is the sole place delta.
local fs,rb,luau=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau')
-- Reuse S4's export/compiler with an existing-module source replacement.
local base=fs.readFile('treasure/sections/S4/build.luau'):gsub('S4','S6'):gsub('Section4','Section6'):gsub('pre%-s4','pre-s6r3')
base=base:gsub("local s=rb.Instance.new%('ModuleScript'%);s.Name='Section6';",'local s=place.ReplicatedStorage.MeadowV4.Section6;')
base=base:gsub(' and not oldWarning','')
base=base:gsub('kind=p.ClassName,position','kind=p.ClassName,shadows=p.Shadows,position')
base=base:gsub("table.insert%(physical,serde.encode%('json',q%)%)",function() return [[
local copy=serde.decode('json',serde.encode('json',q));local v=copy.position
if copy.name=='SolidMountainStone' and v[1]>=-65 and v[1]<=125 and v[3]>=-158 and v[3]<=-35 and v[2]+copy.size[2]/2>=0 and v[2]+copy.size[2]/2<=54 and not(v[1]>=-32 and v[1]<=32 and v[3]>=-132 and v[3]<=-72) then copy.color=nil;copy.material=nil end
table.insert(physical,serde.encode('json',copy))]] end)
base=base:gsub("export%(old,'before'%)","export(old,'r3-start')"):gsub('signatures.before',"signatures['r3-start']")
base=base:gsub('local kits=serde.decode',[[
local section=load(root.ReplicatedStorage.MeadowV4.Section6);local s6kits={}
for _,g in section.kits or {} do table.insert(s6kits,{id=g.id,name=g.name,x=g.x,y=g.y,z=g.z,size={g.size.X,g.size.Y,g.size.Z},color=g.color}) end
fs.writeFile(H..tag..'-kits.json',serde.encode('json',s6kits))
local kits=serde.decode]])
base=base:gsub("if mode=='deliver' then","if mode=='r3' or mode=='r4' then")
local first=assert(base:find(' local rojo=',1,true));local last=assert(base:find(' fs.writeFile(main,bytes)',first,true));base=base:sub(1,first-1)..base:sub(last)
base=base:gsub('local bytes=rb.serializePlace%(place%)',[[
local neutral=rb.deserializePlace(rb.serializePlace(place))
neutral.ReplicatedStorage.MeadowV4.Section6.Source=old.ReplicatedStorage.MeadowV4.Section6.Source
assert(rb.serializePlace(neutral)==rb.serializePlace(old),'unrelated serialized state changed')
local bytes=rb.serializePlace(place)]])
base=base:gsub(' fs.writeFile%(main,bytes%)'," fs.writeFile(H..string.upper(mode)..'-review.rbxl',bytes);fs.writeFile(main,bytes)")
luau.load(base,{environment=getfenv(),injectGlobals=true})()
