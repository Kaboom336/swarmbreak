-- Presentation only. Never receives or changes the authoritative loot root.
local A={}
function A.build()
 local model=Instance.new('Model');model.Name='SummitAcorn'
 local function piece(name,size,frame,color,material,shape)
  local p=Instance.new('Part');p.Name=name;p.Size=size;p.CFrame=frame
  p.Color=Color3.fromRGB(unpack(color));p.Material=Enum.Material[material]
  p.Shape=Enum.PartType[shape or 'Ball'];p.Anchored=true;p.Massless=true
  p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.Parent=model;return p
 end
 piece('GoldenBody',Vector3.new(2.55,2.8,2.55),CFrame.new(0,1.4,0),{244,183,39},'Metal')
 piece('CapBrown',Vector3.new(2.8,.85,2.8),CFrame.new(0,2.55,0),{102,66,31},'Wood')
 for ring=0,1 do
  for i=1,12 do
   local a=(i+ring*.5)*math.pi/6;local r=ring==0 and 1.18 or .87
   piece('CapScale',Vector3.new(.38,.22,.38),CFrame.new(math.cos(a)*r,2.69+ring*.18,math.sin(a)*r),{125+ring*10,85,39},'Wood')
  end
  if task then task.wait() end
 end
 piece('StemBrown',Vector3.new(.32,.72,.32),CFrame.new(.08,3.12,0)*CFrame.Angles(0,0,-.2),{81,52,25},'Wood','Cylinder')
 model.WorldPivot=CFrame.identity
 return model
end
return A
