local fs,rb,serde=require('@lune/fs'),require('@lune/roblox'),require('@lune/serde')
local main='slice-v2/prototype/guardian-greybox.rbxl'
local backup='slice-v2/prototype/guardian-greybox.pre-s9.rbxl'
assert(not fs.isFile(backup),'backup already exists; inspect before replacing')
local bytes=fs.readFile(main);local p=rb.deserializePlace(bytes)
fs.writeFile(backup,bytes);assert(fs.readFile(backup)==bytes)
local sources={}
for _,n in p:GetDescendants() do if n:IsA('LuaSourceContainer') then
 sources[n.Name]=#n.Source
 if n.Name=='GreyboxPlacement' or n.Name=='GreyboxConfig' or n.Name=='GreyboxScene' or n.Name=='UIStyle' then fs.writeFile('treasure/sections/S9/baseline-'..n.Name..'.luau',n.Source) end
end end
fs.writeFile('treasure/sections/S9/BACKUP.json',serde.encode('json',{sha256=serde.hash('sha256',bytes),byte_verified=true,sources=sources},true))
print('BACKUP',serde.hash('sha256',bytes));print(serde.encode('json',sources,true))
