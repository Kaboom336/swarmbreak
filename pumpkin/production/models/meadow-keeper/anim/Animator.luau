-- Upload-free, deliberately independent of Humanoid/Animator animation assets.
-- C0 is used because Motor6D.Transform is not replicated. Use one driver only.
local RunService = game:GetService("RunService")
local Clips = require(script.Parent.Clips)
local Animator = {}
Animator.__index = Animator

local function ease(a, style)
	if style == "sine" then
		return (1 - math.cos(a * math.pi)) / 2
	end
	if style == "in" then
		return a * a
	end
	if style == "out" then
		return 1 - (1 - a) * (1 - a)
	end
	return a
end

function Animator.sample(name, time)
	local clip = assert(Clips.clips[name], "Unknown Keeper animation: " .. tostring(name))
	time = math.clamp(time, 0, clip.duration)
	local frames = clip.frames
	local left, right = frames[1], frames[#frames]
	for i = 2, #frames do
		if time <= frames[i].t then
			left, right = frames[i - 1], frames[i]
			break
		end
	end
	local a = ease((time - left.t) / (right.t - left.t), right.ease)
	local pose = {}
	for _, joint in ipairs(Clips.jointOrder) do
		pose[joint] = left.pose[joint]:Lerp(right.pose[joint], a)
	end
	return pose
end

function Animator.new(rig)
	local self = {
		rig = rig,
		time = 0,
		speed = 1,
		fade = 0.12,
		elapsed = 0,
		pose = Animator.sample("idle", 0),
		stopped = true,
		generation = 0,
	}
	setmetatable(self, Animator)
	self.Marker = Instance.new("BindableEvent")
	self.Completed = Instance.new("BindableEvent")
	self.connection = RunService.PreSimulation:Connect(function(dt)
		self:Step(dt)
	end)
	return self
end

function Animator:Apply(pose)
	for name, motor in pairs(self.rig.motors) do
		motor.C0 = self.rig.rest[name] * pose[name]
	end
	self.pose = pose
end

function Animator:Play(name, options)
	options = options or {}
	local clip = assert(Clips.clips[name], "Unknown Keeper animation")
	assert((options.speed or 1) > 0, "speed must be positive")
	self.generation += 1
	self.name, self.clip, self.time, self.elapsed = name, clip, 0, 0
	self.speed, self.fade = options.speed or 1, math.max(0, options.fade or 0.12)
	-- Attack callbacks must match the sampled release pose, without crossfade drift.
	if name == "throw" or name == "lob" or name == "fan" or name == "slam" or name == "dash" then
		self.fade = 0
	end
	self.loop = if options.loop == nil then clip.loop else options.loop
	self.from, self.stopped = self.pose, false
	self.onMarker = options.onMarker
	self:Apply(if self.fade == 0 then Animator.sample(name, 0) else self.from)
	for _, marker in ipairs(clip.markers or {}) do
		if marker.t == 0 then
			self:Emit(marker, name, 0)
		end
	end
	return self
end

function Animator:Emit(marker, name, lateness)
	local snapshot = { releaseCFrame = self.rig:ReleaseCFrame(Animator.sample(name, marker.t), name) }
	-- Immutable CFrame snapshot remains correct with deferred Roblox signals.
	self.Marker:Fire(marker.name, name, marker.t, lateness, snapshot)
	if self.onMarker then
		self.onMarker(marker.name, name, marker.t, lateness, snapshot)
	end
end

function Animator:Step(dt)
	if self.stopped or dt <= 0 then
		return
	end
	local generation, clip, name = self.generation, self.clip, self.name
	local remaining = dt * self.speed
	self.elapsed += dt
	-- Split at markers: apply their exact pose BEFORE the event fires, even on a hitch.
	while remaining > 1e-8 and not self.stopped do
		local before = self.time
		local after = math.min(clip.duration, before + remaining)
		for _, marker in ipairs(clip.markers or {}) do
			if marker.t > before and marker.t <= after then
				self:Apply(Animator.sample(name, marker.t))
				self:Emit(marker, name, (after - marker.t) / self.speed)
				if self.generation ~= generation or self.stopped then
					return
				end
			end
		end
		self.time = after
		local pose = Animator.sample(name, after)
		if self.elapsed < self.fade then
			local a = ease(self.elapsed / self.fade, "sine")
			for joint, cf in pairs(pose) do
				pose[joint] = self.from[joint]:Lerp(cf, a)
			end
		end
		self:Apply(pose)
		remaining -= after - before
		if after >= clip.duration then
			if self.loop then
				self.time = 0
			else
				self.stopped = true
				self.Completed:Fire(name)
				return
			end
		end
	end
end

function Animator:Stop(reset)
	self.generation += 1
	self.stopped = true
	if reset then
		self:Apply(Animator.sample("idle", 0))
	end
end

function Animator:Destroy()
	self:Stop(true)
	self.connection:Disconnect()
	self.Marker:Destroy()
	self.Completed:Destroy()
end

Animator.Clips = Clips.clips
return Animator
