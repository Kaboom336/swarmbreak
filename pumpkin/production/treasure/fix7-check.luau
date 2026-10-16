-- Offline regression evidence; engine collision and Humanoid movement need Studio.
local fs,rb,luau,serde=require("@lune/fs"),require("@lune/roblox"),require("@lune/luau"),require("@lune/serde")
local process=require("@lune/process")
local V,C=rb.Vector3,rb.CFrame
local function build(path,origin)
 local place=rb.deserializePlace(fs.readFile(path));local cache={}
 local function load(node)
  if cache[node] then return cache[node] end
  cache[node]=luau.load(node.Source,{environment={script=node,require=load,Vector3=V,Vector2=rb.Vector2,CFrame=C,Color3=rb.Color3,Enum=rb.Enum,Instance=rb.Instance,UDim2=rb.UDim2,warn=warn}})();return cache[node]
 end
 return load(place.ReplicatedStorage.MeadowV4.Builder).build(rb.Instance.new("Folder"),origin),place,load
end
local function physics(model)
 local out={}
 for _,p in model:GetDescendants() do if p:IsA("BasePart") and (p.CanCollide or p:GetAttribute("WalkableLaneFloor")) then
  table.insert(out,serde.encode("json",{p.Name,{p.CFrame:GetComponents()},{p.Size.X,p.Size.Y,p.Size.Z},p.CanCollide,p.CanQuery,p:GetAttribute("SurfaceRole"),p:GetTags()}))
 end end
 table.sort(out);return table.concat(out,"\n")
end
local model,place,load
if process.args[1]~="policy" then
for _,origin in {V.zero,V.new(0,76,-360)} do
 local old=build("slice-v2/prototype/guardian-greybox.pre-fix7.rbxl",origin)
 model,place,load=build("slice-v2/prototype/guardian-greybox.rbxl",origin)
 assert(physics(old)==physics(model),"physical geometry/floor/tag drift")
 assert(not model:FindFirstChild("OutsmartRamp"),"floating recovery label")
 for _,p in model:GetChildren() do if p.Name=="S1_SignPost" then assert(p.Size.Z/2<.2,"post protrudes through board face") end end
end
print("PASS production builder at zero/live origins: physical geometry/floors/tags parity; signpost depth; label removed")
else place=rb.deserializePlace(fs.readFile("slice-v2/prototype/guardian-greybox.rbxl")) end
-- The production cover (not its nonquery kit skin) must remain queryable.
local cover
if model then
for _,p in model:GetDescendants() do if p.Name=="R5BoulderFoot" and math.abs(p.CFrame.Position.X+73)<.01 and math.abs(p.CFrame.Position.Z+247)<.01 then cover=p end end
assert(cover and cover.CanCollide and cover.CanQuery,"broad corner collider missing")
else
 cover=rb.Instance.new("Part");cover.Name="R5BoulderFoot";cover.CFrame=C.new(-73,80.305,-247);cover.Size=V.new(8.16,8.61,8.16)
end
cover:SetAttribute("SurfaceRole","Cover") -- Arena's production category mapping.
local floorParams,coverParams={},{}
local stars,casts=0,0
local Kit=luau.load(place.ReplicatedStorage.MeadowKeeper.Attacks.Source,{environment={Vector3=V,CFrame=C,Color3=rb.Color3,Instance=rb.Instance,Enum=rb.Enum,
 workspace={Blockcast=function(_,_,_,delta,params)
  casts+=1;assert(params==coverParams,"dash consumed general floor seam query")
  return {Instance=cover,Normal=-V.zAxis,Position=cover.CFrame.Position-V.new(0,0,cover.Size.Z/2)}
 end}}})()
local a={guardian=rb.Instance.new("Part"),model=rb.Instance.new("Model"),warning={},throws=0,params=floorParams,wallParams=coverParams}
a.guardian.Size=V.new(4,11,4)
local api={floor=function(_,p) return V.new(p.X,76.12,p.Z) end,safe=function() return false end,dashLegal=function() return true end,
 fx=function(_,name) if name=="WallStun" then stars+=1 end end}
local function dash(now)
 a.guardian.CFrame=C.lookAt(V.new(-73,81.62,-272),V.new(-73,81.62,-256))
 a.guardian.Position=V.new(-73,81.62,-272)
 assert(Kit.begin(a,{},V.new(-73,79.12,-256),now,"dash",api,{}))
 Kit.step(a,now+.55,{},function() end,function() error("unexpected player hit") end,api,{})
end
dash(10);assert(stars==1 and a.keeperStunUntil and not a.attack,"wall stun/one-shot FX")
local untilTime=a.keeperStunUntil;dash(30);assert(stars==1 and a.keeperStunUntil==untilTime,"repeat corner refresh")
print("PASS actual dash branch with mocked collision: cover-only query, single stun/star request, no repeat refresh; live Blockcast UNKNOWN")
-- Execute actual recovery wrapper with nil coordinates and production-style retire.
local source=place.ServerScriptService.GreyboxLoopTestRunner.Source
local wrapper=assert(source:match('(local function recover%(api, actor, states, walk, item, log, checked%).-)\n%-%- Live production expiry'))
local fields,logs,raycasts={}, {},0
local resultOK,resultValue,resultWhy=true,false,"expiry"
local retireDuringAttempt=false
local lastDrop="{}"
local recover=luau.load(wrapper.."\nreturn recover",{environment={
 Vector3=V,Enum=rb.Enum,RaycastParams={new=function() return {} end},
 SSS={GetAttribute=function() return lastDrop end},
 game={GetService=function() return {JSONDecode=function(_,s) return serde.decode("json",s) end} end},
 updateDrop=function(values) for k,v in values do fields[k]=v end end,
 recoverAttempt=function(_,_,_,_,item) if retireDuringAttempt then item.position=nil;item.state="Retired" end;if not resultOK then error(resultValue,0) end;return resultValue,resultWhy end,
 workspace={Raycast=function() raycasts+=1 end},
}})()
local actor={};local function log(s) table.insert(logs,s) end
local ok,why=recover({},actor,{},nil,{id="retired",state="Retired"},log,nil)
assert(ok==false and why=="expiry" and fields.reason=="expiry" and raycasts==0,"nil expiry diagnostic")
lastDrop='{"lootPos":[7,8,9]}'
recover({},actor,{},nil,{id="retired",state="Retired"},log,nil)
assert(fields.lootPos[1]==7 and raycasts==1,"production last-drop fallback")
lastDrop="{}";raycasts=0
resultOK=false;resultValue="original recovery failure"
local passed,problem=pcall(recover,{},actor,{},nil,{id="carried",state="Carried",visual={Position=V.new(1,2,3)}},log,nil)
assert(not passed and problem==resultValue and fields.lootPos[1]==1 and raycasts==1,"original error/visual fallback")
-- Reproduce a retirement during recoverAttempt: the wrapper keeps entry position.
resultOK=true;resultValue=false
local item={id="expired",state="Dropped",position=V.new(4,5,6)}
retireDuringAttempt=true
recover({},actor,{},nil,item,log,nil)
assert(fields.lootPos[1]==4,"last position fallback")
local pvpStart=assert(source:find("function Test.pvp",1,true))
local pvp=source:sub(pvpStart)
assert(assert(pvp:find("api.pvpCourt(true)",1,true))<assert(pvp:find('hold(api, dummy, "Steal")',1,true)),"guardian isolation too late")
print("PASS actual recovery diagnostics: nil expiry reason, visual fallback, original error; PvP isolation precedes timed pickup")
