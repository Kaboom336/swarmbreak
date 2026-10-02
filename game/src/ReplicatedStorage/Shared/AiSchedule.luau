--!strict
-- Pure scheduling policy for spreading enemy AI work across heartbeat frames.

local AiSchedule = {}

AiSchedule.RepathIntervalFrames = 24

local function isFinite(value: number): boolean
	return value == value and value > -math.huge and value < math.huge
end

local function validInterval(intervalFrames: number): boolean
	return isFinite(intervalFrames) and intervalFrames >= 1 and intervalFrames % 1 == 0
end

function AiSchedule.updateSlot(enemyId: number, intervalFrames: number): number?
	if not isFinite(enemyId) or not validInterval(intervalFrames) then
		return nil
	end
	return math.floor(enemyId) % intervalFrames
end

-- Returns the first scheduled frame strictly after `frame`.
function AiSchedule.nextRepathFrame(enemyId: number, frame: number, intervalFrames: number): number?
	if not isFinite(frame) then
		return nil
	end
	local slot = AiSchedule.updateSlot(enemyId, intervalFrames)
	if slot == nil then
		return nil
	end
	local nextFrame = math.floor(frame) + 1
	return nextFrame + (slot - nextFrame % intervalFrames) % intervalFrames
end

function AiSchedule.shouldRepath(frame: number, nextRepathFrame: number?, urgent: boolean): boolean
	if urgent then
		return true
	end
	return isFinite(frame)
		and nextRepathFrame ~= nil
		and isFinite(nextRepathFrame)
		and frame >= nextRepathFrame
end

return AiSchedule
