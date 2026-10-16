-- S2 exterior dressing only; local coordinates until MeadowV4 translates once.
local S={kits={}}
local V=Vector3.new
-- R2 locked-camera ray-visible identity whitelist. Physical entries permit palette only.
local r2Remove={
 ["Fix1AmethystCrystal@-83.34,1.97,74.33"]=true,
 ["Fix1AmethystCrystal@-83.18,1.56,74.13"]=true,
 ["Fix1AmethystCrystal@-82.89,1.08,75.74"]=true,
 ["Fix1AmethystCrystal@-81.93,1.07,75.95"]=true,
 ["Fix1AmethystCrystal@-56.69,1.75,98.89"]=true,
 ["Fix1AmethystCrystal@-56.33,1.75,98.42"]=true,
 ["Fix1AmethystCrystal@-57.32,1.63,98.45"]=true,
 ["Fix1AmethystCrystal@-55.96,1.61,97.08"]=true,
 ["Fix1AmethystCrystal@-56.29,1.61,97.26"]=true,
 ["Fix1AmethystCrystal@-56.42,1.65,97.90"]=true,
 ["Fix1HillSlateBacking@-78.61,10.14,116.79"]=true,
 ["Fix1HillSlateBacking@-78.28,21.38,111.03"]=true,
 ["Fix1HillSlateBacking@-115.34,15.43,33.45"]=true,
 ["Fix1HillSlateBacking@-115.33,14.89,27.25"]=true,
 ["Fix1HillSlateBacking@-115.34,14.64,21.05"]=true,
 ["Fix1HillSlateBacking@-103.98,28.81,21.23"]=true,
 ["Fix1HillSlateBacking@-115.38,14.64,14.88"]=true,
 ["Fix1HillSlateBacking@-115.45,14.84,8.75"]=true,
 ["TunnelExitArchShoulderVoxel1@-89.00,7.00,78.00"]=true,
 ["TunnelExitArchShoulderVoxel3@-87.25,5.43,78.00"]=true,
 ["TunnelExitArchShoulderVoxel1@-89.90,14.00,78.00"]=true,
 ["TunnelExitArchShoulderVoxel3@-88.15,12.43,78.00"]=true,
 ["TunnelExitArchShoulderVoxel3@-89.05,19.43,78.00"]=true,
 ["TunnelExitArchShoulderVoxel1@-63.00,7.00,78.00"]=true,
 ["TunnelExitArchShoulderVoxel2@-64.75,5.43,78.00"]=true,
 ["TunnelExitArchShoulderVoxel1@-62.10,14.00,78.00"]=true,
 ["TunnelExitArchShoulderVoxel2@-63.85,12.43,78.00"]=true,
 ["TunnelExitArchShoulderVoxel1@-61.20,21.00,78.00"]=true,
 ["TunnelExitArchShoulderVoxel2@-62.95,19.43,78.00"]=true,
 ["TunnelExitArchShoulderVoxel1@-49.00,7.00,99.00"]=true,
 ["TunnelExitArchShoulderVoxel2@-50.75,5.43,99.00"]=true,
 ["TunnelExitArchShoulderVoxel3@-47.25,5.43,99.00"]=true,
 ["TunnelExitArchShoulderVoxel1@-48.10,14.00,99.00"]=true,
 ["TunnelExitArchShoulderVoxel2@-49.85,12.43,99.00"]=true,
 ["TunnelExitArchShoulderVoxel3@-46.35,12.43,99.00"]=true,
 ["TunnelExitArchShoulderVoxel1@-47.20,21.00,99.00"]=true,
 ["TunnelExitArchShoulderVoxel2@-48.95,19.43,99.00"]=true,
 ["TunnelExitArchShoulderVoxel3@-45.45,19.43,99.00"]=true,
 ["TunnelBlueCrystal@-83.07,1.85,37.44"]=true,
 ["TunnelBlueCrystal@-83.32,2.10,40.82"]=true,
 ["TunnelBlueCrystal@-69.02,2.00,65.65"]=true,
 ["TunnelBlueCrystal@-66.62,2.08,63.82"]=true,
 ["TunnelBlueCrystal@-67.95,1.05,65.98"]=true,
 ["TunnelBlueCrystal@-67.64,1.25,66.17"]=true,
 ["TunnelBlueCrystal@-52.28,1.48,86.01"]=true,
 ["TunnelBlueCrystal@-51.48,1.65,88.80"]=true,
 ["TunnelBlueCrystal@-51.55,1.65,88.47"]=true,
 ["TunnelBlueCrystal@-51.45,1.65,89.18"]=true,
 ["TunnelStalactite@-78.01,28.35,41.70"]=true,
 ["Fix1AmethystCrystal@-83.36,1.08,75.65"]=true,
 ["Fix1AmethystCrystal@-82.88,1.20,75.76"]=true,
 ["Fix1AmethystCrystal@-82.86,1.20,75.32"]=true,
 ["Fix1AmethystCrystal@-57.44,1.63,98.13"]=true,
 ["Fix1AmethystCrystal@-57.48,1.71,97.10"]=true,
 ["Fix1AmethystCrystal@-57.04,1.71,97.12"]=true,
 ["Fix1HillSlateBacking@-104.02,28.53,15.15"]=true,
 ["Fix1HillSlateBacking@-104.09,28.31,9.09"]=true,
 ["Fix1HillSlateBacking@-115.52,15.16,2.68"]=true,
 ["Fix1HillSlateBacking@-104.18,28.13,3.07"]=true,
 ["Fix1HillSlateBacking@-115.61,15.52,-3.34"]=true,
 ["Fix1HillSlateBacking@-109.90,22.22,-3.12"]=true,
 ["TunnelExitArchShoulderVoxel1@-90.80,21.00,78.00"]=true,
 ["TunnelExitArchShoulderVoxel3@-61.25,5.43,78.00"]=true,
 ["TunnelExitArchShoulderVoxel3@-60.35,12.43,78.00"]=true,
 ["TunnelExitArchShoulderVoxel3@-59.45,19.43,78.00"]=true,
}
local r2Stone={
 ["SolidMountainStone@-102.00,-18.50,62.00"]=true,
 ["SolidMountainStone@-98.00,-18.50,70.00"]=true,
 ["SolidMountainStone@-94.00,-18.50,74.00"]=true,
 ["SolidMountainStone@-86.00,-18.50,90.00"]=true,
 ["SolidMountainStone@-82.00,-18.50,94.00"]=true,
 ["SolidMountainStone@-70.00,-18.50,110.00"]=true,
 ["SolidMountainStone@-66.00,-18.50,114.00"]=true,
 ["SolidMountainStone@-62.00,-18.50,118.00"]=true,
 ["SolidMountainStone@-58.00,-18.50,122.00"]=true,
 ["SolidMountainStone@-54.00,-18.50,126.00"]=true,
 ["R5BoulderFoot@-73.00,4.30,113.00"]=true,
 ["TunnelRockCourse@-77.77,2.80,102.00"]=true,
 ["TunnelRockCourse@-78.00,18.44,102.25"]=true,
 ["TunnelRockCourse@-77.77,25.76,101.75"]=true,
 ["TunnelRockCourse@-88.00,4.30,84.00"]=true,
 ["TunnelRockCourse@-87.77,12.62,84.25"]=true,
 ["TunnelRockCourse@-88.23,19.94,84.25"]=true,
 ["TunnelRockCourse@-88.00,26.26,83.75"]=true,
 ["TunnelHillEarth@-79.00,8.25,117.00"]=true,
 ["TunnelHillEarth@-79.00,13.45,111.00"]=true,
 ["TunnelHillEarth@-79.00,17.47,105.00"]=true,
 ["TunnelHillEarth@-79.00,20.01,99.00"]=true,
 ["TunnelHillEarth@-73.00,32.92,99.00"]=true,
 ["TunnelHillEarth@-67.00,33.30,99.00"]=true,
 ["TunnelHillEarth@-85.00,19.96,93.00"]=true,
 ["TunnelHillEarth@-79.00,33.19,93.00"]=true,
 ["TunnelHillEarth@-73.00,33.88,93.00"]=true,
 ["TunnelHillEarth@-67.00,34.06,93.00"]=true,
 ["TunnelHillEarth@-61.00,33.55,93.00"]=true,
 ["TunnelHillEarth@-85.00,32.91,87.00"]=true,
 ["TunnelHillEarth@-79.00,33.93,87.00"]=true,
 ["TunnelHillEarth@-73.00,34.53,87.00"]=true,
 ["TunnelHillEarth@-67.00,34.50,87.00"]=true,
 ["TunnelHillEarth@-61.00,33.86,87.00"]=true,
 ["TunnelHillEarth@-55.00,32.81,87.00"]=true,
 ["TunnelHillEarth@-49.00,19.09,87.00"]=true,
 ["TunnelHillEarth@-43.00,17.02,87.00"]=true,
 ["TunnelHillEarth@-37.00,14.52,87.00"]=true,
 ["TunnelHillEarth@-91.00,20.09,81.00"]=true,
 ["TunnelHillEarth@-85.00,33.63,81.00"]=true,
 ["TunnelHillEarth@-79.00,34.58,81.00"]=true,
 ["TunnelHillEarth@-73.00,35.10,81.00"]=true,
 ["TunnelHillEarth@-67.00,34.85,81.00"]=true,
 ["TunnelHillEarth@-61.00,34.08,81.00"]=true,
 ["TunnelHillEarth@-97.00,18.95,75.00"]=true,
 ["TunnelHillEarth@-79.00,35.15,75.00"]=true,
 ["TunnelHillEarth@-73.00,35.59,75.00"]=true,
 ["TunnelHillEarth@-67.00,35.12,75.00"]=true,
 ["TunnelHillEarth@-103.00,17.81,63.00"]=true,
 ["TunnelHillEarth@-79.00,36.07,63.00"]=true,
 ["TunnelHillEarth@-103.00,30.42,57.00"]=true,
 ["TunnelHillEarth@-85.00,35.70,57.00"]=true,
 ["TunnelHillEarth@-79.00,36.41,57.00"]=true,
 ["TunnelHillEarth@-109.00,15.37,51.00"]=true,
 ["TunnelHillEarth@-103.00,30.49,51.00"]=true,
 ["TunnelHillEarth@-97.00,32.90,51.00"]=true,
 ["TunnelHillEarth@-91.00,34.76,51.00"]=true,
 ["TunnelHillEarth@-85.00,36.00,51.00"]=true,
 ["TunnelHillEarth@-109.00,14.98,45.00"]=true,
 ["TunnelHillEarth@-103.00,30.22,45.00"]=true,
 ["TunnelHillEarth@-97.00,32.73,45.00"]=true,
 ["TunnelHillEarth@-91.00,34.67,45.00"]=true,
 ["TunnelHillEarth@-85.00,36.03,45.00"]=true,
 ["TunnelHillEarth@-109.00,26.78,39.00"]=true,
 ["TunnelHillEarth@-103.00,29.94,39.00"]=true,
 ["TunnelHillEarth@-97.00,32.53,39.00"]=true,
 ["TunnelHillEarth@-91.00,34.53,39.00"]=true,
 ["TunnelHillEarth@-115.00,10.57,33.00"]=true,
 ["TunnelHillEarth@-109.00,26.49,33.00"]=true,
 ["TunnelHillEarth@-103.00,29.69,33.00"]=true,
 ["TunnelHillEarth@-97.00,32.32,33.00"]=true,
 ["TunnelHillEarth@-115.00,10.37,27.00"]=true,
 ["TunnelHillEarth@-109.00,26.28,27.00"]=true,
 ["TunnelHillEarth@-103.00,29.48,27.00"]=true,
 ["TunnelHillEarth@-97.00,32.11,27.00"]=true,
 ["TunnelHillEarth@-115.00,10.30,21.00"]=true,
 ["TunnelHillEarth@-109.00,26.16,21.00"]=true,
 ["TunnelHillEarth@-103.00,29.31,21.00"]=true,
 ["TunnelHillEarth@-115.00,10.30,15.00"]=true,
 ["TunnelHillEarth@-109.00,26.10,15.00"]=true,
 ["TunnelHillEarth@-115.00,10.34,9.00"]=true,
 ["TunnelHillEarth@-109.00,26.09,9.00"]=true,
 ["TunnelHillEarth@-115.00,10.45,3.00"]=true,
 ["SolidMountainStone@-86.00,-19.14,86.00"]=true,
 ["SolidMountainStone@-54.00,-25.50,74.00"]=true,
 ["TunnelRockCourse@-53.00,2.80,72.25"]=true,
 ["TunnelRockCourse@-52.77,10.12,71.75"]=true,
 ["TunnelRockCourse@-53.23,18.44,71.75"]=true,
 ["TunnelRockCourse@-58.23,3.30,59.75"]=true,
 ["TunnelRockCourse@-58.00,9.62,60.00"]=true,
 ["TunnelRockCourse@-57.77,16.94,60.25"]=true,
 ["TunnelRockCourse@-58.23,25.26,60.25"]=true,
 ["TunnelInnerRockFacet@-85.00,3.65,37.40"]=true,
 ["TunnelInnerRockFacet@-85.28,11.45,36.60"]=true,
 ["TunnelInnerRockFacet@-84.72,18.55,37.40"]=true,
 ["TunnelInnerRockFacet@-85.00,24.95,36.60"]=true,
 ["TunnelInnerRockFacet@-85.00,11.10,32.40"]=true,
 ["TunnelInnerRockFacet@-85.28,17.50,31.60"]=true,
 ["TunnelInnerRockFacet@-84.72,24.60,32.40"]=true,
 ["TunnelInnerRockFacet@-84.72,9.35,27.00"]=true,
 ["TunnelInnerRockFacet@-85.00,16.45,27.40"]=true,
 ["TunnelInnerRockFacet@-85.28,24.25,26.60"]=true,
 ["TunnelHillEarth@-91.00,32.91,75.00"]=true,
 ["TunnelHillEarth@-85.00,34.26,75.00"]=true,
 ["TunnelHillEarth@-49.00,18.53,75.00"]=true,
 ["TunnelHillEarth@-97.00,31.70,69.00"]=true,
 ["TunnelHillEarth@-91.00,33.49,69.00"]=true,
 ["TunnelHillEarth@-85.00,34.81,69.00"]=true,
 ["TunnelHillEarth@-79.00,35.65,69.00"]=true,
 ["TunnelHillEarth@-73.00,35.89,69.00"]=true,
 ["TunnelHillEarth@-67.00,35.30,69.00"]=true,
 ["TunnelHillEarth@-61.00,34.18,69.00"]=true,
 ["TunnelHillEarth@-55.00,32.46,69.00"]=true,
 ["TunnelHillEarth@-97.00,32.23,63.00"]=true,
 ["TunnelHillEarth@-91.00,34.01,63.00"]=true,
 ["TunnelHillEarth@-85.00,35.29,63.00"]=true,
 ["TunnelHillEarth@-73.00,36.12,63.00"]=true,
 ["TunnelHillEarth@-55.00,20.00,63.00"]=true,
 ["TunnelHillEarth@-97.00,32.70,57.00"]=true,
 ["TunnelHillEarth@-91.00,34.46,57.00"]=true,
 ["TunnelHillEarth@-73.00,36.27,57.00"]=true,
 ["TunnelHillEarth@-61.00,21.76,57.00"]=true,
 ["TunnelHillEarth@-79.00,36.67,51.00"]=true,
 ["TunnelHillEarth@-73.00,36.38,51.00"]=true,
 ["TunnelHillEarth@-85.00,35.96,39.00"]=true,
 ["TunnelHillEarth@-79.00,36.82,39.00"]=true,
 ["TunnelHillEarth@-91.00,34.37,33.00"]=true,
 ["TunnelHillEarth@-85.00,35.85,33.00"]=true,
 ["TunnelHillEarth@-79.00,36.75,33.00"]=true,
 ["TunnelHillEarth@-91.00,34.18,27.00"]=true,
 ["TunnelHillEarth@-85.00,35.69,27.00"]=true,
 ["TunnelHillEarth@-97.00,31.92,21.00"]=true,
 ["TunnelHillEarth@-103.00,29.19,15.00"]=true,
 ["TunnelHillEarth@-97.00,31.74,15.00"]=true,
 ["TunnelHillEarth@-103.00,29.08,9.00"]=true,
 ["TunnelHillEarth@-109.00,26.09,3.00"]=true,
 ["TunnelHillEarth@-103.00,28.99,3.00"]=true,
 ["TunnelHillEarth@-115.00,10.60,-3.00"]=true,
 ["TunnelHillEarth@-109.00,13.95,-9.00"]=true,
}
local function r2Key(p) local v=p.CFrame.Position;return p.Name..string.format("@%.2f,%.2f,%.2f",v.X,v.Y,v.Z) end
local groundModule=require(script.Parent.Section1)
S.ground=groundModule.ground
local wood={132,82,40};local leaf={71,139,46}
local function safe(name,fn)
 local ok,err=pcall(fn);if not ok then warn('[Section2] '..name..' skipped: '..tostring(err)) end
