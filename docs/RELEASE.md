# Release

## Release Checklist

1. Run `python3 skill/scripts/onec_test_cli.py bootstrap --dry-run` on at least one non-Windows machine if you claim cross-platform repo-side support.
2. Run `python3 skill/scripts/onec_test_cli.py doctor` on the target machine class used by the team.
3. Confirm `.env.example` matches current script expectations.
4. Confirm `skill/core/SKILL.md` is still the main entrypoint.
5. Confirm examples open the expected local cycle.
6. Confirm `python3 skill/scripts/onec_test_cli.py package-skill` creates a distributable zip in `dist/`.
7. Confirm `artifacts/` and local env files are not bundled accidentally.
8. Prepare a short changelog and PR text.

## Packaging

```bash
python3 skill/scripts/onec_test_cli.py package-skill
```

## Push Policy

- if a remote exists and credentials are available, push the working branch after local review;
- if not, keep local commits and state clearly that the repository is ready to push but not yet pushed.

## Suggested PR Text

```
Build a cross-platform 1C testing skill package for agent workflows.

- add core docs and thin adapters for Codex/Cursor/Claude
- add Vanessa Automation and xUnitFor1C templates and smoke examples
- add cross-platform Python bootstrap/doctor/run/debug/artifact/package commands
- keep PowerShell as a thin Windows wrapper, not the core runtime
- add install, quickstart, release, and CI example docs
- document honest runtime limits and optional vanessa-runner usage
```
