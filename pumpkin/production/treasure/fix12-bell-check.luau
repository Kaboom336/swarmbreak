-- Execute the entire Studio bell acceptance block, unchanged, against production
-- Traps/Arena and native map parts. Mock engine scheduling/audio/pathfinding only.
local fs,rb,luau,serde=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau'),require('@lune/serde')
local V,C=rb.Vector3,rb.CFrame
local place=rb.deserializePlace(fs.readFile('slice-v2/prototype/guardian-greybox.rbxl'))
local cache={}
local loaderGame={GetService=function() return {WaitForChild=function(_,name) return place.ReplicatedStorage[name] end} end}
local function load(n)
 if cache[n] then return cache[n] end
 cache[n]=luau.load(n.Source,{environment={script=n,require=load,game=loaderGame,Vector3=V,Vector2=rb.Vector2,CFrame=C,Color3=rb.Color3,Enum=rb.Enum,Instance=rb.Instance,UDim2=rb.UDim2,warn=warn}})();return cache[n]
end
local Config=load(place.ReplicatedStorage.GreyboxConfig)
local Traps=load(place.ReplicatedStorage.GreyboxTraps)
local O=load(place.ReplicatedStorage.MeadowV4.Outsmart)
local source=place.ServerScriptService.OutsmartTestRunner.Source
local first=assert(source:find('\t\tstage = "bell"',1,true))
local last=assert(source:find('\n\tend)',first,true))
local bellCode=source:sub(first,last-1)
local reports={}
for _,origin in {V.zero,V.new(0,76,-360)} do
 for _,dt in {1/60,0.05,0.11} do
  local model=load(place.ReplicatedStorage.MeadowV4.Builder).build(rb.Instance.new('Folder'),origin)
  local ray=require('../prototype/meadow-v4/OfflineRay').new(model)
  local function floor(_,p)
   local h=ray(V.new(p.X,p.Y+12,p.Z),V.new(0,-90,0))
   if h and h.Instance:GetAttribute('SurfaceRole')=='Floor' then return h.Position,h.Normal end
  end
  local attr={}
  -- Studio derives Position from CFrame; Lune native instances do not.
  local guard=setmetatable({CFrame=C.new(origin+V.new(0,5.5,0)),Size=V.new(4,11,4),
   SetAttribute=function(_,k,v) attr[k]=v end,GetAttribute=function(_,k) return attr[k] end},
   {__index=function(p,k) if k=='Position' then return p.CFrame.Position end end})
  local a={origin=origin,model=model,guardian=guard,arm={},warning={},keeper=true,mode='Guard',
   layout=load(place.ReplicatedStorage.MeadowV4.Gameplay).assemble(Config,1),throws=0,chaseTicks=0,chaseDistance=0,impacts=0,
   points={},index=1,nextPath=0,nextThrow=0,patrol=1,untilTime=0}
  local game={GetService=function(_,s)
   if s=='PathfindingService' then return {CreatePath=function() return {
    Status=rb.Enum.PathStatus.Success,ComputeAsync=function() end,
    GetWaypoints=function() return {{Position=guard.Position},{Position=a.decoy and a.decoy.position or guard.Position}} end,Destroy=function() end} end} end
   return {WaitForChild=function(_,name) return place.ReplicatedStorage[name] end,MeadowV4=place.ReplicatedStorage.MeadowV4}
  end}
  local Arena=luau.load(place.ServerScriptService.GreyboxArena.Source,{environment={game=game,require=load,
   Vector3=V,CFrame=C,Color3=rb.Color3,Enum=rb.Enum,Instance=rb.Instance,
   workspace={SetAttribute=function() end,Blockcast=function() return nil end,GetServerTimeNow=function() return 100 end},
   task={spawn=function(f) f() end},print=function() end}})()
  Arena.floor=floor;Arena.safe=function() return false end;Arena.sight=function() return true end;Arena.fx=function() end
  local function make(parent,name,size,p,color)
   local n=rb.Instance.new('Part');n.Name,n.Size,n.Position,n.CFrame,n.Color,n.Parent=name,size,p,C.new(p),color,parent;return n
  end
  local manager=Traps.new(Config,Arena,make,function() return {} end)
  local soundCount=0
  -- Execute the actual production rattle callback with an observable audio adapter.
  local server=place.ServerScriptService.Greybox.Source
  local soundStart=assert(server:find('traps.rattle = function(parent)',1,true))
  local soundEnd=assert(server:find('\nlocal function prompt(',soundStart,true))
  luau.load(server:sub(soundStart,soundEnd-1),{environment={traps=manager,Config=Config,
   Instance={new=function(class)
    assert(class=='Sound');return {Play=function(sound)
     assert(not a.decoy,'attention published before sound')
     assert(sound.Looped and sound.SoundId~='' and sound.Parent,'missing production sound setup');soundCount+=1
    end}
   end},game={GetService=function() return {AddItem=function() end} end}}})()
  local actor={UserId=-9001,GetAttribute=function() return nil end}
  local states={[actor]={phase='Run',run=a,meadowEscapes=3,mercy=0}}
  local root={Position=origin+V.new(0,3,0)}
  local checks=0
  local env={Arena=Arena,Traps=Traps,Config=Config,O=O,a=a,manager=manager,actor=actor,state=states[actor],states=states,root=root,
   Vector3=V,CFrame=C,now=100,ground=function(p) return assert(floor(a,origin+p+V.new(0,3,0)),'missing native floor') end,
   check=function(ok,message) assert(ok,message);checks+=1 end}
  local delayed=0
  env.advance=function(seconds,clock)
   -- Preserve requested acceptance deadlines while subdividing at live cadence.
   local remaining=seconds
   repeat
    local step=math.min(dt,remaining);clock+=step;remaining-=step
    Traps.tick(manager,clock,states)
    Arena.tick(a,step,clock,states,function(who) return who==actor and root or nil end,function() error('attack hit') end,function() end)
    if a.decoy then
     assert(a.decoy.trap.part:GetAttribute(Traps.RattleSignal)==true,'attention without rattle')
     assert(a.decoy.trap.part:GetAttribute(Traps.RattleTimeSignal)<=clock,'future rattle')
    end
    delayed+=1
   until remaining<1e-9
   assert(delayed<2000,'acceptance clock stalled')
   return clock
  end
  env.now=luau.load('local now=now\nlocal function tick(seconds) now=advance(seconds,now) end\n'..bellCode..'\nreturn now',{environment=env})()
  assert(soundCount==1,'rattle replayed or second owner triggered during immunity')
  local second=manager.active[1]
  assert(second and not second.triggered and not second.part:GetAttribute(Traps.RattleSignal),'immune bell emitted rattle')
  local immunity=a.decoyImmuneUntil
  env.now=immunity-0.001;Traps.tick(manager,env.now,states);assert(not a.decoy,'immunity ended early')
  -- At exact expiry, another bell may trigger, then must clean up only once.
  guard.CFrame=C.new(second.position+V.new(5,5.5,0))
  env.now=immunity;Traps.tick(manager,env.now,states);assert(a.decoy and soundCount==2,'immunity never expires')
  env.now=second.effectEnd;Traps.tick(manager,env.now,states)
  assert(not a.decoy and #manager.active==0,'exact end cleanup')
  local immuneEnd=a.decoyImmuneUntil
  Traps.tick(manager,env.now+1,states);assert(a.decoyImmuneUntil==immuneEnd,'cleanup refreshed immunity')
  table.insert(reports,{origin={origin.X,origin.Y,origin.Z},dt=dt,checks=checks,ticks=delayed,soundEvents=soundCount,result='PASS'})
  model:Destroy()
 end
end
fs.writeFile('treasure/FIX12-BELL.json',serde.encode('json',{cases=reports,live='UNKNOWN; Studio session unavailable',engineMocks={'audio playback','pathfinding','blockcast','scheduler'}},true))
print('PASS complete production bell acceptance at both origins, 60 Hz / 20 Hz / 110 ms cadence; exact immunity boundaries; single cleanup')
