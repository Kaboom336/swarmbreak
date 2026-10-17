local fs,rb,luau,serde=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau'),require('@lune/serde')
local p=rb.deserializePlace(fs.readFile('slice-v2/prototype/guardian-greybox.rbxl'))
for _,pair in {{p.ServerScriptService.Greybox,'slice-v2/prototype/Greybox.server.luau'},{p.ServerScriptService.GreyboxLoopTestRunner,'slice-v2/prototype/LoopTest.luau'},{p.ReplicatedStorage.MeadowV4.Section5,'prototype/meadow-v4/Section5.luau'}} do
 print('PARITY',pair[1]:GetFullName(),pair[1].Source==fs.readFile(pair[2]))
end
local cache={}
local function load(n)
 if cache[n] then return cache[n] end
 cache[n]=luau.load(n.Source,{environment={script=n,require=load,warn=warn,Vector3=rb.Vector3,Vector2=rb.Vector2,CFrame=rb.CFrame,Color3=rb.Color3,NumberSequence=rb.NumberSequence,ColorSequence=rb.ColorSequence,Enum=rb.Enum,Instance=rb.Instance,UDim2=rb.UDim2,game={GetService=function() return p.ReplicatedStorage end}}})()
 return cache[n]
end
local model=load(p.ReplicatedStorage.MeadowV4.Builder).build(p.Workspace,rb.Vector3.new(0,76,-360))
local Ray=require('../prototype/meadow-v4/OfflineRay').new(model,nil,2)
local rows={}
for _,pos in {rb.Vector3.new(0,124,-456),rb.Vector3.new(6,124,-466.7),rb.Vector3.new(0,76,-402)} do
 local h=Ray(pos+rb.Vector3.new(0,10,0),rb.Vector3.new(0,-30,0))
 assert(h,'missing court/summit floor')
 table.insert(rows,{probe={pos.X,pos.Y,pos.Z},floor=h.Instance:GetFullName(),height=h.Position.Y})
 print('FLOOR',pos,h and h.Instance:GetFullName(),h and h.Position)
end
local cosmetics=0
for _,n in model:GetDescendants() do
 if n:IsA('BasePart') and n:GetAttribute('Section')=='S5' then
  assert(not n.CanCollide and not n.CanQuery and not n.CanTouch,'S5 physical contamination')
  cosmetics+=1
 end
end
fs.writeFile('treasure/PVPFLAKE-GEOMETRY.json',serde.encode('json',{probes=rows,S5_cosmetic_parts=cosmetics,S5_physical_contamination=false,live='UNKNOWN'},true))
