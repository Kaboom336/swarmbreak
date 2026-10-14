local P=require('./TunnelPolicy')
local n=0
local function check(value,message) assert(value,message);n+=1 end
check(P.inside(-76,3,-20),'entrance route')
check(P.inside(-76,3,40),'trunk')
check(P.inside(-60,3,85),'south branch')
check(not P.inside(-100,3,20),'surface west excluded')
check(not P.inside(-76,30,40),'roof excluded')
check(not P.inside(-76,-3,40),'buried ground excluded')
check(P.inMud(-76,3,-7) and P.inMud(-76,3,17),'puddle full24')
check(not P.inMud(-76,3,18),'mud ends')
check(P.Tuning.MudLength/P.Tuning.MudSpeed==3,'puddle3seconds')
check(P.Tuning.ShadowSeconds==.7,'warning0.7')
check(P.interval(7.99)==2.4,'before rumble')
check(P.interval(8)==.9,'rumble threshold')
check(P.predict(-76,78,.59)==1 and P.predict(-76,78,.61)==2,'near prediction uncertainty')
check(P.predict(-61,99,.59)==2 and P.predict(-61,99,.61)==1,'south prediction uncertainty')
check(#P.path(1)==7 and #P.path(2)==9,'surface paths terminate selected exit')
check(P.path(1)[7].z==P.Exits[1].z,'near surface endpoint')
check(P.path(2)[9].z==P.Exits[2].z,'south surface endpoint')
check(P.Tuning.ExitWaitTimeout>105/16+1.5,'guard persists beyond nominal crossing')
check(P.Tuning.Width>=12 and P.Tuning.Width<=14,'approved width')
check(P.Tuning.Ceiling>=20,'jump headroom')
local tx,tz=P.hazardTarget(-76,0,0,8)
check(tx==-76 and math.abs(tz-8.4)<.00001,'lead targets mud runner impact position')
tx,tz=P.hazardTarget(-76,0,0,0);check(tx==-76 and tz==0,'stationary shadow stays under thief')
tx,tz=P.hazardTarget(-76,76,0,16);check(P.inside(tx,3,tz),'boundary lead remains in cave')
check(not P.shouldIntercept('A',1,100,'A',1,100),'same visit repick cannot restart active intercept')
check(P.shouldIntercept('A',1,100,'A',1,110),'new visit re-invokes external adapter for same player/exit')
check(P.shouldIntercept('A',1,100,'B',1,100),'ownership handoff starts distinct pursuit')
check(P.shouldIntercept(nil,nil,nil,'A',1,100),'first adapter dispatch')
check(P.Tuning.ExitGuardRadius==12,'guard covers full14-wide mouth and18-wide apron')
check((P.Exits[1].x-P.Exits[2].x)^2+(P.Exits[1].z-P.Exits[2].z)^2>(2*P.Tuning.ExitGuardRadius)^2,'guard mouth discs do not overlap')
local fs=require('@lune/fs')
local rb=require('@lune/roblox')
local serde=require('@lune/serde')
local scene=serde.decode('json',fs.readFile('prototype/meadow-v4/scene.json'))
local current=rb.deserializePlace(fs.readFile('prototype/meadow-v4.rbxl'))
local baseline=rb.deserializePlace(fs.readFile('prototype/meadow-v4/tunnel-baseline.rbxl'))
local old={}
for _,item in baseline:GetDescendants() do if item:IsA('LuaSourceContainer') and item.Name~='Data' then old[item:GetFullName()]=item.Source end end
local newCount=0
for _,item in current:GetDescendants() do
 if item:IsA('LuaSourceContainer') and item.Name~='Data' then
  local compiled,err=loadstring(item.Source);check(compiled~=nil,'Luau syntax '..item.Name..' '..tostring(err))
  local source=old[item:GetFullName()]
  if source then
   if item.Name=='MeadowV4Links' then
    local hook=item.Source:find('-- Isolated tunnel prototype bridge.',1,true)
    local normalized=item.Source:sub(1,hook-1)
    local function removePlain(text,needle,replacement)
     local a,b=text:find(needle,1,true);assert(a,'missing approved hook fragment');return text:sub(1,a-1)..(replacement or '')..text:sub(b+1)
    end
    normalized=removePlain(normalized,'local TunnelPolicy = require(game:GetService("ReplicatedStorage"):WaitForChild("MeadowV4"):WaitForChild("TunnelPolicy"))\n')
    normalized=removePlain(normalized,'    -- Tunnel drop rays start below its roof, so manual/lifecycle drops remain rival-grabbable.\n    local rayHeight=if TunnelPolicy.inside(x,3,z) then 10 else 70\n')
    normalized=removePlain(normalized,'Vector3.new(x,rayHeight,z)','Vector3.new(x,70,z)')
    check(normalized==source,'only documented Links adapter and roof-safe drop hook')
   else check(item.Source==source,'existing source unchanged '..item:GetFullName()) end
  else
   check(item.Name=='TunnelPolicy' or item.Name=='TunnelController','only isolated tunnel modules added')
   check(item.Source==fs.readFile('prototype/meadow-v4/'..item.Name..'.luau'),'native tunnel Source exact '..item.Name)
   newCount+=1
  end
 end
end
check(newCount==2,'two separate modules')
local model=current:FindFirstChildOfClass('Workspace'):FindFirstChild('MeadowV4');local buckets={};local count=0
local function key(name,pos) return name..':'..math.floor(pos[1]/8+.00001)..':'..math.floor(pos[2]/8+.00001)..':'..math.floor(pos[3]/8+.00001) end
for _,p in model:GetChildren() do
 if p:IsA('BasePart') then local k=key(p.Name,{p.CFrame:GetComponents()});buckets[k]=buckets[k] or {};table.insert(buckets[k],p);count+=1 end
end
check(count==#scene.parts,'native geometry part count')
for _,p in scene.parts do
 local bucket=buckets[key(p.name,p.position)] or {};local matched=nil
 for i,q in bucket do
  local cf={q.CFrame:GetComponents()};local good=true
  for j=1,3 do if math.abs(cf[j]-p.position[j])>.0001 then good=false end end
  for j=1,9 do if math.abs(cf[j+3]-p.rotation[j])>.0001 then good=false end end
  for j,v in {q.Size.X,q.Size.Y,q.Size.Z} do if math.abs(v-p.size[j])>.0001 then good=false end end
  if good then assert(q.CanCollide==p.collidable,'collision mismatch');matched=i;break end
 end
 assert(matched,'native geometry mismatch '..p.name);table.remove(bucket,matched)
end
local report={state='PASS',assertions=n,matched_native_parts=count,tolerance_studs=.0001,existing_sources='byte-equal except documented isolated Links adapter and below-roof drop ray',Studio_runtime='UNKNOWN'}
fs.writeFile('treasure/map-v4/TUNNEL-TEST.json',serde.encode('json',report,true))
print('PASS '..n..' policy/artifact assertions; '..count..' exact native parts; runtime UNKNOWN')
