# Install

## What This Repository Ships

- core skill docs and adapters;
- reusable templates;
- Windows-first run/debug/bootstrap scripts;
- smoke examples;
- CI wiring examples;
- packaging script for reuse in another repository.

It does not ship:

- the 1C platform;
- Vanessa Automation binaries;
- xUnitFor1C binaries;
- `vanessa-runner`.

## Honest Support Matrix

- Windows: supported target for real 1C execution.
- macOS/Linux: only repo-side tasks such as reading docs, copying templates, packaging, and the thin bootstrap wrapper are claimed here.

## Prerequisites

Required for real execution:

- compatible 1C executable path;
- Vanessa Automation EPF path;
- xUnitFor1C `xddTestRunner.epf` path;
- accessible test infobase connection;
- write access to the repository `artifacts/` directory.

Optional:

- `vanessa-runner`;
- `oscript`.

## Local Setup

1. Copy this repository or vendor the `skill/`, `examples/`, `install/`, `ci/`, and `docs/` folders into your target repository.
2. Run `pwsh -File skill/scripts/bootstrap.ps1`.
3. Fill `.env` with machine-specific paths and connection data.
4. Run `pwsh -File skill/scripts/doctor.ps1`.

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
