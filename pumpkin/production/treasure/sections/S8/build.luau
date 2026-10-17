local fs,luau=require('@lune/fs'),require('@lune/luau')
local source=fs.readFile('treasure/sections/S7/build.luau'):gsub('S7','S8'):gsub('Section7','Section8')
source=source:gsub('pre%-s7','pre-s8')
luau.load(source,{environment=getfenv(),injectGlobals=true})()
local mode=require('@lune/process').args[1]
if mode=='r1' or mode=='r2' then fs.writeFile('treasure/sections/S8/MOUNT-'..mode..'.json',fs.readFile('treasure/sections/S8/AUDIT-'..mode..'.json')) end