end
local function part(root,name,pos,size,color,material)
 local p=Instance.new('Part');p.Name='S2_'..name;p.Size=size;p.CFrame=CFrame.new(pos)
 p.Color=Color3.fromRGB(unpack(color));p.Material=material or Enum.Material.Wood
 p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false
 p:SetAttribute('Section','S2');p:SetAttribute('Cosmetic',true);p.Parent=root;return p
end
local function foot(root,name,x,z,size,color,material)
 local y=assert(S.ground(root,x,z,size.X,size.Z),'unsupported '..name)
 local p=part(root,name,V(x,y+size.Y/2,z),size,color,material);p:SetAttribute('SupportY',y);return p
end
local function rod(root,name,a,b,width,color)
 local p=part(root,name,(a+b)/2,V(width,width,(b-a).Magnitude),color)
 local up=if math.abs((b-a).Unit.Y)>.95 then V(1,0,0) else V(0,1,0)
 local back=(a-b).Unit;local right=up:Cross(back).Unit;up=back:Cross(right)
 local mid=(a+b)/2
 p.CFrame=CFrame.new(mid.X,mid.Y,mid.Z,right.X,up.X,back.X,right.Y,up.Y,back.Y,right.Z,up.Z,back.Z);return p
end
local function lantern(root,pos,normal,reach)
 reach=reach or 1.1
 local scale=if pos.Z>=88 then 1.2 else 1.35
 local bracket=rod(root,'LampBracket',pos,pos+normal*reach,.22,wood)
 local c=pos+normal*reach-V(0,1.1,0)
 part(root,'LampBase',c-V(0,.75*scale,0),V(1.3,.2,1.3)*scale,{53,47,37},Enum.Material.Metal)
 local core=part(root,'LampGlass',c,V(.85,1.3,.85)*scale,{255,193,91},Enum.Material.Neon)
 part(root,'LampRoof',c+V(0,.75*scale,0),V(1.3,.2,1.3)*scale,{53,47,37},Enum.Material.Metal)
 for _,dx in {-.55,.55} do for _,dz in {-.55,.55} do part(root,'LampIron',c+V(dx*scale,0,dz*scale),V(.12,1.3,.12)*scale,{53,47,37},Enum.Material.Metal) end end
 rod(root,'LampHanger',pos+normal*reach,c+V(0,.85*scale,0),.16,{53,47,37})
 local l=Instance.new('PointLight');l.Color=core.Color;l.Brightness=if pos.Z>=88 then 12 else 6;l.Range=28;l.Shadows=true;l.Parent=core
