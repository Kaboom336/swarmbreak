param([switch]$EvidenceOnly)
$ErrorActionPreference='Stop'
$taskRoot=(Resolve-Path '.').Path
$taskLune='C:/Users/zerha/.rokit/tool-storage/lune-org/lune/0.10.5/lune.exe'
$taskRojo='C:/Users/zerha/.rokit/tool-storage/rojo-rbx/rojo/7.4.4/rojo.exe'
if(-not $EvidenceOnly) {
& $taskLune run prototype/look-delivery.luau
if($LASTEXITCODE -ne 0){throw 'Look delivery failed'}
& $taskLune run prototype/look-check.luau
if($LASTEXITCODE -ne 0){throw 'Look preservation failed'}
& $taskRojo build prototype/meadow-v4.project.json -o prototype/meadow-v4.rbxl
if($LASTEXITCODE -ne 0){throw 'Standalone build failed'}
& ([scriptblock]::Create((Get-Content prototype/merge-v4-verify.ps1 -Raw)))
}
$taskBefore=Get-FileHash -Algorithm SHA256 prototype/guardian-greybox.pre-look.rbxl
$taskAfter=Get-FileHash -Algorithm SHA256 prototype/guardian-greybox.rbxl
$taskEvidence=[ordered]@{
 state='PASS';backup_sha256=$taskBefore.Hash;place_sha256=$taskAfter.Hash
 scene_sha256=(Get-FileHash -Algorithm SHA256 prototype/meadow-v4/scene.json).Hash
 collision_violations=(Get-Content treasure/map-v4/collision-audit.json -Raw | ConvertFrom-Json).violation_count_recorded
 merge_audit_state=(Get-Content prototype/MERGE-V4-OFFLINE.json -Raw | ConvertFrom-Json).state
 render_manifest_sha256=(Get-Content treasure/map-v4/LOOK-RENDER-AFTER.json -Raw | ConvertFrom-Json).manifest_sha256
 before_after_jpg_sha256=(Get-FileHash -Algorithm SHA256 treasure/map-v4/build-look.jpg).Hash
 unchanged_live_test_expectations=@('LoopTest.run','LoopTest.pvp','TrapTest.exercise')
 live_tests='UNKNOWN / NOT RUN';commit='NONE';publish='NONE'
}
if($taskEvidence.collision_violations -ne 0 -or $taskEvidence.merge_audit_state -ne 'PASS'){throw 'Look evidence check failed'}
if($taskEvidence.scene_sha256 -ne $taskEvidence.render_manifest_sha256){throw 'Render manifest differs from delivered map'}
$taskEvidence | ConvertTo-Json -Depth 5 | Set-Content treasure/map-v4/LOOK-VERIFY.json -Encoding UTF8
