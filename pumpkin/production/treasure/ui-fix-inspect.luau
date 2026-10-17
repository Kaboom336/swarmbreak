local fs, rb, serde = require('@lune/fs'), require('@lune/roblox'), require('@lune/serde')
local main = 'slice-v2/prototype/guardian-greybox.rbxl'
local backup = 'slice-v2/prototype/guardian-greybox.pre-uifix.rbxl'
local bytes = fs.readFile(main)
if not fs.isFile(backup) then fs.writeFile(backup, bytes) end
assert(fs.readFile(backup) == bytes, 'existing backup differs; preserve it')
local p = rb.deserializePlace(bytes)
for _, pair in {
 {p.ReplicatedStorage.UIStyle,'prototype/core/UIStyle.luau'},
 {p.ReplicatedStorage.MeadowV4.Section7,'prototype/meadow-v4/Section7.luau'},
 {p.StarterPlayer.StarterPlayerScripts.Greybox,'slice-v2/prototype/Greybox.client.luau'},
 {p.StarterPlayer.StarterPlayerScripts.HomeArt,'slice-v2/prototype/HomeArt.client.luau'},
 {p.StarterPlayer.StarterPlayerScripts.TreasureUIWorld,'prototype/core/UIWorld.client.luau'},
} do print(pair[1]:GetFullName(), 'disk exact', pair[1].Source == fs.readFile(pair[2])) end
for _, node in p:GetDescendants() do
 if node:IsA('LuaSourceContainer') and #node.Source < 150000 then
  local lines=string.split(node.Source,'\n')
  for i,line in lines do
   if line:find('Golden Acorn',1,true) or line:find('ExitBoard',1,true) or line:find('BillboardGui',1,true) and node.Name=='HomeArt' then
    print(node:GetFullName(),i,line)
   end
  end
 end
end
print('BACKUP', serde.hash('sha256', bytes))
