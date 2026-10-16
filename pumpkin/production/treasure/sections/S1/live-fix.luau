-- Preserve the saved Studio place; mount only this fix, then exercise runtime sources.
local fs, rb, luau, serde, process = require("@lune/fs"), require("@lune/roblox"), require("@lune/luau"), require("@lune/serde"), require("@lune/process")
local main = "slice-v2/prototype/guardian-greybox.rbxl"
local backup = "slice-v2/prototype/guardian-greybox.pre-s1live.rbxl"
if process.args[1] == "backup" then
 assert(not fs.isFile(backup), "preserve existing backup")
 local bytes = fs.readFile(main); rb.deserializePlace(bytes); fs.writeFile(backup, bytes)
 assert(fs.readFile(backup) == bytes); print("PASS byte-verified pre-s1live backup"); return
end
assert(fs.isFile(backup), "backup required before Rojo")
local before = rb.deserializePlace(fs.readFile(backup))
local place = rb.deserializePlace(fs.readFile(backup))
local built = rb.deserializePlace(fs.readFile("treasure/sections/S1/live-fix-rojo.rbxl"))
local function at(root, path) for _, key in string.split(path, ".") do root = assert(root:FindFirstChild(key), path) end; return root end
local allowed = {}
for _, path in {"ReplicatedStorage.MeadowV4.Builder", "ReplicatedStorage.MeadowV4.Section1", "ServerScriptService.KitSwap", "StarterPlayer.StarterPlayerScripts.TreasureCoreHud"} do
 at(place, path).Source = at(built, path).Source; allowed[path] = true
end
local compiled, preserved = 0, 0
for _, node in place:GetDescendants() do if node:IsA("LuaSourceContainer") then
 for level = 0, 2 do luau.compile(node.Source, {optimizationLevel=level}) end
 compiled += 1
 if not allowed[node:GetFullName()] then assert(node.Source == at(before, node:GetFullName()).Source, "unrelated source changed"); preserved += 1 end
end end
assert(rb.serializeModel({before.Workspace}) == rb.serializeModel({place.Workspace}), "Workspace changed")
local bytes = rb.serializePlace(place)
local function runtime(root, warnings)
 local cache = {}
 local function load(node)
  if cache[node] then return cache[node] end
  local env = {script=node, require=load, Vector3=rb.Vector3, Vector2=rb.Vector2, CFrame=rb.CFrame, Color3=rb.Color3, Enum=rb.Enum, Instance=rb.Instance, UDim2=rb.UDim2,
   warn=function(message) table.insert(warnings, message) end}
  cache[node] = luau.load(node.Source, {environment=env})(); return cache[node]
 end
 return load
