-- Reuse established exporter; source-only mount, never plain Rojo.
local fs,rb,luau,serde=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau'),require('@lune/serde')
local tag=assert(require('@lune/process').args[1]);assert(tag=='r3' or tag=='r4')
local H='treasure/sections/S8/'
local backup='slice-v2/prototype/guardian-greybox.pre-s8r3.rbxl'
local old=rb.deserializePlace(fs.readFile(backup))
local p=rb.deserializePlace(fs.readFile(backup))
local parent=p.ReplicatedStorage.MeadowV4
parent.Section8.Source=fs.readFile('prototype/meadow-v4/Section8.luau')
if tag=='r4' then p.StarterPlayer.StarterPlayerScripts.HomeArt.Source=fs.readFile('slice-v2/prototype/HomeArt.client.luau') end
local function scene(root)
 for _,n in root:GetDescendants() do if n:IsA('ModuleScript') and n.Name=='GreyboxScene' then return n end end
 error('Scene module missing')
end
scene(p).Source=fs.readFile('slice-v2/prototype/Scene.luau')
local restored=scene(p).Source:gsub('Vector3.new%(3, 24, 0.4%)','Vector3.new(8, 66, 3)'):gsub('Color3.fromRGB%(176, 112, 62%)','Color3.fromRGB(255, 110, 25)')
if tag=='r4' then assert(restored:gsub('%s+','')==scene(old).Source:gsub('%s+',''),'Scene delta exceeds lava cosmetic size/color') end
local neutral=rb.deserializePlace(rb.serializePlace(p))
neutral.ReplicatedStorage.MeadowV4.Section8.Source=old.ReplicatedStorage.MeadowV4.Section8.Source
neutral.StarterPlayer.StarterPlayerScripts.HomeArt.Source=old.StarterPlayer.StarterPlayerScripts.HomeArt.Source
scene(neutral).Source=scene(old).Source
assert(rb.serializePlace(neutral)==rb.serializePlace(old),'unrelated serialized place changed')
local count=0
for _,n in p:GetDescendants() do if n:IsA('LuaSourceContainer') then
 for level=0,2 do luau.compile(n.Source,{optimizationLevel=level}) end;count+=1
end end
local bytes=rb.serializePlace(p)
local source=fs.readFile('treasure/sections/S4/build.luau')
local start=assert(source:find('local signatures={}',1,true))
local stop=assert(source:find("export(old,'before')",start,true))
source=source:sub(start,stop-1)
source=source:gsub('Section4','Section8'):gsub('kind=p.ClassName,position','kind=p.ClassName,shadows=p.Shadows,position')
source=source:gsub(' and not oldWarning','')
source=source.."\nif not fs.isFile(H..'before-r34.json') then export(old,'before-r34') end;export(place,mode)\n"
local env=table.clone(getfenv());env.fs=fs;env.rb=rb;env.serde=serde;env.luau=luau;env.H=H;env.old=old;env.place=p;env.mode=tag
luau.load(source,{environment=env,injectGlobals=true})()
fs.writeFile(H..tag..'-Section8.luau',parent.Section8.Source)
fs.writeFile(H..tag..'-Scene.luau',scene(p).Source)
fs.writeFile(H..tag..'-HomeArt.luau',p.StarterPlayer.StarterPlayerScripts.HomeArt.Source)
fs.writeFile(H..string.upper(tag)..'-review.rbxl',bytes)
fs.writeFile('slice-v2/prototype/guardian-greybox.rbxl',bytes)
fs.writeFile(H..'MOUNT-'..tag..'.json',serde.encode('json',{compiled_O0_O1_O2=count,unrelated_sources_preserved=count-(tag=='r4' and 3 or 2),unrelated_serialized_place_exact=true,workspace_exact=true,changed_sources=tag=='r4' and {'Section8','GreyboxScene','HomeArt'} or {'Section8','GreyboxScene'},canonical_sha256=serde.hash('sha256',bytes),backup_sha256=serde.hash('sha256',fs.readFile(backup))},true))
print('PASS',tag,count,'compile O0/O1/O2; all unrelated place exact')
