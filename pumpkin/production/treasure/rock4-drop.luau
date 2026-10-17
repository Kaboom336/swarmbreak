local fs,luau=require('@lune/fs'),require('@lune/luau')
local s=fs.readFile('treasure/rock3-drop.luau'):gsub('treasure/rock3/','treasure/rock4/')
s=s:gsub('load%(place.ReplicatedStorage.MeadowV4.ZRockShells%).spawnKits%(model,kit%)',function(t)return t..'\\nload(place.ReplicatedStorage.MeadowV4.ZRock4).spawnKits(model,kit)'end)
local env=table.clone(getfenv());local nativeRequire=require
env.require=function(p)if p=='../prototype/meadow-v4/OfflineRay'then return nativeRequire('../prototype/meadow-v4/OfflineRay')end;return nativeRequire(p)end
luau.load(s,{environment=env,injectGlobals=true})()
