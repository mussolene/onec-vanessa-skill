# Release

## Release Checklist

1. Run `bootstrap.ps1` and `doctor.ps1` on a Windows-ready machine.
2. Confirm `.env.example` matches current script expectations.
3. Confirm `skill/core/SKILL.md` is still the main entrypoint.
4. Confirm examples open the expected local cycle.
5. Confirm `package-skill.ps1` creates a distributable zip in `dist/`.
6. Confirm `artifacts/` and local env files are not bundled accidentally.
7. Prepare a short changelog and PR text.

## Packaging

```powershell
pwsh -File skill/scripts/package-skill.ps1
```

## Push Policy

- if a remote exists and credentials are available, push the working branch after local review;
- if not, keep local commits and state clearly that the repository is ready to push but not yet pushed.

## Suggested PR Text

```
Build a Windows-first 1C testing skill package for agent workflows.

- add core docs and thin adapters for Codex/Cursor/Claude
- add Vanessa Automation and xUnitFor1C templates and smoke examples
- add bootstrap/doctor/run/debug/artifact/package scripts
- add install, quickstart, release, and CI example docs
- document honest platform limits and optional vanessa-runner usage
```

