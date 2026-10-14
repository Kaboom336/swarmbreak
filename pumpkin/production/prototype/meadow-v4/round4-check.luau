local fs=require('@lune/fs')
local rb=require('@lune/roblox')
local serde=require('@lune/serde')
local function sources(path)
 local place=rb.deserializePlace(fs.readFile(path))
 local result={}
 local count=0
 for _,item in place:GetDescendants() do
  if item:IsA('LuaSourceContainer') and item.Name~='Data' then
   local key=item:GetFullName()
   result[key]=item.Source
   count+=1
  end
 end
 return result,count
end
local a,n=sources('prototype/meadow-v4/round4-baseline.rbxl')
local b,m=sources('prototype/meadow-v4.rbxl')
assert(n==m,'script counts differ')
for key,source in a do assert(b[key]==source,'changed script source '..key) end
local report={state='PASS',non_generated_source_count=n,byte_equal=true}
fs.writeFile('treasure/map-v4/ROUND4-SCRIPT-PRESERVATION.json',serde.encode('json',report,true))
print('PASS byte-equal non-generated script Sources: '..n)
