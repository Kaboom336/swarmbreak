local Layout = load("GardenLayout")
local function overlap(a, b)
	return a.x < b.x + b.width
		and b.x < a.x + a.width
		and a.y < b.y + b.height
		and b.y < a.y + a.height
end
test("garden safe layout keeps 56px actions apart and below HUD across devices", function()
	for _, viewport in { { 320, 280 }, { 568, 280 }, { 360, 640 }, { 1920, 1080 }, { 320, 220 } } do
		local w, h = viewport[1], viewport[2]
		local r = Layout.calculate(w, h)
		eq(overlap(r.hud, r.main), false)
		eq(overlap(r.hud, r.burst), false)
		eq(overlap(r.main, r.burst), false)
		for _, button in { r.main, r.burst } do
			eq(button.height >= 56, true)
			eq(button.width >= 56, true)
			eq(button.y >= 0 and button.y + button.height <= h - 12, true)
			eq(button.x >= 0 and button.x + button.width <= w, true)
		end
	end
end)
test("garden short phone actions leave side thumb controls clear", function()
	local r = Layout.calculate(320, 280)
	local left = { x = 0, y = 136, width = 100, height = 144 }
	local right = { x = 216, y = 136, width = 104, height = 144 }
	for _, button in { r.main, r.burst } do
		eq(overlap(button, left), false)
		eq(overlap(button, right), false)
	end
	eq(r.main.y - (r.burst.y + r.burst.height), 8)
end)
