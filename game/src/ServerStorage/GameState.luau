--!strict
-- Thin wrapper over ReplicatedStorage.State so the client can just read values.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local State = ReplicatedStorage:WaitForChild("State")

local GameState = {}

function GameState.set(name: string, value: any)
	local v = State:FindFirstChild(name) :: ValueBase?
	if v then
		(v :: any).Value = value
	end
end

function GameState.get(name: string): any
	local v = State:FindFirstChild(name) :: ValueBase?
	return if v then (v :: any).Value else nil
end

return GameState
