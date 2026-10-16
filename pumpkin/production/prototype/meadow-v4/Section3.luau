-- S3: local-coordinate cosmetic architecture; existing MeadowV4 pcall guard owns failures.

-- Bound synchronous construction/scans; offline builders have no task.
local yieldWork = 0
local yieldDeadline = os.clock() + .01
local function yieldBuild()
 yieldWork += 1
 if yieldWork % 300 == 0 and os.clock() >= yieldDeadline then
  if task then task.wait() end
  yieldDeadline = os.clock() + .01
 end
end
-- R4 final constrained dressing over frozen R2 arches. No gameplay changes.
local S={}
local V=Vector3.new
local function part(root,name,frame,size,color,material)
 yieldBuild()
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
 local l=Instance.new('PointLight');l.Color=Color3.fromRGB(255,190,112);l.Brightness=(brightness or 3)*.3;l.Range=16 -- Live Studio tuning: offline values washed the tunnel out.;l.Shadows=false;l.Parent=p
 return p
end
local function cage(root,name,x,y,z)
 local iron={48,44,39}
 -- An open lower rail lets the existing point source illuminate the track.
 for _,s in {-1,1} do part(root,name..'Cap'..s,CFrame.new(x,y+s*.5,z),V(1.1,.2,if s<0 then .14 else 1.1),iron,Enum.Material.Metal) end
 for _,sx in {-1,1} do for _,sz in {-1,1} do
  part(root,name..'Bar'..sx..'_'..sz,CFrame.new(x+sx*.5,y,z+sz*.5),V(.1,.8,.1),iron,Enum.Material.Metal)
 end end
end
local function labelBoard(board,text)
 board:SetAttribute('RouteLabel',text);board:SetAttribute('LabelFace','Front');board:SetAttribute('LabelY',.55);board:SetAttribute('LabelSize',.6)
 local gui=Instance.new('SurfaceGui');gui.Face=Enum.NormalId.Front;gui.PixelsPerStud=64;gui.LightInfluence=.15;gui.Parent=board
 local label=Instance.new('TextLabel');label.Position=UDim2.fromScale(.05,.08);label.Size=UDim2.fromScale(.9,.30);label.BackgroundTransparency=1;label.Text=text;label.Parent=gui
 require(game:GetService('ReplicatedStorage').UIStyle).lettering(label,36,12)
end
local function wayboard(root,name,x,z,right,exitId)
 local wood={91,59,35};local ink={244,224,166};local y=11.6
 part(root,name..'Hanger',CFrame.new(x,18.35,z),V(.16,11.3,.16),{53,47,39},Enum.Material.Metal)
 local board=part(root,name..'Board',CFrame.new(x,y,z),V(3,2.2,.2),wood);labelBoard(board,'EXIT '..exitId)
 y=11.25
 local f=z-.15
 if right then
  beam(root,name..'Stem',V(x-.6,y,f),V(x+.6,y,f),.16,.16,ink)
  beam(root,name..'TipA',V(x+.6,y,f),V(x+.2,y+.38,f),.16,.16,ink)
  beam(root,name..'TipB',V(x+.6,y,f),V(x+.2,y-.38,f),.16,.16,ink)
 else
  beam(root,name..'Stem',V(x,y-.5,f),V(x,y+.5,f),.16,.16,ink)
  beam(root,name..'TipA',V(x,y+.5,f),V(x-.4,y+.1,f),.16,.16,ink)
  beam(root,name..'TipB',V(x,y+.5,f),V(x+.4,y+.1,f),.16,.16,ink)
 end
