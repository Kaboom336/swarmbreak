-- Humanoid state enablement does not replicate between server and client.
local h = script.Parent:WaitForChild("Humanoid")
local prior
local function update()
	if h:GetAttribute("CaveCartRiding") then
		if prior == nil then
			prior = h:GetStateEnabled(Enum.HumanoidStateType.Jumping)
		end
		h:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
		h.Jump = false
	elseif prior ~= nil then
		h:SetStateEnabled(Enum.HumanoidStateType.Jumping, prior)
		prior = nil
	end
end
h:GetAttributeChangedSignal("CaveCartRiding"):Connect(update)
update()
