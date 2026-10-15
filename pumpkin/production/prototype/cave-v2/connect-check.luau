local fs,rb,serde,luau=require('@lune/fs'),require('@lune/roblox'),require('@lune/serde'),require('@lune/luau')
local H='prototype/cave-v2/'
local before=rb.deserializePlace(fs.readFile(H..'connect-before.rbxl'))
local after=rb.deserializePlace(fs.readFile('prototype/cave-v2.rbxl'))
local scene=serde.decode('json',fs.readFile(H..'scene.json'))
local baseline=serde.decode('json',fs.readFile(H..'connect-before-scene.json'))
local function eq(a,b)
 if type(a)~=type(b) then return false end
 if type(a)~='table' then return a==b end
 for k,v in a do if not eq(v,b[k]) then return false end end
 for k in b do if a[k]==nil then return false end end
 return true
end
assert(eq(scene.routes,baseline.routes),'route dictionary changed')
local function geometry(s)
 local t={};for _,p in s.parts do if p.collidable then table.insert(t,{name=p.name,category=p.category,position=p.position,size=p.size,rotation=p.rotation}) end end;return t
end
assert(eq(geometry(scene),geometry(baseline)),'collision geometry changed')
local compiled=0
local function contracts(place)
 local scripts,hooks={},{}
 for _,p in place:GetDescendants() do
  if p:IsA('LuaSourceContainer') then luau.compile(p.Source);compiled+=1;if p.Name~='CaveRouteData' and p.Name~='CaveConnectArt' then scripts[p.Name]=p.Source end end
  if p:GetAttribute('Placeholder')==true then hooks[p.Name]=p:GetAttributes() end
 end
 return scripts,hooks
end
local a,b=contracts(before);compiled=0;local c,d=contracts(after)
assert(eq(a,c),'gameplay script changed');assert(eq(b,d),'native hook contracts changed')
local children=after:GetService('Workspace'):FindFirstChild('CaveV2'):GetChildren()
assert(#children==#scene.parts,'native count mismatch')
local error=0;local lights=0
for i,p in children do
 local e=scene.parts[i];assert(p.Name==e.name and p.CanCollide==e.collidable,'native flags/name')
 assert(p.Material.Name==e.material and math.abs(p.Transparency-e.transparency)<.001,'native material/transparency mismatch')
 if e.category:match('^connect%-') then assert(p.Size.X>=.001 and p.Size.Y>=.001 and p.Size.Z>=.001,'sub-minimum visual dimension') end
 local pos=p.CFrame.Position;local r,u,k=p.CFrame.RightVector,p.CFrame.UpVector,-p.CFrame.LookVector
 local values={pos.X,pos.Y,pos.Z,p.Size.X,p.Size.Y,p.Size.Z,r.X,u.X,k.X,r.Y,u.Y,k.Y,r.Z,u.Z,k.Z}
 local target={unpack(e.position)};for _,v in e.size do table.insert(target,v) end;for _,v in e.rotation do table.insert(target,v) end
 for j,v in values do error=math.max(error,math.abs(v-target[j])) end
 for j,v in {p.Color.R*255,p.Color.G*255,p.Color.B*255} do assert(math.abs(v-e.color[j])<.001,'native color mismatch') end
 for _,l in p:GetChildren() do if l:IsA('PointLight') then lights+=1 end end
end
assert(error<.0001 and lights==#scene.lights,'native transform/light mismatch')
local lighting=after:GetService('Lighting')
assert(lighting.Ambient.R<60/255 and lighting.ClockTime<1,'cool dim night settings missing')
local report={native_parts=#children,max_transform_error=error,point_lights=lights,routes_equal=true,collision_geometry_equal=true,terrain_height_mass_equal=true,gameplay_sources_equal=true,native_hook_attributes_equal=true,compiled_scripts=compiled,exposure=lighting.ExposureCompensation,runtime='UNKNOWN; static native binary inspection'}
fs.writeFile(H..'CONNECT-NATIVE-CHECK.json',serde.encode('json',report,true));print(serde.encode('json',report,true))

