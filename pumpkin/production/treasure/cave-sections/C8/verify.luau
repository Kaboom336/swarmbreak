local fs,rb,serde,luau=require('@lune/fs'),require('@lune/roblox'),require('@lune/serde'),require('@lune/luau')
local H='treasure/cave-sections/C8/'
local original=fs.readFile('prototype/cave-v2.pre-c8.rbxl');local bytes=fs.readFile('prototype/cave-v2.rbxl')
local p,b=rb.deserializePlace(bytes),rb.deserializePlace(original)
local node=p.ServerScriptService.CaveEscapeC8
local retire=require('./retire')
assert(node.Source==fs.readFile('prototype/cave-v2/EscapeC8.server.luau'))
local tag=node.Round.Value;local compiled=0
for _,n in p:GetDescendants()do if n:IsA('LuaSourceContainer')then for o=0,2 do luau.compile(n.Source,{optimizationLevel=o})end;compiled+=1 end end
p.Workspace.CaveEscapeC8:Destroy();p.ServerScriptService.CaveEscapeC8:Destroy()
local old,new=b.Workspace.CaveV2:GetDescendants(),p.Workspace.CaveV2:GetDescendants();assert(#old==#new)
local hidden=0
for i,q in new do if retire(q,tag)then
 assert(not q.CanCollide and q.Transparency==1 and old[i].Name==q.Name);q.Transparency=old[i].Transparency;hidden+=1
end end
assert(hidden>=74,'retirement scope');assert(rb.serializePlace(p)==rb.serializePlace(b),'unrelated serialized state changed')
assert(fs.readFile('prototype/cave-v2.pre-c8.rbxl')==original)
local mount=serde.decode('json',fs.readFile(H..'MOUNT-'..tag..'.json'));assert(mount.place_sha256==serde.hash('sha256',bytes))
fs.writeFile(H..'VERIFY.json',serde.encode('json',{state='PASS',compiled_O0_O1_O2=compiled,retired_c8_noncollidable_parts=hidden,only_original_delta='retire.luau residual C8 cubes/distant Crystal detail Transparency',restored_complete_serialized_parity=true,all_original_sources_six_suites_colliders_lanes_carts_blasts_geode_exact=true,place_sha256=serde.hash('sha256',bytes),backup_sha256=serde.hash('sha256',original)},true))
print('PASS C8 preservation: complete restored state exact; Transparency-only cosmetics',hidden,'compiled',compiled)
