-- Execute the real model factory using Lune Roblox types; export these exact parts.
local fs,rb,luau,serde=require("@lune/fs"),require("@lune/roblox"),require("@lune/luau"),require("@lune/serde")
return function()
	local path="slice-v2/base/earners/"
	local env={Instance=rb.Instance,Vector3=rb.Vector3,Color3=rb.Color3,CFrame=rb.CFrame,Enum=rb.Enum}
	local function load(name) return luau.load(fs.readFile(path..name..".luau"),{environment=env,injectGlobals=true})() end
	local build=load("VoxelKit"); local compass=load("CopperCompass"); local pose=load("Walk")
	local assertions=0
	local function check(ok,why) assert(ok,why); assertions+=1 end
	local expected,baseline,exports=nil,nil,{}
	for mutation=1,3 do
		local m=compass.create(build,mutation,rb.Vector3.zero)
		local parts=m:GetChildren(); check(#parts<250,"model part budget includes root")
		expected=expected or #parts; check(#parts==expected,"mutation same part count")
		local rows={}; local legs=0; local neon=0; local eyes=0
		for i,p in parts do
			check(p:IsA("BasePart") and p.Anchored and not p.CanCollide,"all anchored/non-colliding")
			check(not p.CanTouch and not p.CanQuery,"visual parts cannot intercept gameplay")
			if baseline then check(p.Size==baseline[i].Size and p.CFrame==baseline[i].CFrame,"recolour preserves exact geometry") end
			if p:GetAttribute("Leg") then legs+=1 end
			if p.Material==rb.Enum.Material.Neon then neon+=1 end
			if p.Transparency==0 then
				check(p.TopSurface==rb.Enum.SurfaceType.Studs,"top studs")
				if p.Color==rb.Color3.fromHex("101010") then
					eyes+=1; check(p.Size==rb.Vector3.new(0.5,0.5,0.5),"1x1 grid black eyes")
				end
				table.insert(rows,{position={p.CFrame.X,p.CFrame.Y,p.CFrame.Z},size={p.Size.X,p.Size.Y,p.Size.Z},color={p.Color.R,p.Color.G,p.Color.B},neon=p.Material==rb.Enum.Material.Neon,leg=p:GetAttribute("Leg")})
			end
		end
		check(legs==4,"two separate two-cell legs")
		check(eyes==2,"two square eyes")
		check((mutation==3 and neon>0) or (mutation~=3 and neon==0),"Diamond-only neon accent")
		baseline=baseline or parts; exports[mutation]=rows
	end
	local a,b=pose(0,true,-1); local c,d=pose(0.65,true,-1)
	check(a~=c and b~=d,"two walk frames differ")
	check(pose(1,false,-1)==0 and pose(1,true,nil)==0,"idle and body do not bob")
	fs.writeFile(path.."parts.json",serde.encode("json",exports,true))
	local report=string.format("PASS %d earner assertions; %d model parts per mutation, plus 1 authority Part; height 6 studs.\nClient replication, 40-stud engine readability, Studio: NOT RUN.\n",assertions,expected)
	fs.writeFile(path.."CHECK-RESULT.txt",report); print(report)
	return assertions
end
