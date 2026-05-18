#!/usr/bin/env bash
# detect_package_manager.sh — Auto-detect the package manager used in this repo
# Usage: bash detect_package_manager.sh [--json]

set -euo pipefail

JSON_OUTPUT=false
for arg in "$@"; do
  case "$arg" in
    --json) JSON_OUTPUT=true ;;
  esac
done

PKG_MANAGER="none"
PKG_INSTALL=""
PKG_RUN=""
PKG_TEST=""
PKG_LINT=""
PKG_AUDIT=""
LOCKFILE="none"

# Node.js
if [ -f "pnpm-lock.yaml" ]; then
  PKG_MANAGER="pnpm"; PKG_INSTALL="pnpm install"; PKG_RUN="pnpm run"; PKG_TEST="pnpm test"; PKG_LINT="pnpm run lint"; PKG_AUDIT="pnpm audit"; LOCKFILE="pnpm-lock.yaml"
elif [ -f "yarn.lock" ]; then
  PKG_MANAGER="yarn"; PKG_INSTALL="yarn install"; PKG_RUN="yarn run"; PKG_TEST="yarn test"; PKG_LINT="yarn lint"; PKG_AUDIT="yarn audit"; LOCKFILE="yarn.lock"
elif [ -f "bun.lockb" ] || [ -f "bun.lock" ]; then
  PKG_MANAGER="bun"; PKG_INSTALL="bun install"; PKG_RUN="bun run"; PKG_TEST="bun test"; PKG_LINT="bun run lint"; PKG_AUDIT="bun audit 2>/dev/null || npm audit"; LOCKFILE="bun.lockb"
elif [ -f "package-lock.json" ]; then
  PKG_MANAGER="npm"; PKG_INSTALL="npm install"; PKG_RUN="npm run"; PKG_TEST="npm test"; PKG_LINT="npm run lint"; PKG_AUDIT="npm audit"; LOCKFILE="package-lock.json"
fi

# Python
if [ -f "poetry.lock" ]; then
  if [ "$PKG_MANAGER" = "none" ]; then PKG_MANAGER="poetry"; PKG_INSTALL="poetry install"; PKG_RUN="poetry run"; PKG_TEST="poetry run pytest"; PKG_LINT="poetry run ruff check"; PKG_AUDIT="poetry run pip-audit"; LOCKFILE="poetry.lock"; else PKG_MANAGER="${PKG_MANAGER}+poetry"; fi
elif [ -f "Pipfile.lock" ]; then
  if [ "$PKG_MANAGER" = "none" ]; then PKG_MANAGER="pipenv"; PKG_INSTALL="pipenv install"; PKG_RUN="pipenv run"; PKG_TEST="pipenv run pytest"; PKG_LINT="pipenv run ruff check"; PKG_AUDIT="pipenv run pip-audit"; LOCKFILE="Pipfile.lock"; else PKG_MANAGER="${PKG_MANAGER}+pipenv"; fi
elif [ -f "uv.lock" ]; then
  if [ "$PKG_MANAGER" = "none" ]; then PKG_MANAGER="uv"; PKG_INSTALL="uv sync"; PKG_RUN="uv run"; PKG_TEST="uv run pytest"; PKG_LINT="uv run ruff check"; PKG_AUDIT="uv run pip-audit"; LOCKFILE="uv.lock"; else PKG_MANAGER="${PKG_MANAGER}+uv"; fi
elif [ -f "requirements.txt" ]; then
  if [ "$PKG_MANAGER" = "none" ]; then PKG_MANAGER="pip"; PKG_INSTALL="pip install -r requirements.txt"; PKG_RUN="python"; PKG_TEST="pytest"; PKG_LINT="ruff check"; PKG_AUDIT="pip-audit -r requirements.txt"; LOCKFILE="requirements.txt"; else PKG_MANAGER="${PKG_MANAGER}+pip"; fi
fi

# Rust
if [ -f "Cargo.lock" ]; then
  if [ "$PKG_MANAGER" = "none" ]; then PKG_MANAGER="cargo"; PKG_INSTALL="cargo build"; PKG_RUN="cargo run"; PKG_TEST="cargo test"; PKG_LINT="cargo clippy"; PKG_AUDIT="cargo audit"; LOCKFILE="Cargo.lock"; else PKG_MANAGER="${PKG_MANAGER}+cargo"; fi
fi

# Go
if [ -f "go.sum" ]; then
  if [ "$PKG_MANAGER" = "none" ]; then PKG_MANAGER="go"; PKG_INSTALL="go mod download"; PKG_RUN="go run"; PKG_TEST="go test ./..."; PKG_LINT="golangci-lint run"; PKG_AUDIT="govulncheck ./..."; LOCKFILE="go.sum"; else PKG_MANAGER="${PKG_MANAGER}+go"; fi
fi

# Ruby
if [ -f "Gemfile.lock" ]; then
  if [ "$PKG_MANAGER" = "none" ]; then PKG_MANAGER="bundler"; PKG_INSTALL="bundle install"; PKG_RUN="bundle exec"; PKG_TEST="bundle exec rspec"; PKG_LINT="bundle exec rubocop"; PKG_AUDIT="bundle audit"; LOCKFILE="Gemfile.lock"; else PKG_MANAGER="${PKG_MANAGER}+bundler"; fi
fi

# Output
if [ "$JSON_OUTPUT" = true ]; then
  cat <<EOF
{
  "package_manager": "$PKG_MANAGER",
  "lockfile": "$LOCKFILE",
  "install": "$PKG_INSTALL",
  "run": "$PKG_RUN",
  "test": "$PKG_TEST",
  "lint": "$PKG_LINT",
  "audit": "$PKG_AUDIT"
}
EOF
else
  echo "Package Manager: $PKG_MANAGER"
  echo "Lockfile:        $LOCKFILE"
  echo ""
  echo "Commands:"
  echo "  Install: $PKG_INSTALL"
  echo "  Run:     $PKG_RUN"
  echo "  Test:    $PKG_TEST"
  echo "  Lint:    $PKG_LINT"
  echo "  Audit:   $PKG_AUDIT"
fi
