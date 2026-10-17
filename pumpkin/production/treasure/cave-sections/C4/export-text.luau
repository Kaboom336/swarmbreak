-- Export only preserved saved text + explicitly installed reverse faces into
-- previous immutable geometry manifests. Does not write any place or source.
local fs,rb,serde=require('@lune/fs'),require('@lune/roblox'),require('@lune/serde')
local H='treasure/cave-sections/C4/'
for _,tag in {'before','r1','r2'}do
 local p=rb.deserializePlace(fs.readFile(tag=='before'and'prototype/cave-v2.pre-c4.rbxl'or H..tag..'-review.rbxl'))
 local faces={}
 for i,n in p.Workspace:GetDescendants()do
  if n:IsA('BasePart')then for _,gui in n:GetChildren()do if gui:IsA('SurfaceGui')then
   local label=gui:FindFirstChildWhichIsA('TextLabel')
   if label then
    faces[n.Name]=faces[n.Name]or{};table.insert(faces[n.Name],{face=gui.Face.Name,text=label.Text})
    if tag=='r2'and table.find({'BailSign','JumpReady','RecoverySign'},n.Name)then
     table.insert(faces[n.Name],{face=gui.Face==rb.Enum.NormalId.Front and'Back'or'Front',text=label.Text})
    end
   end
  end end end
  if i%300==0 then require('@lune/task').wait()end
 end
 local data=serde.decode('json',fs.readFile(H..tag..'.json'))
 for _,g in data.parts do g.textFaces=faces[g.name]or{}end
 fs.writeFile(H..tag..'.json',serde.encode('json',data,true));print('text-only export',tag)
end
