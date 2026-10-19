-- One authored grid, three palettes. Grid cells are 0.5 studs; front is +Z.
local M = {Voxel=0.5}
M.Palettes = {
	{c="C67C45", w="FFF0C2", k="101010", a="C67C45"},
	{c="E9B824", w="FFF1A0", k="101010", a="E9B824"},
	{c="40B9DC", w="D5F8FF", k="101010", a="*46FFFF"},
}
-- 11 wide x 5 deep x 12 high = 6 studs. Empty corners make an octagonal case.
function M.layers()
	local grid={}
	for y=1,12 do
		grid[y]={}
		for z=1,5 do grid[y][z]=table.create(11,".") end
	end
	local function box(key,x0,x1,y0,y1,z0,z1)
		for y=y0,y1 do for z=z0,z1 do for x=x0,x1 do grid[y][z][x]=key end end end
	end
	box("c",3,4,1,2,2,4); box("c",8,9,1,2,2,4)
	box("c",3,9,3,3,2,4); box("c",2,10,4,4,2,4)
	box("c",1,11,5,8,2,4); box("c",2,10,9,9,2,4)
	box("c",3,9,10,10,2,4)
	-- Dial projects one whole cell, making its rim readable from a three-quarter view.
	box("w",3,9,4,9,1,1); box("w",2,10,5,8,1,1)
	box("k",4,4,7,7,1,1); box("k",8,8,7,7,1,1)
	-- Angled north-east needle, kept above the face instead of bisecting it.
	box("a",7,7,9,9,1,1); box("a",6,7,8,8,1,1); box("a",6,6,7,7,1,1)
	box("c",5,7,5,5,1,1)
	-- Closed suspension loop with a one-cell hole.
	box("c",5,5,11,11,3,3); box("c",7,7,11,11,3,3)
	box("c",5,7,12,12,3,3)
	local layers={}
	for y=1,12 do
		local rows={}
		for z=1,5 do table.insert(rows,table.concat(grid[y][z])) end
		table.insert(layers,table.concat(rows,"\n"))
	end
	return layers
end
function M.create(build,mutation,origin)
	local model=build("CopperCompass",M.Voxel,M.layers(),assert(M.Palettes[mutation]),origin)
	for _,p in model:GetChildren() do
		if p:IsA("BasePart") then
			p.CanCollide=false; p.CanTouch=false; p.CanQuery=false
			local localCF=CFrame.new(origin):ToObjectSpace(p.CFrame)
			p:SetAttribute("Rest",localCF)
			if p.Name~="Root" and localCF.Position.Y<=1 then
				p:SetAttribute("Leg",localCF.Position.X<0 and -1 or 1)
			end
		end
	end
	return model
end
return M
