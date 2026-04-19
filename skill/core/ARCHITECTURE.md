# Architecture

## Core Principle

The skill is an orchestration layer around existing tools.

It does not define a new runtime, a new DSL, or a new test framework.

## Layout

- `skill/core/`: canonical behavior, strategy, usage, and troubleshooting.
- `skill/adapters/`: thin agent-specific wrappers.
- `skill/templates/`: reusable starter files and config templates.
- `skill/scripts/`: Windows-first orchestration scripts and thin shell bootstrap.
- `examples/`: smoke examples with minimal real content.
- `install/`: install and quickstart docs.
- `ci/`: sample CI wiring.

## Runtime Backends

### UI / BDD

- primary: native Vanessa Automation command line with `VAParams`;
- optional: `vrunner vanessa`.

### xUnit

- primary: native `xddTestRunner.epf` command line;
- optional: `vrunner xunit`.

## Configuration Layers

1. committed templates in `skill/templates/config/`;
2. committed `.env.example` for project wiring;
3. ignored local `.env` and `.onec-test/` files for machine-specific paths;
4. generated run-specific config inside `artifacts/`.

## Artifact Layout

Expected structure:

```text
artifacts/
  ui/
    <run-id>/
  xunit/
    <run-id>/
  doctor/
    <run-id>/
  packages/
```

Each run directory should contain:

- `summary.json`
- `command.txt`
- `stdout.log`
- `status.txt` or equivalent
- framework reports
- screenshots when the UI flow produces them

## Why Adapters Stay Thin

Cursor, Codex, and Claude should share:

- the same test-choice rules;
- the same run/debug split;
- the same artifact discipline;
- the same limitation notes.

Agent-specific files should only express how that agent should consume the shared core.

