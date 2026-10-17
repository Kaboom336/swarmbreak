-- Run the unchanged cave checker against its own mounted loader version.
-- Shared on-disk KitLibrary was changed by Meadow after this cave was built.
local fs,rb,luau=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau')
local baseline=rb.deserializePlace(fs.readFile('prototype/cave-v2.pre-c3.rbxl'))
local final=rb.deserializePlace(fs.readFile('prototype/cave-v2.rbxl'))
assert(final.ServerScriptService.KitLibrary.Source==baseline.ServerScriptService.KitLibrary.Source,'C3 changed loader')
local proxy=table.clone(fs)
proxy.readFile=function(path)
 if path=='prototype/kits/KitLibrary.luau'then return final.ServerScriptService.KitLibrary.Source end
 return fs.readFile(path)
end
local originalRequire=require
local serde=require('@lune/serde')
local mode=require('@lune/process').args[1]or'8'
fs.writeFile('treasure/cave-sections/C3/OFFLINE-INPUT-'..mode..'.json',serde.encode('json',{
 place_sha256=serde.hash('sha256',fs.readFile('prototype/cave-v2.rbxl')),
 loader_sha256=serde.hash('sha256',final.ServerScriptService.KitLibrary.Source),
 working_tree_loader_differs=final.ServerScriptService.KitLibrary.Source~=fs.readFile('prototype/kits/KitLibrary.luau'),
 checker_sha256=serde.hash('sha256',fs.readFile('prototype/cave-v2/studio-check.luau')),
 mode=mode,expected_loader='unchanged pre-C3 mounted cave loader',test_assertions_changed=false},true))
local env=table.clone(getfenv())
env.require=function(path)
 if path=='@lune/fs'then return proxy end
 if path=='../meadow-v4/OfflineRay'then return originalRequire('../../../prototype/meadow-v4/OfflineRay')end
 return originalRequire(path)
end
print('SOURCE-AWARE: unchanged studio-check; expected KitLibrary read uses exact pre-C3 mounted version, not Meadow working-tree version')
luau.load(fs.readFile('prototype/cave-v2/studio-check.luau'),{environment=env,injectGlobals=true})()
