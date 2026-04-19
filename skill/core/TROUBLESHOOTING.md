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

