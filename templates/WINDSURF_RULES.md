# WINDSURF_RULES.md — Windsurf Cascade Safety Configuration

> Windsurf-specific rules for the Cascade coding agent.
> These rules complement AGENTS.md with Windsurf terminal and execution controls.

---

## Auto-Execution Levels

Windsurf supports auto-execution levels. Use these settings:

| Level | Setting | When to Use |
|---|---|---|
| 0 | Manual approval for everything | Default. Use for production repos. |
| 1 | Auto-run safe read commands | Audit mode — allow `cat`, `ls`, `grep`, `rg`, `git log`, `git diff` |
| 2 | Auto-run safe write commands | Patch mode — allow approved file edits only |
| 3 | Full auto | **NEVER USE** in this repo |

**Recommended default: Level 0**
**Audit mode: Level 1**
**Approved patch mode: Level 2 (only after human confirms the plan)**

---

## Terminal Allow/Deny Lists

### Allowlist (safe to auto-execute)

```sh
# Read-only inspection
cat, head, tail, less, more
ls, find, fd, tree
grep, rg, ag
git status, git log, git diff, git branch, git show
npm list, npm outdated, npm audit
pip list, pip show, pip check
pnpm list, pnpm outdated
pytest --collect-only, pytest -v --dry-run
npm test -- --dry-run
tsc --noEmit
eslint --no-fix
prettier --check
ruff check
mypy --no-error-summary

# Safe diagnostics
node -e "console.log(process.version)"
python --version
which, where, command -v
echo, printf
wc, sort, uniq, cut, awk
```

### Denylist (NEVER auto-execute)

```sh
# Destructive filesystem
rm -rf, rm -r, rmdir /s
del /s, rd /s
shred, srm

# Destructive git
git push --force, git push -f
git push origin --delete
git reset --hard
git clean -fd
git checkout -- .

# Production/deploy
vercel --prod
railway up
fly deploy
heroku push
aws deploy
docker push *:latest

# Database
psql -c "DROP", psql -c "TRUNCATE", psql -c "DELETE"
mongosh --eval "db.drop"
redis-cli FLUSHALL, redis-cli FLUSHDB
prisma migrate deploy
npx prisma db push

# Secrets/env
export SECRET, export API_KEY, export TOKEN
echo $SECRET, echo $API_KEY
cat .env, cat .env.production
printenv, env

# Package management (global)
npm install -g
pip install --user

# Network
curl -X DELETE
wget --post-data
nc -l, ncat -l
```

---

## Cascade Workflow Rules

### Before Starting a Task

1. Read `AGENTS.md` and this file
2. Run `git status` to understand current state
3. Identify the branch you're on — never work directly on `main`
4. Check if there are uncommitted changes — report them before proceeding

### During a Task

1. **One change at a time** — don't batch unrelated edits
2. **Show the diff** — use `git diff` after each change
3. **Run tests after each logical change** — not just at the end
4. **Never skip failing tests** — report them, don't `// @ts-ignore` or `pytest.skip()`
5. **Never add `!important`** or force-push workarounds

### After Completing a Task

1. Run the full test suite
2. Run lint and typecheck
3. Summarize all changes with file paths
4. Create a branch (never commit to main)
5. Suggest a PR with the PR template from `.github/pull_request_template.md`

---

## Context Awareness

Cascade has access to:
- **Edit history** — use it to understand what changed recently
- **Terminal commands** — use allow/deny lists above
- **File system** — respect directory safety zones in AGENTS.md
- **Browser preview** — use for visual verification, not for scraping
- **Web search** — use for documentation lookup only, not for code generation from random sources
- **MCP plugins** — GitHub, Supabase, etc. — use read operations freely, write operations need approval

---

## Error Handling

When a command fails:
1. Report the **exact command** that was run
2. Report the **full error output** (don't truncate)
3. Suggest a **specific fix** with evidence
4. Do NOT retry the command automatically
5. Do NOT attempt alternative destructive approaches

---

## Branch Naming Convention

When Cascade creates branches:
- Feature: `agent/feat/<short-description>`
- Fix: `agent/fix/<short-description>`
- Audit: `agent/audit/<short-description>`
- Refactor: `agent/refactor/<short-description>`

Example: `agent/fix/missing-test-gate-in-ci`
