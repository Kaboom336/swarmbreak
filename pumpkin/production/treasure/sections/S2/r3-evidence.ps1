$ErrorActionPreference='Stop'
$dir='treasure/sections/S2/'
$metrics=Get-Content ($dir+'METRICS-R3.json') -Raw | ConvertFrom-Json
$contact=Get-Content ($dir+'r3-after-physical-contact.json') -Raw | ConvertFrom-Json
$audit=Get-Content ($dir+'r3-AUDIT.json') -Raw | ConvertFrom-Json
$removed=Get-Content ($dir+'REMOVED-R3.json') -Raw | ConvertFrom-Json
$mesh=Get-Content ($dir+'r3-after-mesh-contact.json') -Raw | ConvertFrom-Json
foreach($goal in $metrics.goals.PSObject.Properties){if(-not $goal.Value){throw ('Camera goal failed: '+$goal.Name)}}
foreach($field in @('physical_penetrations','kit_physical_penetrations','kit_support_errors','floating_assemblies','lane_buffer_errors')){if($contact.$field.Count){throw ('Contact failures: '+$field)}}
foreach($kit in $mesh){if([Math]::Abs($kit.base_error) -gt .002){throw 'FBX base mismatch'}}
if($audit.compiled_O0_O1_O2 -ne 72 -or $audit.unrelated_sources_preserved -ne 71 -or -not $audit.workspace_equal -or -not $audit.physics_floor_tags_equal){throw 'Source/protected-world audit failed'}
if(-not $removed.protected_solids_all_other_fields_equal -or -not $removed.lanes_and_floor_tags_exactly_equal){throw 'Protected part changes'}
if(-not (Select-String -LiteralPath ($dir+'r3-contracts.log') -Pattern 'PASS nonzero origin' -Quiet)){throw 'Missing contract PASS'}
$hashes=[ordered]@{}
foreach($file in @('slice-v2/prototype/guardian-greybox.rbxl','slice-v2/prototype/guardian-greybox.pre-s2r3.rbxl','prototype/meadow-v4/Section2.luau',($dir+'r3-rojo.rbxl'),($dir+'r3-before.json'),($dir+'r3-after.json'),($dir+'METRICS-R3.json'),($dir+'REMOVED-R3.json'),($dir+'CRITIC-R3.md'),($dir+'RESULT.md'),($dir+'SBS-R3.jpg'),($dir+'TARGET.png'),($dir+'r3-deliver.log'),($dir+'r3-behavior.log'),($dir+'r3-contracts.log'),($dir+'r3-50-seed.log'))){$hashes[$file]=(Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash}
$out=[ordered]@{artifact_hashes=$hashes;compile_and_preservation=$audit;contact=$contact;mesh=$mesh;metrics=$metrics;solid_palette_edits=$removed.wall_palette_edits.Count;independent_blind_reviews=1;visual_correction_rounds=1;sole_changed_mounted_source='ReplicatedStorage.MeadowV4.Section2';protected_solids_all_other_fields_equal=$true;lanes_floor_tags_and_palettes_equal=$true;live_StudioPassAll='UNKNOWN: all nine not run';owner_visual_acceptance='UNKNOWN';qualitative_limits='Protected rectangular wall silhouettes and diagonal opening remain; mounted timber corbels rather than grounded posts; orchard crops tightly in the locked walk camera';render_limits='Native materials lack Roblox Rock/Slate/Wood texture; point lights, text and shafts approximate; older kits use native proxies, new kits use original FBX';commit='NONE by this agent';publish='NONE'}
$out | ConvertTo-Json -Depth 25 | Set-Content ($dir+'FINAL-EVIDENCE-R3.json') -Encoding UTF8
Write-Output 'PASS R3 hashes, camera gates, 72 compiled / 71 preserved sources, zero contacts, protected lanes/floors/solids'
