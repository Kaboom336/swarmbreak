-- Existing origin, failure-isolation and coordinator contracts, with S7 included.
local fs,luau=require('@lune/fs'),require('@lune/luau')
local source=fs.readFile('treasure/sections/S2/contracts.luau')
source=source:gsub("local cache,warnings=", "assert(p.ReplicatedStorage.MeadowV4.Section7.Source==fs.readFile('prototype/meadow-v4/Section7.luau'),'mounted S7 parity')\nlocal cache,warnings=")
source=source:gsub("q:GetAttribute%('Section'%)=='S2'", "(q:GetAttribute('Section')=='S2' or q:GetAttribute('Section')=='S7')")
source=source:gsub('treasure/sections/S2/CONTRACTS.json','treasure/sections/S7/CONTRACTS.json')
luau.load(source,{environment=getfenv(),injectGlobals=true})()
