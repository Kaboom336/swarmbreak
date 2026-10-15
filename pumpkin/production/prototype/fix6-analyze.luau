-- Inspect native landing hits for the exact failed sockets from the kits2 sweep.
local fs,rb,luau,serde=require("@lune/fs"),require("@lune/roblox"),require("@lune/luau"),require("@lune/serde")
local V=rb.Vector3
local place=rb.deserializePlace(fs.readFile("slice-v2/prototype/guardian-greybox.pre-fix6.rbxl"))
local cache={}
local function load(n)
 if cache[n] then return cache[n] end
 cache[n]=luau.load(n.Source,{environment={script=n,require=load,Instance=rb.Instance,Vector3=V,CFrame=rb.CFrame,Color3=rb.Color3,Enum=rb.Enum}})()
 return cache[n]
end
local folder=place.ReplicatedStorage.MeadowV4
local model=load(folder.Builder).build(rb.Instance.new("Folder"),V.zero)
local join=model:FindFirstChild("TunnelValleyJoin")
print("TunnelValleyJoin",join:GetAttribute("MeadowV4Category"),tostring(join.Size),tostring(join.CFrame),join.CanCollide)
local ray=require("./meadow-v4/OfflineRay").new(model,nil,2)
local report=serde.decode("json",fs.readFile("prototype/FIX6-DROPS-before-join.json"))
assert(report.samples==31824 and #report.failures==269,"expected pre-connector sweep")
local counts,examples={},{}
for _,f in report.failures do
 local p=V.new(unpack(f.position));local h=ray(p+V.new(0,8.25,0),V.new(0,-10.45,0))
 local name=h and h.Instance.Name or "NONE"
 local key=name.." tag="..tostring(h and h.Instance:HasTag("AuthoredLaneFloor")).." delta="..string.format("%.3f",h and h.Position.Y-p.Y or 999)
 counts[key]=(counts[key] or 0)+1
 if not examples[key] then examples[key]=f end
end
local evidence=serde.encode("json",{nativeLandingCounts=counts,examples=examples,source="pre-fix6 backup native geometry; failed sockets from kits2 sweep"},true)
fs.writeFile("prototype/FIX6-NATIVE-LANDINGS.json",evidence)
print(evidence)
local fixed=rb.deserializePlace(fs.readFile("slice-v2/prototype/guardian-greybox.rbxl"))
local fixedModel=load(fixed.ReplicatedStorage.MeadowV4.Builder).build(rb.Instance.new("Folder"),V.zero)
local fixedRay=require("./meadow-v4/OfflineRay").new(fixedModel,nil,2)
for _,f in report.failures do
 local p=V.new(unpack(f.position));local h=fixedRay(p+V.new(0,8.25,0),V.new(0,-10.45,0))
 assert(h and h.Instance:HasTag("AuthoredLaneFloor") and h.Instance:GetAttribute("WalkableLaneFloor")==true
  and math.abs(h.Position.Y-p.Y)<0.1,"failed socket still unmarked: "..f.label)
end
print("PASS all 269 original failed sockets now hit marked authored floors at the same Y")
