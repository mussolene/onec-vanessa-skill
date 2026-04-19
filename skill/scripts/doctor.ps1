[CmdletBinding()]
param(
    [ValidateSet("All", "UI", "XUnit", "Package")]
    [string]$Scope = "All",
    [string]$EnvFile = ".env",
    [switch]$Help
)

if ($Help) {
    @"
doctor.ps1

Checks the local environment and writes a summary to artifacts/doctor/.

Usage:
  pwsh -File skill/scripts/doctor.ps1
  pwsh -File skill/scripts/doctor.ps1 -Scope UI
  pwsh -File skill/scripts/doctor.ps1 -Scope XUnit
"@
    exit 0
}

. (Join-Path $PSScriptRoot "lib/common.ps1")

$envMap = Import-SkillEnv -Path (Join-Path (Get-RepoRoot) $EnvFile)
$runPath = New-RunContext -Category "doctor" -Name ($Scope.ToLowerInvariant())

$checks = @()

function Add-Check {
    param(
        [string]$Name,
        [bool]$Passed,
        [string]$Severity,
        [string]$Details
    )

    $script:checks += [pscustomobject]@{
        name = $Name
        passed = $Passed
        severity = $Severity
        details = $Details
    }
}

function Test-ConfiguredPath {
    param([string]$SettingName, [string]$Label, [bool]$Required)

    $value = ""
    $severity = if ($Required) { "required" } else { "optional" }
    try {
        $value = Get-Setting -EnvMap $envMap -Name $SettingName -Required:$Required
        if ($value -and ((Test-Path -LiteralPath $value) -or (Get-Command $value -ErrorAction SilentlyContinue))) {
            Add-Check -Name $Label -Passed $true -Severity $severity -Details $value
        }
        elseif ($value) {
            Add-Check -Name $Label -Passed $false -Severity $severity -Details "Configured path does not exist: $value"
        }
        elseif (-not $Required) {
            Add-Check -Name $Label -Passed $false -Severity $severity -Details "Not configured."
        }
    }
    catch {
        Add-Check -Name $Label -Passed $false -Severity $severity -Details $_.Exception.Message
    }
}

Add-Check -Name "git" -Passed ([bool](Get-Command git -ErrorAction SilentlyContinue)) -Severity "required" -Details "Required for git-first workflow."
Test-ConfiguredPath -SettingName "OVS_1C_BIN" -Label "1C executable" -Required ($Scope -in @("All", "UI", "XUnit"))
Test-ConfiguredPath -SettingName "OVS_VANESSA_EPF" -Label "Vanessa Automation EPF" -Required ($Scope -in @("All", "UI"))
Test-ConfiguredPath -SettingName "OVS_XUNIT_EPF" -Label "xUnitFor1C EPF" -Required ($Scope -in @("All", "XUnit"))
Test-ConfiguredPath -SettingName "OVS_VRUNNER" -Label "vanessa-runner executable" -Required $false
Test-ConfiguredPath -SettingName "OVS_OSCRIPT" -Label "oscript executable" -Required $false

try {
    $ibConnection = Get-Setting -EnvMap $envMap -Name "OVS_IB_CONNECTION" -Required ($Scope -in @("All", "UI", "XUnit"))
    Add-Check -Name "IB connection" -Passed ([bool]$ibConnection) -Severity "required" -Details $ibConnection
}
catch {
    Add-Check -Name "IB connection" -Passed $false -Severity "required" -Details $_.Exception.Message
}

$summary = [pscustomobject]@{
    scope = $Scope
    createdAt = (Get-Date).ToString("s")
    runPath = $runPath
    checks = $checks
    failedRequired = @($checks | Where-Object { -not $_.passed -and $_.severity -eq "required" }).Count
    failedOptional = @($checks | Where-Object { -not $_.passed -and $_.severity -eq "optional" }).Count
}

Save-Json -Path (Join-Path $runPath "summary.json") -Value $summary
Save-Text -Path (Join-Path $runPath "summary.txt") -Value (($checks | ForEach-Object {
    "{0} [{1}] {2}" -f ($(if ($_.passed) { "PASS" } else { "FAIL" }), $_.severity, $_.name + " - " + $_.details)
}) -join [Environment]::NewLine)

Write-Host "Doctor summary written to $runPath"
if ($summary.failedRequired -gt 0) {
    exit 2
}
