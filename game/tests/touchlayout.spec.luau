local TouchLayout = load("TouchLayout")

local function overlaps(a, b)
	return a.X < b.X + b.Size and b.X < a.X + a.Size and a.Y < b.Y + b.Size and b.Y < a.Y + a.Size
end

for _, viewport in { { 667, 375 }, { 1280, 720 } } do
	test(
		string.format("touch controls fit without overlap at %dx%d", viewport[1], viewport[2]),
		function()
			local buttons = TouchLayout.layout(
				viewport[1],
				viewport[2],
				{ Left = 0, Top = 0, Right = 0, Bottom = 0 }
			)
			for name, rect in buttons do
				eq(rect.Size >= 56, true, name .. " minimum size")
				eq(rect.X >= 0 and rect.Y >= 0, true, name .. " starts on screen")
				eq(rect.X + rect.Size <= viewport[1], true, name .. " ends on screen")
				eq(rect.Y + rect.Size <= viewport[2], true, name .. " ends on screen")
				for otherName, other in buttons do
					if name < otherName then
						eq(overlaps(rect, other), false, name .. " overlaps " .. otherName)
					end
				end
			end
		end
	)
end
