--!strict
local MouseMode = load("MouseMode")

local function state(overrides: { [string]: boolean }?)
	local s = {
		LockPreferred = true,
		Alive = true,
		ModalOpen = false,
		FreeHeld = false,
		TouchOnly = false,
	}
	for key, value in overrides or {} do
		(s :: any)[key] = value
	end
	return s
end

test("mouse locks while fighting with lock on", function()
	eq(MouseMode.locked(state()), true, "fighting")
end)

test("mouse frees for any modal, death, Alt, touch, or lock off", function()
	eq(MouseMode.locked(state({ ModalOpen = true })), false, "modal (run summary, cards, shop)")
	eq(MouseMode.locked(state({ Alive = false })), false, "dead: Play Again must be clickable")
	eq(MouseMode.locked(state({ FreeHeld = true })), false, "Alt held")
	eq(MouseMode.locked(state({ TouchOnly = true })), false, "touch")
	eq(MouseMode.locked(state({ LockPreferred = false })), false, "lock setting off")
end)

test("character only turns to the crosshair while alive and no modal is open", function()
	eq(MouseMode.aimsCharacter(state()), true, "fighting")
	eq(MouseMode.aimsCharacter(state({ ModalOpen = true })), false, "modal")
	eq(MouseMode.aimsCharacter(state({ Alive = false })), false, "dead")
end)
