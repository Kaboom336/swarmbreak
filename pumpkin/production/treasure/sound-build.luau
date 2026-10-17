-- Source-only overlay on complete canonical places, with serialized undo proof.
return function(biome)
	local fs, rb, luau, serde = require('@lune/fs'), require('@lune/roblox'), require('@lune/luau'), require('@lune/serde')
	local path = biome == 'cave' and 'prototype/cave-v2.rbxl' or 'slice-v2/prototype/guardian-greybox.rbxl'
	local bytes = fs.readFile(path)
	local stackBackup = 'treasure/sound-stack-backup-20261017/' .. path:gsub('/', '__')
	assert(fs.isFile(stackBackup), 'stack-fix backup required before mount')
	local backup = path:gsub('%.rbxl$', '.pre-sound.rbxl')
	if not fs.isFile(backup) then fs.writeFile(backup, bytes) end
	local backupBytes = fs.readFile(backup)
	local place = rb.deserializePlace(bytes)
	local changes = {}
	local mounts = {
		{place.ReplicatedStorage.TreasureCore, 'ModuleScript', 'Audio', 'prototype/core/Audio.luau'},
		{place.StarterPlayer.StarterPlayerScripts, 'LocalScript', 'TreasureAudio', 'prototype/core/Audio.client.luau'},
		{place.StarterPlayer.StarterPlayerScripts, 'LocalScript', 'CinematicMovement', 'prototype/core/CinematicMove.client.luau'},
		{place.ReplicatedStorage, 'ModuleScript', 'UIStyle', 'prototype/core/UIStyle.luau'},
	}
	if biome == 'meadow' then
		table.insert(mounts, {place.ServerScriptService, 'ModuleScript', 'GreyboxArena', 'slice-v2/prototype/Arena.luau'})
	end
	for _, mount in mounts do
		local node = mount[1]:FindFirstChild(mount[3])
		local prior = node and node.Source
		if not node then node = rb.Instance.new(mount[2]); node.Name, node.Parent = mount[3], mount[1] end
		node.Source = fs.readFile(mount[4])
		table.insert(changes, {node = node, prior = prior})
	end
	local count = 0
	for _, node in place:GetDescendants() do
		if node:IsA('LuaSourceContainer') then
			for level = 0, 2 do luau.compile(node.Source, {optimizationLevel = level}) end
			count += 1
		end
	end
	local output = rb.serializePlace(place)
	for _, change in changes do if change.prior then change.node.Source = change.prior else change.node:Destroy() end end
	assert(rb.serializePlace(place) == rb.serializePlace(rb.deserializePlace(bytes)), 'unrelated saved state changed')
	assert(fs.readFile(backup) == backupBytes, 'backup changed')
	fs.writeFile(path, output)
	fs.writeFile('treasure/SOUND-BUILD-' .. biome .. '.json', serde.encode('json', {
		state = 'PASS', place = path, backup = backup, compiled_O0_O1_O2 = count,
		input_sha256 = serde.hash('sha256', bytes), backup_sha256 = serde.hash('sha256', backupBytes),
		stack_fix_backup = stackBackup, stack_fix_backup_sha256 = serde.hash('sha256', fs.readFile(stackBackup)),
		place_sha256 = serde.hash('sha256', output), complete_unrelated_serialization_exact = true,
		server_change = biome == 'meadow' and 'KeeperMode presentation attribute only' or 'NONE',
		live_asset_loading = 'OWNER-REPORTED PASS (13 IDs, Claude 2026-10-17)', Studio = 'NOT RUN',
	}, true))
	print('PASS sound ' .. biome .. ': compiled', count, 'scripts; serialized undo exact')
end
