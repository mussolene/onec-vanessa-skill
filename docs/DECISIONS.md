# Decisions

## D-001: Native tool flows stay primary

- Status: accepted
- Decision: the skill treats native Vanessa Automation and xUnitFor1C command lines as the source of truth.
- Why: this avoids hiding behavior behind an extra wrapper and keeps support claims tied to documented upstream capabilities.
- Consequence: `vanessa-runner` is supported only as an optional adapter.

## D-002: Windows-first execution

- Status: accepted
- Decision: production test execution support is documented for Windows first.
- Why: Vanessa Automation and xUnitFor1C execution paths depend on 1C tooling that is not honestly verified in this repo on macOS/Linux.
- Consequence: non-Windows support is limited to packaging, bootstrap, and documentation unless a path is explicitly proven later.

## D-003: Core-first adapter model

- Status: accepted
- Decision: all agent adapters are thin files pointing back to `skill/core/`.
- Why: the skill must remain portable and avoid duplicated instructions across Cursor, Codex, and Claude.
- Consequence: changes in behavior belong in core docs and scripts, not in adapter-specific copies.

## D-004: Artifact collection is mandatory

- Status: accepted
- Decision: every run/debug flow writes into a predictable `artifacts/` structure with reproduction metadata.
- Why: agent workflows need durable evidence for retest, debugging, and CI triage.
- Consequence: scripts and docs must distinguish environment failures from test failures and must emit reproduction commands.