end
local function mine(root)
 -- Face-mounted timbers: low grounded posts would overlap the authoritative bait lane.
 -- Skin backs touch exposed solid cliff sides; they do not enter earth or cap voids.
 local a,b=V(-75.2,10.75,99),V(-52.7,10.75,88)
 part(root,'MineWestTimber',a,V(1.2,5.5,6),wood)
 part(root,'MineEastTimber',b,V(1.2,5.5,6),wood)
 -- Visible corbel footings: wall-mounted to keep the entire bait-lane envelope clear.
 for _,q in {{a,1},{b,-1}} do
  part(root,'MineStoneFooting',V(q[1].X,7.75,q[1].Z),V(1.2,.5,6.4),{137,125,107},Enum.Material.Slate)
  part(root,'MinePostBase',V(q[1].X,8.2,q[1].Z),V(1.22,.4,6.2),{80,59,37})
  for _,dz in {-1.7,0,1.7} do
   part(root,'MinePostGrain',V(q[1].X+q[2]*.612,10.8,q[1].Z+dz),V(.025,4.8,.075),{103,65,33})
  end
 end
 -- Three brackets tie each facing back to the actual rock courses.
 for _,pair in {{a,1},{b,-1}} do local q,side=pair[1],pair[2];for _,y in {10,11.5,13} do
  local distance=math.huge
  for _,p in root:GetDescendants() do if p:IsA('BasePart') and p.CanCollide then
   local c,h=p.CFrame,p.Size/2;local localRay=c:PointToObjectSpace(V(q.X+side*3,y,q.Z));local dir=c:VectorToObjectSpace(V(-side,0,0))
   local enter,leave=0,200
   for _,axis in {'X','Y','Z'} do
    if math.abs(dir[axis])<.00001 then if math.abs(localRay[axis])>h[axis] then enter=201 end
    else local u=(-h[axis]-localRay[axis])/dir[axis];local v=(h[axis]-localRay[axis])/dir[axis];enter=math.max(enter,math.min(u,v));leave=math.min(leave,math.max(u,v)) end
   end
   if enter<=leave then distance=math.min(distance,enter) end
  end end
  assert(distance<math.huge,'timber wall support')
  rod(root,'WallBracket',V(q.X+side*(3-distance),y,q.Z),V(q.X-side*.6,y,q.Z),.22,{87,62,37})
 end end
 local topA,topB=V(a.X,12.5,a.Z),V(b.X,12.5,b.Z)
 local header=rod(root,'MineHeader',topA,topB,1.25,wood)
 header.Size=V(1.4,3,(topB-topA).Magnitude)
 -- Header meets both skins; steel bolt plates sit on their visible faces.
 for _,q in {{a,1},{b,-1}} do
  for _,y in {10,11.5,13} do
   part(root,'TimberBolt',V(q[1].X+q[2]*.63,y,q[1].Z),V(.06,.42,.42),{74,74,66},Enum.Material.Metal)
  end
  lantern(root,V(q[1].X+q[2]*.6,10.6,q[1].Z),V(q[2],0,0))
 end
 local mid=(topA+topB)/2
 -- Entire board clears the header bottom (Y11), including player-camera parallax.
 local board=part(root,'ShortcutBoard',mid-V(0,2.5,0),V(9,1.25,.35),{157,102,50})
 local u=(topB-topA).Unit;local n=u:Cross(V(0,1,0))
 for _,q in {{a,1},{b,-1}} do
  local lower=q[1]+u*(q[2]*.6)-V(0,.9,0)
  local upper=q[1]+u*(q[2]*4.2)+V(0,1.35,0)
  rod(root,'MineKneeBrace',lower,upper,.9,wood)
 end
 board.CFrame=CFrame.new(board.CFrame.Position.X,board.CFrame.Position.Y,board.CFrame.Position.Z,u.X,0,n.X,0,1,0,u.Z,0,n.Z)
 board.CFrame=CFrame.new(n*1.0)*board.CFrame
 -- Two hangers connect physical board to header, no floating label.
 for _,dx in {-3,3} do rod(root,'SignHanger',board.CFrame.Position+u*dx+V(0,.625,0),mid+u*dx-V(0,.9,0),.12,{62,55,42}) end
 board:SetAttribute('RouteLabel','SHORTCUT')
 local gui=Instance.new('SurfaceGui');gui.Face=Enum.NormalId.Back;gui.PixelsPerStud=64;gui.LightInfluence=.15;gui.Parent=board
 local label=Instance.new('TextLabel');label.Position=UDim2.fromScale(.05,.1);label.Size=UDim2.fromScale(.9,.8);label.BackgroundTransparency=1;label.Text='SHORTCUT';label.Parent=gui
 require(game:GetService('ReplicatedStorage').UIStyle).lettering(label,60,12)
 -- Three foliage chains on each actual side-wall face; all bases >=8 studs.
 for _,q in {{a,1},{b,-1}} do for _,j in {-2.5,2.5} do
  local x=q[1].X+q[2]*.66;local z=q[1].Z+j*1.1;local low=8.2+math.abs(j)*.2
  rod(root,'CliffRoot',V(x,low,z),V(x,13.3,z),.18,{94,72,39})
  for i=0,5 do
   local p=part(root,'IvyLeaf',V(x+q[2]*.12,low+i*.9,z+(i%2-.5)*.3),V(.18,.8,.7),{59,115+(i%3)*9,39},Enum.Material.Grass);p.Shape=Enum.PartType.Ball
  end
 end end
 -- Runtime shafts: real Beam attachments; offline renderer labels its planar proxy.
 for j=0,1 do
  local base=part(root,'ShaftAnchor',V(a.X+.61,12+j*.5,a.Z),V(.05,.05,.05),leaf);base.Transparency=1
  local a0=Instance.new('Attachment');a0.Position=Vector3.zero;a0.Parent=base
  local a1=Instance.new('Attachment');a1.Position=V(2,-3,4);a1.Parent=base
  local beam=Instance.new('Beam');beam.Attachment0=a0;beam.Attachment1=a1;beam.Width0=.1;beam.Width1=2;beam.FaceCamera=true;beam.LightEmission=.5
  beam.Transparency=NumberSequence.new(.92);beam.Color=ColorSequence.new(Color3.fromRGB(255,248,215));beam.Parent=base
 end
