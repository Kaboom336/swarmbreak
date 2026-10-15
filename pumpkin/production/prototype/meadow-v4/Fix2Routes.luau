-- The route centerlines are also the authoring source for the physical lanes.
-- Preserve the 18-stud deck and fill bend seams; carve earth below its low edge.
local F = {}
function F.waypoints(routes)
	local out = {}
	for name, route in routes do
		local points = {table.clone(route[1])}
		for i=2,#route do
			local a,b=route[i-1],route[i]
			local length=math.sqrt((b.x-a.x)^2+(b.y-a.y)^2+(b.z-a.z)^2)
			local steps=math.max(1,math.ceil(length/3))
			for j=1,steps-1 do
				local t=j/steps
				table.insert(points,{x=a.x+(b.x-a.x)*t,y=a.y+(b.y-a.y)*t,z=a.z+(b.z-a.z)*t,kind="Walk"})
			end
			table.insert(points,table.clone(b))
		end
		out[name]=points
	end
	return out
end
function F.transform(data, routes)
	local out, lanes = {}, {}
	local styles={}
	for _,p in data do
		local name=p.name:match("^(.-)%d+$")
		if name and routes[name] then styles[p.name]=p;styles[name]=styles[name] or p end
	end
	for name, route in routes do
		if not name:match("^tunnel") and not name:match("^ravine") and not name:match("^jump") then
			for i = 2, #route do
				local a, b = route[i-1], route[i]
				local dx, dz, dy = b.x-a.x, -(b.z-a.z), b.y-a.y
				local run = math.sqrt(dx*dx+dz*dz)
				if run < 0.001 then continue end
				local length = math.sqrt(run*run+dy*dy)
				local ux, uz, c, s = dx/run, dz/run, run/length, dy/length
				local nx, ny, nz = -ux*s, c, -uz*s
				local style=styles[name..(i-2)] or styles[name]
				local p = {name="Fix2Lane_"..name.."_"..(i-1),category="lane",shape="Block",
					position={(a.x+b.x)/2-nx*0.6,(a.y+b.y)/2-ny*0.6+0.12,-(a.z+b.z)/2-nz*0.6},
					size={18,1.2,length+(if dy==0 and ((i==#route and (name=="spiral" or name=="fork_link" or name=="shelf")) or (name=="shelf_link" and i==2)) then 8 else 2)},rotation={uz,nx,ux*c,0,ny,s,-ux,nz,uz*c},
					material=if style then style.material else "Grass",color=if style then table.clone(style.color) else {99,172,44},collidable=true,transparency=0}
				table.insert(lanes,p)
			end
			-- Shared courts at flat route endpoints keep turning bodies supported;
			-- narrow longitudinal extensions alone leave outer L-junction corners.
			for _,i in {1,#route} do
				local p=route[i]
				local neighbour=route[if i==1 then 2 else #route-1]
				if math.abs(p.y-neighbour.y)<0.00001 then
					local style=styles[name]
					table.insert(lanes,{name="Fix2Junction_"..name.."_"..i,category="lane",shape="Block",
						position={p.x,p.y-0.48,-p.z},size={18,1.2,18},rotation={1,0,0,0,1,0,0,0,1},
						material=if style then style.material else "Grass",color=if style then table.clone(style.color) else {99,172,44},collidable=true,transparency=0})
				end
			end
		end
	end
	for _, source in data do
		-- Replace old route slabs rather than stack inconsistent sloped surfaces.
		local routeName = source.name:match("^(.-)%d+$")
		if routeName and routes[routeName] and not routeName:match("^tunnel") and not routeName:match("^ravine") and not routeName:match("^jump") then continue end
		local p = source
		if source.name == "SolidMountainStone" then
			local top = source.position[2]+source.size[2]/2
			for _, lane in lanes do
				local r, v = lane.rotation,lane.position
				local dx,dz = source.position[1]-v[1],source.position[3]-v[3]
				local cross = dx*r[1]+dz*r[7]
				local along = (dx*r[3]+dz*r[9])/r[5]
				local extent = (math.abs(r[1])+math.abs(r[7]))*2
				local endExtent = (math.abs(r[3])+math.abs(r[9]))*2/r[5]
				if math.abs(cross)<=9+extent and math.abs(along)<=lane.size[3]/2+endExtent then
					-- Entire column top below the lowest lane surface over its footprint.
					local floor = v[2]+0.6/r[5]-(r[2]*dx+r[8]*dz)/r[5]
					local low = floor-2*(math.abs(r[2])+math.abs(r[8]))/r[5]-1.4
					top = math.min(top,low)
				end
			end
			local bottom = source.position[2]-source.size[2]/2
			if top<=bottom then continue end
			if top<source.position[2]+source.size[2]/2 then
				p=table.clone(source)
				p.size={source.size[1],top-bottom,source.size[3]}
				p.position={source.position[1],(top+bottom)/2,source.position[3]}
			end
		end
		table.insert(out,p)
	end
	for _, lane in lanes do
		local r,v=lane.rotation,lane.position
		if math.abs(r[6])<0.00001 then table.insert(out,lane);continue end
		-- Upright wedges have vertical end faces. Tilted thin slabs expose their
		-- sloping end caps above neighbouring floors, which fail walking normals.
		local run=lane.size[3]*r[5]
		local rise=math.abs(lane.size[3]*r[6])
		local ux,uz=r[3]/r[5],r[9]/r[5]
		local sign=if r[6]>0 then 1 else -1
		local center={v[1]+r[2]*0.6,v[2]+r[5]*0.6,v[3]+r[8]*0.6}
		local yaw={uz*sign,0,ux*sign,0,1,0,-ux*sign,0,uz*sign}
		if rise<0.05 then
			-- Engine minimum size would inflate a near-flat wedge. A full-depth
			-- level slab stays within 0.025 studs of this tiny authored grade.
			local flat=table.clone(lane)
			flat.size,flat.rotation,flat.position={18,1.2,run},yaw,{center[1],center[2]-0.6,center[3]}
			table.insert(out,flat)
			continue
		end
		local wedge=table.clone(lane)
		wedge.shape,wedge.size,wedge.rotation,wedge.position="Wedge",{18,rise,run},yaw,center
		table.insert(out,wedge)
		local base=table.clone(lane)
		base.name=lane.name.."_Base"
		base.size,base.rotation,base.position={18,1.2,run},yaw,{center[1],center[2]-rise/2-0.6,center[3]}
		table.insert(out,base)
	end
	return out
end
return F
