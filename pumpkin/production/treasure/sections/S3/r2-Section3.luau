-- S3: local-coordinate cosmetic architecture; existing MeadowV4 pcall guard owns failures.
-- R2 silhouette correction. All floors, policy fields, colliders and gameplay sources untouched.
local S={}
local V=Vector3.new
local function part(root,name,frame,size,color,material)
 local p=Instance.new('Part');p.Name='S3_'..name;p.Size=size;p.CFrame=frame
 p.Color=Color3.fromRGB(unpack(color));p.Material=material or Enum.Material.Wood
 p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false
 p:SetAttribute('Section','S3');p:SetAttribute('Cosmetic',true);p:SetAttribute('MeadowV4Category','s3_architecture');p.Parent=root;return p
end
local function beam(root,name,a,b,width,depth,color)
 -- Explicit basis keeps Lune and Studio identical; all shoring endpoints share Z.
 local d=b-a;assert(math.abs(d.Z)<.001);local n=d.Unit;local c=(a+b)/2
 local cf=CFrame.new(c.X,c.Y,c.Z,0,-n.Y,n.X,0,n.X,n.Y,-1,0,0)
 local p=part(root,name,cf,V(width,depth,d.Magnitude),color)
 return p
end
local function glow(root,name,x,y,z,brightness)
 local p=part(root,name,CFrame.new(x,y,z),V(.65,.8,.8),{255,210,133},Enum.Material.Neon)
 local l=Instance.new('PointLight');l.Color=Color3.fromRGB(255,211,145);l.Brightness=brightness or 3;l.Range=28;l.Shadows=true;l.Parent=p
 return p
end
function S.build(root)
 -- Old hanging silhouettes compete with the shoring, but never touch protected parts or path stones.
 local remove={TunnelStalactite=true,TunnelArchedRockRib=true,TunnelWallRoot=true,TunnelWallMoss=true}
 for _,p in root:GetDescendants() do if p:IsA('BasePart') and remove[p.Name] and not p.CanCollide and not p.CanQuery and not p.CanTouch and not p:GetAttribute('WalkableLaneFloor') and #p:GetTags()==0 then
  local v=p.CFrame.Position;if v.X>=-90 and v.X<=-63 and v.Z>=-22 and v.Z<=70 and v.Y>=8 and v.Y<=28 then p:Destroy() end
 end end
 for i=0,7 do
  local z=-11+i*11;local brown={111,73,43}
  part(root,'RibHeader'..i,CFrame.new(-76,23.4,z),V(14,1.2,1.2),brown)
  for _,side in {-1,1} do
   local x=-76+side*6.6
   part(root,'RibLeg'..i..'_'..side,CFrame.new(x,14.25,z),V(1.2,9.35,1.2),brown)
   beam(root,'RibBrace'..i..'_'..side,V(x,18.7,z),V(-76+side*4.2,23.4,z),1.2,1.2,brown)
   glow(root,'RibSource'..i..'_'..side,-76+side*5.68,11,z,3.8)
  end
 end
 -- Each source hangs from an existing retained ceiling; no light through new openings.
 for i,g in {{-76,73},{-61.8,94}} do
  part(root,'ExitHanger'..i,CFrame.new(g[1],18.4,g[2]),V(.18,11.2,.18),{64,50,39})
  glow(root,'ExitSource'..i,g[1],12.4,g[2],8)
  part(root,'ExitCap'..i,CFrame.new(g[1],12.9,g[2]),V(1.1,.2,1.1),{64,50,39})
 end
end
return S