end
function S.build(root)
 -- Old hanging silhouettes compete with the shoring, but never touch protected parts or path stones.
 local remove={TunnelStalactite=true,TunnelArchedRockRib=true,TunnelWallRoot=true,TunnelWallMoss=true}
 for _,p in root:GetDescendants() do yieldBuild(); if p:IsA('BasePart') and remove[p.Name] and not p.CanCollide and not p.CanQuery and not p.CanTouch and not p:GetAttribute('WalkableLaneFloor') and #p:GetTags()==0 then
  local v=p.CFrame.Position;if v.X>=-90 and v.X<=-63 and v.Z>=-22 and v.Z<=70 and v.Y>=8 and v.Y<=28 then p:Destroy() end
 end end
 for i=0,7 do
  local z=-11+i*11;local brown={111,73,43}
  part(root,'RibHeader'..i,CFrame.new(-76,23.4,z),V(14,1.2,1.2),brown)
  for _,side in {-1,1} do
   local x=-76+side*6.6
   part(root,'RibLeg'..i..'_'..side,CFrame.new(x,14.25,z),V(1.2,9.35,1.2),brown)
   beam(root,'RibBrace'..i..'_'..side,V(x,18.7,z),V(-76+side*4.2,23.4,z),1.2,1.2,brown)
   local source=glow(root,'RibSource'..i..'_'..side,-76+side*5.68,10.4,z,2.8)
   local cone=Instance.new('SpotLight');cone.Name='TrackPool';cone.Face=Enum.NormalId.Bottom;cone.Angle=90;cone.Range=18;cone.Brightness=1.2;cone.Color=Color3.fromRGB(255,191,116);cone.Shadows=false;cone.Parent=source
   cage(root,'RibCage'..i..'_'..side,-76+side*5.68,10.4,z)
  end
 end
 -- Each source hangs from an existing retained ceiling; no light through new openings.
 for i,g in {{-76,73},{-61.8,94}} do
  part(root,'ExitHanger'..i,CFrame.new(g[1],18.4,g[2]),V(.18,11.2,.18),{64,50,39})
  glow(root,'ExitSource'..i,g[1],12.4,g[2],8)
  part(root,'ExitCap'..i,CFrame.new(g[1],12.9,g[2]),V(1.1,.2,1.1),{64,50,39})
 end
 -- Exact off-lane wall pockets measured against retained OBBs; no invented footings.
 local corbels={
  {0,1,-68.675898,.288204},{1,1,-68.681576,.276849},
  {2,-1,-83.342854,.325707},{2,1,-68.311521,1.016958},
  {3,-1,-83.630941,.901882},{3,1,-68.711317,.217366},
  {4,-1,-83.403689,.447377},{4,1,-68.551295,.537410},
  {5,1,-67.966816,1.706367},
 }
 for _,a in corbels do
  local i,side,x,length=unpack(a);length-=.004;x-=side*.002 -- F32 margin inside audited .035 tolerance.
  local z=-11+i*11;local leg=-76+side*6.6
  part(root,'WallCorbel'..i..'_'..side,CFrame.new(x,9.85,z),V(length,.55,.65),{85,59,39})
  part(root,'Shoe'..i..'_'..side,CFrame.new(leg,9.85,z),V(1.24,.3,1.24),{53,47,39},Enum.Material.Metal)
  local bolt=part(root,'ShoeBolt'..i..'_'..side,CFrame.new(leg,9.85,z+.66),V(.18,.18,.18),{132,125,105},Enum.Material.Metal);bolt.Shape=Enum.PartType.Ball
 end
 -- A stored pickaxe is four purposeful pieces; the mounting strap touches the shoring.
 for _,g in {{2,-1},{4,1},{6,-1}} do
  local i,side=unpack(g);local x=-76+side*6.6;local inward=-side;local z=-11+i*11
  part(root,'ToolMount'..i,CFrame.new(x,12.8,z-.68),V(.7,.22,.25),{53,47,39},Enum.Material.Metal)
  beam(root,'PickHandle'..i,V(x+inward*.15,11.3,z-.85),V(x+inward*.35,13.7,z-.85),.2,.2,{100,68,39})
  local head=beam(root,'PickHead'..i,V(x-inward*.3,13.8,z-.85),V(x+inward*1.1,13.6,z-.85),.24,.24,{117,127,130});head.Material=Enum.Material.Metal
  local tip=beam(root,'PickTip'..i,V(x+inward*1.1,13.6,z-.85),V(x+inward*1.3,13.2,z-.85),.22,.22,{117,127,130});tip.Material=Enum.Material.Metal
 end
 wayboard(root,'AheadExit',-77.8,61,false,1)
 wayboard(root,'BendExit',-73.8,61,true,2)
end
return S
