-- Insert MeadowKeeperAnimations.rbxmx into Workspace in an EMPTY local Studio place.
-- Eight separate rigs, no changes to the production state machine or map.
local Rig = require(script.Parent.Rig)
local Animator = require(script.Parent.Animator)
local names = { "idle", "patrol", "warn", "chase", "lob", "fan", "slam", "stun", "celebrate", "return", "throw" }

local function label(root, text)
	local gui = Instance.new("BillboardGui")
	gui.Size, gui.StudsOffset, gui.AlwaysOnTop = UDim2.fromOffset(260, 50), Vector3.new(0, 12.5, 0), true
	gui.Adornee, gui.Parent = root, root
	local title = Instance.new("TextLabel")
	title.Size, title.BackgroundTransparency, title.Text = UDim2.fromScale(1, 1), 1, text
	title.TextColor3, title.TextStrokeTransparency, title.TextSize = Color3.new(1, 1, 1), 0.3, 24
	title.Parent = gui
	return title
end

for i, name in ipairs(names) do
	local rig = Rig.build(CFrame.new(((i - 1) % 4) * 17, 0, math.floor((i - 1) / 4) * 21))
	rig.model.Parent = workspace
	local title = label(rig.root, name)
	local anim = Animator.new(rig)
	local stone = Instance.new("Part")
	stone.Shape, stone.Size, stone.Color = Enum.PartType.Ball, Vector3.new(1.4, 1.4, 1.4), Color3.fromRGB(100, 105, 110)
	stone.Anchored, stone.CanCollide, stone.Transparency, stone.Parent = true, false, 1, rig.model
	local releasedAt, origin
	anim.Marker.Event:Connect(function(marker, clip, at, lateness, snapshot)
		if marker == "Alert" then
			title.Text = "!  WARN"
		end
		if marker == "Release" then
			-- Socket sampled at the exact release keyframe. Gameplay owns aim/lead/knock-drop.
			origin, releasedAt = snapshot.releaseCFrame.Position, os.clock() - lateness
			stone.Position, stone.Transparency = origin, 0
			print("Keeper Release", at, origin)
		end
	end)
	game:GetService("RunService").Heartbeat:Connect(function()
		if name == "throw" or name == "lob" or name == "fan" then
			if releasedAt then
				local t = os.clock() - releasedAt
				stone.Position = origin + Vector3.new(0, 10 * t - 22 * t * t, 24 * t)
				if t > 0.8 then
					stone.Transparency = 1
				end
			elseif not anim.stopped then
				stone.CFrame, stone.Transparency = rig:ReleaseCFrame(anim.pose, name), 0
			end
		end
	end)
	if Animator.Clips[name].loop then
		anim:Play(name)
	else
		task.spawn(function()
			while rig.model.Parent do
				releasedAt = nil
				title.Text = name
				anim:Play(name, { fade = 0 })
				anim.Completed.Event:Wait()
				task.wait(0.65)
			end
		end)
	end
end
