-- Source-only Lune mount and the established home/native-client export.
local fs,rb,luau,serde=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau'),require('@lune/serde')
local tag=require('@lune/process').args[1]or'before'
local H='treasure/sections/S10/'
local baseline=fs.readFile('slice-v2/prototype/guardian-greybox.pre-s10.rbxl')
local p=rb.deserializePlace(baseline)
if tag~='before'then
 p.ReplicatedStorage.MeadowV4.Section9.Source=fs.readFile('prototype/meadow-v4/Section9.luau')
 local s=rb.Instance.new('ModuleScript');s.Name='Section10';s.Source=fs.readFile('prototype/meadow-v4/Section10.luau');s.Parent=p.ReplicatedStorage.MeadowV4
 fs.writeFile(H..tag..'-Section10.luau',s.Source)
end
local count=0
for _,s in p:GetDescendants()do if s:IsA('LuaSourceContainer')then for opt=0,2 do luau.compile(s.Source,{optimizationLevel=opt})end;count+=1 end end
local bytes=rb.serializePlace(p);local neutral=rb.deserializePlace(bytes)
if tag~='before'then neutral.ReplicatedStorage.MeadowV4.Section10:Destroy();neutral.ReplicatedStorage.MeadowV4.Section9.Source=rb.deserializePlace(baseline).ReplicatedStorage.MeadowV4.Section9.Source end
assert(rb.serializePlace(neutral)==rb.serializePlace(rb.deserializePlace(baseline)),'unrelated serialized change')
-- Reuse the inspected home builder, without its historical source-mount step.
local source=fs.readFile('treasure/sections/S9/build.luau')
local start=assert(source:find('local warnings,cache=',1,true))
source=source:sub(start)
source=source:gsub("if tag~='before' then",'if true then')
source=source:gsub("if tag=='r2'then",'if true then')
source=source:gsub("q:GetAttribute%('RouteLabel'%)", "(q:GetAttribute('S10Caption')or q:GetAttribute('S9Caption')or q:GetAttribute('RouteLabel'))")
source=source:sub(1,assert(source:find("fs.writeFile(H..'BOUNDS.json'",1,true))-1)
local env=table.clone(getfenv());env.p=p;env.H=H;env.tag=tag;env.fs=fs;env.rb=rb;env.luau=luau;env.serde=serde
luau.load(source,{environment=env,injectGlobals=true})()
fs.writeFile(H..'MOUNT-'..tag..'.json',serde.encode('json',{compiled_O0_O1_O2=count,unrelated_serialized_state_exact=true,canonical_sha256=serde.hash('sha256',bytes),backup_sha256=serde.hash('sha256',baseline)},true))
if tag~='before'then fs.writeFile(H..string.upper(tag)..'-review.rbxl',bytes);fs.writeFile('slice-v2/prototype/guardian-greybox.rbxl',bytes)end
print('PASS',tag,'compile',count,'source-only mount; unrelated state exact')
