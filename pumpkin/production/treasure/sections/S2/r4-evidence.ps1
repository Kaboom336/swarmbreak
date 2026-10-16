$ErrorActionPreference='Stop'
$dir='treasure/sections/S2/'
$metrics=Get-Content ($dir+'METRICS-R4.json') -Raw | ConvertFrom-Json
$contact=Get-Content ($dir+'r4-after-physical-contact.json') -Raw | ConvertFrom-Json
$audit=Get-Content ($dir+'r4-AUDIT.json') -Raw | ConvertFrom-Json
$preserved=Get-Content ($dir+'REMOVED-R4.json') -Raw | ConvertFrom-Json
$enclosure=Get-Content ($dir+'r4-ENCLOSURE.json') -Raw | ConvertFrom-Json
$clearance=Get-Content ($dir+'r4-CLEARANCE.json') -Raw | ConvertFrom-Json
$drops=Get-Content ($dir+'r4-DROPS.json') -Raw | ConvertFrom-Json
$dropInput=Get-Content ($dir+'r4-DROP-INPUT.json') -Raw | ConvertFrom-Json
$dropParity=Get-Content ($dir+'r4-DROP-PARITY.json') -Raw | ConvertFrom-Json
$climb=Get-Content ($dir+'r4-CLIMB.json') -Raw | ConvertFrom-Json
foreach($field in @('physical_penetrations','kit_physical_penetrations','kit_support_errors','floating_assemblies','lane_buffer_errors')){if($contact.$field.Count){throw ('Contact failure: '+$field)}}
if($audit.compiled_O0_O1_O2 -ne 72 -or $audit.unrelated_sources_preserved -ne 71 -or -not $audit.workspace_equal -or -not $audit.all_non_hill_physics_floor_tags_equal){throw 'Source audit failed'}
if(-not $preserved.lanes_floors_cover_court_exact -or -not $preserved.all_inner_rock_courses_facets_vaults_exact){throw 'Protection audit failed'}
if($enclosure.failures.Count -or $clearance.bad -ne 0 -or $drops.state -ne 'PASS' -or $drops.failures.Count -or $drops.workers.Count -ne 3 -or -not $climb.no_new_colliding_shoulder_slopes){throw 'Offline geometry/drop checks failed'}
if($dropInput.Hash -ne $dropParity.tested_artifact_sha256 -or -not $dropParity.all_collidable_and_query_parts_exact -or -not $dropParity.all_kit_placements_exact -or $dropParity.delivered_artifact_sha256 -ne (Get-FileHash slice-v2/prototype/guardian-greybox.rbxl -Algorithm SHA256).Hash){throw 'Drop input parity failed'}
if(-not (Select-String -LiteralPath ($dir+'r4-contracts.log') -Pattern 'PASS nonzero origin' -Quiet)){throw 'Contracts not passed'}
if(-not (Select-String -LiteralPath ($dir+'r4-50-seed.log') -Pattern 'PASS 50-seed actual 3D walking-floor' -Quiet)){throw '50-seed walking contract missing'}
if(-not (Select-String -LiteralPath ($dir+'r4-drop-final.log') -Pattern '^PASS 31824 samples 0 failures' -Quiet)){throw 'Final N8 drop lattice not finished'}
$hashes=[ordered]@{}
foreach($file in @('slice-v2/prototype/guardian-greybox.rbxl','slice-v2/prototype/guardian-greybox.pre-s2r4.rbxl','prototype/meadow-v4/Section2.luau',($dir+'r4-rojo.rbxl'),($dir+'r4-after.json'),($dir+'METRICS-R4.json'),($dir+'REMOVED-R4.json'),($dir+'CRITIC-R4.md'),($dir+'RESULT.md'),($dir+'SBS-R4.jpg'),($dir+'r4-DROPS.json'),($dir+'r4-drop-final.log'),($dir+'r4-CLEARANCE.json'),($dir+'r4-ENCLOSURE.json'),($dir+'r4-CLIMB.json'),($dir+'r4-DROP-PARITY.json'),($dir+'r4-DROP-INPUT.json'),($dir+'r4-drop-input.rbxl'),($dir+'r4-DROPS-1.json'),($dir+'r4-DROPS-2.json'),($dir+'r4-DROPS-3.json'),($dir+'r4-drop-1.log'),($dir+'r4-drop-2.log'),($dir+'r4-drop-3.log'))){$hashes[$file]=(Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash}
$misses=@($metrics.goals.PSObject.Properties | Where-Object {-not $_.Value} | ForEach-Object Name)
$out=[ordered]@{artifact_hashes=$hashes;source_audit=$audit;preservation_summary=@{protected_parts=$preserved.unchanged_protected_parts;hill_edits=$preserved.authorized_hill_edits.Count;hill_removals=$preserved.authorized_hill_removals.Count;unchanged_lanes_floors_cover_court=$true;unchanged_inner_blockers=$true};contact=$contact;enclosure=$enclosure;clearance=$clearance;drops=$drops;camera=$metrics;camera_misses=$misses;blind_critics=1;final_visual_corrections=1;visual_acceptance='NOT MET';live_StudioPassAll='UNKNOWN: all nine not run';owner_acceptance='UNKNOWN';commit='NONE';publish='NONE';render_limits='Offline materials, point lights, text, shafts and older kit proxies differ from Studio'}
$out['drop_input_parity']=$dropParity
$out['climb']=$climb
$out | ConvertTo-Json -Depth 30 | Set-Content ($dir+'FINAL-EVIDENCE-R4.json') -Encoding UTF8
Write-Output ('PASS preservation/contact/contracts/native clearance/drop; camera misses: '+($misses -join ', '))
