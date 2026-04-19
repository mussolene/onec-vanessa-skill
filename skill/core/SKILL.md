# 1C Testing Skill

## Purpose

This skill gives an agent a thin, production-ready orchestration layer for 1C testing.

It does not replace Vanessa Automation or xUnitFor1C.

It standardizes:

- how to inspect a repo before changing tests;
- how to choose UI/BDD versus xUnit;
- how to generate minimal test stubs with real bodies;
- how to run or debug the right scope;
- how to collect artifacts and describe reproduction steps;
- how to stay honest when the required 1C runtime is missing.

## What The Agent Must Inspect First

Before editing anything, inspect the target repository for:

- existing `features/`, `tests/`, `specs/`, `smoke/`, or `qa/` folders;
- existing Vanessa Automation files, `VAParams*.json`, `vrunner.json`, or `vanessa-runner` scripts;
- existing xUnitFor1C test modules, `xddTestRunner.epf` references, or `xddConfig` files;
- CI files that already define smoke/full splits;
- current artifact folders and report formats;
- project-specific environment files, platform paths, and test bases;
- any library of shared UI steps or data fixtures.

If the repository already has conventions, reuse them unless they are clearly broken.

## When To Use UI / BDD

Use Vanessa Automation when the behavior depends on:

- forms, commands, navigation, or interactive user flows;
- end-to-end business behavior visible through the UI;
- feature-based regression coverage;
- smoke scenarios that prove the application is alive from the user's point of view.

Do not use UI tests when a fast xUnit test is enough.

## When To Use xUnit

Use xUnitFor1C when the behavior can be checked cheaply in code:

- module logic;
- calculation rules;
- validation branches;
- isolated business logic with predictable setup;
- narrow regressions that do not require UI interaction.

Prefer xUnit first when it proves the same thing with less runtime cost and less flakiness.

## Required Working Order

1. Inspect the repository and current test layout.
2. Decide whether the change belongs to UI, xUnit, or both.
3. Prefer the cheaper test if it is sufficient.
4. Create or update only the minimum relevant tests.
5. Run the narrowest relevant scope first.
6. If the run fails, collect logs, status, screenshots, and the reproduction command into `artifacts/`.
7. Localize the fault before editing product code.
8. Apply the smallest safe fix.
9. Re-run the minimum retest.
10. Run the broader scope only after the focused retest is green.

## Non-Negotiable Rules

- Do not invent commands, flags, loaders, APIs, or framework behavior.
- Do not claim that `vanessa-runner` is required. It is optional here.
- Do not claim unverified OS/runtime combinations for actual 1C execution.
- Do not hide missing infrastructure. State it clearly.
- Do not merge UI and xUnit into one opaque command.
- Do not create empty placeholder tests. Every stub must include a minimal executable intent.

## Execution Model

### Vanessa Automation

- Native source of truth: `VAParams` plus the 1C command line.
- Automated execution: explicit `StartFeaturePlayer`.
- Local debug/load: open Vanessa Automation with `VAParams` loaded but without auto-run.
- Optional wrapper: `vrunner vanessa`.

### xUnitFor1C

- Native source of truth: `xddTestRunner.epf` with `xddRun`, `xddReport`, and `xddShutdown`.
- Supported targeting: directory, file/module, and configuration subsystem loaders.
- Optional wrapper: `vrunner xunit`.

## Artifact Discipline

Every non-trivial run should leave:

- a status file;
- a text log;
- the command used for reproduction;
- report files;
- screenshots for UI failures when available;
- a short summary describing whether the failure is infrastructure or test/product logic.

Use `artifacts/` and keep paths stable enough for follow-up agent work.

## Cross-Platform Contract

- The skill orchestration layer is cross-platform and Python-based.
- `skill/scripts/onec_test_cli.py` is the canonical entrypoint on macOS, Linux, and Windows.
- PowerShell files are thin convenience wrappers for Windows users.
- The agent should keep commands OS-agnostic where possible and use the configured `OVS_1C_BIN` path instead of hardcoded platform-specific launchers.

## Limitations

- This skill ships orchestration, not vendor binaries.
- Real execution requires a compatible 1C platform, test base, and upstream tools.
- The repo can orchestrate runs cross-platform, but actual 1C execution still depends on the OS/runtime combination installed by the consumer.

## Fast Links

- [USAGE.md](./USAGE.md)
- [TESTING_STRATEGY.md](./TESTING_STRATEGY.md)
- [ARCHITECTURE.md](./ARCHITECTURE.md)
- [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)
- [../../install/INSTALL.md](../../install/INSTALL.md)
- [../../install/QUICKSTART.md](../../install/QUICKSTART.md)
