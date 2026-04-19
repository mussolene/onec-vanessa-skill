# Quickstart

## 1. Bootstrap

```bash
python3 skill/scripts/onec_test_cli.py bootstrap
```

Then fill `.env` and rerun:

```bash
python3 skill/scripts/onec_test_cli.py doctor
```

## 2. Create The First UI Test

Copy the template:

```bash
python3 - <<'PY'
from pathlib import Path
import shutil
target = Path("tests/ui/smoke/open-form.feature")
target.parent.mkdir(parents=True, exist_ok=True)
shutil.copy2("skill/templates/ui/feature-template.feature", target)
PY
```

Or start from the example:

```bash
python3 - <<'PY'
from pathlib import Path
import shutil
target = Path("tests/ui/smoke/open-form.feature")
target.parent.mkdir(parents=True, exist_ok=True)
shutil.copy2("examples/ui/smoke-open-form.feature", target)
PY
```

Run it:

```bash
python3 skill/scripts/onec_test_cli.py run-ui --feature-path tests/ui/smoke/open-form.feature
```

Debug it locally:

```bash
python3 skill/scripts/onec_test_cli.py debug-ui --feature-path tests/ui/smoke/open-form.feature
```

## 3. Create The First xUnit Test

Copy the module template:

```bash
python3 - <<'PY'
from pathlib import Path
import shutil
target = Path("tests/xunit/Smoke/DocumentTests.bsl")
target.parent.mkdir(parents=True, exist_ok=True)
shutil.copy2("skill/templates/xunit/test-module-template.bsl", target)
PY
```

Or start from the example:

```bash
python3 - <<'PY'
from pathlib import Path
import shutil
target = Path("tests/xunit/Smoke/SmokeMathTests.bsl")
target.parent.mkdir(parents=True, exist_ok=True)
shutil.copy2("examples/xunit/Smoke/SmokeMathTests.bsl", target)
PY
```

Run it:

```bash
python3 skill/scripts/onec_test_cli.py run-xunit --tests-path tests/xunit/Smoke/SmokeMathTests.bsl --loader File
```

Debug it:

```bash
python3 skill/scripts/onec_test_cli.py debug-xunit --tests-path tests/xunit/Smoke/SmokeMathTests.bsl --loader File
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
