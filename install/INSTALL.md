# Install

## What This Repository Ships

- core skill docs and adapters;
- reusable templates;
- cross-platform Python run/debug/bootstrap CLI;
- thin PowerShell wrappers for Windows;
- smoke examples;
- CI wiring examples;
- packaging script for reuse in another repository.

It does not ship:

- the 1C platform;
- Vanessa Automation binaries;
- xUnitFor1C binaries;
- `vanessa-runner`.

## Honest Support Matrix

- The skill package is cross-platform because the orchestration layer is Python-based.
- The same CLI can be used on Windows, macOS, and Linux for bootstrap, doctor, packaging, config generation, and dry-run command assembly.
- Actual 1C execution still depends on the consuming machine having a compatible 1C runtime and upstream tools installed.

## Prerequisites

Required for real execution:

- compatible 1C executable path;
- Vanessa Automation EPF path;
- xUnitFor1C `xddTestRunner.epf` path;
- accessible test infobase connection. If `OVS_IB_CONNECTION` is a plain connection string, the CLI passes it as `/IBConnectionString <value>`; if it already starts with a 1C command-line switch such as `/F` or `/IBConnectionString`, the CLI passes it as-is;
- write access to the repository `artifacts/` directory.

Optional:

- `vanessa-runner`;
- `oscript`.

## Local Setup

1. Copy this repository or vendor the `skill/`, `examples/`, `install/`, `ci/`, and `docs/` folders into your target repository.
2. Run `python3 skill/scripts/onec_test_cli.py bootstrap`.
3. Fill `.env` with machine-specific paths and connection data.
4. Run `python3 skill/scripts/onec_test_cli.py doctor`.

On Windows, `pwsh -File skill/scripts/<command>.ps1` remains available as a convenience wrapper.

## Embedding Into Another Repository

Minimum shared payload:

- `skill/`
- `examples/`
- `install/`
- `ci/`
- `docs/RELEASE.md`
- `.env.example`

Recommended ignored local payload:

- `.env`
- `.onec-test/`
- `artifacts/`
- `dist/`

## Adapting For Codex, Cursor, And Claude

- Codex: point the agent to [../skill/adapters/codex/PROMPT.md](../skill/adapters/codex/PROMPT.md).
- Cursor: point project rules to [../skill/adapters/cursor/RULES.md](../skill/adapters/cursor/RULES.md).
- Claude: point the project guide to [../skill/adapters/claude/CLAUDE.md](../skill/adapters/claude/CLAUDE.md).

All three adapters are intentionally thin and inherit behavior from [../skill/core/SKILL.md](../skill/core/SKILL.md).

## Upstream References

- Vanessa Automation docs: [https://pr-mex.github.io/vanessa-automation/dev/](https://pr-mex.github.io/vanessa-automation/dev/)
- xUnitFor1C repo/wiki: [https://github.com/xDrivenDevelopment/xUnitFor1C](https://github.com/xDrivenDevelopment/xUnitFor1C)
- vanessa-runner repo: [https://github.com/vanessa-opensource/vanessa-runner](https://github.com/vanessa-opensource/vanessa-runner)