end
local origins = {rb.Vector3.zero, rb.Vector3.new(0, 76, -360)}
-- Replay the saved pre-fix sources at the real Arena origin, not a scene proxy.
local oldWarnings={}
local oldOk,oldResult=pcall(function()
 return runtime(before,oldWarnings)(before.ReplicatedStorage.MeadowV4.Builder).build(rb.Instance.new("Folder"),origins[2])
end)
assert((not oldOk and tostring(oldResult):find("unsupported BedSoil")) or table.concat(oldWarnings,"\n"):find("unsupported BedSoil"),"saved source must reproduce reported failure")
print("PASS reproduced pre-fix unsupported BedSoil at live origin")
local snapshots = {}
for i, origin in origins do
 local warnings = {}; local load = runtime(place, warnings)
 local root = load(place.ReplicatedStorage.MeadowV4.Builder).build(rb.Instance.new("Folder"), origin)
 assert(#warnings == 0, table.concat(warnings, "\n"))
 local s = load(place.ReplicatedStorage.MeadowV4.Section1)
 assert(root:FindFirstChild("S1_BedSoil"), "section aborted")
 assert(root:FindFirstChild("OutsmartCorner"), "Outsmart absent")
 assert(s.ground(root,-45,146,13.5,5.5) ~= nil, "live bed support")
 local snapshot = {}
 for _, p in root:GetDescendants() do if p:IsA("BasePart") then
  table.insert(snapshot, {name=p.Name, cf=rb.CFrame.new(-origin)*p.CFrame, size=p.Size, collide=p.CanCollide, query=p.CanQuery, tags=table.concat(p:GetTags(),",")})
 end end
 snapshots[i] = snapshot
 local spawned = 0
 s.spawnKits(root, {
  spawn=function(_, _, cf, size)
   spawned += 1
   if spawned <= #s.kits then
    local g = s.kits[spawned]
    assert(math.abs(cf.Position.X-origin.X-g.x)<.001 and math.abs(cf.Position.Z-origin.Z-g.z)<.001, "kit origin")
    assert(math.abs(cf.Position.Y-origin.Y-s.ground(root,g.x,g.z,g.size.X,g.size.Z)-(g.lift or 0))<.001, "kit support")
   end
   local m=rb.Instance.new("Model");local p=rb.Instance.new("Part");p.Size=size;p.CFrame=cf;p.CanCollide=false;p.Parent=m;return m
  end,
  fit=function() return true end,
 })
 assert(root:GetAttribute("S1KitsLoaded") == #s.kits, "all kit placements")
 print("PASS runtime source build + full footprint support + late kit placement at", origin)
end
assert(#snapshots[1] == #snapshots[2], "origin inventory")
local oldZero=runtime(before,{})(before.ReplicatedStorage.MeadowV4.Builder).build(rb.Instance.new("Folder"),rb.Vector3.zero)
local physical={}
for _,p in oldZero:GetDescendants() do if p:IsA("BasePart") and (p.CanCollide or p:GetAttribute("WalkableLaneFloor")) then
 table.insert(physical,p)
end end
local index=0
for _,p in snapshots[1] do if p.collide then
 index+=1;local q=physical[index]
 assert(q and q.Name==p.name and q.Size==p.size and q.CFrame==p.cf and q.CanQuery==p.query and table.concat(q:GetTags(),",")==p.tags,"authored physical geometry changed")
end end
assert(index==#physical,"physical inventory changed")
for i,a in snapshots[1] do
 local b=snapshots[2][i];assert(a.name==b.name and a.size==b.size and a.collide==b.collide and a.query==b.query and a.tags==b.tags,"origin parity")
 local ac,bc={a.cf:GetComponents()},{b.cf:GetComponents()};for j=1,12 do assert(math.abs(ac[j]-bc[j])<.001,"origin transform") end
end
-- Existing/future dressing failures must not abort the island or following sections.
local folder=place.ReplicatedStorage.MeadowV4
folder.Section1.Source='error("injected Section1 failure")'
folder.Outsmart.Source='error("injected Outsmart failure")'
local future=rb.Instance.new("ModuleScript");future.Name="Section2";future.Source='error("injected future failure")';future.Parent=folder
local warnings={};local root=runtime(place,warnings)(folder.Builder).build(rb.Instance.new("Folder"),origins[2])
assert(root.Parent and #root:GetChildren()>100 and #warnings==3,"dressing failure isolation")
rb.deserializePlace(bytes);fs.writeFile(main,bytes)
fs.writeFile("treasure/sections/S1/LIVE-FIX-AUDIT.json",serde.encode("json",{status="PASS",compiled_O0_O1_O2=compiled,unrelated_sources_preserved=preserved,workspace_byte_equal=true,physical_geometry_and_tags_preserved=true,pre_fix_failure_reproduced=true,origins={{0,0,0},{0,76,-360}},full_footprint_support=true,late_kit_placement=true,injected_dressing_failures=3,Studio_runtime="UNKNOWN",kit_mesh_loading="UNKNOWN; placement stub only"},true))
print("PASS origin parity; Section1/Outsmart/future failure isolation;",compiled,"scripts compile;",preserved,"unrelated sources preserved")
