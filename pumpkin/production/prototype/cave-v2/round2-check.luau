local fs,rb,serde,luau=require('@lune/fs'),require('@lune/roblox'),require('@lune/serde'),require('@lune/luau')
local place=rb.deserializePlace(fs.readFile('prototype/cave-v2.rbxl'))
local scene=serde.decode('json',fs.readFile('prototype/cave-v2/scene.json'))
local model=place:GetService('Workspace'):FindFirstChild('CaveV2')
local children=model:GetChildren();assert(#children==#scene.parts,'native part count')
local maxError=0
for i,p in children do
 local expected=scene.parts[i];assert(p.Name==expected.name,'part order/name')
 local q=p.CFrame.Position;local s=p.Size
 for axis,v in {q.X,q.Y,q.Z} do maxError=math.max(maxError,math.abs(v-expected.position[axis])) end
 for axis,v in {s.X,s.Y,s.Z} do maxError=math.max(maxError,math.abs(v-expected.size[axis])) end
 assert(p.Anchored and p.CanCollide==expected.collidable,'physics flags')
 local right,up,back=p.CFrame.RightVector,p.CFrame.UpVector,-p.CFrame.LookVector
 local r={right.X,up.X,back.X,right.Y,up.Y,back.Y,right.Z,up.Z,back.Z}
 for axis,v in r do maxError=math.max(maxError,math.abs(v-expected.rotation[axis])) end
end
assert(maxError<.0001,'native manifest transform mismatch')
local scripts,lights,hooks=0,0,0
for _,p in place:GetDescendants() do
 if p:IsA('LuaSourceContainer') then luau.compile(p.Source);scripts+=1 end
 if p:IsA('PointLight') then lights+=1 end
 if p:GetAttribute('Placeholder')==true then
  hooks+=1;assert(p:GetAttribute('TelegraphSeconds') and p:GetAttribute('CooldownSeconds'),'hook contracts')
 end
end
assert(lights==#scene.lights and hooks==5,'light or hook export count')
local lighting=place:GetService('Lighting')
assert(math.abs(lighting.ClockTime-.2)<.0001 and lighting:FindFirstChild('CrystalBloom') and lighting:FindFirstChild('NightBlueSky'),'night sky/bloom export')
local report={parts=#children,maximum_native_transform_error=maxError,compiled_scripts=scripts,point_lights=lights,placeholder_hooks=hooks,runtime='UNKNOWN; static binary inspection'}
fs.writeFile('prototype/cave-v2/ROUND2-NATIVE-CHECK.json',serde.encode('json',report,true))
print(serde.encode('json',report,true))
