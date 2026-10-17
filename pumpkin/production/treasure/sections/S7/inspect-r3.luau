local fs,rb=require('@lune/fs'),require('@lune/roblox')
local main='slice-v2/prototype/guardian-greybox.rbxl'
local backup='slice-v2/prototype/guardian-greybox.pre-s7r3.rbxl'
assert(not fs.isFile(backup),'preserve pre-r3 backup')
local bytes=fs.readFile(main);local p=rb.deserializePlace(bytes)
fs.writeFile(backup,bytes);assert(fs.readFile(backup)==bytes)
for _,n in p:GetDescendants() do
 if n:IsA('LuaSourceContainer') and (n.Source:find('Beam') or n.Source:find('Golden Acorn') or n.Name=='Builder') then
  if n.Name~='Data' then fs.writeFile('treasure/sections/S7/inspect-'..n.Name..'.txt',n.Source);print(n:GetFullName()) end
 end
end
print('PASS byte-verified pre-s7r3 backup')