end
local function orchard(root,x,z,w,h,index)
 local y=assert(S.ground(root,x,z,w,w),'orchard full footprint')
 part(root,'OrchardTrunk',V(x,y+h*.31,z),V(.65,h*.62,.65),wood)
 local cy=y+h*.7
 for _,q in {{0,0,0,w},{-.17,.1,.09,w*.72},{.18,-.12,-.1,w*.68}} do
  local crown=part(root,'OrchardCrown',V(x+q[1]*w,cy+q[2]*h,z+q[3]*w),V(q[4],h*.5,q[4]),{65+index*6,142+index*4,44},Enum.Material.Grass);crown.Shape=Enum.PartType.Ball
 end
 for i=0,3 do
  local theta=i*math.pi/2+.4;local fx=x+math.sin(theta)*w*.4;local fz=z+math.cos(theta)*w*.4;local fy=cy+(i%2-.5)*h*.12
  local fruit=part(root,'OrchardApple',V(fx,fy,fz),V(.65,.7,.65),{192+index*9,49,36},Enum.Material.SmoothPlastic);fruit.Shape=Enum.PartType.Ball
  part(root,'AppleStem',V(fx,fy+.4,fz),V(.09,.14,.09),wood)
 end
end
S.kits={
 {id='HarvestBarrel',name='kenney_mini-dungeon__barrel',x=-65,z=119,size=V(2.2,3.4,2.2),fit=true},
 {id='HarvestCrate',name='kenney_survival-kit__box',x=-62,z=122,size=V(2,2,2)},
 {id='OrchardRockA',name='quaternius-nature__Rock_Medium_1',x=-74,z=120,size=V(2,1.7,2)},
 {id='OrchardRockB',name='quaternius-nature__Rock_Medium_1',x=-72,z=120,size=V(1.3,1.1,1.3)},
 {id='OrchardRockC',name='quaternius-nature__Rock_Medium_1',x=-69,z=118,size=V(1.7,1.3,1.7)},
}
-- R3: tangent kits2 rock clusters, each 3-7 varied rocks; generated from unchanged solid faces.
table.insert(S.kits,{id='RockCluster1_1',name='quaternius-nature__Rock_Medium_1',x=-68.1020,y=2.0000,z=113.0000,size=V(1.6380,3.8220,4.1860),fit=true,attachment='S2_RockAnchor1_1',color={95,91,83}})
table.insert(S.kits,{id='RockCluster1_2',name='quaternius-nature__Rock_Medium_1',x=-68.0210,y=5.0000,z=111.6000,size=V(1.8000,4.2000,4.6000),fit=true,attachment='S2_RockAnchor1_2',color={112,105,94}})
table.insert(S.kits,{id='RockCluster1_3',name='quaternius-nature__Rock_Medium_1',x=-68.1020,y=8.0000,z=114.3000,size=V(1.6380,3.8220,4.1860),fit=true,attachment='S2_RockAnchor1_3',color={137,125,107}})
table.insert(S.kits,{id='RockCluster2_1',name='quaternius-nature__Rock_Medium_1',x=-73.0000,y=2.0000,z=117.8980,size=V(4.1860,3.8220,1.6380),fit=true,attachment='S2_RockAnchor2_1',color={112,105,94}})
table.insert(S.kits,{id='RockCluster2_2',name='quaternius-nature__Rock_Medium_1',x=-74.4000,y=5.0000,z=117.6790,size=V(3.2000,3.2000,1.2000),fit=true,attachment='S2_RockAnchor2_2',color={137,125,107}})
table.insert(S.kits,{id='RockCluster2_3',name='quaternius-nature__Rock_Medium_1',x=-71.7000,y=8.0000,z=117.8980,size=V(4.1860,3.8220,1.6380),fit=true,attachment='S2_RockAnchor2_3',color={95,91,83}})
table.insert(S.kits,{id='RockCluster3_1',name='quaternius-nature__Rock_Medium_1',x=-75.7043,y=8.0000,z=118.3000,size=V(0.5915,2.9120,1.8200),fit=true,attachment='S2_RockAnchor3_1',color={137,125,107}})
table.insert(S.kits,{id='RockCluster3_2',name='quaternius-nature__Rock_Medium_1',x=-75.1000,y=11.0000,z=116.0000,size=V(1.8000,4.2000,4.6000),fit=true,attachment='S2_RockAnchor3_2',color={95,91,83}})
table.insert(S.kits,{id='RockCluster3_3',name='quaternius-nature__Rock_Medium_1',x=-75.1810,y=14.0000,z=118.0000,size=V(1.6380,3.8220,4.1860),fit=true,attachment='S2_RockAnchor3_3',color={112,105,94}})
table.insert(S.kits,{id='RockCluster4_1',name='quaternius-nature__Rock_Medium_1',x=-80.4000,y=5.0000,z=120.9000,size=V(4.6000,4.2000,1.8000),fit=true,attachment='S2_RockAnchor4_1',color={95,91,83}})
table.insert(S.kits,{id='RockCluster4_2',name='quaternius-nature__Rock_Medium_1',x=-77.7000,y=8.0000,z=120.8190,size=V(4.1860,3.8220,1.6380),fit=true,attachment='S2_RockAnchor4_2',color={112,105,94}})
table.insert(S.kits,{id='RockCluster4_3',name='quaternius-nature__Rock_Medium_1',x=-80.0000,y=11.0000,z=120.3250,size=V(2.0000,3.2000,0.6500),fit=true,attachment='S2_RockAnchor4_3',color={137,125,107}})
table.insert(S.kits,{id='RockCluster5_1',name='quaternius-nature__Rock_Medium_1',x=-81.1810,y=2.0000,z=93.0000,size=V(1.6380,3.8220,4.1860),fit=true,attachment='S2_RockAnchor5_1',color={112,105,94}})
table.insert(S.kits,{id='RockCluster5_2',name='quaternius-nature__Rock_Medium_1',x=-81.4000,y=5.0000,z=91.6000,size=V(1.2000,3.2000,3.2000),fit=true,attachment='S2_RockAnchor5_2',color={137,125,107}})
table.insert(S.kits,{id='RockCluster5_3',name='quaternius-nature__Rock_Medium_1',x=-81.4540,y=8.0000,z=94.3000,size=V(1.0920,2.9120,2.9120),fit=true,attachment='S2_RockAnchor5_3',color={95,91,83}})
table.insert(S.kits,{id='RockCluster5_4',name='quaternius-nature__Rock_Medium_1',x=-81.4000,y=11.0000,z=92.0000,size=V(1.2000,3.2000,3.2000),fit=true,attachment='S2_RockAnchor5_4',color={112,105,94}})
table.insert(S.kits,{id='RockCluster5_5',name='quaternius-nature__Rock_Medium_1',x=-81.4540,y=14.0000,z=94.0000,size=V(1.0920,2.9120,2.9120),fit=true,attachment='S2_RockAnchor5_5',color={137,125,107}})
table.insert(S.kits,{id='RockCluster5_6',name='quaternius-nature__Rock_Medium_1',x=-81.4000,y=17.0000,z=91.7000,size=V(1.2000,3.2000,3.2000),fit=true,attachment='S2_RockAnchor5_6',color={95,91,83}})
table.insert(S.kits,{id='RockCluster5_7',name='quaternius-nature__Rock_Medium_1',x=-81.4540,y=20.0000,z=94.2000,size=V(1.0920,2.9120,2.9120),fit=true,attachment='S2_RockAnchor5_7',color={112,105,94}})
table.insert(S.kits,{id='RockCluster6_1',name='quaternius-nature__Rock_Medium_1',x=-52.5460,y=8.0000,z=76.3000,size=V(1.0920,2.9120,2.9120),fit=true,attachment='S2_RockAnchor6_1',color={137,125,107}})
table.insert(S.kits,{id='RockCluster6_2',name='quaternius-nature__Rock_Medium_1',x=-52.5460,y=14.0000,z=76.0000,size=V(1.0920,2.9120,2.9120),fit=true,attachment='S2_RockAnchor6_2',color={95,91,83}})
table.insert(S.kits,{id='RockCluster6_3',name='quaternius-nature__Rock_Medium_1',x=-52.5460,y=20.0000,z=76.2000,size=V(1.0920,2.9120,2.9120),fit=true,attachment='S2_RockAnchor6_3',color={112,105,94}})
table.insert(S.kits,{id='RockCluster7_1',name='quaternius-nature__Rock_Medium_1',x=-56.4000,y=5.0000,z=66.3250,size=V(2.0000,3.2000,0.6500),fit=true,attachment='S2_RockAnchor7_1',color={95,91,83}})
table.insert(S.kits,{id='RockCluster7_2',name='quaternius-nature__Rock_Medium_1',x=-56.0000,y=11.0000,z=66.3250,size=V(2.0000,3.2000,0.6500),fit=true,attachment='S2_RockAnchor7_2',color={112,105,94}})
table.insert(S.kits,{id='RockCluster7_3',name='quaternius-nature__Rock_Medium_1',x=-56.3000,y=17.0000,z=66.3250,size=V(2.0000,3.2000,0.6500),fit=true,attachment='S2_RockAnchor7_3',color={137,125,107}})
-- Close-out: remove the detached upper stacks beside the old cue and inside the
-- right mouth. Retain the contiguous lower wall cladding and orchard rocks.
for i=#S.kits,1,-1 do
 local id=S.kits[i].id
 if id:match('^RockCluster[3467]_') then table.remove(S.kits,i) end
