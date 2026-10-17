local fs,rb,serde,luau=require('@lune/fs'),require('@lune/roblox'),require('@lune/serde'),require('@lune/luau')
local id=require('@lune/process').args[1];local H='treasure/cave-sections/'..id..'/'
local bytes=fs.readFile('prototype/cave-v2.rbxl');local original=fs.readFile('prototype/cave-v2.pre-'..id:lower()..'.rbxl')
local p=rb.deserializePlace(bytes);local b=rb.deserializePlace(original);local name='CaveEscape'..id
local node=p.ServerScriptService[name];assert(node.Source==fs.readFile('prototype/cave-v2/Escape'..id..'.server.luau'),'runtime source drift')
local tag=node.Round.Value;local plan=serde.decode('json',node.Plan.Value)
for _,g in plan do
 local q=assert(p.Workspace[name]:FindFirstChild(g.name))
 assert((q.Size-rb.Vector3.new(unpack(g.s))).Magnitude<.0001)
 assert((q.CFrame.Position-rb.Vector3.new(unpack(g.c))).Magnitude<.0001)
 assert(q.Color==rb.Color3.fromRGB(unpack(g.color))and q.Material==rb.Enum.Material[g.material or'Slate'])
end
local sources,compiled=0,0
for _,n in p:GetDescendants()do if n:IsA('LuaSourceContainer')then for o=0,2 do luau.compile(n.Source,{optimizationLevel=o})end;compiled+=1 end end
p.Workspace[name]:Destroy();p.ServerScriptService[name]:Destroy()
assert(rb.serializePlace(p)==rb.serializePlace(b),'complete unrelated state changed')
for _,n in b:GetDescendants()do if n:IsA('LuaSourceContainer')then sources+=1 end end
local m=serde.decode('json',fs.readFile(H..'MOUNT-'..tag..'.json'));assert(m.place_sha256==serde.hash('sha256',bytes))
assert(serde.hash('sha256',original)==serde.decode('json',fs.readFile(H..'BACKUP.json')).sha256)
if id=='C7'then
 local c6=serde.decode('json',fs.readFile('treasure/cave-sections/C6/VERIFY.json'))
 assert(serde.hash('sha256',original)==c6.place_sha256,'C7 did not start from delivered C6')
 local combined=rb.deserializePlace(bytes)
 for _,key in {'CaveEscapeC6','CaveEscapeC7'}do combined.Workspace[key]:Destroy();combined.ServerScriptService[key]:Destroy()end
 assert(rb.serializePlace(combined)==rb.serializePlace(rb.deserializePlace(fs.readFile('prototype/cave-v2.pre-c6.rbxl'))),'combined unrelated state changed')
 print('PASS C6 -> C7 backup hash chain and combined pre-C6 complete serialization')
end
fs.writeFile(H..'VERIFY.json',serde.encode('json',{state='PASS',place_sha256=serde.hash('sha256',bytes),backup_sha256=serde.hash('sha256',original),all_original_sources_exact=sources,compiled_O0_O1_O2=compiled,complete_unrelated_serialization_exact=true,mounted_native_parts=#plan,gameplay_and_six_suite_bodies_exact=true,live_suites='UNKNOWN; no Studio play'},true))
print('PASS complete unrelated serialization; original sources',sources,'compiled',compiled)
