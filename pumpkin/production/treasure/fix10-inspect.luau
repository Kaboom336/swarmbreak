local fs,rb,luau=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau')
local main='slice-v2/prototype/guardian-greybox.rbxl'
local backup='slice-v2/prototype/guardian-greybox.pre-fix10.rbxl'
if not fs.isFile(backup) then
 local bytes=fs.readFile(main);rb.deserializePlace(bytes);fs.writeFile(backup,bytes);assert(fs.readFile(backup)==bytes)
end
for _,suffix in {'pre-outsmart','pre-fix7','pre-fix8','pre-fix9','pre-fix10'} do
 local p=rb.deserializePlace(fs.readFile('slice-v2/prototype/guardian-greybox.'..suffix..'.rbxl'))
 local cache={}
 local function load(n)
  if cache[n] then return cache[n] end
  cache[n]=luau.load(n.Source,{environment={script=n,require=load,Vector3=rb.Vector3,Vector2=rb.Vector2,CFrame=rb.CFrame,Color3=rb.Color3,Enum=rb.Enum,Instance=rb.Instance,UDim2=rb.UDim2,warn=warn}})();return cache[n]
 end
 local g=load(p.ReplicatedStorage.MeadowV4.Gameplay)
 local r=g.pvpRoutes();local length=0
 for i=2,#r.Dummy do local a,b=r.Dummy[i-1],r.Dummy[i];length+=rb.Vector3.new(a.x-b.x,a.y-b.y,a.z-b.z).Magnitude end
 print(suffix,'dummy distance',length,'court',r.Pacing[1])
end
