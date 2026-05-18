#!/usr/bin/env python3
"""simple_secret_scan.py — Grep-based secret leak detector.

Scans the repository for potential secret leaks using regex patterns.
Does NOT send any data externally. Runs entirely locally.

Usage: python3 simple_secret_scan.py [--root DIR] [--json] [--check-staged]
"""

import argparse, json, os, re, subprocess, sys
from pathlib import Path

PATTERNS = [
    (r"(?:AKIA|ABIA|ACCA|ASIA)[0-9A-Z]{16}", "AWS Access Key ID"),
    (r"(?:api[_-]?key|apikey)\s*[:=]\s*['\"]?[0-9a-zA-Z\-_]{20,}", "Generic API Key"),
    (r"(?:secret[_-]?key|secretkey)\s*[:=]\s*['\"]?[0-9a-zA-Z\-_]{20,}", "Generic Secret Key"),
    (r"(?:access[_-]?token|accesstoken)\s*[:=]\s*['\"]?[0-9a-zA-Z\-_.]{20,}", "Generic Access Token"),
    (r"ghp_[0-9a-zA-Z]{36}", "GitHub Personal Access Token"),
    (r"gho_[0-9a-zA-Z]{36}", "GitHub OAuth Token"),
    (r"ghu_[0-9a-zA-Z]{36}", "GitHub User-to-Server Token"),
    (r"ghs_[0-9a-zA-Z]{36}", "GitHub Server-to-Server Token"),
    (r"github_pat_[0-9a-zA-Z_]{82}", "GitHub Fine-Grained PAT"),
    (r"xox[baprs]-[0-9a-zA-Z\-]{10,}", "Slack Token"),
    (r"sk_live_[0-9a-zA-Z]{24}", "Stripe Live Secret Key"),
    (r"rk_live_[0-9a-zA-Z]{24}", "Stripe Live Restricted Key"),
    (r"(?:postgres|postgresql|mysql|mongodb|redis)://[^\s'\"]+", "Database Connection String"),
    (r"-----BEGIN (?:RSA |EC |DSA )?PRIVATE KEY-----", "PEM Private Key"),
    (r"eyJ[A-Za-z0-9-_]+\.eyJ[A-Za-z0-9-_]+\.[A-Za-z0-9-_]+", "JSON Web Token"),
    (r"AIza[0-9A-Za-z\-_]{35}", "Google API Key"),
    (r"ya29\.[0-9A-Za-z\-_]+", "Google OAuth Access Token"),
    (r"SK[0-9a-fA-F]{32}", "Twilio API Key"),
    (r"SG\.[0-9A-Za-z\-_]{22}\.[0-9A-Za-z\-_]{43}", "SendGrid API Key"),
]

IGNORE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".gif", ".bmp", ".webp", ".ico", ".svg", ".woff", ".woff2", ".ttf", ".eot", ".otf", ".mp3", ".mp4", ".wav", ".avi", ".mov", ".zip", ".tar", ".gz", ".rar", ".7z", ".pdf", ".doc", ".docx", ".xls", ".xlsx", ".pyc", ".pyo", ".so", ".dll", ".exe", ".obj", ".o", ".class", ".lock", ".map"}
IGNORE_DIRS = {"node_modules", ".git", "__pycache__", ".cache", ".next", ".nuxt", "dist", "build", "out", "coverage", "target", ".turbo", ".vercel", "venv", ".venv", "env", ".tox", ".mypy_cache", ".pytest_cache", ".ruff_cache", ".idea", ".vscode"}
IGNORE_FILES = {"package-lock.json", "yarn.lock", "pnpm-lock.yaml", "Gemfile.lock", "poetry.lock", "uv.lock", "Cargo.lock", "go.sum"}
COMPILED_PATTERNS = [(re.compile(p, re.IGNORECASE), label) for p, label in PATTERNS]


def should_scan(filepath: Path) -> bool:
    if filepath.name in IGNORE_FILES or filepath.suffix.lower() in IGNORE_EXTENSIONS:
        return False
    try:
        with open(filepath, "rb") as f:
            chunk = f.read(8192)
            if chunk.count(b"\x00") > len(chunk) // 100:
                return False
    except (OSError, PermissionError):
        return False
    return True


def scan_file(filepath: Path, root: Path) -> list:
    findings = []
    rel = str(filepath.relative_to(root)).replace("\\", "/")
    try:
        with open(filepath, "r", encoding="utf-8", errors="replace") as f:
            for line_num, line in enumerate(f, 1):
                for pattern, label in COMPILED_PATTERNS:
                    if pattern.search(line):
                        masked = pattern.sub("[REDACTED]", line.strip())
                        findings.append({"file": rel, "line": line_num, "type": label, "masked_line": masked})
    except (OSError, PermissionError):
        pass
    return findings


def scan_staged(root: Path) -> list:
    findings = []
    try:
        result = subprocess.run(["git", "diff", "--cached", "--name-only", "--diff-filter=ACM"], capture_output=True, text=True, cwd=root)
        for f in result.stdout.strip().split("\n"):
            if f:
                fp = root / f
                if fp.is_file() and should_scan(fp):
                    findings.extend(scan_file(fp, root))
    except (subprocess.SubprocessError, OSError):
        pass
    return findings


def scan_directory(root: Path) -> list:
    findings = []
    for dirpath, dirnames, filenames in os.walk(root):
        dp = Path(dirpath)
        dirnames[:] = [d for d in dirnames if d not in IGNORE_DIRS]
        for fname in filenames:
            fp = dp / fname
            if should_scan(fp):
                findings.extend(scan_file(fp, root))
    return findings


def format_report(findings: list, root: str) -> str:
    lines = ["═" * 60, "  SECRET SCAN REPORT", "═" * 60, "", f"  Root: {root}", f"  Findings: {len(findings)}", ""]
    if not findings:
        lines.append("  No secrets detected.")
    else:
        lines.append("  POTENTIAL SECRETS DETECTED:")
        for f in findings:
            lines += [f"  [{f['type']}]", f"    File: {f['file']}:{f['line']}", f"    Line: {f['masked_line']}", ""]
    lines.append("═" * 60)
    if findings:
        lines += ["  ACTION REQUIRED:", "  1. Verify each finding", "  2. Rotate confirmed leaked secrets", "  3. Add real secrets to .gitignore", "  4. Use .env.example for template", "  5. Consider: git filter-branch or BFG to clean history", "═" * 60]
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description="Simple secret leak scanner")
    parser.add_argument("--root", default=".", help="Root directory to scan")
    parser.add_argument("--json", action="store_true", help="Output as JSON")
    parser.add_argument("--check-staged", action="store_true", help="Scan only git-staged files")
    args = parser.parse_args()
    root = Path(args.root).resolve()
    if not root.is_dir():
        print(f"Error: {root} is not a directory", file=sys.stderr)
        sys.exit(1)
    findings = scan_staged(root) if args.check_staged else scan_directory(root)
    if args.json:
        print(json.dumps({"root": str(root), "findings": findings, "count": len(findings)}, indent=2))
    else:
        print(format_report(findings, str(root)))
    sys.exit(1 if findings else 0)


if __name__ == "__main__":
    main()
