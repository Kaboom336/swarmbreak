local fs,rb,luau,s=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau'),require('@lune/serde')
local pre=rb.deserializePlace(fs.readFile('slice-v2/prototype/guardian-greybox.pre-s3.rbxl'))
local now=rb.deserializePlace(fs.readFile('slice-v2/prototype/guardian-greybox.rbxl'))
local report={workspace_exact=rb.serializeModel({pre.Workspace})==rb.serializeModel({now.Workspace}),storage_exact=pre:FindFirstChild('ServerStorage')==nil and now:FindFirstChild('ServerStorage')==nil,routes={},workspace={}}
for _,pair in {{'before',pre},{'current',now}} do
 local p=pair[2];local solid,parts=0,0
 for _,n in p.Workspace:GetDescendants() do if n:IsA('BasePart') then parts+=1;if n.CanCollide or n.CanQuery then solid+=1 end end end
 report.workspace[pair[1]]={descendants=#p.Workspace:GetDescendants(),parts=parts,solids=solid,children={}}
 for _,n in p.Workspace:GetChildren() do table.insert(report.workspace[pair[1]].children,{name=n.Name,class=n.ClassName,descendants=#n:GetDescendants()}) end
end
local function get(p,name) return luau.load(p.ReplicatedStorage.MeadowV4[name].Source,{environment={}})() end
local routes=get(pre,'RouteData');assert(pre.ReplicatedStorage.MeadowV4.RouteData.Source==now.ReplicatedStorage.MeadowV4.RouteData.Source)
for name,r in routes do
 local length,segments=0,{}
 for i=2,#r do local a,b=r[i-1],r[i];local horizontal=math.sqrt((b.x-a.x)^2+(b.z-a.z)^2);local rise=b.y-a.y;local d=math.sqrt(horizontal^2+rise^2);length+=d;table.insert(segments,{length=d,rise=rise,slope_degrees=math.deg(math.atan2(rise,horizontal))}) end
 report.routes[name]={length=length,segments=segments,before_after_equal=true}
end
fs.writeFile('treasure/carry-state.json',s.encode('json',report,true));print(s.encode('json',report.workspace));print('Workspace exact',report.workspace_exact,'Storage exact',report.storage_exact)
