local fs,rb,luau,serde=require("@lune/fs"),require("@lune/roblox"),require("@lune/luau"),require("@lune/serde")
local result={status="PASS",places={}}
for _,path in {"prototype/guardian-greybox.rbxl","prototype/meadow-v4.rbxl","prototype/cave-v2.rbxl"} do
	local old=rb.deserializePlace(fs.readFile(path:gsub("%.rbxl$",".pre-kits.rbxl")))
	local new=rb.deserializePlace(fs.readFile(path))
	local a,b=old.Workspace:GetDescendants(),new.Workspace:GetDescendants()
	local function compareSources(before,after,pathName)
		local buckets,seen={},{}
		for _,node in after:GetChildren() do
			buckets[node.Name]=buckets[node.Name] or {}
			table.insert(buckets[node.Name],node)
		end
		for _,node in before:GetChildren() do
			local name=pathName.."."..node.Name
			seen[node.Name]=(seen[node.Name] or 0)+1
			local other=assert(buckets[node.Name] and buckets[node.Name][seen[node.Name]],"missing original "..name)
			if name==".ReplicatedStorage.TreasureCore" then continue end
			if node:IsA("LuaSourceContainer") and node.Name~="TreasureCoreHud"
				and node.Name~="CoreLoopTestRunner" then
				assert(node.Source==other.Source,"unrelated source changed "..name)
			end
			compareSources(node,other,name)
		end
	end
	compareSources(old,new,"")
	assert(#a==#b,"workspace count changed")
	local names,properties={},0
	for i,node in a do
		local other=b[i]
		assert(node.Name==other.Name and node.ClassName==other.ClassName,"workspace hierarchy changed")
		if node:IsA("BasePart") then
			names[node.Name]=true
			for _,property in {"CFrame","Size","Color","Material","Transparency","CanCollide","CanTouch","CanQuery","Anchored"} do
				assert(node[property]==other[property],path.." changed "..node.Name.."."..property)
				properties+=1
			end
		end
	end
	for _,node in new:GetDescendants() do
		if node:IsA("LuaSourceContainer") then luau.compile(node.Source) end
	end
	local core=new.ReplicatedStorage.TreasureCore
	for _,name in {"Config","Domain","Profiles","Runtime","Service","Tests","MockStore","StudioStoreTest","Feel"} do
		assert(core[name].Source==fs.readFile("prototype/core/"..name..".luau"),"stale core "..name)
	end
	for _,name in {"ProfileStore","Shake","Spring","Signal","Trove"} do
		assert(core.Packages[name].Source==fs.readFile("prototype/core/Packages/"..name..".luau"),"stale package "..name)
	end
	local sorted={}
	for name in names do table.insert(sorted,name) end
	table.sort(sorted)
	table.insert(result.places,{file=path,workspaceNodes=#a,propertiesUnchanged=properties,propNames=sorted})
end
assert(fs.readFile("prototype/guardian-greybox.rbxl")==fs.readFile("slice-v2/prototype/guardian-greybox.rbxl"))
fs.writeFile("prototype/KITS-OFFLINE.json",serde.encode("json",result,true))
print("PASS latest binary source mounts, all scripts compiled, unchanged Workspace geometry/collision, canonical parity")
