# Pull Request Template — Agent-Safe Review

## Description

<!-- Brief description of what this PR does and why -->

## Agent Origin

- [ ] This PR was created or assisted by an AI coding agent (Windsurf / Cursor / Codex / other)
- [ ] The agent followed AGENTS.md governance rules
- [ ] The agent operated in the approved workflow (Plan → Approve → Patch → Test → Report)

If agent-assisted, link the agent's plan/report: <!-- paste or link -->

---

## Agent Before-Merge Checklist

### Safety Checks

- [ ] No files were deleted without explicit approval
- [ ] No production config was modified (`.env.production`, deploy configs)
- [ ] No database migrations were applied (created only)
- [ ] No secrets, API keys, or tokens were added or exposed
- [ ] No destructive commands were executed (`rm -rf`, `DROP TABLE`, etc.)
- [ ] No dependencies were upgraded without audit

### Quality Checks

- [ ] All existing tests pass
- [ ] New tests added for new behavior
- [ ] Lint passes (`npm run lint` / `ruff check` / equivalent)
- [ ] Typecheck passes (`tsc --noEmit` / `mypy` / equivalent)
- [ ] No `// @ts-ignore`, `# type: ignore`, `eslint-disable` added without justification
- [ ] No `!important` or force-workarounds added

### Diff Review

- [ ] I have reviewed the full diff (`git diff main...HEAD`)
- [ ] No speculative or "while I'm here" changes are included
- [ ] Changes are scoped to the approved plan only
- [ ] No unrelated files were modified

---

## Smoke Test Checklist

- [ ] Application starts without errors
- [ ] Main user flow works (login → core action → logout)
- [ ] No console errors in browser
- [ ] API health check returns 200
- [ ] No visual regressions on key pages

---

## Test Results

<!-- Paste the output of your test run -->

```text
# Example:
# npm test → 42 passed, 0 failed
# npm run lint → 0 errors, 0 warnings
# tsc --noEmit → no errors
```

---

## What Changed

| File | Change Type | Description |
|------|-------------|-------------|
| <!-- path --> | <!-- added/modified/deleted --> | <!-- what and why --> |

---

## Risks & Follow-ups

- <!-- Any remaining risks or things to watch -->
- <!-- Follow-up tasks not included in this PR -->
