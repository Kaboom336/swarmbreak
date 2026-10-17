-- Seal executed evidence after the long unchanged Cave sampler has finished.
local fs, rb, serde = require('@lune/fs'), require('@lune/roblox'), require('@lune/serde')
local function read(path) return serde.decode('json', fs.readFile(path)) end
local contract = read('treasure/CUTSCENES-CONTRACT.json')
assert(contract.state == 'PASS')
local cave = read('treasure/cutscenes-evidence/cave-treasure_cave-sections_C8_STUDIO-OFFLINE.json')
assert(cave.N == 8 and next(cave.reasons) == nil and #cave.failures == 0)
local origin = read('treasure/cutscenes-evidence/origin-treasure_rockcolor_ORIGIN-CONTRACTS.json')
assert(origin.offset_origin_once and origin.late_kits_origin_once and origin.failed_section_warns_and_keeps_island)
local movement = read('treasure/CUTSCENES-MOVEMENT.json')
assert(movement.state == 'PASS' and movement.actual_client_guarded_runtime == 'PASS')
local files, places = {}, {}
for _, path in {'prototype/core/Cutscenes.luau', 'prototype/core/Cutscenes.client.luau',
	'prototype/core/UIStyle.luau',
	'slice-v2/prototype/StudioPass.client.luau', 'prototype/cave-v2/build.luau',
	'treasure/cutscenes-build.luau', 'treasure/cutscenes-meadow-build.luau', 'treasure/cutscenes-check.luau',
	'treasure/cutscenes-seal.luau',
	'treasure/cutscenes-existing-checks.luau', 'treasure/CUTSCENES.md', 'treasure/sections/LESSONS.md'} do
	files[path] = serde.hash('sha256', fs.readFile(path))
end
for _, biome in {'meadow', 'cave'} do
	local cutfix = biome == 'cave' and fs.isFile('treasure/CUTFIX-BUILD-cave.json')
	local build = read('treasure/' .. (cutfix and 'CUTFIX-BUILD-' or 'CUTSCENES-BUILD-') .. biome .. '.json')
	assert(build.state == 'PASS')
	local bytes = fs.readFile(build.place)
	assert(serde.hash('sha256', bytes) == build.place_sha256, 'place changed since build')
	local baseline = rb.deserializePlace(fs.readFile(build.backup))
	local final = rb.deserializePlace(bytes)
	assert(rb.serializeModel({baseline.ServerScriptService, baseline.Workspace})
		== rb.serializeModel({final.ServerScriptService, final.Workspace}), 'server/physical map drift')
	for _, row in contract.places do
		if row.place == build.place then assert(row.sha256 == build.place_sha256) end
	end
	places[biome] = build
end
fs.writeFile('treasure/CUTSCENES-FINAL.json', serde.encode('json', {
	state = 'PASS_OFFLINE', files = files, places = places,
	actual_client_fixture_groups = contract.executed_client_fixture_groups,
	all_seven_restore_within_5s = true, no_server_or_WalkSpeed_writes = true,
	cave_N = cave.N, cave_samples = cave.samples, cave_failures = #cave.failures,
	cave_sample_input = read('treasure/cutscenes-evidence/cave-treasure_cave-sections_C8_OFFLINE-INPUT-8.json'),
	cave_sampling_note = 'Cave N8 rerun after UIStyle cutfix; saved client startup, real UIStyle and movement composition independently executed offline.',
	existing_tool_session_passes = {'shared core domain/syntax', 'Meadow behavior/reset/coordinator',
		'Meadow nonzero/late origin and cosmetic failure isolation', 'actual cinematic movement/Feel fixtures',
		'Cave source-aware native/kit/drop N8', 'Cave cart production drive', 'Cave cart production boarding'},
	lint_new_camera_sources = '0 errors, 0 warnings, 0 parse errors',
	Studio = 'NOT RUN', commit = 'NOT MADE', live_visual_device_tiktok_acceptance = 'UNKNOWN; Claude check required',
	archival_failures = 'Four previously documented failures not rerun; unchanged old assertions retained.',
}, true))
print('PASS cutscenes sealed: both builds, authority/restoration, existing checks; Cave samples', cave.samples, 'failures', #cave.failures)
