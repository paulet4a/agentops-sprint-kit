#!/usr/bin/env bash
# repo_readiness_check.sh — AI Agent Repo Readiness Audit
# Run this script to assess how prepared your repo is for AI coding agent usage.
# Usage: bash repo_readiness_check.sh [--json] [--quiet]

set -euo pipefail

JSON_OUTPUT=false
QUIET=false
for arg in "$@"; do
  case "$arg" in
    --json) JSON_OUTPUT=true ;;
    --quiet) QUIET=true ;;
  esac
done

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Score tracking
SCORE=0
MAX_SCORE=100
FINDINGS=()
WARNINGS=()
CRITICAL=()

pass() { ((SCORE+=5)); FINDINGS+=("[PASS] $1"); }
warn() { WARNINGS+=("[WARN] $1"); }
fail() { CRITICAL+=("[FAIL] $1"); }
info() { $QUIET || printf "${CYAN}[INFO]${NC} %s\n" "$1"; }

# 1. AGENTS.md / Governance
info "Checking for agent governance files..."
if [ -f "AGENTS.md" ]; then
  pass "AGENTS.md exists"
else
  fail "AGENTS.md is missing — agents have no governance rules"
fi

if [ -f "WINDSURF_RULES.md" ] || [ -f ".windsurfrules" ] || [ -f ".cursorrules" ] || [ -f "CLAUDE.md" ]; then
  pass "Tool-specific agent rules file exists"
else
  warn "No tool-specific agent rules (WINDSURF_RULES.md, .cursorrules, CLAUDE.md)"
fi

# 2. Test infrastructure
info "Checking test infrastructure..."
HAS_TESTS=false

if [ -f "package.json" ]; then
  if grep -q '"test"' package.json 2>/dev/null; then
    pass "npm test script defined"
    HAS_TESTS=true
  else
    warn "No 'test' script in package.json"
  fi
fi

if [ -f "pytest.ini" ] || [ -f "pyproject.toml" ] || [ -f "setup.cfg" ]; then
  if grep -q "pytest\|unittest" pyproject.toml setup.cfg 2>/dev/null; then
    pass "Python test framework detected"
    HAS_TESTS=true
  fi
fi

if [ -d "tests" ] || [ -d "test" ] || [ -d "__tests__" ] || [ -d "spec" ]; then
  pass "Test directory exists"
  HAS_TESTS=true
else
  warn "No test directory found (tests/, test/, __tests__/, spec/)"
fi

if [ "$HAS_TESTS" = false ]; then
  fail "No test infrastructure detected — agent changes are unverified"
fi

