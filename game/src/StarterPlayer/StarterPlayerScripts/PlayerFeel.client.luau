--!strict
-- Additive procedural poses layered over Roblox's default character animation.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local PlayerPose = require(ReplicatedStorage.Shared.PlayerPose)
local ClientFX = require(script.Parent:WaitForChild("ClientFX"))

local player = Players.LocalPlayer
local StatsChanged = (ReplicatedStorage:WaitForChild("Remotes") :: Folder):WaitForChild(
	"StatsChanged"
) :: RemoteEvent
local RENDER_STEP_NAME = "SwarmPlayerFeel"

type FeelState = {
	Root: BasePart,
	PoseJoint: Motor6D?,
	Trail: Trail,
	DashStartedAt: number,
	HitStartedAt: number,
	LevelStartedAt: number,
	Pitch: number,
	Roll: number,
}

local activeState: FeelState? = nil
local lastOffset = CFrame.identity
local lastWritten: CFrame? = nil
local characterConnections: { RBXScriptConnection } = {}
local bindGeneration = 0
local lastLevel: number? = nil

local function disconnectCharacter()
	RunService:UnbindFromRenderStep(RENDER_STEP_NAME)
	for _, connection in characterConnections do
		connection:Disconnect()
	end
	table.clear(characterConnections)
	if activeState then
		activeState.Trail:Destroy()
	end
	activeState = nil
end

local function makeDashTrail(root: BasePart): Trail
	local top = Instance.new("Attachment")
	top.Name = "PlayerFeelTrailTop"
	top.Position = Vector3.new(0, 1.5, 0)
	top.Parent = root

	local bottom = Instance.new("Attachment")
	bottom.Name = "PlayerFeelTrailBottom"
	bottom.Position = Vector3.new(0, -1.5, 0)
	bottom.Parent = root

	local trail = Instance.new("Trail")
	trail.Name = "PlayerFeelDashTrail"
	trail.Attachment0 = top
	trail.Attachment1 = bottom
	trail.Color = ColorSequence.new(Color3.fromRGB(40, 220, 210))
	trail.LightEmission = 1
	trail.Lifetime = PlayerPose.DashTrailLifetime
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.15),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.Enabled = false
	trail.Parent = root
	return trail
end

local function bind(character: Model)
	bindGeneration += 1
	local generation = bindGeneration
	disconnectCharacter()

	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local root = character:WaitForChild("HumanoidRootPart") :: BasePart
	if generation ~= bindGeneration then
		return
	end

	local waist = character:FindFirstChild("Waist", true)
	local rootJoint = root:FindFirstChild("RootJoint")
	local poseJoint: Motor6D? = nil
	if waist and waist:IsA("Motor6D") then
		poseJoint = waist
	elseif rootJoint and rootJoint:IsA("Motor6D") then
		poseJoint = rootJoint
	end

	local now = os.clock()
	local state: FeelState = {
		Root = root,
		PoseJoint = poseJoint,
		Trail = makeDashTrail(root),
		DashStartedAt = -math.huge,
		HitStartedAt = -math.huge,
		LevelStartedAt = -math.huge,
		Pitch = 0,
		Roll = 0,
	}
	activeState = state

	local previousHealth = humanoid.Health
	local previousDashReady = player:GetAttribute("DashReady") :: number?
	table.insert(
		characterConnections,
		humanoid.HealthChanged:Connect(function(health)
			if health < previousHealth - 0.5 then
				state.HitStartedAt = os.clock()
			end
			previousHealth = health
		end)
	)
	table.insert(
		characterConnections,
		player:GetAttributeChangedSignal("DashReady"):Connect(function()
			local ready = player:GetAttribute("DashReady") :: number?
			if ready and previousDashReady and ready < previousDashReady then
				state.DashStartedAt = os.clock()
			end
			previousDashReady = ready
		end)
	)
	table.insert(
		characterConnections,
		humanoid.Died:Connect(function()
			state.Trail.Enabled = false
		end)
	)

	RunService:BindToRenderStep(
		RENDER_STEP_NAME,
		Enum.RenderPriority.Character.Value + 1,
		function(deltaTime)
			if activeState ~= state or not character.Parent then
				return
			end

			local localMove = root.CFrame:VectorToObjectSpace(humanoid.MoveDirection)
			state.Pitch, state.Roll = PlayerPose.stepRunLean(
				state.Pitch,
				state.Roll,
				localMove.X,
				-localMove.Z,
				deltaTime
			)

			local currentTime = os.clock()
			local dashElapsed = currentTime - state.DashStartedAt
			local dash = PlayerPose.dashPose(dashElapsed)
			local flinch = PlayerPose.hitFlinch(currentTime - state.HitStartedAt)
			local pop = PlayerPose.levelUpPop(currentTime - state.LevelStartedAt)
			state.Trail.Enabled = dashElapsed >= 0 and dashElapsed < PlayerPose.DashDuration

			if state.PoseJoint then
				local offset = CFrame.new(0, dash.Stretch + pop, 0)
					* CFrame.Angles(
						math.rad(-state.Pitch - dash.LeanDegrees),
						0,
						math.rad(state.Roll + flinch)
					)
				-- Transform persists when no animation drives this joint, so remove last frame's
				-- offset first; otherwise the lean would compound every frame.
				local joint = state.PoseJoint
				local base = if joint.Transform == lastWritten
					then joint.Transform * lastOffset:Inverse()
					else joint.Transform
				joint.Transform = base * offset
				lastOffset = offset
				lastWritten = joint.Transform
			end
		end
	)

	-- Avoid treating the initial character bind as a hit.
	previousHealth = humanoid.Health
	state.HitStartedAt = now - PlayerPose.HitDuration
end

StatsChanged.OnClientEvent:Connect(function(stats: any)
	local level = stats.Level
	if type(level) ~= "number" then
		return
	end
	if lastLevel ~= nil and level > lastLevel and activeState then
		activeState.LevelStartedAt = os.clock()
		ClientFX.ring(
			activeState.Root.Position - Vector3.new(0, 2.5, 0),
			Color3.fromRGB(255, 220, 80),
			7,
			PlayerPose.LevelUpDuration
		)
	end
	lastLevel = level
end)

if player.Character then
	task.spawn(bind, player.Character)
end
player.CharacterAdded:Connect(bind)
