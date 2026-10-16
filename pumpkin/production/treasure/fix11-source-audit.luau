local fs,rb=require('@lune/fs'),require('@lune/roblox')
local old=rb.deserializePlace(fs.readFile('treasure/fix10-rojo.rbxl'))
local live=rb.deserializePlace(fs.readFile('slice-v2/prototype/guardian-greybox.pre-fix11.rbxl'))
local function at(root,path) for _,k in string.split(path,'.') do root=assert(root:FindFirstChild(k),path) end;return root end
for _,path in {'ServerScriptService.OutsmartTestRunner','ServerScriptService.Greybox','ServerScriptService.GreyboxArena','ServerScriptService.GreyboxLoopTestRunner','ReplicatedStorage.MeadowV4.Outsmart','ReplicatedStorage.MeadowV4.Section1'} do
 local a,b=at(old,path).Source,at(live,path).Source
 print(path,a==b and 'same as fix10' or 'CHANGED SINCE FIX10')
 if a~=b then fs.writeFile('treasure/fix11-live-'..path:match('[^.]+$')..'.txt',b) end
end
