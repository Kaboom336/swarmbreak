-- Client-only presentation; bounded shake, spring targets and owned cleanup.
local Feel={}
local Packages=script.Parent.Packages
local Shake,Spring,Trove,Signal=require(Packages.Shake),require(Packages.Spring),require(Packages.Trove),require(Packages.Signal)
function Feel.new()
	local self={trove=Trove.new(), springs={}, impacts=Signal.new()}
	self.trove:Add(self.impacts)
	local shake=Shake.new()
	shake.FadeInTime=0;shake.FadeOutTime=.3;shake.SustainTime=.04
	shake.Frequency=18;shake.PositionInfluence=Vector3.new(.12,.12,0)
	shake.RotationInfluence=Vector3.new(.012,.012,.004)
	self.trove:Add(shake)
	self.trove:Connect(self.impacts,function(position, strength)
		local camera=workspace.CurrentCamera
		if not camera or game.Players.LocalPlayer:GetAttribute("ReducedMotion") then return end
		local falloff=math.clamp(1-(camera.CFrame.Position-position).Magnitude/100,0,1)
		if falloff<=0 then return end
		shake.Amplitude=math.min(2,strength)*falloff
		shake:Start()
	end)
	local baseCamera,baseFrame
	self.trove:BindToRenderStep(Shake.NextRenderName(),Enum.RenderPriority.Camera.Value-1,function()
		if baseCamera and baseCamera==workspace.CurrentCamera then baseCamera.CFrame=baseFrame end
		baseCamera=nil
	end)
	self.trove:BindToRenderStep(Shake.NextRenderName(),Enum.RenderPriority.Camera.Value+1,function()
		local camera=workspace.CurrentCamera
		if camera and shake:IsShaking() then
			local pos,rot=shake:Update()
			baseCamera,baseFrame=camera,camera.CFrame
			camera.CFrame=baseFrame*CFrame.new(pos)*CFrame.Angles(rot.X,rot.Y,rot.Z)
		end
	end)
	self.trove:Connect(game:GetService("RunService").RenderStepped,function(dt)
		for object,entry in self.springs do
			if object.Parent then entry.apply(entry.spring:Update(dt))
			else self.springs[object]=nil end
		end
	end)
	function self:pop(object)
		local entry=self.springs[object]
		if not entry then
			local scale=Instance.new("UIScale");scale.Parent=object
			entry={spring=Spring.new(1,.12),apply=function(value) scale.Scale=value end}
			self.springs[object]=entry
		end
		if not game.Players.LocalPlayer:GetAttribute("ReducedMotion") then entry.spring:Impulse(3) end
	end
	function self:counter(object, value, apply)
		local entry=self.springs[object]
		if not entry then entry={spring=Spring.new(value,.15),apply=apply};self.springs[object]=entry end
		entry.spring.Target=value
		if game.Players.LocalPlayer:GetAttribute("ReducedMotion") then entry.spring:Reset(value) end
	end
	function self:Destroy()
		if baseCamera and baseCamera==workspace.CurrentCamera then baseCamera.CFrame=baseFrame end
		self.trove:Destroy();table.clear(self.springs)
	end
	return self
end
return Feel
