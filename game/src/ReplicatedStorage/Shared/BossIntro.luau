--!strict
-- Pure presentation data and rules for the full-screen boss poster.
local Config = require(script.Parent.Config)

export type Poster = {
	Name: string,
	Title: string,
	ElementColor: { number }, -- r, g, b 0..255
}

local BossIntro = {
	Duration = Config.BossIntroSeconds,
	Posters = {
		Brute = {
			Name = "Big Brute",
			Title = "The Breaker",
			ElementColor = { 214, 116, 54 },
		},
		Queen = {
			Name = "Swarm Queen",
			Title = "Mother of the Swarm",
			ElementColor = { 130, 230, 80 },
		},
		Warden = {
			Name = "Sky King",
			Title = "Ruler of the Skies",
			ElementColor = { 100, 160, 255 },
		},
	} :: { [string]: Poster },
}

function BossIntro.canSkip(hasSeen: boolean): boolean
	return hasSeen
end

return BossIntro
