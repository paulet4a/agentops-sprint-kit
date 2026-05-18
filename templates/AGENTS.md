# AGENTS.md — Agent Governance Protocol

> This file defines how AI coding agents (Windsurf, Cursor, Codex, Claude, etc.) must operate in this repository.
> Agents MUST read and follow these rules before making any changes.

---

## Core Principle

**Read-only audit first. Always.**

Before touching any file, the agent must:
1. Read this file
2. Inspect the project structure
3. Understand the test/CI landscape
4. Produce a plan and get explicit approval

---

## Mandatory Workflow: Plan → Approve → Patch → Test → Report

Every task follows this sequence. No exceptions.

### Step 1: Plan
- Analyze the request
- Identify affected files and directories
- List risks and dependencies
- Present the plan as a structured document

### Step 2: Approve
- Wait for human approval before proceeding
- If no approval is received, STOP
- Never assume approval from silence

### Step 3: Patch
- Make only the approved changes
- One logical change per patch
- No speculative or "while I'm here" edits

### Step 4: Test
- Run the full test suite after patching
- Run lint and typecheck
- If any check fails, report the failure and STOP
- Do not auto-fix test failures without approval

### Step 5: Report
- Summarize what changed and why
- Provide the diff
- List any remaining risks or follow-ups
- State the exact commands that were run and their results

---

## Forbidden Actions

The following actions are NEVER permitted without explicit human approval:

- **Deleting files** — even seemingly unused ones
- **Modifying production config** — `.env.production`, `vercel.json`, `railway.json`, etc.
- **Touching database migrations** — create only, never apply
- **Accessing secrets** — API keys, tokens, private keys, `.env` files
- **Force-pushing to git** — `git push --force` is banned
- **Deploying to production** — no deploy commands, no merge to main without review
- **Modifying CI/CD pipelines** — only with explicit approval
- **Changing dependency versions** — without running audit first
- **Altering authentication/authorization logic** — without security review
- **Executing destructive SQL** — DROP, TRUNCATE, DELETE without WHERE
- **Running `rm -rf`** or equivalent destructive filesystem commands
- **Installing global packages** — only local dev dependencies allowed
- **Opening network listeners** — no server.start() in test code

---

## Read-Only Audit Mode

When asked to audit, the agent:

1. **MUST NOT edit any files**
2. Inspects code structure, test coverage, CI config, dependency health
3. Produces a structured report with:
   - Test/CI map (what exists, what's missing)
   - Risky directories and files
   - Missing guardrails
   - Agent workflow recommendations
   - Top 10 fixes with evidence (file paths, line numbers)
4. All claims must cite specific file paths and line numbers — no speculation

---

## Diff-First Policy

- Always show the diff before applying changes
- Use `git diff` to verify what will change
- Never commit directly — always create a branch and PR
- Commit messages must reference the task and be descriptive

---

## Evidence-Based Reporting

- Every claim must be backed by a command output, file path, or line number
- No speculative statements like "this might be broken" — instead: "test X on line Y of file Z fails with error: ..."
- If a tool/command is unavailable, state exactly what was attempted and what failed
- Never fabricate test results or command outputs

---

## Directory Safety Zones

The following directories are **read-only** for agents unless explicitly approved:

| Directory | Risk Level | Rule |
|---|---|---|
| `src/` | Medium | Modify only approved files |
| `config/` | High | Read-only unless approved |
| `migrations/` | Critical | Create only, never apply |
| `.env*` | Critical | Never read or modify |
| `scripts/` | Medium | Modify only approved files |
| `dist/`, `build/` | Low | Regenerated, safe to modify |
| `.github/workflows/` | High | Modify only with approval |
| `package.json`, `requirements.txt` | High | Modify only with approval |

---

## Agent Readiness Checklist

Before starting any task, verify:

- [ ] I have read AGENTS.md
- [ ] I understand the project structure
- [ ] I know where tests live and how to run them
- [ ] I know the lint/typecheck commands
- [ ] I have identified the forbidden zones
- [ ] I will follow the Plan → Approve → Patch → Test → Report workflow
- [ ] I will not make speculative changes
- [ ] I will report evidence, not opinions

---

## Emergency Protocol

If the agent detects:
- A security vulnerability → Report immediately, do not attempt to fix without approval
- Data loss risk → Stop all operations, report to human
- Production outage risk → Stop all operations, report to human
- Broken tests after patch → Revert the patch, report the failure

**When in doubt, STOP and ask.**
