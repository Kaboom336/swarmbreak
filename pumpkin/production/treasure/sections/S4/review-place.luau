-- Package the already-frozen R1 source so Claude can inspect both rounds in Studio.
local fs,rb,luau=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau')
local h='treasure/sections/S4/'
local baseline=rb.deserializePlace(fs.readFile('slice-v2/prototype/guardian-greybox.pre-s4.rbxl'))
local p=rb.deserializePlace(fs.readFile('slice-v2/prototype/guardian-greybox.pre-s4.rbxl'))
local source=fs.readFile(h..'r1-Section4.luau')
assert(not source:find('WarningBoard',1,true) and not source:find('RescueGlow',1,true),'R1 must precede dressing')
for opt=0,2 do luau.compile(source,{optimizationLevel=opt}) end
local module=rb.Instance.new('ModuleScript');module.Name='Section4';module.Source=source;module.Parent=p.ReplicatedStorage.MeadowV4
for _,old in baseline:GetDescendants() do if old:IsA('LuaSourceContainer') then
 local q=p;for _,n in string.split(old:GetFullName(),'.') do q=assert(q:FindFirstChild(n)) end;assert(q.Source==old.Source)
end end
assert(rb.serializeModel({baseline.Workspace})==rb.serializeModel({p.Workspace}))
fs.writeFile(h..'R1-review.rbxl',rb.serializePlace(p))
local out=rb.deserializePlace(fs.readFile(h..'R1-review.rbxl'));assert(out.ReplicatedStorage.MeadowV4.Section4.Source==source)
assert(rb.serializeModel({baseline.Workspace})==rb.serializeModel({out.Workspace}))
print('PASS R1 review place: frozen silhouette source; existing sources and Workspace exact; no dressing')
