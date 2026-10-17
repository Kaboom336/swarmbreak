local fs,rb,serde=require('@lune/fs'),require('@lune/roblox'),require('@lune/serde')
local p=rb.deserializePlace(fs.readFile('prototype/cave-v2.pre-c5.rbxl'))
local ray=require('../../../prototype/meadow-v4/OfflineRay').new(p.Workspace.CaveV2,nil,4)
local out={}
for _,v in serde.decode('json',fs.readFile('treasure/cave-sections/C5/CAMERAS.json')).views do
 if v.name=='overview'then continue end
 local e=rb.Vector3.new(unpack(v.eye));local inside={}
 for i,n in p.Workspace.CaveV2:GetDescendants()do
  if n:IsA('BasePart')and n.CanCollide then
   local q=n.CFrame:PointToObjectSpace(e);local h=n.Size/2
   if math.abs(q.X)<h.X-.01 and math.abs(q.Y)<h.Y-.01 and math.abs(q.Z)<h.Z-.01 then table.insert(inside,n.Name)end
  end
  if i%500==0 then require('@lune/task').wait()end
 end
 local hit=ray(e,rb.Vector3.new(0,-24,0))
 table.insert(out,{view=v.name,eye_inside_original_solid_boxes=inside,floor=hit and hit.Instance.Name,floorY=hit and hit.Position.Y})
 assert(#inside==0,'camera inside solid '..v.name)
 assert(hit and hit.Instance.Name:match('^cave'),'camera not above cave floor '..v.name)
end
fs.writeFile('treasure/cave-sections/C5/CAMERA-CHECK.json',serde.encode('json',{state='PASS',views=out,eyes='estimated standing player height, not live motion'},true))
print('PASS 3 player eyes clear of original solids, above mounted cave floors')
