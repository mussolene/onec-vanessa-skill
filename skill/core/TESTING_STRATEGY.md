# Testing Strategy

## When To Write A UI Scenario

Write a Vanessa Automation scenario when you need to prove:

- navigation across forms;
- command execution through the real UI;
- field behavior, command panels, or user-visible workflow;
- end-to-end smoke coverage.

## When To Write An xUnit Test

Write an xUnitFor1C test when you can prove the behavior without opening the UI:

- business rules in modules;
- calculation branches;
- validation logic;
- isolated regression checks with cheap setup.

## When Not To Mix Them

Do not hide pure business logic inside a UI scenario just because the screen exposes it.

Do not turn a real UI regression into an xUnit test if the failure only appears through forms, commands, or client interaction.

## Smoke Versus Regression

Smoke means:

- one or a few short scenarios that prove the product starts and critical user paths are alive;
- one or a few fast xUnit checks that prove the core business logic is not obviously broken.

Regression means:

- broader feature directories, wider tag scopes, or the full xUnit tree;
- slower, more complete coverage run after a focused fix is already validated.

## Minimal Local Loop

1. reproduce with the smallest feature, tag, file, or folder;
2. if a cheap xUnit test can prove the change, run it before UI;
3. if the bug is UI-only, run one feature or tag group;
4. collect artifacts;
5. fix;
6. rerun the same narrow scope;
7. expand to smoke, then to full regression only when needed.

## Escalation Rules

- single test/module/feature first;
- narrow folder or tag second;
- smoke set third;
- full regression last.

The agent should always explain why it escalated.

## Test Data

- keep test data close to the test that owns it;
- prefer explicit setup over hidden global state;
- for UI, use context/setup blocks and defensive cleanup;
- for xUnit, keep fixtures cheap and isolated;
- do not rely on a dirty shared base unless the repository already has a controlled convention for it.
- for installer and migration UI tests, prefer a refreshed baseline database dump over scripted dismissal of startup/update reminders.

## UI Stability Rules

- factor repeated UI actions into shared library scenarios;
- keep steps business-readable but avoid vague assertions;
- avoid brittle selectors when a stable field name exists;
- separate setup, action, check, and cleanup;
- capture screenshots and status consistently for failures.
- for installation flows, assert durable postconditions in the base, not only the final visible page.

## xUnit Quality Rules

- keep tests small and deterministic;
- one reason to fail per test;
- include both positive and negative cases where the branch matters;
- reset local state in setup/teardown hooks when the framework version supports them;
- use UI only when code-level proof is insufficient.
