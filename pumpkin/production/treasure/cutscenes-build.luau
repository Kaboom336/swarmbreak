-- Patch complete canonical places; never regenerate an earlier map.
return function(biome, cutfix)
	local fs, rb, luau, serde = require('@lune/fs'), require('@lune/roblox'), require('@lune/luau'), require('@lune/serde')
	local main = biome == 'cave' and 'prototype/cave-v2.rbxl' or 'slice-v2/prototype/guardian-greybox.rbxl'
	local before = fs.readFile(main)
	local backup = main:gsub('%.rbxl$', cutfix and '.pre-cutfix.rbxl' or '.pre-cutscenes.rbxl')
	if not fs.isFile(backup) then fs.writeFile(backup, before) end
	local backupBytes = fs.readFile(backup)
	local place = rb.deserializePlace(before)
	local changes = {}
	local mounts = {
		{place.ReplicatedStorage.TreasureCore, 'ModuleScript', 'Cutscenes', 'prototype/core/Cutscenes.luau'},
		{place.StarterPlayer.StarterPlayerScripts, 'LocalScript', 'TreasureCutscenes', 'prototype/core/Cutscenes.client.luau'},
	}
	if biome == 'cave' then
		local style = fs.readFile('prototype/core/UIStyle.luau')
		local meadow = rb.deserializePlace(fs.readFile('slice-v2/prototype/guardian-greybox.rbxl'))
		assert(meadow.ReplicatedStorage.UIStyle.Source == style, 'shared UIStyle differs from Meadow')
		table.insert(mounts, {place.ReplicatedStorage, 'ModuleScript', 'UIStyle', 'prototype/core/UIStyle.luau'})
	end
	for _, item in mounts do
		local node = item[1]:FindFirstChild(item[3])
		local prior = node and node.Source
		node = node or rb.Instance.new(item[2]); node.Name = item[3]
		node.Source, node.Parent = fs.readFile(item[4]), item[1]
		table.insert(changes, {node = node, prior = prior})
	end
	if biome == 'meadow' then
		local capture
		for _, node in place.StarterPlayer.StarterPlayerScripts:GetChildren() do
			if node:IsA('LocalScript') and node.Source:find('StudioPassCapture', 1, true) then capture = node end
		end
		assert(capture, 'existing capture client missing')
		table.insert(changes, {node = capture, prior = capture.Source})
		local source = fs.readFile('slice-v2/prototype/StudioPass.client.luau')
		-- Accept only the documented local release handshake, not unrelated source drift.
		local insert = '\t\tlocal cutscenes = player.PlayerGui:FindFirstChild("TreasureCutscenes")\n'
			.. '\t\tlocal release = cutscenes and cutscenes:FindFirstChild("ReleaseCamera")\n'
			.. '\t\tif release then release:Invoke() end -- Local presentation only; save the released camera.\n'
		local normalized = source:gsub('\r\n', '\n')
		local plain = normalized:gsub(insert:gsub('([^%w])', '%%%1'), '')
		local prior = capture.Source:gsub('\r\n', '\n')
		assert(prior == plain or prior == normalized, 'capture changed beyond local handshake')
		capture.Source = source
	end
	local compiled = 0
	for _, node in place:GetDescendants() do
		if node:IsA('LuaSourceContainer') then
			for level = 0, 2 do luau.compile(node.Source, {optimizationLevel = level}) end
			compiled += 1
		end
	end
	local output = rb.serializePlace(place)
	for _, change in changes do
		if change.prior then change.node.Source = change.prior else change.node:Destroy() end
	end
	assert(rb.serializePlace(place) == rb.serializePlace(rb.deserializePlace(before)), 'unrelated place state changed')
	assert(fs.readFile(backup) == backupBytes, 'backup changed')
	fs.writeFile(main, output)
	assert(fs.readFile(main) == output)
	fs.writeFile('treasure/' .. (cutfix and 'CUTFIX-BUILD-' or 'CUTSCENES-BUILD-') .. biome .. '.json', serde.encode('json', {
		state = 'PASS', place = main, backup = backup, compiled_O0_O1_O2 = compiled,
		input_sha256 = serde.hash('sha256', before), backup_sha256 = serde.hash('sha256', backupBytes),
		place_sha256 = serde.hash('sha256', output), complete_unrelated_serialization_exact = true,
		server_and_physics_and_existing_tests_exact = true, Studio = 'NOT RUN',
	}, true))
	print('PASS cutscenes ' .. biome .. ': compiled', compiled, 'scripts; complete unrelated state exact')
end
