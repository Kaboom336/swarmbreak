-- Mount only reviewed sources into the canonical native place; preserve all assets.
local fs, rb, luau, serde = require('@lune/fs'), require('@lune/roblox'), require('@lune/luau'), require('@lune/serde')
local main = 'slice-v2/prototype/guardian-greybox.rbxl'
local backup = 'slice-v2/prototype/guardian-greybox.pre-perf.rbxl'
local original = fs.readFile(main)
assert(not fs.isFile(backup), 'refuse to overwrite pre-perf backup')
fs.writeFile(backup, original)
assert(fs.readFile(backup) == original, 'backup byte parity')
local place, before = rb.deserializePlace(original), rb.deserializePlace(original)
local source = fs.readFile('slice-v2/prototype/Greybox.server.luau')
place.ServerScriptService.Greybox.Source = source
local count, preserved = 0, 0
for _, node in place:GetDescendants() do
 if node:IsA('LuaSourceContainer') then
  for opt=0,2 do luau.compile(node.Source, {optimizationLevel=opt}) end
  count += 1
  if node ~= place.ServerScriptService.Greybox then
   local old=before
   for _, key in string.split(node:GetFullName(), '.') do old=assert(old:FindFirstChild(key),key) end
   assert(node.Source == old.Source, 'unrelated source changed: '..node:GetFullName())
   preserved += 1
  end
 end
 assert(node.Name ~= 'Section5', 'S5 must remain unmounted')
end
assert(rb.serializeModel({place.Workspace}) == rb.serializeModel({before.Workspace}), 'Workspace parity')
local bytes=rb.serializePlace(place)
assert(rb.deserializePlace(bytes).ServerScriptService.Greybox.Source == source)
fs.writeFile(main, bytes)
fs.writeFile('treasure/PERF-BUILD.json', serde.encode('json', {
 backup_sha256=serde.hash('sha256',original), canonical_sha256=serde.hash('sha256',bytes),
 compiled_O0_O1_O2=count, unrelated_sources_preserved=preserved,
 workspace_parity=true, s5_unmounted=true, live='NOT RUN'
},true))
print('PASS Lune source mount; byte-verified pre-perf backup;',count,'sources compile O0/O1/O2;',preserved,'unrelated sources preserved; S5 absent')
