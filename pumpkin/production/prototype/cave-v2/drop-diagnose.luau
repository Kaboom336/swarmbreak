local fs,rb,luau=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau')
local V=rb.Vector3
local place=rb.deserializePlace(fs.readFile('prototype/cave-v2.rbxl'))
local map=place.Workspace.CaveV2
local Ray=require('../meadow-v4/OfflineRay')
local lane=Ray.new(map,function(p) return p:GetAttribute('WalkableLaneFloor') end,4)
local solid=Ray.new(map,nil,4)
local D=luau.load(place.ServerScriptService.CaveReachableDrops.Source,{environment={}})()
for _,root in {V.new(-65.3125,16,34.0625),V.new(-100.3125,11,-7.1875)} do
 local f=D.floor(root,lane,V);print('carrier',root,'floor',f)
 if not f then print('seed ray',lane(root+V.new(0,5,0),V.new(0,-12,0)));continue end
 local c=lane(f+V.new(0,2.05,0),V.new(0,-4.1,0));print('central normal',c.Normal)
 local reasons={}
 for ix=-6,6 do for iz=-6,6 do if ix*ix+iz*iz>36 then continue end
  local x,z=f.X+ix*.5,f.Z+iz*.5
  local h=lane(V.new(x,f.Y+2.05,z),V.new(0,-4.1,0))
  local top=solid(V.new(x,c.Position.Y+8.25,z),V.new(0,-10.45,0))
  local up=solid(V.new(x,c.Position.Y+2.2,z),V.new(0,6,0))
  local reason
  if not h then reason='no floor'
  elseif math.abs(h.Position.Y-c.Position.Y)>2.15 then reason='slope'
  elseif not top then reason='no solid'
  elseif top.Instance:GetAttribute('WalkableLaneFloor')~=true then reason='untagged '..top.Instance.Name
  elseif math.abs(top.Position.Y-h.Position.Y)>.1 then reason='height mismatch '..top.Instance.Name
  elseif up then reason='head strike '..up.Instance.Name end
  if reason then reasons[reason]=(reasons[reason] or 0)+1 end
 end end
 print(reasons)
end
