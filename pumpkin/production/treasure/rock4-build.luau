-- Retain the inspected Lune-only source mount and native manifest exporter.
local fs,luau=require('@lune/fs'),require('@lune/luau')
local s=fs.readFile('treasure/rock3-build.luau'):gsub('rock3','rock4'):gsub('ZRock3','ZRock4'):gsub('Rock3Plan','Rock4Plan')
s=s:gsub("assert%(#warnings==0,serde.encode%('json',warnings%)%)",function(t)return t.."\nif mode~='before' then load(p.ReplicatedStorage.MeadowV4.ZRock4).hideReplaced(model) end"end)
luau.load(s,{environment=getfenv(),injectGlobals=true})()
