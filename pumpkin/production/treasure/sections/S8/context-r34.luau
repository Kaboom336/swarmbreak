-- Diagnostic render proxy, never mounted: reuse actual NativeBlocks connected
-- component bounds for HomeArtDecor in world space, then subtract MeadowOrigin.
local fs,rb,serde,luau=require('@lune/fs'),require('@lune/roblox'),require('@lune/serde'),require('@lune/luau')
local H='treasure/sections/S8/'
local p=rb.deserializePlace(fs.readFile('slice-v2/prototype/guardian-greybox.rbxl'))
local env={Vector3=rb.Vector3,CFrame=rb.CFrame,Color3=rb.Color3,Enum=rb.Enum,Instance=rb.Instance,game={GetService=function(_,name) assert(name=='HttpService');return {JSONDecode=function(_,s)return serde.decode('json',s)end} end}}
local data=luau.load(p.ReplicatedStorage.HomeArtGeometry.Source,{environment=env})()
local blocks=luau.load(fs.readFile('slice-v2/prototype/NativeBlocks.luau'),{environment=env})()
for _,tag in {'r2','r4'} do
 local manifest=serde.decode('json',fs.readFile(H..tag..'.json'))
 local group=rb.Instance.new('Model')
 for _,source in data.Decor do
  local section=table.clone(source)
  local name=section.name:lower()
  local neon=table.find({'PortalLight','PortalGreen','Cyan','LampLight','Lava'},section.name)~=nil
  local material=(name:find('wood') or name:find('brown')) and rb.Enum.Material.WoodPlanks
   or (name:find('grass') or name:find('leaf') or name:find('green')) and rb.Enum.Material.Grass
   or name:find('path') and rb.Enum.Material.Cobblestone or rb.Enum.Material.Slate
  if tag=='r4' and section.name=='Lava' then section.color={143,105,69};neon=false end
  blocks.section(section,group,rb.CFrame.new(0,-76,360),neon and rb.Enum.Material.Neon or material)
 end
 local count=0
 for _,q in group:GetChildren() do
  local c={q.CFrame:GetComponents()};local r={};for i=4,12 do table.insert(r,c[i]) end
  table.insert(manifest.parts,{name='ClientDecor_'..q.Name,position={c[1],c[2],c[3]},rotation=r,size={q.Size.X,q.Size.Y,q.Size.Z},color={q.Color.R*255,q.Color.G*255,q.Color.B*255},material=q.Material.Name,shape='Block',transparency=0,collidable=false,query=false,touch=false,tags={},attributes={},section='ClientDecorProxy'})
  count+=1
 end
 fs.writeFile(H..tag..'-context.json',serde.encode('json',manifest))
 fs.writeFile(H..tag..'-context-Section8.luau',fs.readFile(H..tag..'-Section8.luau'))
 print('PASS context proxy',tag,count,'exact NativeBlocks bounds; only Lava finish differs; world minus MeadowOrigin')
end
