$ErrorActionPreference='Stop'
$dir='treasure/sections/S2/'
$metrics=Get-Content ($dir+'METRICS-R2.json') -Raw | ConvertFrom-Json
$contact=Get-Content ($dir+'r2-after-physical-contact.json') -Raw | ConvertFrom-Json
$audit=Get-Content ($dir+'r2-AUDIT.json') -Raw | ConvertFrom-Json
$removed=Get-Content ($dir+'REMOVED-R2.json') -Raw | ConvertFrom-Json
$mesh=Get-Content ($dir+'r2-after-mesh-contact.json') -Raw | ConvertFrom-Json
foreach($goal in $metrics.goals.PSObject.Properties){if(-not $goal.Value){throw ('Camera goal failed: '+$goal.Name)}}
foreach($field in @('physical_penetrations','kit_physical_penetrations','kit_support_errors','floating_assemblies','lane_buffer_errors')){if($contact.$field.Count){throw ('Contact failures: '+$field)}}
foreach($kit in $mesh){if([Math]::Abs($kit.base_error) -gt .002){throw 'FBX base mismatch'}}
if($audit.compiled_O0_O1_O2 -ne 72 -or $audit.unrelated_sources_preserved -ne 71 -or -not $audit.workspace_equal -or -not $audit.physics_floor_tags_equal){throw 'Mounted-source or protected-world audit failed'}
$hashes=[ordered]@{}
foreach($file in @('slice-v2/prototype/guardian-greybox.rbxl','slice-v2/prototype/guardian-greybox.pre-s2r2.rbxl','prototype/meadow-v4/Section2.luau',($dir+'r2-rojo.rbxl'),($dir+'r2-before.json'),($dir+'r2-after.json'),($dir+'METRICS-R2.json'),($dir+'REMOVED-R2.json'),($dir+'CRITIC-R2.md'),($dir+'RESULT.md'),($dir+'SBS-R2.jpg'),($dir+'TARGET.png'),($dir+'r2-build-final.log'),($dir+'r2-behavior.log'),($dir+'r2-contracts.log'),($dir+'r2-50-seed.log'))){$hashes[$file]=(Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash}
$out=[ordered]@{artifact_hashes=$hashes;compile_and_preservation=$audit;contact=$contact;mesh=$mesh;metrics=$metrics;removed_cosmetics=$removed.removed_count;solid_palette_edits=$removed.physical_color_material_only.Count;cosmetic_palette_edits=$removed.restyled_cosmetics.Count;independent_blind_reviews=2;correction_rounds=2;sole_changed_mounted_source='ReplicatedStorage.MeadowV4.Section2';protected_solids_all_other_fields_equal=$removed.protected_solids_all_other_fields_equal;live_StudioPassAll='UNKNOWN: all nine not run';owner_visual_acceptance='UNKNOWN';qualitative_limits='Broad flat walls, thin rock cladding, weak orchard; destination is a wall glow, not a newly opened exit';render_limits='PointLight approximation; shadow-ray transparency only for emitting lamp/glow parents; text and Beam proxies labelled; older kit substitutions use native proxies';commit='NONE by this agent';publish='NONE'}
$out | ConvertTo-Json -Depth 20 | Set-Content ($dir+'FINAL-EVIDENCE-R2.json') -Encoding UTF8
Write-Output 'PASS R2 final hashes, camera gates, 72 compiled sources, 71 preserved sources, protected solids and zero contacts'
