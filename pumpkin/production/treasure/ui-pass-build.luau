-- Current-place source overlay. No historical map regeneration or server changes.
return function(biome)
	local fs, rb, luau, serde = require('@lune/fs'), require('@lune/roblox'), require('@lune/luau'), require('@lune/serde')
	local path = biome == 'cave' and 'prototype/cave-v2.rbxl' or 'slice-v2/prototype/guardian-greybox.rbxl'
	local backup = 'treasure/ui-pass-backup-20261017/' .. path:gsub('/', '__')
	local before = fs.readFile(path)
	assert(fs.isFile(backup), 'byte-verified backup required')
	local place = rb.deserializePlace(before)
	local clients, core = place.StarterPlayer.StarterPlayerScripts, place.ReplicatedStorage.TreasureCore
	local mounts = {
		{place.ReplicatedStorage, 'ModuleScript', 'UIStyle', 'prototype/core/UIStyle.luau'},
		{core, 'ModuleScript', 'UIPresentation', 'prototype/core/UIPresentation.luau'},
		{clients, 'LocalScript', 'TreasureObjective', 'prototype/core/Objective.client.luau'},
		{clients, 'LocalScript', 'TreasureCoreHud', 'prototype/core/Hud.client.luau'},
		{clients, 'LocalScript', 'TreasureUIWorld', 'prototype/core/UIWorld.client.luau'},
		{clients, 'LocalScript', 'CinematicMovement', 'prototype/core/CinematicMove.client.luau'},
	}
	if biome == 'meadow' then table.insert(mounts, {clients, 'LocalScript', 'Greybox', 'slice-v2/prototype/Greybox.client.luau'}) end
	local changes, compiled = {}, 0
	for _, m in mounts do
		local node = m[1]:FindFirstChild(m[3])
		local prior = node and node.Source
		if not node then node = rb.Instance.new(m[2]); node.Name, node.Parent = m[3], m[1] end
		node.Source = fs.readFile(m[4])
		table.insert(changes, {node = node, prior = prior})
	end
	for _, node in place:GetDescendants() do if node:IsA('LuaSourceContainer') then
		for level = 0, 2 do luau.compile(node.Source, {optimizationLevel = level}) end
		compiled += 1
	end end
	local output = rb.serializePlace(place)
	for _, change in changes do if change.prior then change.node.Source = change.prior else change.node:Destroy() end end
	assert(rb.serializePlace(place) == rb.serializePlace(rb.deserializePlace(before)), 'unrelated saved state changed')
	local result = rb.deserializePlace(output)
	local baseline = rb.deserializePlace(fs.readFile(backup))
	assert(rb.serializeModel({result.Workspace}) == rb.serializeModel({baseline.Workspace}), 'Workspace changed')
	assert(rb.serializeModel({result.ServerScriptService}) == rb.serializeModel({baseline.ServerScriptService}), 'server tree changed')
	fs.writeFile(path, output)
	fs.writeFile('treasure/UI-PASS-BUILD-' .. biome .. '.json', serde.encode('json', {
		status = 'PASS', place = path, compiled_O0_O1_O2 = compiled, backup = backup,
		backup_sha256 = serde.hash('sha256', fs.readFile(backup)), place_sha256 = serde.hash('sha256', output),
		serialized_undo_exact = true, server_tree_exact = true, workspace_exact = true, Studio = 'NOT RUN',
	}, true))
	print('PASS ui-pass ' .. biome .. ': all scripts compile O0/O1/O2; server and Workspace exact')
end
