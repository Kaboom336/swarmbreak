-- Execute the existing origin/late-kit/failure-isolation contracts on the final place.
local fs,luau=require('@lune/fs'),require('@lune/luau')
local source=fs.readFile('treasure/sections/S2/contracts.luau')
source=source:gsub("local cache,warnings=", "assert(p.ReplicatedStorage.MeadowV4.Section6.Source==fs.readFile('prototype/meadow-v4/Section6.luau'),'mounted S6 source parity')\nlocal cache,warnings=")
source=source:gsub("q:GetAttribute%('Section'%)=='S2'", "(q:GetAttribute('Section')=='S2' or q:GetAttribute('Section')=='S6')")
source=source:gsub('treasure/sections/S2/CONTRACTS.json','treasure/sections/S6/CONTRACTS.json')
luau.load(source,{environment=getfenv(),injectGlobals=true})()
