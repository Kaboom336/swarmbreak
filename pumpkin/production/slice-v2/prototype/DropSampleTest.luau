-- Studio raycasts over the loaded place, AFTER KitSwap finishes; no offline proxy.
local SSS = game:GetService("ServerScriptService")
local RS = game:GetService("ReplicatedStorage")
local Sample = {}
function Sample.run(arena, Arena)
	local deadline = os.clock() + 120
	while arena.v4:GetAttribute("KitSwapVersion") == nil do
		assert(os.clock() < deadline, "KitSwap not complete >120s; live sample refused")
		task.wait(0.1)
	end
	local n = SSS:GetAttribute("DropSampleTestN") or 8
	assert(type(n) == "number" and n % 1 == 0 and n >= 2 and n <= 64, "DropSampleTestN must be integer 2..64")
	-- Refresh the allowlist AFTER all asynchronous kit placements.
	arena.laneParams = nil
	local D = require(RS.MeadowV4.ReachableDrops)
	local routes = require(RS.MeadowV4.RouteData)
	local total, failures = 0, 0
	local groups = {}
	SSS:SetAttribute("DropSampleTestFailures", "[]")
	SSS:SetAttribute("DropSampleTestFailureCount", 0)
	arena.samplingDrops = true
	local function persist()
		local rows = {}
		for _, row in groups do
			table.insert(rows, row)
		end
		table.sort(rows, function(a, b)
			if a.count ~= b.count then return a.count > b.count end
			return a.laneId .. a.landingInstance .. a.reason < b.laneId .. b.landingInstance .. b.reason
		end)
		while #rows > 30 do
			table.remove(rows)
		end
		SSS:SetAttribute("DropSampleTestFailures", game:GetService("HttpService"):JSONEncode(rows))
		SSS:SetAttribute("DropSampleTestFailureCount", failures)
	end
	local params = RaycastParams.new()
	params.FilterType, params.FilterDescendantsInstances = Enum.RaycastFilterType.Include, {arena.model}
	params.RespectCanCollide = true
	local function fail(label, point, reason, laneId)
		failures += 1
		local h = workspace:Raycast(point + Vector3.new(0, 8, 0), Vector3.new(0, -30, 0), params)
		local landing = h and h.Instance:GetFullName() or "NONE"
		laneId = laneId or "kit"
		local key = laneId .. "|" .. landing .. "|" .. tostring(reason)
		local row = groups[key] or {laneId=laneId, landingInstance=landing, reason=tostring(reason), count=0, samples={}}
		groups[key] = row
		row.count += 1
		if #row.samples < 3 then
			table.insert(row.samples, {label=label, position={point.X, point.Y, point.Z}, landingY=h and h.Position.Y or "UNKNOWN"})
		end
		persist() -- Retain evidence even if the runner is interrupted.
		if failures <= 30 then
			warn("[DropSampleTest] FAIL " .. label .. " " .. tostring(reason) .. " under=" .. landing .. " Y=" .. tostring(h and h.Position.Y))
		end
	end
	for _, p in arena.v4:GetDescendants() do
		if p:GetAttribute("KitAssemblyId") or p:FindFirstAncestor("KitDressing") then
			if p:GetAttribute("WalkableLaneFloor") == true or p:GetAttribute("Walkable") == true
				or p:HasTag("AuthoredLaneFloor") or p:HasTag("Walkable") or p:HasTag("WalkableLaneFloor") then
				fail("kit allowlist contamination " .. p:GetFullName(), arena.origin, "walkable kit prop")
			end
		end
	end
	for lane, route in routes do
		for i = 2, #route do
			local u, v = route[i - 1], route[i]
			local a, b = arena.origin + Vector3.new(u.x, u.y, -u.z), arena.origin + Vector3.new(v.x, v.y, -v.z)
			local forward = Vector3.new(b.X - a.X, 0, b.Z - a.Z).Unit
			local side = Vector3.new(-forward.Z, 0, forward.X)
			for j = 0, n - 1 do
				for _, edge in {-5, 0, 5} do
					local pose = a:Lerp(b, (j + 0.5) / n) + side * edge
					local floor = Arena.carrierFloor(arena, pose + Vector3.new(0, 3, 0))
					for _, knock in {-20, 0, 20} do
						total += 1
						local label = lane .. "/" .. i .. "/" .. j .. " edge=" .. edge .. " knock=" .. knock
						if not floor then fail(label, pose, "no lane floor at carrier", lane)
						else
							local socket, why = Arena.dropSocket(arena, pose + side * knock + Vector3.new(0, 3, 0), floor)
							if not socket then fail(label, pose, why, lane)
							else
								local hit = workspace:Raycast(socket + Vector3.new(0, 8.25, 0), Vector3.new(0, -10.45, 0), params)
								if not hit or not hit.Instance:HasTag("AuthoredLaneFloor")
									or math.abs(hit.Position.Y - socket.Y) > 0.1 or math.abs(socket.Y - floor.Y) > 2
									or not D.connected(D.segment(floor, arena.laneGraph), D.segment(socket, arena.laneGraph)) then
										fail(label, socket, "landing differs from carrier lane / blocked live surface", lane)
								end
							end
						end
						if total % 9 == 0 then
							task.wait()
						end
					end
				end
			end
		end
	end
	SSS:SetAttribute("DropSampleTestSamples", total)
	arena.samplingDrops = false
	persist()
	assert(failures == 0, string.format("%d/%d live drops failed; see ServerScriptService.DropSampleTestFailures JSON", failures, total))
	return string.format("%d live knock-drops; zero failures; KitSwapVersion=%s; N=%d per segment", total, tostring(arena.v4:GetAttribute("KitSwapVersion")), n)
end
return Sample
