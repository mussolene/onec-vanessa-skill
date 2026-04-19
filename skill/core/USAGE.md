# Usage

## Standard Flow

1. Run bootstrap once.
2. Run doctor and fix environment gaps first.
3. Create or copy the needed test template.
4. Run the smallest relevant scope.
5. If needed, switch to the separate debug command.
6. Read `artifacts/` before changing more code.

## Commands

Windows-first entrypoints:

- `pwsh -File skill/scripts/bootstrap.ps1`
- `pwsh -File skill/scripts/doctor.ps1`
- `pwsh -File skill/scripts/run-ui.ps1 -FeaturePath <path>`
- `pwsh -File skill/scripts/debug-ui.ps1 -FeaturePath <path>`
- `pwsh -File skill/scripts/run-xunit.ps1 -TestsPath <path>`
- `pwsh -File skill/scripts/debug-xunit.ps1 -TestsPath <path>`
- `pwsh -File skill/scripts/collect-artifacts.ps1 -RunPath <path>`
- `pwsh -File skill/scripts/package-skill.ps1`

## UI Examples

Run one feature:

```powershell
pwsh -File skill/scripts/run-ui.ps1 -FeaturePath tests/ui/smoke/open-form.feature
```

Run a feature directory:

```powershell
pwsh -File skill/scripts/run-ui.ps1 -FeaturePath tests/ui/smoke
```

Run by tags:

```powershell
pwsh -File skill/scripts/run-ui.ps1 -FeaturePath tests/ui -Tags '@smoke,@api'
```

Open local debug session without auto-run:

```powershell
pwsh -File skill/scripts/debug-ui.ps1 -FeaturePath tests/ui/smoke/open-form.feature
```

## xUnit Examples

Run all xUnit tests in a folder:

```powershell
pwsh -File skill/scripts/run-xunit.ps1 -TestsPath tests/xunit
```

Run one module:

```powershell
pwsh -File skill/scripts/run-xunit.ps1 -TestsPath tests/xunit/Smoke/DocumentPostingTests.bsl -Loader File
```

Open debug-oriented run without shutdown:

```powershell
pwsh -File skill/scripts/debug-xunit.ps1 -TestsPath tests/xunit/Smoke
```

## Optional vrunner Usage

Use this only when the project already depends on `vanessa-runner`.

```powershell
pwsh -File skill/scripts/run-ui.ps1 -FeaturePath tests/ui/smoke -Backend VRunner
pwsh -File skill/scripts/run-xunit.ps1 -TestsPath tests/xunit/smoke -Backend VRunner
```

## Exit Semantics

- environment/setup failures use script-level non-zero exit codes;
- Vanessa Automation status codes come from the exported status file when available;
- xUnit direct mode treats the 1C process exit code as primary and records an additional status file when the wrapper backend provides one;
- dry-run prints the exact command and generated paths without launching 1C.

