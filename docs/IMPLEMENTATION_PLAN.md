# Implementation Plan

## Goal

Build a production-ready, minimal skill package for agent-driven 1C testing in Cursor, Codex, and Claude without inventing a new test framework.

## Target Architecture

- `skill/core/` is the single source of truth.
- `skill/adapters/` contains thin agent-specific wrappers that only translate core guidance.
- `skill/templates/` contains reusable feature, xUnit, and config templates.
- `skill/scripts/` contains a cross-platform Python CLI for bootstrap, doctor, run, debug, artifact collection, and packaging, plus thin OS-specific wrappers.
- `examples/` contains concrete smoke examples for UI and xUnit usage.
- `install/` contains installation and quickstart instructions.
- `ci/` contains example CI wiring, not mandatory live CI.

## Covered Scenarios

- Bootstrap a fresh repo or consumer copy of the skill.
- Diagnose missing 1C/Vanessa/xUnit dependencies.
- Create new UI feature and library files from templates.
- Create new xUnit modules and suites from templates.
- Run Vanessa Automation features by file, directory, tags, smoke convention, or explicit profile.
- Run xUnit tests by directory, file/module, targeted subset, or smoke/fast/full repo conventions.
- Collect artifacts for local debug and CI.
- Package the skill for delivery into another repository.

## Honest Platform Support

- The skill package itself is cross-platform because the orchestration layer is Python-based and does not depend on PowerShell.
- Runtime execution uses the configured `OVS_1C_BIN` path and does not hardcode a Windows-only launcher.
- Live 1C execution is still environment-dependent and must be validated on the actual OS/runtime combination used by the consuming team.

## Capability Split

### UI / BDD

- Source of truth: Vanessa Automation native command-line flow with `VAParams` and `StartFeaturePlayer`.
- Local debug flow: load settings and open Vanessa Automation without auto-run.
- CI flow: explicit execution profile with status, log, screenshot, and report export.

### xUnit

- Source of truth: xUnitFor1C execution through `xddTestRunner.epf` and `xddRun`/`xddReport`/`xddShutdown`.
- Optional adapter: `vanessa-runner xunit` for teams that already use `vrunner`.
- Smoke/fast/full are repository conventions, not claimed as xUnitFor1C built-ins.

### Shared Utilities

- `.env.example` and config templates.
- predictable artifact folders under `artifacts/`;
- short, explicit commands with dry-run and help output;
- troubleshooting and limitation notes.

## Risks And Limits

- This environment cannot verify live 1C execution, so runtime correctness must be documented honestly and validated structurally.
- `pwsh` is not available in the current workspace, so Windows wrappers are verified only as thin forwarders to the Python CLI.
- xUnitFor1C usage differs across legacy versions; templates and docs will target the documented `xddTestRunner.epf` flow and state that version-specific adjustments may be required.
- `vanessa-runner` examples must stay optional because the core skill cannot depend on extra runtime layers.

## Immediate Build Order

1. Establish repo metadata and ignore rules.
2. Write core architecture and usage documents.
3. Add templates and smoke examples.
4. Add a cross-platform Python orchestration CLI plus thin wrappers.
5. Add install and CI example docs.
6. Package evidence, run a fresh verification pass, and fix only proven gaps.
