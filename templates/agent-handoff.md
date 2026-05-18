# Agent Handoff Document

> This document is delivered to the founder/team after the Agent-Safe Repo Sprint.
> It explains what changed, how to use the new agent rules, and what to do next.

---

## What Changed

### Files Added

| File | Purpose |
|------|---------|
| `AGENTS.md` | Agent governance protocol — the constitution for AI agents in your repo |
| `WINDSURF_RULES.md` | Windsurf-specific safety config (allow/deny lists, auto-execution levels) |
| `.github/pull_request_template.md` | PR template with agent-safety checklist |
| `.github/workflows/agent-safety.yml` | CI safety gate (lint + test + typecheck + secret scan) |
| `scripts/agent_preflight.sh` | Pre-merge safety check script |

### Files Modified

| File | Change | Why |
|------|--------|-----|
| <!-- path --> | <!-- what changed --> | <!-- reason --> |

---

## How to Use the Agent Rules

### Before Giving an Agent a Task

1. **Always reference AGENTS.md** — When starting a new agent session, say: "Read AGENTS.md before proceeding"
2. **Use task templates** — Copy prompts from `agent-task-prompts.md` instead of writing ad-hoc instructions
3. **Start in audit mode** — Before big changes, use the "Audit Only, No Edits" template first

### During Agent Work

1. **Review the plan** — The agent must present a plan before editing. Read it carefully.
2. **Approve explicitly** — Say "approved" or "go ahead" only after reviewing the plan
3. **Watch the diff** — After each change, review `git diff` output
4. **Don't rush** — If the agent says "I also fixed X while I was there," reject the scope creep

### After Agent Completes Work

1. **Run the preflight check**: `bash scripts/agent_preflight.sh`
2. **Review the PR** using the PR template checklist
3. **Merge only if all checks pass** — tests, lint, typecheck, no secrets

---

## Commands to Run Before Merging

```bash
# Run all safety checks
bash scripts/agent_preflight.sh

# Or run individually:
npm test              # or: pytest, pnpm test, etc.
npm run lint          # or: ruff check, eslint .
npx tsc --noEmit      # or: mypy .
npm audit             # or: pip audit
```

If any of these fail, **do not merge**. Fix the issue first.

---

## What NOT to Let AI Agents Do

### Never Allow

- Delete files without explicit approval
- Modify `.env`, `.env.production`, or any secrets file
- Run or apply database migrations directly
- Push to `main` branch directly
- Force-push to any branch
- Deploy to production
- Install or upgrade dependencies without running audit first
- Modify CI/CD pipelines without review
- Change authentication/authorization logic without security review
- Add `// @ts-ignore`, `# type: ignore`, or `eslint-disable` without justification
- Skip or disable failing tests

### Always Require Approval For

- Changes to `package.json`, `requirements.txt`, or any dependency file
- Changes to config files (`tsconfig.json`, `vite.config.*`, `next.config.*`, etc.)
- Any file in `migrations/` directory
- Any file in `.github/workflows/`
- Any file in `config/` or `config/`-adjacent directories

---

## 7-Day Improvement Plan

### Day 1–2: Stabilize

- [ ] Run `agent_preflight.sh` and fix any failures
- [ ] Add missing tests for the 5 most critical paths
- [ ] Set up branch protection on `main` (require PR + passing CI)

### Day 3–4: Harden

- [ ] Add pre-commit hooks (lint + typecheck on commit)
- [ ] Set up secret scanning (GitHub native or `simple_secret_scan.py`)
- [ ] Add `AGENTS.md` reference to your onboarding docs

### Day 5–6: Scale

- [ ] Create agent task templates for your 3 most common task types
- [ ] Set up a "staging" branch that mirrors production for agent testing
- [ ] Document your repo-specific forbidden zones in AGENTS.md

### Day 7: Review

- [ ] Review all agent-created PRs from the past week
- [ ] Identify patterns: what does the agent get wrong most often?
- [ ] Update AGENTS.md with repo-specific rules based on learnings
- [ ] Consider adding the Monthly AgentOps Retainer for ongoing support

---

## Quick Reference Card

| Situation | What to Do |
|-----------|------------|
| Agent wants to edit files | Make sure it presented a plan and you approved it |
| Agent deleted something | Revert immediately. Add the file to forbidden list in AGENTS.md |
| Tests fail after agent edit | Don't merge. Ask agent to fix or revert. Don't let it skip tests |
| Agent touched `.env` | Audit the change. Rotate any exposed secrets immediately |
| Agent wants to deploy | Stop it. Deploy only happens through your CI/CD pipeline |
| Agent modified deps | Run `npm audit` / `pip audit` before merging |
| You're unsure about a change | Don't merge. Ask for a second opinion or run the preflight check |

---

## Support

If you need ongoing agent governance support, the **Monthly AgentOps Retainer** includes:
- Monthly repo health audit
- AGENTS.md updates as your codebase evolves
- CI gate adjustments
- Agent workflow optimization
- Priority support for agent-related incidents

Contact: [YOUR CONTACT INFO]
