[CmdletBinding()]
param(
    [string]$RunPath,
    [string]$OutputName = "artifacts-bundle.zip",
    [switch]$Help
)

if ($Help) {
    @"
collect-artifacts.ps1

Bundles one artifact directory into artifacts/packages/.

Usage:
  pwsh -File skill/scripts/collect-artifacts.ps1 -RunPath artifacts/ui/20260419-120000-run
"@
    exit 0
}

. (Join-Path $PSScriptRoot "lib/common.ps1")

$repoRoot = Get-RepoRoot
if (-not $RunPath) {
    throw "RunPath is required."
}

$sourcePath = Join-Path $repoRoot $RunPath
if (-not (Test-Path -LiteralPath $sourcePath)) {
    throw "Run path not found: $sourcePath"
}

$packagesRoot = Ensure-Directory (Join-Path $repoRoot "artifacts/packages")
$destination = Join-Path $packagesRoot $OutputName
if (Test-Path -LiteralPath $destination) {
    Remove-Item -LiteralPath $destination -Force
}

Compress-Archive -Path (Join-Path $sourcePath "*") -DestinationPath $destination
Write-Host "Created bundle: $destination"
