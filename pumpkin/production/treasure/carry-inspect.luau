local fs,rb,luau,serde=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau'),require('@lune/serde')
local base='slice-v2/prototype/guardian-greybox.'
local a=rb.deserializePlace(fs.readFile(base..'pre-s3.rbxl'))
local b=rb.deserializePlace(fs.readFile(base..'rbxl'))
local function sources(p) local t={} for _,n in p:GetDescendants() do if n:IsA('LuaSourceContainer') then t[n:GetFullName()]=n.Source end end return t end
local aa,bb=sources(a),sources(b)
fs.writeFile('treasure/carry-sources-before.json',serde.encode('json',aa))
fs.writeFile('treasure/carry-sources-current.json',serde.encode('json',bb))
for k,v in bb do if v~=aa[k] then print('SOURCE',k,if aa[k] then 'changed' else 'added') end end
local function build(p,tag)
 local cache={};local function load(n)
  if cache[n] then return cache[n] end
  cache[n]=luau.load(n.Source,{environment={script=n,require=load,warn=warn,Vector3=rb.Vector3,Vector2=rb.Vector2,CFrame=rb.CFrame,Color3=rb.Color3,NumberSequence=rb.NumberSequence,ColorSequence=rb.ColorSequence,Enum=rb.Enum,Instance=rb.Instance,UDim2=rb.UDim2,game={GetService=function(_,name) if name=='ReplicatedStorage' then return p.ReplicatedStorage elseif name=='RunService' then return {} end return {JSONDecode=function(_,s)return serde.decode('json',s)end} end}}})() return cache[n]
 end
 local m=load(p.ReplicatedStorage.MeadowV4.Builder).build(p.Workspace,rb.Vector3.zero)
 local out={}
 for _,n in m:GetDescendants() do if n:IsA('BasePart') then table.insert(out,{name=n.Name,cf={n.CFrame:GetComponents()},size={n.Size.X,n.Size.Y,n.Size.Z},collide=n.CanCollide,query=n.CanQuery,touch=n.CanTouch,material=n.Material.Name,attributes=n:GetAttributes(),tags=n:GetTags()}) end end
 fs.writeFile('treasure/carry-'..tag..'.json',serde.encode('json',out))
 print(tag,#out)
end
build(a,'before');build(b,'current')
