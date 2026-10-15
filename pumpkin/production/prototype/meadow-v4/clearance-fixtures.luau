-- Positive and negative controls for the analytic ray provider/shared runner.
local rb=require("@lune/roblox")
local Ray=require("./OfflineRay")
local C=require("./Clearance")
local V=rb.Vector3
local function block(model,name,size,cf,role,wedge)
	local p=rb.Instance.new(if wedge then "WedgePart" else "Part")
	p.Name,p.Size,p.CFrame=name,size,cf
	p.Anchored,p.CanCollide,p.CanQuery=true,true,true
	if not wedge then p.Shape=rb.Enum.PartType.Block end
	p:SetAttribute("SurfaceRole",role or "Floor")
	p.Parent=model
	return p
end
local function expect(model,position,message)
	local ok,why=pcall(C.resolve,position,false,3,Ray.new(model),true,V)
	assert(if message then not ok and tostring(why):find(message,1,true) else ok,tostring(why))
end
local model=rb.Instance.new("Model")
block(model,"floor",V.new(30,2,30),rb.CFrame.new(0,-1,0))
expect(model,V.new(0,3,0)) -- Includes negative-zero grid coordinate.
expect(model,V.new(0,4,0),"authored Y")
local obstacle=block(model,"column",V.new(1,4,1),rb.CFrame.new(2,2,0))
expect(model,V.new(0,3,0),"clearance cliff/wall")
obstacle:Destroy()
local ceiling=block(model,"ceiling",V.new(10,1,10),rb.CFrame.new(0,7,0),"Cover")
expect(model,V.new(0,3,0),"no walkable center")
-- Above the down-ray origin but inside the runner's upward head ray.
ceiling.CFrame=rb.CFrame.new(0,13,0)
-- Separate provider control ensures the upward ray hits the lower face.
local hit=Ray.new(model)(V.new(0,10,0),V.new(0,6,0))
assert(hit and hit.Normal.Y==-1 and math.abs(hit.Position.Y-12.5)<0.001,"up ray underside")
ceiling:Destroy()
model:FindFirstChild("floor").Size=V.new(4,2,30)
expect(model,V.new(0,3,0),"floor/cover")
model:Destroy()
local ramp=rb.Instance.new("Model")
block(ramp,"wedge",V.new(18,4,12),rb.CFrame.new(30,2,-20),"Floor",true)
block(ramp,"base",V.new(18,2,12),rb.CFrame.new(30,-1,-20))
local ray=Ray.new(ramp)
hit=ray(V.new(30,14,-17),V.new(0,-70,0))
assert(hit and math.abs(hit.Position.Y-3)<0.001 and math.abs(hit.Normal.Y-3/math.sqrt(10))<0.001,"wedge slope/normal")
expect(ramp,V.new(30,5,-20))
-- Rotate/translate the fixture: intersection must use built CFrame, not AABB.
for _,p in ramp:GetChildren() do p.CFrame=rb.CFrame.new(5,6,7)*rb.CFrame.Angles(0,math.pi/3,0)*p.CFrame end
local position=(rb.CFrame.new(5,6,7)*rb.CFrame.Angles(0,math.pi/3,0)):PointToWorldSpace(V.new(30,5,-20))
expect(ramp,position)
return true
