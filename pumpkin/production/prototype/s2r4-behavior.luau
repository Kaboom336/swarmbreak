-- Existing policy/domain/coordinator/reset contracts, unedited. Their historical
-- pre-Studio-prep artifact comparison is superseded by the immediate R4 audit.
local fs,luau=require('@lune/fs'),require('@lune/luau')
local src=fs.readFile('prototype/studio-pass-check.luau')
src=src:sub(1,assert(src:find('local old = rb.deserializePlace',1,true))-1)
-- Production added OutsmartTest after this historical fixture was written.
src=src:gsub('#result.tests == 8 and resets == 9','#result.tests == 9 and resets == 10')
src=src:gsub('#starts == 4','#starts == 5')
src=src:gsub('starts%[4%] == "GreyboxTrapTest"','starts[4] == "GreyboxTrapTest" and starts[5] == "OutsmartTest"')
src=src:gsub('result.tests%[8%].name == "TunnelTest"','result.tests[8].name == "TunnelTest" and result.tests[9].name == "OutsmartTest"')
src=src:gsub('%(reject and 0 or 8%)','(reject and 0 or 9)')
src=src:gsub('arena = arena, rules = rules','arena = arena, rules = rules')
-- resetPass now removes temporary Outsmart fixtures from the existing map.
src=src:gsub('arena.tunnel.disconnect = function%(%)', 'arena.model = {FindFirstChild=function() return nil end}\narena.tunnel.disconnect = function()')
local env=table.clone(getfenv());local nativeRequire=require
env.require=function(path) return nativeRequire(path) end
luau.load(src,{environment=env,injectGlobals=true})()
