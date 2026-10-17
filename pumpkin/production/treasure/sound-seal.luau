local fs, serde = require('@lune/fs'), require('@lune/serde')
local files = {'SOUND-KIT.md','prototype/core/Audio.luau','prototype/core/Audio.client.luau',
	'slice-v2/prototype/Arena.luau',
	'prototype/core/CinematicMove.client.luau','treasure/sound-build.luau','treasure/sound-check.luau',
	'treasure/sound-existing-checks.luau','treasure/sound-live-check.luau',
	'slice-v2/prototype/guardian-greybox.rbxl','prototype/cave-v2.rbxl'}
local hashes = {}
for _, path in files do hashes[path] = serde.hash('sha256', fs.readFile(path)) end
local reports = {}
for _, name in {'SOUND-BUILD-meadow','SOUND-BUILD-cave','SOUND-CONTRACT','SOUND-MOVEMENT','SOUND-CUTSCENES'} do
	local path = 'treasure/' .. name .. '.json'
	local bytes = fs.readFile(path)
	assert(serde.decode('json', bytes).state == 'PASS', name .. ' failed')
	reports[path] = serde.hash('sha256', bytes)
end
for _, biome in {'meadow','cave'} do
	local report = serde.decode('json', fs.readFile('treasure/SOUND-BUILD-' .. biome .. '.json'))
	assert(hashes[report.place] == report.place_sha256, 'build/place drift')
	assert(serde.hash('sha256', fs.readFile(report.backup)) == report.backup_sha256, 'backup drift')
	assert(serde.hash('sha256', fs.readFile(report.stack_fix_backup)) == report.stack_fix_backup_sha256, 'stack backup drift')
end
fs.writeFile('treasure/SOUND-FINAL.json', serde.encode('json', {state = 'PASS', hashes = hashes, report_hashes = reports,
	offline_only = true, prior_live_check = 'OWNER-REPORTED: Claude 2026-10-17, 13 IDs load; Meadow music/ambience play',
	post_fix_live_listening = 'UNKNOWN', Studio_Play = 'NOT RUN',
	commit = 'NOT RUN', notes = 'Stack fix: actual audio client in both biomes, Keeper behavior/reset, movement and cutscenes pass. Selene audio clean; Arena has one pre-existing multiple_statements warning at line 227.'}, true))
print('PASS sound final seal: source, places, immutable backups and passing contract reports hashed')
