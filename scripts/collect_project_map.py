#!/usr/bin/env python3
"""collect_project_map.py — Directory tree + risk scoring for AI agent safety.

Walks the project tree, scores files/directories by risk level for AI agent
operations, and produces a structured map.

Usage: python3 collect_project_map.py [--root DIR] [--json] [--max-depth N]
"""

import argparse
import json
import os
import sys
from pathlib import Path

CRITICAL_PATTERNS = {
    ".env", ".env.production", ".env.local", ".env.staging",
    ".pem", ".key", ".p12", ".pfx", ".id_rsa",
}
CRITICAL_DIRS = {"migrations", "secrets", "credentials", "ssl", "certs"}
HIGH_PATTERNS = {"package.json", "requirements.txt", "Pipfile", "Cargo.toml", "go.mod", "Gemfile", "pyproject.toml"}
HIGH_DIRS = {"config", "conf", ".github", "scripts", "infrastructure", "terraform", "kubernetes", "k8s", "docker"}
MEDIUM_DIRS = {"src", "lib", "app", "api", "server", "client"}
LOW_DIRS = {"dist", "build", "out", "coverage", ".next", ".nuxt", "node_modules", "__pycache__", ".cache", "target"}
IGNORE_DIRS = {"node_modules", ".git", "__pycache__", ".cache", ".next", ".nuxt", "dist", "build", "out", "coverage", "target", ".turbo", ".vercel", ".DS_Store", "venv", ".venv", "env", ".tox", ".mypy_cache", ".pytest_cache", ".ruff_cache"}


def score_file(filepath: Path, root: Path) -> dict:
    name = filepath.name
    ext = filepath.suffix.lower()
    rel = str(filepath.relative_to(root)).replace("\\", "/")
    risk, reasons = "low", []
    if name in CRITICAL_PATTERNS or ext in {".pem", ".key", ".p12", ".pfx"}:
        risk, reasons = "critical", ["Contains secrets or private keys"]
    elif name.startswith(".env"):
        risk, reasons = "critical", ["Environment file — may contain secrets"]
    elif name in HIGH_PATTERNS:
        risk, reasons = "high", ["Dependency manifest — changes affect entire project"]
    elif ".github" in rel and "workflows" in rel and ext in {".yml", ".yaml"}:
        risk, reasons = "high", ["CI/CD pipeline — changes affect deployment safety"]
    elif "migrations" in rel and ext in {".sql", ".py", ".ts", ".js"}:
        risk, reasons = "high", ["Database migration — destructive potential"]
    elif any(kw in name.lower() for kw in ("auth", "login", "password", "session", "token", "jwt", "oauth")):
        risk, reasons = "high", ["Authentication/authorization logic — security sensitive"]
    elif ext in {".ts", ".tsx", ".js", ".jsx", ".py", ".rs", ".go", ".rb", ".java"}:
        risk, reasons = "medium", ["Source code — standard edit risk"]
    elif ext in {".md", ".txt", ".css", ".html", ".json", ".yaml", ".yml", ".toml"}:
        risk, reasons = "low", ["Config or documentation — low risk"]
    return {"path": rel, "risk": risk, "reasons": reasons}


def score_directory(dirpath: Path, root: Path) -> dict:
    name = dirpath.name
    rel = str(dirpath.relative_to(root)).replace("\\", "/")
    if name in CRITICAL_DIRS or any(d in rel for d in CRITICAL_DIRS):
        return {"path": rel, "risk": "critical", "reason": "Contains secrets, migrations, or credentials"}
    elif name in HIGH_DIRS or any(d in rel for d in HIGH_DIRS):
        return {"path": rel, "risk": "high", "reason": "Configuration, CI/CD, or infrastructure"}
    elif name in MEDIUM_DIRS:
        return {"path": rel, "risk": "medium", "reason": "Source code directory"}
    elif name in LOW_DIRS:
        return {"path": rel, "risk": "low", "reason": "Generated/build output"}
    return {"path": rel, "risk": "medium", "reason": "Unknown — treat as medium risk"}


def collect_map(root: Path, max_depth: int = 5) -> dict:
    files, directories, top_risks = [], [], []
    for dirpath, dirnames, filenames in os.walk(root):
        dp = Path(dirpath)
        dirnames[:] = [d for d in dirnames if d not in IGNORE_DIRS]
        depth = len(dp.relative_to(root).parts)
        if depth > max_depth:
            dirnames.clear()
            continue
        if dp != root:
            directories.append(score_directory(dp, root))
        for fname in filenames:
            fp = dp / fname
            if fp.suffix.lower() in {".pyc", ".pyo", ".so", ".dll", ".exe", ".obj", ".o", ".class"}:
                continue
            file_score = score_file(fp, root)
            files.append(file_score)
            if file_score["risk"] in ("critical", "high"):
                top_risks.append(file_score)
    risk_order = {"critical": 0, "high": 1, "medium": 2, "low": 3}
    files.sort(key=lambda f: risk_order.get(f["risk"], 99))
    directories.sort(key=lambda d: risk_order.get(d["risk"], 99))
    top_risks.sort(key=lambda f: risk_order.get(f["risk"], 99))
    risk_counts = {"critical": 0, "high": 0, "medium": 0, "low": 0}
    for f in files:
        risk_counts[f["risk"]] = risk_counts.get(f["risk"], 0) + 1
    return {"root": str(root), "total_files": len(files), "total_dirs": len(directories), "risk_counts": risk_counts, "top_risks": top_risks[:20], "directories": directories, "files": files}


def format_report(data: dict) -> str:
    lines = ["═" * 60, "  PROJECT RISK MAP — AI Agent Safety", "═" * 60, ""]
    lines.append(f"  Root: {data['root']}")
    lines.append(f"  Files: {data['total_files']} | Directories: {data['total_dirs']}")
    rc = data["risk_counts"]
    lines += ["", "  Risk Distribution:", f"    CRITICAL : {rc.get('critical', 0)}", f"    HIGH     : {rc.get('high', 0)}", f"    MEDIUM   : {rc.get('medium', 0)}", f"    LOW      : {rc.get('low', 0)}"]
    if data["top_risks"]:
        lines.append("  Top Risk Files:")
        for r in data["top_risks"][:10]:
            lines.append(f"    [{r['risk'].upper():8s}] {r['path']}")
    lines += ["", "  Directory Risk Zones:"]
    for d in data["directories"]:
        if d["risk"] in ("critical", "high"):
            lines.append(f"    [{d['risk'].upper():8s}] {d['path']} — {d['reason']}")
    lines.append("═" * 60)
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description="Project risk map for AI agent safety")
    parser.add_argument("--root", default=".", help="Root directory to scan")
    parser.add_argument("--json", action="store_true", help="Output as JSON")
    parser.add_argument("--max-depth", type=int, default=5, help="Max directory depth")
    args = parser.parse_args()
    root = Path(args.root).resolve()
    if not root.is_dir():
        print(f"Error: {root} is not a directory", file=sys.stderr)
        sys.exit(1)
    data = collect_map(root, args.max_depth)
    print(json.dumps(data, indent=2) if args.json else format_report(data))


if __name__ == "__main__":
    main()
