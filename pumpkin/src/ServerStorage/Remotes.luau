--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local REMOTE_NAMES = {
	"GrowRequest",
	"GrowEffect",
	"StatsChanged",
}

local Remotes = {}

function Remotes.build(): Folder
	local folder = ReplicatedStorage:FindFirstChild("Remotes")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = ReplicatedStorage
	end

	for _, name in REMOTE_NAMES do
		if not folder:FindFirstChild(name) then
			local remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = folder
		end
	end
	return folder :: Folder
end

return Remotes
