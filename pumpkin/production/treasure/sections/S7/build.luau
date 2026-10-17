-- Source-only Lune mount; immutable pre-S7 canonical is the comparison authority.
local fs,rb,luau=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau')
local base=fs.readFile('treasure/sections/S4/build.luau'):gsub('S4','S7'):gsub('Section4','Section7'):gsub('pre%-s4','pre-s7')
base=base:gsub(' and not oldWarning','')
base=base:gsub('kind=p.ClassName,position','kind=p.ClassName,shadows=p.Shadows,position')
base=base:gsub("table.insert%(physical,serde.encode%('json',q%)%)", "table.insert(physical,serde.encode('json',serde.decode('json',serde.encode('json',q))))")
base=base:gsub("if mode=='deliver' then","if mode=='r1' or mode=='r2' then")
local first=assert(base:find(' local rojo=',1,true));local last=assert(base:find(' fs.writeFile(main,bytes)',first,true));base=base:sub(1,first-1)..base:sub(last)
base=base:gsub('local bytes=rb.serializePlace%(place%)',[[
local neutral=rb.deserializePlace(rb.serializePlace(place))
local s=neutral.ReplicatedStorage.MeadowV4:FindFirstChild('Section7');if s then s:Destroy() end
assert(rb.serializePlace(neutral)==rb.serializePlace(old),'unrelated serialized place delta')
local bytes=rb.serializePlace(place)]])
base=base:gsub(' fs.writeFile%(main,bytes%)'," fs.writeFile(H..string.upper(mode)..'-review.rbxl',bytes);fs.writeFile(main,bytes)")
luau.load(base,{environment=getfenv(),injectGlobals=true})()
