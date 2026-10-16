local fs,rb=require('@lune/fs'),require('@lune/roblox')
local main='slice-v2/prototype/guardian-greybox.rbxl'
local backup='slice-v2/prototype/guardian-greybox.pre-s2close.rbxl'
assert(not fs.isFile(backup),'preserve close backup')
local bytes=fs.readFile(main);rb.deserializePlace(bytes);fs.writeFile(backup,bytes)
assert(fs.readFile(backup)==bytes,'backup byte verification')
local old=rb.deserializePlace(fs.readFile('slice-v2/prototype/guardian-greybox.pre-s2r4.rbxl'))
local current=rb.deserializePlace(bytes)
for _,n in current:GetDescendants() do if n:IsA('LuaSourceContainer') then
 local q=old;for _,name in string.split(n:GetFullName(),'.') do q=assert(q:FindFirstChild(name),name) end
 if q.Source~=n.Source then assert(n:GetFullName()=='ReplicatedStorage.MeadowV4.Section2','unexpected R4 source '..n:GetFullName()) end
end end
local path='prototype/meadow-v4/Section2.luau'
local patch='*** Begin Patch\n*** Update File: '..path..'\n@@\n'
for _,line in string.split(fs.readFile(path):gsub('\r\n','\n'),'\n') do patch..='-'..line..'\n' end
for _,line in string.split(old.ReplicatedStorage.MeadowV4.Section2.Source:gsub('\r\n','\n'),'\n') do patch..='+'..line..'\n' end
print(patch..'*** End Patch')
