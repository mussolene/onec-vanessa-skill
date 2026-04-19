# Quickstart

## 1. Bootstrap

```powershell
pwsh -File skill/scripts/bootstrap.ps1
```

Then fill `.env` and rerun:

```powershell
pwsh -File skill/scripts/doctor.ps1
```

## 2. Create The First UI Test

Copy the template:

```powershell
Copy-Item skill/templates/ui/feature-template.feature tests/ui/smoke/open-form.feature
```

Or start from the example:

```powershell
Copy-Item examples/ui/smoke-open-form.feature tests/ui/smoke/open-form.feature
```

Run it:

```powershell
pwsh -File skill/scripts/run-ui.ps1 -FeaturePath tests/ui/smoke/open-form.feature
```

Debug it locally:

```powershell
pwsh -File skill/scripts/debug-ui.ps1 -FeaturePath tests/ui/smoke/open-form.feature
```

## 3. Create The First xUnit Test

Copy the module template:

```powershell
Copy-Item skill/templates/xunit/test-module-template.bsl tests/xunit/Smoke/DocumentTests.bsl
```

Or start from the example:

```powershell
Copy-Item examples/xunit/Smoke/SmokeMathTests.bsl tests/xunit/Smoke/SmokeMathTests.bsl
```

Run it:

```powershell
pwsh -File skill/scripts/run-xunit.ps1 -TestsPath tests/xunit/Smoke/SmokeMathTests.bsl -Loader File
```

Debug it:

```powershell
pwsh -File skill/scripts/debug-xunit.ps1 -TestsPath tests/xunit/Smoke/SmokeMathTests.bsl -Loader File
```

## 4. Read Artifacts

After each run, inspect:

- `artifacts/ui/<run-id>/` or `artifacts/xunit/<run-id>/`
- `command.txt`
- `stdout.log`
- `summary.json`
- status files and reports
- screenshots for UI failures

## 5. Minimal Local Cycle

1. copy template or example;
2. run one file;
3. reproduce failure;
4. inspect `artifacts/`;
5. fix the test or product code;
6. rerun the same file;
7. expand to smoke or full scope only after the focused rerun passes.

