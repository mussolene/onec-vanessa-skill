[CmdletBinding()]
param(
    [string]$TestsPath,
    [ValidateSet("Directory", "File", "Subsystem")]
    [string]$Loader = "Directory",
    [ValidateSet("Native", "VRunner")]
    [string]$Backend = "Native",
    [ValidateSet("Custom", "Smoke", "Fast", "Full")]
    [string]$Profile = "Custom",
    [string]$EnvFile = ".env",
    [switch]$DryRun,
    [switch]$Help
)

if ($Help) {
    @"
run-xunit.ps1

Runs xUnitFor1C tests.

Usage:
  pwsh -File skill/scripts/run-xunit.ps1 -TestsPath examples/xunit
  pwsh -File skill/scripts/run-xunit.ps1 -TestsPath examples/xunit/Smoke/SmokeMathTests.bsl -Loader File
  pwsh -File skill/scripts/run-xunit.ps1 -Profile Smoke
"@
    exit 0
}

. (Join-Path $PSScriptRoot "lib/common.ps1")

$repoRoot = Get-RepoRoot
$envMap = Import-SkillEnv -Path (Join-Path $repoRoot $EnvFile)
$runPath = New-RunContext -Category "xunit" -Name "run"

if (-not $TestsPath) {
    switch ($Profile) {
        "Smoke" { $TestsPath = Get-Setting -EnvMap $envMap -Name "OVS_XUNIT_SMOKE_PATH" -Default "examples/xunit" }
        default { $TestsPath = Get-Setting -EnvMap $envMap -Name "OVS_XUNIT_PATH" -Default "examples/xunit" }
    }
}

$resolvedTestsPath = Join-Path $repoRoot $TestsPath
$commandPath = Join-Path $runPath "command.txt"
$logPath = Join-Path $runPath "stdout.log"
$statusPath = Join-Path $runPath "status.txt"
$reportPath = Join-Path $runPath "junit.xml"
$summaryPath = Join-Path $runPath "summary.json"

if ($Backend -eq "Native") {
    $bin = Get-Setting -EnvMap $envMap -Name "OVS_1C_BIN" -Required
    $ib = Get-Setting -EnvMap $envMap -Name "OVS_IB_CONNECTION" -Required
    $user = Get-Setting -EnvMap $envMap -Name "OVS_DB_USER"
    $password = Get-Setting -EnvMap $envMap -Name "OVS_DB_PASSWORD"
    $xunit = Get-Setting -EnvMap $envMap -Name "OVS_XUNIT_EPF" -Required
    $loaderName = Get-LoaderName -Loader $Loader

    $commandValue = "xddRun $loaderName ""$resolvedTestsPath"";xddReport ГенераторОтчетаJUnitXML ""$reportPath"";xddShutdown;"
    $arguments = @("ENTERPRISE", $ib)
    if ($user) { $arguments += "/N$user" }
    if ($password) { $arguments += "/P$password" }
    $arguments += @("/Execute", $xunit, "/C", $commandValue)

    Write-CommandFile -Path $commandPath -FilePath $bin -Arguments $arguments
    $result = Invoke-LoggedCommand -FilePath $bin -Arguments $arguments -StdoutPath $logPath -DryRun:$DryRun
    Save-Text -Path $statusPath -Value ([string]$result.ExitCode)
    $statusCode = $result.ExitCode
}
else {
    $vrunner = Get-Setting -EnvMap $envMap -Name "OVS_VRUNNER" -Required
    $ib = Get-Setting -EnvMap $envMap -Name "OVS_IB_CONNECTION" -Required
    $user = Get-Setting -EnvMap $envMap -Name "OVS_DB_USER"
    $password = Get-Setting -EnvMap $envMap -Name "OVS_DB_PASSWORD"
    $xunit = Get-Setting -EnvMap $envMap -Name "OVS_XUNIT_EPF" -Required
    $xunitConfig = Join-Path $repoRoot ".onec-test/XUnitParams.local.json"

    $arguments = @(
        "xunit",
        $resolvedTestsPath,
        "--ibconnection", $ib,
        "--pathxunit", $xunit,
        "--xddConfig", $xunitConfig,
        "--reportsxunit", "ГенераторОтчетаJUnitXML{$reportPath}",
        "--xddExitCodePath", $statusPath
    )
    if ($user) { $arguments += @("--db-user", $user) }
    if ($password) { $arguments += @("--db-pwd", $password) }

    Write-CommandFile -Path $commandPath -FilePath $vrunner -Arguments $arguments
    $result = Invoke-LoggedCommand -FilePath $vrunner -Arguments $arguments -StdoutPath $logPath -DryRun:$DryRun
    $statusCode = if (Test-Path -LiteralPath $statusPath) { [int](Get-Content -LiteralPath $statusPath -Raw).Trim() } else { $result.ExitCode }
}

Save-Json -Path $summaryPath -Value @{
    mode = "xunit-run"
    backend = $Backend
    profile = $Profile
    loader = $Loader
    testsPath = $resolvedTestsPath
    runPath = $runPath
    commandFile = $commandPath
    reportPath = $reportPath
    statusCode = $statusCode
}

Write-Host "xUnit run artifacts: $runPath"
exit $statusCode

