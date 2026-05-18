# AI Agent Repo Readiness Report

**Project:** Example SaaS App  
**Date:** 2025-01-15  
**Auditor:** AgentOps Sprint  
**Scope:** Full repository audit for AI coding agent safety

---

## Executive Summary

**Readiness Score: 25/100 — Grade D (Not Agent-Ready)**

This repository has significant gaps that make it dangerous for AI coding agent operations. The most critical issues are: no agent governance files, no CI pipeline, exposed `.env` in git history, and zero test coverage on core business logic. An AI agent given write access today could silently break production.

---

## 1. Test/CI Map

### What Exists

| Component | Status | Location |
|-----------|--------|----------|
| Test framework | Jest installed | `package.json` devDependencies |
| Test scripts | 3 test files | `src/__tests__/utils.test.ts` |
| CI pipeline | None | No `.github/workflows/` |
| Pre-commit hooks | None | No `.husky` or `.pre-commit-config.yaml` |

### What's Missing

- **No tests for API routes** — `src/pages/api/` has 12 endpoints, 0 tests
- **No tests for database layer** — `src/lib/db.ts` handles all DB operations, untested
- **No integration tests** — only unit tests for utility functions
- **No CI pipeline** — nothing runs on push/PR
- **No test coverage reporting** — no `--coverage` in test script
- **No E2E tests** — no Playwright/Cypress/anything

### Test Coverage Estimate

```text
src/
  __tests__/          → 3 files, ~45 test cases (utils only)
  pages/api/          → 0 tests (12 endpoints)
  lib/                → 0 tests (8 modules)
  components/         → 0 tests (23 components)
  hooks/              → 0 tests (5 hooks)

Estimated coverage: ~8% of source files
```

---

## 2. Risky Directories

| Directory | Risk Level | Why |
|-----------|------------|-----|
| `prisma/migrations/` | Critical | DB schema changes — destructive if applied by agent |
| `src/lib/auth.ts` | Critical | Authentication logic — security sensitive |
| `src/lib/db.ts` | High | Database layer — data integrity risk |
| `src/pages/api/stripe/` | High | Payment webhooks — financial risk |
| `.env` | Critical | Contains secrets, tracked in git |
| `config/` | High | App configuration — affects all behavior |
| `src/lib/email.ts` | Medium | Transactional email — spam/deliverability risk |

---

## 3. Missing Guardrails

| Guardrail | Status | Impact |
|-----------|--------|--------|
| AGENTS.md | Missing | Agents have no governance rules |
| WINDSURF_RULES.md | Missing | No tool-specific safety config |
| .cursorrules | Missing | No Cursor-specific rules |
| PR template | Missing | No agent-safety checklist on PRs |
| Branch protection | Not enabled | Anyone can push to main |
| Pre-commit hooks | Missing | No lint/test enforcement on commit |
| Secret scanning | Not configured | Leaked secrets go undetected |
| CI gates | Missing | No automated quality checks |

---

## 4. Agent Workflow Recommendation

For this repository, the recommended agent workflow is:

1. **Mandatory AGENTS.md** — Must be created before any agent work
2. **Read-only audit first** — Every task starts with inspection, not editing
3. **Feature branches only** — Never work on `main`
4. **PR required** — All changes go through PR with the safety template
5. **CI must pass** — Once CI is set up, no merge without green checks
6. **Forbidden zones** — `prisma/migrations/`, `.env*`, `src/lib/auth.ts`, `src/pages/api/stripe/`

---

## 5. Top 10 Fixes (Prioritized)

| # | Fix | Impact | Effort |
|---|-----|--------|--------|
| 1 | Remove `.env` from git tracking, rotate secrets | Critical — active leak | 30 min |
| 2 | Create `AGENTS.md` with governance rules | Critical — no agent discipline | 1 hour |
| 3 | Add GitHub Actions CI (lint + test + typecheck) | High — no quality gate | 2 hours |
| 4 | Add tests for `src/lib/auth.ts` | High — auth is untested | 3 hours |
| 5 | Add tests for `src/lib/db.ts` | High — data layer untested | 3 hours |
| 6 | Enable branch protection on `main` | High — anyone can push | 15 min |
| 7 | Create PR template with agent checklist | Medium — PRs unstructured | 30 min |
| 8 | Add pre-commit hooks (lint + typecheck) | Medium — no commit enforcement | 1 hour |
| 9 | Add `WINDSURF_RULES.md` with allow/deny lists | Medium — no tool safety | 1 hour |
| 10 | Add API route tests (at least smoke tests) | Medium — endpoints untested | 4 hours |

---

## "If You Give an Agent a Task Today" — Top 5 Breakage Scenarios

1. **Agent deletes a migration file** → Database schema drift, data loss
2. **Agent modifies `.env`** → Secrets exposed in git diff, potential credential theft
3. **Agent changes `auth.ts` without tests** → Authentication bypass, user data breach
4. **Agent pushes directly to main** → Unreviewed code in production, no rollback plan
5. **Agent upgrades a dependency** → Breaking change in Stripe API, payment failures

---

## Appendix: Raw Command Outputs

```text
$ npm test
> jest
PASS src/__tests__/utils.test.ts
  ✓ formatDate returns ISO string (3ms)
  ✓ truncate handles empty string (1ms)
  ✓ slugify converts special chars (2ms)

Test Suites: 1 passed, 1 total
Tests:       3 passed, 3 total
Coverage:    not configured

$ npm run lint
> eslint .
0 errors, 12 warnings

$ npx tsc --noEmit
src/lib/auth.ts:15 - error TS2304: Cannot find name 'Session'
src/pages/api/stripe/webhook.ts:8 - error TS2307: Cannot find module 'stripe'
2 errors found

$ npm audit
1 critical | 3 high | 5 moderate | 12 low
```
