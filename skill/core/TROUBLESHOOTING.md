# Troubleshooting

## First Split: Environment Or Test Failure

Treat these as environment failures:

- `1cv8.exe` or `1cv8c.exe` path is missing;
- `VanessaAutomation.epf` path is missing;
- `xddTestRunner.epf` path is missing;
- the test base connection is missing;
- `vanessa-runner` was selected but `vrunner` is not installed;
- artifact directories cannot be created.

Treat these as test or product failures:

- Vanessa Automation returns a non-zero scenario status;
- xUnit reports failing assertions or failing modules;
- screenshots show a real UI state mismatch;
- only a targeted business test fails while environment checks are green.

## Common UI Problems

### No screenshots

- confirm screenshot export is enabled in the generated `VAParams` file;
- confirm the artifact folder is writable;
- confirm the run is using a profile that enables screenshot capture.

### VanessaExt install issues

- verify the environment really allows the external component;
- if silent installation fails, document it as an environment blocker;
- do not pretend the UI run is healthy when the component never became available.

### Feature not found

- check whether `-FeaturePath` points to a file or directory that exists;
- check tag filters;
- check whether the smoke convention path is mapped in `.env`.

### TestManager starts but TestClient does not connect

Typical signals:

- Vanessa returns status `2`;
- `ui-smoke.log` stops on the step that opens `TestClient`;
- the second `1cv8` process exists, but the step ends with `Не смог подключить TestClient`.

Check these in order:

- close all previous 1C sessions, then retry the minimal smoke;
- verify that the first smoke feature does only open/close `TestClient`;
- compare the project `VAParams` with the installed ADD sample `VBParams*.json` files and keep the same key layout for client-launch settings;
- inspect startup windows in the second client before assuming a step-definition problem;
- remember that Vanessa steps cannot close startup windows before `TestClient` handshake is complete;
- on Linux/container runs, verify that OS tools used by the configuration or its extensions actually exist, for example `ip`, `ping`, and the configured screenshot command;
- if screenshots are enabled, verify the screenshot tool and output directory, or disable screenshots for the first smoke.

If the environment is already launching both processes but still returns status `2`, document it as an infrastructure handshake problem first, not as a failing business scenario.

Useful interpretation pattern:

- if the log says `Прерывание по таймауту <25>` even though you configured a larger timeout, first suspect that ADD ignored your `VAParams` shape and fell back to bundled defaults;
- if the timeout value changes after fixing the JSON layout, the config is now being read and you can continue debugging the real handshake or network problem.

### Startup windows block scenario loading

Typical signals:

- the log prints technical information about Vanessa/ADD and then stops before the first feature line;
- a visible 1C window asks to update the configuration, shows informational startup text, or waits for another modal decision;
- killing or forcibly closing X11 windows makes the 1C process unstable.

Preferred fix order:

- refresh the baseline test database from an already updated dump, then rerun the scenario on a fresh copy of that base;
- pass startup-suppression command-line switches such as `/DisableStartupMessages`, `/DisableStartupDialogs`, and `/DisableSplash` where the platform and runner support them;
- keep first-smoke bases free of startup reminders and update prompts.

Avoid treating this as a normal feature step. Vanessa cannot reliably close a modal startup window before the runner has loaded the scenario and connected the expected test context.

### Custom Vanessa steps stay Pending

Typical signals:

- the scenario reaches the custom step and reports `Pending` or an empty snippet address;
- built-in library steps execute normally;
- the status file may still contain success if pending is not configured as failure.

Check these in order:

- set `ПриравниватьPendingКFailed` to true for CI and agent runs;
- verify the step external processing exports `ПолучитьСписокТестов(КонтекстФреймворкаBDD)` from the form module expected by the ADD version in use;
- declare the standard Vanessa context variables used by local examples, especially `Ванесса`, `Контекст`, and `КонтекстСохраняемый`;
- keep snippet signatures valid and minimal, for example `ИмяШага(Параметр)`, without stale generated punctuation;
- load external step processors using the same mechanism as the repository's existing ADD configuration, either library folders or the external-processings directory, but do not mix incompatible layouts in one run.

### UI scenarios for installers

Installer tests should prove three things separately:

- the installer is opened through a user-visible UI path or a Vanessa UI step;
- required user decisions are explicit steps, for example pressing an install or continue button only when the product flow needs it;
- the final assertion checks persisted state in the test base, such as an installed extension, a registered external processing, or another durable artifact.

Do not stop at checking that the installer form opened. A form-only assertion is a smoke of the launcher, not a proof that installation worked.

## Common xUnit Problems

### Wrong loader

- use `Directory` for folders;
- use `File` for one module file;
- use `Subsystem` only when the project actually runs built-in tests from configuration metadata.

### Runner closes before inspection

- use `debug-xunit.ps1`;
- in `VRunner` mode, keep `--no-shutdown`;
- in direct mode, omit the shutdown command and capture the full reproduction command.

## When The Current Machine Cannot Prove Runtime Execution

Be explicit:

- say which dependency is missing;
- keep templates and docs accurate;
- still provide dry-run commands and config generation;
- do not mark runtime support as verified.

## Upstream References

- Vanessa Automation docs: command-line launch, `VAParams`, return status, screenshots, debug loading.
- xUnitFor1C docs: `xddTestRunner.epf`, command-line loaders, test module structure.
- `vanessa-runner` docs: optional `vrunner vanessa` and `vrunner xunit` wrappers.
