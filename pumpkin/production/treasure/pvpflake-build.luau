-- Preserve the canonical asset tree; mount only the two reviewed sources.
local fs,rb,luau,serde=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau'),require('@lune/serde')
local main='slice-v2/prototype/guardian-greybox.rbxl'
local backup='slice-v2/prototype/guardian-greybox.pre-pvpflake.rbxl'
local original=fs.readFile(main)
if require('@lune/process').args[1]=='remount' then
 assert(fs.isFile(backup),'pre-pvpflake backup required')
else
 assert(not fs.isFile(backup),'refuse to overwrite pre-pvpflake backup')
 fs.writeFile(backup,original)
 assert(fs.readFile(backup)==original,'backup byte parity')
end
local p=rb.deserializePlace(original)
p.ServerScriptService.Greybox.Source=fs.readFile('slice-v2/prototype/Greybox.server.luau')
p.ServerScriptService.GreyboxArena.Source=fs.readFile('slice-v2/prototype/Arena.luau')
local count=0
for _,n in p:GetDescendants() do
 if n:IsA('LuaSourceContainer') then
  for opt=0,2 do luau.compile(n.Source,{optimizationLevel=opt}) end
  count+=1
 end
end
local bytes=rb.serializePlace(p)
local neutral=rb.deserializePlace(bytes)
local old=rb.deserializePlace(original)
neutral.ServerScriptService.Greybox.Source=old.ServerScriptService.Greybox.Source
neutral.ServerScriptService.GreyboxArena.Source=old.ServerScriptService.GreyboxArena.Source
assert(rb.serializePlace(neutral)==rb.serializePlace(old),'unrelated serialized state changed')
fs.writeFile(main,bytes)
fs.writeFile('treasure/PVPFLAKE-BUILD.json',serde.encode('json',{
 backup_sha256=serde.hash('sha256',fs.readFile(backup)),canonical_sha256=serde.hash('sha256',bytes),
 compiled_O0_O1_O2=count,only_Greybox_and_Arena_changed=true,pvp_runner_preserved=true,live='NOT RUN'
},true))
print('PASS Lune mount; backup byte verified; only Greybox/Arena Source changed;',count,'sources O0/O1/O2')
