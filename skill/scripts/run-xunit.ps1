$ErrorActionPreference = "Stop"
$python = (Get-Command python -ErrorAction SilentlyContinue)
if (-not $python) {
    $python = (Get-Command python3 -ErrorAction SilentlyContinue)
}
if (-not $python) {
    throw "Python 3 is required to run this wrapper."
}
& $python.Source (Join-Path $PSScriptRoot "onec_test_cli.py") run-xunit @args
exit $LASTEXITCODE
