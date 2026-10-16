$ErrorActionPreference='Stop'
$dir='treasure/sections/S2/'
$audit=Get-Content ($dir+'CLOSE-SIGNATURES.json') -Raw | ConvertFrom-Json
$source=Get-Content ($dir+'close-AUDIT.json') -Raw | ConvertFrom-Json
$contact=Get-Content ($dir+'close-after-physical-contact.json') -Raw | ConvertFrom-Json
$drops=Get-Content ($dir+'close-DROPS.json') -Raw | ConvertFrom-Json
if($audit.status -ne 'PASS' -or -not $source.physics_floor_tags_equal -or $source.compiled_O0_O1_O2 -ne 72 -or $source.unrelated_sources_preserved -ne 70){throw 'Source/signature check failed'}
foreach($field in @('physical_penetrations','kit_physical_penetrations','kit_support_errors','floating_assemblies','lane_buffer_errors')){if($contact.$field.Count){throw ('Contact failure: '+$field)}}
if($drops.state -ne 'PASS' -or $drops.samples -ne 31824 -or $drops.failures.Count -or $drops.workers.Count -ne 3){throw 'DropSample failed'}
if(-not (Select-String -LiteralPath ($dir+'close-contracts.log') -Pattern 'PASS nonzero origin' -Quiet)){throw 'Contracts failed'}
if(-not (Select-String -LiteralPath ($dir+'close-50-seed.log') -Pattern 'PASS 50-seed actual 3D walking-floor' -Quiet)){throw '50-seed check failed'}
if(-not (Select-String -LiteralPath ($dir+'close-behavior.log') -Pattern 'PASS actual production reset' -Quiet)){throw 'Behavior contracts failed'}
$artifact='slice-v2/prototype/guardian-greybox.rbxl'
$hash=(Get-FileHash -LiteralPath $artifact -Algorithm SHA256).Hash
if($hash.ToLower() -ne $audit.artifact_sha256){throw 'Artifact changed after audit'}
$hashes=[ordered]@{}
foreach($path in @($artifact,'slice-v2/prototype/guardian-greybox.pre-s2close.rbxl','slice-v2/prototype/guardian-greybox.pre-s2r4.rbxl','prototype/meadow-v4/Section2.luau','prototype/meadow-v4/Outsmart.luau',($dir+'close-rojo.rbxl'),($dir+'close-after.json'),($dir+'close-after-mouth.png'),($dir+'CLOSE-SIGNATURES.json'),($dir+'close-AUDIT.json'),($dir+'close-after-physical-contact.json'),($dir+'close-contracts.log'),($dir+'close-50-seed.log'),($dir+'close-behavior.log'),($dir+'close-DROPS.json'),($dir+'close-DROPS-1.json'),($dir+'close-DROPS-2.json'),($dir+'close-DROPS-3.json'),($dir+'RESULT.md'),'treasure/sections/LESSONS.md')){$hashes[$path]=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash}
$out=[ordered]@{state='PASS';section_status='REVISIT; four-round cap; round 3 plus cosmetic fixes';source=$source;signatures=$audit;contact=$contact;drop_samples=$drops.samples;drop_routes=$drops.all_routes_executed_exactly_once;artifact_hashes=$hashes;mouth_camera='Inspected offline render; full SHORTCUT readable';owner_report='Claude judged R4 in live Studio: not better than R3';live_StudioPassAll='UNKNOWN; all nine not run';commit='NONE';publish='NONE'}
$out | ConvertTo-Json -Depth 35 | Set-Content ($dir+'FINAL-EVIDENCE-CLOSE.json') -Encoding UTF8
Write-Output 'PASS close-out: strict R3 signatures, zero contacts, contracts, 50 seeds, 31824 DropSample samples'
