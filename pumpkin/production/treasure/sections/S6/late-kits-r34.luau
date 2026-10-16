-- Reuse the existing late-kit assertions for the S6 fitted envelopes.
local fs,luau=require('@lune/fs'),require('@lune/luau')
local src=fs.readFile('treasure/sections/S5/late-kits-r34.luau'):gsub('S5','S6'):gsub('Section5','Section6')
src=src:gsub("'S6_RockAnchor'..count",function() return "'S6_VisibleRockAnchor'..g.id:match('%d+')" end)
luau.load(src,{environment=getfenv(),injectGlobals=true})()
