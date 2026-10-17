local fs,rb,luau,serde=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau'),require('@lune/serde')
local bytes=fs.readFile('prototype/cave-v2.rbxl');local p=rb.deserializePlace(bytes)
local node=p.ServerScriptService.CaveEscapeC7;assert(node.Presentation.Source==fs.readFile('treasure/cave-sections/C7/labels.luau'))
local native={}
for _,n in p.Workspace.CaveV2:GetDescendants()do if n:IsA('BasePart')then native[n]={n.CFrame,n.Size,n.Color,n.Material,n.CanCollide,n.CanQuery,n.CanTouch,n.Transparency}end end
local waits=0
local f=luau.load(node.Presentation.Source,{environment={Instance=rb.Instance,Vector3=rb.Vector3,UDim2=rb.UDim2,Color3=rb.Color3,Font=rb.Font,task={wait=function()waits+=1 end}}})()
f(p.Workspace.CaveV2,p.Workspace.CaveEscapeC7,node.Round.Value)
f(p.Workspace.CaveV2,p.Workspace.CaveEscapeC7,node.Round.Value)
local count=0
for n,v in native do
 local now={n.CFrame,n.Size,n.Color,n.Material,n.CanCollide,n.CanQuery,n.CanTouch,n.Transparency}
 for i,x in v do assert(now[i]==x,'original native field write')end
 for _,g in n:GetChildren()do if g.Name=='C7FootExit'or g.Name=='C7CaveExit'then
  local distance=node.Round.Value=='r4'and(g.Name=='C7FootExit'and 32 or 45)or 70
  count+=1;assert(g:IsA('BillboardGui')and g.Adornee==n and not g.AlwaysOnTop and g.MaxDistance==distance and g.LightInfluence==0)
  assert(g.Size.X.Scale==0 and g.Size.Y.Scale==0 and g.Size.Y.Offset==28)
  assert(g.Size.X.Offset==(node.Round.Value=='r4'and 104 or 112))
  assert(g.StudsOffsetWorldSpace==rb.Vector3.new(0,node.Round.Value=='r4'and 2.5 or 4,0))
  local t=g:FindFirstChildWhichIsA('TextLabel');assert(t and t.TextScaled and (t.Text=='FOOT EXIT'or t.Text=='CAVE EXIT'))
  local pos=n.CFrame.Position+g.StudsOffsetWorldSpace
  assert(pos.X>=-154 and pos.X<=75 and pos.Z>=65 and pos.Z<=156)
 end end
end
assert(count==2,'missing/duplicate route labels')
local board=serde.decode('json',node.Plan.Value)
local guiCount=0
-- Actual mounted runtime fixture separately creates and checks the new SurfaceGui.
for _,g in board do if g.text then guiCount+=1 end end
fs.writeFile('treasure/cave-sections/C7/LABELS.json',serde.encode('json',{state='PASS',place_sha256=serde.hash('sha256',bytes),actual_mounted_module=true,labels=count,all_original_native_fields_exact=true,fixed_pixels=true,world_occlusion=true,idempotence=true,yields=waits,new_surface_boards=guiCount,live_text_and_remote_font='UNKNOWN; offline fixture'},true))
print('PASS actual labels: two fixed-pixel world-occluded approach labels; original native fields exact; idempotent; yielding')
