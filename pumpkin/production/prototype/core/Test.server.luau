local SSS = game:GetService("ServerScriptService")
local RS = game:GetService("ReplicatedStorage")
local folder = RS:WaitForChild("TreasureCore")
local running = false
local function run()
	if running or not SSS:GetAttribute("CoreLoopTest") then
		return
	end
	running = true
	SSS:SetAttribute("CoreLoopTestSuccess", false)
	SSS:SetAttribute("CoreLoopTestResult", "RUNNING")
	local ok, result = pcall(function()
		return require(folder.Tests).run(
			require(folder.Config),
			require(folder.Domain),
			require(folder.Profiles),
			require(RS.GreyboxLootRules),
			require(RS.GreyboxConfig),
			require(folder.Service)
		)
	end)
	SSS:SetAttribute("CoreLoopTestSuccess", ok)
	SSS:SetAttribute("CoreLoopTestResult", (ok and "PASS: " or "FAIL: ") .. tostring(result))
	SSS:SetAttribute("CoreLoopTest", false)
	running = false
	print("[CoreLoopTest] " .. (ok and "PASS: " or "FAIL: ") .. tostring(result))
end
SSS:GetAttributeChangedSignal("CoreLoopTest"):Connect(run)
run()
