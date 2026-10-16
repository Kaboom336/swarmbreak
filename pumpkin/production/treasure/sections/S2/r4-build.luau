-- Reuse the shipped compiler/export pipeline; R4 permits only explicit exterior hill edits.
local fs,luau=require('@lune/fs'),require('@lune/luau')
local src=fs.readFile('treasure/sections/S2/build.luau'):gsub('r3','r4'):gsub('r%[23%]','r[234]')
src=src:gsub('Vector4','Vector3'):gsub('Color4','Color3')
src=src:gsub('physics_floor_tags_equal=true','all_non_hill_physics_floor_tags_equal=true')
src=src:gsub('physical/floor/tag parity','non-hill physical/floor/tag parity; exact hill audit required')
-- Exterior solid identity/field preservation is independently checked by r4-audit.py.
-- All non-hill physical parts still participate in the original exact signature gate.
src=src:gsub("if r2 and not p:GetAttribute%('WalkableLaneFloor'%) and table.find", "if r2 and not p:GetAttribute('WalkableLaneFloor') and table.find")
src=src:gsub("table.insert%(physical,serde.encode%('json',signature%)%)", "if not (r.name=='TunnelHillEarth' or r.name=='TunnelHillTurf') then table.insert(physical,serde.encode('json',signature)) end")
luau.load(src,{environment=getfenv(),injectGlobals=true})()
