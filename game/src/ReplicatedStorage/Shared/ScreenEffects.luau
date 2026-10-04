--!strict
-- Engine-free timing, palette, and layout rules for the anime HUD effects.
local BossFight = require(script.Parent.BossFight)
local Theme = require(script.Parent.Theme)

local ScreenEffects = {}

ScreenEffects.TrailSeconds = 0.4
ScreenEffects.ShakeSeconds = 0.15
ScreenEffects.ShakePixels = 4
ScreenEffects.BigHitRatio = 0.05
ScreenEffects.HitMarkerSeconds = 0.1
ScreenEffects.DamageNumberPopSeconds = 0.12
ScreenEffects.SpeedLineSeconds = 0.28
ScreenEffects.MaxCenterCoverSeconds = 0.3
ScreenEffects.VignetteColor = Theme.Goo
ScreenEffects.TextureIds = {
	SpeedLines = 0,
}
ScreenEffects.BossPortraitIds = {
	["Big Brute"] = 0,
	["Swarm Queen"] = 0,
	["Sky King"] = 0,
}

local function clamp01(value: number): number
	return math.clamp(value, 0, 1)
end

function ScreenEffects.trailRatio(startRatio: number, fillRatio: number, elapsed: number): number
	local progress = clamp01(elapsed / ScreenEffects.TrailSeconds)
	local easedOutQuad = 1 - (1 - progress) * (1 - progress)
	return math.max(fillRatio, startRatio + (fillRatio - startRatio) * easedOutQuad)
end

function ScreenEffects.phaseNotches(): { number }
	return { BossFight.PhaseTwoHealthRatio }
end

function ScreenEffects.shakeOffset(progress: number): (number, number)
	local envelope = 1 - clamp01(progress)
	return math.sin(progress * math.pi * 8) * ScreenEffects.ShakePixels * envelope,
		math.cos(progress * math.pi * 10) * ScreenEffects.ShakePixels * envelope
end

export type Rect = { x: number, y: number, w: number, h: number }

function ScreenEffects.bossBarRect(
	viewportWidth: number,
	_viewportHeight: number,
	scale: number,
	safeTop: number
): Rect
	local width = math.min(560 * scale, viewportWidth - 24 * scale)
	return {
		x = (viewportWidth - width) / 2,
		y = safeTop + 38 * scale,
		w = width,
		h = 58 * scale,
	}
end

return ScreenEffects
