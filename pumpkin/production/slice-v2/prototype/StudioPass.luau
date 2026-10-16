-- Studio-only pass coordinator. Live tests retain their own authoritative assertions.
local SSS = game:GetService("ServerScriptService")
local RS = game:GetService("ReplicatedStorage")
local Http = game:GetService("HttpService")
local Pass = {}
function Pass.attach(api)
	local control = Instance.new("Folder")
	control.Name, control.Parent = "StudioPassControl", RS
	local function debugToggle()
		control:SetAttribute("ShowDebug", SSS:GetAttribute("ShowDebug") == true)
	end
	SSS:GetAttributeChangedSignal("ShowDebug"):Connect(debugToggle)
	debugToggle()
	game:GetService("RunService").Heartbeat:Connect(function()
		if control:GetAttribute("ShowDebug") then
			control:SetAttribute("KeeperState", api.keeperState())
		end
	end)
	local captureSerial = 0
	SSS:GetAttributeChangedSignal("CaptureShots"):Connect(function()
		if SSS:GetAttribute("CaptureShots") then
			captureSerial += 1
			control:SetAttribute("CaptureShots", captureSerial)
			SSS:SetAttribute("CaptureShots", false)
		end
	end)
	local running = false
	local names = {
		"GreyboxSelfTest",
		"DropSampleTest",
		"GreyboxLoopTest",
		"GreyboxPvpTest",
		"GreyboxTrapTest",
		"CoreLoopTest",
		"RavineTest",
		"TunnelTest",
		"OutsmartTest",
	}
	local function run()
		if running or not SSS:GetAttribute("StudioPassAll") then
			return
		end
		running = true
		SSS:SetAttribute("StudioPassBusy", true)
		local began, rows = os.clock(), {}
		local summary = {
			status = "RUNNING",
			tests = rows,
			evidence = "Studio legacy tests + live Outsmart collision; core mock store; ravine/tunnel policy assertions",
		}
		local function publish()
			summary.seconds = os.clock() - began
			SSS:SetAttribute("StudioPassResult", Http:JSONEncode(summary))
		end
		for _, name in names do
			SSS:SetAttribute(name .. "StudioPassStatus", "NOT RUN")
			SSS:SetAttribute(name .. "StudioPassSeconds", 0)
		end
		publish()
		local prepared, failure = pcall(api.prepare)
		local activeThread
		local ok, why = pcall(function()
			assert(prepared, failure)
			SSS:SetAttribute("GreyboxLoopTestRuns", 3)
			for _, name in names do
				local start = os.clock()
				local passed, detail = pcall(function()
					api.reset()
					if name == "OutsmartTest" then SSS:SetAttribute("OutsmartTestFailureJSON", "{}") end
					if name == "RavineTest" or name == "TunnelTest" then
						return require(RS.MeadowV4.PolicyTests)[name](
							require(RS.MeadowV4.RavinePolicy),
							require(RS.MeadowV4.TunnelPolicy)
						)
					end
					SSS:SetAttribute(name .. "Result", "RUNNING")
					SSS:SetAttribute(name .. "Success", false)
					if name == "GreyboxSelfTest" or name == "CoreLoopTest" then
						SSS:SetAttribute(name, true)
					else
						SSS:SetAttribute(name, true)
						activeThread = api.start(name)
					end
					local deadline = os.clock() + ((name == "GreyboxLoopTest" or name == "DropSampleTest") and 900 or 300)
					repeat
						task.wait(0.1)
					until SSS:GetAttribute(name .. "Result") ~= "RUNNING" or os.clock() > deadline
					assert(os.clock() <= deadline, name .. " timed out")
					activeThread = nil
					local result = tostring(SSS:GetAttribute(name .. "Result"))
					assert(result:sub(1, 4) == "PASS", result)
					if name ~= "GreyboxSelfTest" then
						assert(SSS:GetAttribute(name .. "Success") == true, result)
					end
					if name == "GreyboxLoopTest" then
						assert(SSS:GetAttribute("GreyboxLoopTestPassCount") == 3, "three runs required")
						assert(
							(SSS:GetAttribute("GreyboxLoopTestExpiryCount") or 3) < 3,
							"balance failure: all runs expired, no secure/place"
						)
					end
					return result
				end)
				if activeThread then
					pcall(task.cancel, activeThread)
					activeThread = nil
				end
				local row = { name = name, pass = passed, seconds = os.clock() - start, result = tostring(detail) }
				if name == "OutsmartTest" and not passed and SSS:GetAttribute("OutsmartTestFailureJSON") == "{}" then
					SSS:SetAttribute("OutsmartTestFailureJSON", Http:JSONEncode({stage="harness",error=tostring(detail):sub(1,2000)}))
				end
				table.insert(rows, row)
				SSS:SetAttribute(name .. "StudioPassStatus", passed and "PASS" or "FAIL")
				SSS:SetAttribute(name .. "StudioPassSeconds", row.seconds)
				if name == "RavineTest" or name == "TunnelTest" then
					SSS:SetAttribute(name .. "Success", passed)
					SSS:SetAttribute(name .. "Result", (passed and "PASS: " or "FAIL: ") .. row.result)
				end
				print(
					"[StudioPass] "
						.. name
						.. " "
						.. (passed and "PASS" or "FAIL")
						.. " "
						.. row.seconds
						.. "s "
						.. row.result
				)
				publish()
			end
		end)
		local clean, cleanup = true, nil
		if prepared then
			clean, cleanup = pcall(api.reset)
		end
		local all = ok and clean and #rows == #names
		for _, row in rows do
			all = all and row.pass
		end
		summary.status = all and "PASS" or "FAIL"
		summary.error = not ok and tostring(why) or (not clean and tostring(cleanup) or nil)
		publish()
		SSS:SetAttribute("StudioPassSuccess", all)
		SSS:SetAttribute("StudioPassBusy", false)
		SSS:SetAttribute("StudioPassAll", false)
		running = false
	end
	SSS:GetAttributeChangedSignal("StudioPassAll"):Connect(function()
		task.spawn(run)
	end)
	task.spawn(run)
end
return Pass
