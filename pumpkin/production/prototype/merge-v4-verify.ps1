$ErrorActionPreference = 'Stop'
$taskRoot = (Resolve-Path '.').Path
$taskLog = Join-Path $taskRoot 'prototype/MERGE-V4-VERIFY.log'
$taskLune = 'C:/Users/zerha/.rokit/tool-storage/lune-org/lune/0.10.5/lune.exe'
$taskSelene = 'C:/Users/zerha/.rokit/tool-storage/kampfkarren/selene/0.31.0/selene.exe'
$taskStyLua = 'C:/Users/zerha/.rokit/tool-storage/johnnymorganz/stylua/2.0.2/stylua.exe'
'Meadow v4 offline verification; Studio runtime UNKNOWN' | Set-Content -LiteralPath $taskLog -Encoding UTF8
$taskFailures = @()
function Write-MergeLog { process { $_.ToString() | Add-Content -LiteralPath $taskLog -Encoding UTF8; $_ } }
function Run-MergeCheck($name, $exe, $arguments, $directory, $historical = $false) {
    Push-Location -LiteralPath $directory
    try {
        "CHECK $name" | Write-MergeLog
        $taskOldPreference = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        & $exe @arguments 2>&1 | Write-MergeLog
        $code = $LASTEXITCODE
        $ErrorActionPreference = $taskOldPreference
        "EXIT $code : $name" | Write-MergeLog
        if ($code -ne 0 -and -not $historical) { $script:taskFailures += $name }
        if ($code -ne 0 -and $historical) {
            'HISTORICAL FAIL: immutable guardian-source contract superseded by this merge; see fresh backup parity.' |
                Write-MergeLog
        }
    } finally { Pop-Location }
}
Run-MergeCheck 'v4 builder/floors/drops/mouth contact/clearance/test routes/source parity' $taskLune @('run','prototype/merge-v4-check.luau') $taskRoot
Run-MergeCheck 'production tunnel callbacks' $taskLune @('run','prototype/merge-v4-tunnel-check.luau') $taskRoot
Run-MergeCheck 'sampled Keeper sweep' $taskLune @('run','prototype/merge-v4-sweep.luau') $taskRoot
$taskPrototype = Join-Path $taskRoot 'slice-v2/prototype'
foreach ($name in @('check','keeper-check','kit-check','keeper-clearance')) {
    Run-MergeCheck $name $taskLune @('run',"$name.luau") $taskPrototype
}
foreach ($name in @('verify','ravine-test','tunnel-test')) {
    Run-MergeCheck $name $taskLune @('run',"prototype/meadow-v4/$name.luau") $taskRoot
}
$taskFiles = @('Arena.luau','Greybox.server.luau','GreyboxConfig.luau','Layout.luau','LoopTest.luau','TrapTest.luau','Scene.luau','Traps.luau','../../prototype/meadow-v4/Gameplay.luau','../../prototype/meadow-v4/ProductionTunnelController.luau')
Run-MergeCheck 'selene' $taskSelene $taskFiles $taskPrototype
Run-MergeCheck 'stylua' $taskStyLua (@('--check') + $taskFiles) $taskPrototype
foreach ($name in @('home-art-check','home-round3-check')) {
    Run-MergeCheck $name $taskLune @('run',"$name.luau") $taskPrototype $true
}
Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $taskRoot 'prototype/guardian-greybox.pre-v4.rbxl'),(Join-Path $taskRoot 'prototype/guardian-greybox.rbxl'),(Join-Path $taskRoot 'slice-v2/prototype/guardian-greybox.rbxl') |
    Format-List | Out-String | Write-MergeLog
if ($taskFailures.Count) { throw "Required checks failed: $($taskFailures -join ', ')" }
'PASS required offline checks; two superseded historical preservation tests FAIL; Studio UNKNOWN' |
    Write-MergeLog
