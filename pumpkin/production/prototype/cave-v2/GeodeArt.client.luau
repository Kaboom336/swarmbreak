-- Reveal the hero art without changing the server loot/checker contract.
local function apply(part)
	if part and part:IsA("BasePart") and part:FindFirstChild("C2_GeodeArt") then
		part.LocalTransparencyModifier = 0.85
	end
end

-- Connect first so replication, recreation and carried/reparented loot are covered.
workspace.DescendantAdded:Connect(function(node)
	apply(node)
	if node.Name == "C2_GeodeArt" then
		apply(node.Parent)
	end
end)

for _, node in workspace:GetDescendants() do
	apply(node)
end
