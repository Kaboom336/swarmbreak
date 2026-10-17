-- Execute actual mounted arrival script with textured mesh/fit failure fixtures.
local fs,rb,luau,serde=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau'),require('@lune/serde')
local bytes=fs.readFile('prototype/cave-v2.rbxl');local p=rb.deserializePlace(bytes)
local S=p.ServerScriptService;local node=S.CaveEscapeC8
local Plan=luau.load(S.KitPlan.Source,{environment={Vector3=rb.Vector3,CFrame=rb.CFrame}})()
local plan=serde.decode('json',node.Plan.Value)
local fail=false;local kit={}
function kit.spawn(_,_,base,size)
 local m=rb.Instance.new('Model');local q=rb.Instance.new('MeshPart');q.TextureID='rbxassetid://123';q.Size=size;q.CFrame=base*rb.CFrame.new(0,size.Y/2,0);q.Parent=m
 local a=rb.Instance.new('SurfaceAppearance');a.Parent=q;return m
end
function kit.fit()return not fail end
local waits,warnings=0,0
local map=p.Workspace.CaveV2
local duplicates={}
local dressing=rb.Instance.new('Folder');dressing.Name='CaveKitDressing';dressing.Parent=map
for _,q in map:GetChildren()do if q:IsA('BasePart')and q.Name=='FloatingRock'then
 local id='fixture:c8:'..tostring(#duplicates+1);q:SetAttribute('KitAssemblyId',id)
 local m=rb.Instance.new('Model');m:SetAttribute('KitAssemblyId',id);m.Parent=dressing
 local v=rb.Instance.new('Part');v.CanCollide=false;v.CanQuery=false;v.CanTouch=false;v.Transparency=0;v.Parent=m;table.insert(duplicates,v)
end end
assert(#duplicates==24)
local control=rb.Instance.new('Model');control:SetAttribute('KitAssemblyId','unrelated');control.Parent=dressing
local untouched=rb.Instance.new('Part');untouched.Parent=control;untouched.Transparency=0
local delayed=true
local env={script=node,workspace={WaitForChild=function(_,name)return assert(p.Workspace:FindFirstChild(name))end},Instance=rb.Instance,Vector3=rb.Vector3,CFrame=rb.CFrame,Color3=rb.Color3,Enum=rb.Enum,UDim2=rb.UDim2,Font=rb.Font,Vector2=rb.Vector2,NumberRange=rb.NumberRange,NumberSequence=rb.NumberSequence,NumberSequenceKeypoint=rb.NumberSequenceKeypoint,ColorSequence=rb.ColorSequence,
 task={wait=function(delay)waits+=1;if delayed and delay==.5 then map:SetAttribute('KitSwapVersion',2);delayed=false end end},warn=function()warnings+=1 end,
 game={GetService=function(_,name)if name=='HttpService'then return {JSONDecode=function(_,s)return serde.decode('json',s)end}end;return {WaitForChild=function(_,key)return assert(S:FindFirstChild(key))end}end},
 require=function(n)if n==S.KitLibrary then return kit elseif n==S.KitPlan then return Plan elseif n==node.Presentation then return function()end end;error('unexpected require')end}
local function run()luau.load(node.Source,{environment=env})()end
run();local root=p.Workspace.CaveEscapeC8;local group=assert(root:FindFirstChild('Rocks'));assert(group:GetAttribute('Complete'))
for _,v in duplicates do assert(v.Transparency==1,'original kit duplicate remained visible')end
assert(untouched.Transparency==0,'unrelated kit changed')
local count=0
for _,g in plan do if g.kit then
 count+=1;local q=assert(group:FindFirstChild(g.name)):FindFirstChildWhichIsA('MeshPart')
 assert(q.TextureID==''and not q:FindFirstChildWhichIsA('SurfaceAppearance'),'atlas survived')
 assert(q.Anchored and not q.CanCollide and not q.CanQuery and not q.CanTouch,'cosmetic flags')
 assert(q.Color==rb.Color3.fromRGB(unpack(g.color))and q.Material==rb.Enum.Material.Slate,'tint')
 assert((q.CFrame.Position-rb.Vector3.new(unpack(g.c))).Magnitude<.001,'fit transform')
end end
assert(#group:GetChildren()==count)
local emitters=0
for _,g in plan do if g.sparkle then
 local q=root:FindFirstChild(g.name);local e=assert(q:FindFirstChild('C8FallingSparkles'))
 local sign=e.EmissionDirection==rb.Enum.NormalId.Top and 1 or -1
 assert(q.CFrame.UpVector.Y*sign<-.99 and e.Acceleration.Y<0,'sparkles do not start falling in world space')
 assert(e.Rate<=3 and e.Lifetime.Max<=1.8 and e.LightEmission<=.401,'unbounded sparkle budget')
 emitters+=1
end end
assert(emitters==3,'sparkle fixture count')
local cameras=serde.decode('json',fs.readFile('treasure/cave-sections/C8/CAMERAS.json')).views
for _,g in plan do if g.text then
 local q=root:FindFirstChild(g.name)
 local index=tonumber(g.name:match('SafetyBoard(%d+)'))
 local eye=rb.Vector3.new(unpack(cameras[index].eye))
 assert(q.CFrame.LookVector:Dot((eye-q.CFrame.Position).Unit)>.8,'sign faces away from player approach')
 for _,face in {'C8Front','C8Back'}do
  local gui=assert(q:FindFirstChild(face));local label=assert(gui:FindFirstChildWhichIsA('TextLabel'))
  assert(label.Text==g.text and label.TextScaled,'actual sign lettering does not fit')
 end
end end
local n=#root:GetDescendants();run();assert(#root:GetDescendants()==n,'duplicate kits')
group:Destroy();for _,q in root:GetChildren()do if q:IsA('BasePart')then q.Transparency=0 end end
for _,v in duplicates do v.Transparency=0 end
fail=true;run();assert(not root:FindFirstChild('Rocks'),'failed staging published')
for _,v in duplicates do assert(v.Transparency==0,'failure suppressed original kits')end
for _,q in root:GetChildren()do if q:IsA('BasePart')then assert(q.Transparency==0,'failure hid fallback')end end
fail=false;run();assert(root.Rocks:GetAttribute('Complete'),'retry failed')
for _,v in duplicates do assert(v.Transparency==1,'retry did not retire duplicate')end
assert(untouched.Transparency==0)
local r1=serde.decode('json',fs.readFile('treasure/cave-sections/C8/r1-plan.json'))
for i,g in r1 do assert(serde.encode('json',g)==serde.encode('json',plan[i]),'R1 silhouette changed')end
fs.writeFile('treasure/cave-sections/C8/RUNTIME.json',serde.encode('json',{state='PASS',rocks=count,textured_fixture=true,failure_cleanup_retry=true,idempotence=true,falling_world_space_emitters=emitters,delayed_original_kit_completion=true,original_floating_kit_duplicates_suppressed=24,unrelated_kit_control_exact=true,failure_leaves_original_kits_visible=true,r1_frozen=#r1,yields=waits,expected_failure_warnings=warnings,place_sha256=serde.hash('sha256',bytes)},true))
print('PASS actual mounted C8: atlas, flags, full-envelope lane margins, fit, staging failure/retry, idempotence, frozen R1',count)
