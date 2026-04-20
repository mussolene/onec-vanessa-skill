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

## Containerized UI Smoke

For Linux container runs, prefer a two-stage check:

1. First run a minimal `TestManager -> TestClient` smoke.
2. Only after it is green, run business-form smoke scenarios.

Mandatory steps for the first smoke:

- run in a mode that does not already keep an extra 1C session open;
- clean previous 1C windows and stale test sessions before launch;
- keep a stable `artifacts/` directory with status, text log, allure, and cucumber files;
- use a minimal feature that only opens and closes `TestClient`;
- build `VAParams` from the installed ADD version's own sample files instead of assuming a generic schema;
- inspect the status file and `ui-smoke.log` before touching product code.

Optional steps when the base is heavy or noisy:

- add pre-start window cleanup for non-business windows like update reminders or info forms;
- disable screenshots if the runtime does not provide a screenshot tool;
- install or document required OS tools such as `ip`, `ping`, and the screenshot command used by `VAParams`;
- keep a dedicated container profile for file-db smoke and a separate one for client-server smoke.

Important `VAParams` nuance:

- for some ADD versions, `ТаймаутЗапуска1С`, `ДиапазонПортовTestclient`, `КоличествоСекундПоискаОкна`, and similar client-launch settings must stay at the top JSON level;
- if you move them into nested sections because it looks cleaner, ADD may ignore them and use bundled defaults instead;
- a common symptom is that a custom timeout is ignored and the log still shows a fallback timeout like `Прерывание по таймауту <25>`.

Important limitation:

- Vanessa steps can close windows only after `TestClient` is already connected.
- If startup windows block the connection itself, treat that as environment orchestration and solve it outside the feature steps.

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
