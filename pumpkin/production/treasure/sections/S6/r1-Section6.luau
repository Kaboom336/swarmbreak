-- S6 R1 silhouette study. Existing summit court, routes and solids remain exact.
local S = {}
local V = Vector3.new
local work = 0
local function yieldBuild()
 work += 1
 if work % 300 == 0 then if task then task.wait() end end
end
local function part(root,name,frame,size,color,material)
 yieldBuild()
 local p=Instance.new('Part');p.Name='S6_'..name;p.CFrame=frame;p.Size=size
 p.Color=Color3.fromRGB(unpack(color));p.Material=material or Enum.Material.Slate
 p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false
 p:SetAttribute('Section','S6');p:SetAttribute('Cosmetic',true);p.Parent=root
 return p
end
local function beam(root,name,a,b,width)
 local n=(b-a).Unit;local u=V(0,1,0)
 local x=u:Cross(n).Unit;local y=n:Cross(x).Unit;local c=(a+b)/2
 return part(root,name,CFrame.new(c.X,c.Y,c.Z,x.X,y.X,n.X,x.Y,y.Y,n.Y,x.Z,y.Z,n.Z),V(width,width,(b-a).Magnitude),{149,139,114})
end
local groups={
 {name='LowerSpiral',y=24,points={{-46,-142},{-42,-146},{-38,-150}}},
 {name='UpperSpiral',y=36,points={{26,-150},{30,-146},{34,-142}}},
 {name='RecoveryShelf',y=12,points={{86,-86},{94,-86},{102,-86}}},
}
function S.build(root)
 -- Finish-only on explicit residual S6 cliff bodies. No lane, art, tag or flag edits.
 for _,p in root:GetDescendants() do
  yieldBuild()
  if p:IsA('BasePart') and p.Name=='SolidMountainStone' then
   local v=p.CFrame.Position
   local top=v.Y+p.Size.Y/2
   if top>=0 and top<=54 and v.X>=-65 and v.X<=125 and v.Z>=-158 and v.Z<=-35
    and not(v.X>=-32 and v.X<=32 and v.Z>=-132 and v.Z<=-72) then
    p.Color=if top>=36 then Color3.fromRGB(149,139,115) elseif top>=20 then Color3.fromRGB(128,124,101) else Color3.fromRGB(112,116,93)
    p.Material=Enum.Material.Rock
   end
  end
 end
 for _,g in groups do
  local points={}
  for i,q in g.points do
   part(root,g.name..'Pier'..i,CFrame.new(q[1],g.y+1.5,q[2]),V(.9,3,.9),{137,130,108})
   points[i]=V(q[1],g.y+2.5,q[2])
  end
  for i=1,2 do beam(root,g.name..'Sill'..i,points[i],points[i+1],.28) end
 end
end
return S
