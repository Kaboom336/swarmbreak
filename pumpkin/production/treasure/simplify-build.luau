return function(biome)
	local fs, rb, luau, serde = require('@lune/fs'), require('@lune/roblox'), require('@lune/luau'), require('@lune/serde')
	local path = biome == 'cave' and 'prototype/cave-v2.rbxl' or 'slice-v2/prototype/guardian-greybox.rbxl'
	local backup = 'treasure/simplify-backup-20261017/' .. path:gsub('/', '__')
	assert(fs.isFile(backup), 'verified pre-edit backup required')
	local before = fs.readFile(path)
	local place = rb.deserializePlace(before)
	local baseline = rb.deserializePlace(fs.readFile(backup))
	local clients, core = place.StarterPlayer.StarterPlayerScripts, place.ReplicatedStorage.TreasureCore
	local mounts = {
		{core.UIPresentation, 'prototype/core/UIPresentation.luau'},
		{core.Cutscenes, 'prototype/core/Cutscenes.luau'},
		{clients.TreasureObjective, 'prototype/core/Objective.client.luau'},
		{clients.TreasureUIWorld, 'prototype/core/UIWorld.client.luau'},
	}
	if biome == 'meadow' then table.insert(mounts, {clients.Greybox, 'slice-v2/prototype/Greybox.client.luau'}) end
	local changes, compiled = {}, 0
	for _, mount in mounts do
		table.insert(changes, {node=mount[1], source=mount[1].Source})
		mount[1].Source = fs.readFile(mount[2])
	end
	for _, n in place:GetDescendants() do if n:IsA('LuaSourceContainer') then
		for level=0,2 do luau.compile(n.Source, {optimizationLevel=level}) end
		compiled += 1
	end end
	local output = rb.serializePlace(place)
	for _, change in changes do change.node.Source = change.source end
	assert(rb.serializePlace(place) == rb.serializePlace(rb.deserializePlace(before)), 'overlay undo changed saved state')
	local result = rb.deserializePlace(output)
	assert(rb.serializeModel({result.ServerScriptService}) == rb.serializeModel({baseline.ServerScriptService}), 'server changed')
	assert(rb.serializeModel({result.Workspace}) == rb.serializeModel({baseline.Workspace}), 'Workspace changed')
	-- Restore every allowlisted source against the immediate backup, not only this build input.
	for _, mount in mounts do
		local names, cursor = {}, mount[1]
		while cursor.Parent do table.insert(names, 1, cursor.Name); cursor=cursor.Parent end
		local node, old = result, baseline
		for _, name in names do node=node[name]; old=old[name] end
		node.Source=old.Source
	end
	assert(rb.serializePlace(result) == rb.serializePlace(baseline), 'change outside presentation allowlist')
	fs.writeFile(path, output)
	fs.writeFile('treasure/SIMPLIFY-BUILD-'..biome..'.json', serde.encode('json', {
		status='PASS', place=path, backup=backup, compiled_O0_O1_O2=compiled,
		place_sha256=serde.hash('sha256', output), backup_sha256=serde.hash('sha256', fs.readFile(backup)),
		complete_allowlist_undo_exact=true, server_tree_exact=true, workspace_exact=true, Studio='NOT RUN',
	}, true))
	print('PASS simplify '..biome..': '..compiled..' scripts O0/O1/O2; exact server/Workspace/allowlist undo')
end
