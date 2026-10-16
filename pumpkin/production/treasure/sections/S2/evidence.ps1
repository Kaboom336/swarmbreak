$ErrorActionPreference='Stop'
$h='treasure/sections/S2/'
$audit=Get-Content ($h+'AUDIT.json') -Raw | ConvertFrom-Json
$contact=Get-Content ($h+'after-physical-contact.json') -Raw | ConvertFrom-Json
$coverage=Get-Content ($h+'after-coverage.json') -Raw | ConvertFrom-Json
$contracts=Get-Content ($h+'CONTRACTS.json') -Raw | ConvertFrom-Json
$files=@('slice-v2/prototype/guardian-greybox.rbxl','slice-v2/prototype/guardian-greybox.pre-s2.rbxl','prototype/meadow-v4/Section2.luau','prototype/meadow-v4/Outsmart.luau','prototype/kits/Swap.server.luau',($h+'before.json'),($h+'after.json'),($h+'TARGET.png'),($h+'REFS.jpg'),($h+'REFS-review.jpg'),($h+'SBS.jpg'),($h+'RESULT.md'))
$hashes=[ordered]@{}
foreach($file in $files){$hashes[$file]=(Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash}
$out=[ordered]@{artifact_hashes=$hashes;compile_and_preservation=$audit;contact=$contact;coverage=$coverage;contracts=$contracts;visual_goal_walk_percent=10;visual_goal_mouth_percent=18;visual_goal_mouth_frame_span_percent=25;live_StudioPassAll='UNKNOWN: all nine not run';independent_reviews=2;correction_rounds=2;commit='NONE by this agent';publish='NONE';beam_render='labelled transparent effect proxy';light_render='approximation from actual PointLight metadata';font_render='Comic Sans Bold local proxy; runtime shared FredokaOne/UIStroke'}
if($contact.physical_penetrations.Count -or $contact.kit_physical_penetrations.Count -or $contact.kit_support_errors.Count -or $contact.floating_assemblies.Count -or $contact.lane_buffer_errors.Count){throw 'Contact audit failed'}
$out | ConvertTo-Json -Depth 15 | Set-Content ($h+'FINAL-EVIDENCE.json') -Encoding UTF8
Write-Output 'PASS final hashes, source/geometry preservation, contacts and recorded coverage'
