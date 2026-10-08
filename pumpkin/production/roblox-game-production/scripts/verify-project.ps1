[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$ProjectPath,
    [string]$ToolStorage = (Join-Path $env:USERPROFILE '.rokit\tool-storage'),
    [string]$ProjectFile = 'default.project.json',
    [string]$SourcePath = 'src',
    [string]$TestsPath = 'tests',
    [string]$TestRunner = 'tests/run.luau',
    [string]$BuildPath = 'out.rbxl',
    [string]$ReportPath
)

$ErrorActionPreference = 'Stop'
$project = (Resolve-Path -LiteralPath $ProjectPath).Path
foreach ($required in @('rokit.toml', $ProjectFile, $SourcePath, $TestsPath, $TestRunner)) {
    if (-not (Test-Path -LiteralPath (Join-Path $project $required))) {
        throw "Missing project input: $required"
    }
}
$pins = Get-Content -LiteralPath (Join-Path $project 'rokit.toml') -Raw
$toolPaths = @{}
foreach ($tool in @('stylua', 'selene', 'lune', 'rojo')) {
    $pattern = '(?m)^\s*' + $tool + '\s*=\s*"([A-Za-z0-9_-]+)/([A-Za-z0-9_-]+)@([0-9]+\.[0-9]+\.[0-9]+)"\s*$'
    $match = [regex]::Match($pins, $pattern)
    if (-not $match.Success) { throw "Missing supported exact version pin: $tool" }
    $relative = $match.Groups[1].Value.ToLowerInvariant() + '\' +
        $match.Groups[2].Value.ToLowerInvariant() + '\' +
        $match.Groups[3].Value + '\' + $tool + '.exe'
    $toolPaths[$tool] = Join-Path $ToolStorage $relative
    if (-not (Test-Path -LiteralPath $toolPaths[$tool])) {
        throw "Pinned binary missing: $($toolPaths[$tool]). Install project tools before running checks."
    }
}
$build = if ([IO.Path]::IsPathRooted($BuildPath)) { $BuildPath } else { Join-Path $project $BuildPath }
# Build into a separate file. A failed build must not replace the last playable artifact.
$staging = Join-Path ([IO.Path]::GetDirectoryName($build)) (([IO.Path]::GetFileNameWithoutExtension($build)) + '.checking.rbxl')
if (Test-Path -LiteralPath $staging) { throw "Staging file already exists; inspect it first: $staging" }
if ($ReportPath -and (Test-Path -LiteralPath $ReportPath)) { throw "Report exists; choose a new report path: $ReportPath" }
$results = [Collections.Generic.List[object]]::new()
$report = [ordered]@{
    project = $project
    projectFile = $ProjectFile
    startedUtc = [DateTime]::UtcNow.ToString('o')
    sourceRevision = $null
    workingTreeDirty = $null
    staticBuildStatus = 'failed'
    checks = $results
    artifact = $null
    sha256 = $null
    runtime = 'pending'
    multiplayer = 'pending'
    visual = 'pending'
    device = 'pending'
}
function Invoke-Check([string]$Name, [string]$Tool, [string[]]$ToolArguments) {
    Write-Host "Checking $Name"
    & $toolPaths[$Tool] @ToolArguments
    $code = $LASTEXITCODE
    $results.Add([ordered]@{ name = $Name; exitCode = $code })
    if ($code -ne 0) { throw "$Name failed (exit $code)." }
}
Push-Location -LiteralPath $project
try {
    $revision = & git rev-parse HEAD 2>$null
    if ($LASTEXITCODE -eq 0) {
        $report.sourceRevision = [string]$revision
        $dirty = & git status --porcelain 2>$null
        $report.workingTreeDirty = [bool]$dirty
    }
    Invoke-Check 'format' 'stylua' @('--check', $SourcePath, $TestsPath)
    Invoke-Check 'lint' 'selene' @($SourcePath)
    Invoke-Check 'Luau tests and syntax' 'lune' @('run', $TestRunner)
    Invoke-Check 'Rojo build' 'rojo' @('build', $ProjectFile, '-o', $staging)
    Move-Item -LiteralPath $staging -Destination $build -Force
    $report.staticBuildStatus = 'passed'
    $report.artifact = $build
    $report.sha256 = (Get-FileHash -LiteralPath $build -Algorithm SHA256).Hash
    Write-Host "Build passed: $build"
    Write-Host 'Runtime, multiplayer, visual and device verification remain pending.'
} finally {
    Pop-Location
    $report.finishedUtc = [DateTime]::UtcNow.ToString('o')
    if ($ReportPath) {
        $report | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $ReportPath -Encoding UTF8
    }
}
