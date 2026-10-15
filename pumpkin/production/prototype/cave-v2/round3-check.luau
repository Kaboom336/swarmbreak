local fs,rb,serde,luau=require('@lune/fs'),require('@lune/roblox'),require('@lune/serde'),require('@lune/luau')
local old=rb.deserializePlace(fs.readFile('prototype/cave-v2/round3-baseline.rbxl'))
local new=rb.deserializePlace(fs.readFile('prototype/cave-v2.rbxl'))
local function scripts(place)
 local result={}
 for _,p in place:GetDescendants() do if p:IsA('LuaSourceContainer') and p.Name~='CaveRouteData' then result[p.Name]=p.Source;luau.compile(p.Source) end end
 return result
end
local a,b=scripts(old),scripts(new)
for name,source in a do assert(b[name]==source,'script source changed: '..name) end
local function hooks(place)
 local result={}
 for _,p in place:GetDescendants() do if p:GetAttribute('Placeholder')==true then result[p.Name]=p:GetAttributes() end end
 return serde.encode('json',result)
end
assert(hooks(old)==hooks(new),'native hook attributes changed')
local l=new:GetService('Lighting');assert(math.abs(l.Brightness-2.3)<.0001 and math.abs(l.ExposureCompensation-.35)<.0001)
assert(l:FindFirstChild('CrystalBloom').Intensity>.6)
fs.writeFile('prototype/cave-v2/ROUND3-SCRIPT-CHECK.json',serde.encode('json',{native_hook_attributes_equal=true,gameplay_script_sources_equal=true,brightness=l.Brightness,exposure=l.ExposureCompensation,bloom=l:FindFirstChild('CrystalBloom').Intensity},true))
-- The reused checker writes its historical Round2 filename. Restore that
-- archived report after the caller copies the current report to Round3.
local archived=serde.decode('json',fs.readFile('prototype/cave-v2/ROUND2-EVIDENCE.json')).native_check
fs.writeFile('prototype/cave-v2/ROUND2-NATIVE-CHECK.json',serde.encode('json',archived,true))
print('PASS native gameplay scripts and hook attributes preserved; exposure and bloom saved')