# 3. CI/CD
info "Checking CI/CD configuration..."
if [ -d ".github/workflows" ]; then
  WORKFLOW_COUNT=$(find .github/workflows -name "*.yml" -o -name "*.yaml" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$WORKFLOW_COUNT" -gt 0 ]; then
    pass "GitHub Actions workflows found ($WORKFLOW_COUNT)"
  else
    warn ".github/workflows/ exists but contains no workflow files"
  fi
else
  fail "No CI/CD workflows found — no automated quality gates"
fi

if [ -f ".gitlab-ci.yml" ]; then pass "GitLab CI configured"; fi
if [ -f "Jenkinsfile" ]; then pass "Jenkins pipeline configured"; fi

# 4. Lint / Typecheck
info "Checking lint and typecheck..."
if [ -f "package.json" ]; then
  if grep -q '"lint"' package.json 2>/dev/null; then
    pass "npm run lint script defined"
  else
    warn "No 'lint' script in package.json"
  fi
fi

if [ -f ".eslintrc" ] || [ -f ".eslintrc.js" ] || [ -f ".eslintrc.json" ] || [ -f "eslint.config.js" ] || [ -f "eslint.config.mjs" ]; then
  pass "ESLint config found"
fi

if [ -f "ruff.toml" ] || [ -f ".ruff.toml" ] || grep -q "ruff" pyproject.toml 2>/dev/null; then
  pass "Ruff (Python linter) config found"
fi

if [ -f "tsconfig.json" ]; then
  pass "TypeScript config found"
  if grep -q '"noEmit"' tsconfig.json 2>/dev/null || grep -q '"strict"' tsconfig.json 2>/dev/null; then
    pass "TypeScript strict/noEmit enabled"
  else
    warn "TypeScript config exists but strict mode may not be enabled"
  fi
fi

if [ -f "mypy.ini" ] || grep -q "mypy" pyproject.toml 2>/dev/null; then
  pass "mypy (Python type checker) config found"
fi

# 5. Secret leak risk
info "Checking for secret leak risks..."
SECRET_RISK=0

if [ -f ".env" ]; then
  if git check-ignore .env 2>/dev/null; then
    pass ".env exists and is gitignored"
  else
    fail ".env exists but is NOT in .gitignore — SECRETS MAY BE LEAKED"
    ((SECRET_RISK++))
  fi
fi

if [ -f ".env.example" ] || [ -f ".env.template" ]; then
  pass ".env.example template exists"
else
  warn "No .env.example — new developers won't know what env vars are needed"
fi

if git ls-files --cached 2>/dev/null | grep -qiE '\.env\.production|\.env\.local|\.env\.\$'; then
  fail "Production env files are tracked in git — IMMEDIATE RISK"
  ((SECRET_RISK++))
fi

if git log --all --diff-filter=A -- '*.pem' '*.key' '*.p12' '*.pfx' 2>/dev/null | head -1 | grep -q .; then
  warn "Private key files found in git history"
  ((SECRET_RISK++))
fi

if [ "$SECRET_RISK" -gt 0 ]; then
  warn "Secret leak risk detected — run simple_secret_scan.py for full audit"
fi

# 6. Git hygiene
info "Checking git hygiene..."
if [ -f ".gitignore" ]; then
  pass ".gitignore exists"
else
  fail "No .gitignore — build artifacts and secrets may be committed"
fi

BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
if [ "$BRANCH" = "main" ] || [ "$BRANCH" = "master" ]; then
  warn "Currently on $BRANCH branch — agents should work on feature branches"
fi

# 7. Dependency audit
info "Checking dependency health..."
if [ -f "package.json" ] && command -v npm &>/dev/null; then
  AUDIT_OUTPUT=$(npm audit 2>/dev/null || true)
  if echo "$AUDIT_OUTPUT" | grep -q "0 vulnerabilities"; then
    pass "npm audit: 0 vulnerabilities"
  else
    VULN_COUNT=$(echo "$AUDIT_OUTPUT" | grep -oP '\d+ vulnerabilities' | head -1 || echo "unknown")
    warn "npm audit found $VULN_COUNT"
  fi
fi

if [ -f "requirements.txt" ] && command -v pip-audit &>/dev/null; then
  if pip-audit -r requirements.txt --desc 2>/dev/null | grep -q "0 vulnerabilities"; then
    pass "pip-audit: 0 vulnerabilities"
  else
    warn "pip-audit found vulnerabilities — run: pip-audit -r requirements.txt"
  fi
fi

# 8. PR template
info "Checking PR templates..."
if [ -f ".github/pull_request_template.md" ]; then
  pass "PR template exists"
else
  warn "No PR template — agent PRs won't follow a safety checklist"
fi

# 9. Pre-commit hooks
info "Checking pre-commit hooks..."
if [ -d ".git/hooks" ] && [ -f ".git/hooks/pre-commit" ]; then
  pass "Pre-commit hook is installed"
elif [ -f ".pre-commit-config.yaml" ]; then
  pass "pre-commit framework configured"
else
  warn "No pre-commit hooks — lint/typecheck not enforced on commit"
fi

# 10. Branch protection
info "Checking branch protection (requires gh CLI)..."
if command -v gh &>/dev/null && git remote get-url origin &>/dev/null 2>&1; then
  REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "")
  if [ -n "$REPO" ]; then
    PROTECTION=$(gh api "repos/$REPO/branches/main/protection" 2>/dev/null || echo "")
    if [ -n "$PROTECTION" ]; then
      pass "Branch protection enabled on main"
    else
      warn "No branch protection on main — anyone (or any agent) can push directly"
    fi
  fi
else
  warn "gh CLI not available — cannot check branch protection. Check manually in GitHub Settings."
fi

# Output
if [ "$JSON_OUTPUT" = true ]; then
  printf '{"score": %d, "max": %d}\n' "$SCORE" "$MAX_SCORE"
else
  echo ""
  echo "═══════════════════════════════════════════════════════════"
  echo "  AI AGENT REPO READINESS REPORT"
  echo "═══════════════════════════════════════════════════════════"
  echo ""
  printf "  Score: ${GREEN}%d${NC}/%d\n" "$SCORE" "$MAX_SCORE"

  if [ "$SCORE" -ge 80 ]; then
    printf "  Grade: ${GREEN}A — Agent-ready${NC}\n"
  elif [ "$SCORE" -ge 60 ]; then
    printf "  Grade: ${YELLOW}B — Mostly ready, some gaps${NC}\n"
  elif [ "$SCORE" -ge 40 ]; then
    printf "  Grade: ${YELLOW}C — Significant gaps — agent may cause damage${NC}\n"
  elif [ "$SCORE" -ge 20 ]; then
    printf "  Grade: ${RED}D — Not agent-ready — high risk${NC}\n"
  else
    printf "  Grade: ${RED}F — Dangerous — do not let agents edit this repo${NC}\n"
  fi

  echo ""
  if [ ${#CRITICAL[@]} -gt 0 ]; then
    printf "  ${RED}CRITICAL ISSUES (${#CRITICAL[@]}):${NC}\n"
    for c in "${CRITICAL[@]}"; do printf "    ${RED}%s${NC}\n" "$c"; done
    echo ""
  fi

  if [ ${#WARNINGS[@]} -gt 0 ]; then
    printf "  ${YELLOW}WARNINGS (${#WARNINGS[@]}):${NC}\n"
    for w in "${WARNINGS[@]}"; do printf "    ${YELLOW}%s${NC}\n" "$w"; done
    echo ""
  fi

  if [ ${#FINDINGS[@]} -gt 0 ]; then
    printf "  ${GREEN}PASSED (${#FINDINGS[@]}):${NC}\n"
    for f in "${FINDINGS[@]}"; do printf "    ${GREEN}%s${NC}\n" "$f"; done
    echo ""
  fi

  echo "═══════════════════════════════════════════════════════════"
  echo "  Run 'python3 scripts/simple_secret_scan.py' for deep secret audit"
  echo "  Run 'python3 scripts/collect_project_map.py' for risk heat map"
  echo "═══════════════════════════════════════════════════════════"
fi
