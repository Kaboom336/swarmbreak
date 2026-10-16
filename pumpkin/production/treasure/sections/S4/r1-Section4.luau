-- S4 R1: structural silhouettes only. Existing pcall guard; island-local coordinates.
local S={}
local V=Vector3.new
local function part(root,name,frame,size,color,material)
 local p=Instance.new('Part');p.Name='S4_'..name;p.CFrame=frame;p.Size=size
 p.Color=Color3.fromRGB(unpack(color));p.Material=material or Enum.Material.Wood
 p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false
 p:SetAttribute('Section','S4');p:SetAttribute('Cosmetic',true);p.Parent=root;return p
end
local function rod(root,name,a,b,width,color)
 -- Explicit basis avoids offline lookAt/engine disagreement. Long axis local Z.
 local n=(b-a).Unit;local u=V(1,0,0)
 if math.abs(n:Dot(u))>.9 then u=V(0,1,0) end
 local x=u:Cross(n).Unit;local y=n:Cross(x).Unit;local c=(a+b)/2
 return part(root,name,CFrame.new(c.X,c.Y,c.Z,x.X,y.X,n.X,x.Y,y.Y,n.Y,x.Z,y.Z,n.Z),V(width,width,(b-a).Magnitude),color,Enum.Material.Fabric)
end
function S.build(root)
 -- Remove only bridge-owned cosmetic fence; preserve all planks, guard beams and floors.
 for _,p in root:GetDescendants() do if p:IsA('BasePart') then
  local v=p.CFrame.Position
  if (p.Name=='R5FencePost' or p.Name=='R5FenceRail') and math.abs(math.abs(v.X)-11.6)<.02 then
   if math.abs(v.Z)<=24.01 and not p.CanCollide and not p.CanQuery and not p.CanTouch and not p:GetAttribute('WalkableLaneFloor') and #p:GetTags()==0 then p:Destroy() end
  end
 end end
 -- Four three-piece anchor groups: footing carries post; cap protects its end grain.
 for _,x in {-11.6,11.6} do
  for _,z in {-16,16} do
   local key=x..'_'..z
   part(root,'Footing'..key,CFrame.new(x,4.65,z),V(2.6,.7,2.6),{104,108,89},Enum.Material.Slate)
   part(root,'Anchor'..key,CFrame.new(x,7.5,z),V(1.15,5,1.15),{108,69,39})
   part(root,'Cap'..key,CFrame.new(x,10.12,z),V(1.4,.24,1.4),{78,50,31})
  end
  -- Seven cable segments form one load-bearing silhouette, each end touches an anchor.
  for i=0,6 do
   local function point(t)return V(x,9.5-2.6*math.sin(math.pi*t),-16+32*t) end
   rod(root,'Cable'..x..'_'..i,point(i/7),point((i+1)/7),.22,{161,135,85})
  end
 end
 -- Recovery rail follows the actual straight ramp. Feet sit on existing stone columns,
 -- outside the complete lane margin; no new walking surface or switchback.
 local tops={}
 for i=0,5 do
  local z=20+i*10;local top=-math.huge
  for _,p in root:GetDescendants() do if p:IsA('BasePart') and p.Name=='SolidMountainStone' then
   local v=p.CFrame.Position
   if math.abs(v.X+34)<=p.Size.X/2 and math.abs(v.Z-z)<=p.Size.Z/2 then top=math.max(top,v.Y+p.Size.Y/2) end
  end end
  assert(top>-36 and top<4,'recovery support missing')
  tops[i+1]=V(-34,top+6,z)
  part(root,'RecoveryFoot'..i,CFrame.new(-34,top+.25,z),V(1,.5,1),{95,101,84},Enum.Material.Slate)
  part(root,'RecoveryPost'..i,CFrame.new(-34,top+3.25,z),V(.55,5.5,.55),{103,69,42})
  part(root,'RecoveryCap'..i,CFrame.new(-34,top+6.1,z),V(.8,.2,.8),{78,50,31})
 end
 for i=1,5 do rod(root,'RecoveryCable'..i,tops[i],tops[i+1],.16,{161,135,85}) end
 -- Three purposeful cliff groups, three offset faces each; tangent to retained wall.
 for i,g in {{-46,-1},{32,-1},{57,1}} do
  for j=0,2 do
   local x=g[1]+(j-1)*3.6;local h=10+j*3;local z=g[2]*15.7
   part(root,'CliffFace'..i..'_'..j,CFrame.new(x,-5-h/2,z),V(3.6,h,.6),{88+j*6,98+j*5,89+j*3},Enum.Material.Rock)
  end
 end
end
return S