end
S.ground=function(root,x,z,w,d)
 for _,g in S.kits do if g.y and math.abs(g.x-x)<.001 and math.abs(g.z-z)<.001 and math.abs(g.size.X-w)<.001 then return g.y end end
 return groundModule.ground(root,x,z,w,d)
end
function S.build(root)
 for _,p in root:GetDescendants() do if p:IsA('BasePart') then
  local key=r2Key(p)
  if r2Remove[key] and not p.CanCollide and not p:GetAttribute('WalkableLaneFloor') and not p:GetAttribute('GameplayCover') then p:Destroy()
  elseif r2Stone[key] and p.CanCollide and not p:GetAttribute('WalkableLaneFloor') then
   local v=p.CFrame.Position
   local tone=(math.floor(v.X/6)+math.floor(v.Z/6)+math.floor(v.Y/7))%3
   local palette={{112,105,94},{137,125,107},{95,91,83}}
   p.Color=Color3.fromRGB(unpack(palette[tone+1]));p.Material=if tone==1 then Enum.Material.Slate else Enum.Material.Rock
  end
 end end
 -- Remove complete revealed crystal/voxel clumps, including pieces hidden by the first ray-visible slice.
 for _,p in root:GetDescendants() do if p:IsA('BasePart') and not p.CanCollide and not p:GetAttribute('WalkableLaneFloor') and not p:GetAttribute('GameplayCover') then
  local v=p.CFrame.Position
  if v.X>=-120 and v.X<=-40 and v.Z>=0 and v.Z<=112 and v.Y<28 then
   if p.Name:find('Crystal') or p.Name:find('^TunnelExitArchShoulderVoxel') then p:Destroy()
   elseif p.Name=='GrassShoulder' or p.Name=='WindingCobble' or p.Name:find('^TunnelDirtStoneVoxel') then
    p.Color=Color3.fromRGB(151,119,77);p.Material=Enum.Material.Ground
   elseif p.Name:find('^TunnelMushroomGlowVoxel') or p.Name=='Fix1MushroomSpot' then
    p.Color=Color3.fromRGB(161,129,79);p.Material=Enum.Material.Rock
    for _,light in p:GetChildren() do if light:IsA('PointLight') then light.Color=p.Color;light.Brightness=.5 end end
   end
  end
 end end
 -- Dirt/stone transition uses existing cosmetic paving only: no new floor thickness or queries.
 for _,p in root:GetDescendants() do if p:IsA('BasePart') and not p.CanCollide and not p:GetAttribute('WalkableLaneFloor') and not p:GetAttribute('GameplayCover') then
  local v=p.CFrame.Position
  if v.X>=-80 and v.X<=-40 and v.Z>=102 and v.Z<=122 and (p.Name=='WindingCobble' or p.Name=='TunnelValleyJoin_Cobble') then
   local t=math.clamp((v.Z-102)/20,0,1);local wear=(math.floor(v.X)+math.floor(v.Z))%3*5
   p.Color=Color3.fromRGB(151+38*t+wear,122+28*t+wear,85+21*t+wear);p.Material=Enum.Material.Ground
  end
 end end
 for _,g in S.kits do if g.y then
  local anchor=part(root,g.attachment:sub(4),V(g.x,g.y+g.size.Y/2,g.z),g.size,g.color,Enum.Material.Rock);anchor.Transparency=1
 end end
 -- Superseded nonphysical S1 trim lies entirely in S2, below the new header.
 -- Remove only the old elevated pebble columns and their cap/moss pieces.
 for _,p in root:GetDescendants() do if p:IsA('BasePart') and not p.CanCollide and not p.CanQuery and not p.CanTouch
  and not p:GetAttribute('WalkableLaneFloor') and not p:GetAttribute('GameplayCover') then
  local v=p.CFrame.Position
  if v.X>=-120 and v.X<=-28 and v.Z>=75 and v.Z<=140 and v.Y>1
   and (p.Name=='Round4StackedRock' or p.Name=='Round4PaleRockTop' or p.Name=='Round4RockMoss') then p:Destroy() end
 end end
 -- Explicit names + physics/tag guards preserve the bait cover, every lane and court.
 for _,p in root:GetDescendants() do if p:IsA('BasePart') and not p.CanCollide and not p:GetAttribute('WalkableLaneFloor') and not p:GetAttribute('GameplayCover') then
  local v=p.CFrame.Position
  if p.Name:find('^TunnelExitArchShoulderVoxel') and v.X< -58 and v.X>=-120 and v.Z>=96 and v.Z<=102 and v.Y<28 then p:Destroy();continue end
  if p.Name=='S1_MineHeader' or p.Name=='S1_MinePost' or p.Name=='S1_MineLanternGlow' or p.Name=='S1_MineLanternCap' then p:Destroy() end
 end end
 safe('mine mouth',function() mine(root) end)
 safe('shoulder root trails',function()
  -- Attach to the continuous front face of the protected east shoulder, above headroom.
  -- Its solid remains unchanged; these roots have no collision, touch or query participation.
  for j,x in {-51.3,-49.5,-47.7} do
   local low=8.2+(j%2)*1.2
   rod(root,'ShoulderRoot',V(x,low,90.14),V(x+.25,22,90.14),.26,{91,74,49})
   for i=0,11 do
    local y=low+i*.9;local dx=if i%2==0 then -.28 else .28
    local p=part(root,'ShoulderIvy',V(x+dx,y,90.16),V(.75,1.1,.22),{66,115+(i%3)*8,42},Enum.Material.Grass)
    p.Shape=Enum.PartType.Ball
   end
  end
 end)
 safe('lit tunnel',function()
  -- Pairs on real wall faces, twelve studs apart. Cosmetic lights do not enter Keeper policy.
  for z=78,30,-16 do
   local wallZ=if z==30 then 32 else z
   local x=if z>=54 then -76+(z-54)*16/28 else -76
   for _,side in {-1,1} do
    local nearest=math.huge
    for _,p in root:GetDescendants() do if p:IsA('BasePart') and p.CanCollide and not p:GetAttribute('WalkableLaneFloor') then
     local h=p.Size/2;local o=p.CFrame:PointToObjectSpace(V(x,11.7,wallZ));local d=p.CFrame:VectorToObjectSpace(V(side,0,0));local enter,leave=0,100
     for _,axis in {'X','Y','Z'} do
      if math.abs(d[axis])<.00001 then if math.abs(o[axis])>h[axis] then enter=101 end
      else local a=(-h[axis]-o[axis])/d[axis];local b=(h[axis]-o[axis])/d[axis];enter=math.max(enter,math.min(a,b));leave=math.min(leave,math.max(a,b)) end
     end
     if enter<=leave then nearest=math.min(nearest,enter) end
    end end
    assert(nearest<40 and nearest>1,'tunnel wall face')
    lantern(root,V(x+side*nearest,11.7,wallZ),V(-side,0,0))
   end
  end
  -- End-wall sunlight cue; face-mounted, above the protected walking envelope.
  local glow=part(root,'RouteEndGlow',V(-111.949,6,18),V(.1,7,6),{255,221,142},Enum.Material.Neon)
  local light=Instance.new('PointLight');light.Color=glow.Color;light.Brightness=36;light.Range=40;light.Parent=glow
 end)
 for i,t in {{-71,122,5,17},{-64.5,122,5.5,18},{-60,124,2.5,10}} do safe('orchard '..i,function() orchard(root,t[1],t[2],t[3],t[4],i) end) end
 safe('harvest shovel',function()
  local p=foot(root,'ShovelBlade',-65,121,V(.7,.9,.2),{139,151,151},Enum.Material.Metal)
  local y=p.CFrame.Position.Y+.45
  part(root,'ShovelHandle',V(-65,y+1,121),V(.15,2,.15),wood)
  part(root,'ShovelGrip',V(-65,y+2.1,121),V(.6,.2,.2),wood)
 end)
end
function S.spawnKits(root,kit)
 local origin=root:GetAttribute('MeadowOrigin') or Vector3.zero
 for _,g in S.kits do safe(g.id,function()
  local y=assert(S.ground(root,g.x,g.z,g.size.X,g.size.Z),'unsupported kit')
  local frame=CFrame.new(origin+V(g.x,y,g.z));local m=kit.spawn(g.name,g.island or 'meadow',frame,g.size)
  if m then
   if g.fit then assert(kit.fit(m,g.size,frame)) end
   m.Name='S2_'..g.id;m:SetAttribute('Section','S2');m.Parent=root
   for _,p in m:GetDescendants() do if p:IsA('BasePart') then p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p:SetAttribute('Section','S2') end end
   if g.color then for _,p in m:GetDescendants() do if p:IsA('BasePart') then p.Color=Color3.fromRGB(unpack(g.color));p.Material=Enum.Material.Rock end end end
  end
 end) end
end
return S
