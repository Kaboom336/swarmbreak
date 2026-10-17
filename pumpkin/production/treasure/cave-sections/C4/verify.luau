local fs,rb,serde,luau=require('@lune/fs'),require('@lune/roblox'),require('@lune/serde'),require('@lune/luau')
local H='treasure/cave-sections/C4/'
local bytes=fs.readFile('prototype/cave-v2.rbxl');local original=fs.readFile('prototype/cave-v2.pre-c4.rbxl')
local p=rb.deserializePlace(bytes);local b=rb.deserializePlace(original)
assert(p.ServerScriptService.CaveBlastC4.Source==fs.readFile('prototype/cave-v2/BlastC4.server.luau'),'mounted source drift')
assert(p.ServerScriptService.CaveBlastC4.Presentation.Source==fs.readFile('treasure/cave-sections/C4/effects.luau'),'mounted effects drift')
local plan=serde.decode('json',p.ServerScriptService.CaveBlastC4.Plan.Value)
local function equal(a,b)
 if type(a)~=type(b)then return false end
 if type(a)=='number'then return math.abs(a-b)<1e-8 end
 if type(a)~='table'then return a==b end
 for k,v in a do if not equal(v,b[k])then return false end end
 for k in b do if a[k]==nil then return false end end
 return true
end
assert(equal(plan,require('./plan')('r4')),'mounted plan drift')
for _,g in plan do
 local q=assert(p.Workspace.CaveBlastC4:FindFirstChild(g.name))
 local cf=rb.CFrame.new(unpack(g.c))*rb.CFrame.Angles(0,math.rad(g.yaw or 0),0)
 assert((q.Size-rb.Vector3.new(unpack(g.s))).Magnitude<.0001,'native size drift')
 assert((q.CFrame.Position-cf.Position).Magnitude<.0001 and q.CFrame.LookVector:Dot(cf.LookVector)>.99999,'native transform drift')
 assert(q.Color==rb.Color3.fromRGB(unpack(g.color))and q.Material==rb.Enum.Material[g.material or'Slate'],'native appearance drift')
end
local sources,compiled=0,0
for _,n in p:GetDescendants()do if n:IsA('LuaSourceContainer')then for o=0,2 do luau.compile(n.Source,{optimizationLevel=o})end;compiled+=1 end end
p.Workspace.CaveBlastC4:Destroy();p.ServerScriptService.CaveBlastC4:Destroy()
local oldSign=b.Workspace.CaveV2.CartSign
local sign=p.Workspace.CaveV2.CartSign
assert((sign.Size-rb.Vector3.new(7,2.8,.6)).Magnitude<.0001,'serialized CART size')
local facing=sign.CFrame.LookVector:Dot((rb.Vector3.new(145,sign.CFrame.Y,-105)-sign.CFrame.Position).Unit)
assert(facing>.99,'CART face away from approach')
sign.CFrame=oldSign.CFrame;sign.Size=oldSign.Size
assert(rb.serializePlace(p)==rb.serializePlace(b),'complete unrelated state changed')
for _,n in b:GetDescendants()do if n:IsA('LuaSourceContainer')then sources+=1 end end
local m=serde.decode('json',fs.readFile(H..'MOUNT-r4.json'));assert(m.place_sha256==serde.hash('sha256',bytes),'round artifact mismatch')
fs.writeFile(H..'VERIFY.json',serde.encode('json',{state='PASS',place_sha256=serde.hash('sha256',bytes),backup_sha256=serde.hash('sha256',original),all_original_sources_exact=sources,compiled_O0_O1_O2=compiled,complete_unrelated_serialization_exact=true,mounted_plan_native_parity=#plan,cart_sign_exception='Size/CFrame only; original flags and children exact',cart_sign_face_approach_dot=facing,cart_physics_seats_rails_contract_blasts_lanes_colliders_suites_exact=true,live_suites='UNKNOWN; no Studio play'},true))
print('PASS complete unrelated serialization, original sources',sources,'compiled',compiled)


