[CmdletBinding()]
param(
    [string]$FeaturePath,
    [string]$EnvFile = ".env",
    [switch]$DryRun,
    [switch]$Help
)

if ($Help) {
    @"
debug-ui.ps1

Opens Vanessa Automation with settings loaded but without StartFeaturePlayer.

Usage:
  pwsh -File skill/scripts/debug-ui.ps1 -FeaturePath examples/ui/smoke-open-form.feature
"@
    exit 0
}

. (Join-Path $PSScriptRoot "lib/common.ps1")

$repoRoot = Get-RepoRoot
$envMap = Import-SkillEnv -Path (Join-Path $repoRoot $EnvFile)
$runPath = New-RunContext -Category "ui" -Name "debug"

if (-not $FeaturePath) {
    $FeaturePath = Get-Setting -EnvMap $envMap -Name "OVS_UI_SMOKE_PATH" -Default "examples/ui"
}

$resolvedFeaturePath = Join-Path $repoRoot $FeaturePath
$librariesPath = Join-Path $repoRoot (Get-Setting -EnvMap $envMap -Name "OVS_UI_LIBRARIES" -Default "examples/ui/libraries")
$configPath = Join-Path $runPath "VAParams.debug.json"
$logPath = Join-Path $runPath "stdout.log"
$commandPath = Join-Path $runPath "command.txt"

$vaConfig = [ordered]@{
    "КаталогФич" = $resolvedFeaturePath
    "КаталогиБиблиотек" = @($librariesPath)
    "ДелатьЛогВыполненияСценариевВТекстовыйФайл" = $true
    "ИмяФайлаЛогВыполненияСценариев" = (Join-Path $runPath "va-debug.log")
}
Save-Json -Path $configPath -Value $vaConfig

$bin = Get-Setting -EnvMap $envMap -Name "OVS_1C_BIN" -Required
$ib = Get-Setting -EnvMap $envMap -Name "OVS_IB_CONNECTION" -Required
$user = Get-Setting -EnvMap $envMap -Name "OVS_DB_USER"
$password = Get-Setting -EnvMap $envMap -Name "OVS_DB_PASSWORD"
$vanessa = Get-Setting -EnvMap $envMap -Name "OVS_VANESSA_EPF" -Required

$arguments = @("ENTERPRISE", $ib)
if ($user) { $arguments += "/N$user" }
if ($password) { $arguments += "/P$password" }
$arguments += @("/Execute", $vanessa, "/C", "VAParams=$configPath")

Write-CommandFile -Path $commandPath -FilePath $bin -Arguments $arguments
$result = Invoke-LoggedCommand -FilePath $bin -Arguments $arguments -StdoutPath $logPath -DryRun:$DryRun

Save-Json -Path (Join-Path $runPath "summary.json") -Value @{
    mode = "ui-debug"
    featurePath = $resolvedFeaturePath
    runPath = $runPath
    launched = $result.Launched
    note = "Debug mode loads VAParams and opens Vanessa Automation without StartFeaturePlayer."
}

Write-Host "UI debug artifacts: $runPath"
exit $result.ExitCode

