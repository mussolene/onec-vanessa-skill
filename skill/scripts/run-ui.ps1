[CmdletBinding()]
param(
    [string]$FeaturePath,
    [string]$Tags,
    [ValidateSet("Native", "VRunner")]
    [string]$Backend = "Native",
    [ValidateSet("CI", "Local", "Smoke")]
    [string]$Profile = "CI",
    [string]$EnvFile = ".env",
    [switch]$DryRun,
    [switch]$Help
)

if ($Help) {
    @"
run-ui.ps1

Runs Vanessa Automation UI/BDD tests.

Usage:
  pwsh -File skill/scripts/run-ui.ps1 -FeaturePath examples/ui/smoke-open-form.feature
  pwsh -File skill/scripts/run-ui.ps1 -FeaturePath examples/ui -Tags '@smoke'
  pwsh -File skill/scripts/run-ui.ps1 -Profile Smoke
"@
    exit 0
}

. (Join-Path $PSScriptRoot "lib/common.ps1")

$repoRoot = Get-RepoRoot
$envMap = Import-SkillEnv -Path (Join-Path $repoRoot $EnvFile)
$runPath = New-RunContext -Category "ui" -Name "run"

if (-not $FeaturePath) {
    if ($Profile -eq "Smoke") {
        $FeaturePath = Get-Setting -EnvMap $envMap -Name "OVS_UI_SMOKE_PATH" -Default "examples/ui"
    }
    else {
        $FeaturePath = Get-Setting -EnvMap $envMap -Name "OVS_UI_PATH" -Default "examples/ui"
    }
}

$resolvedFeaturePath = Join-Path $repoRoot $FeaturePath
$librariesPath = Join-Path $repoRoot (Get-Setting -EnvMap $envMap -Name "OVS_UI_LIBRARIES" -Default "examples/ui/libraries")

$configPath = Join-Path $runPath "VAParams.generated.json"
$statusPath = Join-Path $runPath "status.txt"
$logPath = Join-Path $runPath "stdout.log"
$commandPath = Join-Path $runPath "command.txt"
$summaryPath = Join-Path $runPath "summary.json"

$tagsList = @()
if ($Tags) {
    $tagsList = @($Tags -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ })
}

$vaConfig = [ordered]@{
    "КаталогФич" = $resolvedFeaturePath
    "КаталогиБиблиотек" = @($librariesPath)
    "ДелатьСкриншотПриВозникновенииОшибки" = $true
    "КаталогOutputСкриншоты" = (Join-Path $runPath "screenshots")
    "ДелатьЛогВыполненияСценариевВТекстовыйФайл" = $true
    "ИмяФайлаЛогВыполненияСценариев" = (Join-Path $runPath "va.log")
    "ВыгружатьСтатусВыполненияСценариевВФайл" = $true
    "ПутьКФайлуДляВыгрузкиСтатусаВыполненияСценариев" = $statusPath
    "ДелатьОтчетВФорматеCucumberJson" = $true
    "КаталогOutputCucumberJson" = (Join-Path $runPath "cucumber")
    "ДелатьОтчетВФорматеАллюр" = $true
    "КаталогOutputAllureБазовый" = (Join-Path $runPath "allure")
}

if ($tagsList.Count -gt 0) {
    $vaConfig["СписокТеговОтбор"] = $tagsList
}

Save-Json -Path $configPath -Value $vaConfig

if ($Backend -eq "Native") {
    $bin = Get-Setting -EnvMap $envMap -Name "OVS_1C_BIN" -Required
    $ib = Get-Setting -EnvMap $envMap -Name "OVS_IB_CONNECTION" -Required
    $user = Get-Setting -EnvMap $envMap -Name "OVS_DB_USER"
    $password = Get-Setting -EnvMap $envMap -Name "OVS_DB_PASSWORD"
    $vanessa = Get-Setting -EnvMap $envMap -Name "OVS_VANESSA_EPF" -Required

    $arguments = @("ENTERPRISE", $ib)
    if ($user) { $arguments += "/N$user" }
    if ($password) { $arguments += "/P$password" }
    $arguments += @("/Execute", $vanessa, "/C", "StartFeaturePlayer;VAParams=$configPath")

    Write-CommandFile -Path $commandPath -FilePath $bin -Arguments $arguments
    $result = Invoke-LoggedCommand -FilePath $bin -Arguments $arguments -StdoutPath $logPath -DryRun:$DryRun
    $statusCode = if (Test-Path -LiteralPath $statusPath) { [int](Get-Content -LiteralPath $statusPath -Raw).Trim() } else { $result.ExitCode }
}
else {
    $vrunner = Get-Setting -EnvMap $envMap -Name "OVS_VRUNNER" -Required
    $arguments = @(
        "vanessa",
        "--path", $resolvedFeaturePath,
        "--workspace", $repoRoot,
        "--vanessasettings", $configPath
    )

    if ($tagsList.Count -gt 0) {
        $arguments += @("--tags-filter", ($tagsList -join ","))
    }

    Write-CommandFile -Path $commandPath -FilePath $vrunner -Arguments $arguments
    $result = Invoke-LoggedCommand -FilePath $vrunner -Arguments $arguments -StdoutPath $logPath -DryRun:$DryRun
    $statusCode = if (Test-Path -LiteralPath $statusPath) { [int](Get-Content -LiteralPath $statusPath -Raw).Trim() } else { $result.ExitCode }
}

$summary = [ordered]@{
    mode = "ui-run"
    backend = $Backend
    profile = $Profile
    featurePath = $resolvedFeaturePath
    tags = $tagsList
    runPath = $runPath
    commandFile = $commandPath
    generatedConfig = $configPath
    statusCode = $statusCode
    launched = $result.Launched
}

Save-Json -Path $summaryPath -Value $summary
Write-Host "UI run artifacts: $runPath"
exit $statusCode
