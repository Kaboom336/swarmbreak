local fs,rb=require('@lune/fs'),require('@lune/roblox')
local p=rb.deserializePlace(fs.readFile('slice-v2/prototype/guardian-greybox.pre-fix12.rbxl'))
print('Saved OutsmartTestFailureJSON:',p.ServerScriptService:GetAttribute('OutsmartTestFailureJSON'))
for _,pair in {{p.ReplicatedStorage.GreyboxTraps,'Traps.luau'},{p.ServerScriptService.OutsmartTestRunner,'OutsmartTest.luau'},{p.ServerScriptService.Greybox,'Greybox.server.luau'},{p.ServerScriptService.GreyboxArena,'Arena.luau'}} do
 print(pair[2],pair[1].Source==fs.readFile('slice-v2/prototype/'..pair[2]) and 'source matches saved place' or 'DIFFERS from saved place')
end
