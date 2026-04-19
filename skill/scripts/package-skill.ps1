[CmdletBinding()]
param(
    [string]$OutputName,
    [switch]$DryRun,
    [switch]$Help
)

if ($Help) {
    @"
package-skill.ps1

Creates a zip archive in dist/ with the reusable skill contents.

Usage:
  pwsh -File skill/scripts/package-skill.ps1
"@
    exit 0
}

. (Join-Path $PSScriptRoot "lib/common.ps1")

$repoRoot = Get-RepoRoot
$distRoot = Ensure-Directory (Join-Path $repoRoot "dist")

if (-not $OutputName) {
    $OutputName = "onec-vanessa-skill-{0}.zip" -f (Get-Date -Format "yyyyMMdd-HHmmss")
}

$destination = Join-Path $distRoot $OutputName
$includePaths = @(
    "README.md",
    "install",
    "skill",
    "examples",
    "ci",
    "docs",
    ".env.example"
)

if ($DryRun) {
    $includePaths | ForEach-Object { Write-Host "[dry-run] include $_" }
    Write-Host "[dry-run] output $destination"
    exit 0
}

$stagingRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("onec-vanessa-skill-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $stagingRoot | Out-Null

foreach ($path in $includePaths) {
    $source = Join-Path $repoRoot $path
    if (Test-Path -LiteralPath $source) {
        Copy-Item -LiteralPath $source -Destination $stagingRoot -Recurse -Force
    }
}

if (Test-Path -LiteralPath $destination) {
    Remove-Item -LiteralPath $destination -Force
}

Compress-Archive -Path (Join-Path $stagingRoot "*") -DestinationPath $destination
Remove-Item -LiteralPath $stagingRoot -Recurse -Force

Write-Host "Package created: $destination"
