[CmdletBinding()]
param(
    [string]$TestsPath,
    [ValidateSet("Directory", "File", "Subsystem")]
    [string]$Loader = "Directory",
    [ValidateSet("Native", "VRunner")]
    [string]$Backend = "VRunner",
    [string]$EnvFile = ".env",
    [switch]$DryRun,
    [switch]$Help
)

if ($Help) {
    @"
debug-xunit.ps1

Runs xUnitFor1C in a debug-oriented mode and keeps the session open when possible.

Usage:
  pwsh -File skill/scripts/debug-xunit.ps1 -TestsPath examples/xunit
"@
    exit 0
}

. (Join-Path $PSScriptRoot "lib/common.ps1")

$repoRoot = Get-RepoRoot
$envMap = Import-SkillEnv -Path (Join-Path $repoRoot $EnvFile)
$runPath = New-RunContext -Category "xunit" -Name "debug"

if (-not $TestsPath) {
    $TestsPath = Get-Setting -EnvMap $envMap -Name "OVS_XUNIT_SMOKE_PATH" -Default "examples/xunit"
}

$resolvedTestsPath = Join-Path $repoRoot $TestsPath
$commandPath = Join-Path $runPath "command.txt"
$logPath = Join-Path $runPath "stdout.log"
$statusPath = Join-Path $runPath "status.txt"

if ($Backend -eq "Native") {
    $bin = Get-Setting -EnvMap $envMap -Name "OVS_1C_BIN" -Required
    $ib = Get-Setting -EnvMap $envMap -Name "OVS_IB_CONNECTION" -Required
    $user = Get-Setting -EnvMap $envMap -Name "OVS_DB_USER"
    $password = Get-Setting -EnvMap $envMap -Name "OVS_DB_PASSWORD"
    $xunit = Get-Setting -EnvMap $envMap -Name "OVS_XUNIT_EPF" -Required
    $loaderName = Get-LoaderName -Loader $Loader

    $commandValue = "xddRun $loaderName ""$resolvedTestsPath"";xddReport ГенераторОтчетаJUnitXML ""$(Join-Path $runPath "junit.xml")"";"
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
        "--reportsxunit", "ГенераторОтчетаJUnitXML{$(Join-Path $runPath "junit.xml")}",
        "--xddExitCodePath", $statusPath,
        "--xdddebug",
        "--no-shutdown"
    )
    if ($user) { $arguments += @("--db-user", $user) }
    if ($password) { $arguments += @("--db-pwd", $password) }

    Write-CommandFile -Path $commandPath -FilePath $vrunner -Arguments $arguments
    $result = Invoke-LoggedCommand -FilePath $vrunner -Arguments $arguments -StdoutPath $logPath -DryRun:$DryRun
    $statusCode = if (Test-Path -LiteralPath $statusPath) { [int](Get-Content -LiteralPath $statusPath -Raw).Trim() } else { $result.ExitCode }
}

Save-Json -Path (Join-Path $runPath "summary.json") -Value @{
    mode = "xunit-debug"
    backend = $Backend
    loader = $Loader
    testsPath = $resolvedTestsPath
    runPath = $runPath
    statusCode = $statusCode
    note = "Debug mode keeps more context and avoids shutdown when the backend supports it."
}

Write-Host "xUnit debug artifacts: $runPath"
exit $statusCode

