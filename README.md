# Agent-Safe Repo Sprint

> **Your AI coding agent is fast. Your repo is not ready.**

48-hour sprint to harden your repository for Windsurf / Cursor / Codex: agent rules, CI gates, PR templates, safety workflows, and a repo-readiness audit.

## The Problem

- 84% of developers use AI coding tools (Stack Overflow 2025)
- 46% don't trust AI output accuracy
- 45% of AI-generated code has security flaws (Veracode 2025)

Everyone ships fast with AI agents, but nobody manages what the agent breaks, which tests must pass, or what it shouldn't touch.

## What This Kit Delivers

| Deliverable | Description |
|---|---|
| **Repo Risk Audit** | Test/CI map, risky directories, missing guardrails, agent readiness score, top 10 fixes |
| **Agent Rules Pack** | `AGENTS.md`, `WINDSURF_RULES.md`, plan→approve→patch→test→report workflow, forbidden actions |
| **CI / Safety Gates** | GitHub Actions: lint + test + typecheck + dependency audit + secret scan |
| **Agent Task Templates** | 7 copy-paste prompts for safe agent task assignment |
| **Handoff Document** | What changed, how to use rules, pre-merge commands, 7-day improvement plan |

## Quick Start

### 1. Audit Your Repo

```bash
bash scripts/repo_readiness_check.sh
```

### 2. Scan for Secrets

```bash
python3 scripts/simple_secret_scan.py
```

### 3. Generate Risk Map

```bash
python3 scripts/collect_project_map.py
```

### 4. Detect Package Manager

```bash
bash scripts/detect_package_manager.sh
```

## File Structure

```
agentops-sprint-kit/
├── templates/
│   ├── AGENTS.md              # Agent governance constitution
│   ├── WINDSURF_RULES.md      # Windsurf-specific allow/deny lists
│   ├── PR_TEMPLATE.md         # PR template with agent-safety checklist
│   ├── agent-task-prompts.md  # 7 reusable agent task templates
│   └── agent-handoff.md       # Founder handoff document
├── scripts/
│   ├── repo_readiness_check.sh    # Full repo audit with scoring
│   ├── detect_package_manager.sh  # Auto-detect package manager
│   ├── collect_project_map.py     # Directory tree + risk scoring
│   └── simple_secret_scan.py      # Regex-based secret detector
├── reports/
│   ├── sample-readiness-report.md # Example audit output
│   └── sample-founder-summary.md  # Example founder handoff
├── workflows/
│   └── agent-safety.yml       # GitHub Actions CI safety gate
└── landing/
    └── index.html             # Landing page (TailwindCSS)
```

## Pricing

| Package | Price | Description |
|---|---|---|
| Mini Repo Chaos Audit | $149 | Quick risk snapshot |
| 48h Agent-Safe Sprint | $497 (beta) / $997 | Full repo hardening |
| Monthly AgentOps Retainer | $750/mo | Ongoing governance |

## Who Is This For?

- 1–5 person SaaS teams using Cursor/Windsurf/Codex
- Solo founders shipping with AI
- Indie hackers and small agencies
- Teams with no CTO or senior review

## Philosophy

This is **not** "AI automation agency" work. This is **AgentOps for small software teams** — production repo discipline for AI-assisted development.

**Honest promise:** "48 hours, I make your repo safer, more controlled, and more testable for AI agent usage. I don't guarantee code quality — I set up workflow, guardrails, and visibility."

## License

MIT
