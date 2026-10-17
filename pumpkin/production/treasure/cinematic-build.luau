-- Shared source-only Lune mount; complete canonical maps are the input.
return function(biome)
	local fs, rb, luau, serde = require('@lune/fs'), require('@lune/roblox'), require('@lune/luau'), require('@lune/serde')
	local main = biome == 'cave' and 'prototype/cave-v2.rbxl' or 'slice-v2/prototype/guardian-greybox.rbxl'
	local backup = main:gsub('%.rbxl$', '.pre-cine-bindingfix.rbxl')
	local before = fs.readFile(main)
	if not fs.isFile(backup) then fs.writeFile(backup, before) end
	local backupBytes = fs.readFile(backup)
	local p = rb.deserializePlace(before)
	local clients, core = p.StarterPlayer.StarterPlayerScripts, p.ReplicatedStorage.TreasureCore
	local module = core:FindFirstChild('CinematicMove')
	local client = clients:FindFirstChild('CinematicMovement')
	local priorModule = module and module.Source
	local priorClient = client and client.Source
	module = module or rb.Instance.new('ModuleScript'); module.Name = 'CinematicMove'
	module.Source = fs.readFile('prototype/core/CinematicMove.luau'); module.Parent = core
	client = client or rb.Instance.new('LocalScript'); client.Name = 'CinematicMovement'
	client.Source = fs.readFile('prototype/core/CinematicMove.client.luau'); client.Parent = clients
	local priorFeel = core.Feel.Source
	core.Feel.Source = fs.readFile('prototype/core/Feel.luau')
	local compiled = 0
	for _, n in p:GetDescendants() do if n:IsA('LuaSourceContainer') then
		for level = 0, 2 do luau.compile(n.Source, {optimizationLevel = level}) end
		compiled += 1
	end end
	local bytes = rb.serializePlace(p)
	-- Stronger than checking selected speed constants: every old property/source exact.
	if priorModule then module.Source = priorModule else module:Destroy() end
	if priorClient then client.Source = priorClient else client:Destroy() end
	core.Feel.Source = priorFeel
	assert(rb.serializePlace(p) == rb.serializePlace(rb.deserializePlace(before)), 'unrelated serialized state changed')
	assert(fs.readFile(backup) == backupBytes, 'backup changed')
	fs.writeFile(main, bytes)
	assert(fs.readFile(main) == bytes)
	fs.writeFile('treasure/CINEMATIC-BUILD-' .. biome .. '.json', serde.encode('json', {
		state = 'PASS', place = main, backup = backup,
		backup_sha256 = serde.hash('sha256', backupBytes), input_sha256 = serde.hash('sha256', before), place_sha256 = serde.hash('sha256', bytes),
		compiled_O0_O1_O2 = compiled, complete_unrelated_serialization_exact = true,
		server_WalkSpeed_values_and_all_test_sources_unchanged = true, Studio = 'NOT RUN',
	}, true))
	print('PASS cinematic ' .. biome .. ': source-only mount, all unrelated state exact; compiled', compiled)
end
