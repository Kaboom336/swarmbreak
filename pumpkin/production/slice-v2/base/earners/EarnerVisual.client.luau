local RS=game:GetService("ReplicatedStorage")
local Run=game:GetService("RunService")
local shared=RS:WaitForChild("TreasureBase")
local pose=require(shared:WaitForChild("Earners"):WaitForChild("Walk"))
local folder=workspace:WaitForChild("TreasureBase"):WaitForChild("Earners")
local tracked={}
local function track(root)
	-- Track authority Parts before attributes/Visual arrive; placeholders simply have no Visual.
	if not root:IsA("BasePart") then return end
	tracked[root]={last=root.Position,distance=0}
end
folder.ChildAdded:Connect(track)
folder.ChildRemoved:Connect(function(root) tracked[root]=nil end)
for _,root in folder:GetChildren() do track(root) end
Run.RenderStepped:Connect(function(dt)
	for root,entry in tracked do
		local visual=root:FindFirstChild("Visual")
		if not visual then continue end -- replication may deliver children after the root
		local delta=root.Position-entry.last; entry.last=root.Position
		local state=root:GetAttribute("State")
		local walking=state=="Carpet" or state=="Delivering"
		local travel=Vector3.new(delta.X,0,delta.Z).Magnitude
		if walking and travel>0.001 and travel<4 then
			entry.distance+=travel; entry.activeUntil=os.clock()+0.18
			entry.direction=Vector3.new(delta.X,0,delta.Z).Unit
		end
		local moving=walking and os.clock()<(entry.activeUntil or 0)
		local facing=root.CFrame
		if walking and entry.direction then
			-- Authored +Z is the face. Keep it toward the current travel direction.
			facing=CFrame.lookAt(root.Position,root.Position-entry.direction)
		end
		for _,p in visual:GetChildren() do
			if not p:IsA("BasePart") then continue end
			local rest=p:GetAttribute("Rest")
			if rest then
				local y,z=pose(entry.distance,moving,p:GetAttribute("Leg"))
				p.CFrame=facing*CFrame.new(0,-1.7,0)*rest*CFrame.new(0,y,z)
			end
		end
	end
end)
