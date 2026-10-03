--!strict
-- Ordered enemy hit-zone definitions. Part names are matched on the server when rigs are built;
-- combat then trusts only the resulting server-created tag. Precision is intentionally hitscan-only.
export type FeedbackColor = { number }
export type Zone = {
	Id: string,
	Patterns: { string },
	Multiplier: number,
	Label: string,
	FeedbackColor: FeedbackColor,
	WeakPoint: boolean,
}
export type Resolution = {
	Multiplier: number,
	Label: string,
	FeedbackColor: FeedbackColor,
	WeakPoint: boolean,
}

local HitZones = {}

HitZones.AttributeName = "HitZone"
HitZones.MultiplierBounds = { Min = 0.7, Max = 2 }
HitZones.Neutral = {
	Multiplier = 1,
	Label = "Body",
	FeedbackColor = { 255, 255, 255 },
	WeakPoint = false,
} :: Resolution

local WEAK = { 255, 150, 60 }
local ARMOR = { 110, 180, 255 }

local function weak(id: string, label: string, multiplier: number, patterns: { string }): Zone
	return {
		Id = id,
		Patterns = patterns,
		Multiplier = multiplier,
		Label = label,
		FeedbackColor = WEAK,
		WeakPoint = true,
	}
end

local function armor(id: string, label: string, multiplier: number, patterns: { string }): Zone
	return {
		Id = id,
		Patterns = patterns,
		Multiplier = multiplier,
		Label = label,
		FeedbackColor = ARMOR,
		WeakPoint = false,
	}
end

-- First match wins. Keep narrow weak-point patterns before broader armor patterns.
HitZones.Defs = {
	Walker = {
		weak("Eyes", "Eyes", 1.75, { "^Eyes?", "^Head$" }),
	},
	Runner = {
		weak("Jaw", "Jaw", 1.8, { "^Jaw$" }),
	},
	Flyer = {
		weak("Core", "Core", 2, { "^Core" }),
	},
	Tank = {
		weak("Head", "Head", 1.6, { "^Eyes?", "^Head$" }),
		armor("Carapace", "Carapace", 0.7, { "^Shell$", "^Torso$" }),
	},
	Spitter = {
		weak("AcidSacs", "Acid sacs", 1.75, { "^Sacs?" }),
	},
	Brute = {
		weak("Eyes", "Eyes", 1.6, { "^Eyes?", "^Head$" }),
		armor("Crown", "Crown armor", 0.85, { "^Crown" }),
	},
	Queen = {
		weak("Head", "Head", 1.65, { "^Eyes?", "^Head$" }),
		armor("Carapace", "Carapace", 0.75, { "^Shell$", "^Abdomen$", "^Torso$" }),
	},
	Warden = {
		weak("Eye", "Central eye", 1.8, { "^Iris", "^Pupil$", "^Eye", "^Core" }),
		armor("Aegis", "Aegis armor", 0.8, { "^Wing_", "^Halo", "^.*_Glow$" }),
	},
} :: { [string]: { Zone } }

local function copyResolution(zone: Zone): Resolution
	return {
		Multiplier = zone.Multiplier,
		Label = zone.Label,
		FeedbackColor = zone.FeedbackColor,
		WeakPoint = zone.WeakPoint,
	}
end

function HitZones.zoneForPart(enemyType: string, partName: string): Zone?
	for _, zone in HitZones.Defs[enemyType] or {} do
		for _, pattern in zone.Patterns do
			if partName:match(pattern) then
				return zone
			end
		end
	end
	return nil
end

function HitZones.zoneForTag(enemyType: string, tag: string?): Zone?
	if not tag then
		return nil
	end
	for _, zone in HitZones.Defs[enemyType] or {} do
		if zone.Id == tag then
			return zone
		end
	end
	return nil
end

function HitZones.resolve(enemyType: string, tag: string?, weaponKind: string): Resolution
	if weaponKind ~= "Hitscan" then
		return HitZones.Neutral
	end
	local zone = HitZones.zoneForTag(enemyType, tag)
	return if zone then copyResolution(zone) else HitZones.Neutral
end

return HitZones
