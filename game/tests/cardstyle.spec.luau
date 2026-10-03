local CardStyle = load("CardStyle")
local LevelUp = load("LevelUp")
local WaveRewards = load("WaveRewards")

test("every rarity palette keeps its text readable", function()
	for _, rarity in LevelUp.RarityOrder do
		local style = CardStyle.styleFor(rarity)
		assert(style, "style exists for " .. rarity)
		for _, background in style.Background do
			assert(
				CardStyle.contrastRatio(background, style.Text) >= CardStyle.MinimumContrast,
				rarity .. " text passes contrast"
			)
		end
	end
end)

test("every upgrade has a family icon", function()
	for _, id in WaveRewards.Order do
		local icon = CardStyle.iconFor(id)
		assert(type(icon) == "string" and icon ~= "", "icon exists for " .. id)
	end
	assert(
		CardStyle.iconFor("Sharp", "Nature") ~= CardStyle.iconFor("Sharp"),
		"elements use their icon"
	)
end)

test("cards reveal left to right in under half a second", function()
	eq(LevelUp.CardFlipSeconds, 0.12, "flip cadence")
	local schedule = CardStyle.revealSchedule(WaveRewards.OfferSize)
	eq(#schedule, WaveRewards.OfferSize, "one reveal per card")
	for index, reveal in schedule do
		eq(reveal.Index, index, "left-to-right order")
		if index > 1 then
			assert(reveal.Delay > schedule[index - 1].Delay, "delays increase")
		end
	end
	assert(CardStyle.totalRevealTime(WaveRewards.OfferSize) <= 0.5, "reveal completes quickly")
end)

test("card chrome covers every category and highlights effect keywords", function()
	eq(CardStyle.categoryFor("Weapon"), "WEAPON", "weapon category")
	eq(CardStyle.categoryFor("Utility"), "PASSIVE", "passive category")
	eq(CardStyle.categoryFor("Stat"), "UPGRADE", "upgrade category")
	eq(CardStyle.categoryFor("Weapon", "Nature"), "ELEMENT", "element category wins")
	for _, category in { "WEAPON", "PASSIVE", "ELEMENT", "UPGRADE" } do
		assert(CardStyle.CategoryColors[category], "category color for " .. category)
	end
	local rich = CardStyle.richEffect("Chain fire, pierce, slow and heal")
	assert(rich:find("<font color=", 1, true), "keywords receive RichText color tags")
	for _, keyword in { "Chain", "fire", "pierce", "slow", "heal" } do
		assert(rich:find(keyword, 1, true), "keeps keyword " .. keyword)
	end
end)
