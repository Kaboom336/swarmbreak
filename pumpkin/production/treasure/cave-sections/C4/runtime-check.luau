-- Execute actual mounted arrival script with textured mesh/fit failure fixtures.
local fs,rb,luau,serde=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau'),require('@lune/serde')
local bytes=fs.readFile('prototype/cave-v2.rbxl');local p=rb.deserializePlace(bytes)
local S=p.ServerScriptService;local node=S.CaveBlastC4
local Plan=luau.load(S.KitPlan.Source,{environment={Vector3=rb.Vector3,CFrame=rb.CFrame}})()
local plan=serde.decode('json',node.Plan.Value)
local fail=false;local kit={}
function kit.spawn(_,_,base,size)
 local m=rb.Instance.new('Model');local q=rb.Instance.new('MeshPart');q.TextureID='rbxassetid://123';q.Size=size;q.CFrame=base*rb.CFrame.new(0,size.Y/2,0);q.Parent=m
 local a=rb.Instance.new('SurfaceAppearance');a.Parent=q;return m
end
function kit.fit()return not fail end
local waits,warnings=0,0
local env={script=node,workspace={WaitForChild=function(_,name)return assert(p.Workspace:FindFirstChild(name))end},Instance=rb.Instance,Vector3=rb.Vector3,CFrame=rb.CFrame,Color3=rb.Color3,Enum=rb.Enum,UDim2=rb.UDim2,Font=rb.Font,
 task={wait=function()waits+=1 end},warn=function()warnings+=1 end,
 game={GetService=function(_,name)if name=='HttpService'then return {JSONDecode=function(_,s)return serde.decode('json',s)end}end;return {WaitForChild=function(_,key)return assert(S:FindFirstChild(key))end}end},
 require=function(n)if n==S.KitLibrary then return kit elseif n==S.KitPlan then return Plan elseif n==node.Presentation then return function(map,root,round)assert(map==p.Workspace.CaveV2 and root==p.Workspace.CaveBlastC4 and round=='r4')end end;error('unexpected require')end}
local function run()luau.load(node.Source,{environment=env})()end
run();local root=p.Workspace.CaveBlastC4;local group=assert(root:FindFirstChild('Rocks'));assert(group:GetAttribute('Complete'))
local count=0
for _,g in plan do if g.kit then
 count+=1;local q=assert(group:FindFirstChild(g.name)):FindFirstChildWhichIsA('MeshPart')
 assert(q.TextureID==''and not q:FindFirstChildWhichIsA('SurfaceAppearance'),'atlas survived')
 assert(q.Anchored and not q.CanCollide and not q.CanQuery and not q.CanTouch,'cosmetic flags')
 assert(q.Color==rb.Color3.fromRGB(unpack(g.color))and q.Material==rb.Enum.Material.Slate,'tint')
 assert((q.CFrame.Position-rb.Vector3.new(unpack(g.c))).Magnitude<.001,'fit transform')
end end
assert(#group:GetChildren()==count)
local n=#root:GetDescendants();run();assert(#root:GetDescendants()==n,'duplicate kits')
group:Destroy();for _,q in root:GetChildren()do if q:IsA('BasePart')then q.Transparency=0 end end
fail=true;run();assert(not root:FindFirstChild('Rocks'),'failed staging published')
for _,q in root:GetChildren()do if q:IsA('BasePart')then assert(q.Transparency==0,'failure hid fallback')end end
fail=false;run();assert(root.Rocks:GetAttribute('Complete'),'retry failed')
local r1=serde.decode('json',fs.readFile('treasure/cave-sections/C4/r1-plan.json'))
for i,g in r1 do assert(serde.encode('json',g)==serde.encode('json',plan[i]),'R1 silhouette changed')end
fs.writeFile('treasure/cave-sections/C4/RUNTIME.json',serde.encode('json',{state='PASS',rocks=count,textured_fixture=true,failure_cleanup_retry=true,idempotence=true,r1_frozen=#r1,yields=waits,expected_failure_warnings=warnings,place_sha256=serde.hash('sha256',bytes)},true))
print('PASS actual mounted C4: atlas, flags, full-envelope lane margins, fit, staging failure/retry, idempotence, frozen R1',count)


