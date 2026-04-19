Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-SkillRoot {
    return (Split-Path -Parent $PSScriptRoot)
}

function Get-RepoRoot {
    return (Split-Path -Parent (Get-SkillRoot))
}

function Get-DefaultEnvFile {
    return (Join-Path (Get-RepoRoot) ".env")
}

function Import-SkillEnv {
    param(
        [string]$Path = (Get-DefaultEnvFile)
    )

    $values = @{}

    if (Test-Path -LiteralPath $Path) {
        foreach ($line in Get-Content -LiteralPath $Path) {
            $trimmed = $line.Trim()
            if (-not $trimmed -or $trimmed.StartsWith("#")) {
                continue
            }

            $pair = $trimmed -split "=", 2
            if ($pair.Count -eq 2) {
                $values[$pair[0].Trim()] = $pair[1].Trim()
            }
        }
    }

    return $values
}

function Get-Setting {
    param(
        [hashtable]$EnvMap,
        [string]$Name,
        [string]$Default = "",
        [switch]$Required
    )

    $fromProcess = [Environment]::GetEnvironmentVariable($Name)
    if ($fromProcess) {
        return $fromProcess
    }

    if ($EnvMap.ContainsKey($Name) -and $EnvMap[$Name]) {
        return $EnvMap[$Name]
    }

    if ($Required) {
        throw "Missing required setting: $Name"
    }

    return $Default
}

function Ensure-Directory {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Force -Path $Path | Out-Null
    }

    return $Path
}

function New-RunContext {
    param(
        [string]$Category,
        [string]$Name = "run"
    )

    $artifactsRoot = Ensure-Directory (Join-Path (Get-RepoRoot) "artifacts")
    $categoryRoot = Ensure-Directory (Join-Path $artifactsRoot $Category)
    $runId = "{0}-{1}" -f (Get-Date -Format "yyyyMMdd-HHmmss"), $Name
    $runPath = Ensure-Directory (Join-Path $categoryRoot $runId)
    return $runPath
}

function Save-Text {
    param(
        [string]$Path,
        [string]$Value
    )

    Set-Content -LiteralPath $Path -Value $Value -Encoding UTF8
}

function Save-Json {
    param(
        [string]$Path,
        $Value
    )

    $json = $Value | ConvertTo-Json -Depth 10
    Set-Content -LiteralPath $Path -Value $json -Encoding UTF8
}

function Format-CommandLine {
    param(
        [string]$FilePath,
        [string[]]$Arguments
    )

    $parts = @($FilePath)
    foreach ($argument in $Arguments) {
        if ($argument -match "\s") {
            $parts += '"' + $argument.Replace('"', '\"') + '"'
        }
        else {
            $parts += $argument
        }
    }

    return ($parts -join " ")
}

function Write-CommandFile {
    param(
        [string]$Path,
        [string]$FilePath,
        [string[]]$Arguments
    )

    Save-Text -Path $Path -Value (Format-CommandLine -FilePath $FilePath -Arguments $Arguments)
}

function Invoke-LoggedCommand {
    param(
        [string]$FilePath,
        [string[]]$Arguments,
        [string]$StdoutPath,
        [switch]$DryRun
    )

    if ($DryRun) {
        Save-Text -Path $StdoutPath -Value "Dry-run. Command was not launched."
        return @{
            ExitCode = 0
            Launched = $false
        }
    }

    & $FilePath @Arguments 2>&1 | Tee-Object -FilePath $StdoutPath | Out-Null
    return @{
        ExitCode = $LASTEXITCODE
        Launched = $true
    }
}

function Get-LoaderName {
    param([ValidateSet("Directory", "File", "Subsystem")] [string]$Loader)

    switch ($Loader) {
        "Directory" { return "ЗагрузчикКаталога" }
        "File" { return "ЗагрузчикФайла" }
        "Subsystem" { return "ЗагрузчикИзПодсистемКонфигурации" }
        default { throw "Unsupported loader: $Loader" }
    }
}

