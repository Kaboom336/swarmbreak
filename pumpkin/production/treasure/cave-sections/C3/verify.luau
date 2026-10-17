local fs,rb,serde,luau=require('@lune/fs'),require('@lune/roblox'),require('@lune/serde'),require('@lune/luau')
local H='treasure/cave-sections/C3/'
local bytes=fs.readFile('prototype/cave-v2.rbxl');local original=fs.readFile('prototype/cave-v2.pre-c3.rbxl')
local p=rb.deserializePlace(bytes);local b=rb.deserializePlace(original)
assert(p.ServerScriptService.CaveDockC3.Source==fs.readFile('prototype/cave-v2/DockC3.server.luau'),'mounted source drift')
local sources,compiled=0,0
for _,n in p:GetDescendants()do if n:IsA('LuaSourceContainer')then for o=0,2 do luau.compile(n.Source,{optimizationLevel=o})end;compiled+=1 end end
p.Workspace.CaveDockC3:Destroy();p.ServerScriptService.CaveDockC3:Destroy()
assert(rb.serializePlace(p)==rb.serializePlace(b),'complete unrelated state changed')
for _,n in b:GetDescendants()do if n:IsA('LuaSourceContainer')then sources+=1 end end
local m=serde.decode('json',fs.readFile(H..'MOUNT-r4.json'));assert(m.place_sha256==serde.hash('sha256',bytes),'round artifact mismatch')
fs.writeFile(H..'VERIFY.json',serde.encode('json',{state='PASS',place_sha256=serde.hash('sha256',bytes),backup_sha256=serde.hash('sha256',original),all_original_sources_exact=sources,compiled_O0_O1_O2=compiled,complete_unrelated_serialization_exact=true,cart_physics_seats_rails_contract_blasts_lanes_colliders_suites_exact=true,live_suites='UNKNOWN; no Studio play'},true))
print('PASS complete unrelated serialization, original sources',sources,'compiled',compiled)
