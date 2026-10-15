local RS=game:GetService("ReplicatedStorage")
local feel=require(RS:WaitForChild("TreasureCore").Feel).new()
local keeper=RS:FindFirstChild("MeadowKeeper")
if keeper then
	local event=keeper:WaitForChild("FXEvent")
	feel.trove:Connect(event.OnClientEvent,function(_, kind, position)
		if kind=="slamRelease" or kind=="lobImpact" then
			feel.impacts:Fire(position,kind=="slamRelease" and 1.8 or 1.2)
		end
	end)
end
-- Cave TNT previews replicate payoff attributes after their full telegraph.
local cave=workspace:FindFirstChild("CaveV2")
if cave then
	for _,name in {"TNTHook","DynamiteGuardianHook"} do
		local hook=cave:FindFirstChild(name)
		if hook then feel.trove:Connect(hook:GetAttributeChangedSignal("PayoffPreview"),function()
			if hook:GetAttribute("PayoffPreview") then feel.impacts:Fire(hook.Position,1.5) end
		end) end
	end
end
script.Destroying:Connect(function() feel:Destroy() end)
