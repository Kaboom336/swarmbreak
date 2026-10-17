local fs,rb,serde=require('@lune/fs'),require('@lune/roblox'),require('@lune/serde')
local H='treasure/cave-sections/C8/'
local p=rb.deserializePlace(fs.readFile('prototype/cave-v2.rbxl'))
local Ray=require('../../../prototype/meadow-v4/OfflineRay')
local floorRay=Ray.new(p.Workspace.CaveV2,function(q)return q:GetAttribute('WalkableLaneFloor')==true end,4)
local out={}
for _,v in serde.decode('json',fs.readFile(H..'CAMERAS.json')).views do
 local e=rb.Vector3.new(unpack(v.eye));local inside={}
 for i,n in p.Workspace:GetDescendants()do
  if n:IsA('BasePart') and n.CanCollide then
   local q=n.CFrame:PointToObjectSpace(e);local h=n.Size/2
   if math.abs(q.X)<h.X-.01 and math.abs(q.Y)<h.Y-.01 and math.abs(q.Z)<h.Z-.01 then table.insert(inside,n.Name)end
  end
  if i%500==0 then require('@lune/task').wait()end
 end
 assert(#inside==0,'camera inside original solid '..v.name)
 local hit=floorRay(e,rb.Vector3.new(0,-24,0))
 if v.name=='portal' or v.name=='cart' then
  assert(hit,'player camera off authored floor '..v.name)
  assert(e.Y-hit.Position.Y>=3 and e.Y-hit.Position.Y<=7,'camera height '..v.name)
 end
 table.insert(out,{view=v.name,inside=inside,floor=hit and hit.Instance.Name,floorY=hit and hit.Position.Y,eyeY=e.Y,role=(v.name=='portal'or v.name=='cart')and'estimated player eye'or'nonplayable inspection camera'})
end
fs.writeFile(H..'CAMERA-CHECK.json',serde.encode('json',{state='PASS',views=out,live_motion=false},true))
print('PASS C8 cameras: native-solid containment, player floor/height, inspection views')
