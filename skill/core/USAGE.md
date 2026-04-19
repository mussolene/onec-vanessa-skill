# Usage

## Standard Flow

1. Run bootstrap once.
2. Run doctor and fix environment gaps first.
3. Create or copy the needed test template.
4. Run the smallest relevant scope.
5. If needed, switch to the separate debug command.
6. Read `artifacts/` before changing more code.

## Commands

Canonical cross-platform entrypoint:

- `python3 skill/scripts/onec_test_cli.py bootstrap`
- `python3 skill/scripts/onec_test_cli.py doctor`
- `python3 skill/scripts/onec_test_cli.py run-ui --feature-path <path>`
- `python3 skill/scripts/onec_test_cli.py debug-ui --feature-path <path>`
- `python3 skill/scripts/onec_test_cli.py run-xunit --tests-path <path>`
- `python3 skill/scripts/onec_test_cli.py debug-xunit --tests-path <path>`
- `python3 skill/scripts/onec_test_cli.py collect-artifacts --run-path <path>`
- `python3 skill/scripts/onec_test_cli.py package-skill`

Windows convenience wrappers:

- `pwsh -File skill/scripts/bootstrap.ps1`
- `pwsh -File skill/scripts/doctor.ps1`
- `pwsh -File skill/scripts/run-ui.ps1`
- `pwsh -File skill/scripts/debug-ui.ps1`
- `pwsh -File skill/scripts/run-xunit.ps1`
- `pwsh -File skill/scripts/debug-xunit.ps1`

## UI Examples

Run one feature:

```bash
python3 skill/scripts/onec_test_cli.py run-ui --feature-path tests/ui/smoke/open-form.feature
```

Run a feature directory:

```bash
python3 skill/scripts/onec_test_cli.py run-ui --feature-path tests/ui/smoke
```

Run by tags:

```bash
python3 skill/scripts/onec_test_cli.py run-ui --feature-path tests/ui --tags '@smoke,@api'
```

Open local debug session without auto-run:

```bash
python3 skill/scripts/onec_test_cli.py debug-ui --feature-path tests/ui/smoke/open-form.feature
```

## xUnit Examples

Run all xUnit tests in a folder:

```bash
python3 skill/scripts/onec_test_cli.py run-xunit --tests-path tests/xunit
```

Run one module:

```bash
python3 skill/scripts/onec_test_cli.py run-xunit --tests-path tests/xunit/Smoke/DocumentPostingTests.bsl --loader File
```

Open debug-oriented run without shutdown:

```bash
python3 skill/scripts/onec_test_cli.py debug-xunit --tests-path tests/xunit/Smoke
```

## xUnit Naming Conventions

- module file: `<Area>Tests.bsl`
- suite file: `<Area>Suite.bsl`
- test procedures: `Тест<Behavior>`
- smoke modules live in a dedicated `Smoke/` folder when the repository uses smoke splits

Keep names stable and boring. The goal is cheap targeting from scripts and CI, not clever naming.

## Optional vrunner Usage

Use this only when the project already depends on `vanessa-runner`.

```bash
python3 skill/scripts/onec_test_cli.py run-ui --feature-path tests/ui/smoke --backend VRunner
python3 skill/scripts/onec_test_cli.py run-xunit --tests-path tests/xunit/smoke --backend VRunner
```

## Exit Semantics

- environment/setup failures use script-level non-zero exit codes;
- Vanessa Automation status codes come from the exported status file when available;
- xUnit direct mode treats the 1C process exit code as primary and records an additional status file when the wrapper backend provides one;
- dry-run prints the exact command and generated paths without launching 1C.
