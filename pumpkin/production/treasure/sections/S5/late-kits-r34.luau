-- Additional check for S5's deferred kit envelopes at the real nonzero MeadowOrigin.
local fs,rb,luau,serde=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau'),require('@lune/serde')
local place=rb.deserializePlace(fs.readFile('slice-v2/prototype/guardian-greybox.rbxl'));local cache={}
local function load(n)
 if cache[n] then return cache[n] end
 local env={script=n,require=load,warn=function(...)error(...)end,Vector3=rb.Vector3,Vector2=rb.Vector2,CFrame=rb.CFrame,Color3=rb.Color3,NumberSequence=rb.NumberSequence,ColorSequence=rb.ColorSequence,Enum=rb.Enum,Instance=rb.Instance,UDim2=rb.UDim2,
 game={GetService=function(_,name) if name=='ReplicatedStorage' then return place.ReplicatedStorage elseif name=='RunService' then return {} end;assert(name=='HttpService');return {JSONDecode=function(_,s)return serde.decode('json',s)end} end}}
 cache[n]=luau.load(n.Source,{environment=env})();return cache[n]
end
local origin=rb.Vector3.new(0,76,-360)
local root=load(place.ReplicatedStorage.MeadowV4.Builder).build(place.Workspace,origin)
local section=load(place.ReplicatedStorage.MeadowV4.Section5);local count=0
local kit={fit=function()return true end,spawn=function(name,island,frame,size)
 count+=1;local g=section.kits[count]
 assert((frame.Position-origin-rb.Vector3.new(g.x,g.y,g.z)).Magnitude<.002,'S5 kit translated wrong')
 local anchor=assert(root:FindFirstChild('S5_RockAnchor'..count))
 assert((anchor.CFrame.Position-frame.Position-rb.Vector3.new(0,size.Y/2,0)).Magnitude<.002,'kit envelope/anchor mismatch')
 local m=rb.Instance.new('Model');local p=rb.Instance.new('Part');p.Size=size;p.CFrame=frame*rb.CFrame.new(0,size.Y/2,0);p.Parent=m;return m
end}
section.spawnKits(root,kit);section.spawnKits(root,kit)
assert(count==#section.kits,'S5 kit idempotence')
for _,p in root:GetDescendants() do if p:IsA('BasePart') and p:GetAttribute('Section')=='S5' then assert(not p.CanCollide and not p.CanQuery and not p.CanTouch,'S5 physics flags') end end
print('PASS S5 late kits: real MeadowOrigin (0,76,-360), exact fitted envelopes, idempotence, cosmetic flags;',count,'kits')
