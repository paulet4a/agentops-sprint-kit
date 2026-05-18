# Agent Task Prompt Templates

> Copy-paste these prompts when assigning tasks to your AI coding agent.
> Each template enforces the Plan → Approve → Patch → Test → Report workflow from AGENTS.md.

---

## 1. Audit Only, No Edits

```text
You are in AUDIT MODE. Do NOT edit any files.

Inspect this repository and produce a structured report:

1. **Test/CI Map**: What test frameworks exist? What CI pipelines are configured? What's missing?
2. **Risky Directories**: Which directories/files would be dangerous for an AI agent to modify? List with risk levels.
3. **Missing Guardrails**: What safety mechanisms are absent? (AGENTS.md, pre-commit hooks, branch protection, etc.)
4. **Agent Workflow Recommendation**: What workflow should an AI agent follow in this repo? Be specific to this codebase.
5. **Top 10 Fixes with Evidence**: List the 10 most impactful improvements, with file paths and line numbers.

All claims must cite specific file paths and line numbers. No speculation.
```

---

## 2. Implement with Tests

```text
You are in IMPLEMENT MODE. Follow the Plan → Approve → Patch → Test → Report workflow.

Task: [DESCRIBE THE FEATURE/TASK HERE]

Before coding:
1. Read AGENTS.md and understand the governance rules
2. Analyze the codebase to understand where this change fits
3. Present a plan: which files you'll modify, what tests you'll add, what risks exist
4. WAIT for my approval before making any changes

After approval:
1. Implement the change
2. Write tests for the new behavior FIRST (TDD preferred)
3. Run the full test suite — all must pass
4. Run lint and typecheck — zero errors
5. Report: what changed, the diff, test results, any follow-ups

Do NOT touch files outside the approved plan.
Do NOT skip failing tests or add ignore directives.
```

---

## 3. Fix Failing CI

```text
You are in FIX MODE. CI is failing. Follow the Plan → Approve → Patch → Test → Report workflow.

CI failure details:
[PASTE CI ERROR OUTPUT HERE]

Before fixing:
1. Read AGENTS.md
2. Reproduce the failure locally if possible
3. Identify root cause — don't just patch the symptom
4. Present your diagnosis and proposed fix
5. WAIT for my approval

After approval:
1. Apply the minimal fix
2. Run the full test suite
3. Run lint and typecheck
4. Verify CI would pass (run the same commands CI runs)
5. Report: root cause, fix applied, verification results

Do NOT disable failing tests. Do NOT add ignore/skip directives without justification.
```

---

## 4. Refactor Without Behavior Change

```text
You are in REFACTOR MODE. The goal is structural improvement with ZERO behavior change.

Refactoring target: [DESCRIBE WHAT TO REFACTOR]

Rules:
1. Read AGENTS.md
2. Identify all files affected by this refactoring
3. Ensure there are tests that verify current behavior — if not, WRITE THEM FIRST
4. Present your refactoring plan with before/after examples
5. WAIT for my approval

After approval:
1. Make changes incrementally — one logical step at a time
2. Run tests after EACH step — they must pass at every point
3. No behavior changes allowed — same inputs, same outputs
4. Run lint and typecheck
5. Report: what was refactored, test results, any risks

If tests don't exist for the code being refactored, STOP and ask me to approve writing characterization tests first.
```

---

## 5. Add Feature Behind Flag

```text
You are in FEATURE FLAG MODE. Implement a new feature gated behind a feature flag.

Feature: [DESCRIBE THE FEATURE]
Flag name: [SUGGEST A FLAG NAME]

Rules:
1. Read AGENTS.md
2. Identify where the flag should be defined and checked
3. Plan: which files to modify, how the flag gates the feature, what tests to add
4. WAIT for my approval

After approval:
1. Add the flag definition in the appropriate config
2. Implement the feature, gated behind the flag (off by default)
3. Add tests for both flag states (on and off)
4. Run full test suite with flag OFF — nothing should change
5. Run tests with flag ON — new behavior should work
6. Run lint and typecheck
7. Report: flag location, feature implementation, test results

The flag MUST be off by default. Existing behavior MUST be unchanged when flag is off.
```

---

## 6. Generate Migration But Don't Apply

```text
You are in MIGRATION MODE. Create a database migration but DO NOT apply it.

Migration purpose: [DESCRIBE THE SCHEMA CHANGE]

Rules:
1. Read AGENTS.md — migrations are CRITICAL zone
2. Analyze the current schema and affected models
3. Plan: what the migration does, rollback strategy, risks
4. WAIT for my approval

After approval:
1. Generate the migration file ONLY
2. Include both UP and DOWN (rollback) migrations
3. Do NOT run the migration — just create the file
4. Verify the migration file is syntactically valid
5. Report: migration file path, what it does, rollback plan, risks

NEVER execute: prisma migrate deploy, prisma db push, or any direct SQL against a database.
```

---

## 7. Create Report with Evidence

```text
You are in REPORT MODE. Produce an evidence-based report. Do NOT edit any files.

Report topic: [DESCRIBE WHAT TO REPORT ON]

Rules:
1. Inspect the relevant code, configs, and logs
2. Every claim must cite: file path, line number, or command output
3. No speculation — if you're unsure, say "UNVERIFIED:" and explain what you'd need to check
4. Structure the report with:
   - Executive Summary (3-5 sentences)
   - Findings (each with evidence)
   - Risk Assessment (rated: Critical / High / Medium / Low)
   - Recommendations (ordered by impact)
   - Appendix: raw command outputs

Do NOT make any code changes. This is a read-only task.
```
