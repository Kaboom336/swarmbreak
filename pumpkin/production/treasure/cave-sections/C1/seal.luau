local fs,rb,serde=require('@lune/fs'),require('@lune/roblox'),require('@lune/serde')
local H='treasure/cave-sections/C1/'
local bytes=fs.readFile('prototype/cave-v2.rbxl');local p=rb.deserializePlace(bytes)
local old=rb.deserializePlace(fs.readFile('prototype/cave-v2.pre-c1.rbxl'))
local sourceCount,solids,lights,newLights=0,0,0,0
for _,n in p:GetDescendants()do
 if n:IsA('LuaSourceContainer')then sourceCount+=1 end
 if n:IsA('BasePart')and n.CanCollide then solids+=1 end
 if n:IsA('Light')then lights+=1;if n:IsDescendantOf(p.Workspace.CaveArrivalC1)then newLights+=1;assert(n.Brightness<=1.5 and n.Range<=18 and not n.Shadows)end end
end
local neutral=rb.deserializePlace(bytes);neutral.Workspace.CaveArrivalC1:Destroy();neutral.ServerScriptService.CaveArrivalC1:Destroy()
assert(rb.serializePlace(neutral)==rb.serializePlace(old),'unrelated state drift')
for _,name in {'SelfTest','DropSampleTest','BoardingTest','LoopTest','CartRideTest','BlastPolicyTest'}do
 assert(p.ServerScriptService.CaveStudioPass.Source:find('function suites.'..name,1,true),'missing suite '..name)
end
local lo,hi={math.huge,math.huge,math.huge},{-math.huge,-math.huge,-math.huge}
for _,n in old.Workspace.CaveV2:GetDescendants()do if n:IsA('BasePart')then
 for _,x in {-1,1}do for _,y in {-1,1}do for _,z in {-1,1}do
  local q=n.CFrame:PointToWorldSpace(n.Size*rb.Vector3.new(x,y,z)/2)
  for i,v in {q.X,q.Y,q.Z}do lo[i]=math.min(lo[i],v);hi[i]=math.max(hi[i],v)end
 end end end
end end
fs.writeFile(H..'BOUNDS.json',serde.encode('json',{coordinates='Roblox X,Y,Z',native_map_min=lo,native_map_max=hi,C1_min={-192,-24,96},C1_max={-100,36,164},source='all transformed original native BasePart corners, not generated concept'},true))
local evidence={state='PASS offline conservation',place_sha256=serde.hash('sha256',bytes),backup_sha256=serde.hash('sha256',fs.readFile('prototype/cave-v2.pre-c1.rbxl')),compiled_sources=sourceCount,protected_solids=solids,lights=lights,new_lights=newLights,full_unrelated_serialization_exact=true,six_suite_bodies_exact=true,studio_play='NOT RUN',visual='REVISIT',independent_claude_review='PENDING',owner_acceptance='UNKNOWN',rounds=2}
-- Windows PowerShell redirects native stdout as UTF-16; verdict tokens are ASCII.
local denseLog=fs.readFile(H..'dense-drop-mounted.log'):gsub('%z','')
assert(denseLog:find('PASS scene preservation',1,true),'dense sweep incomplete')
local dense=serde.decode('json',fs.readFile(H..'DENSE-FINAL.json'))
assert(dense.samples==3024 and #dense.failures==0 and next(dense.reasons)==nil,'dense drop failures')
local r1=rb.deserializePlace(fs.readFile(H..'r1-review.rbxl'))
local r1Hash=serde.hash('sha256',fs.readFile(H..'r1-review.rbxl'))
r1.Workspace.CaveArrivalC1:Destroy();r1.ServerScriptService.CaveArrivalC1:Destroy()
assert(rb.serializePlace(r1)==rb.serializePlace(neutral),'tested R1 gameplay differs from final')
evidence.dense={state='PASS',samples=dense.samples,failures=0,N=dense.N,tested_artifact_sha256=r1Hash,final_gameplay_and_original_state_exact=true,native_ray='unchanged; no memo cache',log='dense-drop-mounted.log'}
local artifact=serde.decode('json',fs.readFile(H..'OFFLINE-INPUT-artifact-only.json'))
assert(artifact.place_sha256==evidence.place_sha256,'final artifact check input drift')
assert(fs.readFile(H..'artifact-only-final.log'):gsub('%z',''):find('PASS final mounted source parity',1,true),'final artifact check incomplete')
evidence.artifact_only=artifact
evidence.artifact_hashes={}
for _,name in {'before.json','r1.json','r2.json','r1-plan.json','r2-plan.json','CAMERAS.json','REFS.jpg','TARGET.png','SBS-R1.jpg','SBS-R2.jpg','SBS-R2-phone.jpg','r2-arrival.png','r2-outgoing.png','render.py','PROMPT.md','DENSE-FINAL.json','selene.log'}do
 evidence.artifact_hashes[name]=serde.hash('sha256',fs.readFile(H..name))
end
for _,name in {'AUDIT-r1','AUDIT-r2','CONTACT-r1','CONTACT-r2','RUNTIME'}do evidence[name]=serde.decode('json',fs.readFile(H..name..'.json'))end
assert(evidence['CONTACT-r1'].contact==0 and evidence['CONTACT-r2'].contact==0)
assert(#evidence['AUDIT-r1'].lane_errors==0 and #evidence['AUDIT-r2'].lane_errors==0)
assert(#evidence['AUDIT-r1'].support_errors==0 and #evidence['AUDIT-r2'].support_errors==0)
assert(evidence.RUNTIME.place_sha256==evidence.place_sha256)
fs.writeFile(H..'FINAL-EVIDENCE.json',serde.encode('json',evidence,true))
print('PASS final seal; all original serialized state and six suites exact; contact 0, C1 lights',newLights)
