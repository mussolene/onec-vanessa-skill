[CmdletBinding()]
param(
    [string]$EnvFile = ".env",
    [switch]$SkipDoctor,
    [switch]$DryRun,
    [switch]$Help
)

if ($Help) {
    @"
bootstrap.ps1

Prepares the local workspace for this skill:
- creates runtime folders
- copies .env.example to .env when missing
- copies config templates into .onec-test/
- optionally runs doctor.ps1

Usage:
  pwsh -File skill/scripts/bootstrap.ps1
  pwsh -File skill/scripts/bootstrap.ps1 -SkipDoctor
  pwsh -File skill/scripts/bootstrap.ps1 -DryRun
"@
    exit 0
}

. (Join-Path $PSScriptRoot "lib/common.ps1")

$repoRoot = Get-RepoRoot
$skillRoot = Get-SkillRoot
$envTarget = Join-Path $repoRoot $EnvFile
$envExample = Join-Path $repoRoot ".env.example"
$localConfigRoot = Join-Path $repoRoot ".onec-test"
$uiConfigTarget = Join-Path $localConfigRoot "VAParams.local.json"
$xunitConfigTarget = Join-Path $localConfigRoot "XUnitParams.local.json"

$actions = @()
$actions += "Ensure artifacts/ui, artifacts/xunit, artifacts/doctor, artifacts/packages, dist"
$actions += "Ensure .onec-test"
$actions += "Copy .env.example from skill template when missing"
$actions += "Copy .env from .env.example when missing"
$actions += "Copy VA and xUnit local config templates when missing"

if ($DryRun) {
    $actions | ForEach-Object { Write-Host "[dry-run] $_" }
    exit 0
}

Ensure-Directory (Join-Path $repoRoot "artifacts/ui") | Out-Null
Ensure-Directory (Join-Path $repoRoot "artifacts/xunit") | Out-Null
Ensure-Directory (Join-Path $repoRoot "artifacts/doctor") | Out-Null
Ensure-Directory (Join-Path $repoRoot "artifacts/packages") | Out-Null
Ensure-Directory (Join-Path $repoRoot "dist") | Out-Null
Ensure-Directory $localConfigRoot | Out-Null

if (-not (Test-Path -LiteralPath $envExample)) {
    Copy-Item -LiteralPath (Join-Path $skillRoot "templates/config/env.template") -Destination $envExample
}

if (-not (Test-Path -LiteralPath $envTarget)) {
    Copy-Item -LiteralPath $envExample -Destination $envTarget
}

if (-not (Test-Path -LiteralPath $uiConfigTarget)) {
    Copy-Item -LiteralPath (Join-Path $skillRoot "templates/config/VAParams.template.json") -Destination $uiConfigTarget
}

if (-not (Test-Path -LiteralPath $xunitConfigTarget)) {
    Copy-Item -LiteralPath (Join-Path $skillRoot "templates/config/XUnitParams.template.json") -Destination $xunitConfigTarget
}

Write-Host "Bootstrap completed."
Write-Host "Local env: $envTarget"
Write-Host "Local config root: $localConfigRoot"

if (-not $SkipDoctor) {
    & (Join-Path $PSScriptRoot "doctor.ps1") -EnvFile $EnvFile
    exit $LASTEXITCODE
}

