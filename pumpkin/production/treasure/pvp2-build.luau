-- Lune source-only mount. Preserve every property/asset and the original backup.
local fs,rb,luau,serde=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau'),require('@lune/serde')
local path='slice-v2/prototype/guardian-greybox.rbxl'
local backup='slice-v2/prototype/guardian-greybox.pre-pvp2.rbxl'
local original=fs.readFile(path)
assert(not fs.isFile(backup),'refuse to overwrite pre-pvp2 backup')
local place=rb.deserializePlace(original)
local old=place.ServerScriptService.GreyboxLoopTestRunner.Source
place.ServerScriptService.GreyboxLoopTestRunner.Source=fs.readFile('slice-v2/prototype/LoopTest.luau')
local count=0
for _,n in place:GetDescendants() do
 if n:IsA('LuaSourceContainer') then
  for level=0,2 do luau.compile(n.Source,{optimizationLevel=level}) end
  count+=1
 end
end
local bytes=rb.serializePlace(place)
local check=rb.deserializePlace(bytes)
assert(check.ServerScriptService.GreyboxLoopTestRunner.Source==fs.readFile('slice-v2/prototype/LoopTest.luau'))
check.ServerScriptService.GreyboxLoopTestRunner.Source=old
assert(rb.serializePlace(check)==rb.serializePlace(rb.deserializePlace(original)),'unrelated serialized state changed')
fs.writeFile(backup,original)
assert(fs.readFile(backup)==original,'backup bytes differ')
fs.writeFile(path,bytes)
fs.writeFile('treasure/PVP2-BUILD.json',serde.encode('json',{
 backup=backup,backup_sha256=serde.hash('sha256',original),mounted_sha256=serde.hash('sha256',bytes),
 compiled_O0_O1_O2=count,only_runner_source_changed=true,backup_byte_verified=true,
 limits_timers_assertions_gameplay_geometry_preserved=true,studio_play='NOT RUN',commit='NONE'
},true))
print('PASS mount; byte-verified pre-pvp2 backup; only runner Source changed;',count,'sources compile O0/O1/O2')
