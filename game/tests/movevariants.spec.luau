local MoveVariants = load("MoveVariants")

test("movement variants never repeat", function()
	for _, action in { "Dash", "DoubleJump", "Slide" } do
		for lastIndex = 1, MoveVariants.Count do
			for step = 0, 20 do
				local picked = MoveVariants.pick(action, lastIndex, step / 20)
				assert(picked ~= lastIndex, action .. " repeated its previous variant")
			end
		end
	end
end)

test("every movement variant is reachable", function()
	for _, action in { "Dash", "DoubleJump", "Slide" } do
		local reached = {}
		for lastIndex = 1, MoveVariants.Count do
			for step = 0, 20 do
				reached[MoveVariants.pick(action, lastIndex, step / 20)] = true
			end
		end
		for index = 1, MoveVariants.Count do
			assert(reached[index], string.format("%s variant %d was unreachable", action, index))
		end
	end
end)
