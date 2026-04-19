# Codex Adapter

Use [../../core/SKILL.md](../../core/SKILL.md) as the source of truth.

Codex-specific behavior:

- inspect the repository before choosing UI or xUnit;
- prefer the cheapest proving test first;
- run dedicated `run-*` and `debug-*` commands instead of inventing compound commands;
- always cite paths under `artifacts/` when describing failures or reruns;
- state environment blockers directly when the 1C runtime is unavailable.

