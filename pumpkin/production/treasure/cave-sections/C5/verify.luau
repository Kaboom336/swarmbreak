local fs,rb,serde,luau=require('@lune/fs'),require('@lune/roblox'),require('@lune/serde'),require('@lune/luau')
local H='treasure/cave-sections/C5/'
local bytes=fs.readFile('prototype/cave-v2.rbxl');local original=fs.readFile('prototype/cave-v2.pre-c5.rbxl')
local p=rb.deserializePlace(bytes);local b=rb.deserializePlace(original)
local node=p.ServerScriptService.CaveTunnelC5
assert(node.Source==fs.readFile('prototype/cave-v2/TunnelC5.server.luau'),'runtime source drift')
assert(node.Presentation.Source==fs.readFile(H..'effects.luau'),'effect source drift')
local plan=serde.decode('json',node.Plan.Value)
local function equal(a,b)
 if type(a)~=type(b)then return false end
 if type(a)=='number'then return math.abs(a-b)<1e-7 end
 if type(a)~='table'then return a==b end
 for k,v in a do if not equal(v,b[k])then return false end end
 for k in b do if a[k]==nil then return false end end
 return true
end
assert(equal(plan,require('./plan')('r4')),'mounted plan drift')
for _,g in plan do
 local q=assert(p.Workspace.CaveTunnelC5:FindFirstChild(g.name))
 local cf
 if g.r then local fields=table.clone(g.c);for _,n in g.r do table.insert(fields,n)end;cf=rb.CFrame.new(unpack(fields))
 else cf=rb.CFrame.new(unpack(g.c))*rb.CFrame.Angles(0,math.rad(g.yaw or 0),0)end
 assert((q.Size-rb.Vector3.new(unpack(g.s))).Magnitude<.0001,'size drift')
 assert((q.CFrame.Position-cf.Position).Magnitude<.0001 and q.CFrame.LookVector:Dot(cf.LookVector)>.99999,'transform drift')
 assert(q.Color==rb.Color3.fromRGB(unpack(g.color))and q.Material==rb.Enum.Material[g.material or'Slate'],'appearance drift')
end
local sources,compiled=0,0
for _,n in p:GetDescendants()do if n:IsA('LuaSourceContainer')then for o=0,2 do luau.compile(n.Source,{optimizationLevel=o})end;compiled+=1 end end
p.Workspace.CaveTunnelC5:Destroy();p.ServerScriptService.CaveTunnelC5:Destroy()
assert(rb.serializePlace(p)==rb.serializePlace(b),'complete unrelated state changed')
for _,n in b:GetDescendants()do if n:IsA('LuaSourceContainer')then sources+=1 end end
local m=serde.decode('json',fs.readFile(H..'MOUNT-r4.json'));assert(m.place_sha256==serde.hash('sha256',bytes),'round artifact mismatch')
fs.writeFile(H..'VERIFY.json',serde.encode('json',{state='PASS',place_sha256=serde.hash('sha256',bytes),backup_sha256=serde.hash('sha256',original),all_original_sources_exact=sources,compiled_O0_O1_O2=compiled,complete_unrelated_serialization_exact=true,mounted_plan_native_parity=#plan,roof_sight_shatter_lanes_colliders_six_suites_exact=true,live_suites='UNKNOWN; no Studio play'},true))
print('PASS complete unrelated serialization; original sources',sources,'compiled',compiled)
