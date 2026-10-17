local fs,rb=require('@lune/fs'),require('@lune/roblox')
local path='slice-v2/prototype/guardian-greybox.rbxl'
local bytes=fs.readFile(path)
local backup='slice-v2/prototype/guardian-greybox.pre-raid1.rbxl'
if not fs.isFile(backup) then fs.writeFile(backup,bytes) end
assert(fs.readFile(backup)==bytes,'backup differs; do not overwrite')
local p=rb.deserializePlace(bytes)
for _,n in p.ServerScriptService:GetChildren() do print(n.Name,n.ClassName) end
local luau,serde=require('@lune/luau'),require('@lune/serde')
local cache={}
local function load(n)
 if cache[n] then return cache[n] end
 local env={script=n,require=load,warn=warn,Vector3=rb.Vector3,Vector2=rb.Vector2,CFrame=rb.CFrame,Color3=rb.Color3,Enum=rb.Enum,Instance=rb.Instance,UDim2=rb.UDim2,NumberSequence=rb.NumberSequence,ColorSequence=rb.ColorSequence,
 game={GetService=function(_,s) if s=='ReplicatedStorage' then return p.ReplicatedStorage elseif s=='RunService' then return {} elseif s=='Workspace' then return p.Workspace else return {JSONDecode=function(_,v)return serde.decode('json',v)end} end end}}
 cache[n]=luau.load(n.Source,{environment=env})();return cache[n]
end
local map=load(p.ReplicatedStorage.MeadowV4.Builder).build(p.Workspace,rb.Vector3.new(0,76,-360))
local ray=require('../prototype/meadow-v4/OfflineRay').new(map)
local origin=rb.Vector3.new(0,76,-360)
for z=36,116,8 do
 local row={tostring(z)}
 for x=-100,-48,4 do
  local h=ray(origin+rb.Vector3.new(x,8,z),rb.Vector3.new(0,-16,0))
  table.insert(row,h and string.format('%s:%.1f',x,h.Position.Y-76) or tostring(x)..':X')
 end
 print(table.concat(row,' '))
end
for _,q in p.Workspace:GetDescendants() do
 if q:IsA('BasePart') and q.Name=='OutsmartBaitFloor' then print('ORIGIN',q.Position-rb.Vector3.new(-73,-.48,98.25)) end
end
