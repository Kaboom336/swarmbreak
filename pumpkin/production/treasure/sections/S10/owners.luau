-- Execute actual UIWorld decorator and actual Section9 bind against staged UI.
local fs,rb,luau=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau')
local p=rb.deserializePlace(fs.readFile('slice-v2/prototype/guardian-greybox.rbxl'))
local before=rb.deserializePlace(fs.readFile('slice-v2/prototype/guardian-greybox.pre-s10.rbxl'))
assert(p.StarterPlayer.StarterPlayerScripts.HomeArt.Source==before.StarterPlayer.StarterPlayerScripts.HomeArt.Source,'HomeArt changed')
local world=rb.Instance.new('Folder');world.Name='GREYBOX';world.Parent=p.Workspace
for i=1,8 do local plot=rb.Instance.new('Model');plot.Name='HomePlot'..i;plot.Parent=world end
local workspaceService=p.Workspace;local cache={}
local function load(n)
 if cache[n]then return cache[n]end
 cache[n]=luau.load(n.Source,{environment={script=n,require=load,Vector3=rb.Vector3,Vector2=rb.Vector2,CFrame=rb.CFrame,Color3=rb.Color3,Instance=rb.Instance,Enum=rb.Enum,UDim2=rb.UDim2,
 game={GetService=function(_,name)if name=='Workspace'then return workspaceService end;assert(name=='ReplicatedStorage');return p.ReplicatedStorage end}}})();return cache[n]
end
local section=load(p.ReplicatedStorage.MeadowV4.Section9);section.build(nil,rb.Vector3.new(513,77,-912))
local group=world.HomeYardsS9;local sources,callbacks,guis={},{},{}
local fakeWorld={FindFirstChild=function(_,name)
 if name=='HomeYardsS9'then return group end
 local slot=tonumber(name:match('^HomePlot(%d+)$'));if not slot then return end
 return {FindFirstChild=function()return {FindFirstChildOfClass=function()return guis[slot]end}end}
end}
workspaceService={FindFirstChild=function()return fakeWorld end}
for i=1,8 do
 local slot=i
 sources[i]={Text='> Pen '..i..' / vacant',GetPropertyChangedSignal=function(_,field)
  assert(field=='Text');return {Connect=function(_,callback)assert(not callbacks[slot],'duplicate owner listener');callbacks[slot]=callback end}
 end}
 guis[i]={Enabled=true,FindFirstChildWhichIsA=function()return sources[slot]end}
end
local uiSource
for _,n in p.StarterPlayer.StarterPlayerScripts:GetDescendants()do
 if n:IsA('LuaSourceContainer')and n.Source:find('local function styledPrompt',1,true)then
  assert(not uiSource,'ambiguous UI decorator');uiSource=n.Source
 end
end
assert(uiSource==fs.readFile('prototype/core/UIWorld.client.luau'),'mounted UIWorld differs from inspected code')
local a=assert(uiSource:find('local function styledPrompt',1,true));local b=assert(uiSource:find('workspace.DescendantAdded',a,true))
local decorate=luau.load(uiSource:sub(a,b-1)..'\nreturn decorate',{environment={Style=load(p.ReplicatedStorage.UIStyle),Enum=rb.Enum,workspace=p.Workspace}})()
-- Actual generic decorator runs before owner-binding, then again after it.
local function decorateBoards()
 for _,board in group:GetChildren()do
  if board.Name:match('^S9_PlotBoard')or board.Name:match('^S9_NumberBanner')then
   decorate(board);for _,node in board:GetDescendants()do decorate(node)end
  end
 end
end
decorateBoards()
local board7=group.S9_PlotBoard7;local face7=board7:GetChildren()[2];face7.Parent=nil
local delayed=guis[8];guis[8]=nil
assert(section.bindOwners()==6)
assert(not board7:GetAttribute('S9OwnerBound')and not board7:GetChildren()[1]:FindFirstChild('LiveOwner'),'partial faces created a stale row')
assert(guis[7].Enabled,'source hidden before ready')
face7.Parent=board7;guis[8]=delayed
assert(section.bindOwners()==8 and section.bindOwners()==8)
decorateBoards()
for i=1,8 do
 local function check(expected)
  local n=0
  for _,gui in group:FindFirstChild('S9_PlotBoard'..i):GetChildren()do if gui:IsA('SurfaceGui')then
   local owners=0;for _,q in gui:GetChildren()do if q.Name=='LiveOwner'then owners+=1;assert(q.Text==expected)end end
   assert(owners==1,'owner row lost/duplicated by decorator');n+=1
  end end
  assert(n==2 and not guis[i].Enabled)
 end
 check('vacant');sources[i].Text='> Pen '..i..' / Zion';callbacks[i]();check('Zion')
 sources[i].Text='> Pen '..i..' / vacant';callbacks[i]();check('vacant')
end
print('PASS actual UIWorld before/after bind; 8 boards x 2 faces vacant/name/vacant; delayed source and partial face; single binding; HomeArt exact')
-- Negative control: proves the original generic RouteLabel opt-in destroys rows.
local probe=rb.Instance.new('Part');probe.Name='RaceControl';probe.Parent=world
local style=load(p.ReplicatedStorage.UIStyle);style.sign(probe,'PLOT')
local stale=rb.Instance.new('TextLabel');stale.Name='LiveOwner';stale.Parent=probe:GetChildren()[1]
probe:SetAttribute('RouteLabel','PLOT');decorate(probe)
for _,gui in probe:GetChildren()do assert(not gui:FindFirstChild('LiveOwner'),'negative control failed')end
print('PASS negative control reproduces old RouteLabel owner-row loss')
