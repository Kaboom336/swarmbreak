-- One Meadow encounter; cues are neutral, the bait lane is authored floor.
local O = {}
O.Corner = Vector3.new(-73, 0, 113) -- Existing broad R5BoulderFoot, south-west return.
O.Bait = Vector3.new(-73, 0, 104)
O.Start = Vector3.new(-73, 0, 88)
O.Bell = Vector3.new(36, 0, 64) -- Off-route clearing; reserve the entire bypass from dressing.
O.BellClearSize = 20
function O.levelApproach(a, floor)
	local start = floor(a, a.origin + O.Start + Vector3.new(0, 3, 0))
	if not start then return false, "missing start floor" end
	local direction = Vector3.new(O.Bait.X-O.Start.X, 0, O.Bait.Z-O.Start.Z).Unit
	local face = workspace:Raycast(start + Vector3.new(0, 2, 0), direction * 24, a.wallParams)
	if not face or not face.Instance:GetAttribute("OutsmartBaitCover") then return false, "missing tagged wall face" end
	local distance = Vector3.new(face.Position.X-start.X, 0, face.Position.Z-start.Z).Magnitude
	local function sample(d)
		local p = floor(a, start + direction * d + Vector3.new(0, 5.5, 0))
		return p and math.abs(p.Y-start.Y)<0.3
	end
	for d=0,distance-0.01,0.5 do
		if not sample(d) then return false, "floor change at " .. tostring(d) end
	end
	return sample(distance-0.01), "wall face at " .. tostring(distance)
end
function O.build(model, origin)
	-- The old lane ended at z=99, exposing a two-stud dip until z=104.
	-- One six-stud-wide slab spans the entire approach and meets the cover face.
	local lane = Instance.new("Part")
	lane.Name, lane.Size = "OutsmartBaitFloor", Vector3.new(6, 1.2, 22.5)
	lane.CFrame = CFrame.new(origin + Vector3.new(-73, -0.48, 98.25))
	lane.Anchored, lane.CanCollide, lane.CanQuery, lane.CanTouch = true, true, true, false
	lane.Material, lane.Color, lane.Parent = Enum.Material.Grass, Color3.fromRGB(101, 148, 64), model
	lane:SetAttribute("SurfaceRole", "Floor")
	lane:SetAttribute("MeadowV4Category", "route")
	lane:SetAttribute("WalkableLaneFloor", true)
	lane:SetAttribute("LaneId", "outsmart_bait")
	lane:AddTag("AuthoredLaneFloor")
	for _,p in model:GetDescendants() do
		if p:IsA("BasePart") and p.Name=="R5BoulderFoot" and (p.CFrame.Position-origin-O.Corner-Vector3.new(0,4.305,0)).Magnitude<0.02 then
			p:SetAttribute("OutsmartBaitCover", true)
			p:SetAttribute("GameplayCover", true)
			p:SetAttribute("SurfaceRole", "Cover")
			p.CanCollide, p.CanQuery = true, true
			p:AddTag("OutsmartBaitCover")
			-- End the runway at the wall face, with no wall inside its footprint.
			local faceZ = p.CFrame.Position.Z - p.Size.Z/2
			local startZ = origin.Z + 87
			lane.Size = Vector3.new(6, 1.2, faceZ-startZ)
			lane.CFrame = CFrame.new(origin.X-73, origin.Y-.48, (startZ+faceZ)/2)
		end
	end
	local function cue(name, p, text, color)
		local sign = Instance.new("Part")
		sign.Name, sign.Size, sign.Position = name, Vector3.new(0.2, 0.2, 0.2), origin + p
		sign.Anchored, sign.CanCollide, sign.CanQuery, sign.CanTouch = true, false, false, false
		sign.Transparency, sign.Parent = 1, model
		sign:SetAttribute("OutsmartCue", true)
		local gui = Instance.new("BillboardGui")
		gui.Size, gui.MaxDistance = UDim2.fromOffset(230, 54), 65
		gui.Parent = sign
		local label = Instance.new("TextLabel")
		label.Size, label.BackgroundTransparency = UDim2.fromScale(1, 1), 1
		label.Text, label.TextColor3, label.TextScaled = text, color, true
		label.Font, label.TextStrokeTransparency, label.Parent = Enum.Font.GothamBold, 0.2, gui
	end
	local cyan, gold = Color3.fromRGB(80, 235, 240), Color3.fromRGB(255, 213, 85)
	cue("OutsmartCorner", Vector3.new(-73, 11, 113), "CHARGE → CUT ASIDE", gold)
	-- S2 removes the debug-like floating return cue at the mine mouth.
	-- The physical route and cyan portal remain the return landmarks.
	cue("OutsmartFork", Vector3.new(0, 5, -42), "← TUNNEL / BRIDGE AHEAD", cyan)
	cue("OutsmartTunnel", Vector3.new(-76, 5, -31), "TUNNEL: MUD / TWO EXITS\nSURFACE WALK ←", gold)
	cue("OutsmartBridge", Vector3.new(0, 4, -22), "BRIDGE: WALK ACROSS", cyan)
	cue("OutsmartRecovery", Vector3.new(-22, -26, 0), "CLIMB OUT → RAMP SOUTH", cyan)
	-- Landing edges are cues, never new colliders or drop sockets.
	for _,z in {-19, 19} do
		local p = Instance.new("Part")
		p.Name, p.Size, p.Position = "OutsmartLanding", Vector3.new(15, 0.08, 0.5), origin + Vector3.new(0, 0.18, z)
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
		p.Color, p.Material, p.Parent = cyan, Enum.Material.Neon, model
		p:SetAttribute("OutsmartCue", true)
	end
end
return O
